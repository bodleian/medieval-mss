"""
Check entity keys

Verifies that every @key in TEI XML manuscript descriptions
corresponds to an @xml:id in the authority files.
"""

import os
import re
import sys

from lxml import etree


class XMLFile:
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
    def __init__(self, file_path: str) -> None:
        super().__init__(file_path)
        self.keys: set[str] = self.get_keys()

    def get_keys(self) -> set[str]:
        """Returns a set of all xml:id attributes on <person>, <place>, <org>, and <bibl> elements."""
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
    def check_keys(self, authority_keys: set[str]) -> bool:
        KeysValid = True
        for key in self.tree.xpath("//@key"):
            # is the key empty?
            if key == "":
                sys.stderr.write(f"Error: empty key in {self.file_path}\n")
                KeysValid = False
            # is the key in the form of `prefix_1234`?
            elif not re.match(r"\w+_\d+", key):
                sys.stderr.write(f"Error: {key} is invalid in {self.file_path}\n")
                KeysValid = False
            # is the key in the authority files?
            elif key not in authority_keys:
                sys.stderr.write(
                    f"Error: {key} not found in authority files in {self.file_path}\n"
                )
                KeysValid = False
        return KeysValid


class Collections:
    def __init__(self, directory_path: str) -> None:
        self.directory_path: str = directory_path

    @property
    def xml_paths(self) -> list[str]:
        """
        Returns a list of all XML files in the given directory.
        """
        return [
            os.path.join(root, file)
            for root, _, files in os.walk(self.directory_path)
            for file in files
            if file.endswith(".xml")
        ]


def main() -> int:
    persons = AuthorityFile("persons.xml")
    places = AuthorityFile("places.xml")
    works = AuthorityFile("works.xml")
    authority_keys: set[str] = persons.keys | places.keys | works.keys

    msdesc_paths: list[str] = Collections("collections").xml_paths

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
