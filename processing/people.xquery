import module namespace functx = "http://www.functx.com" at "functx.xq";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";
declare variable $disablelogging as xs:boolean external := false();

declare function local:logging($level, $msg, $values)
{
    if (not($disablelogging)) then
        (: Trick XQuery into doing trace() to output message to STDERR but not insert it into the XML :)
        substring(trace('', concat(upper-case($level), '	', $msg, '	', string-join($values, '	'), '	')), 0, 0)
    else ()
};

declare function local:personRole($role)
{
    (:  Most of the roles just need to be capitalized. These are the exceptions. :)
    switch($role)
        case "formerOwner" return "Owner or signer"
        case "signer" return "Owner or signer"
        case "commissioner" return "Commissioner, dedicatee, or patron"
        case "dedicatee" return "Commissioner, dedicatee, or patron"
        case "patron" return "Commissioner, dedicatee, or patron"
        default return functx:capitalize-first($role)
};

<add>
{
    let $doc := doc("../persons.xml")
    let $collection := collection('../collections?select=*.xml;recurse=yes')
    let $people := $doc//tei:person

    for $person in $people
        (:let $viaf := $authors[normalize-space(.) = normalize-space($distinct-authors)][1]/@ref:)
        let $id := $person/@xml:id/string()
        let $name := fn:normalize-space($person//tei:persName[@type='display'][1]/string())
        let $isauthor := boolean($collection//tei:author[@key = $id])
        (: TODO: Experiment, either uncomment or delete: let $issubject := boolean($collection//tei:msItem/tei:title//tei:persName[not(@role) and @key = $id]) :)

        let $mss1 := $collection//tei:TEI[.//(tei:persName)[@key = $id]]/concat('/catalog/', string(@xml:id), '|', (./tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type = "shelfmark"])[1]/text())
        let $mss2 := $collection//tei:TEI[.//(tei:author)[@key = $id]]/concat('/catalog/', string(@xml:id), '|', (./tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[@type = "shelfmark"])[1]/text())
        let $mss := distinct-values(($mss1, $mss2))

        let $variants := $person/tei:persName[@type="variant"]
        let $noteitems := $person/tei:note[@type="links"]//tei:item

        return if (count($mss) > 0) then
        <doc>
            <field name="type">person</field>
            <field name="pk">{ $id }</field>
            <field name="id">{ $id }</field>
            <field name="title">{ $name }</field>
            <field name="alpha_title">
                { functx:capitalize-first(substring(replace($name, '[^\p{L}|\p{N}]+', ''), 1, 1))}
            </field>
            <field name="pp_name_s">{ $name }</field>
            {
            let $roles := fn:distinct-values(($collection//tei:persName[@key = $id]/@role/fn:tokenize(., ' '), if ($isauthor) then 'author' else ()))
            return if (count($roles) > 0) then
                for $role in $roles
                    order by $role
                    return <field name="pp_roles_sm">{ local:personRole($role) }</field>
            else
                ()
            }
            { for $variant in $variants
                let $vname := fn:normalize-space($variant/string())
                order by $vname
                return <field name="pp_variant_sm">{ $vname }</field>
            }
            { for $item in $noteitems
                let $refs := $item//tei:ref
                order by $refs[1]
                for $ref in $refs
                    let $linktarget := $ref/string(@target)
                    let $linktext := $ref/fn:normalize-space(tei:title/string())
                    order by $linktarget
                    return <field name="link_external_smni">{ concat($linktarget, "|", $linktext)}</field>
            }
            { for $ms in $mss
                order by $ms
                return <field name="link_manuscripts_smni">{ $ms }</field>
            }
        </doc>
        else
            (
            local:logging('info', 'Skipping person in persons.xml but not in any manuscript', ($id, $name))
            )
}

{
    let $controlledpeopleids := doc("../persons.xml")//tei:person/@xml:id/string()
    let $allpeople := collection("../collections?select=*.xml;recurse=yes")//tei:TEI//(tei:persName|tei:author)
    let $allpeopleids := distinct-values($allpeople/@key/string())
    for $personid in $allpeopleids
        return if (not($controlledpeopleids[. = $personid])) then
            local:logging('warn', 'Person in manuscripts not in persons.xml: will create broken link', ($personid, normalize-space(string-join($allpeople[@key = $personid][1]/text(), ''))))
        else 
            ()
}

{
    let $allpeople := collection("../collections?select=*.xml;recurse=yes")//tei:TEI//(tei:persName|tei:author)
    return if (count($allpeople[not(@key)]) > 0) then local:logging('info', concat(count($allpeople[not(@key)]), ' people found in manuscripts which lack @key attributes'), ()) else ()
}
</add>
