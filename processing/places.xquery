declare namespace tei="http://www.tei-c.org/ns/1.0";


<add>
{
    let $doc := doc("../places.xml")
    let $collection := collection("../collections/?select=*.xml;recurse=yes")
    let $places := $doc//tei:place

    (:for $distinct-title in distinct-values(fn:data($items/tei:title)):)
    
    (:let $normtitle := normalize-space($distinct-title):)
    (:let $thiswork := $items[fn:data(.//tei:title) = $normtitle]  :)
    (:let $workid := $thiswork/data(@xml:id):)
    (:let $author := $thiswork//tei:persName/text():)

    for $place in $places
        let $placeid := fn:tokenize($place/string(@xml:id), "_")[2]
        let $mss1 := $collection//tei:msDesc[.//tei:history//tei:country[@key = $placeid]]//tei:idno[@type = "shelfmark"]/data()
        let $mss2 := $collection//tei:msDesc[.//tei:history//tei:settlement[@key = $placeid]]//tei:idno[@type = "shelfmark"]/data()
        let $mss := ($mss1, $mss2)
        return <doc>
            <field name="type">place</field>
            <field name="title">{ $place/tei:placeName[@type="index"]/text() }</field>
            <field name="pk">{ $place/string(@xml:id) }</field>
            <field name="id">{ $place/string(@xml:id) }</field>
            <field name="pl_name_s">{ $place/tei:placeName[@type="index"]/text() }</field>
            <field name="pl_type_s">{ $place/string(@type) }</field>
            { for $ms in $mss
                return <field name="pl_manuscripts_sm">{ data($ms) }</field> }
        </doc>
}
</add>
