<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei html xs"
    version="2.0">
    
    <xsl:import href="lib/msdesc2html.xsl"/>

    <!-- Only set this variable if you want full URLs hardcoded into the HTML
         on the web site (previewManuscript.xsl overrides this to do so when previewing.) -->
    <xsl:variable name="website-url" as="xs:string" select="''"/>

    <!-- Any templates added below will override the templates in the shared
         imported stylesheet, allowing customization of manuscript display for each catalogue. -->
    
    <xsl:template name="SubItems">
        <!-- For Medieval, notes are sometimes used between items to give context, so this overrides the 
             default in msdesc2html.xsl, which re-orders child elements of msItem for the sake of neatness. -->
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="msDesc/msIdentifier/altIdentifier[@type='former']">
        <!-- TODO: Move this template to msdesc2html.xsl? -->
        <p>
            <xsl:text>Former shelfmark: </xsl:text>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="title[@key]">
        <!-- TODO: Move this template to msdesc2html.xsl? -->
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
            <a>
                <xsl:attribute name="href">
                    <xsl:value-of select="$website-url"/>
                    <xsl:text>/catalog/</xsl:text>
                    <xsl:value-of select="tokenize(@key, ' ')[1]"/>
                </xsl:attribute>
                <xsl:apply-templates/>
            </a>
        </span>
        <xsl:if test="following-sibling::*[1][self::note and not(matches(., '^\s*[A-Z(,]')) and not(child::*[1][self::lb and string-length(normalize-space(preceding-sibling::text())) = 0])]">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>


</xsl:stylesheet>
