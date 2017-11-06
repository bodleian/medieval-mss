#!/usr/bin/env bash

#./generate-html.sh
./generate-solr-document.sh manuscripts.xquery mss_solr_index.xml manuscript solr01-qa.bodleian.ox.ac.uk
./generate-solr-document.sh places.xquery places_solr_index.xml place solr01-qa.bodleian.ox.ac.uk
./generate-solr-document.sh organizations.xquery organizations_solr_index.xml organization solr01-qa.bodleian.ox.ac.uk
./generate-solr-document.sh people.xquery people_solr_index.xml person solr01-qa.bodleian.ox.ac.uk
./generate-solr-document.sh works.xquery works_solr_index.xml work solr01-qa.bodleian.ox.ac.uk