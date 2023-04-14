"""
Check entity keys

Verifies that every @key in TEI XML manuscript descriptions
corresponds to an @xml:id in the authority files.
"""

import os
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
            # if the key is empty, print an error message
            if element.attrib["key"] == "":
                sys.stderr.write(
                    f"Error: empty key in {file_path}:{element.sourceline}\n"
                )
                KeyError = True
            # if the key contains a space, print an error message
            elif " " in element.attrib["key"]:
                sys.stderr.write(
                    f"Error: {element.attrib['key']} contains a space in {file_path}:{element.sourceline}\n"
                )
                KeyError = True
            # if the key is not found in the authority files, print an error message
            elif element.attrib["key"] not in authority_ids:
                sys.stderr.write(
                    f"Error: {element.attrib['key']} in {file_path}:{element.sourceline} not found in authority files\n"
                )
                KeyError = True
    return KeyError


if __name__ == "__main__":
    authority_ids = set()
    for file_path in ["./persons.xml", "./places.xml", "./works.xml"]:
        authority_ids |= get_authority_ids(file_path)
    manuscript_descriptions = {
        os.path.join(root, file)
        for root, dirs, files in os.walk("./collections")
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
        sys.exit(1)
    else:
        print("All keys are valid.")
        sys.exit(0)
