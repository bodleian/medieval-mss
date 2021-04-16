<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs map tei ZiNG marc" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:ZiNG="urn:z3950:ZiNG:Service" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="no" method="xml"/>
    <!-- This adds ISNIs, or comments when a record exists in the ISNI database but is not yet approved, from the results of 
         calls to the ISNI API saved locally in a temporary folder (done separately via curl as username/password is required) -->
    <!-- Queries to send to ISNI API can be generated with this XPath:
         /TEI/text/body/*/(person|org)[not(note/list/item/ref[contains(@target, 'isni.org')])]/note/list/item/ref[contains(@target, 'viaf.org')]/@target/concat('pica.cn+%3D+%22VIAF%2B', substring-after(., '/viaf/'), '%22')
         The output of that can then be passed to a Bash command like:
         xargs -I {} bash -c 'curl -k -o "/tmp/isni/output/{}.xml" "https://isni-m.oclc.nl/sru/username=____/password=____/DB=1.3/?query={}"; sleep 2;'
         Finally transform either persons.xml or places.xml using this stylesheet, and it will retrieve the ISNI API responses to add to the authority file. -->
    <xsl:variable as="xs:string" name="newline" select="'&#10;'"/>
    <xsl:variable as="xs:string" name="today" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
    <xsl:variable as="xs:string" name="sourcenoteid" select="concat('IL', count(/TEI/teiHeader/fileDesc/notesStmt[1]/note[starts-with(@xml:id, 'IL')]) + 1)"/>
    <xsl:variable name="isniapiresults" select="collection('file:///tmp/isni/output/?select=*.xml')/ZiNG:searchRetrieveResponse"/>
    <xsl:variable as="map(xs:string, node())" name="viaf2isni">
        <xsl:map>
            <xsl:for-each select="$isniapiresults">
                <xsl:variable name="isnidoc" select="."/>
                <xsl:variable as="xs:string*" name="viafid" select="tokenize($isnidoc/ZiNG:echoedRequest[1]/*[local-name() = 'query'][1]/text()[1], '%..')[string-length(.) gt 0][position() eq last()]"/>
                <xsl:if test="count($viafid) ne 1">
                    <xsl:message terminate="yes">Cannot find VIAF ID in <xsl:value-of select="$isnidoc/ZiNG:echoedRequest[1]"/></xsl:message>
                </xsl:if>
                <xsl:map-entry key="$viafid">
                    <xsl:choose>
                        <xsl:when test="$isnidoc/ZiNG:numberOfRecords[1]/text() = '0'">
                            <xsl:comment>No match found in ISNI for VIAF ID <xsl:value-of select="$viafid"/> on <xsl:value-of select="$today"/> </xsl:comment>
                        </xsl:when>
                        <xsl:when test="$isnidoc/ZiNG:numberOfRecords[1]/text() = '1'">
                            <xsl:variable as="element(marc:datafield)*" name="isniiddatafield" select="$isnidoc//marc:collection/marc:record/marc:datafield[@tag = '003E']"/>
                            <xsl:choose>
                                <xsl:when test="$isniiddatafield/marc:subfield[@code = 'a']/text()[1] = 'assigned'">
                                    <item source="#{ $sourcenoteid }">
                                        <ref target="http://www.isni.org/isni/{ $isniiddatafield/marc:subfield[@code='0']/text()[1] }">
                                            <title>ISNI</title>
                                        </ref>
                                    </item>
                                </xsl:when>
                                <xsl:when test="$isniiddatafield/marc:subfield[@code = 'a']/text()[1] = 'provisional'">
                                    <xsl:comment>Provisional ISNI ID as of <xsl:value-of select="$today"/>: <xsl:value-of select="$isniiddatafield/marc:subfield[@code = '0']/text()[1]"/></xsl:comment>
                                </xsl:when>
                                <xsl:when test="$isniiddatafield/marc:subfield[@code = 'a']/text()[1] = 'suspect'">
                                    <xsl:comment>Suspect ISNI ID as of <xsl:value-of select="$today"/>: <xsl:value-of select="$isniiddatafield/marc:subfield[@code = '0']/text()[1]"/></xsl:comment>
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
        <xsl:if test="not(preceding-sibling::processing-instruction('xml-model'))">
            <xsl:value-of select="$newline"/>
        </xsl:if>
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
    <xsl:template match="/TEI/text/body/(listPerson | listOrg)/(person | org)[@xml:id]/note/list">
        <xsl:variable as="xs:string*" name="viafurls" select="item/ref[title/text()[1] = 'VIAF']/@target"/>
        <xsl:variable as="xs:string*" name="viafids" select="
                for $url in $viafurls
                return
                    tokenize($url, '/')[string-length(.) gt 0][position() eq last()]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="(* | comment() | text() | processing-instruction())[not(self::comment()[matches(., '^(Provisional ISNI ID|No match found in ISNI|Suspect ISNI ID|Unexpected ISNI API|Multiple matches found in ISNI)')])]"/>
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
    <xsl:template match="text() | comment() | processing-instruction()">
        <xsl:copy/>
    </xsl:template>
</xsl:stylesheet>
