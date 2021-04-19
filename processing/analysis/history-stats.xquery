xquery version "3.0" encoding "utf-8";
declare namespace saxon = "http://saxon.sf.net/";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option output:method "text";

<dummy>
{
    let $tab := '&#9;'
    let $newline := '&#10;'
 
    let $header := string-join(('collection', 'files', 'parts', 'history', 'origin', 'provenance', 'acquisition', 'origDate', 'provenance dates', 'acquisition dates', 'persNames in origin', 'persNames in provenance', 'persNames in acquisition', 'formerOwner', 'No-key-persNames', $newline), $tab)
 
    let $alltei := collection("../../collections?select=*.xml;recurse=yes")

    let $results := (
        for $doc in $alltei
            let $collection := string-join(tokenize(substring-after(base-uri($doc), '/collections/'), '/')[position() ne last()], '/')
            group by $collection
            order by $collection
            return string-join((
                    $collection,
                    count($doc//tei:TEI),
                    count($doc//tei:msPart),
                    count($doc//tei:history),
                    count($doc//tei:history/tei:origin),
                    count($doc//tei:history/tei:provenance),
                    count($doc//tei:history/tei:acquisition),
                    count($doc//tei:history/tei:origin//tei:origDate),
                    count($doc//tei:history/tei:provenance/descendant-or-self::*[@when or @notBefore or @notAfter or@from or @to]),
                    count($doc//tei:history/tei:acquisition/descendant-or-self::*[@when or @notBefore or @notAfter or@from or @to]),
                    count($doc//tei:history/tei:origin//tei:persName),
                    count($doc//tei:history/tei:provenance//tei:persName),
                    count($doc//tei:history/tei:acquisition//tei:persName),
                    count($doc//tei:msDesc//tei:persName[lower-case(@role) = 'formerowner']),
                    count($doc//tei:msDesc//tei:persName[not(@key)]),
                $newline), $tab)
        )
        
    return ($header, $results)
}
</dummy>
