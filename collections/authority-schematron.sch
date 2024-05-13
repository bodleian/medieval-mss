<?xml version="1.0" encoding="UTF-8"?>
<schema queryBinding="xslt2" xmlns="http://purl.oclc.org/dsdl/schematron">
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <!-- currently, these are basic rules relating to correct entry of names and ids. Later they may be expanded to cover other areas. -->
   <pattern>
      <rule context="tei:person">
         <assert test="matches(@xml:id, 'person_\d+')">The person element must have an xml:id attribute matching the pattern 'person_[digits]'</assert>
         <assert test="count(tei:persName[@type = 'display']) = 1">One persName element only must have @type=display</assert>
      </rule>
   </pattern>
   <pattern>
      <rule context="tei:org">
         <assert test="matches(@xml:id, 'org_\d+')">The org element must have an xml:id attribute matching the pattern 'org_[digits]'</assert>
         <assert test="count(tei:orgName[@type = 'display']) = 1">One orgName element only must have @type=display</assert>
      </rule>
      <rule context="tei:place">
         <assert test="matches(@xml:id, 'place_\d+')">The place element must have an xml:id attribute matching the pattern 'place_[digits]'</assert>
         <assert test="count(tei:placeName[@type = 'index']) = 1">One placeName element only must have @type=index</assert>
      </rule>
   </pattern>
   <pattern>
      <rule context="tei:text/tei:body/tei:listBibl/tei:bibl">
         <assert test="matches(@xml:id, 'work_\d+')">The bibl element must have an xml:id attribute matching the pattern 'work_[digits]'</assert>
         <assert test="count(tei:title[@type = 'uniform']) = 1">One title element only must have @type=uniform</assert>
         <assert test="tei:textLang[@mainLang]">Works should have language(s) specified in a textLang element which must have an attribute @mainLang</assert>
      </rule>
   </pattern>
   <pattern>
      <rule context="tei:text/tei:body/tei:listBibl/tei:bibl">
         <assert test="tei:term" role="warn">All works should have one or more terms</assert>
      </rule>
      <rule context="tei:text/tei:body/tei:listBibl/tei:bibl/tei:term">
         <let name="categoryids" value="/tei:TEI/tei:teiHeader/tei:encodingDesc/tei:classDecl/tei:taxonomy/tei:category/@xml:id"/>
         <assert test="@ref">Terms should reference a category defined in the header</assert>
         <assert test="
               every $r in tokenize(@ref, '\s*#')[string-length() gt 0]
                  satisfies $r = $categoryids">Term does not reference the ID of a category in the header</assert>
      </rule>
   </pattern>
</schema>
