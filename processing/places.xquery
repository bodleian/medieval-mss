import module namespace functx = "http://www.functx.com" at "functx.xq";
declare namespace tei="http://www.tei-c.org/ns/1.0";

<add>
{
    let $doc := doc("../places.xml")
    let $collection := collection("../collections/?select=*.xml;recurse=yes")
    let $places := $doc//tei:place

    for $place in $places
        let $placeid := $place/string(@xml:id)
        let $variants := $place/tei:placeName[@type="variant"]
        let $mss1 := $collection//tei:TEI[.//tei:history//tei:country[@key = $placeid]]
        let $mss2 := $collection//tei:TEI[.//tei:history//tei:settlement[@key = $placeid]]
        let $mss3 := $collection//tei:TEI[.//tei:placeName[@key = $placeid]]
        let $mss := ($mss1, $mss2, $mss3)

        let $noteitems := $place/tei:note[@type="links"]//tei:item
        let $placename := $place/tei:placeName[@type="index"]/text()

        return <doc>
            <field name="type">place</field>
            <field name="title">{ $placename }</field>
            <field name="alpha_title">
                { functx:capitalize-first(substring(replace($placename, '[^\p{L}|\p{N}]+', ''), 1, 1))}
            </field>

        <field name="pk">{ $placeid }</field>
            <field name="id">{ $placeid }</field>
            <field name="pl_name_s">{ $placename }</field>
            <field name="pl_type_s">{ $place/string(@type) }</field>
            { for $variant in $variants
                let $vname := fn:normalize-space($variant/string())
                return <field name="pl_variant_sm">{ $vname }</field>
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
                (: Concat the URL and shelfmark; these will get split to create a link in the display. :)
                return (
                    <field name="link_manuscripts_smni">{ concat($url, "|", $linktext[1]) }</field>,
                    <field name="pl_manuscripts_sm">{ $ms//tei:idno[@type = "shelfmark"]/data() }</field>)
            }
        </doc>
}
</add>
