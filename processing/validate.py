"""
Validate XML files using schemas declared in xml-model.
"""

import argparse
import logging
import os
import shlex
import sys
import threading
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from pathlib import Path

from lxml import etree


class SchemaCache:
    """Cache compiled RelaxNG schemas by absolute identifier (path or URL)."""

    def __init__(self) -> None:
        self._cache: dict[str, etree.RelaxNG] = {}
        self._lock = threading.Lock()

    def get_relaxng(self, identifier: str | Path) -> etree.RelaxNG:
        # Fast path under lock to avoid races
        with self._lock:
            cached = self._cache.get(str(identifier))
        if cached is not None:
            return cached

        # Load and compile outside lock to minimize contention
        data = self._load_schema_text(identifier)
        try:
            rng_doc = etree.fromstring(data.encode("utf-8"))
            compiled = etree.RelaxNG(rng_doc)
        except etree.XMLSyntaxError as e:
            raise RuntimeError(
                f"Failed to parse RelaxNG schema from '{identifier}': {e}"
            ) from e

        # Store or return existing if another thread won the race
        with self._lock:
            return self._cache.setdefault(str(identifier), compiled)

    @staticmethod
    def _load_schema_text(identifier: str | Path) -> str:
        ident_str = str(identifier)
        if ident_str.startswith("http://") or ident_str.startswith("https://"):
            return _http_get_text(ident_str)
        return Path(ident_str).read_text(encoding="utf-8")


def _http_get_text(url: str, *, timeout: float = 15.0, retries: int = 3) -> str:
    """Fetch URL as text with basic retry and a friendly User-Agent."""
    backoff = 0.5
    last_exc: Exception | None = None
    headers = {
        "User-Agent": "medieval-mss-validator/1.0 (+https://github.com/bodleian/medieval-mss)",
        "Accept": "application/xml, text/xml, */*;q=0.1",
    }
    for attempt in range(retries):
        req = urllib.request.Request(url, headers=headers, method="GET")
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                # Let urllib handle redirects; assume UTF-8 for RNG sources
                data = resp.read()
                return data.decode("utf-8")
        except (
            urllib.error.URLError,
            urllib.error.HTTPError,
            TimeoutError,
        ) as e:
            last_exc = e
            if attempt < retries - 1:
                time.sleep(backoff)
                backoff *= 2
            else:
                break
    raise RuntimeError(f"Failed to fetch schema from '{url}': {last_exc}")


def _gha_escape_message(s: str) -> str:
    """Escape message text for GitHub Actions workflow commands."""
    return s.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def _gha_escape_property(s: str) -> str:
    """Escape property values for GitHub Actions workflow commands."""
    return _gha_escape_message(s).replace(":", "%3A").replace(",", "%2C")


class XMLModelPI:
    """Represents one xml-model processing instruction entry."""

    def __init__(
        self, href: str, type_: str | None, schematypens: str | None
    ) -> None:
        self.href = href
        self.type = type_
        self.schematypens = schematypens

    @property
    def is_relaxng_xml(self) -> bool:
        # Strictly recognize Relax NG when schematypens is present
        if self.schematypens:
            return (
                self.schematypens.strip()
                == "http://relaxng.org/ns/structure/1.0"
            )
        # When schematypens is absent, fall back to common conventions
        href_lower = (self.href or "").lower()
        if href_lower.endswith(".rng"):
            return True
        if self.type and "xml" in self.type.lower():
            return True
        return False


class XMLModelResolver:
    """Resolves the xml-model schema reference for a given XML file."""

    def resolve_schema_identifier(self, file_path: Path) -> str | Path:
        entries = self._parse_xml_model_pis(file_path)
        for entry in entries:
            if entry.is_relaxng_xml:
                return self._absolutize(entry.href, base=file_path.parent)
        raise RuntimeError("No compatible xml-model (RelaxNG XML) found")

    @staticmethod
    def _parse_xml_model_pis(file_path: Path) -> list[XMLModelPI]:
        results: list[XMLModelPI] = []
        with file_path.open("rb") as f:
            for _event, pi in etree.iterparse(f, events=("pi",), recover=True):
                if pi.target != "xml-model":
                    continue
                attrs = XMLModelResolver._parse_pi_pseudo_attributes(
                    pi.text or ""
                )
                href = attrs.get("href")
                if not href:
                    continue
                results.append(
                    XMLModelPI(
                        href=href,
                        type_=attrs.get("type"),
                        schematypens=attrs.get("schematypens"),
                    )
                )
        return results

    @staticmethod
    def _parse_pi_pseudo_attributes(text: str) -> dict[str, str]:
        # xml-model PI uses whitespace-separated pseudo-attributes with quoted values
        attrs: dict[str, str] = {}
        for token in shlex.split(text, posix=True):
            if "=" in token:
                k, v = token.split("=", 1)
                v = v.strip()
                if len(v) >= 2 and v[0] in ('"', "'") and v[-1] == v[0]:
                    v = v[1:-1]
                attrs[k] = v
        return attrs

    @staticmethod
    def _absolutize(href: str, base: Path) -> str | Path:
        if href.startswith("http://") or href.startswith("https://"):
            return href
        p = Path(href)
        if p.is_absolute():
            return p
        return (base / p).resolve()


@dataclass(slots=True, frozen=True)
class Issue:
    file: Path
    line: int | None
    column: int | None
    message: str


@dataclass(slots=True, frozen=True)
class ValidationResult:
    """Outcome of validating a single file."""

    file_path: Path
    ok: bool
    errors: tuple[str, ...] = field(default_factory=tuple)
    issues: tuple[Issue, ...] = field(default_factory=tuple)


class RelaxNGValidator:
    """Validates XML files using RelaxNG schemas resolved via xml-model."""

    def __init__(
        self,
        schema_cache: SchemaCache | None = None,
        resolver: XMLModelResolver | None = None,
    ) -> None:
        self.schema_cache = schema_cache or SchemaCache()
        self.resolver = resolver or XMLModelResolver()

    def validate(self, file_path: Path) -> ValidationResult:
        try:
            schema_id = self.resolver.resolve_schema_identifier(file_path)
        except Exception as e:
            return ValidationResult(
                file_path,
                ok=False,
                errors=(str(e),),
                issues=(Issue(file_path, None, None, str(e)),),
            )

        try:
            rng = self.schema_cache.get_relaxng(schema_id)
            with file_path.open("rb") as f:
                tree = etree.parse(f)
            ok = rng.validate(tree)
            if ok:
                return ValidationResult(file_path, ok=True)
            errors: list[str] = []
            issues: list[Issue] = []

            for entry in rng.error_log:
                line_val = getattr(entry, "line", None)
                col_val = getattr(entry, "column", None)
                filename_val = getattr(entry, "filename", None)
                msg = getattr(entry, "message", str(entry))

                eline = int(line_val) if isinstance(line_val, int) else None
                ecol = int(col_val) if isinstance(col_val, int) else None

                errors.append(f"{file_path}, line {eline}: {msg}")
                issues.append(
                    Issue(
                        Path(filename_val)
                        if isinstance(filename_val, str)
                        else file_path,
                        eline,
                        ecol,
                        msg,
                    )
                )
            return ValidationResult(
                file_path,
                ok=False,
                errors=tuple(errors),
                issues=tuple(issues),
            )
        except etree.XMLSyntaxError as e:
            # lxml's XMLSyntaxError exposes .lineno and sometimes .position (line, col)
            colno: int | None = None
            pos = getattr(e, "position", None)
            if isinstance(pos, tuple) and len(pos) >= 2:
                try:
                    colno = int(pos[1])
                except Exception:
                    colno = None
            return ValidationResult(
                file_path,
                ok=False,
                errors=(f"{file_path}, line {e.lineno}: {e.msg}",),
                issues=(
                    Issue(
                        file_path,
                        int(e.lineno) if e.lineno else None,
                        colno,
                        e.msg,
                    ),
                ),
            )
        except Exception as e:
            return ValidationResult(
                file_path,
                ok=False,
                errors=(f"{file_path}: Validation error: {e}",),
                issues=(
                    Issue(file_path, None, None, f"Validation error: {e}"),
                ),
            )


class FileCollector:
    @staticmethod
    def collect_from_directory(directory_path: str | Path) -> list[Path]:
        """Returns a list of XML files in the directory."""
        base = Path(directory_path)
        return [p for p in base.rglob("*.xml") if p.is_file()]


def main(argv: list[str] | None = None) -> int:
    """CLI entrypoint to validate XML files using xml-model PIs."""
    parser = argparse.ArgumentParser(
        description="Validate XML files using their xml-model schemas.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-d",
        "--directory",
        dest="directory_path",
        help="Path to the directory containing XML files",
        type=Path,
    )
    parser.add_argument(
        "-j",
        "--jobs",
        dest="jobs",
        type=int,
        default=0,
        help="Number of parallel workers (0 = auto by CPU count)",
    )
    parser.add_argument(
        "--fail-fast",
        action="store_true",
        help="Stop on first validation failure (cancels remaining tasks)",
    )
    parser.add_argument(
        "--log-level",
        dest="log_level",
        choices=["CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"],
        default="INFO",
        help="Logging level (default: INFO)",
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="List of XML files to validate (overrides directory)",
        type=Path,
    )
    args = parser.parse_args(argv)

    # Configure logging
    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(levelname)s: %(message)s",
    )
    logger = logging.getLogger(__name__)

    if args.files:
        # Validate provided file paths
        missing_or_invalid: list[str] = []
        xml_files = []
        for p in args.files:
            if not p.exists() or not p.is_file():
                missing_or_invalid.append(str(p))
            else:
                xml_files.append(p)
        if missing_or_invalid:
            parser.error(
                "The following paths are not existing files: "
                + ", ".join(missing_or_invalid)
            )
    elif args.directory_path:
        dir_path: Path = args.directory_path
        if not dir_path.exists() or not dir_path.is_dir():
            parser.error(
                f"Directory does not exist or is not a directory: {dir_path}"
            )
            return 2
        xml_files = FileCollector.collect_from_directory(dir_path)
    else:
        parser.error("Must specify either --directory or a list of files.")
        return 2

    # Deterministic ordering for stable output
    xml_files = sorted(xml_files, key=lambda p: str(p))

    if not xml_files:
        logger.warning("No XML files found to validate.")
        return 0

    workers = (
        args.jobs if args.jobs and args.jobs > 0 else (os.cpu_count() or 1)
    )

    logger.info(
        f"Validating {len(xml_files)} file(s) with {workers} worker(s) ..."
    )
    if args.files:
        logger.info("Files to be validated:")
        for f in xml_files:
            logger.info(f"  {f}")
    elif args.directory_path:
        logger.info(
            f"Validating all .xml files in directory: {args.directory_path}"
        )
    start = time.perf_counter()

    validator = RelaxNGValidator()
    results: list[ValidationResult] = []
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [executor.submit(validator.validate, p) for p in xml_files]
        for fut in as_completed(futures):
            try:
                res = fut.result()
            except Exception as ex:
                # Shouldn't happen as validate handles errors, but be safe
                res = ValidationResult(
                    Path("<unknown>"), ok=False, errors=(str(ex),)
                )
            results.append(res)
            if args.fail_fast and not res.ok:
                logger.info("Fail-fast: stopping after first failure")
                for f in futures:
                    if not f.done():
                        f.cancel()
                break

    ok_count = 0
    gha = os.getenv("GITHUB_ACTIONS", "").lower() == "true"
    for res in results:
        if res.ok:
            ok_count += 1
            logger.debug(f"OK: {res.file_path}")
        else:
            # Emit GitHub Actions annotations if in GitHub environment
            if gha and res.issues:
                for issue in res.issues:
                    props: list[str] = [
                        f"file={_gha_escape_property(str(issue.file))}"
                    ]
                    if issue.line is not None:
                        props.append(f"line={issue.line}")
                    if issue.column is not None:
                        props.append(f"col={issue.column}")
                    props.append(
                        f"title={_gha_escape_property('XML Schema Validation')}"
                    )
                    print(
                        f"::error {','.join(props)}::{_gha_escape_message(issue.message)}"
                    )
            # Always log human-readable errors as well
            for msg in res.errors:
                logger.error(msg)

    elapsed = time.perf_counter() - start
    failed = len(results) - ok_count
    if failed == 0:
        logger.info(
            f"Validated {len(results)} file(s): all OK in {elapsed:.2f}s"
        )
        # GitHub Actions success notice
        if gha:
            print(
                f"::notice title=XML Schema Validation::✅ All {len(results)} files passed XML schema validation in {elapsed:.2f}s"
            )
        return 0
    logger.info(
        f"Validated {len(results)} file(s): {ok_count} OK, {failed} failed in {elapsed:.2f}s"
    )
    logger.error(f"{failed} errors found")
    # GitHub Actions error summary
    if gha:
        print(
            f"::error title=XML Schema Validation Summary::❌ {failed} of {len(results)} files failed XML schema validation"
        )
    return 1


if __name__ == "__main__":
    sys.exit(main())
