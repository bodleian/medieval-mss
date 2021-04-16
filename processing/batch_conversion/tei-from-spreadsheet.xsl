<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs local tei map" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:local="/" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!-- Created for Jesus College records. Could be used for other uses in the future, but will probably
         require some modification to account for different columns.
         
         Splitting authors and titles into separate columns, instead of being comma-separated in a single
         "Content summary" one, would avoid ambiguity and allow mutliple authors per work.
         
         Pipe symbols separate values for mutliple parts in composite manuscripts. For a full explanation of 
         all the encodings of multiple values, see the comments here: https://github.com/bodleian/medieval-mss/issues/199
                  
         To run, convert the spreadsheet to a tab-separated-value text file, and specify that as a parameter, e.g.:
    
         java -Xmx1G -cp ../saxon/saxon9he.jar net.sf.saxon.Transform -it:Main -xsl:tei-from-spreadsheet.xsl infile=./jesus_college_metadata.tsv nextmsid=10550
          
         Optionally, you can also specify the Solr server for a Digital Bodleian instance to attempt to lookup 
         shelfmarks against UUIDs, and create surrogates links for any it finds.
    -->
    <!-- Parameters -->
    <xsl:param as="xs:string" name="infile" required="yes"/>
    <xsl:param as="xs:integer" name="nextmsid" required="yes"/>
    <xsl:param as="xs:anyURI?" name="digbodsolr" required="no"/>
    <!-- Lookups -->
    <xsl:variable as="map(xs:string, xs:string)" name="iso639codes">
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
    <xsl:variable as="xs:string" name="digbodquery">/solr/digital_bodleian_production/select?fl=full_shelfmark_s,object_id,completeness_s&amp;fq=collections_id_sm:jesus&amp;q=*:*&amp;wt=xml&amp;rows=1000</xsl:variable>
    <!-- Query Digital Bodleian's Solr for UUIDs -->
    <xsl:variable as="element(result)?" name="digbodresults" select="
            if ($digbodsolr) then
                document(concat($digbodsolr, $digbodquery))/response/result
            else
                ()"/>
    <!-- Load the local places authority file -->
    <xsl:variable as="element(tei:place)*" name="authorityplaces" select="document('../../places.xml')//tei:place[@xml:id]"/>
    <!-- Call this template to loop thru records to be created -->
    <xsl:template name="Main">
        <xsl:for-each select="tokenize(unparsed-text($infile, 'utf-8'), '\r?\n')">
            <xsl:if test="position() gt 1 and string-length(.) gt 0">
                <!-- After skipping the header on line 1, each line represents a new TEI record to be created -->
                <xsl:call-template name="CreateTEI">
                    <xsl:with-param as="xs:string*" name="fields" select="
                            for $f in tokenize(., '\t')
                            return
                                normalize-space($f)"/>
                    <xsl:with-param name="msid" select="$nextmsid + position() - 2"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    <!-- The template for the TEI file -->
    <xsl:template name="CreateTEI">
        <xsl:param as="xs:string*" name="fields" required="yes"/>
        <xsl:param as="xs:integer" name="msid" required="yes"/>
        <xsl:variable as="xs:string" name="shelfmark" select="$fields[1]"/>
        <xsl:variable as="xs:string" name="summary" select="$fields[2]"/>
        <xsl:variable as="xs:string" name="languages" select="$fields[3]"/>
        <xsl:variable as="xs:string" name="format" select="$fields[4]"/>
        <xsl:variable as="xs:string" name="support" select="$fields[5]"/>
        <xsl:variable as="xs:string" name="decoration" select="$fields[6]"/>
        <xsl:variable as="xs:string" name="date" select="$fields[7]"/>
        <xsl:variable as="xs:string" name="origin" select="$fields[8]"/>
        <xsl:variable as="xs:string" name="filename" select="replace(replace($shelfmark, '\*', '_star'), '[^A-Za-z0-9_]+', '_')"/>
        <xsl:variable as="xs:integer" name="shelfmarknum" select="replace($shelfmark, '\D', '') cast as xs:integer"/>
        <xsl:variable as="xs:string" name="catalogueimage" select="
                concat('jes', if ($shelfmarknum lt 10) then
                    '000'
                else
                    if ($shelfmarknum lt 100) then
                        '00'
                    else
                        if ($shelfmarknum lt 1000) then
                            '0'
                        else
                            '', $shelfmarknum, '.png')"/>
        <xsl:variable as="xs:string*" name="parts" select="tokenize($summary, '\|')"/>
        <xsl:result-document encoding="UTF-8" href="../../collections/Jesus_College/{$filename}.xml" indent="yes" method="xml">
            <xsl:processing-instruction name="xml-model">href="https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
            <xsl:processing-instruction name="xml-model">href="https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
            <TEI xml:id="manuscript_{ $msid }" xmlns="http://www.tei-c.org/ns/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0">
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
                            <msDesc xml:id="{ $filename }" xml:lang="en">
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
                                            <xsl:variable as="xs:string*" name="works" select="tokenize($parts[1], ';')"/>
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
                                            <xsl:variable as="xs:integer" name="partnum" select="position()"/>
                                            <xsl:variable as="xs:string" name="partworks" select="tokenize(normalize-space(.), ';')"/>
                                            <xsl:variable as="xs:string" name="partlanguages" select="normalize-space(tokenize($languages, '\|')[$partnum])"/>
                                            <xsl:variable as="xs:string" name="partformat" select="normalize-space(tokenize($format, '\|')[$partnum])"/>
                                            <xsl:variable as="xs:string" name="partsupport" select="normalize-space(tokenize($support, '\|')[$partnum])"/>
                                            <xsl:variable as="xs:string" name="partlanguage" select="normalize-space(tokenize($languages, '\|')[$partnum])"/>
                                            <xsl:variable as="xs:string" name="partdecoration" select="normalize-space(tokenize($decoration, '\|')[$partnum])"/>
                                            <xsl:variable as="xs:string" name="partdate" select="normalize-space(tokenize($date, '\|')[$partnum])"/>
                                            <xsl:variable as="xs:string" name="partorigin" select="normalize-space(tokenize($origin, '\|')[$partnum])"/>
                                            <msPart n="{ $partnum }" xml:id="{ $filename }-part{ $partnum }">
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
    <xsl:template as="element(tei:msItem)" name="AddWork">
        <xsl:param as="xs:integer" name="worknum" required="yes"/>
        <xsl:param as="xs:string*" name="workdetails" required="yes"/>
        <xsl:param as="xs:string" name="idprefix" required="yes"/>
        <xsl:variable as="xs:string" name="author" select="
                if (count($workdetails) gt 1) then
                    $workdetails[1]
                else
                    ''"/>
        <xsl:variable as="xs:string" name="title" select="
                if (count($workdetails) gt 1) then
                    string-join($workdetails[position() gt 1], ',')
                else
                    $workdetails[1]"/>
        <msItem n="{ $worknum }" xml:id="{ $idprefix }-item{ $worknum }">
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
    <xsl:template as="element(tei:textLang)" name="AddTextLang">
        <xsl:param as="xs:string" name="languages" required="yes"/>
        <xsl:variable as="xs:string*" name="langcodes" select="local:lookupLanguages($languages)"/>
        <textLang mainLang="{ $langcodes[1] }">
            <xsl:if test="count($langcodes) gt 1">
                <xsl:attribute name="otherLangs" select="string-join($langcodes[position() gt 1], ' ')"/>
            </xsl:if>
            <xsl:value-of select="$languages"/>
        </textLang>
    </xsl:template>
    <xsl:function as="xs:string*" name="local:lookupLanguages">
        <xsl:param as="xs:string" name="languages"/>
        <xsl:for-each select="
                for $l in tokenize($languages, ';')
                return
                    normalize-space($l)">
            <xsl:value-of select="map:get($iso639codes, .)"/>
        </xsl:for-each>
    </xsl:function>
    <xsl:template as="element(tei:physDesc)" name="AddPhysDesc">
        <xsl:param as="xs:string" name="format" required="yes"/>
        <xsl:param as="xs:string" name="support" required="yes"/>
        <xsl:param as="xs:string" name="decoration" required="yes"/>
        <physDesc>
            <objectDesc form="{ $format }">
                <xsl:variable as="xs:string" name="material">
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
    <xsl:template as="element(tei:history)" name="AddHistory">
        <xsl:param as="xs:string" name="date" required="yes"/>
        <xsl:param as="xs:string" name="origin" required="yes"/>
        <history>
            <origin>
                <xsl:choose>
                    <xsl:when test="string-length($date) gt 0">
                        <!-- Calculate notBefore and noAfter years from dates in the form "Nth century"
                         optionally followed by ", early" or ", late". Ranges of centuries are also possible.
                         The following only works for 2nd century CE onwards, which is sufficient for 
                         Jesus College's collection -->
                        <xsl:variable as="xs:integer*" name="years">
                            <xsl:analyze-string regex="(\d|\d\d)(st|nd|rd|th) century(, )*(early|late)*" select="$date">
                                <xsl:matching-substring>
                                    <xsl:variable as="xs:integer" name="centurynum" select="regex-group(1) cast as xs:integer"/>
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
                        <xsl:variable as="xs:string" name="notbefore" select="
                                if (min($years) lt 1000) then
                                    concat('0', min($years))
                                else
                                    string(min($years))"/>
                        <xsl:variable as="xs:string" name="notafter" select="
                                if (max($years) lt 1000) then
                                    concat('0', max($years))
                                else
                                    string(max($years))"/>
                        <origDate calendar="Gregorian" notAfter="{ $notafter }" notBefore="{ $notbefore }">
                            <xsl:value-of select="$date"/>
                        </origDate>
                    </xsl:when>
                    <xsl:otherwise>
                        <p>No date</p>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="string-length($origin) gt 0">
                    <origPlace>
                        <xsl:analyze-string regex="[\w\-'\.\s]+" select="$origin">
                            <xsl:matching-substring>
                                <xsl:variable as="xs:string" name="placename" select="normalize-space(.)"/>
                                <xsl:variable as="element(tei:place)*" name="placeauthority" select="$authorityplaces[tei:placeName/string() = $placename][1]"/>
                                <xsl:choose>
                                    <xsl:when test="not($placeauthority)">
                                        <xsl:value-of select="."/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:if test="matches(., '^\s')">
                                            <xsl:text> </xsl:text>
                                        </xsl:if>
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
                                        <xsl:if test="matches(., '\s$')">
                                            <xsl:text> </xsl:text>
                                        </xsl:if>
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
    <xsl:template as="element(tei:additional)" name="InsertAdditional">
        <xsl:param as="xs:string" name="decoration" required="yes"/>
        <xsl:param as="xs:string" name="catalogueimage" required="yes"/>
        <xsl:param as="xs:string" name="shelfmark" required="yes"/>
        <additional>
            <adminInfo>
                <recordHist>
                    <source>
                        <p>Summary description by Owen McKnight, based on the following sources.</p>
                        <listBibl>
                            <bibl facs="{ $catalogueimage }">H. O. Coxe, <title>Catalogus codicum mss. qui in collegiis aulisque Oxoniensibus hodie adservantur</title> (1852)</bibl>
                            <xsl:if test="string-length($decoration) gt 0">
                                <bibl>J. J. G. Alexander and Elzbieta Temple, <title>Illuminated manuscripts in Oxford college libraries, the University Archives and the Taylor Institution</title> (Oxford, 1985) [information on decoration and origin]</bibl>
                            </xsl:if>
                        </listBibl>
                    </source>
                </recordHist>
            </adminInfo>
            <xsl:variable as="element(doc)*" name="digbods" select="$digbodresults/doc[str[@name = 'full_shelfmark_s']/text() = $shelfmark]"/>
            <xsl:for-each select="$digbods">
                <surrogates>
                    <bibl type="digital-facsimile">
                        <xsl:attribute name="subtype" select="
                                if (str[@name = 'completeness_s']/text() = 'complete') then
                                    'full'
                                else
                                    'partial'"/>
                        <ref target="https://digital.bodleian.ox.ac.uk/inquire/p/{ str[@name='object_id']/text() }">
                            <title>Digital Bodleian</title>
                        </ref>
                        <note>(<xsl:value-of select="
                                    if (str[@name = 'completeness_s']/text() = 'complete') then
                                        'full digital facsimile'
                                    else
                                        'selected images only'"/>)</note>
                    </bibl>
                </surrogates>
            </xsl:for-each>
        </additional>
    </xsl:template>
</xsl:stylesheet>
