import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

<add>
{
    let $doc := doc("../works.xml")
    let $collection := collection("../collections?select=*.xml;recurse=yes")
    let $works := $doc//tei:listBibl/tei:bibl[@xml:id]
   
    for $work in $works
        let $id := $work/@xml:id/string()
        let $title := normalize-space($work//tei:title[@type="uniform"][1]/string())
        let $mss := $collection//tei:TEI[.//tei:title[@key = $id]]
        let $lang := $work/tei:textLang/string(@mainLang)
        let $subjects := distinct-values($work/tei:note[@type = "subject"]/string())

        return if (count($mss) > 0) then
        <doc>
            <field name="type">work</field>
            <field name="pk">{ $id }</field>
            <field name="id">{ $id }</field>
            <field name="title">{ $title }</field>
            <field name="wk_title_s">{ $title }</field>
            <field name="alpha_title">{ 
                if (contains($title, ':')) then
                    bod:alphabetize($title)
                else
                    bod:alphabetizeTitle($title)
            }</field>
            { bod:languages($work/tei:textLang, 'wk_lang_sm') }
            { for $subj in $subjects
                return <field name="wk_subjects_sm">{ $subj }</field>
            }
            { for $ms in $mss
                let $msid := $ms/string(@xml:id)
                let $url := concat("/catalog/", $msid[1])
                let $linktext := $ms//tei:idno[@type="shelfmark"]/text()
                return <field name="link_manuscripts_smni">{ concat($url, "|", $linktext[1]) }</field>
                }
        </doc>
        else
            (
            bod:logging('info', 'Skipping work in works.xml but not in any manuscript', ($id, $title))
            )
}

{
    let $controlledworkids := doc("../works.xml")//tei:listBibl/tei:bibl/@xml:id/string()
    let $allworks := collection("../collections?select=*.xml;recurse=yes")//tei:TEI//tei:title
    let $allworksids := distinct-values($allworks/@key/string())
    for $workid in $allworksids
        return if (not($controlledworkids[. = $workid])) then
            bod:logging('warn', 'Work in manuscripts not in works.xml: will create broken link', ($workid, normalize-space(string-join($allworks[@key = $workid][1]/text(), ''))))
        else 
            ()
}

{
    let $allmsitems := collection("../collections?select=*.xml;recurse=yes")//tei:TEI//tei:msItem/tei:title
    return if (count($allmsitems[not(@key)]) > 0) then bod:logging('info', concat(count($allmsitems[not(@key)]), ' msItems found in manuscripts which lack @key attributes'), ()) else ()
}

</add>