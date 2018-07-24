import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "lib/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

(: Read authority file :)
declare variable $authorityentries := doc("../persons.xml")/tei:TEI/tei:text/tei:body/tei:listPerson/tei:person[@xml:id];

(: Read works authority file to be able to link from authors to their works :)
declare variable $workauthority := doc("../works.xml")/tei:TEI/tei:text/tei:body/tei:listBibl/tei:bibl[@xml:id];

(: Find instances in manuscript description files, building in-memory data structure, to avoid having to search across all files for each authority file entry :)
declare variable $allinstances :=
    for $instance in collection('../collections?select=*.xml;recurse=yes')//tei:msDesc//(tei:persName|tei:author)
        let $roottei := $instance/ancestor::tei:TEI
        let $shelfmark := ($roottei/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type = "shelfmark"])[1]/text()
        let $roles := if ($instance/self::tei:author) then ('author') else tokenize($instance/@role/data(), ' ')
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
                            ' (Digital facsimile online)'
                        else if ($roottei//tei:sourceDesc//tei:surrogates/tei:bibl[@type=('digital-fascimile','digital-facsimile') and @subtype='partial']) then
                            ' (Selected pages online)'
                        else
                            ''
                    )
            }</link>
            { for $role in $roles return <role>{ $role }</role> }
            {
            if (some $role in $roles satisfies $role eq 'author' and not($instance/parent::tei:bibl)) then 
                for $workid in distinct-values($instance/ancestor::tei:msItem[1]/tei:title/@key/tokenize(data(), ' '))
                    return <work>{ $workid }</work> 
            else
                () 
            }
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
        let $instances := $allinstances[key = $id]
        let $roles := for $role in distinct-values($instances/role/text()) return bod:personRoleLookup($role)

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
                    return <field name="roles_sm">{ $role }</field>
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
                    order by $relatedid
                    return
                    if (exists($linktext) and $allinstances[key = $relatedid]) then
                        let $link := concat($url, "|", $linktext/string())
                        return
                        <field name="link_related_smni">{ $link }</field>
                    else
                        bod:logging('info', 'Cannot create see-also link', ($id, $relatedid))
                }
                {
                for $workid in distinct-values(($instances/work/text(), $workauthority[tei:author[not(@role)]/@key = $id]/@xml:id))
                    let $url := concat("/catalog/", $workid)
                    let $linktext := ($workauthority[@xml:id = $workid]/tei:title[@type = 'uniform'][1])[1]
                    order by $workid
                    return
                    if (exists($linktext)) then
                        let $link := concat($url, "|", $linktext/string())
                        return
                        <field name="link_works_smni">{ $link }</field>
                    else
                        bod:logging('info', 'Cannot create link from author to work', ($id, $workid))
                }
                {
                for $shelfmark in distinct-values($instances/shelfmark/text())
                    order by $shelfmark
                    return
                    <field name="shelfmarks">{ $shelfmark }</field>
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
            bod:logging('info', 'Skipping authority file entry not referenced in any manuscripts', ($id, $name))
            )
}

{
    (: Log instances with key attributes not in the authority file :)
    for $key in distinct-values($allinstances/key)
        return if (not(some $entryid in $authorityentries/@xml:id/data() satisfies $entryid eq $key)) then
            bod:logging('warn', 'Key attribute in manuscripts not found in authority file: will create broken link', ($key, $allinstances[@k = $key]/name))
        else
            ()
}

{
    (: Log instances without key attributes :)
    for $instancename in distinct-values($allinstances[not(key)]/name)
        order by $instancename
        return bod:logging('info', 'Person in manuscripts without key attribute', $instancename)
}
</add>