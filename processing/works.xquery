import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "../../../consolidated-tei-schema/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

(: Read authority file :)
declare variable $authorityentries := doc("../works.xml")/tei:TEI/tei:text/tei:body/tei:listBibl/tei:bibl[@xml:id];

(: Find instances in manuscript description files, building in-memory data structure :)
declare variable $allinstances :=
    for $title in collection('../collections?select=*.xml;recurse=yes')//tei:title
        let $roottei := $title/ancestor::tei:TEI
        return
        if ($title/@key) then
            for $key in tokenize($title/@key, ' ')
                (: A small number have multiple space-separated keys, e.g. when this instance is two books of the bible which in the authority file are listed separately :)
                return
                <i>
                    { attribute {'k'} { $key } }
                    <n>{ normalize-space($title/string()) }</n>
                    <l>{ concat('/catalog/', $roottei/@xml:id/data(), '|', ($roottei/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type = "shelfmark"])[1]/text()) }</l>
                </i>
        else
            <i>
                <n>{ normalize-space($title/string()) }</n>
                <l>{ concat('/catalog/', $roottei/@xml:id/data(), '|', ($roottei/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type = "shelfmark"])[1]/text()) }</l>
                { if ($title/parent::tei:msItem/@xml:id) then <p>{ $title/parent::tei:msItem/@xml:id }</p> else () }
            </i>;

<add>
{
    (: Loop thru each entry in the authority file :)
    for $work in $authorityentries

        (: Get info in authority entry :)
        let $id := $work/@xml:id/data()
        let $title := if ($work/tei:title[@type='uniform']) then normalize-space($work/tei:title[@type='uniform'][1]/string()) else normalize-space($work/tei:title[1]/string())
        let $variants := for $v in $work/tei:title[not(@type='uniform')] return normalize-space($v/string())
        let $extrefs := for $r in $work/tei:note[@type='links']//tei:item/tei:ref return concat($r/@target/data(), '|', normalize-space($r/tei:title/string()))
        let $bibrefs := for $b in $work/tei:bibl return bod:italicizeTitles($b)
        let $notes := for $n in $work/tei:note[not(@type=('links','shelfmark','language','subject'))] return bod:italicizeTitles($n)
        let $subjects := distinct-values($work/tei:note[@type='subject']/string())
        let $lang := $work/tei:textLang
        
        (: Get info in all the instances in the manuscript description files :)
        let $instances := $allinstances[@k = $id]
        let $links2instances := distinct-values($instances/l/text())

        (: Output a Solr doc element :)
        return if (count($instances) gt 0) then
            <doc>
                <field name="type">work</field>
                <field name="pk">{ $id }</field>
                <field name="id">{ $id }</field>
                <field name="title">{ $title }</field>
                <field name="wk_title_s">{ $title }</field>
                <field name="alpha_title">
                    { 
                    if (contains($title, ':')) then
                        bod:alphabetize($title)
                    else
                        bod:alphabetizeTitle($title)
                    }
                </field>
                {
                for $variant in distinct-values(($variants, $instances/n/text()))
                    order by $variant
                    return <field name="wk_variant_sm">{ $variant }</field>
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
                bod:languages($work/tei:textLang, 'wk_lang_sm')
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
                    return
                    if (exists($linktext) and $allinstances[@k = $relatedid]) then
                        let $link := concat($url, "|", $linktext/string())
                        return
                        <field name="link_related_smni">{ $link }</field>
                    else
                        ()
                }
                {
                for $link in $links2instances
                    order by $link
                    return <field name="link_manuscripts_smni">{ $link }</field>
                }
            </doc>
        else
            (
            bod:logging('info', 'Skipping work in works.xml with no corresponding msItem', ($id, $title))
            )
}

{
    (: Log instances that haven't (yet) been added to the authority file :)
    for $id in distinct-values($allinstances/@k/data())
        return if (not(some $e in $authorityentries/@xml:id/data() satisfies $e eq $id)) then
            bod:logging('warn', 'title with key not in works.xml: will create broken link', ($id, $allinstances[@k = $id]/n/text()))
        else
            ()
}

{
    (: Log instances that don't (yet) have a key attribute :)
    for $i in distinct-values($allinstances[not(@k) and child::p]/n/text())
        order by $i
        return bod:logging('info', 'titles without key', $i)
}
</add>