<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs map"
    version="3.0">
    
    <xsl:output method="xml" indent="yes"/>
    
    <!-- 
        To run:
            cd to collections folder
            cut -f 1 ../processing/batch_conversion/dblinks.txt | sed -e 's/^/"/' | sed -e 's/$/"/' | sort | uniq | grep -rFlf - * | sort -R | xargs -P 3 -I {} java -Xmx1G -cp ../processing/saxon/saxon9he.jar net.sf.saxon.Transform -s:"{}" -xsl:../processing/batch_conversion/add-dblinks.xsl -o:"{}"
    -->
        
    <!-- Load lookup file mapping shelfmarks to barcodes into a hash -->
    <xsl:variable name="roottei" as="element()" select="/TEI"/>
    <xsl:variable name="lookupfile" as="xs:string*" select="tokenize(unparsed-text('dblinks.txt', 'utf-8'), '\r?\n')"/>
    <xsl:variable name="fulldblinks" as="map(xs:anyURI, xs:string)">
        <xsl:map>
            <xsl:for-each select="$lookupfile">
                <xsl:variable name="columns" as="xs:string*" select="tokenize(., '\t')"/>
                <xsl:if test="$columns[3] eq 'full'">
                    <xsl:if test="$columns[1] eq $roottei/@xml:id/string()">
                        <xsl:map-entry key="$columns[2] cast as xs:anyURI" select="$columns[4]"/>
                    </xsl:if>
                </xsl:if>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    <xsl:variable name="partialdblinks" as="map(xs:anyURI, xs:string)">
        <xsl:map>
            <xsl:for-each select="$lookupfile">
                <xsl:variable name="columns" as="xs:string*" select="tokenize(., '\t')"/>
                <xsl:if test="$columns[3] eq 'partial'">
                    <xsl:if test="$columns[1] eq $roottei/@xml:id/string()">
                        <xsl:map-entry key="$columns[2] cast as xs:anyURI" select="$columns[4]"/>
                    </xsl:if>
                </xsl:if>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    <xsl:variable name="addfulllinks" as="xs:boolean" select="map:size($fulldblinks) gt 0"/>
    <xsl:variable name="addpartiallinks" as="xs:boolean" select="map:size($partialdblinks) gt 0"/>
    <xsl:variable name="addlinks" as="xs:boolean" select="boolean($addfulllinks or $addpartiallinks)"/>
    <xsl:variable name="newline" as="xs:string" select="'&#10;'"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="processing-instruction('xml-model')">
        <xsl:if test="not(preceding-sibling::processing-instruction('xml-model'))"><xsl:value-of select="$newline"/></xsl:if>
        <xsl:copy/>
        <xsl:value-of select="$newline"/>
    </xsl:template>
    
    <xsl:template match="sourceDesc/msDesc[not(msPart) and not(additional) and $addlinks]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <additional>
                <surrogates>
                    <xsl:call-template name="AddSurrogatesBothTypes"/>
                </surrogates>
            </additional>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="sourceDesc/msDesc[not(additional)]/msPart[$addlinks]">
        <additional>
            <surrogates>
                <xsl:call-template name="AddSurrogatesBothTypes"/>
            </surrogates>
        </additional>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="sourceDesc/msDesc/additional[not(surrogates) and not(listBibl) and $addlinks]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <surrogates>
                <xsl:call-template name="AddSurrogatesBothTypes"/>
            </surrogates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="sourceDesc/msDesc/additional[not(surrogates)]/listBibl[$addlinks]">
        <surrogates>
            <xsl:call-template name="AddSurrogatesBothTypes"/>
        </surrogates>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="sourceDesc/msDesc/additional/surrogates[$addlinks]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="bibl[@subtype='full']"/>
            <xsl:if test="$addfulllinks">
                <xsl:call-template name="AddSurrogates">
                    <xsl:with-param name="subtype" select="'full'"/>
                    <xsl:with-param name="dblinks" select="$fulldblinks"/>
                </xsl:call-template>
            </xsl:if>
            <xsl:apply-templates select="bibl[@subtype='partial']"/>
            <xsl:if test="$addpartiallinks">
                <xsl:call-template name="AddSurrogates">
                    <xsl:with-param name="subtype" select="'partial'"/>
                    <xsl:with-param name="dblinks" select="$partialdblinks"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="AddSurrogates">
        <xsl:param name="subtype" as="xs:string"/>
        <xsl:param name="dblinks" as="map(xs:anyURI, xs:string)"/>
        <xsl:for-each select="map:keys($dblinks)">
            <xsl:sort select="$dblinks(.)[2]"/>
            <xsl:variable name="dburl" as="xs:anyURI" select="."/>
            <xsl:variable name="note" as="xs:string" select="$dblinks($dburl)"/>
            <bibl type="digital-facsimile" subtype="{ $subtype }">
                <ref target="{ $dburl }">
                    <title>Digital Bodleian</title>
                </ref>
                <xsl:text> </xsl:text>
                <note>
                    <xsl:text>(</xsl:text>
                    <xsl:value-of select="$note"/>
                    <xsl:text>)</xsl:text>
                </note>
            </bibl>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="AddSurrogatesBothTypes">
        <xsl:if test="$addfulllinks">
            <xsl:call-template name="AddSurrogates">
                <xsl:with-param name="subtype" select="'full'"/>
                <xsl:with-param name="dblinks" select="$fulldblinks"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="$addpartiallinks">
            <xsl:call-template name="AddSurrogates">
                <xsl:with-param name="subtype" select="'partial'"/>
                <xsl:with-param name="dblinks" select="$partialdblinks"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
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