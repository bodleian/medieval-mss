declare namespace tei="http://www.tei-c.org/ns/1.0";


declare function local:countryMSS($collection)
{

};

<add>
{
    let $doc := doc("../tolkien-places.xml")
    let $collection := collection("../collections/Add_A?select=*.xml;recurse=yes")
    let $places := $doc//tei:place

    (:for $distinct-title in distinct-values(fn:data($items/tei:title)):)
    
    (:let $normtitle := normalize-space($distinct-title):)
    (:let $thiswork := $items[fn:data(.//tei:title) = $normtitle]  :)
    (:let $workid := $thiswork/data(@xml:id):)
    (:let $author := $thiswork//tei:persName/text():)

    for $x in $places

    let $mss := $collection//tei:msDesc[fn:data(.//tei:) = $normtitle]//tei:idno[@type='shelfmark']
    return <doc>
        <field name="type">place</field>
        <field name="title">{ $x/tei:placeName[@type="index"]/text() }</field>
        <field name="pk">{ $x/string(@xml:id) }</field>
        <field name="id">{ $x/string(@xml:id) }</field>
        <field name="placename_s">{ $x/tei:placeName[@type="index"]/text() }</field>
        <field name="placetype_s">{ $x/string(@type) }</field>
    </doc>
}
</add>
