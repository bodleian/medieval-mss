import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "../../../consolidated-tei-schema/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

(: TODO: Review the usefulness of: pl_type_s, pl_manuscripts_sm, pl_name_s :)

(: Read authority file :)
declare variable $authorityentries := doc("../places.xml")/tei:TEI/tei:text/tei:body/(tei:listPlace/tei:place|tei:listOrg/tei:org)[@xml:id];

(: Find instances in manuscript description files, building in-memory data structure :)
declare variable $allinstances :=
    for $i in collection('../collections?select=*.xml;recurse=yes')//tei:msDesc//(tei:placeName|tei:country|tei:settlement|tei:region|tei:orgName)
        let $t := $i/ancestor::tei:TEI
        return
        <i>
            { if ($i/@key) then attribute {'k'} { $i/@key/data() } else () }
            <n>{ normalize-space($i/string()) }</n>
            <l>{ concat('/catalog/', $t/@xml:id/data(), '|', ($t/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type = "shelfmark"])[1]/text()) }</l>
            { for $r in tokenize($i/@role/data(), ' ') return <r>{ $r }</r> }
            { if (not($i/self::tei:placeName or $i/self::tei:orgName)) then <t>{ local-name($i) }</t> else () }
        </i>;

<add>
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
        let $extrefs := for $r in $placeororg/tei:note[@type="links"]//tei:item/tei:ref return concat($r/@target/data(), '|', normalize-space($r/tei:title/string()))
        let $bibrefs := for $b in $placeororg/tei:bibl return bod:italicizeTitles($b)
        let $notes := for $n in $placeororg/tei:note[not(@type="links")] return bod:italicizeTitles($n)
        let $geolocs := $placeororg/tei:location/tei:geo[matches(text(), '^\s*\-?[\d\.]+\s*,\s*\-?[\d\.]+\s*$')]
        
        (: Get info in all the instances in the manuscript description files :)
        let $instances := $allinstances[@k = $id]
        let $links2instances := distinct-values($instances/l/text())
        let $roles := distinct-values(($instances/r/text(), $instances/t/text(), $placeororg/@type/data()))
        
        (: Output a Solr doc element :)
        return if (count($instances) gt 0) then
            <doc>
                <field name="type">place</field>
                <field name="pk">{ $id }</field>
                <field name="id">{ $id }</field>
                <field name="title">{ $name }</field>
                <field name="alpha_title">{  bod:alphabetize($name) }</field>
                <field name="pl_name_s">{ $name }</field>
                {
                if ($placeororg/self::tei:place) then
                    if ($placeororg/@type) then 
                        <field name="pl_type_s">{ $placeororg/@type/data() }</field> 
                    else
                        for $t in distinct-values($instances/t/text())
                            return
                            <field name="pl_type_s">{ $t }</field>
                else
                    ()
                }
                {
                for $role in $roles
                    order by $role
                    return <field name="roles_sm">{ bod:personRoleLookup($role) }</field>
                }
                {
                for $variant in distinct-values(($variants, $instances/n/text()))
                    order by $variant
                    return <field name="pl_variant_sm">{ $variant }</field>
                }
                {
                for $g in $geolocs
                    let $coords := tokenize(translate($g/text(), ' ', ''), ',')
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
                    return
                    (
                    <field name="link_manuscripts_smni">{ $link }</field>,
                    <field name="pl_manuscripts_sm">{ substring-after($link, '|') }</field>
                    )
                }
            </doc>
        else
            if ($placeororg/self::tei:org) then
                bod:logging('info', 'Skipping org in places.xml as no matching key attribute found', ($id, $name))
            else
                bod:logging('info', 'Skipping place in places.xml as no matching key attribute found', ($id, $name))
}

{
    (: Log instances that haven't (yet) been added to the authority file :)
    for $id in distinct-values($allinstances/@k/data())
        return if (not(some $e in $authorityentries/@xml:id/data() satisfies $e eq $id)) then
            bod:logging('warn', 'Place or org with key attribute not in places.xml: will create broken link', ($id, $allinstances[@k = $id]/n/text()))
        else
            ()
}

{
    (: Log instances that don't (yet) have a key attribute :)
    for $i in distinct-values($allinstances[not(@k)]/n/text())
        order by $i
        return bod:logging('info', 'Place or org in without key attribute', $i)
}
</add>
