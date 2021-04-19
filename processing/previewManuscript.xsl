<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei html xs"
    version="2.0">
    
    <!-- Import standard templates shared by all TEI catalogues -->
    <xsl:import href="https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc2html.xsl"/>
    
    <!-- Override the above with customizations specific to this TEI catalogue -->
    <xsl:include href="customizations.xsl"/>
    
    <!-- Set URL here to allow links (e.g. to persons or places) to work
         when previewing (only if destinations already exist on the web site.) -->
    <xsl:variable name="website-url" as="xs:string" select="'http://medieval.bodleian.ox.ac.uk'"/>
    
    <!-- Wrap the output resulting from the above in html and body tags, for previewing
         while editing the TEI in Oxygen. Do not add anything else to this stylesheet. -->
    
    <xsl:template match="/">
        <html>
            <head>
                <style type="text/css">
                    <xsl:value-of select="string-join(tokenize(unparsed-text('preview.css', 'utf-8'), '&#xD;'), ' ')"/>
                </style>
            </head>
            <body style="padding:2em ! important;">
                <h1 itemprop="name">
                    <xsl:value-of select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type='shelfmark']/text()"/>
                </h1>
                <div class="content tei-body" id="{//TEI/@xml:id}">
                    <xsl:call-template name="Header"/>
                    <xsl:apply-templates select="//msDesc"/>
                    <xsl:call-template name="AbbreviationsKey"/>
                    <xsl:call-template name="Footer"/>
                </div>
            </body>
        </html>
    </xsl:template>
    
</xsl:stylesheet>
