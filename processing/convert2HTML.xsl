<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:bod="http://www.bodleian.ox.ac.uk/bdlss"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei html xs bod"
    version="2.0">
    
    <!-- Import standard templates shared by all TEI catalogues. The relative path here will
         only work once the consolidated-tei-schema repository has been downloaded by the 
         index-all-qa.sh or index-all-prd.sh script (which avoids the script hanging if network is slow) -->
    <xsl:import href="lib/msdesc2html.xsl"/>
    
    <!-- Override the above with customizations specific to this TEI catalogue -->
    <xsl:include href="customizations.xsl"/>
    
    <!-- Only set this variable if you want full URLs hardcoded into the HTML on the web site -->
    <xsl:variable name="website-url" as="xs:string" select="''"/>
    
    <!-- Do not add anything else to this stylesheet. -->
    
</xsl:stylesheet>
