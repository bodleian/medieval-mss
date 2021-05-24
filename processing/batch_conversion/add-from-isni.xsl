<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:ZiNG="urn:z3950:ZiNG:Service"
    xmlns:marc="http://www.loc.gov/MARC21/slim"
    xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs map tei ZiNG marc"
    version="3.0">
    
    <xsl:output method="xml" indent="no" encoding="UTF-8"/>
    
    <!-- This adds ISNIs, or comments when a record exists in the ISNI database but is not yet approved, from the results of 
         calls to the ISNI API saved locally in a temporary folder (done separately via curl as username/password is required) -->
    
    <!-- Queries to send to ISNI API can be generated with this XPath:
         /TEI/text/body/*/(person|org)[not(note/list/item/ref[contains(@target, 'isni.org')])]/note/list/item/ref[contains(@target, 'viaf.org')]/@target/concat('pica.cn+%3D+%22VIAF%2B', tokenize(., '/')[5], '%22')
         The output of that can then be passed to a Bash command like:
         xargs -I {} bash -c 'curl -k -o "/tmp/isni/output/{}.xml" "https://isni-m.oclc.nl/sru/username=____/password=____/DB=1.3/?query={}"; sleep 2;'
         Finally transform either persons.xml or places.xml using this stylesheet, and it will retrieve the ISNI API responses to add to the authority file. -->
    
    <xsl:variable name="newline" as="xs:string" select="'&#10;'"/>
    <xsl:variable name="today" as="xs:string" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
    <xsl:variable name="sourcenoteid" as="xs:string" select="concat('IL', count(/TEI/teiHeader/fileDesc/notesStmt[1]/note[starts-with(@xml:id, 'IL')])+1)"/>
    <xsl:variable name="isniapiresults" select="collection('file:///tmp/isni/output/?select=*.xml')/ZiNG:searchRetrieveResponse"/>
    <xsl:variable name="viaf2isni" as="map(xs:string, node())">
        <xsl:map>
            <xsl:for-each select="$isniapiresults">
                <xsl:variable name="isnidoc" select="."/>
                <xsl:variable name="viafid" as="xs:string*" select="tokenize($isnidoc/ZiNG:echoedRequest[1]/*[local-name()='query'][1]/text()[1], '%..')[string-length(.) gt 0][position() eq last()]"/>
                <xsl:if test="count($viafid) ne 1"><xsl:message terminate="yes">Cannot find VIAF ID in <xsl:value-of select="$isnidoc/ZiNG:echoedRequest[1]"/></xsl:message></xsl:if>
                <xsl:map-entry key="$viafid">
                    <xsl:choose>
                        <xsl:when test="$isnidoc/ZiNG:numberOfRecords[1]/text() = '0'">
                            <xsl:comment>No match found in ISNI for VIAF ID <xsl:value-of select="$viafid"/> on <xsl:value-of select="$today"/> </xsl:comment>
                        </xsl:when>
                        <xsl:when test="$isnidoc/ZiNG:numberOfRecords[1]/text() = '1'">
                            <xsl:variable name="isniiddatafield" as="element(marc:datafield)*" select="$isnidoc//marc:collection/marc:record/marc:datafield[@tag='003E']"/>
                            <xsl:choose>
                                <xsl:when test="$isniiddatafield/marc:subfield[@code='a']/text()[1] = 'assigned'">
                                    <item source="#{ $sourcenoteid }">
                                        <ref target="http://www.isni.org/isni/{ $isniiddatafield/marc:subfield[@code='0']/text()[1] }">
                                            <title>ISNI</title>
                                        </ref>
                                    </item>
                                </xsl:when>
                                <xsl:when test="$isniiddatafield/marc:subfield[@code='a']/text()[1] = 'provisional'">
                                    <xsl:comment>Provisional ISNI ID as of <xsl:value-of select="$today"/>: <xsl:value-of select="$isniiddatafield/marc:subfield[@code='0']/text()[1]"/></xsl:comment>
                                </xsl:when>
                                <xsl:when test="$isniiddatafield/marc:subfield[@code='a']/text()[1] = 'suspect'">
                                    <xsl:comment>Suspect ISNI ID as of <xsl:value-of select="$today"/>: <xsl:value-of select="$isniiddatafield/marc:subfield[@code='0']/text()[1]"/></xsl:comment>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:comment>Unexpected ISNI API response for <xsl:value-of select="$viafid"/></xsl:comment>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:comment>Multiple matches found in ISNI on <xsl:value-of select="$today"/></xsl:comment>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    
    <!-- Root template -->
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- Keep header PIs on separate lines -->
    
    <xsl:template match="processing-instruction('xml-model')">
        <xsl:if test="not(preceding-sibling::processing-instruction('xml-model'))"><xsl:value-of select="$newline"/></xsl:if>
        <xsl:copy/>
        <xsl:value-of select="$newline"/>
    </xsl:template>
    
    <!-- Add note to header to serve as target for source attributes in links added below -->
    
    <xsl:template match="/TEI/teiHeader/fileDesc/notesStmt[1]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <note xml:id="{ $sourcenoteid }">Elements with source attributes of "#<xsl:value-of select="$sourcenoteid"/>" were retrieved from ISNI and added by add-from-isni.xsl on <xsl:value-of select="$today"/></note>
        </xsl:copy>
    </xsl:template>
    
    <!-- Add links or comments to authority entries -->
    
    <xsl:template match="/TEI/text/body/(listPerson|listOrg)/(person|org)[@xml:id]/note/list">
        <xsl:variable name="viafurls" as="xs:string*" select="item/ref[title/text()[1] = 'VIAF']/@target"/>
        <xsl:variable name="viafids" as="xs:string*" select="for $url in $viafurls return tokenize($url, '/')[string-length(.) gt 0][position() eq last()]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="(*|comment()|text()|processing-instruction())[not(self::comment()[matches(., '^(Provisional ISNI ID|No match found in ISNI|Suspect ISNI ID|Unexpected ISNI API|Multiple matches found in ISNI)')])]"/>
            <xsl:for-each select="$viafids">
                <xsl:if test="exists($viaf2isni(.))">
                    <xsl:copy-of select="$viaf2isni(.)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <!-- Default templates -->
    
    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="text()|comment()|processing-instruction()">
        <xsl:copy/>
    </xsl:template>
    
</xsl:stylesheet>