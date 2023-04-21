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


def process_binding_element(binding_element, file_name):
    """
    Processes the <binding> element, prompting the user to input a date
    or mark it as contemporary.
    Modifies the element to include the appropriate attribute.
    """
    print(f"\nProcessing file: {file_name}")
    # Print the <p> elements in the <binding> element to the console
    for p_element in binding_element.findall("{http://www.tei-c.org/ns/1.0}p"):
        print(ET.tostring(p_element, encoding="unicode", pretty_print=True))
    while True:
        # Prompt the user to enter a date or mark the binding as contemporary
        response = input(
            "Enter ‘c’ for a contemporary binding, a date range as yyyy-yyyy, or a single year as yyyy: "
        )
        # if the user enters 'c', mark the binding as contemporary
        if response.lower() == "c":
            binding_element.set("contemporary", "true")
            break

        # if the user presses return, skip the element
        elif not response:
            break

        # if the user enters a single date, add this to when
        elif response.isdigit():
            binding_element.set("when", response)
            break

        # if the user enters a date range, add this to notBefore and notAfter
        else:
            # replace an en dash with a hyphen
            response = response.replace("–", "-")
            # split the date range into two dates
            dates = response.split("-")
            # check that the date range is valid
            if len(dates) == 2 and all(date.isdigit() for date in dates):
                binding_element.set("notBefore", dates[0])
                binding_element.set("notAfter", dates[1])
                break
            else:
                print("Invalid date range format. Please try again.")
            break


def process_tei_file(file_path):
    """
    Processes a TEI file, modifying <binding> elements as needed.
    """
    tree = ET.parse(file_path)
    root = tree.getroot()
    modified = False

    for binding_element in root.findall(".//{http://www.tei-c.org/ns/1.0}binding"):
        if not binding_element.attrib:
            process_binding_element(binding_element, file_path)
            modified = True
    if modified:
        # Write the updated XML to the file
        tree.write(
            file_path,
            encoding="utf-8",
            method="xml",
            pretty_print=True,
            xml_declaration=True,
        )
        # Fix XML declaration reformatting from lxml
        with open(file_path, "r", encoding="utf-8") as file:
            processed_xml = file.read()

        processed_xml = processed_xml.replace(
            "<?xml version='1.0' encoding='UTF-8'?>",
            '<?xml version="1.0" encoding="UTF-8"?>',
        )

        with open(file_path, "w", encoding="utf-8") as file:
            file.write(processed_xml)


def main():
    """
    Recursively processes all TEI files in the 'collections' directory.
    """
    for dirpath, _, filenames in os.walk("./collections"):
        for filename in filenames:
            if filename.endswith(".xml"):
                file_path = os.path.join(dirpath, filename)
                process_tei_file(file_path)
    print("All files processed.")


if __name__ == "__main__":
    main()
