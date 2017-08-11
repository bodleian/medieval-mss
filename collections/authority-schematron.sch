<?xml version="1.0" encoding="UTF-8"?>


<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
 <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/> 
    
    <!-- currently, these are basic rules relating to correct entry of names and ids. Later they may be expanded to cover other areas. -->
    
    <pattern>
        <rule context="tei:person">
            <assert test="matches(@xml:id, 'person_\d+')">The person element must have an xml:id attribute matching the pattern 'person_[digits]'</assert>
            <assert test="count(tei:persName[@type='display']) = 1">One persName element only must have @type=display</assert>
        </rule>
    </pattern>
    
    
    <pattern>
        <rule context="tei:org">
            <assert test="matches(@xml:id, 'org_\d+')">The org element must have an xml:id attribute matching the pattern 'org_[digits]'</assert>
            <assert test="count(tei:orgName[@type='display']) = 1">One orgName element only must have @type=display</assert>
        </rule>
        <rule context="tei:place">
            <assert test="matches(@xml:id, 'place_\d+')">The place element must have an xml:id attribute matching the pattern 'place_[digits]'</assert>
            <assert test="count(tei:placeName[@type='index']) = 1">One placeName element only must have @type=index</assert>
        </rule>
    </pattern>
</schema>