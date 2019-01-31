#!/usr/bin/env bash

# Create subfolder to keep generated files out of GitHub
if [ ! -d "results" ]; then
    mkdir results
fi

LOGFILE="results/simplify-tei-for-x3ml.log"

date > $LOGFILE

# Generate the simplied XML, extracting the desired information from the ~10K TEI records for each manuscript, 
# Also output to 20 chunks, to avoids memory issues when they are subsequently processed by x3ml
for i in {0..19}
do
    java -Xmx1G -cp ../../saxon/saxon9he.jar net.sf.saxon.Query -xi:on -q:simplify-records-for-x3ml.xquery -o:results/manuscripts_chunk$i.xml collectionsfolder="../../../collections" chunk=$i numchunks=20 2>> $LOGFILE
done

# Strip out namespaces from authority files, which x3ml cannot handle no matter how I try to declare it
# in the mapping file. Also chunk persons and works, again so the x3ml can process them in minutes rather than hours.
for i in {0..4}
do
    java -Xmx1G -cp ../../saxon/saxon9he.jar net.sf.saxon.Query -xi:on -q:simplify-authorities-for-x3ml.xquery -o:results/persons_chunk$i.xml authorityfile="../../../persons.xml" chunk=$i numchunks=5 2>> $LOGFILE
done
for i in {0..4}
do
    java -Xmx1G -cp ../../saxon/saxon9he.jar net.sf.saxon.Query -xi:on -q:simplify-authorities-for-x3ml.xquery -o:results/works_chunk$i.xml authorityfile="../../../works.xml" chunk=$i numchunks=5 2>> $LOGFILE
done
java -Xmx1G -cp ../../saxon/saxon9he.jar net.sf.saxon.Query -xi:on -q:simplify-authorities-for-x3ml.xquery -o:results/places.xml authorityfile="../../../places.xml" chunk=0 numchunks=1 2>> $LOGFILE
