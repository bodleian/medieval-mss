"""
Verifies that every @key in TEI XML manuscript descriptions
corresponds to an @xml:id in the authority files.
"""

import argparse
import logging
import re
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path
from typing import cast


class GitHubActionsFormatter(logging.Formatter):
    """Custom logging formatter for GitHub Actions annotations."""

    def format(self, record: logging.LogRecord) -> str:
        msg = super().format(record)
        match record.levelno:
            case logging.ERROR:
                return f"::error :: {msg}"
            case logging.WARNING:
                return f"::warning :: {msg}"
            case logging.DEBUG:
                return f"::debug :: {msg}"
            case _:
                return msg


# Replace the default logging configuration with one supporting GitHub Actions annotations.
handler = logging.StreamHandler()
handler.setFormatter(GitHubActionsFormatter(fmt="%(message)s"))
logging.basicConfig(handlers=[handler], level=logging.INFO, force=True)

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
        """Initialises the tree by parsing the XML file."""
        self.tree = self.read()

    def read(self) -> object:
        """Parses the XML file specified by file_path."""
        try:
            tree = ET.parse(self.file_path)
            if tree.getroot() is None:
                msg = f"XML file '{self.file_path}' has no root element"
                raise ValueError(msg)
            return tree
        except ET.ParseError as err:
            msg = f"XML parsing error in '{self.file_path}': {err}"
            logging.error(msg)
            raise
        except (OSError, IOError) as err:
            msg = f"File I/O error reading '{self.file_path}': {err}"
            logging.error(msg)
            raise
        except Exception as exc:
            msg = f"Unexpected error reading '{self.file_path}': {exc}"
            logging.error(msg)
            raise


class AuthorityFile(XMLFile):
    """Represents an authority file with allowed TEI elements."""

    def __init__(self, file_path: Path) -> None:
        super().__init__(file_path)
        self.keys: set[str] = self.get_keys()

    def get_keys(self) -> set[str]:
        """Extracts all xml:id values from allowed TEI elements within the authority file."""
        allowed_tags: set[str] = {
            f"{{{NS['tei']}}}{tag}"
            for tag in ("person", "place", "org", "bibl")
        }
        tree = cast(ET.ElementTree, self.tree)
        return {
            elem.attrib[f"{{{NS['xml']}}}id"]
            for elem in tree.iter()
            if elem.tag in allowed_tags
            and elem.attrib.get(f"{{{NS['xml']}}}id")
        }


class MSDesc(XMLFile):
    """Represents a manuscript description file and provides key validation."""

    def check_keys(self, authority_keys: set[str]) -> bool:
        """Validates that every 'key' attribute in the manuscript description is correct."""
        valid: bool = True
        tree = cast(ET.ElementTree, self.tree)
        for elem in tree.iter():
            if "key" not in elem.attrib:
                continue
            key: str = elem.attrib["key"]
            match key:
                case "":
                    logging.error(f"Empty key found in '{self.file_path}'.")
                    valid = False
                case _ if not KEY_PATTERN.fullmatch(key):
                    logging.error(
                        f"Invalid key '{key}' found in '{self.file_path}'."
                    )
                    valid = False
                case _ if key not in authority_keys:
                    logging.error(
                        f"Key '{key}' not found in authority files in '{self.file_path}'."
                    )
                    valid = False
                case _:
                    # Key is valid.
                    pass
        return valid


class AuthorityKeyValidator:
    """Validates manuscript description files against authority keys."""

    def __init__(
        self, directory_path: Path, authority_paths: list[Path]
    ) -> None:
        self.directory_path: Path = directory_path
        self.authority_paths: list[Path] = authority_paths
        self.authority_keys: set[str] = self._aggregate_authority_keys()

    def _aggregate_authority_keys(self) -> set[str]:
        """Aggregates keys from provided authority files."""
        aggregated: set[str] = set()
        for path in self.authority_paths:
            try:
                aggregated |= AuthorityFile(path).keys
                logging.debug(f"Processed authority file: '{path}'")
            except (OSError, IOError) as err:
                logging.error(
                    f"File I/O error with authority file '{path}': {err}"
                )
            except ET.ParseError as err:
                logging.error(
                    f"XML parsing error in authority file '{path}': {err}"
                )
            except Exception as exc:
                logging.error(
                    f"Unexpected error with authority file '{path}': {exc}"
                )
        return aggregated

    def validate_manuscripts(self) -> int:
        """Processes manuscript description XML files and validates keys.

        Returns:
            int: Number of files with key validation errors.
        """
        error_count: int = 0
        msdesc_paths: list[Path] = list(self.directory_path.rglob("*.xml"))
        if not msdesc_paths:
            logging.warning(f"No XML files found in '{self.directory_path}'.")
        for path in msdesc_paths:
            try:
                if not MSDesc(path).check_keys(self.authority_keys):
                    error_count += 1
                else:
                    logging.debug(f"No issues in '{path}'.")
            except (OSError, IOError) as err:
                logging.error(f"File I/O error processing '{path}': {err}")
                error_count += 1
            except ET.ParseError as err:
                logging.error(f"XML parsing error in '{path}': {err}")
                error_count += 1
            except Exception as exc:
                logging.error(f"Unexpected error processing '{path}': {exc}")
                error_count += 1
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
    return parser.parse_args()


def main() -> int:
    args: argparse.Namespace = parse_arguments()
    logging.info("Starting validation of manuscript keys...")
    validator = AuthorityKeyValidator(args.directory_path, args.authority_paths)
    errors: int = validator.validate_manuscripts()
    if errors:
        logging.info(f"Validation completed with {errors} error(s).")
    else:
        logging.info("Validation completed successfully with no errors.")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
