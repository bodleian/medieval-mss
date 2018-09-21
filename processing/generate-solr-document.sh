#!/usr/bin/env bash

# Command arguments
# $1 = XQuery file
# $2 = Output file
# $3 = Solr `type` (for deleting only one type of record)
# $4 = Solr address for indexing
# $5 = Optional mode:
#           'force' to disable checking for data issues and push to Solr without prompting
#           'noindex' to generate the files and do the checking but not push to Solr
#           'reuse' to send files previously created to Solr without rebuilding them

echo

if [ $# -lt 4 ]; then
    echo "Too few command line arguments."
    exit 1;
fi

if [[ ! "`pwd`" == *-mss/processing ]]; then
    echo "This script must be run from the processing folder"
    exit 1;
fi

if [ ! -d "lib" ]; then 
    echo "Missing processing/lib subfolder"
    exit 1;
fi

# Create subfolder to keep generated files out of GitHub
if [ ! -d "solr" ]; then mkdir solr; fi

# Start log file
LOGFILE="solr/$3.log"
if [ ! "$5" == "reuse" ]; then
    echo "Processing TEI files in collections folder using $1 on $(date +"%Y-%m-%d %H:%M:%S") to be sent to $4 for re-indexing." > $LOGFILE
else
    echo "Sending previously generated index files to $4"
fi

if [ ! "$5" == "reuse" ]; then

    # Run XQuery to build Solr XML index files
    echo "Generating Solr XML file containing $3 records..."
    java -Xmx1G -Xms1G -cp "saxon/saxon9he.jar" net.sf.saxon.Query -xi:on -q:$1 1> solr/$2 2>> $LOGFILE
    if [ $? -gt 0 ]; then
        echo "XQuery failed. Re-indexing of $3 records cancelled. Please raise an issue on GitHub, attaching $LOGFILE"
        exit 1;
    fi

    # Clean up log file (because XQuery/Saxon appends some junk to the end of each line)
    # Doesn't work in git-bash which lacks the rev command
    if hash rev 2>/dev/null; then
        rev $LOGFILE | cut -f 2- | rev > $LOGFILE.tmp && mv $LOGFILE.tmp $LOGFILE
    fi

    # Check what's been logged
    errors=$(grep -ic "^error" $LOGFILE)
    if [ $errors -gt 0 ]; then
        echo "There are $errors error messages in $LOGFILE so re-indexing of $3 records cannot proceed."
        exit 1;
    fi
    warnings=$(grep -ic "^warn" $LOGFILE)
    infos=$(grep -ic "^info" $LOGFILE)
    if [ $warnings -gt 0 ] || [ $infos -gt 0 ]; then
        echo "There are $warnings warning and $infos info messages in $LOGFILE"
        if [ ! "$5" == "force" ] && [ ! "$5" == "noindex" ]; then
            while true; do
                read -p "Do you wish to rebuild the $3 index? [Yes|No|Quit|View] " answer
                case $answer in
                    [Yy]|YES|Yes|yes ) break;;
                    [Nn]|NO|No|no ) echo "Re-indexing of $3 records cancelled. Proceeding to next index."; exit 0;;
                    [Qq]|QUIT|Quit|quit ) echo "Re-indexing of $3 records cancelled. Abandoning all further indexing."; exit 1;;
                    [Vv]|VIEW|View|view ) less $LOGFILE; echo;;
                    * ) echo;;
                esac
            done
        fi
    fi
fi

if [ ! "$5" == "noindex" ]; then

    # Emptying index on Solr
    echo "Emptying Solr of $3 records..."
    curl -X POST -fsS "http://${4}:8983/solr/medieval-mss/update?commit=true" --data-binary "<delete><query>type:${3}</query></delete>" -H "Content-Type: text/xml" 1>> $LOGFILE 2>> $LOGFILE

    if [ $? -gt 0 ]; then
        echo "Emptying Solr failed. Try again later. If problem persists, please raise an issue on GitHub, attaching $LOGFILE."
        exit 1;
    else
        # Upload to Solr
        echo "Sending new $3 records to Solr..."
        curl -fsS "http://${4}:8983/solr/medieval-mss/update?commit=true" --data-binary @solr/$2 -H "Content-Type: text/xml" 1>> $LOGFILE 2>> $LOGFILE
        if [ $? -eq 0 ]; then
            echo "Re-indexing of $3 records finished. Please check the web site for expected changes."
            exit 0;
        else
            echo "Re-indexing of $3 records failed. The web site will have no $3s. If this is on production, raise an urgent issue on GitHub, attaching $LOGFILE."
            exit 1;
        fi
    fi
else
    echo "Processing $3 records finished. Sending to Solr skipped in $5 mode."
    exit 0;
fi
