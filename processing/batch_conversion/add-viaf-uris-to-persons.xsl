<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs map tei"
    version="3.0">
    
    <xsl:output method="xml" indent="no"/>

    <xsl:variable name="newline" as="xs:string" select="'&#10;'"/>

    <xsl:variable name="viafnote" as="xs:string">This record contains information from VIAF (Virtual International Authority File) which is made available under the ODC Attribution License.</xsl:variable>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="processing-instruction('xml-model')">
        <xsl:copy/>
        <xsl:value-of select="$newline"/>
    </xsl:template>
    
    <!-- Ditto for VIAF-sourced orgs -->
    <xsl:template match="//listPerson[@type='VIAF']/person[@xml:id and not(note[@type='links'])]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <xsl:text>    </xsl:text>
            <note type="links">
                <list type="links">
                    <item>
                        <ref>
                            <xsl:attribute name="target">
                                <xsl:text>https://viaf.org/viaf/</xsl:text>
                                <xsl:value-of select="substring-after(@xml:id, 'person_')"/>
                            </xsl:attribute>
                            <title>VIAF</title>
                        </ref>
                    </item>
                </list>
            </note>
            <xsl:value-of select="$newline"/>
            <xsl:text>                </xsl:text>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="//listPerson[@type='VIAF']/person[@xml:id and not(note/list/item/ref[contains(@target, 'viaf.org')])]/note[@type='links'][1]/list[1]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <xsl:text>    </xsl:text>
            <item>
                <ref>
                    <xsl:attribute name="target">
                        <xsl:text>https://viaf.org/viaf/</xsl:text>
                        <xsl:value-of select="substring-after(ancestor::person[1]/@xml:id, 'person_')"/>
                    </xsl:attribute>
                    <title>VIAF</title>
                </ref>
            </item>
            <xsl:value-of select="$newline"/>
            <xsl:text>                    </xsl:text>
        </xsl:copy>
    </xsl:template>
    
    <!-- Remove attribution notes from individual entries, now there are notes in the heads of each group instead -->
    <xsl:template match="//listPerson[@type='VIAF']/person//note[normalize-space(string()) = $viafnote]"></xsl:template>
    
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