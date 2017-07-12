import module namespace functx = "http://www.functx.com" at "functx.xq";
declare namespace tei="http://www.tei-c.org/ns/1.0";

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
        let $roles := fn:distinct-values($collection//tei:persName[@key = $id]/@role/string())

        let $mss1 := $collection//tei:TEI[.//tei:persName[@key = $id]]
        let $mss2 := $collection//tei:TEI[.//tei:author[@key = $id]]
        let $mss := ($mss1, $mss2)

        let $variants := $person/tei:persName[@type="variant"]
        let $noteitems := $person/tei:note[@type="links"]//tei:item

        return <doc>
            <field name="type">person</field>
            <field name="pk">{ $id }</field>
            <field name="id">{ $id }</field>
            <field name="title">{ $name }</field>
            <field name="alpha_title">
                { functx:capitalize-first(substring(replace($name, '[^\p{L}|\p{N}]+', ''), 1, 1))}
            </field>
            <field name="pp_name_s">{ $name }</field>
            { for $role in $roles
                let $theseroles := fn:tokenize($role, ' ')
                for $thisrole in $theseroles
                    return <field name="pp_roles_sm">{ local:personRole($thisrole) }</field>
            }
            { for $variant in $variants
                let $vname := fn:normalize-space($variant/string())
                return <field name="pp_variant_sm">{ $vname }</field>
            }
            { for $item in $noteitems
                let $refs := $item//tei:ref
                for $ref in $refs
                    let $linktarget := $ref/string(@target)
                    let $linktext := $ref/fn:normalize-space(tei:title/string())
                    return <field name="link_external_smni">{ concat($linktarget, "|", $linktext)}</field>
            }
            { for $ms in $mss
                let $msid := $ms/string(@xml:id)
                let $url := concat("/catalog/", $msid[1])
                let $linktext := $ms//tei:idno[@type = "shelfmark"]/text()
                return <field name="link_manuscripts_smni">{ concat($url, "|", $linktext[1]) }</field>
            }

        </doc>
}
</add>
