"""
Verifies that every @key in TEI XML manuscript descriptions
corresponds to an @xml:id in the authority files.
"""

import argparse
import os
import re
import sys

from lxml import etree


class XMLFile:
    """Base class for XML files."""

    def __init__(self, file_path: str) -> None:
        self.file_path: str = file_path
        self.tree: etree.ElementTree = self.read()

    def read(self) -> etree.ElementTree:
        """Create an XML tree from a file."""
        return etree.parse(
            self.file_path,
            parser=etree.XMLParser(ns_clean=True),
        )


class AuthorityFile(XMLFile):
    """Represents an authority file (persons.xml, places.xml, or works.xml)."""

    def __init__(self, file_path: str) -> None:
        super().__init__(file_path)
        self.keys: set[str] = self.get_keys()

    def get_keys(self) -> set[str]:
        """
        Returns a set of all xml:id attributes
        on <person>, <place>, <org>, and <bibl> elements.
        """
        return {
            elem.get("{http://www.w3.org/XML/1998/namespace}id")
            for elem in self.tree.iter(
                "{http://www.tei-c.org/ns/1.0}person",
                "{http://www.tei-c.org/ns/1.0}place",
                "{http://www.tei-c.org/ns/1.0}org",
                "{http://www.tei-c.org/ns/1.0}bibl",
            )
        }


class MSDesc(XMLFile):
    """
    Represents a TEI XML manuscript description.
    """

    def check_keys(self, authority_keys: set[str]) -> bool:
        """Returns True if every @key reference is valid, False otherwise."""
        KeysValid = True
        for key_elem in self.tree.xpath("//@key/parent::*"):
            line_number = key_elem.sourceline
            key = key_elem.get("key")

            # is the key empty?
            if key == "":
                sys.stderr.write(
                    f"Error: empty key in {self.file_path}, line {line_number}\n"
                )
                KeysValid = False
            # is the key in the form of `prefix_1234`?
            elif not re.match(r"\w+_\d+", key):
                sys.stderr.write(
                    f"Error: {key} is invalid in {self.file_path}, line {line_number}\n"
                )
                KeysValid = False
            # is the key in the authority files?
            elif key not in authority_keys:
                sys.stderr.write(
                    f"Error: {key} not found in authority files in {self.file_path}, line {line_number}\n"
                )
                KeysValid = False

        return KeysValid


class Collections:
    """Represents a directory of TEI XML manuscript descriptions."""

    def __init__(self, directory_path: str) -> None:
        self.directory_path: str = directory_path

    @property
    def xml_paths(self) -> list[str]:
        """Returns a list of XML files in the directory."""
        return [
            os.path.join(root, file)
            for root, _, files in os.walk(self.directory_path)
            for file in files
            if file.endswith(".xml")
        ]


def main() -> int:
    """
    Check key references in TEI XML manuscript descriptions.

    Returns 0 if all keys are valid, 1 otherwise.
    """
    parser = argparse.ArgumentParser(
        description="Check key references in TEI XML manuscript descriptions."
    )
    parser.add_argument(
        "-d",
        "--directory",
        dest="directory_path",
        nargs="?",
        default="collections",
        help="Path to a directory of TEI XML manuscript descriptions",
        type=str,
    )
    parser.add_argument(
        "-a",
        "--authority",
        dest="authority_paths",
        nargs="*",
        default=["persons.xml", "places.xml", "works.xml"],
        help="Paths to authority files",
        type=str,
    )
    args: argparse.Namespace = parser.parse_args()

    # create a set of all keys in the authority files
    authority_keys: set[str] = set()
    for authority_path in args.authority_paths:
        authority_keys |= AuthorityFile(authority_path).keys

    # check keys in the manuscript descriptions
    msdesc_paths: list[str] = Collections(args.directory_path).xml_paths
    results: list[bool] = [
        MSDesc(msdesc_path).check_keys(authority_keys) for msdesc_path in msdesc_paths
    ]

    if all(results):
        return 0
    else:
        print(f"{len(results) - sum(results)} errors found")
        return 1


if __name__ == "__main__":
    sys.exit(main())
