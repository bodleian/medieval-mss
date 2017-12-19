import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

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
        let $mss4 := $collection//tei:TEI[.//tei:history//tei:region[@key = $placeid]]
        let $mss := ($mss1, $mss2, $mss3, $mss4)

        let $noteitems := $place/tei:note[@type="links"]//tei:item
        let $placename := $place/tei:placeName[@type="index"]/text()

        return if (count($mss) > 0) then
        <doc>
            <field name="type">place</field>
            <field name="title">{ $placename }</field>
            <field name="alpha_title">{  bod:alphabetize($placename) }</field>

        <field name="pk">{ $placeid }</field>
            <field name="id">{ $placeid }</field>
            <field name="pl_name_s">{ $placename }</field>
            <field name="pl_type_s">{ $place/string(@type) }</field>
            { for $variant in $variants
                let $vname := normalize-space($variant/string())
                return <field name="pl_variant_sm">{ $vname }</field>
            }
            { for $item in $noteitems
                let $refs := $item//tei:ref
                for $ref in $refs
                let $linktarget := $ref/string(@target)
                let $linktext := $ref/normalize-space(tei:title/string())
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
        else
            (
            bod:logging('info', 'Skipping place in places.xml but not in any manuscript', ($placeid, $placename))
            )
}

{
    let $controlledplaceids := doc("../places.xml")//tei:place/@xml:id/string()
    let $allplaces := collection("../collections?select=*.xml;recurse=yes")//tei:TEI//((tei:country|tei:settlement)[ancestor::tei:history]|tei:placeName)
    let $allplaceids := distinct-values($allplaces/@key/string())
    for $placeid in $allplaceids
        return if (not($controlledplaceids[. = $placeid])) then
            bod:logging('warn', 'Place in manuscripts not in places.xml: will create broken link', ($placeid, normalize-space(string-join($allplaces[@key = $placeid][1]/text(), ''))))
        else 
            ()
}

{
    let $allplaces := collection("../collections?select=*.xml;recurse=yes")//tei:TEI//((tei:country|tei:settlement)[ancestor::tei:history]|tei:placeName)
    return if (count($allplaces[not(@key)]) > 0) then bod:logging('info', concat(count(distinct-values($allplaces[not(@key)]/text()[1])), ' places found in manuscripts which lack @key attributes'), ()) else ()
}

</add>
