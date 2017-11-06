<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xpath-default-namespace="http://www.tei-c.org/ns/1.0"
                xmlns:jc="http://james.blushingbunny.net/ns.html"
                xmlns:html="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="tei jc html" version="2.0">
    <!--
        Created by Dr James Cummings james@blushingbunny.net
        2017-05 for output of Bodley TEI msDescs as HTML to
        be sucked into the frontend platform.
    -->
    <!-- Set up the collection of files to be converted -->
    <!-- files and recurse parameters defaulting to '*.xml' and 'no' respectively -->
    <xsl:param name="files" select="'*.xml'"/>
    <xsl:param name="recurse" select="'yes'"/>
    <!-- <xsl:strip-space elements="*" />
    <xsl:output omit-xml-declaration="yes" method="xml" indent="yes"/> -->
    <!--
      Make sure all XML files are ones you want to include
    -->
    <xsl:variable name="path">
        <xsl:value-of select="concat('../collections/?select=', $files,';on-error=warning;recurse=',$recurse)"/>
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

            <!-- This is just a debugging message so I see the msIDs whiz by on the screen in case of any errors -->
            <xsl:message>
                <!--
                    Folder: <xsl:value-of select="$folder"/>
                    Old Filename:<xsl:value-of select="$filename"/>
                -->
                <xsl:value-of select="$msID"/>
            </xsl:message>

            <!-- Create the output file name hard coded to my dev machine-->
            <xsl:variable name="outputFilename" select="concat('./html/', $folder, '/', $msID, '.html')"/>

            <!-- create output file -->
            <xsl:result-document href="{$outputFilename}" method="xml" indent="yes">

                <!-- Create content div with the id of the manuscript. Wrap it in an extra root div so that
                    we can ignore the namespace attribute that XSLT puts on it automatically. -->
                <div>
                <div class="content tei-body" id="{//TEI/@xml:id}">
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
                </div>
                </div>
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

    <!-- new: default title should be in italic -->
    <xsl:template match="title">
        <span class="{name()} italic">
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
        <!-- modified to add @rend to the class -->
        <span class="{name()} {@rend}">
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
        <span class="supplied">[<xsl:apply-templates/>]</span>
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
                <xsl:variable name="possibleDots">
                    .....................................................................................................................
                </xsl:variable>
                <span class="gap">
                    <xsl:value-of select="substring(normalize-space($possibleDots), 1, number(@quantity))"/>
                </span>
            </xsl:when>
            <xsl:when test="@unit='chars' and number(@extent)">
                <xsl:variable name="possibleDots">
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
        <!-- was: class = expan, changed 6.11.17 to better match TEI guidelines. ex=parts of words. -->
        <span class="ex">(<xsl:apply-templates/>)
        </span>
    </xsl:template>

    <!-- editions -->
    <xsl:template match="editionStmt/edition">
        <li class="title">
            <span class="tei-label">Edition: </span>
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
            <span class="tei-label">Change: </span>
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
        <div class="msDesc" id="{concat(@xml:id, '-msDesc', count(preceding::msDesc) + 1)}">
            <xsl:if test="@xml:lang">
                <xsl:attribute name="lang">
                    <xsl:value-of select="@xml:lang"/>
                </xsl:attribute>
            </xsl:if>

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

    <!-- skip output of msIdentifier block with subtype for now - AH -->
    <!-- was: <xsl:template match="msIdentifier/altIdentifier/idno/@subtype" /> 23.10 -->
    <xsl:template match="msIdentifier/altIdentifier/idno[@subtype]" />
    <xsl:template match="msIdentifier/institution | msIdentifier/region | msIdentifier/country | msIdentifier/settlement | msIdentifier/repository | msIdentifier/idno[@type='shelfmark']" />


    <!-- altidentifier/idno is all we want from this section, and not if subtype="alt" -->
    <!-- altidentifier with subtype alt should not be matched, otherwise we get an empty div which interferes with display [e.g. http://medieval-qa.bodleian.ox.ac.uk/catalog/manuscript_4968] -->
    <xsl:template match="msDesc/msIdentifier/altIdentifier[child::idno[not(@subtype)]]">
        <div class="msIdentifier">
            <xsl:choose>
                <!--<xsl:when test="idno/@type='shelfmark' or @type='shelfmark'">ShelfMark:</xsl:when>-->
                <!-- spaces after ':' added 26.6 -->
                <xsl:when test="idno[not(@subtype)]/@type='SCN'">Summary Catalogue no.: <xsl:apply-templates/></xsl:when>
                <xsl:when test="idno[not(@subtype)]/@type='TM' or idno/@type='TM'">Trismegistos no.: <xsl:apply-templates/></xsl:when>
                <xsl:when test="idno[not(@subtype)]/@type='PR'">Papyrological Reference: <xsl:apply-templates/></xsl:when>
                <xsl:when test="idno[not(@subtype)]/@type='diktyon'">Diktyon no.: <xsl:apply-templates/></xsl:when>
                <xsl:when test="idno[not(@subtype)]/@type='LDAB'">LDAB no.: <xsl:apply-templates/></xsl:when>
            </xsl:choose>
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
        <h4 class="{name()}">
            <xsl:apply-templates/>
        </h4>
    </xsl:template>

    <!-- Main Sections inside msDesc-->
    <xsl:template match="msDesc/head|msPart/head|msContents|physDesc|additional|msPart|msFrag">
        <!--<h3 class="msDesc-heading3">-->
            <!--<xsl:choose>-->
                <!--&lt;!&ndash; this heading may not be necessary,and is repeated on the following line in display &ndash;&gt;-->
                <!--<xsl:when test="name()='head'">Summary</xsl:when>-->
                <!--<xsl:when test="name()='msContents'">Contents</xsl:when>-->
                <!--<xsl:when test="name()='physDesc'">Physical Description</xsl:when>-->
                <!--<xsl:when test="name()='additional'">Additional Metadata</xsl:when>-->
                <!--&lt;!&ndash; <xsl:when test="name()='msIdentifier'">Manuscript Identifier</xsl:when> &ndash;&gt;-->
                <!--<xsl:when test="name()='msPart'">-->
                    <!--<xsl:value-of select=".//idno[1]"/>-->
                <!--</xsl:when>-->
                <!--<xsl:when test="name()='msFrag'">-->
                    <!--<xsl:value-of select=".//idno[1]"/>-->
                <!--</xsl:when>-->
            <!--</xsl:choose>-->
        <!--</h3>-->
        <xsl:choose>
            <xsl:when test="name()='msContents'">
                <h3>Contents</h3>
                <div class="msContents">
                    <xsl:apply-templates />
                </div>
            </xsl:when>
            <xsl:when test="name()='physDesc'">
                <h3>Physical Description</h3>
                <div class="physDesc">
                    <xsl:apply-templates/>
                </div>
            </xsl:when>
            <xsl:when test="name()='additional'">
                <h3>Record Sources</h3>
                <div class="additional">
                    <xsl:apply-templates/>
                </div>
            </xsl:when>
            <xsl:when test="name()='msPart' or name()='msFrag'">
                <xsl:variable name="pos" select="count(preceding-sibling::msPart) + 1" />
                <div class="{name()}">
                    <h2>Manuscript Part <xsl:value-of select="$pos" /></h2>
                    <xsl:apply-templates/>
                </div>
            </xsl:when>
            <xsl:when test="name()='head'">
                <!-- make the head more visible h not div  -->
                <h4 class="msHead"><xsl:apply-templates/></h4>
            </xsl:when>
            <xsl:when test="name()='msIdentifier'">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- special case history -->
    <xsl:template match="history">
        <h3 class="msDesc-heading3">History</h3>
        <!-- if Origin make it a paragraph -->
        <div class="{name()}">
            <xsl:if test="origin">
                <div class="origin">
                    <span class="tei-label">Origin: </span>
                    <xsl:apply-templates select="origin"/>
                </div>
            </xsl:if>
            <xsl:if test="provenance or acquisition">
                <div class="provenance">
                    <h4>Provenance and Acquisition</h4>
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
        <!-- modified: added logic for separator before or after depending on other elements -->
        <xsl:if test="preceding-sibling::origDate">
            <xsl:text>; </xsl:text>
        </xsl:if>
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
        <xsl:if test="following-sibling::origDate">
            <xsl:text>; </xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="origin/p|provenance/p|acquisition/p">
        <!-- modified. want to keep it as a paragraph -->
        <p class="{concat(name(), '-p')}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="provenance|acquisition">
        <!-- modified. p not span -->
        <p class="{name()}">
            <xsl:apply-templates/>
        </p>
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
        <xsl:apply-templates/>
    </xsl:template>

    <!-- don't display altIdentifier for msParts, the identifier already appears as a heading -->
    <xsl:template match="msPart//altIdentifier" />
    <!--<xsl:apply-templates/>
    </xsl:template>-->

    <!-- Things in msContents -->
    <xsl:template match="msContents/summary">
        <!-- h instead of p -->
        <h4 class="msSummary">
            <!-- label unnecessary -->
            <!--<span class="tei-label">Summary of Contents:</span>-->
            <xsl:apply-templates/>
        </h4>
    </xsl:template>

    <xsl:template match="msContents/summary/p">
        <span class="summary-p">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="msContents/textLang">
        <p class="ContentsTextLang">
            <!-- this on the other hand does need a label, if it is to appear at all -->
            <span class="tei-label">Language(s): </span>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <!-- msItem -->
    <!-- <xsl:template match="msContents/msItem" priority="10">
         <div class="msItem" id="{@xml:id}">
             <hr />
             <!-\- add -\-><xsl:apply-templates select="locus"/>
             <h4 class="tei-title">
                 <!-\- add -\-><xsl:apply-templates select="author"/>
                 <xsl:choose>
                     <xsl:when test="title">
                         <!-\- modify -\-><xsl:apply-templates select="title[1]"/>
                         <!-\-<xsl:value-of select="normalize-space(title[1])"/>-\->
                     </xsl:when>
                     <xsl:otherwise>
                         <!-\- this creates duplication with later <note>. need to change? -\->
                         [<xsl:value-of select="normalize-space(string-join(note/string(), ' '))"/>]
                     </xsl:otherwise>
                 </xsl:choose>
             </h4>
             <div>
                 <xsl:apply-templates select="* except (locus, author, title[1])"/>
             </div>
         </div>
     </xsl:template>
     -->

    <!-- what happens if we just apply templates? -->
    <xsl:template match="msContents/msItem" priority="10">
        <div class="msItem" id="{@xml:id}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- nested msItem -->
    <!-- check what happens with multiple levels of nesting? -->
    <!-- modified to match main treatment of msItem above-->
    <xsl:template match="msItem/msItem">
        <div class="nestedmsItem" id="{@xml:id}">
            <!--<hr />
            <xsl:apply-templates select="locus"></xsl:apply-templates>
            <!-\- changed from h3. this level needs to be smaller than the preceding level -\->
            <h5 class="tei-title">
                <xsl:apply-templates select="author"/>
                <xsl:apply-templates select="title[1]"/>
                <xsl:apply-templates select="note[1][starts-with(., '(') and preceding-sibling::title]"/>
            </h5>
            <div class="msItemList">
                <xsl:apply-templates select="* except (locus, author, title[1], note[1][starts-with(., '(') and preceding-sibling::title])"/>
            </div>-->
            <!-- again let's try just applying templates -->
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- things in msItem -->
    <!-- don't do anything with an msItem title -->
    <!-- need to apply templates, sometimes titles contain names for example or formatting  -->
    <!-- standard titles should be in italic -->
    <xsl:template match="msItem/title[not(@rend) and not(@type)]">
        <span class="tei-title italic">
            <xsl:apply-templates/>
        </span>
        <!--<xsl:if test="following-sibling::note[1][not(starts-with(., '('))][not(starts-with(., '[A-Z]'))][not(following-sibling::lb[1])]">-->
            <!--<xsl:text>, </xsl:text>-->
        <!--</xsl:if>-->
    </xsl:template>

    <!-- others should be roman -->
    <xsl:template match="msItem/title[@rend or @type]">
        <span class="tei-title">
            <xsl:apply-templates/>
        </span>
        <xsl:if test="following-sibling::note[1][not(starts-with(., '('))][not(starts-with(., '[A-Z]'))][not(following-sibling::lb[1])]">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>

    <!--<xsl:template match="msItem/author | msItem/docAuthor">-->
        <!--<span class="author">-->
            <!--<xsl:apply-templates /><xsl:if test="following-sibling::*[1]/name()='author'"><xsl:text>; </xsl:text></xsl:if><xsl:if test="following-sibling::*[1]/name()='title'"><xsl:text>. </xsl:text></xsl:if>-->
            <!--&lt;!&ndash;<xsl:choose>&ndash;&gt;-->
                <!--<xsl:when test="@key">-->
                    <!--<a href="/catalog/{@key}">-->
                        <!--&lt;!&ndash; modified &ndash;&gt;-->
                        <!--<xsl:apply-templates /><xsl:if test="following-sibling::*[1]/name()='author'"><xsl:text>; </xsl:text></xsl:if><xsl:if test="following-sibling::*[1]/name()='title'"><xsl:text>. </xsl:text></xsl:if>-->
                        <!--&lt;!&ndash;<xsl:value-of select="normalize-space(string-join(text(), ', '))"/>&ndash;&gt;-->
                    <!--</a>-->
                <!--</xsl:when>-->
                <!--<xsl:otherwise>-->
                    <!--&lt;!&ndash; modified &ndash;&gt;-->
                    <!--<xsl:apply-templates /><xsl:if test="following-sibling::*[1]/name()='author'"><xsl:text>; </xsl:text></xsl:if><xsl:if test="following-sibling::*[1]/name()='title'"><xsl:text>. </xsl:text></xsl:if>-->
                    <!--&lt;!&ndash;<xsl:value-of select="normalize-space(string-join(text(), ', '))"/>&ndash;&gt;-->
                <!--</xsl:otherwise>-->
            <!--</xsl:choose>-->
        <!--</span>-->
    <!--</xsl:template>-->
    <xsl:template match="msItem/editor">
        <span class="editor">
            <xsl:value-of select="normalize-space(string-join(text(), ' (editor)'))"/>
        </span>
    </xsl:template>
    <xsl:template match="msItem//bibl | physDesc//bibl | history//bibl">
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

    <!-- new. First note after title, if in ()  should be span not div to follow title.  -->
    <xsl:template match="msItem/note[starts-with(., '(')]">
        <xsl:text> </xsl:text>
        <span class="{name()}">
            <!-- modified: label not needed -->
            <!--<span class="tei-label">Note: </span>-->
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="msItem/note[not(starts-with(., '('))]">
        <p class="{name()}">
            <!-- modified: label not needed -->
            <!--<span class="tei-label">Note: </span>-->
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="msItem/quote">
        <blockquote class="{name()}">"<xsl:apply-templates/>"
        </blockquote>
    </xsl:template>

    <xsl:template match="msItem/incipit">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:if test="name() = 'incipit'">Incipit: </xsl:if>
            </span>
            <xsl:if test="@type">
                <span class="type">(<xsl:value-of select="@type"/>)</span>
            </xsl:if>
            <xsl:if test="@defective='true'">
                <span class="defective">||</span>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/explicit">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:if test="name() = 'explicit'">Explicit: </xsl:if>
            </span>
            <xsl:if test="@type">
                <span class="type">(<xsl:value-of select="@type"/>)</span>
            </xsl:if>
            <xsl:apply-templates/>
            <xsl:if test="@defective='true'">
                <span class="defective">||</span>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template match="msItem/rubric">
        <div class="{name()}">
            <span class="tei-label">Rubric: </span>
            <!-- can we have this and the following <xsl:if> back? there is a difference inthe records between italic and not italic rubrics etc. -->
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
            <span class="tei-label">Filiation:</span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/textLang">
        <div class="{name()}">
            <span class="tei-label">Language(s): </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/locus">
        <div class="{name()}">
            <!-- optional? if the item is numbered, we should display the number -->
            <xsl:if test="parent::msItem[@n]">
                <span class="item-number"><xsl:value-of select="parent::msItem/@n"/>.
                </span>
            </xsl:if>
            <!--<span class="tei-label">Locus: </span>-->
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
        <div class="physDesc-p">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="accMat">
        <div class="{name()}">
            <h4>Accompanying Material</h4>
            <p>
                <xsl:apply-templates/>
            </p>
        </div>
    </xsl:template>

    <xsl:template match="additions">
        <div class="additions">
            <span class="tei-label">Additions: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="bindingDesc">
        <div class="{name()}">
            <h4>Binding</h4>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="binding">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="binding/p|collation/p|foliation/p">
        <p class="{concat(parent::node()/name(), '-p')}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="decoDesc">
        <div class="{name()}">
            <h4>Decoration</h4>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="handDesc">
        <div class="handDesc">
            <h4>Hand(s)</h4>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="decoDesc/*|handDesc/*">
        <p class="{name()}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="decoNote|handNote" priority="20">
        <p class="{name()}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="decoDesc/p|handDesc/p|decoNote/p|handNote/p" priority="10">
        <p class="{concat(parent::node()/name(), '-p')}">
            <xsl:apply-templates/>
        </p>
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
            <span class="tei-label">Musical Notation: </span>
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
        <span class="tei-label">Seal(s): </span>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="scriptDesc">
        <h4>Script(s)</h4>
        <div class="scriptDesc">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="objectDesc">
        <div class="objectDesc">
            <xsl:if test="@form">
                <div class="form">
                    <span class="tei-label">Form: </span>
                    <xsl:value-of select="@form"/>
                </div>
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
        <div class="{name()}">
            <h4>Layout</h4>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="layoutDesc/layout">
            <!-- modified: do not display attribute values -->
            <!--<xsl:if test="@columns">
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
            </xsl:if>-->
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="supportDesc">
        <xsl:apply-templates/>
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
            <h4>Collation</h4>
            <div class="collation">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="condition">
        <div>
            <h4>Condition</h4>
            <div class="condition">
                <xsl:apply-templates/>
            </div>
        </div>

    </xsl:template>

    <xsl:template match="foliation">
        <div class="{name()}">
            <span class="tei-label">Foliation: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- this is handled with supportDesc@material - AH -->
    <xsl:template match="support">
        <div class="{name()}">
            <span class="tei-label">Support: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <!-- secFol, locus, extent -->
    <xsl:template match="secFol">
        <div class="{ name() }">
            <span class="tei-label italic">Secundo Folio: </span>
            <xsl:apply-templates/>
            <!-- would be useful to insert a space at end ? (due to there often being a following <locus>) -->
        </div>
    </xsl:template>

    <!-- locus outside of msitem should not be a div since it always appears in continuous text  -->
    <xsl:template match="locus">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="extent">
        <div class="{name()}">
            <!-- the label "extent" should only be displayed (1) if there is text (not just whitespace) after, giving the extent (2) if there is <measure> directly afterwards -->
            <xsl:choose>
                <xsl:when test="child::text()[1][matches(., '[a-z]')]">
                    <span class="tei-label">Extent: </span>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:when test="child::measure[1]">
                    <span class="tei-label">Extent: </span>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- deal with dimensions in the extent -->
    <xsl:template match="extent/dimensions">
        <div class="{name()}">
            <span class="tei-label">Dimensions<xsl:if test="@type"><xsl:text> </xsl:text>(<xsl:value-of select="@type"/>)</xsl:if>:<xsl:text> </xsl:text></span>
            <xsl:choose>
                <xsl:when test="height and width">
                    <span class="height"><xsl:value-of select="height"/></span>×<span class="width"><xsl:value-of select="width"/></span>
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

    <!-- deal with dimensions elsewhere -->
    <xsl:template match="dimensions">
        <xsl:choose>
            <xsl:when test="height and width">
                <span class="height"><xsl:value-of select="height"/></span>×<span class="width"><xsl:value-of select="width"/></span>
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
    </xsl:template>

    <xsl:template match="height|width">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <!-- formula, catchwords, signatures, watermarks  -->
    <xsl:template match="formula">
        <div class="formula">
            <!-- modified: label not wanted -->
            <!-- <span class="tei-label">Formula: </span>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="catchwords | signatures | watermark | listBibl">
        <!-- changed from div to span since the whole text of <collation> is usually written as a continuous paragraph -->
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
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

    <xsl:template match="list/item | listBibl/bibl">
        <div class="{name()}">
            <!--  modified to create live links in the catalogue references  -->
            <xsl:choose>
                <xsl:when test="@facs">
                    <!-- this path will need to be updated for final version -->
                    <xsl:variable name="facs-url" select="concat('https://medieval.bodleian.ox.ac.uk/images/ms/', substring(@facs, 1, 3), '/', @facs)" />
                    <a href="{$facs-url}">
                        <xsl:apply-templates/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!--<xsl:template match="note//bibl | p//bibl | title//bibl | physDesc//bibl">-->
        <!--<div class="{name()}">-->
            <!--<xsl:apply-templates/>-->
        <!--</div>-->
    <!--</xsl:template>-->

    <!-- Things inside additional -->
    <xsl:template match="additional/listBibl">
        <h3 class="msDesc-heading3">Bibliography</h3>
        <div class="listBibl">
            <ul class="listBibl">
                <xsl:apply-templates/>
            </ul>
        </div>
    </xsl:template>

    <xsl:template match="additional/surrogates">
        <h3 class="msDesc-heading3">Digital Images</h3>
        <div class="surrogates">
            <!--<xsl:choose>
                <xsl:when test="bibl/@facs">
                    <a href="{bibl/@facs}">
                        <xsl:apply-templates/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <!-- new 6.11.17 -->
    <xsl:template match="surrogates//bibl/@*"/>

    <xsl:template match="additional/adminInfo">
        <div class="adminInfo">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="adminInfo/*">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="source">
        
        <div class="{name()}">
           <!-- <xsl:if test="text()[1]">
                <!-\- modified from div to span. Don't want to make leading text a block necessarily. -\->
                <xsl:apply-templates select="text()[1]"/>
            </xsl:if>-->

            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!--<xsl:template match="source/*">
        <xsl:apply-templates/>
        <!-\- the following creates (1) div for titles in source (which we don't want) (2) div for listBibl in source (which we do want). that is also handled at l. 1260, though (need to change priority there?) -\->
        <!-\-<div class="{name()}">
            <xsl:apply-templates/>
        </div>-\->
    </xsl:template>-->

    <xsl:template match="source/listBibl" priority="10">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- names and places -->
    <xsl:template match="persName | placeName | orgName | name | country | settlement | district | region | repository | idno">
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

    <xsl:template match="author">
        <span class="{name()}">
            <xsl:choose>
                <xsl:when test="normalize-space(.)=''" />
                <xsl:when test="@key">
                    <a href="/catalog/{@key}">
                        <xsl:apply-templates/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </span><xsl:if test="following-sibling::*[1]/name()='author'"><xsl:text>; </xsl:text></xsl:if><xsl:if test="following-sibling::*[1]/name()='title'"><xsl:text>, </xsl:text></xsl:if>
    </xsl:template>

    <xsl:template match="heraldry | label | list/head | seg">
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

    <!-- catch all fallback: this is there to warn me of elements I don't have templates for and should never fire otherwise-->
    <xsl:template match="*" priority="-100">
      <xsl:message>No template for: <xsl:value-of select="name()"/></xsl:message>
      <span class="{name()}">
        <xsl:apply-templates select="@*|node()"/>
      </span>
    </xsl:template>
</xsl:stylesheet>
