#!/usr/bin/env bash

# Create subfolder to keep generated files out of GitHub
if [ ! -d "results" ]; then
    mkdir results
fi

LOGFILE="results/simplified-xml-for-3m.log"

# Generate the simplied XML, outputting to 20 chunks, which avoids memory issues when they will be processed by x3ml
for i in {0..19}
do
    java -Xmx1G -cp ../saxon/saxon9he.jar net.sf.saxon.Query -xi:on -q:simplified-xml-for-3m.xquery -o:results/simplified-xml-for-3m-chunk$i.xml chunk=$i 2>> $LOGFILE
done