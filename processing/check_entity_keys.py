"""
Check entity keys

Verifies that every @key in TEI XML manuscript descriptions
corresponds to an @xml:id in the authority files.
"""

import os
import re
import sys
from multiprocessing import Pool

from lxml import etree


def get_authority_ids(file_path: str) -> set:
    """
    Returns a set of all xml:id attributes on <person>, <place>, <org>, and <bibl> elements
    in the metadata XML file.

    Args:
        file_path: the path of the authority file to analyse

    Returns:
        a set of all xml:id attributes in the file
    """
    parser = etree.XMLParser(ns_clean=True)
    tree = etree.parse(file_path, parser)
    xml_ids = {
        elem.get("{http://www.w3.org/XML/1998/namespace}id")
        for elem in tree.iter(
            "{http://www.tei-c.org/ns/1.0}person",
            "{http://www.tei-c.org/ns/1.0}place",
            "{http://www.tei-c.org/ns/1.0}org",
            "{http://www.tei-c.org/ns/1.0}bibl",
        )
    }
    return xml_ids


def find_key_errors(authority_ids: set, file_path: str) -> bool:
    """
    Validates that every @key in the XML descriptions in the file_path directory
    corresponds to an @xml:id in the metadata_files.

    Args:
        authority_ids: all xml:id attributes in the authority files
        file_path: the path to the XML file to check

    Returns:
        True if any errors are found, False otherwise
    """
    with open(file_path, "rb") as f:
        tree = etree.parse(f)
    KeyError = False
    for element in tree.iter():
        if "key" in element.attrib:
            # is the key empty?
            if element.attrib["key"] == "":
                sys.stderr.write(
                    f"Error: empty key in {file_path}:{element.sourceline}\n"
                )
                KeyError = True
            # is the key in the form of `prefix_1234`?
            elif not re.match(r"\w+_\d+", element.attrib["key"]):
                sys.stderr.write(
                    f"Error: {element.attrib['key']} is invalid in {file_path}:{element.sourceline}\n"
                )
                KeyError = True
            # is the key in the authority files?
            elif element.attrib["key"] not in authority_ids:
                sys.stderr.write(
                    f"Error: {element.attrib['key']} in {file_path}:{element.sourceline} not found in authority files\n"
                )
                KeyError = True
    return KeyError


def main() -> int:
    authority_ids = set()
    for file_path in ["persons.xml", "places.xml", "works.xml"]:
        authority_ids |= get_authority_ids(file_path)
    manuscript_descriptions = {
        os.path.join(root, file)
        for root, dirs, files in os.walk("collections")
        for file in files
        if file.endswith(".xml")
    }
    with Pool() as p:
        errors = p.starmap(
            find_key_errors,
            [(authority_ids, file_path) for file_path in manuscript_descriptions],
        )

    # Check if any errors were found
    if any(errors):
        return 1
    else:
        print("All keys are valid.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
