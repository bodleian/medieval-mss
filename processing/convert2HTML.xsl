<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  xmlns:jc="http://james.blushingbunny.net/ns.html" exclude-result-prefixes="tei jc" version="2.0">

  <!-- 
  Created by Dr James Cummings james@blushingbunny.net 
  2017-05 for output of Bodley TEI msDescs as HTML to
  be sucked into the frontend platform
  -->

  <!-- Set up the collection of files to be converted -->
  <!-- files and recurse parameters defaulting to '*.xml' and 'no' respectively -->
  <xsl:param name="files" select="'*.xml'"/>
  <xsl:param name="recurse" select="'yes'"/>

  <!-- path hard-coded to location on my desktop
    Make sure all XML files are ones you want to include
  -->
  <xsl:variable name="path">
    <xsl:value-of
      select="concat('file:///home/jamesc/git/medieval-mss/collections/?select=', $files,';on-error=warning;recurse=',$recurse)"/>
  </xsl:variable>

  <!-- the main collection of all the documents we are dealing with -->
  <xsl:variable name="doc" select="collection($path)"/>


  <!-- In case there are existing schema associations, let's get rid of those -->
  <xsl:template match="processing-instruction()"/>

  <!-- Named template which we call that starts off the whole thing-->
  <xsl:template name="main">
    <!-- For each item in the collection -->
    <xsl:for-each select="$doc">
      <!-- Might as well sort them by current file name -->
      <xsl:sort select="tokenize(base-uri(), '/')[last()-1]"/>
      <xsl:sort select="tokenize(base-uri(), '/')[last()]"/>
      <!-- Get the baseURI -->
      <xsl:variable name="baseURI">
        <xsl:value-of select="base-uri()"/>
      </xsl:variable>
      <!-- Get the file name from that -->
      <xsl:variable name="filename">
        <xsl:value-of select="tokenize($baseURI, '/')[last()]"/>
      </xsl:variable>
      <!-- get the folder from that -->
      <xsl:variable name="folder">
        <xsl:value-of select="tokenize($baseURI, '/')[last()-1]"/>
      </xsl:variable>
      <!-- Get the @xml:id from the first msDesc inside the sourceDesc 
        (won't work if msDesc elsewhere but stops problem with nested msDesc)
      -->
      <xsl:variable name="msID">
        <xsl:value-of select="//sourceDesc/msDesc[1]/@xml:id"/>
      </xsl:variable>

      <!-- This is just a debugging message so I see the msIDs whiz by on the screen
        in case of any errors
      -->
      <xsl:message>
        <!--
        Folder: <xsl:value-of select="$folder"/> 
        Old Filename:<xsl:value-of select="$filename"/>-->
        <xsl:value-of select="$msID"/>
      </xsl:message>

      <!-- Create the output file name hard coded to my dev machine-->
      <xsl:variable name="outputFilename"
        select="concat('file:///home/jamesc/git/medieval-mss/processing/html/', 
      $folder, '/', $msID, '.html')"/>
      <!-- create output file -->
      <xsl:result-document href="{$outputFilename}" method="xml" indent="yes">
        <!-- I was asked for just <div> elements but provided full html... can remove if necessary here -->
        <html>
          <head>
            <title>
              <xsl:value-of select="//msDesc/msIdentifier/idno[@type='shelfmark']"/>
            </title>
          </head>
          <body>
            <!-- Create content div with the id of the manuscript -->
            <div class="content" id="{//sourceDesc/msDesc[1]/@xml:id}">
              <!-- titleStmt div with the two titles in -->
              <div class="titleStmt" id="titleStmt">
                <h1 class="mainTitle">
                  <xsl:value-of select="/TEI/teiHeader/fileDesc/titleStmt/title[1]"/>
                </h1>
                <h2 class="collectionTitle">
                  <xsl:value-of select="/TEI/teiHeader/fileDesc/titleStmt/title[@type='collection']"/>
                </h2>
              </div>

              <!-- Go do everything you need to msDesc -->
              <xsl:apply-templates select="//msDesc"/>

              <!-- Now let's have some publication and editorial metadata -->
              <div class="publicationStmt" id="publicationStmt">
                <h3 class="publicationStmtHeading">Publication Statement</h3>
                <p class="publisher">Published by <xsl:value-of select="/TEI/teiHeader/fileDesc/publicationStmt/publisher"/>
                  <xsl:apply-templates select="/TEI/teiHeader/fileDesc/publicationStmt/address"/>
                </p>
                <p class="distributor">Contact: <a class="distributorEmail"
                    href="{normalize-space(/TEI/teiHeader/fileDesc/publicationStmt/distributor/email)}"><xsl:value-of
                      select="normalize-space(/TEI/teiHeader/fileDesc/publicationStmt/distributor/email)"/></a></p>
                <xsl:if test="/TEI/teiHeader/fileDesc/publicationStmt/availability/licence">
                  <p class="availability">License: <xsl:apply-templates
                      select="/TEI/teiHeader/fileDesc/publicationStmt/availability/licence"/></p>
                </xsl:if>
              </div>

              <!-- And some edition and responsibility statements -->
              <div class="respStmt" id="respStmt">
                <h3>Description Edition and Responsibilities</h3>
                <ul class="editionAndResponsibilities">
                  <xsl:apply-templates select="/TEI/teiHeader/fileDesc/editionStmt/edition"/>
                  <xsl:apply-templates select="/TEI/teiHeader/fileDesc/titleStmt/respStmt"/>
                  <xsl:apply-templates select="/TEI/teiHeader/fileDesc/editionStmt/respStmt"/>
                  <xsl:apply-templates select="/TEI/teiHeader/revisionDesc"/>
                </ul>
              </div>

              <!-- And a comment in a footer, just for the fun of it. -->
              <div class="footer">
                <xsl:comment>HTML fragments generated by Dr James Cummings, <xsl:value-of select="current-date()"/></xsl:comment>
              </div>
            </div>
          </body>
        </html>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>

  <!-- Templates for titleStmt titles and normal titles, author, editors, and related content -->
  <xsl:template match="titleStmt/title">
    <li class="title">
      <span class="label">Title: </span>
      <xsl:apply-templates/>
      <xsl:if test="@type">(<xsl:value-of select="@type"/>)</xsl:if>
    </li>
  </xsl:template>
  <xsl:template match="title">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="author|editor">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="series">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="citedRange">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <!-- transcription related stuff like corr/date/add/dell/note/foreign/sic -->
  <xsl:template match="corr">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="date">
    <span class="{name()}">
      <xsl:if test="@when">
        <xsl:attribute name="title">
          <xsl:value-of select="@when"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="add|del">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="note">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="foreign">
    <span class="{name()}">
      <xsl:if test="@xml:lang">
        <xsl:attribute name="title">
          <xsl:value-of select="@xml:lang"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="sic">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>


  <xsl:template match="supplied">
    <span class="supplied">&lt;<xsl:apply-templates/>&gt;</span>
  </xsl:template>
  
  <xsl:template match="choice">
    <xsl:choose>
      <xsl:when test="sic and corr">
        <span class="sicAndCorr"><xsl:apply-templates select="sic"/> [<span class="italic">sic for</span>
          <xsl:apply-templates select="corr"/>]</span>
      </xsl:when>
      <xsl:when test="sic and not(corr)">
        <span class="sicAndNotCorr"><xsl:apply-templates select="sic"/> [<span class="italic">sic</span>]</span>
      </xsl:when>
      <xsl:when test="abbr and expan">
        <span class="expan" title="{abbr}">
          <xsl:apply-templates select="expan"/>
        </span>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="abbr">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <xsl:template match="unclear">
    <span class="unclear">
      <xsl:apply-templates/>
      <span class="unclearMarker"> (?)</span>
    </span>
  </xsl:template>
  
  
  
  <xsl:template match="gap">
    <xsl:choose>
      <xsl:when test="not(@*)">
        <span class="gap">…</span>
      </xsl:when>
      <xsl:when test="@unit='chars' and number(@quantity)">
        <xsl:variable name="possibleDots"
          >.....................................................................................................................</xsl:variable>
        <span class="gap">
          <xsl:value-of select="substring(normalize-space($possibleDots), 1, number(@quantity))"/>
        </span>
      </xsl:when>
      <xsl:when test="@unit='chars' and number(@extent)">
        <xsl:variable name="possibleDots"
          >.....................................................................................................................</xsl:variable>
        <span class="gap">
          <xsl:value-of select="substring(normalize-space($possibleDots), 1, number(@extent))"/>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <span class="gap">…</span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="expan | ex">
    <span class="expan">(<xsl:apply-templates/>)</span>
  </xsl:template>
  
  

<!-- editions -->
  <xsl:template match="editionStmt/edition">
    <li class="title">
      <span class="label">Edition: </span>
      <xsl:apply-templates/>
      <xsl:if test="@type">(<xsl:value-of select="@type"/>)</xsl:if>
    </li>
  </xsl:template>

<!-- responsibility and revisions -->
  <xsl:template match="respStmt">
    <li class="respStmt">
      <xsl:apply-templates select="resp"/>
      <xsl:if test="persName">(<xsl:value-of select="persName"/>)</xsl:if>
    </li>
  </xsl:template>
  <xsl:template match="resp">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="revisionDesc">
    <li class="revisionDesc">
      <ul class="revisionDesc">
        <xsl:apply-templates/>
      </ul>
    </li>
  </xsl:template>
  <xsl:template match="revisionDesc//change">
    <li class="change">
      <span class="label">Change: </span>
      <xsl:if test="@when">
        <span class="date"><xsl:value-of select="@when"/> -- </span>
      </xsl:if>
      <xsl:apply-templates/>
    </li>
  </xsl:template>

<!-- Refs, with targets and without -->
  <xsl:template match="ref[@target]" priority="10">
    <a href="{@target}">
      <xsl:apply-templates/>
    </a>
  </xsl:template>
  <xsl:template match="ref" priority="5">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

<!-- addresses, dealt with as requested. -->
  <xsl:template match="address">
    <xsl:for-each select="*">
      <xsl:value-of select="."/>
      <xsl:if test="not(last())">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

<!-- lb to br -->
  <xsl:template match="lb">
    <br/>
  </xsl:template>



<!-- Main msDesc template and processing starts here -->
  <xsl:template match="msDesc[@xml:id]">
    <div class="msDesc" id="{concat(@xml:id, '-msDesc', count(preceding::msDesc)+1)}">
      <xsl:if test="@xml:lang">
        <xsl:attribute name="lang">
          <xsl:value-of select="@xml:lang"/>
        </xsl:attribute>
      </xsl:if>
      <h2 class="msDesc-heading2">
        <xsl:value-of select="msIdentifier/idno[@type='shelfmark']"/>
      </h2>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

<!-- Just a warning template if an msDesc doesn't have an @xml:id -->
  <xsl:template match="msDesc">
    <xsl:message>No msDesc ID on <xsl:value-of select="$doc//sourceDesc/msDesc[1]/@xml:id"/></xsl:message>
    <div class="msDesc">
      <xsl:if test="@xml:lang">
        <xsl:attribute name="lang">
          <xsl:value-of select="@xml:lang"/>
        </xsl:attribute>
      </xsl:if>
      <h2 class="msDesc-heading2">
        <xsl:value-of select="msIdentifier/idno[@type='shelfmark']"/>
      </h2>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- Paragraphs -->
  <xsl:template match="p">
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- Default rule for head see msPart head below.-->
  <xsl:template match="head">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <!-- Main Sections inside msDesc-->
  <xsl:template match="msDesc/msIdentifier|msDesc/head|msPart/head|msContents|physDesc|additional|msPart|msFrag">
    <div class="{name()}">
      <h3 class="msDesc-heading3">
        <xsl:choose>
          <xsl:when test="name()='msIdentifier'">Manuscript Identifier</xsl:when>
          <xsl:when test="name()='head'">Summary</xsl:when>
          <xsl:when test="name()='msContents'">Contents</xsl:when>
          <xsl:when test="name()='physDesc'">Physical Description</xsl:when>
          <xsl:when test="name()='additional'">Additional Metadata</xsl:when>
          <xsl:when test="name()='msPart'">
            <xsl:value-of select=".//idno[1]"/>
          </xsl:when>
          <xsl:when test="name()='msFrag'">
            <xsl:value-of select=".//idno[1]"/>
          </xsl:when>
        </xsl:choose>
      </h3>
      <xsl:choose>
        <xsl:when test="name()='msIdentifier'">
          <ul class="msIdentifier">
            <xsl:apply-templates/>
          </ul>
        </xsl:when>
        <xsl:when test="name()='physDesc'">
          <ul class="physDesc">
            <xsl:apply-templates/>
          </ul>
        </xsl:when>
        <xsl:when test="name()='additional'">
          <ul class="additional">
            <xsl:apply-templates/>
          </ul>
        </xsl:when>
        <xsl:when test="name()='msPart' or name()='msFrag'">
          <ul class="{name()}">
            <xsl:apply-templates/>
          </ul>
        </xsl:when>
        <xsl:when test="name()='head'">
          <p class="msHead">
            <span class="label">Summary:</span>
            <xsl:apply-templates/>
          </p>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

  <!-- special case history -->
  <xsl:template match="history">
    <div class="{name()}">
      <h3 class="msDesc-heading3">History</h3>
<!-- if Origin make it a paragraph -->
      <xsl:if test="origin">
        <p class="origin">
          <span class="label">Origin: </span>
          <xsl:apply-templates select="origin"/>
        </p>
      </xsl:if>
      
      <xsl:if test="provenance or acquisition">
        <p class="provenance">
          <span class="label">Provenance and Acquisition: </span>
          <xsl:apply-templates select="provenance | acquisition"/>
        </p>
      </xsl:if>
    </div>
  </xsl:template>
  <!-- inside history -->
  <xsl:template match="origin">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="origin/origDate">
    <xsl:if test="not(preceding-sibling::origDate)">
      <br/>
    </xsl:if>
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="origin/origPlace">
    <xsl:if test="not(preceding-sibling::origPlace)">
      <br/>
    </xsl:if>
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="origin/p|provenance/p|acquisition/p">
    <br/>
    <span class="{concat(name(), '-p')}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="provenance|acquisition">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="origPlace">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

<!-- quotations - should I be putting in quotation marks? -->
  <xsl:template match="q">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>


  <!-- msIdentifier -->
  <xsl:template match="msIdentifier">
    <ul class="msIdentifier">
      <xsl:apply-templates/>
    </ul>
  </xsl:template>

  <xsl:template match="msIdentifier/*">
    <li class="{name()}">
      <span class="label">
        <xsl:choose>
          <xsl:when test="name()='country'">Country: </xsl:when>
          <xsl:when test="name()='institution'">Institution: </xsl:when>
          <xsl:when test="name()='msName'">Manuscript Name: </xsl:when>
          <xsl:when test="name()='region'">Region: </xsl:when>
          <xsl:when test="name()='repository'">Repository: </xsl:when>
          <xsl:when test="name()='settlement'">Settlement: </xsl:when>
          <xsl:when test="name()='altIdentifier' or name()='idno'">
            <xsl:choose>
              <xsl:when test="idno/@type='shelfmark' or @type='shelfmark'">ShelfMark: </xsl:when>
              <xsl:when test="idno/@type='SCN' or @type='SCN'">Summary Catalogue no.: </xsl:when>
              <xsl:when test="@type='TM' or idno/@type='TM'">Trismegistos no.: </xsl:when>
              <xsl:when test="@type='PR'">Papyrological Reference: </xsl:when>
              <xsl:when test="@type='diktyon'">Diktyon no.: </xsl:when>
              <xsl:when test="@type='LDAB'">LDAB no.: </xsl:when>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <xsl:template match="altIdentifier/idno">
    <xsl:apply-templates/>
  </xsl:template>
  
  
  <!-- Things in msContents -->
  
  <xsl:template match="msContents/summary">
    <p class="msSummary">
      <span class="label">Summary of Contents: </span>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="msContents/summary/p">
    <span class="summary-p">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="msContents/textLang">
    <p class="ContentsTextLang">
      <xsl:apply-templates/>
    </p>
  </xsl:template>


<!-- msItem -->
  <xsl:template match="msContents/msItem" priority="10">
    <div class="msItem" id="{@xml:id}">
      <xsl:if test="@n">
        <span class="label">
          <xsl:value-of select="@n"/>
        </span>
      </xsl:if>
      <ul>
        <xsl:apply-templates/>
      </ul>
    </div>
  </xsl:template>
  <!-- nested msItem -->
  <xsl:template match="msItem/msItem">
    <li class="nestedmsItem" id="{@xml:id}">
      <xsl:if test="@n">
        <span class="label">
          <xsl:value-of select="@n"/>
        </span>
      </xsl:if>
      <ul class="nestedmsItemList">
        <xsl:apply-templates/>
      </ul>
    </li>
  </xsl:template>

<!-- things in msItem -->
  <xsl:template match="msItem/author | msItem/docAuthor">
    <li class="author">
      <xsl:apply-templates/>
      <xsl:if test="following-sibling::title[1]">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </li>
  </xsl:template>
  <xsl:template match="msItem/editor">
    <li class="editor">
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="msItem/bibl">
    <xsl:choose>
      <xsl:when test="@type='bible' or @type='commentedOn' or @type='commentary' or @type='related'"/>
      <xsl:otherwise>
        <li class="bibl">
          <xsl:apply-templates/>
          <xsl:if test="following-sibling::title[1]">
            <xsl:text>, </xsl:text>
          </xsl:if>
        </li>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="msItem/title">
    <li class="title">
      <xsl:apply-templates/>
      <xsl:if
        test="following-sibling::note[1][not(starts-with(., '('))][not(starts-with(., '[A-Z]'))][not(following-sibling::lb[1])]">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </li>
  </xsl:template>
  <xsl:template match="msItem/note">
    <li class="{name()}">
      <span class="label">Note: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="msItem/quote">
    <li class="{name()}">"<xsl:apply-templates/>"</li>
  </xsl:template>
  <xsl:template match="msItem/incipit | msItem/explicit">
    <li class="{name()}">
      <span class="label">(<xsl:value-of select="name()"/>)</span>
      <xsl:if test="@defective='true'">
        <span class="defective">||</span>
      </xsl:if>
      <xsl:if test="@type">
        <span class="type">(<xsl:value-of select="@type"/>)</span>
      </xsl:if>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="msItem/rubric">
    <li class="{name()}">
      <span class="label">(<xsl:value-of select="name()"/>)</span>
      <span>
        <xsl:if test="not(@rend='roman')">
          <xsl:attribute name="class">italic</xsl:attribute>
        </xsl:if>
        <xsl:apply-templates/>
      </span>
    </li>
  </xsl:template>
  <xsl:template match="msItem/finalRubric">
    <li class="{name()}">
      <span class="label">(final rubric)</span>
      <span>
        <xsl:if test="not(@rend='roman')">
          <xsl:attribute name="class">italic</xsl:attribute>
        </xsl:if>
        <xsl:apply-templates/>
      </span>
    </li>
  </xsl:template>
  <xsl:template match="msItem/colophon">
    <li class="{name()}">
      <span class="label">(colophon)</span>
      <span>
        <xsl:if test="not(@rend='roman')">
          <xsl:attribute name="class">italic</xsl:attribute>
        </xsl:if>
        <xsl:apply-templates/>
      </span>
    </li>
  </xsl:template>
  <xsl:template match="msItem/filiation">
    <li class="{name()}">
      <span class="label">(filiation)</span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="msItem/textLang">
    <li class="{name()}">
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <xsl:template match="msItem/filiation">
    <li class="{name()}">
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="msItem/locus">
    <li class="{name()}">
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <!-- fallback for msItem children -->
  <xsl:template match="msItem/*" priority="-10">
    <li class="{name()}">
      <xsl:apply-templates/>
    </li>
  </xsl:template>


  <!-- Things inside physDesc -->

  <xsl:template match="physDesc/p">
    <li class="physDesc-p">
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="accMat">
    <li class="accMat">
      <span class="label">Accompanying Material: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="additions">
    <li class="additions">
      <span class="label">Additions: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="bindingDesc">
    <li class="bindingDesc">
      <span class="label">Binding: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="binding">
    <p class="binding">
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="binding/p|collation/p|foliation/p">
    <span class="{concat(parent::node()/name(), '-p')}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="decoDesc">
    <li class="decoDesc">
      <span class="label">Decoration: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="handDesc">
    <li class="handDesc">
      <span class="label">Hand(s): </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
 <xsl:template match="decoDesc/*|handDesc/*">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="decoNote|handNote" priority="20">
    <p class="{name()}">
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="decoDesc/p|handDesc/p|decoNote/p|handNote/p" priority="10">
    <span class="{concat(parent::node()/name(), '-p')}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="decoNote//list|handNote//list|support//list" priority="10">
    <span class="{concat(parent::node()/name(), '-list')}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="decoNote/list/item|handNote/list/item|support//item" priority="10">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
    <br/>
  </xsl:template>
   <!-- where all the text inside a decoNote (e.g. not nested children) = ' Decoration' get rid of it -->
  <xsl:template match="decoNote/text()[normalize-space(.) = 'Decoration']"/>
  <xsl:template match="decoNote/list/head|decoNote/list/label|handNote/list/head|handnote/list/label" priority="10">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="musicNotation">
    <li class="musicNotation">
      <span class="label">Musical Notation: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="typeDesc">
    <li class="typeDesc">
      <span class="label">Type(s): </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="sealDesc">
    <li class="sealDesc">
      <span class="label">Seal(s): </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="scriptDesc">
    <li class="">
      <span class="label">Script(s): </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="objectDesc">
    <li class="objectDesc">
      <span class="label">Format: </span>
      <xsl:if test="@form">
        <span class="form">
          <xsl:value-of select="@form"/>
        </span>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="p|ab">
          <xsl:apply-templates/>
        </xsl:when>
        <xsl:otherwise>
          <ul class="objectDesc">
            <xsl:apply-templates/>
          </ul>
        </xsl:otherwise>
      </xsl:choose>
    </li>
  </xsl:template>
  <xsl:template match="layoutDesc">
    <li class="layoutDesc">
      <span class="label">Layout: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="layoutDesc/*">
    <p class="{name()}">
      <xsl:if test="@columns">
        <span class="label">Columns: </span>
        <span class="columns">
          <xsl:value-of select="@columns"/>
        </span>
        <br/>
      </xsl:if>
      <xsl:if test="@ruledLine">
        <span class="label">Ruled Lines: </span>
        <span class="ruledLines">
          <xsl:value-of select="@ruledLines"/>
        </span>
        <br/>
      </xsl:if>
      <xsl:if test="@writtenLines">
        <span class="label">Written Lines: </span>
        <span class="writtenLines">
          <xsl:value-of select="@writtenLines"/>
        </span>
        <br/>
      </xsl:if>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="supportDesc">
    <li class="supportDesc">
      <span class="label">Support: </span>
      <xsl:if test="@material">
        <span class="label">Material: </span>
        <span class="material">
          <xsl:value-of select="@material"/>
        </span>
        <br/>
      </xsl:if>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  
  <!-- misc phrase-level elements used inside physDesc -->
  <xsl:template match="material">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="measure">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="num">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

<!-- Seals -->
  <xsl:template match="seal">
    <p class="{name()}">
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="seal/p">
    <span class="seal-p">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!--  collation condition foliation support -->
  <xsl:template match="collation">
    <p class="{name()}">
      <span class="label">Collation: </span>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="condition">
    <p class="{name()}">
      <span class="label">Condition: </span>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="foliation">
    <p class="{name()}">
      <span class="label">Foliation: </span>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="support">
    <p class="{name()}">
      <span class="label">Material Support: </span>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

<!-- secFol, locus, extent -->
  <xsl:template match="secFol">
    <span class="label">Secundo Folio: </span>
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
    <br/>
  </xsl:template>
  <xsl:template match="locus">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="extent">
    <span class="label">Extent: </span>
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
    <br/>
  </xsl:template>

<!-- deal with dimensions -->
  <xsl:template match="dimensions">
    <span class="label">Dimensions<xsl:if test="@type"> (<xsl:value-of select="@type"/>)</xsl:if>: </span>
    <span class="{name()}">
      <xsl:choose>
        <xsl:when test="height and width">
          <span class="height">
            <xsl:value-of select="height"/>
          </span>
          <span class="x"> × </span>
          <span class="width">
            <xsl:value-of select="width"/>
          </span>
          <xsl:choose>
            <xsl:when test="@unit">
              <span class="unit"><xsl:value-of select="@unit"/>.</span>
            </xsl:when>
            <xsl:when test="height/@unit">
              <span class="unit"><xsl:value-of select="height/@unit"/>.</span>
            </xsl:when>
            <xsl:when test="width/@unit">
              <span class="unit"><xsl:value-of select="width/@unit"/>.</span>
            </xsl:when>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </span>
    <br/>
  </xsl:template>
  <xsl:template match="height|width">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

<!-- formula, catchwords, signatures, watermarks  -->
  <xsl:template match="formula">
    <span class="formula">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="catchwords | signatures">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="watermark">
    <span class="{name()}">
      <span class="label">Watermark: </span>
      <xsl:apply-templates/>
    </span>
  </xsl:template>


<!-- hi used for ad hoc formatting -->
  <xsl:template match="hi">
    <span>
      <xsl:attribute name="class">hi <xsl:value-of select="@rend"/></xsl:attribute>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="listBibl">
    <ul class="listBibl">
      <xsl:apply-templates/>
    </ul>
  </xsl:template>

  <xsl:template match="list/item|listBibl/bibl">
    <li class="{name()}">
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <xsl:template match="bibl">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="note//bibl|p//bibl|title//bibl|physDesc//bibl">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>


<!-- Things inside additional -->
  <xsl:template match="additional/listBibl">
    <li class="listBibl">
      <span class="label">Bibliography</span>
      <ul class="listBibl">
        <xsl:apply-templates/>
      </ul>
    </li>
  </xsl:template>

  <xsl:template match="additional/surrogates">
    <li class="surrogates">
      <ul class="surrogates">
        <xsl:apply-templates/>
      </ul>
    </li>
  </xsl:template>

  <xsl:template match="additional/adminInfo">
    <li class="adminInfo">
      <ul class="adminInfo">
        <xsl:apply-templates/>
      </ul>
    </li>
  </xsl:template>

  <xsl:template match="adminInfo/*">
    <li class="{name()}">
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <xsl:template match="source">
    <ul>
      <xsl:if test="text()[1]">
        <li>
          <xsl:apply-templates select="text()[1]"/>
        </li>
      </xsl:if>
      <xsl:apply-templates select="*"/>
    </ul>
  </xsl:template>
  <xsl:template match="source/*">
    <li class="{name()}">
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <xsl:template match="source/listBibl" priority="10">
    <li class="{name()}">
      <ul class="{name()}">
        <xsl:apply-templates/>
      </ul>
    </li>
  </xsl:template>
  <!-- names -->
  <xsl:template match="persName|placeName|orgName|name|country|settlement|district|region">
    <span class="{name()}">
      <xsl:choose>
        <xsl:when test="@ref">
          <a href="{@ref}">
            <xsl:apply-templates/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </span>
  </xsl:template>

  <xsl:template match="heraldry">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="label">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="list">
    <ul class="{name()}">
      <xsl:apply-templates/>
    </ul>
  </xsl:template>
  <xsl:template match="list/head">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="seg">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>



  <!-- catch all fallback: this is there to warn me of elements I don't have templates for and should never fire otherwise-->
  <xsl:template match="*" priority="-100">
    <xsl:message>No template for: <xsl:value-of select="name()"/></xsl:message>
    <span class="{name()}">
      <xsl:apply-templates select="@*|node()"/>
    </span>
  </xsl:template>



</xsl:stylesheet>
