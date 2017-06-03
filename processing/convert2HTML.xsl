<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0"
                xmlns:jc="http://james.blushingbunny.net/ns.html"
                xmlns:html="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="tei jc html" version="2.0">

    <!--
    Created by Dr James Cummings james@blushingbunny.net
    2017-05 for output of Bodley TEI msDescs as HTML to
    be sucked into the frontend platform
    -->

    <!-- Set up the collection of files to be converted -->
    <!-- files and recurse parameters defaulting to '*.xml' and 'no' respectively -->
    <xsl:param name="files" select="'*.xml'"/>
    <xsl:param name="recurse" select="'yes'"/>
    <xsl:output omit-xml-declaration="yes" indent="yes"/>

    <!-- path hard-coded to location on my desktop
      Make sure all XML files are ones you want to include
    -->
    <xsl:variable name="path">
        <xsl:value-of
                select="concat('../collections/?select=', $files,';on-error=warning;recurse=',$recurse)"/>
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
                          select="concat('./html/', $folder, '/', $msID, '.html')"/>
            <!-- create output file -->
            <xsl:result-document href="{$outputFilename}" method="xml" indent="yes">
                <!-- I was asked for just <div> elements but provided full html... can remove if necessary here -->
                <!-- <html>
                  <head>
                    <title>
                      <xsl:value-of select="//msDesc/msIdentifier/idno[@type='shelfmark']"/>
                    </title>
                  </head>
                  <body> -->
                <!-- Create content div with the id of the manuscript -->
                <div class="content tei-body" id="{//sourceDesc/msDesc[1]/@xml:id}">
                    <!-- titleStmt div with the two titles in -->
                    <!-- For tolkien, Blacklight will take care of displaying the title and collection -->
                    <!-- <div class="titleStmt" id="titleStmt">
                      <h1 class="mainTitle">
                        <xsl:value-of select="/TEI/teiHeader/fileDesc/titleStmt/title[1]"/>
                      </h1>
                      <h2 class="collectionTitle">
                        <xsl:value-of select="/TEI/teiHeader/fileDesc/titleStmt/title[@type='collection']"/>
                      </h2>
                    </div> -->

                    <!-- Go do everything you need to msDesc -->
                    <xsl:apply-templates select="//msDesc"/>

                    <!-- Now let's have some publication and editorial metadata -->
                    <!-- <div class="publicationStmt" id="publicationStmt">
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
                    </div> -->

                    <!-- And some edition and responsibility statements -->
                    <!-- <div class="respStmt" id="respStmt">
                      <h3>Description Edition and Responsibilities</h3>
                      <ul class="editionAndResponsibilities">
                        <xsl:apply-templates select="/TEI/teiHeader/fileDesc/editionStmt/edition"/>
                        <xsl:apply-templates select="/TEI/teiHeader/fileDesc/titleStmt/respStmt"/>
                        <xsl:apply-templates select="/TEI/teiHeader/fileDesc/editionStmt/respStmt"/>
                        <xsl:apply-templates select="/TEI/teiHeader/revisionDesc"/>
                      </ul>
                    </div> -->

                    <!-- And a comment in a footer, just for the fun of it. -->
                    <div class="footer">
                        <xsl:comment>HTML fragments generated by Dr James Cummings,
                            <xsl:value-of select="current-date()"/>
                        </xsl:comment>
                    </div>
                </div>
                <!-- </body>
              </html> -->
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- Templates for titleStmt titles and normal titles, author, editors, and related content -->
    <xsl:template match="titleStmt/title">
        <li class="title">
            <span class="tei-label">Title:</span>
            <xsl:apply-templates/>
            <xsl:if test="@type">(<xsl:value-of select="@type"/>)
            </xsl:if>
        </li>
    </xsl:template>
    <xsl:template match="title">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <!-- <xsl:template match="author|editor">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template> -->
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
        <span class="supplied">&lt;<xsl:apply-templates/>&gt;
        </span>
    </xsl:template>

    <xsl:template match="choice">
        <xsl:choose>
            <xsl:when test="sic and corr">
                <span class="sicAndCorr">
                    <xsl:apply-templates select="sic"/>
                    [
                    <span class="italic">sic for</span>
                    <xsl:apply-templates select="corr"/>]
                </span>
            </xsl:when>
            <xsl:when test="sic and not(corr)">
                <span class="sicAndNotCorr">
                    <xsl:apply-templates select="sic"/>
                    [<span class="italic">sic</span>]
                </span>
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
            <span class="unclearMarker">(?)</span>
        </span>
    </xsl:template>


    <xsl:template match="gap">
        <xsl:choose>
            <xsl:when test="not(@*)">
                <span class="gap">…</span>
            </xsl:when>
            <xsl:when test="@unit='chars' and number(@quantity)">
                <xsl:variable name="possibleDots"
                >
                    .....................................................................................................................
                </xsl:variable>
                <span class="gap">
                    <xsl:value-of select="substring(normalize-space($possibleDots), 1, number(@quantity))"/>
                </span>
            </xsl:when>
            <xsl:when test="@unit='chars' and number(@extent)">
                <xsl:variable name="possibleDots"
                >
                    .....................................................................................................................
                </xsl:variable>
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
        <span class="expan">(<xsl:apply-templates/>)
        </span>
    </xsl:template>


    <!-- editions -->
    <xsl:template match="editionStmt/edition">
        <li class="title">
            <span class="tei-label">Edition:</span>
            <xsl:apply-templates/>
            <xsl:if test="@type">(<xsl:value-of select="@type"/>)
            </xsl:if>
        </li>
    </xsl:template>

    <!-- responsibility and revisions -->
    <xsl:template match="respStmt">
        <li class="respStmt">
            <xsl:apply-templates select="resp"/>
            <xsl:if test="persName">(<xsl:value-of select="persName"/>)
            </xsl:if>
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
            <span class="tei-label">Change:</span>
            <xsl:if test="@when">
                <span class="date">
                    <xsl:value-of select="@when"/> --
                </span>
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
            <!-- <h2 class="msDesc-heading2">
              <xsl:value-of select="msIdentifier/idno[@type='shelfmark']"/>
            </h2> -->
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- Just a warning template if an msDesc doesn't have an @xml:id -->
    <xsl:template match="msDesc">
        <xsl:message>No msDesc ID on
            <xsl:value-of select="$doc//sourceDesc/msDesc[1]/@xml:id"/>
        </xsl:message>
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
                    <xsl:when test="name()='head'">Summary</xsl:when>
                    <xsl:when test="name()='msContents'">Contents</xsl:when>
                    <xsl:when test="name()='physDesc'">Physical Description</xsl:when>
                    <xsl:when test="name()='additional'">Additional Metadata</xsl:when>
                    <!-- <xsl:when test="name()='msIdentifier'">Manuscript Identifier</xsl:when> -->
                    <xsl:when test="name()='msPart'">
                        <xsl:value-of select=".//idno[1]"/>
                    </xsl:when>
                    <xsl:when test="name()='msFrag'">
                        <xsl:value-of select=".//idno[1]"/>
                    </xsl:when>
                </xsl:choose>
            </h3>
            <xsl:choose>
                <xsl:when test="name()='physDesc'">
                    <div class="physDesc">
                        <xsl:apply-templates/>
                    </div>
                </xsl:when>
                <xsl:when test="name()='additional'">
                    <div class="additional">
                        <xsl:apply-templates/>
                    </div>
                </xsl:when>
                <xsl:when test="name()='msPart' or name()='msFrag'">
                    <div class="{name()}">
                        <xsl:apply-templates/>
                    </div>
                </xsl:when>
                <xsl:when test="name()='head'">
                    <div class="msHead">
                        <span class="tei-label">Summary: </span>
                        <xsl:apply-templates/>
                    </div>
                </xsl:when>
                <xsl:when test="name()='msIdentifier'"/>
                <!-- <xsl:when test="name()='msIdentifier'">
                  <div class="msIdentifier">
                    <xsl:apply-templates/>
                  </div>
                </xsl:when> -->
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
        <hr/>
    </xsl:template>

    <!-- special case history -->
    <xsl:template match="history">
        <div class="{name()}">
            <h3 class="msDesc-heading3">History</h3>
            <!-- if Origin make it a paragraph -->
            <xsl:if test="origin">
                <div class="origin">
                    <span class="tei-label">Origin: </span>
                    <xsl:apply-templates select="origin"/>
                </div>
            </xsl:if>

            <xsl:if test="provenance or acquisition">
                <div class="provenance">
                    <span class="tei-label">Provenance and Acquisition: </span>
                    <xsl:apply-templates select="provenance | acquisition"/>
                </div>
            </xsl:if>
        </div>
    </xsl:template>
    <!-- inside history -->
    <xsl:template match="origin">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="origin/origDate">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="origin/origPlace">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="origin/p|provenance/p|acquisition/p">
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
            <span class="tei-label">
                <xsl:choose>
                    <xsl:when test="name()='country'">Country:</xsl:when>
                    <xsl:when test="name()='institution'">Institution:</xsl:when>
                    <xsl:when test="name()='msName'">Manuscript Name:</xsl:when>
                    <xsl:when test="name()='region'">Region:</xsl:when>
                    <xsl:when test="name()='repository'">Repository:</xsl:when>
                    <xsl:when test="name()='settlement'">Settlement:</xsl:when>
                    <xsl:when test="name()='altIdentifier' or name()='idno'">
                        <xsl:choose>
                            <xsl:when test="idno/@type='shelfmark' or @type='shelfmark'">ShelfMark:</xsl:when>
                            <xsl:when test="idno/@type='SCN' or @type='SCN'">Summary Catalogue no.:</xsl:when>
                            <xsl:when test="@type='TM' or idno/@type='TM'">Trismegistos no.:</xsl:when>
                            <xsl:when test="@type='PR'">Papyrological Reference:</xsl:when>
                            <xsl:when test="@type='diktyon'">Diktyon no.:</xsl:when>
                            <xsl:when test="@type='LDAB'">LDAB no.:</xsl:when>
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
            <span class="tei-label">Summary of Contents:</span>
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
            <hr />
            <h4 class="tei-title">
                <xsl:choose>
                    <xsl:when test="title">
                        <xsl:value-of select="normalize-space(title[1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        [<xsl:value-of select="normalize-space(string-join(note/string(), ' '))"/>]
                    </xsl:otherwise>
                </xsl:choose>
            </h4>
            <div>
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>
    <!-- nested msItem -->
    <xsl:template match="msItem/msItem">
        <div class="nestedmsItem" id="{@xml:id}">
            <hr />
            <h3 class="tei-title">
                <xsl:value-of select="normalize-space(title[1])"/>
            </h3>
            <div class="msItemList">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>

    <!-- things in msItem -->
    <!-- don't do anything with an msItem title -->
    <xsl:template match="msItem/title"/>

    <xsl:template match="msItem/author | msItem/docAuthor">
        <div class="author">
            <span class="tei-label">Author: </span>
            <xsl:choose>
                <xsl:when test="@key">
                    <a href="/catalog/{@key}">
                        <xsl:value-of select="normalize-space(string-join(text(), ', '))"/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(string-join(text(), ', '))"/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    <xsl:template match="msItem/editor">
        <span class="editor">
            <xsl:value-of select="normalize-space(string-join(text(), ' (editor)'))"/>
        </span>
    </xsl:template>
    <xsl:template match="msItem/bibl">
        <xsl:choose>
            <xsl:when test="@type='bible' or @type='commentedOn' or @type='commentary' or @type='related'"/>
            <xsl:otherwise>
                <span class="bibl">
                    <xsl:apply-templates/>
                    <xsl:if test="following-sibling::title[1]">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- title has been moved above - AH -->
    <!-- <xsl:template match="msItem/title">
      <span class="title">
        <xsl:apply-templates/>
        <xsl:if
          test="following-sibling::note[1][not(starts-with(., '('))][not(starts-with(., '[A-Z]'))][not(following-sibling::lb[1])]">
          <xsl:text>, </xsl:text>
        </xsl:if>
      </span>
    </xsl:template> -->
    <xsl:template match="msItem/note">
        <div class="{name()}">
            <span class="tei-label">Note: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="msItem/quote">
        <blockquote class="{name()}">"<xsl:apply-templates/>"</blockquote>
    </xsl:template>
    <xsl:template match="msItem/incipit | msItem/explicit">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:if test="name() = 'incipit'">
                    Incipit:
                </xsl:if>
                <xsl:if test="name() = 'explicit'">
                    Explicit:
                </xsl:if>
            </span>
            <xsl:if test="@defective='true'">
                <span class="defective">||</span>
            </xsl:if>
            <xsl:if test="@type">
                <span class="type">(<xsl:value-of select="@type"/>)</span>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="msItem/rubric">
        <div class="{name()}">
            <span class="tei-label">Rubric: </span>
            <!--<xsl:if test="not(@rend='roman')">-->
                <!--<xsl:attribute name="class">tei-italic</xsl:attribute>-->
            <!--</xsl:if>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="msItem/finalRubric">
        <div class="{name()}">
            <span class="tei-label">Final rubric: </span>
            <!--<xsl:if test="not(@rend='roman')">-->
                <!--<xsl:attribute name="class">tei-italic</xsl:attribute>-->
            <!--</xsl:if>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="msItem/colophon">
        <div class="{name()}">
            <span class="tei-label">Colophon: </span>
            <!--<xsl:if test="not(@rend='roman')">-->
                <!--<xsl:attribute name="class">tei-italic</xsl:attribute>-->
            <!--</xsl:if>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="msItem/filiation">
        <div class="{name()}">
            <span class="tei-label">Filiation: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="msItem/textLang">
        <div class="{name()}">
            <span class="tei-label">Language: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/locus">
        <div class="{name()}">
            <span class="tei-label">Locus: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <!-- fallback for msItem children -->
    <!-- <xsl:template match="msItem/*" priority="-10">
      <span class="{name()}">
        <xsl:apply-templates/>
      </span>
    </xsl:template> -->


    <!-- Things inside physDesc -->

    <xsl:template match="physDesc/p">
        <span class="physDesc-p">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="accMat">
        <div class="accMat">
            <span class="tei-label">Accompanying Material: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="additions">
        <div class="additions">
            <span class="tei-label">Additions: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="bindingDesc">
        <div class="bindingDesc">
            <span class="tei-label">Binding: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="binding">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="binding/p|collation/p|foliation/p">
        <span class="{concat(parent::node()/name(), '-p')}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="decoDesc">
        <div class="decoDesc">
            <span class="tei-label">Decoration: </span>
            <xsl:choose>
                <xsl:when test="decoNote/p">
                    <xsl:value-of select="normalize-space(string-join(decoNote/p/text(), ' '))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(string-join(decoNote/text(), ' '))"/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    <xsl:template match="handDesc">
        <div class="handDesc">
            <span class="tei-label">Hand(s): </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="decoDesc/*|handDesc/*">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="decoNote|handNote" priority="20">
        <xsl:apply-templates />
    </xsl:template>
    <xsl:template match="decoDesc/p|handDesc/p|decoNote/p|handNote/p" priority="10">
        <div class="{concat(parent::node()/name(), '-p')}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="decoNote//list|handNote//list|support//list" priority="10">
        <div class="{concat(parent::node()/name(), '-list')}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="decoNote/list/item|handNote/list/item|support//item" priority="10">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <!-- where all the text inside a decoNote (e.g. not nested children) = ' Decoration' get rid of it -->
    <xsl:template match="decoNote/text()[normalize-space(.) = 'Decoration']"/>
    <xsl:template match="decoNote/list/head|decoNote/list/label|handNote/list/head|handnote/list/label" priority="10">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="musicNotation">
        <div class="musicNotation">
            <span class="tei-label">Musical Notation:</span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="typeDesc">
        <div class="typeDesc">
            <span class="tei-label">Type(s): </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="sealDesc">
        <div class="sealDesc">
            <span class="tei-label">Seal(s): </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="scriptDesc">
        <div class="">
            <span class="tei-label">Script(s): </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="objectDesc">
        <div class="objectDesc">
            <span class="tei-label">Format: </span>
            <xsl:if test="@form">
                <xsl:value-of select="@form"/>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="p|ab">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    <xsl:template match="layoutDesc">
        <div class="layoutDesc">
            <h4 class="tei-label">Layout</h4>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="layoutDesc/*">
        <div class="{name()}">
            <xsl:if test="@columns">
                <div class="layout-columns">
                    <span class="tei-label">Columns: </span>
                    <xsl:value-of select="@columns"/>
                </div>
            </xsl:if>
            <xsl:if test="@ruledLine">
                <div class="ruledLines">
                    <span class="tei-label">Ruled Lines: </span>
                    <xsl:value-of select="@ruledLines"/>
                </div>
            </xsl:if>
            <xsl:if test="@writtenLines">
                <div class="writtenLines">
                    <span class="tei-label">Written Lines: </span>
                    <xsl:value-of select="@writtenLines"/>
                </div>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="supportDesc">
        <!-- <div class="supportDesc"> -->
        <!-- <span class="tei-label">Support: </span> -->
        <xsl:if test="@material">
            <div class="material">
                <span class="tei-label">Material: </span>
                <xsl:variable name="material" select="@material" />
                <xsl:choose>
                    <xsl:when test="$material = 'perg'">
                        Parchment
                    </xsl:when>
                    <xsl:when test="$material = 'chart'">
                        Paper
                    </xsl:when>
                    <xsl:when test="$material = 'papyrus'">
                        Papyrus
                    </xsl:when>
                    <xsl:when test="$material = 'mixed'">
                        Mixed
                    </xsl:when>
                    <xsl:when test="$material = 'unknown'">
                        Unknown
                    </xsl:when>
                    <xsl:otherwise>
                        Other
                    </xsl:otherwise>
                </xsl:choose>
            </div>
        </xsl:if>
        <!-- </div> -->
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
        <div class="{name()}">
            <span class="tei-label">Collation: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="condition">
        <div class="{name()}">
            <span class="tei-label">Condition: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="foliation">
        <div class="{name()}">
            <span class="tei-label">Foliation: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <!-- this is handled with supportDesc@material - AH -->
    <!-- <xsl:template match="support">
        <div class="{name()}">
            <h5 class="tei-label">Material Support</h5>
            <xsl:apply-templates/>
        </div>
    </xsl:template> -->

    <!-- secFol, locus, extent -->
    <xsl:template match="secFol">
        <div class="{name()}">
            <span class="tei-label">Secundo Folio: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="locus">
        <div class="{name()}">
            <span class="tei-label">Locus: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="extent">
        <div class="{name()}">
            <span class="tei-label">Extent: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- deal with dimensions -->
    <xsl:template match="dimensions">
        <div class="{name()}">
            <span class="tei-label">Dimensions <xsl:if test="@type">(<xsl:value-of select="@type"/>)</xsl:if>:</span>
            <xsl:choose>
                <xsl:when test="height and width">
                    <span class="height">
                        <xsl:value-of select="height"/>×<xsl:value-of select="width"/>
                    </span>
                    <xsl:choose>
                        <xsl:when test="@unit">
                            <xsl:value-of select="@unit"/>.
                        </xsl:when>
                        <xsl:when test="height/@unit">
                            <xsl:value-of select="height/@unit"/>.
                        </xsl:when>
                        <xsl:when test="width/@unit">
                            <xsl:value-of select="width/@unit"/>.
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    <xsl:template match="height|width">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <!-- formula, catchwords, signatures, watermarks  -->
    <xsl:template match="formula">
        <div class="formula">
            <span class="tei-label">Formula: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="catchwords | signatures">
        <div class="{name()}">
            <span class="tei-label">Catchwords: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="watermark">
        <div class="{name()}">
            <span class="tei-label">Watermark: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- hi used for ad hoc formatting -->
    <xsl:template match="hi">
        <span>
            <xsl:attribute name="class">
                <xsl:value-of select="@rend"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="listBibl">
        <div class="listBibl">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="list/item|listBibl/bibl">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="bibl">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="note//bibl|p//bibl|title//bibl|physDesc//bibl">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>


    <!-- Things inside additional -->
    <xsl:template match="additional/listBibl">
        <div class="listBibl">
            <h5 class="tei-label">Bibliography</h5>
            <ul class="listBibl">
                <xsl:apply-templates/>
            </ul>
        </div>
    </xsl:template>

    <xsl:template match="additional/surrogates">
        <div class="surrogates">
            <xsl:choose>
                <xsl:when test="bibl/@facs">
                    <a href="{bibl/@facs}">
                        <xsl:apply-templates/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <xsl:template match="additional/adminInfo">
        <div class="adminInfo">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="adminInfo/*">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="source">
        <div>
            <xsl:if test="text()[1]">
                <div>
                    <xsl:apply-templates select="text()[1]"/>
                </div>
            </xsl:if>
            <xsl:apply-templates select="*"/>
        </div>
    </xsl:template>
    <xsl:template match="source/*">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="source/listBibl" priority="10">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <!-- names and places -->
    <xsl:template match="persName|author|placeName|orgName|name|country|settlement|district|region">
        <span class="{name()}">
            <xsl:choose>
                <xsl:when test="@key">
                    <a href="/catalog/{@key}">
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
    <!-- <xsl:template match="*" priority="-100">
      <xsl:message>No template for: <xsl:value-of select="name()"/></xsl:message>
      <span class="{name()}">
        <xsl:apply-templates select="@*|node()"/>
      </span>
    </xsl:template> -->


</xsl:stylesheet>
