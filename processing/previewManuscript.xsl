<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei html xs"
    version="2.0">
    
    <xsl:import href="convert2HTML.xsl"/>
    
    <!-- Set URL here to allow links (e.g. to persons or places) to work
         when previewing (if destinations exist on the web site.) -->
    <xsl:variable name="website-url" as="xs:string" select="'http://medieval-qa.bodleian.ox.ac.uk'"/>

    <!-- Do NOT add customizations here. This stylesheet merely wraps 
         the output of convert2HTML.xsl in html and body tags, for previewing
         while editing the TEI in Oxygen. -->

    <xsl:template match="/">
        <html>
            <head>
                <style type="text/css">
                    <xsl:value-of select="string-join(tokenize(unparsed-text('preview.css', 'utf-8'), '&#xD;'), ' ')"/>
                </style>
            </head>
            <body style="padding:2em ! important;">
                <h1 itemprop="name">
                    <xsl:value-of select="//tei:msDesc/tei:msIdentifier/tei:idno[@type='shelfmark']/text()"/>
                </h1>
                <div class="content tei-body" id="{//TEI/@xml:id}">
                    <xsl:apply-templates select="//msDesc"/>
                </div>
            </body>
        </html>
    </xsl:template>

</xsl:stylesheet>
