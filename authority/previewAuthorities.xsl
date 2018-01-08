<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:xi="http://www.w3.org/2001/XInclude" 
    version="1.0">

    <!-- Using XSLT 1.0 to allow viewing in web browsers -->

    <xsl:template match="/">
        <html>
            <head>
                <title>Authority file browser</title>
                <style type="text/css">
                    body {
                        font-family: Helvetica, Arial, sans-serif;
                        background-color: #CCCCCC;
                        padding-top: 5px;
                        padding-left: 10px;
                        padding-right: 10px;
                    }
                    td {
                        vertical-align: top ! important;
                    }
                    th {
                        text-align: left ! important;
                    }
                    td.ids {
                        word-break: break-all;
                    }</style>
                <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.16/css/jquery.dataTables.min.css"/>
                <script type="text/javascript" language="javascript" src="http://code.jquery.com/jquery-1.12.4.js"/>
                <script type="text/javascript" language="javascript" src="https://cdn.datatables.net/1.10.16/js/jquery.dataTables.min.js"/>
                <script type="text/javascript" class="init">
                    $(document).ready(
                        function() {
                            $('#onetable').DataTable(
                                {
                                    scrollY: '80vh',
                                    "lengthMenu": [[25, 50, -1], [25, 50, "All"]],
                                    "columns": [
                                        { "searchable": true },
                                        { "searchable": true },
                                        { "searchable": false }
                                    ]
                                }
                            );
                        }
                    );
                </script>
            </head>
            <body>
                <xsl:apply-templates select="/tei:TEI/tei:text/tei:body"/>
            </body>
        </html>
    </xsl:template>

    <xsl:template match="tei:body">
        <table id="onetable" class="display">
            <thead>
                <tr>
                    <th width="15%">ID</th>
                    <th width="70%">Names</th>
                    <th width="15%">Sources</th>
                </tr>
            </thead>
            <tbody>

                <!-- Next line works with or without XInclude support enabled in the XSLT processor -->
                <xsl:for-each select=".//tei:person | document(xi:include/@href)//tei:person">
                    <tr>
                        <td class="ids">
                            <xsl:value-of select="@xml:id"/>
                        </td>
                        <td>
                            <!-- Primary form of the person's name, which will be displayed on the web site -->
                            <xsl:value-of select="normalize-space(tei:persName[@type = 'display'])"/>

                            <!-- List alternative forms/spellings, if any, that will be indexed only the web site -->
                            <xsl:if test="tei:persName[@type = 'variant']">
                                <ul>
                                    <xsl:for-each select="tei:persName[@type = 'variant']">
                                        <li>
                                            <xsl:value-of select="normalize-space(.)"/>
                                        </li>
                                    </xsl:for-each>
                                </ul>
                            </xsl:if>
                        </td>
                        <td>
                            <xsl:if test=".//tei:list[@type = 'links']">
                                <ul>
                                    <xsl:for-each select=".//tei:list[@type = 'links']//tei:ref">
                                        <li>
                                            <a href="{@target}">
                                                <xsl:value-of select="tei:title"/>
                                            </a>
                                        </li>
                                    </xsl:for-each>
                                </ul>
                            </xsl:if>
                        </td>
                    </tr>

                    <!-- TODO: Similar code needed for other types of authority files -->

                </xsl:for-each>
            </tbody>
        </table>
    </xsl:template>


</xsl:stylesheet>
