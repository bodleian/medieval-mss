#!/usr/bin/env bash

LOGFILE="results/simplified-xml-for-3m.log"

# Create subfolder to keep generated files out of GitHub
if [ ! -d "results" ]; then
    mkdir results
fi

java -Xmx1G -cp ../saxon/saxon9he.jar net.sf.saxon.Query -xi:on -q:simplified-xml-for-3m.xquery -o:results/simplified-xml-for-3m.xml 2> $LOGFILE
