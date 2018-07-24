#!/usr/bin/env bash

LOGFILE="results/works-msitems-diff.log"

# Create subfolder to keep generated files out of GitHub
if [ ! -d "results" ]; then
    mkdir results
fi

java -Xmx1G -cp ../saxon/saxon9he.jar net.sf.saxon.Query -xi:on -q:works-msitems-diff.xquery -o:results/works-msitems-diff.html 2> $LOGFILE
