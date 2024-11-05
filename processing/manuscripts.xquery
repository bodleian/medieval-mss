import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "lib/msdesc2solr.xquery";
import module namespace functx = "http://www.functx.com" at "functx.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

declare variable $collection := collection('../collections/?select=*.xml;recurse=yes');
declare variable $countryauthorities := doc('../places.xml')/tei:TEI/tei:text/tei:body//tei:listPlace/tei:place[@xml:id and @type='country'];
declare variable $worksauthority := doc("../works.xml");

declare function local:origin($countrykeyatts as attribute()*, $solrfield as xs:string) as element()*
{
    (: Lookup place keys, which are specific to medieval-mss :)
    let $countrykeys as xs:string* := distinct-values(for $att in $countrykeyatts return tokenize($att/data(), '\s+')[string-length() gt 0])
    return if (count($countrykeys) gt 0) then 
        let $countries := $countryauthorities[@xml:id = $countrykeys]
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

declare function local:workSubjects($workkeyatts as attribute()*, $solrfield as xs:string) as element()*
{
    (: Lookup works referenced in this manuscript in the works authority, to get the associated subject classifications :)
    let $workkeys as xs:string* := distinct-values(for $att in $workkeyatts return tokenize($att/data(), '\s+')[string-length() gt 0])
    let $worksubjectrefs as xs:string* := distinct-values($worksauthority/tei:TEI/tei:text/tei:body//tei:listBibl/tei:bibl[@xml:id = $workkeys]/tei:term[@ref]/tokenize(@ref, '\s*#')[string-length() gt 0])
    for $ref in $worksubjectrefs 
        return 
        <field name="{ $solrfield }">{ $worksauthority/tei:TEI/tei:teiHeader/tei:encodingDesc/tei:classDecl/tei:taxonomy/tei:category[@xml:id = $ref][1]/tei:catDesc/string() }</field>      
};

declare function local:buildSummaries($ms as document-node()) as xs:string*
{
    if ($ms/tei:TEI/@type = 'stub') then
        (: No summaries for stub records :)
        ()
    else if ($ms//tei:msDesc/(tei:head|tei:history/tei:origin|tei:msContents/tei:summary) or not($ms//tei:msPart/(tei:head|tei:history/tei:origin|tei:msContents/tei:summary))) then
        (: For manuscripts without parts, or composite manuscripts with an overall head/summary/origin, index with a single summary :)
        local:buildSummary($ms//tei:msDesc[1])
    else
        (: For composite manuscripts, index a summary for each part (but only up to the first 15 parts) :)
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

declare function bod:decoTypeLookup($decotype as xs:string) as xs:string
{
    switch(lower-case($decotype))
        case 'decinit' return "Decorated initial"
        case 'border' return "Border"
        case 'flourinit' return "Flourishing"
        case 'miniature' return "Miniature or coloured drawing"
        case 'colinit' return "Plain initial"
        case 'histinit' return "Historiated initial"
        case 'diagram' return "Diagram"
        case 'drawing' return "Drawing"
        case 'headpiece' return "Headpiece"
        case 'plaininit' return "Plain initial"
        case 'map' return "Map"
        default return "Other"
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
                let $oldshelfmarks := $ms//tei:msIdentifier/tei:altIdentifier[@type='former']/tei:idno[not(@subtype)]
                let $subfolders := string-join(tokenize(substring-after(base-uri($ms), 'collections/'), '/')[position() lt last()], '/')
                let $htmlfilename := concat($msid, '.html')
                let $htmldoc := doc(concat('html/', $subfolders, '/', $htmlfilename))
                let $deconotes := $ms//tei:sourceDesc//tei:decoDesc/tei:decoNote[not(@type='none')]
                let $decotypes := $deconotes/@type
                let $latestoriginyear := max(for $dateattr in $ms//tei:origin//tei:origDate[not(@type = ('additions', 'addition'))]/(@when|@notBefore|@notAfter|@from|@to) return functx:get-matches($dateattr, $bod:yearregex)[1])
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
                    { bod:many2many($oldshelfmarks, 'ms_oldshelfmarks_smni') }
                    { bod:many2many($allshelfmarks, 'ms_shelfmarks_sm') (: Tokenized field :) }
                    { bod:one2one($mainshelfmark, 'ms_shelfmark_sort') }
                    { bod:many2many($ms//tei:msIdentifier/tei:altIdentifier[@type='internal']/tei:idno[not(starts-with(text(), 'Not in'))], 'ms_altid_sm') }
                    { bod:many2many($ms//tei:msIdentifier/tei:altIdentifier[@type='external']/tei:idno, 'ms_extid_sm') }
                    { bod:many2one($ms//tei:msIdentifier/tei:msName, 'ms_name_sm') }
                    <field name="filename_s">{ substring-after(base-uri($ms), 'collections/') }</field>
                    { bod:materials($ms//tei:msDesc//tei:physDesc//tei:supportDesc[@material], 'ms_materials_sm') }
                    {
                    if (not($ms/tei:TEI/@type = 'stub')) then
                        (
                        bod:trueIfExists($ms//tei:sourceDesc//tei:decoDesc/tei:decoNote[not(@type='none')], 'ms_deconote_b'),
                        bod:trueIfExists($ms//tei:sourceDesc//tei:physDesc/tei:musicNotation, 'ms_music_b'),
                        bod:digitized($ms//tei:sourceDesc//tei:surrogates//tei:bibl, 'ms_digitized_s'),
                        bod:centuries($ms//tei:origin//tei:origDate, 'ms_date_sm', 'Undated'),
                        bod:years($ms//tei:origin//tei:origDate),
                        if ($ms//tei:physDesc/tei:bindingDesc//tei:binding[@when or @notBefore or @notAfter or @from or @to]) then
                            bod:centuries($ms//tei:physDesc/tei:bindingDesc//tei:binding, 'ms_bindingdate_sm')
                        else if ($ms//tei:physDesc/tei:bindingDesc//tei:binding[@contemporary eq 'true']) then
                            bod:centuries($ms//tei:origin//tei:origDate[not(@type = ('additions', 'addition')) and (contains(@when, $latestoriginyear) or contains(@notBefore, $latestoriginyear) or contains(@notAfter, $latestoriginyear) or contains(@from, $latestoriginyear) or contains(@to, $latestoriginyear))], 'ms_bindingdate_sm', 'Undated')
                        else if ($ms//tei:physDesc/tei:bindingDesc//tei:binding) then
                            bod:string2one('Undated', 'ms_bindingdate_sm')
                        else
                            (),
                        if (count($ms//tei:origin//tei:origDate[(@when|@notBefore|@notAfter|@from|@to)]) eq 0) then
                            ()
                        else if (every $date in $ms//tei:origin//tei:origDate satisfies $date/@cert eq 'high') then
                            bod:string2one('Known', 'ms_datecert_s')
                        else if (some $date in $ms//tei:origin//tei:origDate satisfies $date/@cert eq 'high') then
                            bod:string2one('Partially known', 'ms_datecert_s')
                        else    
                            bod:string2one('Estimated', 'ms_datecert_s'),
                        if (count($deconotes) eq 0) then
                            bod:string2one('None', 'ms_decotype_sm')
                        else if (count($decotypes) eq 0) then
                            bod:string2one('Other', 'ms_decotype_sm')
                        else
                            for $decotype in distinct-values($decotypes)
                                return bod:string2one(bod:decoTypeLookup($decotype), 'ms_decotype_sm')
                        )
                    else
                        ()
                    }
                    { bod:languages($ms//tei:sourceDesc//tei:textLang, 'lang_sm') }
                    { local:origin($ms//tei:sourceDesc//tei:origPlace/tei:country/@key, 'ms_origin_sm') }
                    { local:workSubjects($ms//tei:msItem/tei:title/@key, 'wk_subjects_sm') }
                    { bod:strings2many(local:buildSummaries($ms), 'ms_summary_sm') }
                    { bod:indexHTML($htmldoc, 'ms_textcontent_tni') }
                    { bod:displayHTML($htmldoc, 'display') }
                    { bod:requesting($ms/tei:TEI) }
                </doc>

            else
                bod:logging('warn', 'Cannot process manuscript without @xml:id for root TEI element', base-uri($ms))
}
</add>
