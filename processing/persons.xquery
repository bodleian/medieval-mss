import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "lib/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

(: Read authority file :)
declare variable $authorityentries := doc("../persons.xml")/tei:TEI/tei:text/tei:body/tei:listPerson/tei:person[@xml:id];

(: Find instances in manuscript description files, building in-memory data structure, to avoid having to search across all files for each authority file entry :)
declare variable $allinstances :=
    for $instance in collection('../collections?select=*.xml;recurse=yes')//tei:msDesc//(tei:persName|tei:author)
        let $roottei := $instance/ancestor::tei:TEI
        let $shelfmark := ($roottei/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type = "shelfmark"])[1]/text()
        return
        <instance>
            { for $key in tokenize($instance/@key, ' ') return <key>{ $key }</key> }
            <name>{ normalize-space($instance/string()) }</name>
            <link>{ concat(
                        '/catalog/', 
                        $roottei/@xml:id/data(), 
                        '|', 
                        $shelfmark,
                        if ($roottei//tei:sourceDesc//tei:surrogates/tei:bibl[@type=('digital-fascimile','digital-facsimile') and @subtype='full']) then
                            ' (Digital images online)'
                        else if ($roottei//tei:sourceDesc//tei:surrogates/tei:bibl[@type=('digital-fascimile','digital-facsimile') and @subtype='partial']) then
                            ' (Selected pages online)'
                        else
                            ''
                    )
            }</link>
            { for $role in if ($instance//self::tei:author) then ('author') else tokenize($instance/@role/data(), ' ') return <role>{ $role }</role> }
            <shelfmark>{ $shelfmark }</shelfmark>
        </instance>;

<add>
{
    comment{concat(' Indexing started at ', current-dateTime(), ' using authority file at ', substring-after(base-uri($authorityentries[1]), 'file:'), ' ')}
}
{
    (: Loop thru each entry in the authority file :)
    for $person in $authorityentries

        (: Get info in authority entry :)
        let $id := $person/@xml:id/data()
        let $name := if ($person/tei:persName[@type='display']) then normalize-space($person/tei:persName[@type='display'][1]/string()) else normalize-space($person/tei:persName[1]/string())
        let $variants := for $variant in $person/tei:persName[not(@type='display')] return normalize-space($variant/string())
        let $extrefs := for $ref in $person/tei:note[@type='links']//tei:item/tei:ref return concat($ref/@target/data(), '|', bod:lookupAuthorityName(normalize-space($ref/tei:title/string())))
        let $bibrefs := for $bibl in $person/tei:bibl return bod:italicizeTitles($bibl)
        let $notes := for $note in $person/tei:note[not(@type='links')] return bod:italicizeTitles($note)
        
        (: Get info in all the instances in the manuscript description files :)
        let $roles := distinct-values($instances/r/text())
        let $instances := $allinstances[key = $id]

        (: Output a Solr doc element :)
        return if (count($instances) gt 0) then
            <doc>
                <field name="type">person</field>
                <field name="pk">{ $id }</field>
                <field name="id">{ $id }</field>
                <field name="title">{ $name }</field>
                <field name="alpha_title">{  bod:alphabetize($name) }</field>
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
                for $instancevariant in distinct-values($instances/name/text())
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
                    if (exists($linktext) and $allinstances[key = $relatedid]) then
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
