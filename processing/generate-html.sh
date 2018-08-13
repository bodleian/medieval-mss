#!/usr/bin/env bash

echo
echo "Generating HTML for customized manuscript view..."

if [[ ! "`pwd`" == *-mss/processing ]]; then
    echo "This script must be run from the processing folder"
    exit 1
fi 

# Create subfolder to keep generated files out of GitHub
if [ ! -d "html" ]; then
    mkdir html
fi

# Start log file
LOGFILE="html/html.log"
echo "Transforming TEI files in collections folder using convert2HTML.xsl on $(date +"%Y-%m-%d %H:%M:%S") to create HTML manuscript view pages." > $LOGFILE

# Run XSLT on all TEI files in collections path (using pwd to get full path, not relative, which is what the XSL needs)
java -Xmx1G -Xms1G -cp "saxon/saxon9he.jar"  net.sf.saxon.Transform -it:batch -xsl:convert2HTML.xsl collections-path=`pwd`/../collections/ 2>> $LOGFILE
if [ $? -gt 0 ]; then
    echo "XSLT failed. Re-indexing cancelled. Please raise an issue on GitHub, attaching $LOGFILE"
    exit 1;
fi
