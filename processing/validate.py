"""
Validates all XML files in a directory
against a remote RelaxNG schema.
"""

import argparse
import os
import sys
import urllib.request
from multiprocessing import Pool, cpu_count

from lxml import etree


class XMLSchema:
    """Represents a RelaxNG schema."""

    def __init__(self, url: str) -> None:
        self.url: str = url
        self.data: str = self.download()

    def download(self) -> str:
        """
        Downloads the RelaxNG schema from a remote server
        and returns it as a string.
        """
        with urllib.request.urlopen(self.url) as response:
            schema_data: str = response.read().decode("utf-8")
        return schema_data


class XMLFile:
    """Base class for XML files."""

    def validate(self, schema: XMLSchema, file_path: str) -> bool:
        """
        Validates the given XML file against the RelaxNG schema.

        Returns True if the file passes validation, False otherwise.
        """
        try:
            with open(file_path, "rb") as f:
                tree = etree.parse(f)
            rng = etree.RelaxNG(etree.fromstring(schema.data.encode("utf-8")))
            if not rng.validate(tree):
                for error in rng.error_log:
                    sys.stderr.write(
                        f"{file_path}, line {error.line}: {error.message}\n"
                    )
                return False
            return True
        except etree.XMLSyntaxError as error:
            sys.stderr.write(f"{file_path}, line {error.lineno}: {error.msg}\n")
            return False


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
    Validates all XML files in a directory.

    Returns 0 if all files pass validation, 1 otherwise.
    """

    parser = argparse.ArgumentParser(
        description="Validate XML files against a RelaxNG schema."
    )
    parser.add_argument(
        "-d",
        "--directory",
        dest="directory_path",
        nargs="?",
        default="collections",
        help="Path to the directory containing XML files",
        type=str,
    )
    parser.add_argument(
        "-s",
        "--schema",
        dest="schema_url",
        nargs="?",
        default="https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc.rng",
        help="URL of the RelaxNG schema",
        type=str,
    )
    args: argparse.Namespace = parser.parse_args()

    schema: XMLSchema = XMLSchema(args.schema_url)

    msdesc_paths: list[str] = Collections(args.directory_path).xml_paths

    with Pool(cpu_count()) as pool:
        results = pool.starmap(
            XMLFile().validate, [(schema, path) for path in msdesc_paths]
        )

    if all(results):
        return 0
    else:
        print(f"{len(results) - sum(results)} errors found")
        return 1


if __name__ == "__main__":
    sys.exit(main())
