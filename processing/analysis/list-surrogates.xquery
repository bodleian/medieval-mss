xquery version "3.0" encoding "utf-8";
declare namespace saxon = "http://saxon.sf.net/";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option output:method "text";

declare variable $tab as xs:string := '&#9;';
declare variable $newline as xs:string := '&#10;';

<dummy>
{
    string-join(
        (
        string-join(
            (
            'CATALOGUE URL',
            'LINK URL',
            'LINK HOST',
            'TYPE',
            'SUBTYPE'
            ), $tab),
        for $ms in collection("../../collections?select=*.xml;recurse=yes")
            let $msurl := concat('https://medieval.bodleian.ox.ac.uk/catalog/', $ms/tei:TEI/@xml:id)
            for $ref in $ms//tei:surrogates//tei:ref
                let $desturl := $ref/@target
                let $desthost := tokenize($desturl, '/')[3]
                let $type := $ref/parent::tei:bibl/@type
                let $subtype := $ref/parent::tei:bibl/@subtype
                return
                    string-join(
                        (
                        $msurl,
                        $desturl,
                        $desthost,
                        $type,
                        $subtype
                        )
                        , $tab
                    )
        ), $newline
    )
}
</dummy>