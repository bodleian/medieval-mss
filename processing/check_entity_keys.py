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

logging.basicConfig(format="%(message)s", level=logging.INFO)

NS: dict[str, str] = {
    "xml": "http://www.w3.org/XML/1998/namespace",
    "tei": "http://www.tei-c.org/ns/1.0",
}

KEY_PATTERN = re.compile(r"\w+_\d+")


@dataclass(slots=True)
class XMLFile:
    """Represents an XML file."""

    file_path: Path
    tree: ET.ElementTree = field(init=False)

    def __post_init__(self) -> None:
        """Initialises the tree by parsing the XML file."""
        self.tree = self.read()

    def read(self) -> ET.ElementTree:
        """Parse the XML file specified by file_path."""
        try:
            return ET.parse(str(self.file_path))
        except (ET.ParseError, Exception) as exc:
            logging.error(f"Error reading {self.file_path}: {exc}")
            raise


class AuthorityFile(XMLFile):
    """Represents an authority file (persons.xml, places.xml, or works.xml)."""

    def __init__(self, file_path: Path) -> None:
        super().__init__(file_path)
        self.keys: set[str] = self.get_keys()

    def get_keys(self) -> set[str]:
        """Extract all xml:id values from allowed TEI elements within the authority file."""
        allowed_tags: set[str] = {
            f"{{{NS['tei']}}}{tag}"
            for tag in ("person", "place", "org", "bibl")
        }
        return {
            elem.attrib[f"{{{NS['xml']}}}id"]
            for elem in self.tree.iter()
            if elem.tag in allowed_tags
            and elem.attrib.get(f"{{{NS['xml']}}}id")
        }


class MSDesc(XMLFile):
    """Represents a manuscript description file and provides key validation."""

    def check_keys(self, authority_keys: set[str]) -> bool:
        """Check that every 'key' attribute in the manuscript description is valid."""
        keys_valid = True
        for elem in self.tree.iter():
            if "key" not in elem.attrib:
                continue
            key: str = elem.attrib["key"]
            match key:
                case "":
                    logging.error(f"Empty key found in {self.file_path}")
                    keys_valid = False
                case _ if not KEY_PATTERN.fullmatch(key):
                    logging.error(f"Invalid key '{key}' in {self.file_path}")
                    keys_valid = False
                case _ if key not in authority_keys:
                    logging.error(
                        f"Key '{key}' not found in authority files in {self.file_path}"
                    )
                    keys_valid = False
                case _:
                    pass
        return keys_valid


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""
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
        help="Path to a directory of TEI XML manuscript descriptions",
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
    # Aggregate authority keys.
    authority_keys: set[str] = set()
    for authority_path in args.authority_paths:
        try:
            authority_keys |= AuthorityFile(authority_path).keys
        except Exception:
            logging.error(f"Skipping authority file: {authority_path}")
    # Discover manuscript description XML files.
    msdesc_paths: list[Path] = list(args.directory_path.rglob("*.xml"))
    errors = 0
    for path in msdesc_paths:
        try:
            if not MSDesc(path).check_keys(authority_keys):
                errors += 1
        except Exception as exc:
            logging.error(f"Error processing {path}: {exc}")
            errors += 1
    if errors:
        logging.info(f"{errors} error(s) found")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
