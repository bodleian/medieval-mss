declare namespace tei="http://www.tei-c.org/ns/1.0";

<add>
{
    let $doc := doc("../places.xml")
    let $collection := collection("../collections/?select=*.xml;recurse=yes")
    let $places := $doc//tei:place

    for $place in $places
        let $placeid := $place/string(@xml:id)
        let $mss1 := $collection//tei:msDesc[.//tei:history//tei:country[@key = $placeid]]
        let $mss2 := $collection//tei:msDesc[.//tei:history//tei:settlement[@key = $placeid]]
        let $mss := ($mss1, $mss2)

        return <doc>
            <field name="type">place</field>
            <field name="title">{ $place/tei:placeName[@type="index"]/text() }</field>
            <field name="pk">{ $place/string(@xml:id) }</field>
            <field name="id">{ $place/string(@xml:id) }</field>
            <field name="pl_name_s">{ $place/tei:placeName[@type="index"]/text() }</field>
            <field name="pl_type_s">{ $place/string(@type) }</field>
            { for $ms in $mss
                return <field name="pl_manuscripts_sm">{ $ms//tei:idno[@type = "shelfmark"]/data() }</field> }
            { for $ms in $mss
                let $msid := $ms//string(@xml:id)
                let $url := concat("/catalog/manuscript_", $msid[1])
                let $linktext := $ms//tei:idno[@type = "shelfmark"]/text()
                (: Concat the URL and shelfmark; these will get split to create a link in the display. :)
                return <field name="link_manuscripts_smni">{ concat($url, "|", $linktext[1]) }</field> }


        </doc>
}
</add>
