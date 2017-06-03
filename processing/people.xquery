declare namespace tei="http://www.tei-c.org/ns/1.0";

<add>
{
    let $doc := doc("../persons.xml")
    let $collection := collection('../collections?select=*.xml;recurse=yes')
    let $people := $doc//tei:person

    for $person in $people
        (:let $viaf := $authors[normalize-space(.) = normalize-space($distinct-authors)][1]/@ref:)
        let $id := $person/@xml:id/string()
        let $name := fn:normalize-space($person//tei:persName[@type='display']/string())

        let $mss1 := $collection//tei:msDesc[.//tei:persName[@key = $id]]
        let $mss2 := $collection//tei:msDesc[.//tei:author[@key = $id]]
        let $mss := ($mss1, $mss2)

        return <doc>
            <field name="type">person</field>
            <field name="pk">{ $id }</field>
            <field name="id">{ $id }</field>
            <field name="title">{ $name }</field>
            { for $ms in $mss
                let $msid := $ms//string(@xml:id)
                let $url := concat("/catalog/manuscript_", $msid[1])
                let $linktext := $ms//tei:idno[@type = "shelfmark"]/text()
                return <field name="link_manuscripts_smni">{ concat($url, "|", $linktext[1]) }</field>
            }
        </doc>
}
</add>
