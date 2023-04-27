"""
Add subject classifications on TEI <bibl> elements

Prompts the user to select a subject classification
from <category> elements defined in `works.xml`.

The selected subject is added as a child <term> to the <bibl> element.

Run from the main project directory:
    $ python3 processing/add_work_subjects.py
"""

from lxml import etree

# define XML namespaces
NS: dict[str, str] = {"tei": "http://www.tei-c.org/ns/1.0"}

WORKS_FILE: str = "works.xml"


def get_categories(tree: etree.ElementTree) -> dict[str, str]:
    """
    Create a dictionary of categories from the works file.

    Returns a dictionary of category IDs and descriptions.
        Key: `@xml:id` of the category element
        Value: text of the <catDesc> element
    """
    return {
        category.get("{http://www.w3.org/XML/1998/namespace}id"): category.findtext(
            "tei:catDesc", namespaces=NS
        )
        for category in tree.xpath("//tei:category", namespaces=NS)
    }


def add_subject(
    works_tree: etree.ElementTree, bibl: etree.Element, categories: dict[str, str]
) -> None:
    """
    Prompt the user to select a category. Add it as a <term> to the <bibl> element.
    """
    print("\nWork without a subject:\n")
    # print the title of the work
    print(
        f"{', '.join(title.text for title in bibl.findall('tei:title', namespaces=NS))}"
    )

    print("\nAvailable categories:")
    # print the categories in three columns
    category_numbers: list[str] = []
    for index, category in enumerate(categories):
        if index % 3 == 0:
            print()
        print(f"{index+1}. {categories[category]:<25}", end="")
        category_numbers.append(str(index + 1))

    while True:
        category_selections: list[str] = input(
            "\nEnter category number(s), separated by spaces: "
        ).split()

        # if entry is blank, skip this <bibl>
        if not category_selections:
            print("\nSkipping this work.")
            break

        # if entry is invalid, prompt again
        if all(
            index.isdigit() and index in category_numbers
            for index in category_selections
        ):
            break
        else:
            print("\nInvalid input. Please enter valid category number(s).\n")

    selected_category_indices: list[str] = [
        list(categories.keys())[int(index) - 1]
        for index in category_selections
        if index.isdigit()
    ]

    for selected_category in selected_category_indices:
        bibl.append(etree.Element("term", ref=f"#{selected_category}", nsmap=NS))

    write_xml(works_tree, WORKS_FILE)


def write_xml(tree: etree.ElementTree, file_path: str) -> None:
    """Write the XML tree to a file with minimal changes to formatting."""
    tree.write(
        file_path,
        encoding="utf-8",
        pretty_print=True,
        xml_declaration=True,
    )

    fix_xml_declaration(file_path)


def fix_xml_declaration(file_path: str) -> None:
    """Fix XML declaration reformatting from lxml."""
    with open(file_path, "r", encoding="utf-8") as file:
        processed_xml: str = file.read().replace(
            "<?xml version='1.0' encoding='UTF-8'?>",
            '<?xml version="1.0" encoding="UTF-8"?>',
        )

    with open(file_path, "w", encoding="utf-8") as file:
        file.write(processed_xml)


if __name__ == "__main__":
    works_tree: etree.ElementTree = etree.parse(
        WORKS_FILE, parser=etree.XMLParser(ns_clean=True, recover=True)
    )
    categories: dict[str, str] = get_categories(works_tree)

    # Find <bibl> elements without a <term>
    for bibl in works_tree.xpath(
        "/tei:TEI/tei:text/tei:body//tei:bibl[@xml:id]", namespaces=NS
    ):
        if bibl.find("tei:term", namespaces=NS) is None:
            # If no <term> exists, prompt the user to select a category
            add_subject(works_tree, bibl, categories)

    print("\nAll works have been processed.")
