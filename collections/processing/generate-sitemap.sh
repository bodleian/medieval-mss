#!/usr/bin/env bash

java -cp "saxon/saxon9he.jar" net.sf.saxon.Query -q:sitemap.xquery | xmllint --format - > sitemap.xml

