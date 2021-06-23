<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs map"
    version="3.0">
    
    <!-- Load lookup file mapping work ID to subjects -->
    <xsl:variable name="newsubjects" as="map(xs:string, xs:string*)">
        <xsl:map>
            <xsl:for-each select="tokenize(unparsed-text('work_subjects_june_2021.tsv', 'utf-8'), '\r?\n')[starts-with(., 'work_')]">
                <xsl:variable name="columns" as="xs:string*" select="tokenize(., '\t')"/>
                <xsl:map-entry key="$columns[1]" select="distinct-values($columns[position() gt 1][string-length() gt 0])"/>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>

    <!-- Root template -->
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- Add new subject terms to works which don't currently have any -->
    <xsl:template match="/TEI/text/body/listBibl/bibl[@xml:id and @xml:id = map:keys($newsubjects) and not(note[@type='subject'])]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <xsl:for-each select="map:get($newsubjects, @xml:id)">
                <xsl:if test="position() eq 1">
                    <xsl:text>  </xsl:text>
                </xsl:if>
                <term ref="{.}"/>
                <xsl:value-of select="'&#10;'"/>
                <xsl:choose>
                    <xsl:when test="position() ne last()">
                        <xsl:text>          </xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>        </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <!-- Replace subjects in works that already have them, in the same place as before -->
    <xsl:template match="/TEI/text/body/listBibl/bibl[@xml:id and @xml:id = map:keys($newsubjects)]/note[@type='subject'][not(preceding-sibling::note[@type='subject'])]">
        <xsl:for-each select="map:get($newsubjects, parent::bibl/@xml:id)">
            <term ref="{.}"/>
            <xsl:if test="position() ne last()">
                <xsl:value-of select="'&#10;'"/>
                <xsl:text>          </xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="/TEI/text/body/listBibl/bibl[@xml:id and @xml:id = map:keys($newsubjects)]/note[@type='subject'][preceding-sibling::note[@type='subject']]"/>
    
    <!-- Convert subject notes to terms in works that aren't in the lookup file -->
    <xsl:template match="/TEI/text/body/listBibl/bibl[@xml:id and not(@xml:id = map:keys($newsubjects))]/note[@type='subject']">
        <term ref="#subject_{replace(normalize-space(lower-case(string())), '\s+', '_')}"/>
    </xsl:template>
    
    <!-- Copy everything else as-is -->
    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="text()|comment()|processing-instruction()">
        <xsl:copy/>
    </xsl:template>
    
    
</xsl:stylesheet>