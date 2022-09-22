<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:bod="http://www.bodleian.ox.ac.uk/bdlss"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei html xs bod"
    version="2.0">
    
    

    <!-- The stylesheet is a library. It doesn't validate and won't produce HTML on its own. It is called by 
         convert2HTML.xsl and previewManuscript.xsl. Any templates added below will override the templates 
         in msdesc2html.xsl in the consolidated-tei-schema repository, allowing customization of manuscript 
         display for each catalogue. -->



    <!-- For Medieval, notes are sometimes used between items to give context, so this overrides the 
         default in msdesc2html.xsl, which re-orders child elements of msItem for the sake of neatness. -->
    
    <xsl:template name="SubItems">        
        <xsl:apply-templates/>
    </xsl:template>
    
    
    
    <!-- TODO: Move these templates to msdesc2html.xsl if applicable to all catalogues? -->
    
    <xsl:template match="msDesc/msIdentifier/altIdentifier[@type='former' and child::idno[not(@subtype)]]">
        <p>
            <xsl:text>Former shelfmark: </xsl:text>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    <xsl:template match="title[@key]">
        <span>
            <xsl:attribute name="class">
                <xsl:if test="not(parent::msItem)">
                    <xsl:text>title </xsl:text>
                </xsl:if>
                <xsl:text>tei-title</xsl:text>
                <xsl:if test="not(@rend) and not(@type)">
                    <xsl:text> italic</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="not(@key='')">
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="$website-url"/>
                            <xsl:text>/catalog/</xsl:text>
                            <xsl:value-of select="tokenize(@key, ' ')[1]"/>
                        </xsl:attribute>
                        <xsl:apply-templates/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </span>
        <xsl:if test="following-sibling::*[1][self::note and not(matches(., '^\s*[A-Z(,]')) and not(child::*[1][self::lb and string-length(normalize-space(preceding-sibling::text())) = 0])]">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>
    
    
    
    <!-- This is Medieval notation, do not move this to msdesc2html.xsl -->
    
    <xsl:template match="lb">
        <xsl:text>|</xsl:text>
    </xsl:template>
    
    
    
    <!-- This is an override of the template in msdesc2html.xsl, which outputs a div. Maybe the choice should be based on context? -->
    
    <xsl:template match="formula">
        <span class="formula">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    
    
    <!-- Display lemmata in italic -->
    
    <xsl:template match="incipit/quote | incipit/cit/quote | explicit/quote | explicit/cit/quote">
        <i>
            <xsl:apply-templates/>
        </i>
    </xsl:template>
    <xsl:template match="text()[ancestor::incipit/@type='lemma' or ancestor::explicit/@type='lemma']">
        <i>
            <xsl:copy/>
        </i>
    </xsl:template>
    
    
    
    <!-- Display links to abbreviations and conventions pages, and the most recent change 
         at the bottom of manuscript pages (just before Zotero links, if any) -->
    
    <xsl:template name="Footer">
        <div class="abbreviations">
            <xsl:processing-instruction name="ni"/>
            <h3>Abbreviations</h3>
            <p>View <a href="https://github.com/bodleian/medieval-mss/wiki/Abbreviations" target="_blank">list of abbreviations</a> and <a href="https://github.com/bodleian/medieval-mss/wiki/Conventions" target="_blank">editorial conventions</a>.</p>
            <xsl:processing-instruction name="ni"/>
        </div>
        <xsl:apply-templates select="/TEI/teiHeader/revisionDesc[change][1]"/>
    </xsl:template>
    
    <xsl:template match="revisionDesc[.//change]">
        <div class="revisionDesc">
            <xsl:processing-instruction name="ni"/>
            <h3>Last Substantive Revision</h3>
            <xsl:choose>
                <xsl:when test="some $change in .//change satisfies exists($change/@when)">
                    <xsl:for-each select=".//change[@when]">
                        <xsl:sort select="@when" order="descending"/>
                        <xsl:if test="position() eq 1">
                            <xsl:apply-templates select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="(.//change)[1]"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:processing-instruction name="ni"/>
        </div>
    </xsl:template>
    
    <xsl:template match="change">
        <p class="change">
            <xsl:if test="@when">
                <xsl:value-of select="@when"/>
                <xsl:text>: </xsl:text>
            </xsl:if>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    
    
    <!-- TODO: Add quick links drop-down to header -->
        
    
</xsl:stylesheet>
