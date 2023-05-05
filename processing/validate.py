"""
Validates all XML files in a directory
against a remote RelaxNG schema.
"""

import os
import sys
import urllib.request
from multiprocessing import Pool, cpu_count

from lxml import etree


def download_schema(schema_url: str) -> str:
    """
    Downloads the RelaxNG schema from a remote server
    and returns it as a string.
    """
    with urllib.request.urlopen(schema_url) as response:
        schema_data = response.read().decode("utf-8")
    return schema_data


def validate_xml_file(xml_file: str, schema: str) -> bool:
    """
    Validates the given XML file against the RelaxNG schema.

    Returns True if the file passes validation, False otherwise.
    """
    try:
        with open(xml_file, "rb") as f:
            doc = etree.parse(f)
        schema_doc = etree.fromstring(schema.encode("utf-8"))
        rng = etree.RelaxNG(schema_doc)
        if not rng.validate(doc):
            for error in rng.error_log:
                sys.stderr.write(f"{xml_file}:{error.line} {error.message}\n")
            return False
        return True
    except etree.XMLSyntaxError as e:
        sys.stderr.write(f"Error parsing {xml_file}: {str(e)}\n")
        return False


def validate_xml_files(collection_dir: str, schema: str) -> bool:
    """
    Validates all XML files in a directory against a RelaxNG schema.

    Returns True if all files pass validation, False otherwise.
    """
    xml_files = get_xml_files(collection_dir)
    # Exit early if no XML files are found
    if not xml_files:
        sys.stderr.write(f"No XML files found in {collection_dir}")
        sys.exit(1)
    # Use multiprocessing to speed up validation
    with Pool(cpu_count()) as pool:
        results = pool.starmap(
            validate_xml_file, [(xml_file, schema) for xml_file in xml_files]
        )
    return all(results)


def get_xml_files(directory: str) -> list[str]:
    """Returns a list of absolute paths to all XML files in a directory."""
    xml_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".xml"):
                xml_files.append(os.path.join(root, file))
    return xml_files


def main() -> int:
    schema_url = "https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc.rng"
    schema = download_schema(schema_url)
    if not validate_xml_files("collections", schema):
        return 1
    else:
        print("All XML files are valid.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
