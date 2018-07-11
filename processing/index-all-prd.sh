#!/usr/bin/env bash

# Command arguments
# $1 = Optional mode:
#           Append 'force' to disable checking for data issues and push to Solr without prompting
#           Append 'noindex' to generate the files and do the checking but not push to Solr

SERVER="solr01-prd.bodleian.ox.ac.uk"

if [[ ! "`pwd`" == *-mss/processing ]]; then
    echo "This script must be run from the processing folder"
    exit 1
fi 

# To avoid Saxon hanging when it cannot download library modules, fetch a local copy
# and fail immediately if that is not possible. But skip this if a symlink has been 
# set up for development and testing. This is in lieu of writing a custom resolver 
# or using the dreaded Git submodules
if [ ! -L "lib" ]; then
    if [ -d "lib" ]; then 
        # The lib folder is a real folder, so delete it
        rm -rf lib;
    fi
    # Retrieve a fresh copy
    git clone -q --depth 1 https://github.com/bodleian/consolidated-tei-schema.git lib
    if [ $? -gt 0 ]; then
        echo "Cannot download library files from GitHub. Check your network connection."
        exit 1
    fi
fi

# Rebuild HTML, which must complete successfully before indexing can start
./generate-html.sh
if [ $? -gt 0 ]; then 
    echo "Indexing cannot proceed because HTML could not be generated for all manuscripts"
    exit 1;
fi

if [ "$1" == "force" ] || [ "$1" == "noindex" ]; then

    echo "Rebuilding index files two at a time..."
    printf "manuscript\nwork\nperson\nplace" | xargs -I {} -P 2 ./generate-solr-document.sh "{}s.xquery" "{}s_index.xml" {} $SERVER $1

else

    # Default mode is interactive - build one index at a time, prompting before sending to Solr
    set -e
    ./generate-solr-document.sh "manuscripts.xquery" "manuscripts_index.xml" manuscript $SERVER $1
    ./generate-solr-document.sh "works.xquery" "works_index.xml" work $SERVER $1
    ./generate-solr-document.sh "persons.xquery" "persons_index.xml" person $SERVER $1
    ./generate-solr-document.sh "places.xquery" "places_index.xml" place $SERVER $1

fi
