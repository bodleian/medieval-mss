#!/usr/bin/env bash

LOGFILE="results/count-external-refs.log"

# Create subfolder to keep generated files out of GitHub
if [ ! -d "results" ]; then
    mkdir results
fi

java -Xmx1G -cp ../saxon/saxon9he.jar net.sf.saxon.Query -xi:on -q:count-external-refs.xquery -o:results/count-external-refs.html 2> $LOGFILE
