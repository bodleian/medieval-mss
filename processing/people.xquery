declare namespace tei="http://www.tei-c.org/ns/1.0";

<add>
{
    let $doc := doc("../persons.xml")
    let $collection := collection('../collections?select=*.xml;recurse=yes')
    let $people := $doc//tei:person

    for $person in $people
        (:let $viaf := $authors[normalize-space(.) = normalize-space($distinct-authors)][1]/@ref:)
        let $id := $person/@xml:id/string()
        let $name := fn:normalize-space($person//tei:persName[@type='display'][1]/string())

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
            <field name="pp_name_s">{ $name }</field>
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
