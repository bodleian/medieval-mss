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
        
        <!-- Do NOT add customizations here. This stylesheet merely wraps 
         the output of convert2HTML.xsl in html and body tags, for previewing
         while editing the TEI in Oxygen. -->
        
        <xsl:template match="/">
            <html>
                <head>
                    <link rel="stylesheet" media="all" href="/assets/blacklight.self-115ad44891739796a4469e9d52f9c748f52326722c43067a8dbb8051c69e1c57.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/design/_contact.self-8725e3e06217435f07dfa35d3cef4b1a24475b69f9baa2f812a9c9aea3d49c17.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/design/_content.self-e209374d605aa8f6215c86d10af563223f482990ed34371e561365f81349f71f.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/design/_fix.self-24c348743e0a42397c1e0a39a29e18ab9623b961012e6d38a1b3743bf01dc12c.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/design/_footer.self-b5f6d11b9787078af5a281444621e10169c1cd522f583a14421cc5f1906160f8.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/design/_header.self-09f02f2a1088a4c9adf2b7ebb2ab532e629260c1d377ec6b1df7fc530c134773.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/design/_print.self-6c88c31dedee57b4f946647aad482d8c7bfaa7bb8157c116a187b552efc7e59a.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/lib/keyboard.self-04aeaf1a3be3d8bdf1ce628e54250316afd804c0622ed57b2a854e938d44fa83.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/lib/parsley.self-0de002fe8584eb1940884f64ed7b97bc0eb26a58bd6d9bbfc288e720588d1544.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/partials/_mixin.self-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/partials/_variables.self-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/application.self-0180b059d0017bbf299e80332f42fc9f2e4e04f254edbb540efa12af0004e005.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/blacklight_advanced_search/advanced_results.self-398970bc03a1030717dc0009e66560cc744d3b48b109f4ceaff6706a953cac39.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/blacklight_advanced_search/blacklight_advanced_search_styles.self-6aac7383133264bbdd499d3aaeadb8de1d7dbb6614a7a3c2c0c6f4d04b208403.css?body=1" />
                    <link rel="stylesheet" media="all" href="/assets/blacklight_advanced_search.self-cc0962a1fdf1162e64afeb7d2d99d5c51138b69186ee83db980fe447b885c6b1.css?body=1" />
                </head>
                <body style="padding:2em ! important;">
                    <div>
                        <div class="content tei-body" id="{//TEI/@xml:id}">
                            <xsl:apply-templates select="//msDesc"/>
                        </div>
                    </div>
                </body>
            </html>
        </xsl:template>
        
    </xsl:stylesheet>
