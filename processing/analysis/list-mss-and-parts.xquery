xquery version "3.0" encoding "utf-8";
declare namespace saxon = "http://saxon.sf.net/";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option output:method "text";

declare variable $tab as xs:string := '&#9;';
declare variable $newline as xs:string := '&#10;';

declare function local:buildSummary($msdescorpart as element()) as xs:string
{
    (: Retrieve various pieces of information, from which the summary will be constructed :)
    let $head := normalize-space(string-join($msdescorpart/tei:head//text(), ''))
    let $authors := distinct-values($msdescorpart//tei:msItem/tei:author/normalize-space())
    let $numauthors := count($authors)
    let $worktitles := distinct-values(for $t in $msdescorpart//tei:msItem/tei:title[1]/normalize-space() return if (ends-with($t, '.')) then substring($t, 1, string-length($t)-1) else $t)

    (: Use the head element, or the summary, or a list of authors, or a list of titles, in that order of preference :)
    return
    if ($head) then
        $head
    else if ($msdescorpart//tei:msContents/tei:summary) then
        normalize-space(string-join($msdescorpart//tei:msContents/tei:summary//text(), ''))
    else if ($numauthors gt 0) then
        if ($numauthors gt 2 or $msdescorpart//tei:msItem[not(tei:author)]) then 
            concat(string-join(subsequence($authors, 1, 2), ', '), ', etc.')
        else
            string-join($authors, ', ')
    else if (count($worktitles) gt 0) then
        if (count($worktitles) gt 2) then 
            concat(string-join(subsequence($worktitles, 1, 2), ', '), ', etc.')
        else
            string-join($worktitles, ', ')
    else if (count($msdescorpart//tei:msItem) gt 1) then
        'Untitled works or fragments'
    else
        'Untitled work or fragment'
};

declare function local:getOrigins($msdescorpart as element()) as xs:string*
{
    let $datesoforigin := distinct-values($msdescorpart/tei:history/tei:origin//tei:origDate/normalize-space())
    let $placesoforigin := distinct-values($msdescorpart/tei:history/tei:origin//tei:origPlace/normalize-space())
    return (
        string-join($datesoforigin, '; '),
        string-join($placesoforigin, '; ')
    )
};

<dummy>
{
    let $results as xs:string* := 
        for $ms in collection("../../collections?select=*.xml;recurse=yes")
            let $msid as xs:string := $ms/tei:TEI/@xml:id/string()
            let $shelfmark as xs:string := $ms//tei:msDesc/tei:msIdentifier/tei:idno[@type='shelfmark']/string()
            let $msname as xs:string* := (($ms//tei:msDesc/tei:msIdentifier/tei:msName/string())[1],'')[1]
            return
            if (not(exists($ms//tei:msPart))) then
                string-join(
                    (
                        for $x in (
                            $msid,
                            $shelfmark,
                            $msname,
                            local:buildSummary(($ms//tei:msDesc)[1]),
                            local:getOrigins(($ms//tei:msDesc)[1])
                        ) return normalize-space($x)
                    )
                    , $tab
                )
            else
                for $p in $ms//tei:msPart
                    let $shelfmark as xs:string := (($p/tei:msIdentifier/tei:altIdentifier/tei:idno[true()]/string())[1], $shelfmark)[1]
                    return
                    string-join(
                        (
                            for $x in (
                                $msid,
                                $shelfmark,
                                $msname,
                                local:buildSummary($p),
                                local:getOrigins($p)
                            ) return normalize-space($x)
                        )
                        , $tab
                    )
    return string-join(($results), $newline)
}
</dummy>
