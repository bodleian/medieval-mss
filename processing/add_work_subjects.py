"""
Add subject classifications to TEI <bibl> elements

Prompts the user to select a subject classification
for each <bibl> element in the works file.
The user's selection is added as a <term> element
with a reference to the selected category.

Run from the main project directory:
    $ python3 processing/add_work_subjects.py
"""


import sys
from dataclasses import dataclass, field

from lxml import etree

NS: dict[str, str] = {"tei": "http://www.tei-c.org/ns/1.0"}


@dataclass
class XMLElement:
    """Represents an XML element."""

    element: etree.Element
    id: str = field(default_factory=str)

    def __post_init__(self) -> None:
        self.id = self.element.get("{http://www.w3.org/XML/1998/namespace}id")


@dataclass
class Category(XMLElement):
    """Represents a <category> element."""

    description: str = field(default_factory=str)

    def __post_init__(self) -> None:
        super().__post_init__()
        self.description = self.element.findtext("tei:catDesc", namespaces=NS)


@dataclass
class Work(XMLElement):
    """Represents a <bibl> element, with a method for adding a <term> element."""

    title: str = field(default_factory=str)

    def __post_init__(self) -> None:
        super().__post_init__()
        self.title = ", ".join(
            title.text for title in self.element.findall("tei:title", namespaces=NS)
        )

    def add_term(self, category: str) -> None:
        """Add a <term> element to a <bibl> element, with a reference to a category."""
        self.element.append(etree.Element("term", ref=f"#{category}", nsmap=NS))


class XMLFile:
    """Represents an XML file, with methods for reading and writing."""

    def __init__(self, file_path: str) -> None:
        self.file_path: str = file_path
        self.tree: etree.ElementTree = self.read_tree()

    def read_tree(self) -> etree.ElementTree:
        """Create an XML tree from a file."""
        return etree.parse(
            self.file_path,
            parser=etree.XMLParser(ns_clean=True),
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


class WorksFile(XMLFile):
    """Represents the works file."""

    @property
    def categories(self) -> list[Category]:
        """Return a list of Category objects."""
        return [
            Category(category)
            for category in self.tree.xpath("//tei:category", namespaces=NS)
        ]


class CategorySelector(list[str]):
    """Prompt the user to select a category."""

    def __call__(self, bibl_title: str, categories: list[Category]) -> list[str]:
        """Return category IDs from the user's selection."""
        while True:
            print(f"\n{bibl_title}\n")
            self._print_categories([category.description for category in categories])
            selection: str = input("\nEnter one or more category numbers: ")
            try:
                # return a list of the category IDs from the user's selection
                return [categories[int(index) - 1].id for index in selection.split()]
            except ValueError:
                print("Please enter one of more numbers.")
                continue
            except IndexError:
                print("Please select from the numbers listed.")
                continue

    def _print_categories(self, category_descriptions: list[str]) -> None:
        """Print the available categories in rows of three."""
        for index, description in enumerate(category_descriptions, start=1):
            print(f"{index:>2}. {description:<25}", end="")
            if index % 3 == 0:
                print()


def main() -> int:
    """Prompt the user to select a category for each <bibl> element."""
    works: WorksFile = WorksFile("works.xml")

    # Iterate over <bibl> elements with an xml:id but no <term> child
    for bibl_element in works.tree.xpath(
        "//tei:bibl[@xml:id and not(tei:term)]", namespaces=NS
    ):
        # Create a Work object for manipulating the <bibl> element
        bibl: Work = Work(bibl_element)

        # Get the user's selection of categories
        selected_categories: list[str] = CategorySelector()(
            bibl.title, works.categories
        )

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
