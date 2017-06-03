#!/usr/bin/env bash

java -cp "saxon/saxon9he.jar"  net.sf.saxon.Transform -it:main -xsl:convert2HTML.xsl