declare namespace tei="http://www.tei-c.org/ns/1.0";


declare function local:authors($authors)
{
    for $author in $authors
    return if (string-length($author) > 0) then
        <field name="author_sm">{ $author }</field>
    else
        ()
};

<add>
{
    let $collection := collection("../collections?select=*.xml;recurse=yes")
    let $items := $collection//tei:msItem

    for $distinct-title in distinct-values($items/tei:title/fn:normalize-space(.))
        let $thiswork := $items[fn:data(.//tei:title/fn:normalize-space(.)) = $distinct-title]

        let $workid := concat("work_", $thiswork[1]/@xml:id/data())
        let $authors := $thiswork[1]//tei:persName/text()/fn:normalize-space(.)
        let $mss := $collection//tei:msDesc[fn:data(.//tei:title/fn:normalize-space(.)) = $distinct-title]//tei:idno[@type='shelfmark']

        return <doc>
            <field name="type">work</field>
            <field name="pk">{ $workid }</field>
            <field name="title">{ $distinct-title }</field>
            { local:authors($authors) }
            { for $ms in $mss
                return <field name="manuscripts_sm">{ data($ms) }</field>
                }
            </doc>
}
</add>
