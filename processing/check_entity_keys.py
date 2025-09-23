"""
Verify that every @key in a TEI XML manuscript description
corresponds to an @xml:id in the authority files.
"""

import argparse
import logging
import os
import re
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import cast

from lxml import etree


def get_element_context(elem: etree._Element) -> str:
    """Get a brief XPath-like context for an element to help with debugging."""
    path_parts = []
    current: etree._Element | None = elem
    while current is not None and current.tag is not None:
        tag = current.tag.split("}")[-1] if "}" in current.tag else current.tag
        path_parts.append(tag)
        current = current.getparent()
        if len(path_parts) >= 3:  # Limit depth for readability
            break
    return "/".join(reversed(path_parts))


@dataclass(slots=True, frozen=True)
class ValidationIssue:
    """Represents a validation issue found in a manuscript description."""

    file: Path
    message: str
    line: int | None = None
    column: int | None = None


def _gha_escape_message(s: str) -> str:
    """Escape message text for GitHub Actions workflow commands."""
    return s.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def _gha_escape_property(s: str) -> str:
    """Escape property values for GitHub Actions workflow commands."""
    return _gha_escape_message(s).replace(":", "%3A").replace(",", "%2C")


NS: dict[str, str] = {
    "xml": "http://www.w3.org/XML/1998/namespace",
    "tei": "http://www.tei-c.org/ns/1.0",
}

KEY_PATTERN = re.compile(r"^(?:(?:person)|(?:place)|(?:org)|(?:work))_\d+$")


@dataclass(slots=True, frozen=False)
class XMLFile:
    """Represents an XML file."""

    file_path: Path
    tree: object = field(init=False, repr=False)

    def __post_init__(self) -> None:
        """Initializes the tree by parsing the XML file."""
        self.tree = self.read()

    def read(self) -> object:
        """Parses the XML file specified by file_path."""
        logger = logging.getLogger(__name__)
        try:
            # Use lxml's parser with line number tracking enabled
            parser = etree.XMLParser()
            tree = etree.parse(self.file_path, parser)
            if tree.getroot() is None:
                msg = f"XML file '{self.file_path}' has no root element"
                raise ValueError(msg)
            return tree
        except etree.XMLSyntaxError as err:
            msg = f"XML parsing error in '{self.file_path}': {err}"
            logger.error(msg)
            raise
        except (OSError, IOError) as err:
            msg = f"File I/O error reading '{self.file_path}': {err}"
            logger.error(msg)
            raise
        except Exception as exc:
            msg = f"Unexpected error reading '{self.file_path}': {exc}"
            logger.error(msg)
            raise


class AuthorityFile(XMLFile):
    """Represents an authority file with allowed TEI elements."""

    def __init__(self, file_path: Path) -> None:
        super().__init__(file_path)
        self._validate_tei_document()
        self.keys: set[str] = self.get_keys()

    def _validate_tei_document(self) -> None:
        """Validate that this is a TEI document."""
        tree = cast(etree._ElementTree, self.tree)
        root = tree.getroot()
        if root.tag != f"{{{NS['tei']}}}TEI":
            logger = logging.getLogger(__name__)
            logger.warning(
                f"Authority file '{self.file_path}' does not appear to be a TEI document (root element: {root.tag})"
            )

    def get_keys(self) -> set[str]:
        """Extracts all xml:id values from allowed TEI elements within the authority file."""
        tree = cast(etree._ElementTree, self.tree)
        xpath_expr = "//tei:person[@xml:id] | //tei:place[@xml:id] | //tei:org[@xml:id] | //tei:bibl[@xml:id]"
        elements = tree.xpath(xpath_expr, namespaces=NS)
        return {
            str(elem.attrib[f"{{{NS['xml']}}}id"])
            for elem in cast(list[etree._Element], elements)
        }


class MSDesc(XMLFile):
    """Represents a manuscript description file and provides key validation."""

    def __init__(self, file_path: Path) -> None:
        super().__init__(file_path)
        self._validate_tei_document()

    def _validate_tei_document(self) -> None:
        """Validate that this is a TEI document."""
        tree = cast(etree._ElementTree, self.tree)
        root = tree.getroot()
        if root.tag != f"{{{NS['tei']}}}TEI":
            logger = logging.getLogger(__name__)
            logger.warning(
                f"Manuscript description '{self.file_path}' does not appear to be a TEI document (root element: {root.tag})"
            )

    def check_keys(self, authority_keys: set[str]) -> list[ValidationIssue]:
        """Validates that every 'key' attribute in the manuscript description is correct."""
        issues: list[ValidationIssue] = []
        tree = cast(etree._ElementTree, self.tree)
        # Use XPath to directly find all elements with key attributes
        elements_with_keys = tree.xpath("//*[@key]")
        for elem in cast(list[etree._Element], elements_with_keys):
            key: str = str(elem.attrib["key"])
            line_number: int | None = (
                elem.sourceline
                if hasattr(elem, "sourceline") and elem.sourceline is not ...
                else None
            )
            column_number: int | None = getattr(elem, "sourcecolumn", None)
            match key:
                case "":
                    context = get_element_context(elem)
                    issues.append(
                        ValidationIssue(
                            file=self.file_path,
                            message=f"Empty key attribute found in {context}",
                            line=line_number,
                            column=column_number,
                        )
                    )
                case _ if not KEY_PATTERN.fullmatch(key):
                    context = get_element_context(elem)
                    issues.append(
                        ValidationIssue(
                            file=self.file_path,
                            message=f"Invalid key format '{key}' in {context} (expected pattern: person_123, place_456, etc.)",
                            line=line_number,
                            column=column_number,
                        )
                    )
                case _ if key not in authority_keys:
                    context = get_element_context(elem)
                    issues.append(
                        ValidationIssue(
                            file=self.file_path,
                            message=f"Key '{key}' in {context} not found in authority files (persons.xml, places.xml, works.xml)",
                            line=line_number,
                            column=column_number,
                        )
                    )
                case _:
                    # Key is valid.
                    pass
        return issues


class AuthorityKeyValidator:
    """Validates manuscript description files against authority keys."""

    def __init__(
        self,
        authority_paths: list[Path],
        directory_path: Path | None = None,
        file_paths: list[Path] | None = None,
    ) -> None:
        self.directory_path: Path | None = directory_path
        self.file_paths: list[Path] | None = file_paths
        self.authority_paths: list[Path] = authority_paths
        self.authority_keys: set[str] = self._aggregate_authority_keys()

    def _aggregate_authority_keys(self) -> set[str]:
        """Aggregates keys from provided authority files."""
        aggregated: set[str] = set()
        logger = logging.getLogger(__name__)
        for path in self.authority_paths:
            try:
                aggregated |= AuthorityFile(path).keys
                logger.debug(f"Processed authority file: '{path}'")
            except (OSError, IOError) as err:
                logger.error(
                    f"File I/O error with authority file '{path}': {err}"
                )
            except etree.XMLSyntaxError as err:
                logger.error(
                    f"XML parsing error in authority file '{path}': {err}"
                )
            except Exception as exc:
                logger.error(
                    f"Unexpected error with authority file '{path}': {exc}"
                )
        return aggregated

    def validate_manuscripts(self) -> int:
        """Processes manuscript description XML files and validates keys.

        Returns:
            int: Number of files with key validation errors.
        """
        start = time.perf_counter()
        error_count: int = 0
        total_files: int = 0
        logger = logging.getLogger(__name__)
        gha = os.getenv("GITHUB_ACTIONS", "").lower() == "true"

        # Determine which files to process
        if self.file_paths:
            msdesc_paths: list[Path] = self.file_paths
        elif self.directory_path:
            msdesc_paths = list(self.directory_path.rglob("*.xml"))
        else:
            logger.error("Neither directory path nor file paths provided.")
            return 1

        if not msdesc_paths:
            if self.directory_path:
                logger.warning(
                    f"No XML files found in '{self.directory_path}'."
                )
            else:
                logger.warning("No XML files provided.")

        for path in msdesc_paths:
            total_files += 1
            try:
                issues = MSDesc(path).check_keys(self.authority_keys)
                if issues:
                    error_count += 1
                    # Emit GitHub Actions annotations if in GitHub environment
                    if gha:
                        for issue in issues:
                            props: list[str] = [
                                f"file={_gha_escape_property(str(issue.file))}"
                            ]
                            if issue.line is not None:
                                props.append(f"line={issue.line}")
                            if issue.column is not None:
                                props.append(f"col={issue.column}")
                            props.append(
                                f"title={_gha_escape_property('Entity key validation')}"
                            )
                            print(
                                f"::error {','.join(props)}::{_gha_escape_message(issue.message)}"
                            )
                    # Always log human-readable errors as well
                    for issue in issues:
                        logger.error(f"{issue.file}: {issue.message}")
                else:
                    logger.debug(f"No issues in '{path}'.")
            except (OSError, IOError) as err:
                logger.error(f"File I/O error processing '{path}': {err}")
                error_count += 1
            except etree.XMLSyntaxError as err:
                logger.error(f"XML parsing error in '{path}': {err}")
                error_count += 1
            except Exception as exc:
                logger.error(f"Unexpected error processing '{path}': {exc}")
                error_count += 1

        # Report results with timing
        elapsed = time.perf_counter() - start
        ok_count = total_files - error_count
        if error_count == 0:
            logger.info(
                f"Validated {total_files} file(s): all OK in {elapsed:.2f}s"
            )
            # GitHub Actions success notice
            if gha:
                print(
                    f"::notice title=Entity Key Validation::✅ All {total_files} files passed entity key validation in {elapsed:.2f}s"
                )
        else:
            logger.info(
                f"Validated {total_files} file(s): {ok_count} OK, {error_count} failed in {elapsed:.2f}s"
            )
            # GitHub Actions error summary
            if gha:
                print(
                    f"::error title=Entity Key Validation Summary::❌ {error_count} of {total_files} files failed entity key validation"
                )

        return error_count


def parse_arguments() -> argparse.Namespace:
    """Parses command-line arguments."""
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-d",
        "--directory",
        dest="directory_path",
        nargs="?",
        default=Path("collections"),
        help="Path to directory of TEI XML manuscript descriptions",
        type=Path,
    )
    parser.add_argument(
        "-a",
        "--authority",
        dest="authority_paths",
        nargs="*",
        default=[Path("persons.xml"), Path("places.xml"), Path("works.xml")],
        help="Paths to authority files",
        type=Path,
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="List of XML files to validate (overrides directory)",
        type=Path,
    )
    return parser.parse_args()


def main() -> int:
    args: argparse.Namespace = parse_arguments()

    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format="%(levelname)s: %(message)s",
    )
    logger = logging.getLogger(__name__)

    logger.info("Starting validation of manuscript keys...")

    # Determine whether to use files or directory
    if args.files:
        validator = AuthorityKeyValidator(
            args.authority_paths, file_paths=args.files
        )
    else:
        validator = AuthorityKeyValidator(
            args.authority_paths, directory_path=args.directory_path
        )

    errors: int = validator.validate_manuscripts()
    if errors:
        logger.error(f"{errors} errors found")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
