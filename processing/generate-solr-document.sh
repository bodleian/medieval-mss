#!/usr/bin/env bash

# Command arguments
# $1 = xQuery file
# $2 = Output file
# $3 = Solr `type` (for deleting only one type of record)
# $4 = Solr address for indexing

#echo "Generating Solr XML document"
#java -Xmx1G -Xms1G -cp "saxon/saxon9he.jar" net.sf.saxon.Query -q:$1 | xmllint --format - > $2

# Emptying for both place and organization will result in only one of them being indexed; if we're indexing
# organizations, then, skip the empty step.
if [ ! $1 == "organizations.xquery" ]; then
    echo "Emptying Solr"
    curl "http://${4}:8983/solr/medieval-mss/update?stream.body=<delete><query>type:${3}</query></delete>&commit=true"
fi

echo "Reindexing in Solr"
curl "http://${4}:8983/solr/medieval-mss/update?commit=true" --data-binary @$2 -H "Content-Type: text/xml"
