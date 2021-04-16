<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs map" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
   <!-- 
        To run:
            cd to collections folder
            find ./ -type f -name "*.xml" | grep -iFf ../processing/batch_conversion/dblinks_filelist.txt | sort -R | xargs -P 3 -I {} java -Xmx1G -cp ../processing/saxon/saxon9he.jar net.sf.saxon.Transform -s:"{}" -xsl:../processing/batch_conversion/add-dblinks.xsl -o:"{}"
    -->
   <!-- Load lookup file mapping shelfmarks to barcodes into a hash -->
   <xsl:variable as="element()" name="roottei" select="/TEI"/>
   <xsl:variable as="xs:string" name="lookupfile" select="'dblinks.txt'"/>
   <xsl:variable as="map(xs:anyURI, xs:string*)" name="dblinks">
      <xsl:map>
         <xsl:for-each select="tokenize(unparsed-text($lookupfile, 'utf-8'), '\r?\n')">
            <xsl:variable as="xs:string*" name="columns" select="tokenize(., '\t')"/>
            <xsl:if test="$columns[1] eq $roottei/@xml:id/string()">
               <xsl:map-entry key="$columns[2] cast as xs:anyURI" select="$columns[position() gt 2]"/>
            </xsl:if>
         </xsl:for-each>
      </xsl:map>
   </xsl:variable>
   <xsl:variable as="xs:boolean" name="addlinks" select="map:size($dblinks) gt 0"/>
   <xsl:template match="/">
      <xsl:apply-templates/>
   </xsl:template>
   <xsl:template match="processing-instruction('xml-model')">
      <xsl:copy/>
      <xsl:value-of select="'&#10;'"/>
   </xsl:template>
   <xsl:template match="sourceDesc/msDesc[not(msPart) and not(additional) and $addlinks]">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates/>
         <additional>
            <surrogates>
               <xsl:call-template name="AddSurrogates"/>
            </surrogates>
         </additional>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="sourceDesc/msDesc[not(additional)]/msPart[$addlinks]">
      <additional>
         <surrogates>
            <xsl:call-template name="AddSurrogates"/>
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
            <xsl:call-template name="AddSurrogates"/>
         </surrogates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="sourceDesc/msDesc/additional[not(surrogates)]/listBibl[$addlinks]">
      <surrogates>
         <xsl:call-template name="AddSurrogates"/>
      </surrogates>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="sourceDesc/msDesc/additional/surrogates[$addlinks]">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates/>
         <xsl:call-template name="AddSurrogates"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template name="AddSurrogates">
      <xsl:for-each select="map:keys($dblinks)">
         <xsl:sort select="$dblinks(.)[2]"/>
         <xsl:variable as="xs:anyURI" name="dburl" select="."/>
         <xsl:variable as="xs:integer" name="numimages" select="$dblinks($dburl)[1] cast as xs:integer"/>
         <xsl:variable as="xs:string" name="extranotes" select="$dblinks($dburl)[2]"/>
         <bibl subtype="partial" type="digital-facsimile">
            <ref target="{.}">
               <title>Digital Bodleian</title>
            </ref>
            <xsl:text> </xsl:text>
            <note>
               <xsl:text>(</xsl:text>
               <xsl:value-of select="$numimages"/>
               <xsl:text> image</xsl:text>
               <xsl:if test="$numimages gt 1">
                  <xsl:text>s</xsl:text>
               </xsl:if>
               <xsl:text> from 35mm slides)</xsl:text>
               <xsl:if test="string-length($extranotes) gt 0">
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="$extranotes"/>
               </xsl:if>
            </note>
         </bibl>
      </xsl:for-each>
   </xsl:template>
   <xsl:template match="*">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="text() | comment() | processing-instruction()">
      <xsl:copy/>
   </xsl:template>
</xsl:stylesheet>
