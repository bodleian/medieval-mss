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
            'SHELFMARK',
            'MAYBE_DEFUNCT?'
            ), $tab),
        for $ms in collection("../../collections?select=*.xml;recurse=yes")
            return
            if (normalize-space($ms//tei:msDesc/tei:msIdentifier/tei:repository/string()) eq 'Bodleian Library') then
                let $shelfmark as xs:string := normalize-space($ms/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type='shelfmark'][1]/string())
                let $numworks as xs:integer := count($ms/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc//tei:msItem)
                order by $shelfmark
                return
                string-join(
                            (
                            $shelfmark,
                            if ($numworks eq 0) then 'Y' else ''
                            )[string-length() gt 0]
                            , $tab
                        )
            else
                ()
        ), $newline
    )
}
</dummy>