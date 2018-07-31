import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "lib/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

(: Read authority file :)
declare variable $authorityentries := doc("../works.xml")/tei:TEI/tei:text/tei:body/tei:listBibl/tei:bibl[@xml:id];

(: Read persons authority file to be able to link from works to their authors :)
declare variable $personauthority := doc("../persons.xml")/tei:TEI/tei:text/tei:body/tei:listPerson/tei:person[@xml:id];

(: Find instances in manuscript description files, building in-memory data structure, to avoid having to search across all files for each authority file entry :)
declare variable $allinstances :=
    for $instance in collection('../collections?select=*.xml;recurse=yes')//tei:title
        let $roottei := $instance/ancestor::tei:TEI
        let $shelfmark := ($roottei/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type = "shelfmark"])[1]/text()
        let $datesoforigin := distinct-values($roottei//tei:origin//tei:origDate/normalize-space())
        let $placesoforigin := distinct-values($roottei//tei:origin//tei:origPlace/normalize-space())
        return
        <instance>
            { for $key in tokenize($instance/@key, ' ') return <key>{ $key }</key> }
            <title>{ normalize-space($instance/string()) }</title>
            <link>{ concat(
                        '/catalog/', 
                        $roottei/@xml:id/data(), 
                        '|', 
                        $shelfmark,
                        if ($roottei//tei:sourceDesc//tei:surrogates/tei:bibl[@type=('digital-fascimile','digital-facsimile') and @subtype='full']) then
                            ' (Digital facsimile online)'
                        else if ($roottei//tei:sourceDesc//tei:surrogates/tei:bibl[@type=('digital-fascimile','digital-facsimile') and @subtype='partial']) then
                            ' (Selected pages online)'
                        else
                            ''
                        ,'|',
                        if ($roottei//tei:msPart) then 'Composite manuscript' else string-join(($datesoforigin, $placesoforigin), '; ')
                    )
            }</link>
            {
            for $authorid in ($instance/ancestor::tei:msItem[tei:author][1]/tei:author[@key], $instance/parent::*/(tei:author|tei:persName[@role='author'])/@key/data())
                return <author>{ $authorid }</author>
            }
            { for $workid in $instance/parent::tei:msItem/@xml:id return <workid>{ $workid }</workid> }
            <shelfmark>{ $shelfmark }</shelfmark>
        </instance>;

<add>
{
    comment{concat(' Indexing started at ', current-dateTime(), ' using authority file at ', substring-after(base-uri($authorityentries[1]), 'file:'), ' ')}
}
{
    (: Loop thru each entry in the authority file :)
    for $work in $authorityentries

        (: Get info in authority entry :)
        let $id := $work/@xml:id/data()
        let $title := if ($work/tei:title[@type='uniform']) then normalize-space($work/tei:title[@type='uniform'][1]/string()) else normalize-space($work/tei:title[1]/string())
        let $variants := for $v in $work/tei:title[not(@type='uniform')] return normalize-space($v/string())
        let $extrefs := for $r in $work/tei:note[@type='links']//tei:item/tei:ref return concat($r/@target/data(), '|', bod:lookupAuthorityName(normalize-space($r/tei:title/string())))
        let $bibrefs := for $b in $work/tei:bibl return bod:italicizeTitles($b)
        let $notes := for $n in $work/tei:note[not(@type=('links','shelfmark','language','subject'))] return bod:italicizeTitles($n)
        let $subjects := distinct-values($work/tei:note[@type='subject']/string())
        let $lang := $work/tei:textLang
        
        (: Get info in all the instances in the manuscript description files :)
        let $instances := $allinstances[key = $id]

        (: Output a Solr doc element :)
        return if (count($instances) gt 0) then
            <doc>
                <field name="type">work</field>
                <field name="pk">{ $id }</field>
                <field name="id">{ $id }</field>
                <field name="title">{ $title }</field>
                <field name="alpha_title">
                    { 
                    if (contains($title, ':')) then
                        bod:alphabetize($title)
                    else
                        bod:alphabetizeTitle($title)
                    }
                </field>
                {
                for $variant in distinct-values($variants)
                    order by $variant
                    return <field name="wk_variant_sm">{ $variant }</field>
                }
                {
                let $lcvariants := for $variant in ($title, $variants) return lower-case($variant)
                for $instancevariant in distinct-values($instances/title/text())
                    order by $instancevariant
                    return if (not(lower-case($instancevariant) = $lcvariants)) then
                        <field name="wk_variant_sm">{ $instancevariant }</field>
                    else
                        ()
                }
                {
                for $extref in $extrefs
                    order by $extref
                    return <field name="link_external_smni">{ $extref }</field>
                }
                {
                for $bibref in $bibrefs
                    order by $bibref
                    return <field name="bibref_smni">{ $bibref }</field>
                }
                {
                for $note in $notes
                    order by $note
                    return <field name="note_smni">{ $note }</field>
                }
                {
                bod:languages($work/tei:textLang, 'lang_sm')
                }
                {
                for $subject in $subjects
                    return <field name="wk_subjects_sm">{ normalize-space($subject) }</field>
                }
                {
                (: See also links to other entries in the same authority file :)
                let $relatedids := tokenize(translate(string-join(($work/@corresp, $work/@sameAs), ' '), '#', ''), ' ')
                for $relatedid in distinct-values($relatedids)
                    let $url := concat("/catalog/", $relatedid)
                    let $linktext := ($authorityentries[@xml:id = $relatedid]/tei:title[@type = 'uniform'][1])[1]
                    order by $linktext
                    return
                    if (exists($linktext) and $allinstances[key = $relatedid]) then
                        let $link := concat($url, "|", normalize-space($linktext/string()))
                        return
                        <field name="link_related_smni">{ $link }</field>
                    else
                        bod:logging('info', 'Cannot create see-also link', ($id, $relatedid))
                }
                {
                for $shelfmark in distinct-values($instances/shelfmark/text())
                    order by $shelfmark
                    return
                    <field name="shelfmarks">{ $shelfmark }</field>
                }
                {
                for $authorid in distinct-values(($instances/author/text(), $work/tei:author[not(@role)]/@key/data()))
                    let $url := concat("/catalog/", $authorid)
                    let $linktext := ($personauthority[@xml:id = $authorid]/tei:persName[@type = 'display'][1])[1]
                    order by $linktext
                    return
                    if (exists($linktext)) then
                        let $link := concat($url, "|", normalize-space($linktext/string()))
                        return
                        <field name="link_author_smni">{ $link }</field>
                    else
                        bod:logging('info', 'Cannot create link from work to author', ($id, $authorid))
                }
                {
                for $link in distinct-values($instances/link/text())
                    order by tokenize($link, '\|')[2]
                    return
                    <field name="link_manuscripts_smni">{ $link }</field>
                }
            </doc>
        else
            (
            bod:logging('info', 'Skipping authority file entry not referenced in any manuscripts', ($id, $title))
            )
}

{
    (: Log instances with key attributes not in the authority file :)
    for $key in distinct-values($allinstances/key)
        return if (not(some $entryid in $authorityentries/@xml:id/data() satisfies $entryid eq $key)) then
            bod:logging('warn', 'Key attribute in manuscripts not found in authority file: will create broken link', ($key, $allinstances[key = $key]/title))
        else
            ()
}

{
    (: Log instances without key attributes :)
    for $instancetitle in distinct-values($allinstances[not(key) and child::workid]/title)
        order by $instancetitle
        return bod:logging('info', 'Work title in manuscripts without key attribute', $instancetitle)
}
</add>