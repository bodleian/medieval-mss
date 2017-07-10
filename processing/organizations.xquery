declare namespace tei="http://www.tei-c.org/ns/1.0";

<add>
{
    let $doc := doc("../places.xml")
    let $collection := collection("../collections/?select=*.xml;recurse=yes")
    let $orgs := $doc//tei:org

    for $org in $orgs
        let $orgid := $org/string(@xml:id)
        let $mss := $collection//tei:msDesc[.//tei:orgName[@key = $orgid]]
        let $variants := $org/tei:orgName[@type="variant"]

        let $notelinks := $org/tei:note[@type="links"]//tei:item

        (: Organizations are indexed as places so that we do not need another section to display them. :)
        return <doc>
            <field name="type">place</field>
            <field name="title">{ fn:normalize-space($org/tei:orgName[@type="display"][1]/string()) }</field>
            <field name="id">{ $orgid }</field>
            <field name="pk">{ $orgid }</field>
            { for $variant in $variants
                let $vname := fn:normalize-space($variant/string())
                return <field name="pl_variant_sm">{ $vname }</field>
            }
            { for $link in $notelinks
                let $linktarget := $link//tei:ref/string(@target)
                let $linktext := $link//tei:ref/fn:normalize-space(tei:title/string())
                return <field name="link_external_smni">{ concat($linktarget, "|", $linktext)}</field>
            }
            { for $ms in $mss
                let $msid := $ms//string(@xml:id)
                let $url := concat("/catalog/manuscript_", $msid[1])
                let $linktext := $ms//tei:idno[@type = "shelfmark"]/text()

                return (
                    <field name="link_manuscripts_smni">{ concat($url, "|", $linktext[1]) }</field>,
                    <field name="pl_manuscripts_sm">{ $ms//tei:idno[@type = "shelfmark"]/data() }</field>)
            }
        </doc>

}
</add>
