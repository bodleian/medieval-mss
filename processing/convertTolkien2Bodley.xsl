<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  xmlns:jc="http://james.blushingbunny.net/ns.html" exclude-result-prefixes="tei jc" version="2.0">

  <!-- 
  Created by James Cummings james@blushingbunny.net 
  2017-04 to 2017-05 or so
  for up-conversion of existing TEI Catalogue
  -->

  <!-- param for overall collection -->
  <xsl:param name="cat" select="'Western'"/>

  <!-- Set up the collection of files to be converted -->
  <!-- files and recurse parameters defaulting to '*.xml' and 'no' respectively -->
  <xsl:param name="files" select="'*.xml'"/>
  <xsl:param name="recurse" select="'yes'"/>
  <!-- path hard-coded to location on my desktop -->
  <xsl:variable name="path">
    <xsl:value-of
      select="concat('file:///home/jamesc/Dropbox/stuff/Desktop/Work/projects/Bodleian-TEI-Catalogue-Consolidation/working/tolkien-xml/working/?select=', $files,';on-error=warning;recurse=',$recurse)"
    />
  </xsl:variable>

  <!-- the main collection of all the documents we are dealing with -->
  <xsl:variable name="doc" select="collection($path)"/>


  <!-- In case there are existing schema associations, let's get rid of those -->
  <xsl:template match="processing-instruction()"/>

  <!-- Named template which we call that starts off the whole thing-->
  <xsl:template name="main">
    <!-- For each item in the collection -->
    <xsl:for-each select="$doc">
      <xsl:sort select="tokenize(base-uri(), '/')[last()-1]"/>
      <xsl:sort select="tokenize(base-uri(), '/')[last()]"/>
      <xsl:variable name="baseURI">
        <xsl:value-of select="base-uri()"/>
      </xsl:variable>
      <xsl:variable name="filename">
        <xsl:value-of select="tokenize(base-uri(), '/')[last()]"/>
      </xsl:variable>
      <xsl:variable name="folder">
        <xsl:value-of select="tokenize(base-uri(), '/')[last()-1]"/>
      </xsl:variable>
      <xsl:variable name="fileNum">
        <xsl:value-of select="position()"/>
      </xsl:variable>
      <xsl:variable name="msID">
        <xsl:value-of select="jc:normalizeID(normalize-space(.//sourceDesc/msDesc[1]/msIdentifier/idno[1]/text()))"/>
      </xsl:variable>

      <!-- This is just a debugging message so I see the filnames whiz by on the screen -->
      <xsl:message> Base URI: <xsl:value-of select="$baseURI"/> 
        Folder: <xsl:value-of select="$folder"/> 
        Old Filename:
          <xsl:value-of select="$filename"/> 
        New ID: <xsl:value-of select="$msID"/>
      </xsl:message>

      <!-- Create the (hard coded) output file name -->
      <xsl:variable name="outputFilename"
        select="concat('file:/home/jamesc/Dropbox/stuff/Desktop/Work/projects/Bodleian-TEI-Catalogue-Consolidation/working/tolkien-xml/new/', 
      $folder, '/', $msID, '.xml')"/>
      <!-- create output file -->
      <xsl:result-document href="{$outputFilename}" method="xml" indent="yes">
        <!-- add relative schema associations -->
        <xsl:text>&#xA;</xsl:text>
        <xsl:processing-instruction name="xml-model">href="../bodley-msDesc.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
        <xsl:text>&#xA;</xsl:text>
        <xsl:processing-instruction name="xml-model">href="../bodley-msDesc.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
        <xsl:text>&#xA;</xsl:text>
        <!-- TEI/@xml:id contains the manuscript_12345 used on the website -->
        <TEI xml:id="{concat('manuscript_', $fileNum)}">
          <xsl:apply-templates/>
        </TEI>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>

  <!-- By default we just copy the input to the output -->
  <xsl:template match="@*|node()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()|comment()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Make TEI element vanish since adding it above -->
  <xsl:template match="TEI">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Add ID to msDesc -->
  <xsl:template match="msDesc">
    <msDesc xml:id="{jc:normalizeID(msIdentifier/idno)}">
      <xsl:apply-templates select="@*[name() ne 'xml:id']|node()"/>
    </msDesc>
  </xsl:template>


  <!-- Schema normalisation -->
  <!-- bibl/@type -->
  <xsl:template match="bibl/@type">
    <xsl:variable name="type">
      <xsl:choose>
        <!--<xsl:when test=".='commentedOn'">commentary</xsl:when>-->
        <xsl:when test=".='digitised-version' or .='related-items' or .='realted-volumes' or .='related-volumes' or .='referred'"
          >related</xsl:when>
        <xsl:when test=".='extracts'">extract</xsl:when>
        <xsl:when test=".='ms'">MS</xsl:when>
        <xsl:when test=".='textual-relations'">text-relations</xsl:when>
        <xsl:when test=".='translated'">translation</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="normalize-space($type) != ''">
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>


  <!-- decoNote/@type -->
  <xsl:template match="decoNote/@type">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test=".='frieze' ">border</xsl:when>
        <xsl:when test=".='decoration' or .='paratext' or .='printmark' or .='secondary' or .='unspecified'">other</xsl:when>
        <xsl:when test=".='diagrams'">diagram</xsl:when>
        <xsl:when test=".='ms'">MS</xsl:when>
        <xsl:when test=".='borderInitials'">initial_border</xsl:when>
        <xsl:when test=".='intials'">initial</xsl:when>
        <xsl:when test=".='marginalSketches'">marginal</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="normalize-space($type) != ''">
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

  <!-- dimensions/@type -->
  <xsl:template match="dimensions/@type">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="normalize-space(.)='number of folia'">folia</xsl:when>
        <xsl:when test=".='ruledColumn' or .='ruling'">ruled</xsl:when>
        <xsl:when test=".='leaves'">leaf</xsl:when>
        <xsl:when test=".='ms'">MS</xsl:when>
        <xsl:when test=".='unknown'">other</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="normalize-space($type) != ''">
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

  <!-- name/@type -->
  <xsl:template match="name/@type">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="normalize-space(.)=''"/>
        <xsl:when test=".='artist'">person</xsl:when>
        <xsl:when test=".='church' or .='corporate'">org</xsl:when>
        <xsl:when test=".='ms'">MS</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="normalize-space($type) != ''">
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

  <!-- title/@type -->
  <xsl:template match="title/@type">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="normalize-space(.)=''"/>
        <xsl:when test=".='alternative' or .='parallel'">alt</xsl:when>
        <xsl:when test=".='general' or .='uniform'">main</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="normalize-space($type) != ''">
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>



  <!-- up-conversions -->

  <!-- Make name/@type='person' into <persName> in the end easier just to do it for all of them and make nested persName vanish -->
  <xsl:template match="name[@type='person']|name[@type='artist']">
    <persName>
      <xsl:apply-templates select="@*[not(name()='type')]|node()"/>
    </persName>
    <!--
     <xsl:choose>
       <xsl:when test="not(persName)"><persName><xsl:apply-templates select="@*[name() ne 'type']|node()" /></persName></xsl:when>
       <xsl:when test="persName and count(*)=1"><persName><xsl:apply-templates select="@*|node()"/></persName></xsl:when>
       <xsl:otherwise><persName><xsl:apply-templates select="@*[name() ne 'type']|node()" /></persName></xsl:otherwise>
     </xsl:choose>-->
  </xsl:template>
  <xsl:template match="name[@type='person' or @type='artist']/persName"><xsl:apply-templates/></xsl:template>

  <!-- Same with corporate to orgName  and church-->
  <xsl:template match="name[@type='corporate']|name[@type='church']"><orgName><xsl:apply-templates select="@*[not(name()='type')]|node()"/></orgName></xsl:template>
  <xsl:template match="name[@type='corporate' or @type='church']/persName"><xsl:apply-templates/></xsl:template>

  <xsl:template match="author/persName"><xsl:apply-templates/></xsl:template>

  <!-- Why does author sometimes have title in it? Let's move it to after -->
  <xsl:template match="author[title]"><xsl:copy><xsl:apply-templates select="@*|node()[not(name()='title')]"/></xsl:copy>
    <xsl:copy-of select="title"/>
  </xsl:template>
  <!-- make it vanish -->
  <xsl:template match="author/title"/>

  <xsl:template match="origin//date"><origDate><xsl:apply-templates select="@*|node()"/></origDate></xsl:template>


  <!-- 
msPart/altIdentifier needs to be changed to msIdentifier
  but also split those existing altIdentifiers with commas 
   -->
  <xsl:template match="altIdentifier">
    <xsl:choose>
      <xsl:when test="parent::msPart">
        <msIdentifier>
          <xsl:copy-of select="jc:splitAltIdentifier(.)"/>
        </msIdentifier>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="jc:splitAltIdentifier(.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- Give new ID to each msPart -->
  <xsl:template match="msPart">
    <xsl:variable name="num">
      <xsl:number count="msPart" level="any"/>
    </xsl:variable>
    <xsl:variable name="msID">
      <xsl:value-of select="jc:normalizeID(ancestor::msDesc[1]/msIdentifier[1]/idno[1])"/>
    </xsl:variable>
<xsl:variable name="desc1"><xsl:if test="preceding::msDesc"><xsl:value-of select="concat('-desc', count(preceding::msDesc)+1)"/></xsl:if></xsl:variable>    
<xsl:variable name="part1">
<xsl:value-of select="concat('-part', count(preceding-sibling::msPart)+1)"/>  
</xsl:variable>
    <!-- Nested msParts -->
    <xsl:variable name="part2">
<xsl:if test="parent::msPart"><xsl:value-of select="concat('-part', count(parent::msPart/preceding-sibling::msPart)+1)"/></xsl:if>  
    </xsl:variable>    
    <msPart xml:id="{concat($msID,$desc1,$part2, $part1)}">
      <xsl:apply-templates select="@*[not(name()='xml:id')]|node()"/>
    </msPart>
  </xsl:template>

  <!-- update IDs on msItems and copy textLang if appropriate -->
  <xsl:template match="msItem">
    <xsl:variable name="msID">
      <xsl:value-of select="jc:normalizeID(ancestor::msDesc[1]/msIdentifier[1]/idno[1])"/>
    </xsl:variable>
    <xsl:variable name="desc1"><xsl:if test="preceding::msDesc"><xsl:value-of select="concat('-desc', count(preceding::msDesc)+1)"/></xsl:if></xsl:variable>
<!-- Very manual way of creating ID that deals with nested msDescs, nested msParts and up to 5 levels of msItems -->    
    <xsl:variable name="msItemID">
<xsl:value-of select="$msID"/>
<xsl:if test="preceding::msDesc"><xsl:value-of select="$desc1"/></xsl:if>      
<xsl:if test="ancestor::msPart[1]/parent::msPart">-part<xsl:value-of select="count(ancestor::msPart[1]/parent::msPart/preceding-sibling::msPart)+1"/></xsl:if>           
<xsl:if test="ancestor::msPart">-part<xsl:value-of select="count(ancestor::msPart[1]/preceding-sibling::msPart)+1"/></xsl:if>
<xsl:choose>
  <xsl:when test="parent::msItem/parent::msItem/parent::msItem/parent::msItem/parent::msContents">
    -item<xsl:value-of select="count(parent::msItem/parent::msItem/parent::msItem/parent::msItem/preceding-sibling::msItem)+1"/>
    -item<xsl:value-of select="count(parent::msItem/parent::msItem/parent::msItem/preceding-sibling::msItem)+1"/>
    -item<xsl:value-of select="count(parent::msItem/parent::msItem/preceding-sibling::msItem)+1"/>
    -item<xsl:value-of select="count(parent::msItem/preceding-sibling::msItem)+1"/>
    -item<xsl:value-of select="count(preceding-sibling::msItem)+1"/>  
  </xsl:when>
  <xsl:when test="parent::msItem/parent::msItem/parent::msItem/parent::msContents">
    -item<xsl:value-of select="count(parent::msItem/parent::msItem/parent::msItem/preceding-sibling::msItem)+1"/>
    -item<xsl:value-of select="count(parent::msItem/parent::msItem/preceding-sibling::msItem)+1"/>
    -item<xsl:value-of select="count(parent::msItem/preceding-sibling::msItem)+1"/>
    -item<xsl:value-of select="count(preceding-sibling::msItem)+1"/>  
    </xsl:when>
  <xsl:when test="parent::msItem/parent::msItem/parent::msContents">
    -item<xsl:value-of select="count(parent::msItem/parent::msItem/preceding-sibling::msItem)+1"/>
    -item<xsl:value-of select="count(parent::msItem/preceding-sibling::msItem)+1"/>
    -item<xsl:value-of select="count(preceding-sibling::msItem)+1"/>  
  </xsl:when>
  <xsl:when test="parent::msItem/parent::msContents">
    -item<xsl:value-of select="count(parent::msItem/preceding-sibling::msItem)+1"/>
    -item<xsl:value-of select="count(preceding-sibling::msItem)+1"/>  
  </xsl:when>
  <xsl:when test="parent::msContents">
    -item<xsl:value-of select="count(preceding-sibling::msItem)+1"/>  
  </xsl:when>
</xsl:choose>
    </xsl:variable>
    <!-- Finally use the variable -->
    <msItem xml:id="{translate(normalize-space($msItemID), ' ', '')}">
      <xsl:apply-templates select="@*[name() ne 'xml:id']|node()"/>
      <!-- textLang -->
      <xsl:choose>
        <xsl:when test="not(.//textLang) and ancestor::msContents/textLang[not(@otherLangs)] and not(p)">
          <xsl:apply-templates select="ancestor::msContents/textLang"/>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
    </msItem>
  </xsl:template>



  <!-- 
  Replace publicationStmt
  -->
  <xsl:template match="publicationStmt">
    <xsl:variable name="folder">
      <xsl:value-of select="tokenize(base-uri(), '/')[last()-1]"/>
    </xsl:variable>
    <xsl:variable name="msID">
      <xsl:value-of select="jc:normalizeID(//sourceDesc[1]/msDesc[1]/msIdentifier[1]/idno[1]/text())"/>
    </xsl:variable>
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
      <xsl:comment>Availability statement will be added here</xsl:comment>
      
      <!-- <availability>
        <licence target="https://creativecommons.org/licenses/by/4.0/">A Creative Commons Attribution licence applies to this file.</licence>
      </availability>
     -->
      
      <idno type="msID">
        <xsl:value-of select="$msID"/>
      </idno>
      <idno type="collection">
        <xsl:value-of select="translate($folder, '_', ' ')"/>
      </idno>
      <idno type="catalogue">
        <xsl:value-of select="$cat"/>
      </idno>
    </publicationStmt>
  </xsl:template>

  <!-- Add revisionDesc to the teiHeader -->
  <xsl:template match="teiHeader">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <xsl:choose>
        <xsl:when test="revisionDesc">
          <xsl:message>WARNING: Already has a revisionDesc element</xsl:message>
        </xsl:when>
        <xsl:otherwise>
          <revisionDesc>
            <change when="{substring(string(current-date()), 0, 11)}">
              <persName>James Cummings</persName> Up-converted the markup using <ref
                target="https://github.com/jamescummings/Bodleian-msDesc-ODD/blob/master/convertTolkien2Bodley.xsl"
                >https://github.com/jamescummings/Bodleian-msDesc-ODD/blob/master/convertTolkien2Bodley.xsl</ref>
            </change>
          </revisionDesc>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <!-- If it has a revisionDesc -->
  <xsl:template match="revisionDesc">
    <xsl:copy>
      <change when="{substring(string(current-date()), 0, 11)}">
        <persName>James Cummings</persName> Up-converted the markup using <ref
          target="https://github.com/jamescummings/Bodleian-msDesc-ODD/blob/master/convertTolkien2Bodley.xsl"
          >https://github.com/jamescummings/Bodleian-msDesc-ODD/blob/master/convertTolkien2Bodley.xsl</ref>
      </change>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- Some have /@type in teiHeader -->

  <xsl:template match="teiHeader/@type"/>

  <!-- type not allowed on msItem -->
  <xsl:template match="msItem/@type"/>

  <!-- tittle is surely title! -->
  <xsl:template match="tittle">
    <title>
      <xsl:apply-templates select="@*|node()"/>
    </title>
  </xsl:template>

<!-- get rid of listBibl that have no child elements -->
  <xsl:template match="listBibl[not(*)]"/>

<!-- Normalize langs -->

<xsl:template match="*/@xml:lang | */@mainLang | */@otherLangs">
<xsl:attribute name="{name()}"><xsl:value-of select="jc:normalizeLang(.)"/></xsl:attribute>  
</xsl:template>
  
  <!-- Get rid of empty p elements -->
  <xsl:template match="p"><xsl:choose>
      <xsl:when test="normalize-space(.)=''"/>
    <xsl:otherwise><xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy></xsl:otherwise>
    </xsl:choose></xsl:template>
  
  <!-- except inside msItems -->
  <xsl:template match="msItem/p"><xsl:choose>
    <xsl:when test="normalize-space(.)='' and  ancestor::msContents/textLang[not(@otherLangs)]"><xsl:apply-templates select="ancestor::msContents/textLang"/></xsl:when>
    <xsl:when test="normalize-space(.)=''"><xsl:copy><xsl:comment>Empty paragraph in source of conversion</xsl:comment></xsl:copy></xsl:when>
    <xsl:otherwise><xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy></xsl:otherwise>
  </xsl:choose></xsl:template>
  
  <!-- and inside binding and layoutDesc -->
  <xsl:template match="binding/p|layoutDesc/p"><xsl:choose>
    <xsl:when test="normalize-space(.)=''"><xsl:copy><xsl:comment>Empty paragraph in source of conversion</xsl:comment></xsl:copy></xsl:when>
    <xsl:otherwise><xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy></xsl:otherwise>
  </xsl:choose></xsl:template>
  
<!-- Put different comment in body/p -->
  <xsl:template match="body/p">
    <xsl:choose>
      <xsl:when test="normalize-space(.)=''">
        <xsl:copy><xsl:comment>Body paragraph provided for validation and future transcription</xsl:comment></xsl:copy>
      </xsl:when>
      <xsl:otherwise><xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy></xsl:otherwise>
    </xsl:choose>
  </xsl:template>


<!-- FUNCTIONS -->
  <!-- function to replace characters in manuscript identifiers -->
  <xsl:function name="jc:normalizeID">
    <xsl:param name="ID" as="item()"/>
    <xsl:variable name="pass0">
      <xsl:value-of select="translate(normalize-space($ID), '\/`!£$%^[_]()}{,.', '')"/>
    </xsl:variable>
    <xsl:variable name="pass1">
      <xsl:value-of select="replace(normalize-space($pass0), ' - ', '-')"/>
    </xsl:variable>
    <xsl:variable name="pass2">
      <xsl:value-of select="replace(normalize-space($pass1), '\*', '-star')"/>
    </xsl:variable>
    <xsl:variable name="apos">&apos;</xsl:variable>
    <xsl:variable name="pass3">
      <xsl:value-of select="replace(normalize-space($pass2), $apos, '')"/>
    </xsl:variable>
    <xsl:value-of select="translate(normalize-space($pass3), ' ','_')"/>
  </xsl:function>


  <!-- function to split altIdentifiers on commas -->
  <xsl:function name="jc:splitAltIdentifier" as="item()*">
    <xsl:param name="altIdentifier" as="item()"/>
    <xsl:choose>
      <xsl:when
        test="$altIdentifier/idno[@type='SCN' and not(contains(., 'Not in SC')) and contains(., ',')] | $altIdentifier/idno[@type='TM']">
        <xsl:for-each select="tokenize($altIdentifier/idno, ',')">
          <altIdentifier>
            <xsl:copy-of select="$altIdentifier/@*"/>
            <idno>
              <xsl:copy-of select="$altIdentifier/idno/@*"/>
              <xsl:value-of select="normalize-space(.)"/>
            </idno>
          </altIdentifier>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <altIdentifier>
          <xsl:apply-templates select="$altIdentifier/@*|$altIdentifier/node()"/>
        </altIdentifier>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>


  <!-- function to normalize language -->
  <xsl:function name="jc:normalizeLang" as="item()">
    <xsl:param name="lang" as="item()"/>
    <xsl:variable name="languages">
      <!-- table of languages to normalize -->
        <row><cell>Egyd</cell><cell>egy-Egyd</cell></row>
        <row><cell>Egyh</cell><cell>egy-Egyh</cell></row>
        <row><cell>English</cell><cell>en</cell></row>
        <row><cell>French</cell><cell>fr</cell></row>
        <row><cell>Hebrew</cell><cell>he</cell></row>
        <row><cell>ara</cell><cell>ar</cell></row>
        <row><cell>ara-Latn-x-lc</cell><cell>ar-Latn-x-lc</cell></row>
        <row><cell>ara-Latn-x-lx</cell><cell>ar-Latn-x-lx</cell></row>
        <row><cell>arb</cell><cell>ar</cell></row>
        <row><cell>ben</cell><cell>bn</cell></row>
        <row><cell>bo-Latn-x-EWTS</cell><cell/></row>
        <row><cell>eng</cell><cell>en</cell></row>
        <row><cell>eng-Latn-x-lc</cell><cell>en-Latn-x-lc</cell></row>
        <row><cell>fre</cell><cell>fr</cell></row>
        <row><cell>fre-Latn-x-lc</cell><cell>fr-Latn-x-lc</cell></row>
        <row><cell>geo</cell><cell>ka</cell></row>
        <row><cell>geo-Latn-x-lc</cell><cell>ka-Latn-x-lc</cell></row>
        <row><cell>ger</cell><cell>de</cell></row>
        <row><cell>heb</cell><cell>he</cell></row>
        <row><cell>heb-Latn-x-lc</cell><cell>he-Latn-x-lc</cell></row>
        <row><cell>hin</cell><cell>hi</cell></row>
        <row><cell>hin-Latn-x-lc</cell><cell>hi-Latn-x-lc</cell></row>
        <row><cell>ita</cell><cell>it</cell></row>
        <row><cell>jav</cell><cell>jv</cell></row>
        <row><cell>kur</cell><cell>ku</cell></row>
        <row><cell>lat</cell><cell>la</cell></row>
        <row><cell>lst</cell><cell>la</cell></row>
        <row><cell>may</cell><cell>ms</cell></row>
        <row><cell>mon</cell><cell>mn</cell></row>
        <row><cell>per</cell><cell>fa</cell></row>
        <row><cell>per-Latn-x-lc</cell><cell>fa-Latn-x-lc</cell></row>
        <row><cell>per-Latn-xlc</cell><cell>fa-Latn-xlc</cell></row>
        <row><cell>pus</cell><cell>ps</cell></row>
        <row><cell>rus</cell><cell>ru</cell></row>
        <row><cell>rus-Latn-x-lc</cell><cell>ru-Latn-x-lc</cell></row>
        <row><cell>san</cell><cell>sa</cell></row>
        <row><cell>san-Latn-x-lc</cell><cell>sa-Latn-x-lc</cell></row>
        <row><cell>shan-Latn-x-lc</cell><cell>shn-Latn-x-lc</cell></row>
        <row><cell>shn-Latn-x-lc</cell><cell/></row>
        <row><cell>spa</cell><cell>es</cell></row>
        <row><cell>t-Latn-x-lc</cell><cell>tr-Latn-x-lc</cell></row>
        <row><cell>tur-Latn-x-lc</cell><cell>tr-Latn-x-lc</cell></row>
        <row><cell>urd</cell><cell>ur</cell></row>
        <row><cell>urd-Latn-x-lc</cell><cell>ur-Latn-x-lc</cell></row>
        <row><cell>x-other</cell><cell>und</cell></row>
        <row><cell>yid</cell><cell>yi</cell></row>
       </xsl:variable> 
    <xsl:variable name="value">
  <xsl:choose>
    <xsl:when test="contains(normalize-space($lang), ' ')">
      <xsl:for-each select="tokenize(normalize-space($lang), ' ')">
        <xsl:variable name="current" select="."/>
        <xsl:choose>
          <xsl:when test="$current=$languages//row/cell[1]">
            <xsl:value-of select="$languages//row[cell[1]=$current]/cell[2]"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$current"/>
          </xsl:otherwise>
        </xsl:choose>
      <xsl:text> </xsl:text>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="$lang=$languages//row/cell[1]">
          <xsl:value-of select="$languages//row[cell[1]=$lang]/cell[2]"/>
        </xsl:when>
       <xsl:otherwise>
         <xsl:value-of select="$lang"/>
       </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
    </xsl:variable>
<xsl:value-of select="normalize-space($value)"/>  
  </xsl:function>

</xsl:stylesheet>
