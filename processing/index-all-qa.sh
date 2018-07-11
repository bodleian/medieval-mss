#!/usr/bin/env bash

# Command arguments
# $1 = Optional mode:
#           Append 'force' to disable checking for data issues and push to Solr without prompting
#           Append 'noindex' to generate the files and do the checking but not push to Solr

if [ ! "$1" == "force" ]; then
    # Give up if any one index fails or is abandoned
    set -e
fi

cd "${0%/*}"

# Re-index manuscripts (includes rebuilding customized manuscript HTML pages, which must be run first)
./generate-html.sh && ./generate-solr-document.sh manuscripts.xquery mss_index.xml manuscript solr01-qa.bodleian.ox.ac.uk $1
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

# Reindex places (includes organizations, which must be run second)
./generate-solr-document.sh places.xquery places_index.xml place solr01-qa.bodleian.ox.ac.uk $1
if [ ! "$1" == "noindex" ]; then
    echo "Place index will be incomplete until organizations have also been reindexed."
fi
./generate-solr-document.sh organizations.xquery organizations_index.xml organization solr01-qa.bodleian.ox.ac.uk $1

# Reindex people
./generate-solr-document.sh people.xquery people_index.xml person solr01-qa.bodleian.ox.ac.uk $1

# Reindex works
./generate-solr-document.sh works.xquery works_index.xml work solr01-qa.bodleian.ox.ac.uk $1


