<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:ns0="http://viaf.org/viaf/abandonedViafRecord"
    xmlns:ns1="http://viaf.org/viaf/terms#"
    xmlns:thread="java.lang.Thread"
    xmlns:local="/"
    xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs map tei ns0 ns1 thread local"
    version="3.0">
    
    <!-- REQUIRES SAXON-PE OR SAXON-EE SO RUN INSIDE OXYGEN'S EDITOR XSLT DEBUGGER.
         DISABLE EXPAND ATTRIBUTE DEFAULTS, SHOW XSL:RESULT-DOCUMENT OUTPUT AND 
         INFINITE LOOP DETECTION IN THE PREFERENCES BEFORE RUNNING. -->
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

    <xsl:variable name="localcachepath" as="xs:string" select="'/tmp/viaf/'"/>
    <xsl:variable name="newline" as="xs:string" select="'&#10;'"/>
    <xsl:variable name="today" as="xs:string" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
    <xsl:variable name="sourcenoteid" as="xs:string" select="concat('VL', count(/TEI/teiHeader/fileDesc/notesStmt[1]/note[starts-with(@xml:id, 'VL')])+1)"/>

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
            <note xml:id="{ $sourcenoteid }">Elements with source attributes of "#<xsl:value-of select="$sourcenoteid"/>" were retrieved from VIAF by lookup-viaf-info.xsl on <xsl:value-of select="$today"/></note>
        </xsl:copy>
    </xsl:template>
    
    <!-- Entries which already have VIAF links -->
    
    <xsl:template match="/TEI/text/body/(listPerson|listOrg)/(person|org)[exists(note/list/item/tei:ref[contains(@target, 'viaf.org')])]">
        <xsl:variable name="viafurls" as="xs:string*" select="for $target in note/list/item/tei:ref[contains(@target, 'viaf.org')]/@target return normalize-space($target/string())"/>
        <xsl:variable name="viafapiurls" as="xs:string*" select="for $url in $viafurls return if (ends-with($url, '/')) then concat($url, 'viaf.xml') else concat($url, '/viaf.xml')"/>
        <xsl:variable name="viafdocs" as="document-node()*" select="for $url in $viafapiurls return local:lookupVIAF($url)"/>
        <xsl:for-each select="$viafapiurls">
            <xsl:variable name="pos" as="xs:integer" select="position()"/>
            <!-- Store a local cached copy of the VIAF documents returned from their API (which has to be done here because of XSLT technicalities) -->
            <xsl:variable name="url" as="xs:string" select="."/>
            <xsl:variable name="cachefilepath" as="xs:string" select="concat($localcachepath, encode-for-uri(substring-after($url, '://')))"/>
            <xsl:if test="not(local:fileExists($cachefilepath))">
                <xsl:result-document href="{ $cachefilepath }" method="xml" encoding="UTF-8" indent="yes">
                    <xsl:copy-of select="$viafdocs[position() eq $pos]"/>
                </xsl:result-document>
            </xsl:if>
        </xsl:for-each>
        <xsl:variable name="viafids" as="xs:string*" select="distinct-values(for $viafdoc in $viafdocs return normalize-space($viafdoc/ns1:VIAFCluster/ns1:viafID[1]/string()))"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each select="$viafids">
                <xsl:variable name="viafid" as="xs:string" select="."/>
                <xsl:if test="not(some $url in $viafurls satisfies contains($url, $viafid))">
                    <!-- The API has redirected to a new VIAF ID, so add comment for double-checking -->
                    <xsl:value-of select="$newline"/>
                    <xsl:comment> ***** Old VIAF ID now redirects to <xsl:value-of select="$viafid"/> ***** </xsl:comment>
                </xsl:if>
            </xsl:for-each>
            <xsl:if test="not(exists(birth) or exists(death) or exists(floruit))">
                <xsl:call-template name="local:addDates">
                    <xsl:with-param name="viafdocs" select="$viafdocs"/>
                </xsl:call-template>
            </xsl:if>
            <xsl:variable name="viafdocids" as="xs:string*" select="distinct-values(for $viafdoc in $viafdocs return $viafdoc/ns1:VIAFCluster/ns1:viafID[1]/string())"/>
            <xsl:variable name="dedupedviafdocs" as="document-node()*" select="for $viafdocid in $viafdocids return $viafdocs[ns1:VIAFCluster/ns1:viafID[1]/string() = $viafdocid][1]"/>
            <xsl:apply-templates>
                <xsl:with-param name="viafdocs" as="document-node()*" select="$dedupedviafdocs"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <!-- Entries which do not have a VIAF links but are in the section for VIAF-based entries, so their IDs should be based on VIAF numbers -->
    
    <xsl:template match="/TEI/text/body/(listPerson|listOrg)[@type='VIAF']/(person|org)[not(exists(note/list/item/tei:ref[contains(@target, 'viaf.org')]))]">
        <xsl:variable name="viafapiurl" as="xs:string" select="
            if (self::org) then 
                concat('http://viaf.org/viaf/', substring-after(@xml:id/string(), 'org_'), '/viaf.xml')
            else
                concat('http://viaf.org/viaf/', substring-after(@xml:id/string(), 'person_'), '/viaf.xml')
            "/>
        <xsl:variable name="viafdocs" as="document-node()*" select="local:lookupVIAF($viafapiurl)"/>
        <!-- Store a local cached copy of the VIAF document returned from their API -->
        <xsl:variable name="cachefilepath" as="xs:string" select="concat($localcachepath, encode-for-uri(substring-after($viafapiurl, '://')))"/>
        <xsl:if test="not(local:fileExists($cachefilepath))">
            <xsl:result-document href="{ $cachefilepath }" method="xml" encoding="UTF-8" indent="yes">
                <xsl:copy-of select="$viafdocs[1]"/>
            </xsl:result-document>
        </xsl:if>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:variable name="viafid" as="xs:string" select="normalize-space($viafdocs[1]/ns1:VIAFCluster/ns1:viafID[1]/string())"/>
            <xsl:if test="not(contains($viafapiurl, $viafid))">
                <!-- The API has redirected to a new VIAF ID, so add comment for double-checking -->
                <xsl:value-of select="$newline"/>
                <xsl:comment> ***** Old VIAF ID now redirects to <xsl:value-of select="$viafid"/> ***** </xsl:comment>
            </xsl:if>
            <xsl:if test="not(exists(birth) or exists(death) or exists(floruit))">
                <xsl:call-template name="local:addDates">
                    <xsl:with-param name="viafdocs" select="$viafdocs"/>
                </xsl:call-template>
            </xsl:if>
            <xsl:apply-templates>
                <xsl:with-param name="viafdocs" as="document-node()*" select="$viafdocs"/>
            </xsl:apply-templates>
            <xsl:if test="count($viafdocs) gt 0 and not(exists(note/list[@type='links' or parent::note/@type='links']))">
                <note type="links">
                    <list type="links">
                        <xsl:call-template name="local:InsertLinks">
                            <xsl:with-param name="viafdocs" select="$viafdocs"/>
                        </xsl:call-template>
                    </list>
                </note>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <!-- Insert links -->
    
    <xsl:template match="(person|org)/note/list[@type='links' or parent::note/@type='links']">
        <xsl:param name="viafdocs" as="document-node()*"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <xsl:call-template name="local:InsertLinks">
                <xsl:with-param name="viafdocs" select="$viafdocs"/>
                <xsl:with-param name="currentlinks" select="item/ref"/>
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>
    
    <!-- Default templates -->
    
    <xsl:template match="*">
        <xsl:param name="viafdocs" as="document-node()*"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates>
                <xsl:with-param name="viafdocs" as="document-node()*" select="$viafdocs"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="text()|comment()|processing-instruction()">
        <xsl:copy/>
    </xsl:template>
    
    <!-- Functions and named templates -->
    
    <xsl:function name="local:fileExists" as="xs:boolean">
        <xsl:param name="localcachepath" as="xs:string"/>
        <xsl:try>
            <xsl:variable name="dummy" select="unparsed-text($localcachepath)"/>
            <xsl:copy-of select="true()"/>
            <xsl:catch>
                <xsl:copy-of select="false()"/>
            </xsl:catch>
        </xsl:try>
    </xsl:function>
    
    <xsl:function name="local:lookupVIAF" as="document-node()*">
        <xsl:param name="url" as="xs:string"/>
        <xsl:variable name="localcachepath" as="xs:string" select="concat($localcachepath, encode-for-uri(substring-after($url, '://')))"/>
        <xsl:variable name="tries" as="xs:integer" select="0"/>
        <xsl:copy-of select="local:lookupVIAF($url, $localcachepath, $tries)"/>
    </xsl:function>
    
    <xsl:function name="local:lookupVIAF" as="document-node()*">
        <xsl:param name="url" as="xs:string"/>
        <xsl:param name="localcachepath" as="xs:string"/>
        <xsl:param name="tries" as="xs:integer"/>
        <xsl:variable name="apiresponse" as="document-node()*">
            <xsl:try>
                <!-- First try loading from a local cached copy if it exists -->
                <xsl:copy-of select="doc($localcachepath)"/>
                <xsl:catch>
                    <xsl:try>
                        <!-- Next line is a hack to pause to save DoS'ing VIAF's API. This only works when run inside Oxygen XML editor -->
                        <xsl:variable name="dummy" select="thread:sleep(2000)"/>
                        <!-- Send API request to VIAF -->
                        <xsl:copy-of select="doc($url)"/>
                        <xsl:catch>
                            <!-- VIAF returns 404 and no body when the ID in the URL does not exist in VIAF -->
                            <xsl:message>No match for <xsl:value-of select="$url"/> returned by VIAF</xsl:message>
                        </xsl:catch>
                    </xsl:try>
                </xsl:catch>
            </xsl:try>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$tries eq 5"></xsl:when>
            <xsl:when test="exists($apiresponse/ns0:abandoned_viaf_record)">
                <!-- Try to retrieve the new record when a VIAF ID has been abandoned because it is a duplicate (do up to 5 tries) -->
                <xsl:variable name="newid" as="xs:string*" select="($apiresponse/ns0:abandoned_viaf_record/ns0:redirect/ns0:directto/string())[string-length(.) gt 0]"/>
                <xsl:choose>
                    <xsl:when test="count($newid) eq 1">
                        <xsl:copy-of select="local:lookupVIAF(concat('http://viaf.org/viaf/', $newid, '/viaf.xml'), $localcachepath, $tries+1)"/>
                    </xsl:when>
                    <xsl:when test="count($newid) gt 1">
                        <xsl:message><xsl:value-of select="$url"/> is defunct and has multiple replacements</xsl:message>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message><xsl:value-of select="$url"/> is defunct and has no replacement</xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- Return VIAF XML doc --> 
                <xsl:copy-of select="$apiresponse"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template name="local:InsertLinks">
        <xsl:param name="viafdocs" as="document-node()*"/>
        <xsl:param name="currentlinks" as="element(ref)*" select="()"/>
        <xsl:variable name="viafids" as="xs:string*" select="for $viafid in $viafdocs/ns1:VIAFCluster/ns1:viafID return normalize-space($viafid/string())"/>
        <xsl:variable name="newlinkids" as="map(xs:string, xs:string*)">
            <xsl:map>
                <xsl:map-entry key="'VIAF'" select="$viafids"/> 
                <xsl:for-each-group select="$viafdocs/ns1:VIAFCluster/ns1:sources/ns1:source" group-by="tokenize(string(), '\|')[1]">
                    <xsl:variable name="key" as="xs:string">
                        <xsl:choose>
                            <xsl:when test="current-grouping-key() eq 'DNB'">GND</xsl:when>
                            <xsl:when test="current-grouping-key() eq 'WKP'">Wikidata</xsl:when>
                            <xsl:otherwise><xsl:value-of select="current-grouping-key()"/></xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:map-entry key="$key" select="for $source in current-group() return replace(tokenize(string($source), '\|')[2], '\s', '')"/>
                </xsl:for-each-group>
            </xsl:map>
        </xsl:variable>
        <xsl:for-each select="map:keys($newlinkids)">
            <xsl:variable name="newlinkkey" as="xs:string" select="."/>
            <xsl:for-each select="$newlinkids($newlinkkey)">
                <xsl:variable name="newlinkid" as="xs:string" select="."/>
                <xsl:if test="not(some $currentlink in $currentlinks satisfies (normalize-space($currentlink/title/string()) = $newlinkkey and contains($currentlink/@target/string(), $newlinkid)))">
                            <xsl:choose>
                                <xsl:when test="$newlinkkey eq 'VIAF'">
                                    <item source="#{ $sourcenoteid }">
                                        <ref>
                                            <xsl:attribute name="target">
                                                <xsl:text>https://viaf.org/viaf/</xsl:text>
                                                <xsl:value-of select="$newlinkid"/>
                                            </xsl:attribute>
                                            <title>VIAF</title>
                                        </ref>
                                    </item>
                                </xsl:when>
                                <xsl:when test="$newlinkkey eq 'ISNI'">
                                    <item source="#{ $sourcenoteid }">
                                        <ref>
                                            <xsl:attribute name="target">
                                                <xsl:text>http://www.isni.org/isni/</xsl:text>
                                                <xsl:value-of select="$newlinkid"/>
                                            </xsl:attribute>
                                            <title>ISNI</title>
                                        </ref>
                                    </item>
                                </xsl:when>
                                <xsl:when test="$newlinkkey eq 'LC'">
                                    <item source="#{ $sourcenoteid }">
                                        <ref>
                                            <xsl:attribute name="target">
                                                <xsl:text>http://id.loc.gov/authorities/names/</xsl:text>
                                                <xsl:value-of select="$newlinkid"/>
                                            </xsl:attribute>
                                            <title>LC</title>
                                        </ref>
                                    </item>
                                </xsl:when>
                                <xsl:when test="$newlinkkey eq 'BNF'">
                                    <item source="#{ $sourcenoteid }">
                                        <ref>
                                            <xsl:attribute name="target">
                                                <xsl:text>https://catalogue.bnf.fr/ark:/12148/cb</xsl:text>
                                                <xsl:value-of select="$newlinkid"/>
                                                <!-- For some reason, VIAF stores the BnF authority record ID without the check digit needed 
                                                     for their ARKs to resolve, so that needs to be calculated using the standard NOID algorithm -->
                                                <xsl:value-of select="local:calculateCheckDigit(concat('cb', $newlinkid))"/>
                                            </xsl:attribute>
                                            <title>BNF</title>
                                        </ref>
                                    </item>
                                </xsl:when>
                                <xsl:when test="$newlinkkey eq 'GND'">
                                    <item source="#{ $sourcenoteid }">
                                        <ref>
                                            <xsl:attribute name="target">
                                                <xsl:text>https://d-nb.info/gnd/</xsl:text>
                                                <xsl:value-of select="$newlinkid"/>
                                            </xsl:attribute>
                                            <title>GND</title>
                                        </ref>
                                    </item>
                                </xsl:when>
                                <xsl:when test="$newlinkkey eq 'Wikidata'">
                                    <item source="#{ $sourcenoteid }">
                                        <ref>
                                            <xsl:attribute name="target">
                                                <xsl:text>https://www.wikidata.org/wiki/</xsl:text>
                                                <xsl:value-of select="$newlinkid"/>
                                            </xsl:attribute>
                                            <title>Wikidata</title>
                                        </ref>
                                    </item>
                                </xsl:when>
                            </xsl:choose>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:function name="local:calculateCheckDigit" as="xs:string">
        <xsl:param name="baseid" as="xs:string"/>
        <xsl:variable name="charmap" as="map(xs:string, xs:integer)">
            <xsl:map>
                <xsl:map-entry key="'0'" select="0"/>
                <xsl:map-entry key="'1'" select="1"/>
                <xsl:map-entry key="'2'" select="2"/>
                <xsl:map-entry key="'3'" select="3"/>
                <xsl:map-entry key="'4'" select="4"/>
                <xsl:map-entry key="'5'" select="5"/>
                <xsl:map-entry key="'6'" select="6"/>
                <xsl:map-entry key="'7'" select="7"/>
                <xsl:map-entry key="'8'" select="8"/>
                <xsl:map-entry key="'9'" select="9"/>
                <xsl:map-entry key="'b'" select="10"/>
                <xsl:map-entry key="'c'" select="11"/>
                <xsl:map-entry key="'d'" select="12"/>
                <xsl:map-entry key="'f'" select="13"/>
                <xsl:map-entry key="'g'" select="14"/>
                <xsl:map-entry key="'h'" select="15"/>
                <xsl:map-entry key="'j'" select="16"/>
                <xsl:map-entry key="'k'" select="17"/>
                <xsl:map-entry key="'m'" select="18"/>
                <xsl:map-entry key="'n'" select="19"/>
                <xsl:map-entry key="'p'" select="20"/>
                <xsl:map-entry key="'q'" select="21"/>
                <xsl:map-entry key="'r'" select="22"/>
                <xsl:map-entry key="'s'" select="23"/>
                <xsl:map-entry key="'t'" select="24"/>
                <xsl:map-entry key="'v'" select="25"/>
                <xsl:map-entry key="'w'" select="26"/>
                <xsl:map-entry key="'x'" select="27"/>
                <xsl:map-entry key="'z'" select="28"/>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="reversecharmap" as="map(xs:integer, xs:string)">
            <xsl:map>
                <xsl:for-each select="map:keys($charmap)">
                    <xsl:map-entry key="$charmap(.)" select="."/>
                </xsl:for-each>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="sequenceofchars" as="xs:string*" select="for $x in string-to-codepoints($baseid) return codepoints-to-string($x)"/>
        <xsl:variable name="charvals" as="xs:integer*">
            <xsl:for-each select="$sequenceofchars">
                <xsl:value-of select="($charmap(.), 0)[1] * position()"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="ordinalofcheckdigit" as="xs:integer" select="sum($charvals) mod 29"/>
        <xsl:value-of select="$reversecharmap($ordinalofcheckdigit)"/>
    </xsl:function>
    
    <xsl:template name="local:addDates">
        <xsl:param name="viafdocs" as="document-node()*"/>
        <xsl:for-each select="$viafdocs/ns1:VIAFCluster/ns1:birthDate[following-sibling::ns1:dateType[1]/text() = 'lived'][1]">
            <xsl:variable name="year" as="xs:string" select="normalize-space(string(.))"/>
            <xsl:if test="not($year eq '0' or $year eq '')">
                <birth source="#{ $sourcenoteid }" when="{ $year }"/>
            </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="$viafdocs/ns1:VIAFCluster/ns1:deathDate[following-sibling::ns1:dateType[1]/text() = 'lived'][1]">
            <xsl:variable name="year" as="xs:string" select="normalize-space(string(.))"/>
            <xsl:if test="not($year eq '0' or $year eq '')">
                <death source="#{ $sourcenoteid }" when="{ $year }"/>
            </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="$viafdocs/ns1:VIAFCluster/ns1:birthDate[following-sibling::ns1:dateType[1]/text() = 'flourished']">
            <xsl:variable name="fromyear" as="xs:string" select="normalize-space(string(.))"/>
            <xsl:variable name="toyear" as="xs:string" select="normalize-space(following-sibling::ns1:deathDate[1]/string())"/>
            <xsl:if test="not($fromyear eq '0' or $fromyear eq '') and not($toyear eq '0' or $toyear eq '')">
                <floruit source="#{ $sourcenoteid }" notBefore="{ $fromyear }" notAfter="{ $toyear }"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>