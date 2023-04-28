"""
Add subject classifications on TEI <bibl> elements

Prompts the user to select a subject classification
from <category> elements defined in `works.xml`.

The selected subject is added as a child <term> to the <bibl> element.

Run from the main project directory:
    $ python3 processing/add_work_subjects.py
"""


import sys
from dataclasses import dataclass

from lxml import etree

NS: dict[str, str] = {"tei": "http://www.tei-c.org/ns/1.0"}


class XMLFile(str):
    def __init__(self, file_path: str):
        self.file_path = file_path

    def write_tree(self, tree: etree.ElementTree) -> None:
        """Write the XML tree to the file with minimal changes to formatting."""
        tree.write(
            self.file_path,
            encoding="utf-8",
            pretty_print=True,
            xml_declaration=True,
        )

        self._fix_xml_declaration()

    def _fix_xml_declaration(self) -> None:
        """Fix the XML declaration with single quotes from lxml."""
        with open(self.file_path, "r+", encoding="utf-8") as file:
            file.seek(0)
            file.write('<?xml version="1.0" encoding="UTF-8"?>\n')
            file.seek(0, 2)
            file.truncate()


class XMLTree:
    """The XML tree of the file."""

    def __init__(self, file_path: str):
        self.works_file_path: str = file_path

    def create_tree(self) -> etree.ElementTree:
        """Create an XML tree from a file."""
        return etree.parse(
            self.works_file_path,
            parser=etree.XMLParser(ns_clean=True, recover=True, encoding="utf-8"),
        )


@dataclass
class Bibl:
    """A <bibl> element."""

    bibl_element: etree.Element

    def add_term(self, category: str) -> None:
        """Add a <term> element to a <bibl> element, with a reference to a category."""
        self.bibl_element.append(etree.Element("term", ref=f"#{category}", nsmap=NS))

    def title(self) -> str:
        """Return a title from the <bibl> element."""
        return ", ".join(
            title.text
            for title in self.bibl_element.findall("tei:title", namespaces=NS)
        )


class Categories(dict):
    """A dictionary of <category> elements."""

    def create_categories(self, works_tree: etree.ElementTree) -> dict[str, str]:
        """Create a dictionary of <category> elements."""
        return {
            category.get("{http://www.w3.org/XML/1998/namespace}id"): category.findtext(
                "tei:catDesc", namespaces=NS
            )
            for category in works_tree.xpath("//tei:category", namespaces=NS)
        }


class CategorySelector(list[str]):
    """
    Prompt the user to select a category.
    """

    def __init__(self, categories: dict[str, str], bibl_title: str):
        self.categories = categories
        self.bibl_title = bibl_title

    def print_categories(self) -> None:
        """Print the available categories in three columns."""
        for index, category in enumerate(self.categories.values()):
            if index % 3 == 0:
                print()
            print(f"{index+1}. {category:<25}", end="")
        print()

    def validate_selection(self, selection: str) -> bool:
        """Check that the selection can be converted to a list of integers."""
        if not selection:
            return True  # valid not to make a selection
        elif all(
            int(index) - 1 in range(len(self.categories)) for index in selection.split()
        ):
            return True  # all indices are valid
        else:
            print("Please enter one of more numbers separated by spaces.")
            return False

    def convert_index_to_category(self, index: int) -> str:
        """Convert an index to a category."""
        return list(self.categories.keys())[index]

    def get_selection(self) -> list[str]:
        """Return category keys from the user's selection."""
        while True:
            print(f"\n{self.bibl_title}")
            self.print_categories()
            selection: str = input("\nEnter one or more category numbers: ")
            if self.validate_selection(selection):
                selection_indices: list[int] = [
                    int(index) - 1 for index in selection.split()
                ]
                selection_keys: list[str] = []
                for index in selection_indices:
                    selection_keys.append(self.convert_index_to_category(index))
                return selection_keys


def main() -> int:
    works_file: XMLFile = XMLFile("works.xml")

    works_tree: etree.ElementTree = XMLTree(works_file).create_tree()

    categories: dict[str, str] = Categories().create_categories(works_tree)

    # Iterate over <bibl> elements with an xml:id but no <term> child
    for bibl_element in works_tree.xpath(
        "//tei:bibl[@xml:id and not(tei:term)]", namespaces=NS
    ):
        # Create a Bibl object from the <bibl> element
        bibl: Bibl = Bibl(bibl_element)

        # Prompt the user for a category selection
        selected_categories: list[str] = CategorySelector(
            categories, bibl.title()
        ).get_selection()

        # If there is no selection, skip to the next <bibl> element
        if not selected_categories:
            continue

        # Add the selection in a <term> element
        for category in selected_categories:
            bibl.add_term(category)

        # Update the XML file
        works_file.write_tree(works_tree)

    print("\nAll works have been processed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
