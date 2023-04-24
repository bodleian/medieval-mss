"""
Classify dates on TEI <binding> elements

All <binding> elements in TEI manuscript descriptions must have an attribute
to provide an approximate date range for the binding.
This script prompts the user to date <binding> elements without attributes
by marking them as contemporary or entering a date range.

Note:
    This script modifies the TEI files in place.
"""

import os

import lxml.etree as ET


def process_binding_element(binding_element: ET.Element, file_name: str) -> bool:
    """
    Processes the <binding> element, prompting the user to input a date
    or mark it as contemporary.
    Modifies the element to include the appropriate attribute.

    Returns True if the element was modified, False otherwise.
    """
    print(f"\nProcessing file: {file_name}")

    # Print the text in the <binding> element to the console
    for description in binding_element.itertext():
        # normalize whitespace
        description = " ".join(description.split())
        print(description)

    # Prompt the user to enter a date or mark the binding as contemporary
    while True:
        date_string: str = input(
            "Enter ‘c’ for a contemporary binding, a date range as yyyy-yyyy, or a single year as yyyy: "
        )
        # if the user enters 'c', mark the binding as contemporary
        if date_string.lower() == "c":
            binding_element.set("contemporary", "true")
            return True

        # if the user presses return, skip the element
        elif not date_string:
            return False

        # if the user enters a single date, add this to when
        elif date_string.isdigit():
            binding_element.set("when", date_string)
            return True

        # if the user enters a date range, add this to notBefore and notAfter
        else:
            # replace an en dash with a hyphen
            date_string = date_string.replace("–", "-")
            # split the date range into two dates
            dates: list[str] = date_string.split("-")
            # check that the date range is valid
            if len(dates) == 2 and all(
                date.isdigit() and len(date) == 4 for date in dates
            ):
                binding_element.set("notBefore", dates[0])
                binding_element.set("notAfter", dates[1])
                return True
            else:
                print("Invalid date range format. Please try again.")
                continue


def process_tei_file(file_path: str) -> None:
    """
    Processes a TEI file, modifying <binding> elements as needed.
    """
    tree: ET.ElementTree = ET.parse(file_path)
    root: ET.Element = tree.getroot()

    # Find all <binding> elements in the file
    for binding_element in root.findall(".//{http://www.tei-c.org/ns/1.0}binding"):
        # If the <binding> element has no attributes, process it
        if not binding_element.attrib:
            # Write the updated XML to the file if the element was modified
            if process_binding_element(binding_element, file_path) is True:
                tree.write(
                    file_path,
                    encoding="utf-8",
                    method="xml",
                    pretty_print=True,
                    xml_declaration=True,
                )

                # Fix XML declaration reformatting from lxml
                with open(file_path, "r", encoding="utf-8") as file:
                    processed_xml: str = file.read()

                processed_xml = processed_xml.replace(
                    "<?xml version='1.0' encoding='UTF-8'?>",
                    '<?xml version="1.0" encoding="UTF-8"?>',
                )

                with open(file_path, "w", encoding="utf-8") as file:
                    file.write(processed_xml)


if __name__ == "__main__":
    """
    Recursively processes all TEI files in the 'collections' directory.
    """
    for dirpath, _, filenames in os.walk("./collections"):
        for filename in filenames:
            if filename.endswith(".xml"):
                file_path: str = os.path.join(dirpath, filename)
                process_tei_file(file_path)
    print("All files processed.")
