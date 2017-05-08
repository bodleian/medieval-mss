declare namespace tei="http://www.tei-c.org/ns/1.0";

<add>
    {
    let $x := collection('../collections?select=*.xml;recurse=yes')
    let $authors := $x//tei:author/@ref

    for $distinct-author in distinct-values($authors)
        (:let $viaf := $authors[normalize-space(.) = normalize-space($distinct-authors)][1]/@ref:)
        let $id := concat("person_", fn:tokenize($distinct-author, "/")[last()])
        let $authnodes := $x//tei:msDesc[.//tei:author[@ref = $distinct-author]]
        let $name := normalize-space(distinct-values($x//tei:author[@ref = $distinct-author]//tei:persName/data())[1])
        let $mss := $authnodes//tei:idno[@type = 'shelfmark']

        return <doc>
            <field name="type">person</field>
            <field name="pk">{ $id }</field>
            <field name="id">{ $id }</field>
            <field name="title">{ $name }</field>
            { for $ms in $mss
                return <field name="manuscripts_sm">{ data($ms) }</field>
            }
        </doc>
    }
</add>
