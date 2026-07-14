<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei html xs"
    version="2.0">
    
    <!-- productes html preview for a whole collection (i.e. folder) which should be specified in line [29]
        the aim is to make proofreading of a collection easier -->
    
    <!-- Import standard templates shared by all TEI catalogues -->
    <xsl:import href="https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc2html.xsl"/>
    
    <!-- Override the above with customizations specific to this TEI catalogue -->
    <xsl:include href="customizations.xsl"/>
    
    <!-- Set URL here to allow links (e.g. to persons or places) to work
         when previewing (only if destinations already exist on the web site.) -->
    <xsl:variable name="website-url" as="xs:string" select="'https://medieval.bodleian.ox.ac.uk'"/>
    
  
    
    <!-- Set up the collection of files to be converted -->
    <!-- files and recurse parameters defaulting to '*.xml' and 'no' respectively -->
    
    <xsl:variable name="collections" select="'Add_A', 'Add_B', 'Add_C',
        'Add_D', 'Add_E', 'Arch_Selden', 'Ash_Rolls', 'Ashmole', 'Aubrey',        'Auct_B', 'Auct_D' , 'Auct_E', 'Auct_F', 'Auct_T',
        'Auct_V',
        'Barlow',
        'Barocci',
        'Bodl',
        'Bodl_Rolls',
        'Bowyer',
        'Brasenose',
        'Broxb',
       'Buchanan',
        'Bywater',
        'Bywater_adds',
        'Canon_Bibl_Lat',
        'Canon_Class_Lat',
        'Canon_Gr',
        'Canon_Ital',
        'Canon_Liturg',
        'Canon_Misc',
        'Canon_Pat_Lat',
       'Carte',
        'Cherry',
        'Christ_Church',
        'Clarendon_Press',
        'Cromwell',
        'Dep',
        'Digby',
        'Digby_Rolls',
        'Dodsworth',
        'Don',
        'DOrville',
        'Douce',
        'Dugdale',
        'Duke_Humfrey',
        'Dutch',
        'E_D_Clarke',
        'e_Mus',
        'Egypt',
        'Eng_bibl',
        'Eng_hist',
        'Eng_misc',
        'Eng_poet',
        'Eng_th',
        'Exeter_College',
        'Fairfax',
        'Fell',
        'Finch',
        'Fragments_printed_books',
        'French',
        'Germ',
        'Gough',
        'Gr_bib',
       'Gr_class',
        'Gr_liturg',
        'Gr_misc',
        'Gr_th',
        'Grabe',
        'Greaves',
        'Hamilton',
        'Hatton',
        'Hertford_College',
        'Holkham_Gr',
        'Holkham_misc',
        'Holmes',
        'Icel',
        'Ir',
        'Ital',
        'James',
        'Jesus_College',
        'Jones',
        'Junius',
        'Kennicott',
        'Lady_Margaret_Hall',
        'Lat_bib',
        'Lat_class',
        'Lat_hist',
        'Lat_liturg',
        'Lat_misc',
        'Lat_th',
        'Laud_Gr',
        'Laud_Lat',
        'Laud_Misc',
        'Lawn',
        'Lincoln_College',
        'Liturg',
        'Lyell',
        'Marshall',
        'Merton',
        'Merton_fragments',
        'Mex',
        'Michael',
        'Montagu',
        'Morrell',
        'Mus',
        'Oriel_College',
        'Radcliffe_Trust',
        'Rawl_A',
        'Rawl_B',
        'Rawl_C',
        'Rawl_D',
        'Rawl_Essex',
        'Rawl_G',
        'Rawl_liturg',
        'Rawl_poet',
        'Rawl_Q',
        'Rawl_statutes',
        'Roe',
        'Savile',
        'Selden_Superius',
        'Selden_Supra',
        'Spanish',
        'Sparrow',
        'St_Amand',
        'St_Johns_College',
        'Tanner',
        'Top',
        'Trinity_College',
        'Trinity_College_fragments',
        'University_College',
        'Wood'"/>
    
    <xsl:template match="/">
        
         <xsl:param name="files" select="'*.xml'"/>
    
    <xsl:param name="recurse" select="'yes'"/>
  
    
    <!-- the main collection of all the documents we are dealing with -->
    
        <xsl:for-each select="$collections">
       <xsl:variable name="collection" select="."></xsl:variable>
         <xsl:variable name="path">
        <xsl:value-of
            select="concat('../collections/', $collection, '?select=', $files,';on-error=warning;recurse=',$recurse)"
        />
    </xsl:variable>
            <xsl:variable name="doc" select="sort(collection($path))"/>
            
            
            <xsl:call-template name="previewCollection">
            <xsl:with-param name="doc" select="$doc"/>
            <xsl:with-param name="collection" select="$collection"></xsl:with-param>
        </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
   
    
    
    <!-- Wrap the output resulting from the above in html and body tags, for previewing
         while editing the TEI in Oxygen. Do not add anything else to this stylesheet. -->
    
    <xsl:template name="previewCollection">
        <xsl:param name="doc"></xsl:param>
        <xsl:param name="collection"></xsl:param>
        <xsl:result-document href="{concat('previews/', $collection, '.html')}">
        <html>
            <head>
                <style type="text/css">
                    <xsl:value-of select="string-join(tokenize(unparsed-text('preview.css', 'utf-8'), '&#xD;'), ' ')"/>
                </style>
            </head>
            <body style="padding:2em ! important;">
                <xsl:for-each select="$doc">
                    <xsl:sort collation="http://www.w3.org/2013/collation/UCA?numeric=yes;reorder=Latn,digit"/>
                <h1 itemprop="name">
                    <xsl:value-of select="./tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type='shelfmark']/text()"/>
                </h1>
                <div class="content tei-body" id="{.//TEI/@xml:id}">
                    <xsl:call-template name="Header"/>
                    <xsl:apply-templates select=".//msDesc"/>
                    <xsl:call-template name="AbbreviationsKey"/>
                    <xsl:call-template name="Footer"/>
                </div>
                </xsl:for-each>
            </body>
        </html></xsl:result-document>
    </xsl:template>
    
</xsl:stylesheet>
