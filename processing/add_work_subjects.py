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


class XMLFile:
    """Represents an XML file, with methods for reading and writing."""

    def __init__(self, file_path: str):
        self.file_path: str = file_path
        self.tree: etree.ElementTree = self.read_tree()

    def read_tree(self) -> etree.ElementTree:
        """Create an XML tree from a file."""
        return etree.parse(
            self.file_path,
            parser=etree.XMLParser(ns_clean=True, recover=True, encoding="utf-8"),
        )

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


@dataclass
class Work:
    """Represents a <bibl> element, with a method for adding a <term> element."""

    bibl_element: etree.Element
    title: str = ""

    def __post_init__(self) -> None:
        self.title = self._get_title()

    def add_term(self, category: str) -> None:
        """Add a <term> element to a <bibl> element, with a reference to a category."""
        self.bibl_element.append(etree.Element("term", ref=f"#{category}", nsmap=NS))

    def _get_title(self) -> str:
        """Return a title from the <bibl> element."""
        return ", ".join(
            title.text
            for title in self.bibl_element.findall("tei:title", namespaces=NS)
        )


class Categories(dict[str, str]):
    """Provides a dictionary of <category> elements."""

    def __init__(self, works_tree: etree.ElementTree):
        self.dict: dict[str, str] = self._create_categories(works_tree)

    def __call__(self) -> dict[str, str]:
        return self.dict

    def _create_categories(self, works_tree: etree.ElementTree) -> dict[str, str]:
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

    def __call__(self) -> list[str]:
        return self.get_selection()

    def _print_categories(self) -> None:
        """Print the available categories in three columns."""
        for index, category in enumerate(self.categories.values()):
            if index % 3 == 0:
                print()
            print(f"{index+1}. {category:<25}", end="")
        print()

    def get_selection(self) -> list[str]:
        """Return category keys from the user's selection."""
        while True:
            print(f"\n{self.bibl_title}")
            self._print_categories()
            selection: str = input("\nEnter one or more category numbers: ")
            try:
                selection_indices: list[int] = [
                    int(index) - 1 for index in selection.split()
                ]
            except ValueError:
                print("Please enter one of more numbers separated by spaces.")
                continue
            except IndexError:
                print("Please select from the numbers listed.")
                continue

            selection_keys: list[str] = []
            for index in selection_indices:
                # append the category key to the list, converting the index to a key
                selection_keys.append(list(self.categories.keys())[index])

            return selection_keys


def main() -> int:
    works: XMLFile = XMLFile("works.xml")

    categories: dict[str, str] = Categories(works.tree)()

    # Iterate over <bibl> elements with an xml:id but no <term> child
    for bibl_element in works.tree.xpath(
        "//tei:bibl[@xml:id and not(tei:term)]", namespaces=NS
    ):
        # Create a Work object for manipulating the <bibl> element
        bibl: Work = Work(bibl_element)

        # Get the user's selection of categories
        selected_categories: list[str] = CategorySelector(categories, bibl.title)()

        # If there is no selection, skip to the next <bibl> element
        if not selected_categories:
            continue

        # Add <term> elements for the selected categories
        for category in selected_categories:
            bibl.add_term(category)

        # Update the XML file
        works.write_tree(works.tree)

    print("\nAll works have been processed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
