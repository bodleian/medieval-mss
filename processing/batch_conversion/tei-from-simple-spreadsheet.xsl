<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:local="/"
    exclude-result-prefixes="xs local tei map"
    version="3.0">

    <!-- Created for Jesus College records. Could be used for other uses in the future, but will probably
         require some modification to account for different columns.
         
         Splitting authors and titles into separate columns, instead of being comma-separated in a single
         "Content summary" one, would avoid ambiguity and allow mutliple authors per work.
         
         Pipe symbols separate values for mutliple parts in composite manuscripts. For a full explanation of 
         all the encodings of multiple values, see the comments here: https://github.com/bodleian/medieval-mss/issues/199
                  
         To run, convert the spreadsheet to a tab-separated-value text file, and specify that as a parameter, e.g.:
    
         java -Xmx1G -cp ../saxon/saxon9he.jar net.sf.saxon.Transform -it:Main -xsl:tei-from-simple-spreadsheet.xsl infile=./jesus_college_metadata.tsv nextmsid=10550
          
         Optionally, you can also specify the Solr server for a Digital Bodleian instance to attempt to lookup 
         shelfmarks against UUIDs, and create surrogates links for any it finds.
    -->
    
    <!-- Parameters -->
    <xsl:param name="infile" as="xs:string" required="yes"/>
    <xsl:param name="nextmsid" as="xs:integer" required="yes"/>
    <xsl:param name="digbodsolr" as="xs:anyURI?" required="no"/>
    
    <!-- Lookup languages (tailor list to what is in each spreadsheet) -->
    <xsl:variable name="iso639codes" as="map(xs:string, xs:string)">
        <xsl:map>
            <xsl:map-entry key="'Latin'" select="'la'"/>
            <xsl:map-entry key="'English'" select="'en'"/>
            <xsl:map-entry key="'French'" select="'fr'"/>
            <xsl:map-entry key="'Welsh'" select="'cy'"/>
            <xsl:map-entry key="'Arabic'" select="'ar'"/>
            <xsl:map-entry key="'Hebrew'" select="'he'"/>
            <!-- Add more if using for another college -->
        </xsl:map>
    </xsl:variable>
    
    <xsl:variable name="digbodquery" as="xs:string">/solr/digital_bodleian_production/select?fl=full_shelfmark_s,object_id,completeness_s&amp;fq=collections_id_sm:jesus&amp;q=*:*&amp;wt=xml&amp;rows=1000</xsl:variable>
    
    <!-- Query Digital Bodleian's Solr for UUIDs -->
    <xsl:variable name="digbodresults" as="element(result)?" select="if ($digbodsolr) then document(concat($digbodsolr, $digbodquery))/response/result else ()"/>

    <!-- Load the local places authority file -->
    <xsl:variable name="authorityplaces" as="element(tei:place)*" select="document('../../places.xml')//tei:place[@xml:id]"/>

    <!-- Call this template to loop thru records to be created -->
    <xsl:template name="Main">
        <xsl:for-each select="tokenize(unparsed-text($infile, 'utf-8'), '\r?\n')">
            <xsl:if test="position() gt 1 and string-length(.) gt 0">
                <!-- After skipping the header on line 1, each line represents a new TEI record to be created -->
                <xsl:call-template name="CreateTEI">
                    <xsl:with-param name="fields" as="xs:string*" select="for $f in tokenize(., '\t') return normalize-space($f)"/>
                    <xsl:with-param name="msid" select="$nextmsid + position() - 2"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <!-- The template for the TEI file -->
    <xsl:template name="CreateTEI">
        <xsl:param name="fields" as="xs:string*" required="yes"/>
        <xsl:param name="msid" as="xs:integer" required="yes"/>
        
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
        <xsl:variable name="catalogueimage" as="xs:string" select="concat('jes', if ($shelfmarknum lt 10) then '000' else if ($shelfmarknum lt 100) then '00' else if ($shelfmarknum lt 1000) then '0' else '', $shelfmarknum, '.png')"/>
        
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
                            <availability>
                                <licence target="https://creativecommons.org/publicdomain/zero/1.0/">This summary description is released under a CC0 licence.</licence>
                                <licence target="https://creativecommons.org/share-your-work/public-domain/pdm/">The text of H. O. Coxe, <title>Catalogus codicum mss. qui in collegiis aulisque Oxoniensibus hodie adservantur</title>, is free of known copyright restrictions.</licence>
                            </availability>
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
                                            <xsl:call-template name="AddTextLang">
                                                <xsl:with-param name="languages" select="$languages"/>
                                            </xsl:call-template>
                                            <xsl:variable name="works" as="xs:string*" select="tokenize($parts[1], ';')"/>
                                            <xsl:for-each select="$works">
                                                <xsl:call-template name="AddWork">
                                                    <xsl:with-param name="worknum" select="position()"/>
                                                    <xsl:with-param name="workdetails" select="tokenize(normalize-space(.), ',')"/>
                                                    <xsl:with-param name="idprefix" select="$filename"/>
                                                </xsl:call-template>
                                            </xsl:for-each>
                                        </msContents>
                                        <xsl:call-template name="AddPhysDesc">
                                            <xsl:with-param name="format" select="$format"/>
                                            <xsl:with-param name="support" select="$support"/>
                                            <xsl:with-param name="decoration" select="$decoration"/>
                                        </xsl:call-template>
                                        <xsl:call-template name="AddHistory">
                                            <xsl:with-param name="date" select="$date"/>
                                            <xsl:with-param name="origin" select="$origin"/>
                                        </xsl:call-template>
                                        <xsl:call-template name="InsertAdditional">
                                            <xsl:with-param name="decoration" select="$decoration"/>
                                            <xsl:with-param name="catalogueimage" select="$catalogueimage"/>
                                            <xsl:with-param name="shelfmark" select="$shelfmark"/>
                                        </xsl:call-template>
                                    </xsl:when>
                                    <xsl:when test="count($parts) gt 1">
                                        <!-- This is a composite manuscript -->
                                        
                                        <!-- TEI schema requires additional element comes before msPart -->
                                        <xsl:call-template name="InsertAdditional">
                                            <xsl:with-param name="decoration" select="$decoration"/>
                                            <xsl:with-param name="catalogueimage" select="$catalogueimage"/>
                                            <xsl:with-param name="shelfmark" select="$shelfmark"/>
                                        </xsl:call-template>
                                        
                                        <xsl:for-each select="$parts">
                                            <xsl:variable name="partnum" as="xs:integer" select="position()"/>
                                            <xsl:variable name="partworks" as="xs:string" select="tokenize(normalize-space(.), ';')"/>
                                            <xsl:variable name="partlanguages" as="xs:string" select="normalize-space(tokenize($languages, '\|')[$partnum])"/>
                                            <xsl:variable name="partformat" as="xs:string" select="normalize-space(tokenize($format, '\|')[$partnum])"/>
                                            <xsl:variable name="partsupport" as="xs:string" select="normalize-space(tokenize($support, '\|')[$partnum])"/>
                                            <xsl:variable name="partlanguage" as="xs:string" select="normalize-space(tokenize($languages, '\|')[$partnum])"/>
                                            <xsl:variable name="partdecoration" as="xs:string" select="normalize-space(tokenize($decoration, '\|')[$partnum])"/>
                                            <xsl:variable name="partdate" as="xs:string" select="normalize-space(tokenize($date, '\|')[$partnum])"/>
                                            <xsl:variable name="partorigin" as="xs:string" select="normalize-space(tokenize($origin, '\|')[$partnum])"/>
                                            
                                            <msPart xml:id="{ $filename }-part{ $partnum }" n="{ $partnum }">
                                                <msIdentifier>
                                                    <altIdentifier type="partial">
                                                        <idno type="part">
                                                            <xsl:value-of select="$shelfmark"/>
                                                            <xsl:text> - Part </xsl:text>
                                                            <xsl:value-of select="$partnum"/>
                                                        </idno>
                                                    </altIdentifier>
                                                </msIdentifier>
                                                <msContents>
                                                    <xsl:call-template name="AddTextLang">
                                                        <xsl:with-param name="languages" select="$partlanguages"/>
                                                    </xsl:call-template>
                                                    <xsl:for-each select="$partworks">
                                                        <xsl:call-template name="AddWork">
                                                            <xsl:with-param name="worknum" select="position()"/>
                                                            <xsl:with-param name="workdetails" select="tokenize(normalize-space(.), ',')"/>
                                                            <xsl:with-param name="idprefix" select="concat($filename, '-part', $partnum)"/>
                                                        </xsl:call-template>
                                                    </xsl:for-each>
                                                </msContents>
                                                <xsl:call-template name="AddPhysDesc">
                                                    <xsl:with-param name="format" select="$partformat"/>
                                                    <xsl:with-param name="support" select="$partsupport"/>
                                                    <xsl:with-param name="decoration" select="$partdecoration"/>
                                                </xsl:call-template>
                                                <xsl:call-template name="AddHistory">
                                                    <xsl:with-param name="date" select="$partdate"/>
                                                    <xsl:with-param name="origin" select="$partorigin"/>
                                                </xsl:call-template> 
                                            </msPart>
                                        </xsl:for-each>
                                    </xsl:when>
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
    
    <xsl:template name="AddWork" as="element(tei:msItem)">
        <xsl:param name="worknum" as="xs:integer" required="yes"/>
        <xsl:param name="workdetails" as="xs:string*" required="yes"/>
        <xsl:param name="idprefix" as="xs:string" required="yes"/>
        <xsl:variable name="author" as="xs:string" select="if (count($workdetails) gt 1) then $workdetails[1] else ''"/>
        <xsl:variable name="title" as="xs:string" select="if (count($workdetails) gt 1) then string-join($workdetails[position() gt 1], ',') else $workdetails[1]"/>
        <msItem xml:id="{ $idprefix }-item{ $worknum }" n="{ $worknum }">
            <xsl:if test="string-length($author) gt 0">
                <author>
                    <xsl:value-of select="normalize-space($author)"/>
                </author>
            </xsl:if>
            <title>
                <xsl:value-of select="normalize-space($title)"/>
            </title>
        </msItem>
    </xsl:template>
    
    <xsl:template name="AddTextLang" as="element(tei:textLang)">
        <xsl:param name="languages" as="xs:string" required="yes"/>
        <xsl:variable name="langcodes" as="xs:string*" select="local:lookupLanguages($languages)"/>
        <textLang mainLang="{ $langcodes[1] }">
            <xsl:if test="count($langcodes) gt 1">
                <xsl:attribute name="otherLangs" select="string-join($langcodes[position() gt 1], ' ')"/>
            </xsl:if>
            <xsl:value-of select="$languages"/>
        </textLang>
    </xsl:template>
    
    <xsl:function name="local:lookupLanguages" as="xs:string*">
        <xsl:param name="languages" as="xs:string"/>
        <xsl:for-each select="for $l in tokenize($languages, ';') return normalize-space($l)">
            <xsl:value-of select="map:get($iso639codes, .)"/>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:template name="AddPhysDesc" as="element(tei:physDesc)">
        <xsl:param name="format" as="xs:string" required="yes"/>
        <xsl:param name="support" as="xs:string" required="yes"/>
        <xsl:param name="decoration" as="xs:string" required="yes"/>
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
            <xsl:if test="string-length($decoration) gt 0">
                <decoDesc>
                    <decoNote>
                        <xsl:value-of select="$decoration"/>
                    </decoNote>
                </decoDesc>
            </xsl:if>
        </physDesc>
    </xsl:template>
    
    <xsl:template name="AddHistory" as="element(tei:history)">
        <xsl:param name="date" as="xs:string" required="yes"/>
        <xsl:param name="origin" as="xs:string" required="yes"/>
        <history>
            <origin>
                <xsl:choose>
                    <xsl:when test="string-length($date) gt 0">
                        <!-- Calculate notBefore and noAfter years from dates in the form "Nth century"
                         optionally followed by ", early" or ", late". Ranges of centuries are also possible.
                         The following only works for 2nd century CE onwards, which is sufficient for 
                         Jesus College's collection -->
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
                        <xsl:variable name="notbefore" as="xs:string" select="if (min($years) lt 1000) then concat('0',min($years)) else string(min($years))"/>
                        <xsl:variable name="notafter" as="xs:string" select="if (max($years) lt 1000) then concat('0',max($years)) else string(max($years))"/>
                        <origDate notBefore="{ $notbefore }" notAfter="{ $notafter }" calendar="Gregorian">
                            <xsl:value-of select="$date"/>
                        </origDate>
                    </xsl:when>
                    <xsl:otherwise>
                        <p>No date</p>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="string-length($origin) gt 0">
                    <origPlace>
                        <xsl:analyze-string select="$origin" regex="[\w\-'\.\s]+">
                            <xsl:matching-substring>
                                <xsl:variable name="placename" as="xs:string" select="normalize-space(.)"/>
                                <xsl:variable name="placeauthority" as="element(tei:place)*" select="$authorityplaces[tei:placeName/string() = $placename][1]"/>
                                <xsl:choose>
                                    <xsl:when test="not($placeauthority)">
                                        <xsl:value-of select="."/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:if test="matches(., '^\s')"><xsl:text> </xsl:text></xsl:if>
                                        <xsl:choose>
                                            <xsl:when test="$placeauthority/@type = 'country'">
                                                <country key="{ $placeauthority/@xml:id }">
                                                    <xsl:value-of select="$placename"/>
                                                </country>
                                            </xsl:when>
                                            <xsl:when test="$placeauthority/@type = 'region'">
                                                <region key="{ $placeauthority/@xml:id }">
                                                    <xsl:value-of select="$placename"/>
                                                </region>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <placeName key="{ $placeauthority/@xml:id }">
                                                    <xsl:value-of select="$placename"/>
                                                </placeName>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        <xsl:if test="matches(., '\s$')"><xsl:text> </xsl:text></xsl:if>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </origPlace>
                </xsl:if>
            </origin>
        </history>
    </xsl:template>

    <xsl:template name="InsertAdditional" as="element(tei:additional)">
        <xsl:param name="decoration" as="xs:string" required="yes"/>
        <xsl:param name="catalogueimage" as="xs:string" required="yes"/>
        <xsl:param name="shelfmark" as="xs:string" required="yes"/>
        <additional>
            <adminInfo>
                <recordHist>
                    <source>
                        <p>Summary description by Owen McKnight, based on the following sources.</p>
                        <listBibl>
                            <bibl facs="{ $catalogueimage }">H. O. Coxe, <title>Catalogus codicum mss. qui in collegiis aulisque Oxoniensibus hodie adservantur</title> (1852)</bibl>
                            <xsl:if test="string-length($decoration) gt 0">
                                <bibl>J. J. G. Alexander and Elzbieta Temple, <title><ref target="https://catalog.hathitrust.org/Record/000387352">Illuminated manuscripts in Oxford college libraries, the University Archives and the Taylor Institution</ref></title> (Oxford, 1985) [information on decoration and origin]</bibl>
                            </xsl:if>
                        </listBibl>
                    </source>
                </recordHist>
            </adminInfo>
            <xsl:variable name="digbods" as="element(doc)*" select="$digbodresults/doc[str[@name='full_shelfmark_s']/text() = $shelfmark]"/>
            <xsl:for-each select="$digbods">
                <surrogates>
                    <bibl type="digital-facsimile">
                        <xsl:attribute name="subtype" select="if (str[@name='completeness_s']/text() = 'complete') then 'full' else 'partial'"/>
                        <ref target="https://digital.bodleian.ox.ac.uk/inquire/p/{ str[@name='object_id']/text() }">
                            <title>Digital Bodleian</title>
                        </ref>
                        <note>(<xsl:value-of select="if (str[@name='completeness_s']/text() = 'complete') then 'full digital facsimile' else 'selected images only'"/>)</note>
                    </bibl>
                </surrogates>
            </xsl:for-each>
        </additional>
    </xsl:template>

</xsl:stylesheet>