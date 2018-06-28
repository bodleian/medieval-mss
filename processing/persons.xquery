import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "../../../consolidated-tei-schema/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

(: Read authority file :)
declare variable $authorityentries := doc("../persons.xml")/tei:TEI/tei:text/tei:body/tei:listPerson/tei:person[@xml:id];

(: Find instances in manuscript description files, building in-memory data structure :)
declare variable $allinstances :=
    for $i in collection('../collections?select=*.xml;recurse=yes')//tei:msDesc//(tei:persName|tei:author)
        let $t := $i/ancestor::tei:TEI
        return
        <i>
            { if ($i/@key) then attribute {'k'} { $i/@key/data() } else () }
            <n>{ normalize-space($i/string()) }</n>
            <l>{ concat('/catalog/', $t/@xml:id/data(), '|', ($t/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type = "shelfmark"])[1]/text()) }</l>
            { for $r in if ($i//self::tei:author) then ('author') else tokenize($i/@role/data(), ' ') return <r>{ $r }</r> }
        </i>;

<add>
{
    (: Loop thru each entry in the authority file :)
    for $person in $authorityentries

        (: Get info in authority entry :)
        let $id := $person/@xml:id/data()
        let $name := if ($person/tei:persName[@type='display']) then normalize-space($person/tei:persName[@type='display'][1]/string()) else normalize-space($person/tei:persName[1]/string())
        let $variants := for $v in $person/tei:persName[not(@type='display')] return normalize-space($v/string())
        let $extrefs := for $r in $person/tei:note[@type='links']//tei:item/tei:ref return concat($r/@target/data(), '|', normalize-space($r/tei:title/string()))
        let $bibrefs := for $b in $person/tei:bibl return bod:italicizeTitles($b)
        let $notes := for $n in $person/tei:note[not(@type='links')] return bod:italicizeTitles($n)
        
        (: Get info in all the instances in the manuscript description files :)
        let $instances := $allinstances[@k = $id]
        let $links2instances := distinct-values($instances/l/text())
        let $roles := distinct-values($instances/r/text())

        (: Output a Solr doc element :)
        return if (count($instances) gt 0) then
            <doc>
                <field name="type">person</field>
                <field name="pk">{ $id }</field>
                <field name="id">{ $id }</field>
                <field name="title">{ $name }</field>
                <field name="alpha_title">{  bod:alphabetize($name) }</field>
                <field name="pp_name_s">{ $name }</field>
                {
                for $role in $roles
                    order by $role
                    return <field name="roles_sm">{ bod:personRoleLookup($role) }</field>
                }
                {
                for $variant in distinct-values($variants)
                    order by $variant
                    return <field name="pp_variant_sm">{ $variant }</field>
                }
                {
                let $lcvariants := for $variant in ($name, $variants) return lower-case($variant)
                for $instancevariant in distinct-values($instances/n/text())
                    order by $instancevariant
                    return if (not(lower-case($instancevariant) = $lcvariants)) then
                        <field name="pp_variant_sm">{ $instancevariant }</field>
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
                (: See also links to other entries in the same authority file :)
                let $relatedids := tokenize(translate(string-join(($person/@corresp, $person/@sameAs), ' '), '#', ''), ' ')
                for $relatedid in distinct-values($relatedids)
                    let $url := concat("/catalog/", $relatedid)
                    let $linktext := ($authorityentries[@xml:id = $relatedid]/tei:persName[@type = 'display'][1])[1]
                    return
                    if (exists($linktext) and $allinstances[@k = $relatedid]) then
                        let $link := concat($url, "|", $linktext/string())
                        return
                        <field name="link_related_smni">{ $link }</field>
                    else
                        bod:logging('info', 'Cannot create see-also link', ($id, $relatedid))
                }
                {
                for $link in $links2instances
                    order by $link
                    return <field name="link_manuscripts_smni">{ $link }</field>
                }
            </doc>
        else
            (
            bod:logging('info', 'Skipping person in persons.xml as no matching key attribute found', ($id, $name))
            )
}

{
    (: Log instances that haven't (yet) been added to the authority file :)
    for $id in distinct-values($allinstances/@k/data())
        return if (not(some $e in $authorityentries/@xml:id/data() satisfies $e eq $id)) then
            bod:logging('warn', 'Person with key attribute not in persons.xml: will create broken link', ($id, $allinstances[@k = $id]/n/text()))
        else
            ()
}

{
    (: Log instances that don't (yet) have a key attribute :)
    for $i in distinct-values($allinstances[not(@k)]/n/text())
        order by $i
        return bod:logging('info', 'Person without key attribute', $i)
}

</add>
