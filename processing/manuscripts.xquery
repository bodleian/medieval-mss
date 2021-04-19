import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "lib/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

declare variable $collection := collection('../collections/?select=*.xml;recurse=yes');
declare variable $countryauthorities := doc('../places.xml')/tei:TEI/tei:text/tei:body//tei:listPlace/tei:place[@xml:id and @type='country'];

declare function local:origin($keys as xs:string*, $solrfield as xs:string) as element()*
{
    (: Lookup place keys, which are specific to medieval-mss :)
    if (count($keys) gt 0) then 
        let $countries := $countryauthorities[@xml:id = distinct-values($keys)]
        return if (count($countries) gt 0) then
            (
            for $country in $countries
                let $name := $country/tei:placeName[@type = 'index'][1]/text()
                order by $name
                return <field name="{ $solrfield }">{ $name }</field>
            ,
            if (count($countries) gt 1) then <field name="{ $solrfield }">Multiple Origins</field> else ()
            )
        else
            <field name="{ $solrfield }">[MISSING]</field>
    else
        ()
};

declare function local:buildSummaries($ms as document-node()) as xs:string*
{
    if ($ms//tei:msDesc/(tei:head|tei:history/tei:origin|tei:msContents/tei:summary) or not($ms//tei:msPart/(tei:head|tei:history/tei:origin|tei:msContents/tei:summary))) then
        local:buildSummary($ms//tei:msDesc[1])
    else
        (
        for $part in $ms//tei:msPart[count(preceding::tei:msPart) lt 10]
            return
            local:buildSummary($part)
        ,
        if (count($ms//tei:msPart) gt 10) then
            let $moreparts := count($ms//tei:msPart) - 10
            return if ($moreparts le 5) then
                for $part in $ms//tei:msPart[count(preceding::tei:msPart) ge 10]
                    return
                    local:buildSummary($part)
            else
                concat('[', $moreparts, ' more parts', ']')
        else
            ()
        )
};

declare function local:buildSummary($msdescorpart as element()) as xs:string
{
    (: Retrieve various pieces of information, from which the summary will be constructed :)
    let $head := normalize-space(string-join($msdescorpart/tei:head//text(), ''))
    let $authors := distinct-values($msdescorpart//tei:msItem/tei:author/normalize-space())
    let $numauthors := count($authors)
    let $worktitles := distinct-values(for $t in $msdescorpart//tei:msItem/tei:title[1]/normalize-space() return if (ends-with($t, '.')) then substring($t, 1, string-length($t)-1) else $t)
    let $datesoforigin := distinct-values($msdescorpart/tei:history/tei:origin//tei:origDate/normalize-space())
    let $placesoforigin := distinct-values($msdescorpart/tei:history/tei:origin//tei:origPlace/normalize-space())

    (: The main part of the summary is the head element, or the summary, or a list of authors, or a list of titles, in that order of preference :)
    let $summary1 := 
        if ($head) then
            bod:shortenToNearestWord($head, 128)
        else if ($msdescorpart//tei:msContents/tei:summary) then
            bod:shortenToNearestWord(normalize-space(string-join($msdescorpart//tei:msContents/tei:summary//text(), '')), 128)
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
                            
    (: Also include the date, unless already in the first part of the summary :)
    let $summary2 := 
        if ($head or count($datesoforigin) eq 0 or (every $date in $datesoforigin satisfies contains($summary1, $date))) then
            ()
        else if (count($datesoforigin) eq 1) then 
            $datesoforigin
        else 'Multiple dates'
                        
    (: Also include the place, unless already in the first part of the summary :)
    let $summary3 := 
        if ($head or count($placesoforigin) eq 0 or (every $place in $placesoforigin satisfies contains($summary1, $place))) then
            ()
        else if (count($placesoforigin) eq 1) then 
            $placesoforigin
        else 'Multiple places of origin'
                        
    (: Stitch them all together :)
    return string-join(($summary1, string-join(($summary2, $summary3), '; '))[string-length(.) gt 0], ' — ')
};

<add>
{
    comment{concat(' Indexing started at ', current-dateTime(), ' using files in ', substring-before(substring-after(base-uri($collection[1]), 'file:'), 'collections/'), ' ')}
}
{
    let $msids := $collection/tei:TEI/@xml:id/data()
    return if (count($msids) ne count(distinct-values($msids))) then
        let $duplicateids := distinct-values(for $msid in $msids return if (count($msids[. eq $msid]) gt 1) then $msid else '')
        return bod:logging('error', 'There are multiple manuscripts with the same xml:id in their root TEI elements', $duplicateids)
        
    else
        for $ms in $collection
            let $msid := $ms/tei:TEI/@xml:id/string()
            order by $msid
            return
            if (string-length($msid) ne 0) then
                let $mainshelfmark := ($ms/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type='shelfmark'])[1]
                let $allshelfmarks := $ms//tei:msIdentifier//tei:idno[(@type, parent::tei:altIdentifier/@type)=('shelfmark','part','former')]
                let $subfolders := string-join(tokenize(substring-after(base-uri($ms), 'collections/'), '/')[position() lt last()], '/')
                let $htmlfilename := concat($msid, '.html')
                let $htmldoc := doc(concat('html/', $subfolders, '/', $htmlfilename))
                (:
                    Guide to Solr field naming conventions:
                        ms_ = manuscript index field
                        _i = integer field
                        _b = boolean field
                        _s = string field (tokenized)
                        _t = text field (not tokenized)
                        _?m = multiple field (typically facets)
                        *ni = not indexed (except _tni fields which are copied to the fulltext index)
                :)
                return <doc>
                    <field name="type">manuscript</field>
                    <field name="pk">{ $msid }</field>
                    <field name="id">{ $msid }</field>
                    { bod:one2one($mainshelfmark, 'title', 'error') }
                    { bod:one2one($ms//tei:titleStmt/tei:title[@type='collection'], 'ms_collection_s') }
                    { bod:one2one($ms//tei:msDesc/tei:msIdentifier/tei:institution, 'institution_sm') }
                    { bod:many2one($ms//tei:msDesc/tei:msIdentifier/tei:repository, 'ms_repository_s') }
                    { bod:strings2many(bod:shelfmarkVariants($allshelfmarks), 'shelfmarks') (: Non-tokenized field :) }
                    { bod:many2many($allshelfmarks, 'ms_shelfmarks_sm') (: Tokenized field :) }
                    { bod:one2one($mainshelfmark, 'ms_shelfmark_sort') }
                    { bod:many2many($ms//tei:msIdentifier/tei:altIdentifier[@type='internal']/tei:idno[not(starts-with(text(), 'Not in'))], 'ms_altid_sm') }
                    { bod:many2many($ms//tei:msIdentifier/tei:altIdentifier[@type='external']/tei:idno, 'ms_extid_sm') }
                    { bod:many2one($ms//tei:msIdentifier/tei:msName, 'ms_name_sm') }
                    <field name="filename_s">{ substring-after(base-uri($ms), 'collections/') }</field>
                    { bod:materials($ms//tei:msDesc//tei:physDesc//tei:supportDesc[@material], 'ms_materials_sm') }
                    { bod:trueIfExists($ms//tei:sourceDesc//tei:decoDesc/tei:decoNote[not(@type='none')], 'ms_deconote_b') }
                    { bod:digitized($ms//tei:sourceDesc//tei:surrogates//tei:bibl, 'ms_digitized_s') }
                    { bod:languages($ms//tei:sourceDesc//tei:textLang, 'lang_sm') }
                    { local:origin($ms//tei:sourceDesc//tei:origPlace/tei:country/string(@key), 'ms_origin_sm') }
                    { bod:centuries($ms//tei:origin//tei:origDate, 'ms_date_sm') }
                    { bod:strings2many(local:buildSummaries($ms), 'ms_summary_sm') }
                    { bod:indexHTML($htmldoc, 'ms_textcontent_tni') }
                    { bod:displayHTML($htmldoc, 'display') }
                </doc>

            else
                bod:logging('warn', 'Cannot process manuscript without @xml:id for root TEI element', base-uri($ms))
}
</add>