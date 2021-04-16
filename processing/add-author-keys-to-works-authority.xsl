<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml"/>
    <!-- Load persons authority file -->
    <xsl:variable as="element(tei:person)*" name="persons" select="document('../persons.xml')/tei:TEI/tei:text/tei:body/tei:listPerson/tei:person"/>
    <!-- Root template -->
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    <!-- Lookup authors with missing/blank key attributes in the persons.xml authority file -->
    <xsl:template match="tei:author[not(@key) or @key = '']">
        <xsl:variable as="xs:string" name="authorname" select="normalize-space(string(.))"/>
        <xsl:variable as="element(tei:person)*" name="matchingpersons" select="
                $persons[some $name in tei:persName
                    satisfies $name/string() eq $authorname]"/>
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="count($matchingpersons) eq 1">
                    <xsl:attribute name="key" select="$matchingpersons[1]/@xml:id/string()"/>
                    <xsl:apply-templates select="@*[not(local-name() = 'key')]"/>
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
