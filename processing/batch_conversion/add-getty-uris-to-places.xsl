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

    <xsl:variable name="gettynote" as="xs:string">Record based on information from the Getty Thesaurus of Geographic Names, copyright 2017 the J. Paul Getty Trust, released under the Open Data Commons Attribution License (ODC-By) 1.0</xsl:variable>
    <xsl:variable name="geonamesnote" as="xs:string">Co-ordinates from Geonames.</xsl:variable>
    <xsl:variable name="viafnote" as="xs:string">This record contains information from VIAF (Virtual International Authority File) which is made available under the ODC Attribution License.</xsl:variable>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="processing-instruction('xml-model')">
        <xsl:copy/>
        <xsl:value-of select="$newline"/>
    </xsl:template>
    
    <!-- Add links to Getty URIs for confirmed Getty-sourced places  -->
    <xsl:template match="//listPlace[@type='TGN']/place[@xml:id]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <xsl:text>    </xsl:text>
            <xsl:if test="not(note[@type='links'])">
                <note type="links">
                    <list type="links">
                        <item>
                            <ref>
                                <xsl:attribute name="target">
                                    <xsl:text>http://vocab.getty.edu/tgn/</xsl:text>
                                    <xsl:value-of select="substring-after(@xml:id, 'place_')"/>
                                </xsl:attribute>
                                <title>TGN</title>
                            </ref>
                        </item>
                    </list>
                </note>
            </xsl:if>
            <xsl:value-of select="$newline"/>
            <xsl:text>                </xsl:text>
        </xsl:copy>
    </xsl:template>
    
    <!-- Ditto for VIAF-sourced orgs -->
    <xsl:template match="//listOrg[@type='VIAF']/org[@xml:id]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <xsl:text>    </xsl:text>
            <xsl:if test="not(note[@type='links'])">
                <note type="links">
                    <list type="links">
                        <item>
                            <ref>
                                <xsl:attribute name="target">
                                    <xsl:text>http://vocab.getty.edu/tgn/</xsl:text>
                                    <xsl:value-of select="substring-after(@xml:id, 'place_')"/>
                                </xsl:attribute>
                                <title>TGN</title>
                            </ref>
                        </item>
                    </list>
                </note>
                <xsl:value-of select="$newline"/>
                <xsl:text>                </xsl:text>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="//listOrg[@type='VIAF']/org[@xml:id]/note[@type='links']/list[not(item/ref[contains(@target, 'viaf.org')])]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <xsl:text>    </xsl:text>
            <item>
                <ref>
                    <xsl:attribute name="target">
                        <xsl:text>https://viaf.org/viaf/</xsl:text>
                        <xsl:value-of select="substring-after(ancestor::org[1]/@xml:id, 'org_')"/>
                    </xsl:attribute>
                    <title>VIAF</title>
                </ref>
            </item>
            <xsl:value-of select="$newline"/>
            <xsl:text>                    </xsl:text>
        </xsl:copy>
    </xsl:template>
    
    <!-- Remove attribution notes from individual entries, now there are notes in the heads of each group instead -->
    <xsl:template match="//listPlace[@type='TGN']/place//note[normalize-space(string()) = $gettynote]"></xsl:template>
    <xsl:template match="//listPlace[@type='geonames']/place//note[normalize-space(string()) = $geonamesnote]"></xsl:template>
    <xsl:template match="//listOrg[@type='VIAF']/org//note[normalize-space(string()) = $viafnote]"></xsl:template>
    
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