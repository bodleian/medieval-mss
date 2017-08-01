#!/usr/bin/env bash

java -cp "saxon/saxon9he.jar"  net.sf.saxon.Transform -it:main -xsl:convert2HTML.xsl

echo "Prettifying output"
#find ./html/ -name "*.html" -type f -exec xmllint --output '{}' --format '{}' \;
find ./html/ -name "*.html" -type f -exec tidy --doctype omit --numeric-entities yes --tidy-mark no -i -m -w 160 -asxhtml -utf8 -output '{}' '{}' \;