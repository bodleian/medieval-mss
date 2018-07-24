import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "lib/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

(: Read authority file :)
declare variable $authorityentries := doc("../places.xml")/tei:TEI/tei:text/tei:body/(tei:listPlace/tei:place|tei:listOrg/tei:org)[@xml:id];

(: Find instances in manuscript description files, building in-memory data structure, to avoid having to search across all files for each authority file entry :)
declare variable $allinstances :=
    for $instance in collection('../collections?select=*.xml;recurse=yes')//tei:msDesc//(tei:placeName|tei:country|tei:settlement|tei:region|tei:orgName)[not(ancestor::tei:msIdentifier)]
        let $roottei := $instance/ancestor::tei:TEI
        let $shelfmark := ($roottei/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type = "shelfmark"])[1]/text()
        let $datesoforigin := distinct-values($roottei//tei:origin//tei:origDate/normalize-space())
        let $placesoforigin := distinct-values($roottei//tei:origin//tei:origPlace/normalize-space())
        return
        <instance>
            { attribute of { if ($instance/self::tei:orgName) then 'org' else 'place' } }
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
                        ,'|',
                        if ($roottei//tei:msPart) then 'Composite manuscript' else string-join(($datesoforigin, $placesoforigin), '; ')
                    )
            }</link>
            { for $role in tokenize($instance/@role/data(), ' ') return <role>{ $role }</role> }
            { if (not($instance/self::tei:placeName or $instance/self::tei:orgName)) then <type>{ local-name($instance) }</type> else () }
            <shelfmark>{ $shelfmark }</shelfmark>
        </instance>;

<add>
{
    comment{concat(' Indexing started at ', current-dateTime(), ' using authority file at ', substring-after(base-uri($authorityentries[1]), 'file:'), ' ')}
}
{
    (: Loop thru each place or organization entry in the authority file :)
    for $placeororg in $authorityentries
    
        (: Get info in authority entry :)
        let $id := $placeororg/@xml:id/data()
        let $name := 
            if ($placeororg/self::tei:org) then
                if ($placeororg/tei:orgName[@type='display']) then normalize-space($placeororg/tei:orgName[@type='display'][1]/string()) else normalize-space($placeororg/tei:orgName[1]/string())
            else
                if ($placeororg/tei:placeName[@type='index']) then normalize-space($placeororg/tei:placeName[@type='index'][1]/string()) else normalize-space($placeororg/tei:placeName[1]/string())
        let $variants := 
            if ($placeororg/self::tei:org) then
                for $v in $placeororg/tei:orgName[not(@type='display')] return normalize-space($v/string())
            else
                for $v in $placeororg/tei:placeName[not(@type='index')] return normalize-space($v/string())
        let $extrefs := for $r in $placeororg/tei:note[@type="links"]//tei:item/tei:ref return concat($r/@target/data(), '|', bod:lookupAuthorityName(normalize-space($r/tei:title/string())))
        let $bibrefs := for $b in $placeororg/tei:bibl return bod:italicizeTitles($b)
        let $notes := for $n in $placeororg/tei:note[not(@type="links")] return bod:italicizeTitles($n)
        let $geolocs := $placeororg/tei:location/tei:geo[matches(text(), '^\s*\-?[\d\.]+\s*,\s*\-?[\d\.]+\s*$')]
        
        (: Get info in all the instances in the manuscript description files :)
        let $instances := $allinstances[key = $id]
        let $roles := for $role in distinct-values($instances/role/text()) return bod:personRoleLookup($role)
        
        (: Output a Solr doc element :)
        return if (count($instances) gt 0) then
            <doc>
                <field name="type">place</field>
                <field name="pk">{ $id }</field>
                <field name="id">{ $id }</field>
                <field name="title">{ $name }</field>
                <field name="alpha_title">{  bod:alphabetize($name) }</field>
                {
                if ($placeororg/self::tei:place) then
                    if ($placeororg/@type) then 
                        <field name="pl_type_s">{ $placeororg/@type/data() }</field> 
                    else
                        for $type in distinct-values($instances/type/text())
                            return
                            <field name="pl_type_s">{ $type }</field>
                else
                    ()
                }
                {
                for $role in $roles
                    order by $role
                    return <field name="roles_sm">{ $role }</field>
                }
                {
                for $variant in distinct-values($variants)
                    order by $variant
                    return <field name="pl_variant_sm">{ $variant }</field>
                }
                {
                let $lcvariants := for $variant in ($name, $variants) return lower-case($variant)
                for $instancevariant in distinct-values($instances/name/text())
                    order by $instancevariant
                    return if (not(lower-case($instancevariant) = $lcvariants)) then
                        <field name="pl_variant_sm">{ $instancevariant }</field>
                    else
                        ()
                }
                {
                for $geoloc in $geolocs
                    let $coords := tokenize(translate($geoloc/text(), ' ', ''), ',')
                    let $lat := number($coords[1])
                    let $long := number($coords[2])
                    return
                    if (string($lat) ne 'NaN' and string($long) ne 'NaN') then
                        let $dmscoords := string-join(bod:latLongDecimal2DMS($lat, $long), ', ')
                        return
                        <field name="link_geo_smni">https://tools.wmflabs.org/geohack/geohack.php?params={ $lat }_N_{ $long }_E|{ $dmscoords }</field>
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
                let $relatedids := tokenize(translate(string-join(($placeororg/@corresp, $placeororg/@sameAs), ' '), '#', ''), ' ')
                for $relatedid in distinct-values($relatedids)
                    let $url := concat("/catalog/", $relatedid)
                    let $linktext := ($authorityentries[@xml:id = $relatedid]/(tei:placeName|tei:orgName)[@type = 'display'][1])[1]
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
                for $link in distinct-values($instances/link/text())
                    order by tokenize($link, '\|')[2]
                    return
                    <field name="link_manuscripts_smni">{ $link }</field>
                }
            </doc>
        else
            bod:logging('info', 'Skipping authority file entry not referenced in any manuscripts', ($id, $name))
}

{
    (: Log instances with key attributes not in the authority file :)
    for $key in distinct-values($allinstances/key)
        return if (not(some $entryid in $authorityentries/@xml:id/data() satisfies $entryid eq $key)) then
            bod:logging('warn', 'Key attribute in manuscripts not found in authority file: will create broken link', ($key, $allinstances[key = $key]/name))
        else
            ()
}

{
    (: Log instances without key attributes :)
    (
    for $instancename in distinct-values($allinstances[@of='place' and not(key)]/name)
        order by $instancename
        return bod:logging('info', 'Place name in manuscripts without key attribute', $instancename)
    ,
    for $instancename in distinct-values($allinstances[@of='org' and not(key)]/name)
        order by $instancename
        return bod:logging('info', 'Organization name in manuscripts without key attribute', $instancename)
    )
}
</add>