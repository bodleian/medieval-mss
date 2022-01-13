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

    <!-- Created for University College records, which are more complex than Jesus ones.
         
         To run, convert the spreadsheet to a tab-separated-value text file and specify that as a parameter, along with the next available manuscript_ number, e.g.:
    
         java -Xmx1G -cp ../saxon/saxon9he.jar net.sf.saxon.Transform -it:Main -xsl:tei-from-complex-spreadsheet.xsl infile=./university_college_metadata.tsv nextmsid=13000
          
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
            <xsl:map-entry key="'Middle English'" select="'enm'"/>
            <xsl:map-entry key="'French'" select="'fr'"/>
            <xsl:map-entry key="'Greek'" select="'el'"/>
            <xsl:map-entry key="'English'" select="'en'"/>
            <xsl:map-entry key="'Italian'" select="'it'"/>
            <!-- Add more if using for another college -->
        </xsl:map>
    </xsl:variable>
    
    <xsl:variable name="digbodquery" as="xs:string">/solr/digital_bodleian_production/select?fl=full_shelfmark_s,object_id,completeness_s&amp;fq=institution_collections_id_sm:university&amp;q=*:*&amp;wt=xml&amp;rows=1000</xsl:variable>
    
    <!-- Query Digital Bodleian's Solr for UUIDs -->
    <xsl:variable name="digbodresults" as="element(result)?" select="if ($digbodsolr) then document(concat($digbodsolr, $digbodquery))/response/result else ()"/>

    <!-- Load the local authority files -->
    <xsl:variable name="authorityworks" as="element(tei:bibl)*" select="document('../../works.xml')//tei:bibl[@xml:id]"/>
    <xsl:variable name="authoritypersons" as="element(tei:person)*" select="document('../../persons.xml')//tei:person[@xml:id]"/>
    <xsl:variable name="authorityplaces" as="element(tei:place)*" select="document('../../places.xml')//tei:place[@xml:id]"/>
    <xsl:variable name="authorityorgs" as="element(tei:org)*" select="document('../../places.xml')//tei:org[@xml:id]"/>

    <!-- Call this template to loop thru records to be created. Each record can have one or more lines, but the first line
         of each records starts with the shelfmark, which for University College all begin "University College MS..." -->
    <xsl:template name="Main">
        <xsl:for-each select="tokenize(unparsed-text($infile, 'utf-8'), '\r?\nUniversity College MS')">
            <xsl:if test="position() gt 1 and string-length(normalize-space(.)) gt 0">
                <!-- After skipping the header or any blank lines, split into manuscripts (can be a single line containing info on both the manuscript
                     and its only work, or multiple lines with the first line starting with the shelfmark containing the manuscript information, 
                     and parts/works on subsequent lines) -->
                <xsl:variable name="lines" as="xs:string*" select="tokenize(., '\r?\n')[string-length(normalize-space(.)) gt 0]"/>
                <xsl:call-template name="CreateTEI">
                    <xsl:with-param name="msfields" as="xs:string*" select="for $f in tokenize($lines[1], '\t') return normalize-space($f)"/>
                    <xsl:with-param name="subrecords" as="map(xs:integer, xs:string*)">
                        <xsl:map>
                            <xsl:choose>
                                <xsl:when test="count($lines) eq 1">
                                    <!-- This is a single-work manuscript -->
                                    <xsl:map-entry key="1" select="for $f in tokenize($lines[1], '\t') return normalize-space($f)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!-- This is a multi-work and/or multi-part manuscript -->
                                    <xsl:for-each select="$lines[some $f in tokenize(., '\t')[position() = (2,3,4)] satisfies string-length(normalize-space($f)) gt 0]">
                                        <!-- Sometimes there is work/part in the first line of the manuscript, sometimes not.
                                             If columns 2, 3, or 4 have values (partno, author, or title) then this it does. -->
                                        <xsl:map-entry key="position()" select="for $f in tokenize(., '\t') return normalize-space($f)"/>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:map>
                    </xsl:with-param>
                    <xsl:with-param name="msid" select="$nextmsid + position() - 2"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <!-- The template for the TEI file -->
    <xsl:template name="CreateTEI">
        <xsl:param name="msfields" as="xs:string*" required="yes"/>
        <xsl:param name="subrecords" as="map(xs:integer, xs:string*)" required="yes"/>
        <xsl:param name="msid" as="xs:integer" required="yes"/>
        
        <!-- Manuscript fields -->
        <xsl:variable name="shelfmark" as="xs:string" select="concat('University College MS', $msfields[1])"/>
        <xsl:variable name="languages" as="xs:string" select="$msfields[5]"/>
        <xsl:variable name="format" as="xs:string" select="$msfields[6]"/>
        <xsl:variable name="support" as="xs:string" select="$msfields[7]"/>
        <xsl:variable name="binding" as="xs:string" select="$msfields[8]"/>
        <xsl:variable name="decoration" as="xs:string" select="$msfields[9]"/>
        <xsl:variable name="datestr" as="xs:string" select="$msfields[10]"/>
        <xsl:variable name="notbefore" as="xs:string" select="$msfields[11]"/>
        <xsl:variable name="notafter" as="xs:string" select="$msfields[12]"/>
        <xsl:variable name="origin1" as="xs:string" select="$msfields[13]"/>
        <xsl:variable name="origin2" as="xs:string" select="$msfields[14]"/>
        <xsl:variable name="provenance" as="xs:string" select="$msfields[15]"/>
        <xsl:variable name="coxe" as="xs:string" select="$msfields[16]"/>
        <xsl:variable name="imocl" as="xs:string" select="$msfields[17]"/>
        <xsl:variable name="imep" as="xs:string" select="$msfields[18]"/>
        <xsl:variable name="notes" as="xs:string" select="$msfields[19]"/>
        <xsl:variable name="bibliography" as="xs:string" select="$msfields[20]"/>
        
        <xsl:variable name="filename" as="xs:string" select="replace(replace($shelfmark, '\*' ,'_star'), '[^A-Za-z0-9_]+', '_')"/>
        <xsl:variable name="shelfmarknum" as="xs:integer" select="replace($shelfmark, '\D', '') cast as xs:integer"/>
        
        <xsl:variable name="parts" as="xs:string*" select="distinct-values(for $key in map:keys($subrecords) return map:get($subrecords, $key)[2])[string-length() gt 0]"/>
        <xsl:variable name="hasparts" as="xs:boolean" select="some $part in $parts satisfies string-length($part) gt 0"/>
        
        <xsl:result-document href="../../collections/University_College/{$filename}.xml" method="xml" encoding="UTF-8" indent="yes">
            
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
                            <title type="collection">University College MSS.</title>
                            <respStmt xml:id="PB">
                                <resp when="2021">Summary description</resp>
                                <persName>Philip Burnett</persName>
                            </respStmt>
                            <respStmt xml:id="AM">
                                <resp when="2022">Markup and encoding</resp>
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
                            <idno type="collection">University_College_MSS</idno>
                            <idno type="catalogue">Western</idno>
                        </publicationStmt>
                        <sourceDesc>
                            <msDesc xml:lang="en" xml:id="{ $filename }">
                                <msIdentifier>
                                    <settlement>Oxford</settlement>
                                    <repository>University College</repository>
                                    <idno type="shelfmark">
                                        <xsl:value-of select="$shelfmark"/>
                                    </idno>
                                </msIdentifier>
                                <xsl:choose>
                                    <xsl:when test="not($hasparts)">
                                        <!-- This manuscript is not split into parts, so msContents comes first -->
                                        <msContents>
                                            <xsl:if test="string-length($languages) gt 0 and count(map:keys($subrecords)) gt 1">
                                                <xsl:call-template name="AddTextLang">
                                                    <xsl:with-param name="languages" select="$languages"/>
                                                </xsl:call-template>
                                            </xsl:if>
                                            <xsl:variable name="works" as="xs:string*" select="tokenize($parts[1], ';')"/>
                                            <xsl:for-each select="map:keys($subrecords)">
                                                <xsl:variable name="key" as="xs:integer" select="."/>
                                                <xsl:call-template name="AddWork">
                                                    <xsl:with-param name="worknum" select="position()"/>
                                                    <xsl:with-param name="workdetails" select="map:get($subrecords, $key)"/>
                                                    <xsl:with-param name="idprefix" select="$filename"/>
                                                </xsl:call-template>
                                            </xsl:for-each>
                                        </msContents>
                                        <xsl:call-template name="AddPhysDesc">
                                            <xsl:with-param name="format" select="$format"/>
                                            <xsl:with-param name="support" select="$support"/>
                                            <xsl:with-param name="decoration" select="$decoration"/>
                                            <xsl:with-param name="binding" select="$binding"/>
                                            <xsl:with-param name="notes" select="$notes"/>
                                        </xsl:call-template>
                                        <xsl:call-template name="AddHistory">
                                            <xsl:with-param name="datestr" select="$datestr"/>
                                            <xsl:with-param name="notbefore" select="$notbefore"/>
                                            <xsl:with-param name="notafter" select="$notafter"/>
                                            <xsl:with-param name="origins" select="($origin1, $origin2)"/>
                                            <xsl:with-param name="provenance" select="$provenance"/>
                                        </xsl:call-template>
                                        <xsl:call-template name="InsertAdditional">
                                            <xsl:with-param name="shelfmark" select="$shelfmark"/>
                                            <xsl:with-param name="coxe" select="$coxe"/>                                        
                                            <xsl:with-param name="imocl" select="$imocl"/>
                                            <xsl:with-param name="imep" select="$imep"/>
                                        </xsl:call-template>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- This is a composite manuscript and the TEI schema requires physDesc, history, and additional
                                             sections relating to the whole manuscript come before the first msPart -->
                                        <xsl:call-template name="AddPhysDesc">
                                            <xsl:with-param name="format" select="$format"/>
                                            <xsl:with-param name="binding" select="$binding"/>
                                            <xsl:with-param name="numparts" select="count($parts)"/>
                                            <xsl:with-param name="notes" select="$notes"/>
                                        </xsl:call-template>
                                        <xsl:call-template name="AddHistory">
                                            <xsl:with-param name="datestr" select="$datestr"/>
                                            <xsl:with-param name="notbefore" select="$notbefore"/>
                                            <xsl:with-param name="notafter" select="$notafter"/>
                                            <xsl:with-param name="origins" select="($origin1, $origin2)"/>
                                            <xsl:with-param name="provenance" select="$provenance"/>
                                        </xsl:call-template>
                                        <xsl:call-template name="InsertAdditional">
                                            <xsl:with-param name="shelfmark" select="$shelfmark"/>
                                            <xsl:with-param name="coxe" select="$coxe"/>
                                            <xsl:with-param name="imocl" select="$imocl"/>
                                            <xsl:with-param name="imep" select="$imep"/>
                                        </xsl:call-template>
                                        <!-- Now the msPart elements -->
                                        <xsl:for-each select="$parts">
                                            <xsl:variable name="partlabel" as="xs:string" select="."/>
                                            <xsl:variable name="partnum" as="xs:integer" select="position()"/>
                                            <xsl:variable name="partrecord" as="xs:string*" select="(for $key in map:keys($subrecords) return if(map:get($subrecords, $key)[2] eq $partlabel) then map:get($subrecords, $key) else ())"/>
                                            <xsl:variable name="partsupport" as="xs:string?" select="$partrecord[7]"/>
                                            <xsl:variable name="partdecoration" as="xs:string?" select="$partrecord[8]"/>
                                            <xsl:variable name="partdatestr" as="xs:string?" select="$partrecord[10]"/>
                                            <xsl:variable name="partnotbefore" as="xs:string?" select="$partrecord[11]"/>
                                            <xsl:variable name="partnoafter" as="xs:string?" select="$partrecord[12]"/>
                                            <xsl:variable name="partorigin1" as="xs:string?" select="$partrecord[13]"/>
                                            <xsl:variable name="partorigin2" as="xs:string?" select="$partrecord[14]"/>
                                            <xsl:variable name="partprovenance" as="xs:string?" select="$partrecord[15]"/>

                                            <msPart xml:id="{ $filename }-part{ $partnum }" n="{ $partnum }">
                                                <msIdentifier>
                                                    <altIdentifier type="partial">
                                                        <idno type="part">
                                                            <xsl:value-of select="$shelfmark"/>
                                                            <xsl:text> - Part </xsl:text>
                                                            <xsl:value-of select="$partlabel"/>
                                                        </idno>
                                                    </altIdentifier>
                                                </msIdentifier>
                                                <msContents>
                                                    <xsl:call-template name="AddWorks">
                                                        <xsl:with-param name="partlabel" select="$partlabel"/>
                                                        <xsl:with-param name="subrecords" select="$subrecords"/>
                                                        <xsl:with-param name="idprefix" select="concat($filename, '-part', $partnum)"/>
                                                    </xsl:call-template>
                                                </msContents>
                                                <xsl:call-template name="AddPhysDesc">
                                                    <xsl:with-param name="support" select="$partsupport"/>
                                                    <xsl:with-param name="decoration" select="$partdecoration"/>
                                                </xsl:call-template>
                                                <xsl:call-template name="AddHistory">
                                                    <xsl:with-param name="datestr" select="$partdatestr"/>
                                                    <xsl:with-param name="notbefore" select="$partnotbefore"/>
                                                    <xsl:with-param name="notafter" select="$partnoafter"/>
                                                    <xsl:with-param name="origins" select="($partorigin1, $partorigin2)"/>
                                                    <xsl:with-param name="provenance" select="$partprovenance"/>
                                                </xsl:call-template>
                                            </msPart>
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
    
    <xsl:template name="AddWorks" as="element(tei:msItem)*">
        <xsl:param name="partlabel" as="xs:string" required="yes"/>
        <xsl:param name="subrecords" as="map(xs:integer, xs:string*)" required="yes"/>
        <xsl:param name="idprefix" as="xs:string" required="yes"/>
        <xsl:param name="key" as="xs:integer" select="1"/>
        <xsl:param name="worknum" as="xs:integer" select="1"/>
        <xsl:param name="doit" as="xs:boolean" select="false()"/>
        <xsl:choose>
            <xsl:when test="map:get($subrecords, $key)[2] eq $partlabel or ($doit and map:get($subrecords, $key)[2] eq '')">
                <xsl:call-template name="AddWork">
                    <xsl:with-param name="worknum" select="$worknum"/>
                    <xsl:with-param name="workdetails" select="map:get($subrecords, $key)"/>
                    <xsl:with-param name="idprefix" select="$idprefix"/>
                </xsl:call-template>
                <xsl:call-template name="AddWorks">
                    <xsl:with-param name="partlabel" select="$partlabel"/>
                    <xsl:with-param name="subrecords" select="$subrecords"/>
                    <xsl:with-param name="idprefix" select="$idprefix"/>
                    <xsl:with-param name="key" select="$key + 1"/>
                    <xsl:with-param name="worknum" select="$worknum + 1"/>
                    <xsl:with-param name="doit" select="true()"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$key le count(map:keys($subrecords))">
                <xsl:call-template name="AddWorks">
                    <xsl:with-param name="partlabel" select="$partlabel"/>
                    <xsl:with-param name="subrecords" select="$subrecords"/>
                    <xsl:with-param name="idprefix" select="$idprefix"/>
                    <xsl:with-param name="key" select="$key + 1"/>
                    <xsl:with-param name="worknum" select="$worknum"/>
                </xsl:call-template>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="AddWork" as="element(tei:msItem)">
        <xsl:param name="worknum" as="xs:integer" required="yes"/>
        <xsl:param name="workdetails" as="xs:string*" required="yes"/>
        <xsl:param name="idprefix" as="xs:string" required="yes"/>
        <xsl:variable name="author" as="xs:string?" select="$workdetails[3]"/>
        <xsl:variable name="title" as="xs:string?" select="$workdetails[4]"/>
        <xsl:variable name="languages" as="xs:string?" select="$workdetails[5]"/>
        <xsl:variable name="normalizedauthor" as="xs:string" select="local:normalizeName($author)"/>
        <xsl:variable name="personauthorities" as="element(tei:person)*" select="$authoritypersons[some $p in tei:persName/string() satisfies local:normalizeName($p) = $normalizedauthor]"/>
        <msItem xml:id="{ $idprefix }-item{ $worknum }" n="{ $worknum }">
            <xsl:if test="string-length($author) gt 0">
                <author>
                    <xsl:if test="count($personauthorities) eq 1">
                        <xsl:attribute name="key" select="$personauthorities[1]/@xml:id"/>
                    </xsl:if>
                    <xsl:value-of select="normalize-space($author)"/>
                </author>
                <xsl:if test="count($personauthorities) gt 1">
                    <xsl:comment>Possible person keys: <xsl:value-of select="string-join(for $p in $personauthorities return $p/@xml:id, ' or ')"/></xsl:comment>
                </xsl:if>
            </xsl:if>
            <xsl:if test="string-length($title) gt 0">
                <xsl:variable name="titlevariants" as="xs:string*" select="local:getTitleVariants($title, $author, $languages)"/>
                <xsl:variable name="workauthorities" as="element(tei:bibl)*" select="$authorityworks[some $t in tei:title/string() satisfies local:normalizeTitle($t) = $titlevariants]"/>
                <title>
                    <xsl:if test="count($workauthorities) eq 1 and $workauthorities[1]/author/@key = $personauthorities/@xml:id">
                        <!-- Only add work key attributes if the author is known, as there are works with the same title by different authors -->
                        <xsl:attribute name="key" select="$workauthorities[1]/@xml:id"/>
                    </xsl:if>
                    <xsl:value-of select="normalize-space($title)"/>
                </title>
                <xsl:if test="count($workauthorities) gt 1 or (count($workauthorities) eq 1 and not($workauthorities[1]/author/@key = $personauthorities/@xml:id))">
                    <xsl:comment>Possible work keys: <xsl:value-of select="string-join(for $w in $workauthorities return $w/@xml:id, ' or ')"/></xsl:comment>
                </xsl:if>
            </xsl:if>
            <xsl:if test="string-length($languages) gt 0">
                <xsl:call-template name="AddTextLang">
                    <xsl:with-param name="languages" select="$languages"/>
                </xsl:call-template>
            </xsl:if>
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
    
    <xsl:template name="AddPhysDesc" as="element(tei:physDesc)">
        <xsl:param name="format" as="xs:string?"/>
        <xsl:param name="support" as="xs:string?"/>
        <xsl:param name="decoration" as="xs:string?"/>
        <xsl:param name="binding" as="xs:string?"/>
        <xsl:param name="numparts" as="xs:integer?" select="0"/>
        <xsl:param name="notes" as="xs:string?"/>
        <physDesc>
            <objectDesc>
                <xsl:if test="string-length($format) gt 0">
                    <xsl:attribute name="form" select="$format"/>
                </xsl:if>
                <xsl:if test="$numparts gt 1">
                    <p>Composite manuscript in <xsl:value-of select="$numparts"/> parts</p>
                </xsl:if>
                <xsl:if test="string-length($support) gt 0">
                    <xsl:variable name="material" as="xs:string">
                        <xsl:choose>
                            <xsl:when test="contains($support, ';') or contains($support, ',') or contains($support, ' and ')">mixed</xsl:when>
                            <xsl:when test="$support eq 'parchment'">perg</xsl:when>
                            <xsl:when test="$support eq 'vellum'">perg</xsl:when>
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
                </xsl:if>
            </objectDesc>
            <xsl:if test="string-length($decoration) gt 0">
                <decoDesc>
                    <decoNote>
                        <xsl:value-of select="$decoration"/>
                    </decoNote>
                </decoDesc>
            </xsl:if>
            <xsl:if test="string-length($binding) gt 0">
                <bindingDesc>
                    <binding>
                        <p>
                            <xsl:value-of select="$binding"/>
                        </p>
                    </binding>
                </bindingDesc>
            </xsl:if>
            <xsl:if test="string-length($notes) gt 0">
                <!-- Most notes in the University College spreadsheet seem to be describing accompanying material -->
                <accMat>
                    <xsl:value-of select="$notes"/>
                </accMat>
            </xsl:if>
        </physDesc>
    </xsl:template>
    
    <xsl:template name="AddHistory" as="element(tei:history)">
        <xsl:param name="datestr" as="xs:string?"/>
        <xsl:param name="notbefore" as="xs:string?"/>
        <xsl:param name="notafter" as="xs:string?"/>
        <xsl:param name="origins" as="xs:string*"/>
        <xsl:param name="provenance" as="xs:string?"/>
        <history>
            <origin>
                <xsl:choose>
                    <xsl:when test="string-length($datestr) gt 0 or string-length($notbefore) gt 0 or string-length($notbefore) gt 0">
                        <origDate calendar="Gregorian">
                            <xsl:if test="string-length($notbefore) gt 0"><xsl:attribute name="notBefore" select="$notbefore"/></xsl:if>
                            <xsl:if test="string-length($notafter) gt 0"><xsl:attribute name="notAfter" select="$notafter"/></xsl:if>
                            <xsl:value-of select="($datestr, concat($notbefore, '–', $notafter))[string-length(.) gt 0][1]"/>
                        </origDate>
                    </xsl:when>
                    <xsl:otherwise>
                        <p>No date</p>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="some $origin in $origins satisfies string-length($origin) gt 0">
                    <origPlace>
                        <xsl:for-each select="(for $origin in $origins return tokenize($origin, '\s+(and|or|in|;)\s+'))[string-length(.) gt 0]">
                            <xsl:variable name="origin" as="xs:string" select="."/>
                            <xsl:analyze-string select="$origin" regex="[\w\-'\.\s]+">
                                <xsl:matching-substring>
                                    <xsl:variable name="placename" as="xs:string" select="replace(normalize-space(.), '\.$', '')"/>
                                    <xsl:variable name="placeauthority" as="element(tei:place)*" select="$authorityplaces[tei:placeName/string() = $placename][1]"/>
                                    <xsl:variable name="orgauthority" as="element(tei:org)*" select="$authorityorgs[tei:orgName/string() = $placename][1]"/>
                                    <xsl:choose>
                                        <xsl:when test="$placeauthority">
                                            <xsl:if test="matches(., '^\s')"><xsl:text> </xsl:text></xsl:if>
                                            <xsl:choose>
                                                <xsl:when test="$placeauthority/@type = 'country'">
                                                    <country key="{ $placeauthority/@xml:id }">
                                                        <xsl:value-of select="."/>
                                                    </country>
                                                </xsl:when>
                                                <xsl:when test="$placeauthority/@type = 'region'">
                                                    <region key="{ $placeauthority/@xml:id }">
                                                        <xsl:value-of select="."/>
                                                    </region>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <placeName key="{ $placeauthority/@xml:id }">
                                                        <xsl:value-of select="."/>
                                                    </placeName>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                            <xsl:if test="matches(., '\s$')"><xsl:text> </xsl:text></xsl:if>
                                        </xsl:when>
                                        <xsl:when test="$orgauthority">
                                            <orgName key="{ $orgauthority/@xml:id }">
                                                <xsl:value-of select="."/>
                                            </orgName>
                                            <xsl:if test="matches(., '\s$')"><xsl:text> </xsl:text></xsl:if>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="."/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:matching-substring>
                                <xsl:non-matching-substring>
                                    <xsl:value-of select="."/>
                                </xsl:non-matching-substring>
                            </xsl:analyze-string>
                            <xsl:if test="position() ne last()">
                                <xsl:text>; </xsl:text>
                            </xsl:if>
                        </xsl:for-each>
                    </origPlace>
                </xsl:if>
            </origin>
            <xsl:if test="string-length($provenance) gt 0">
                <provenance>
                    <xsl:value-of select="$provenance"/>
                </provenance>
            </xsl:if>
        </history>
    </xsl:template>

    <xsl:template name="InsertAdditional" as="element(tei:additional)">
        <xsl:param name="shelfmark" as="xs:string" required="yes"/>
        <xsl:param name="coxe" as="xs:string?"/>
        <xsl:param name="imocl" as="xs:string?"/>
        <xsl:param name="imep" as="xs:string?"/>
        <xsl:variable name="hassources" as="xs:boolean" select="some $s in ($coxe, $imocl, $imep) satisfies string-length($s) gt 0"/>
        <additional>
            <adminInfo>
                <recordHist>
                    <source>
                        <p>Summary description by Philip Burnett<xsl:if test="$hassources">, based on the following sources</xsl:if>.</p>
                        <xsl:if test="$hassources">
                            <listBibl>
                                <xsl:if test="string-length($coxe) gt 0">
                                    <xsl:variable name="catalogueurl" as="xs:string?" select="if ($coxe castable as xs:integer) then concat('https://babel.hathitrust.org/cgi/pt?id=uc1.c3083855&amp;view=1up&amp;seq=', 18 + xs:integer($coxe)) else ()"/>
                                    <bibl><ref target="{ $catalogueurl }">H. O. Coxe, <title>Catalogus codicum mss. qui in collegiis aulisque Oxoniensibus hodie adservantur</title> (1852), p. <xsl:value-of select="$coxe"/></ref></bibl>
                                </xsl:if>
                                <xsl:if test="string-length($imocl) gt 0">
                                    <bibl><ref target="https://catalog.hathitrust.org/Record/000387352">J. J. G. Alexander and Elzbieta Temple, <title>Illuminated manuscripts in Oxford college libraries, the University Archives and the Taylor Institution</title> (Oxford, 1985)</ref><xsl:if test="string-length($imocl) gt 0">, <xsl:value-of select="$imocl"/></xsl:if> [information on decoration and origin]</bibl>
                                </xsl:if>
                                <xsl:if test="string-length($imep) gt 0">
                                    <bibl><title>IMEP</title>, <xsl:value-of select="$imep"/></bibl>
                                </xsl:if>
                            </listBibl>
                        </xsl:if>
                    </source>
                </recordHist>
                <availability>
                    <p>For enquiries about this manuscript, please contact University College Library: <email>library@univ.ox.ac.uk</email></p>
                </availability>
            </adminInfo>
            <xsl:variable name="digbods" as="element(doc)*" select="$digbodresults/doc[str[@name='full_shelfmark_s']/text() = translate($shelfmark, '.', '')]"/>
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

    <xsl:function name="local:lookupLanguages" as="xs:string*">
        <xsl:param name="languages" as="xs:string"/>
        <xsl:for-each select="for $l in tokenize($languages, '(\s*[;&amp;]\s*|\s+and\s+)') return normalize-space(tokenize($l, '\(')[1])">
            <xsl:value-of select="map:get($iso639codes, .)"/>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="local:normalizeName" as="xs:string">
        <xsl:param name="persname" as="xs:string"/>
        <xsl:value-of select="lower-case(replace(normalize-space($persname), '[\.,\-–—\? \(\[\]\):;]+', ''))"/>
    </xsl:function>
    
    <xsl:function name="local:normalizeTitle" as="xs:string">
        <xsl:param name="title" as="xs:string"/>
        <xsl:value-of select="lower-case(replace(normalize-space($title), '[\.,\-–—\? \(\[\]\):;]+', ''))"/>
    </xsl:function>
    
    <xsl:function name="local:getTitleVariants" as="xs:string*">
        <xsl:param name="title" as="xs:string"/>
        <xsl:param name="author" as="xs:string?"/>
        <xsl:param name="languages" as="xs:string?"/>
        <xsl:variable name="withandwithoutauthors" as="xs:string*" select="($title, concat($author, ': ', $title))"/>
        <xsl:variable name="withandwithoutlanguages" as="xs:string*" select="for $t in $withandwithoutauthors return for $l in tokenize($languages, '(\s*[;&amp;]\s*|\s+and\s+)') return ($t, concat($t, ' [', $l, ']')) "/>
        <xsl:copy-of select="distinct-values(for $t in ($withandwithoutlanguages, $withandwithoutauthors)[count(.) gt 0] return local:normalizeTitle($t))"/>
    </xsl:function>

</xsl:stylesheet>