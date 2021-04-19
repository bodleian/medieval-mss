<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output method="xml"/>
    
    
    <!-- Load persons authority file -->
    
    <xsl:variable name="persons" as="element(tei:person)*" select="document('../persons.xml')/tei:TEI/tei:text/tei:body/tei:listPerson/tei:person"/>
    
    
    <!-- Root template -->
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- Lookup authors with missing/blank key attributes in the persons.xml authority file -->
    
    <xsl:template match="tei:author[not(@key) or @key='']">
        <xsl:variable name="authorname" as="xs:string" select="normalize-space(string(.))"/>
        <xsl:variable name="matchingpersons" as="element(tei:person)*" select="$persons[some $name in tei:persName satisfies $name/string() eq $authorname]"/>
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="count($matchingpersons) eq 1">
                    <xsl:attribute name="key" select="$matchingpersons[1]/@xml:id/string()"/>
                    <xsl:apply-templates select="@*[not(local-name()='key')]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@*"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    
    <!-- Everything else, copy as-is -->
    
    <xsl:template match="*">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@* | text() | comment() | processing-instruction()">
        <xsl:copy/>
    </xsl:template>
    
    
</xsl:stylesheet>
