<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:local="/"
    exclude-result-prefixes="xs local tei"
    version="2.0">

    <!-- Created for Jesus College records. Could be used for other uses in the future, but will probably
         require some modification to account for different columns. For an explanation of the encoding of
         multiple values, see the comments here: https://github.com/bodleian/medieval-mss/issues/199
         To run, convert the spreadsheet to a tab-separated text file first, then change filename in the next line -->
    <xsl:variable name="infile" as="xs:string">jesus_college_metadata.tsv</xsl:variable>
    
    <!-- Set the following to the current highest manuscript ID number -->
    <xsl:variable name="highestmsidnum" as="xs:integer" select="10450"/>
    
    <xsl:template name="Main">
        <xsl:for-each select="tokenize(unparsed-text($infile, 'utf-8'), '\r?\n')">
            <xsl:if test="position() gt 1 and string-length(.) gt 0">
                <!-- After skipping header, each line represents a new record to be created -->
                <xsl:call-template name="Template">
                    <xsl:with-param name="fields" as="xs:string*" select="for $f in tokenize(., '\t') return normalize-space($f)"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="Template">
        <xsl:param name="fields" as="xs:string*" required="yes"/>
        
        <xsl:variable name="shelfmark" as="xs:string" select="$fields[1]"/>
        <xsl:variable name="summary" as="xs:string" select="$fields[2]"/>
        <xsl:variable name="languages" as="xs:string" select="$fields[3]"/>
        <xsl:variable name="format" as="xs:string" select="$fields[4]"/>
        <xsl:variable name="support" as="xs:string" select="$fields[5]"/>
        <xsl:variable name="decoration" as="xs:string" select="$fields[6]"/>
        <xsl:variable name="date" as="xs:string" select="$fields[7]"/>
        <xsl:variable name="origin" as="xs:string" select="$fields[8]"/>
        
        <xsl:variable name="filename" as="xs:string" select="replace(replace($shelfmark, '\*' ,'_star'), '[^A-Za-z0-9_]+', '_')"/>
        <xsl:variable name="shelfmarknum" as="xs:integer" select="replace($shelfmark, '\D', '') cast as xs:integer"/>
        <xsl:variable name="msid" as="xs:integer" select="$highestmsidnum + $shelfmarknum"/>
        
        <xsl:variable name="parts" as="xs:string*" select="tokenize($summary, '\|')"/>
        
        <xsl:result-document href="../../collections/Jesus_College/{$filename}.xml" method="xml" encoding="UTF-8" indent="yes">
            
            <xsl:processing-instruction name="xml-model">href="https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
            <xsl:processing-instruction name="xml-model">href="https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
            <TEI xmlns="http://www.tei-c.org/ns/1.0"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xml:id="manuscript_{ $msid }">
                <teiHeader>
                    <fileDesc>
                        <titleStmt>
                            <title>
                                <xsl:value-of select="$shelfmark"/>
                            </title>
                            <title type="collection">Jesus College MSS.</title>
                            <respStmt xml:id="OM">
                                <resp when="2018">Summary description</resp>
                                <persName>Owen McKnight</persName>
                            </respStmt>
                            <respStmt xml:id="AM">
                                <resp when="2018">Markup and encoding</resp>
                                <persName>Andrew Morrison</persName>
                                <note>TEI encoding programmatically created using spreadsheet data</note>
                            </respStmt>
                        </titleStmt>
                        <editionStmt>
                            <edition>TEI P5</edition>
                        </editionStmt>
                        <publicationStmt>
                            <publisher>Special Collections, Bodleian Libraries</publisher>
                            <address>
                                <orgName type="department">Special Collections</orgName>
                                <orgName type="unit">Bodleian Libraries</orgName>
                                <orgName type="institution">University of Oxford</orgName>
                                <street>Weston Library, Broad Street</street>
                                <settlement>Oxford</settlement>
                                <postCode>OX1 3BG</postCode>
                                <country>United Kingdom</country>
                            </address>
                            <distributor>
                                <email>specialcollections.enquiries@bodleian.ox.ac.uk</email>
                            </distributor>
                            <idno type="msID">
                                <xsl:value-of select="$filename"/>
                            </idno>
                            <idno type="collection">Jesus_College_MSS</idno>
                            <idno type="catalogue">Western</idno>
                        </publicationStmt>
                        <sourceDesc>
                            <msDesc xml:lang="en" xml:id="{ $filename }">
                                <msIdentifier>
                                    <settlement>Oxford</settlement>
                                    <repository>Jesus College</repository>
                                    <idno type="shelfmark">
                                        <xsl:value-of select="$shelfmark"/>
                                    </idno>
                                </msIdentifier>
                                <xsl:choose>
                                    <xsl:when test="count($parts) eq 1">
                                        <msContents>
                                            <xsl:variable name="langcodes" as="xs:string*" select="local:lookupLanguages($languages)"/>
                                            <textLang mainLang="{ $langcodes[1] }">
                                                <xsl:if test="count($langcodes) gt 1">
                                                    <xsl:attribute name="otherLangs" select="string-join($langcodes, ' ')"/>
                                                </xsl:if>
                                                <xsl:value-of select="$languages"/>
                                            </textLang>
                                            <xsl:variable name="works" as="xs:string*" select="tokenize($parts[1], ';')"/>
                                            <xsl:for-each select="$works">
                                                <xsl:call-template name="Work">
                                                    <xsl:with-param name="worknum" select="position()"/>
                                                    <xsl:with-param name="workdetails" select="tokenize(normalize-space(.), ',')"/>
                                                    <xsl:with-param name="filename" select="$filename"/>
                                                </xsl:call-template>
                                            </xsl:for-each>
                                        </msContents>
                                        <physDesc>
                                            <objectDesc form="{ $format }">
                                                <xsl:variable name="material" as="xs:string">
                                                    <xsl:choose>
                                                        <xsl:when test="contains($support, ';')">mixed</xsl:when>
                                                        <xsl:when test="$support eq 'parchment'">perg</xsl:when>
                                                        <xsl:when test="$support eq 'paper'">paper</xsl:when>
                                                        <xsl:when test="$support eq 'chart'">chart</xsl:when>
                                                        <xsl:otherwise>unknown</xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:variable>
                                                <supportDesc material="{ $material }">
                                                    <support>
                                                        <xsl:value-of select="$support"/>
                                                    </support>
                                                </supportDesc>
                                            </objectDesc>
                                        </physDesc>
                                        <history>
                                            <origin>
                                                <xsl:variable name="years" as="xs:integer*">
                                                    <xsl:analyze-string select="$date" regex="(\d|\d\d)(st|nd|rd|th) century(, )*(early|late)*">
                                                        <xsl:matching-substring>
                                                            <xsl:variable name="centurynum" as="xs:integer" select="regex-group(1) cast as xs:integer"/>
                                                            <xsl:choose>
                                                                <xsl:when test="regex-group(4) eq 'early'">
                                                                    <xsl:value-of select="($centurynum - 1) * 100"/>
                                                                    <xsl:value-of select="(($centurynum - 1) * 100) + 10"/>
                                                                </xsl:when>
                                                                <xsl:when test="regex-group(4) eq 'late'">
                                                                    <xsl:value-of select="(($centurynum - 1) * 100) + 90"/>
                                                                    <xsl:value-of select="$centurynum * 100"/>
                                                                </xsl:when>
                                                                <xsl:otherwise>
                                                                    <xsl:value-of select="($centurynum - 1) * 100"/>
                                                                    <xsl:value-of select="$centurynum * 100"/>
                                                                </xsl:otherwise>
                                                            </xsl:choose>
                                                        </xsl:matching-substring>
                                                    </xsl:analyze-string>
                                                </xsl:variable>
                                                <origDate notBefore="{ min($years) }" notAfter="{ max($years) }" calendar="Gregorian">
                                                    <xsl:value-of select="$date"/>
                                                </origDate>
                                                <!-- TODO: origPlace -->
                                            </origin>
                                        </history>
                                        <additional>
                                            <adminInfo>
                                                <recordHist>
                                                    <source>Summary description by Owen McKnight, based on the following sources.
                                                        <listBibl>
                                                            <bibl facs="">H. O. Coxe, <title>Catalogus codicum mss. qui in collegiis aulisque Oxoniensibus hodie adservantur</title> (1852)</bibl>
                                                            <!-- the following bibl should only be given if there is decoration information -->
                                                            <!-- <bibl>J. J. G. Alexander and Elzbieta Temple, <title>Illuminated manuscripts in Oxford college libraries, the University Archives and the Taylor Institution</title> (Oxford, 1985) [information on decoration and origin]</bibl>-->
                                                        </listBibl>
                                                    </source>
                                                </recordHist>
                                            </adminInfo>
                                            <surrogates>
                                                <bibl type="digital-facsimile" subtype="full">
                                                    <ref target="___">
                                                        <title>Digital Bodleian</title>
                                                    </ref>
                                                    <note>(full digital facsimile)</note>
                                                </bibl>
                                            </surrogates>
                                        </additional>                                    
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- This is a composite manuscript -->
                                        <xsl:for-each select="$parts">
                                            <xsl:variable name="part" as="xs:string" select="normalize-space(.)"/>
                                            <xsl:variable name="partnum" as="xs:integer" select="position()"/>
                                            <xsl:variable name="partlanguage" as="xs:string" select="normalize-space(tokenize($languages, '|')[$partnum])"/>
                                            <xsl:variable name="partformat" as="xs:string" select="normalize-space(tokenize($format, '|')[$partnum])"/>
                                            <xsl:variable name="partsupport" as="xs:string" select="normalize-space(tokenize($support, '|')[$partnum])"/>
                                            <xsl:variable name="partlanguage" as="xs:string" select="normalize-space(tokenize($languages, '|')[$partnum])"/>
                                            <xsl:variable name="partdecoration" as="xs:string" select="normalize-space(tokenize($decoration, '|')[$partnum])"/>
                                            <xsl:variable name="partdate" as="xs:string" select="normalize-space(tokenize($date, '|')[$partnum])"/>
                                            <xsl:variable name="partorigin" as="xs:string" select="normalize-space(tokenize($origin, '|')[$partnum])"/>
                                            <!-- TODO -->
                                            <xsl:comment>TODO</xsl:comment>
                                        </xsl:for-each>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </msDesc>
                        </sourceDesc>
                    </fileDesc>
                    <revisionDesc>
                        <change when="{ substring(string(current-date()), 0, 11) }">Record created.</change>
                    </revisionDesc>
                </teiHeader>
                <text>
                    <body>
                        <p><!--Body paragraph provided for validation and future transcription--></p>
                    </body>
                </text>
            </TEI>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="Work">
        <xsl:param name="worknum" as="xs:integer" required="yes"/>
        <xsl:param name="workdetails" as="xs:string*" required="yes"/>
        <xsl:param name="filename" as="xs:string" required="yes"/>
        <xsl:variable name="author" as="xs:string" select="if(count($workdetails) gt 1) then $workdetails[1] else ''"/>
        <xsl:variable name="title" as="xs:string" select="if(count($workdetails) gt 1) then string-join($workdetails[position() gt 1], ',') else $workdetails[1]"/>
        <msItem xml:id="{ $filename }-item_{ $worknum }" n="{ $worknum }">
            <xsl:if test="string-length($author) gt 0">
                <author>
                    <xsl:value-of select="$author"/>
                </author>
            </xsl:if>
            <title>
                <xsl:value-of select="$title"/>
            </title>
        </msItem>
    </xsl:template>
    
    <xsl:function name="local:lookupLanguages" as="xs:string*">
        <xsl:param name="languages" as="xs:string"/>
        <xsl:for-each select="for $l in tokenize($languages, ';') return normalize-space($l)">
            <xsl:choose>
                <xsl:when test=". = 'Latin'">la</xsl:when>
                <!-- TODO -->
                <xsl:otherwise>__</xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

</xsl:stylesheet>