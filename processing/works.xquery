import module namespace functx = "http://www.functx.com" at "functx.xq";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";
declare variable $disablelogging as xs:boolean external := false();

declare function local:logging($level, $msg, $values)
{
    if (not($disablelogging)) then
        (: Trick XQuery into doing trace() to output message to STDERR but not insert it into the XML :)
        substring(trace('', concat(upper-case($level), '	', $msg, '	', string-join($values, '	'), '	')), 0, 0)
    else ()
};

declare function local:authors($authors)
{
    for $author in $authors
    return if (string-length($author) > 0) then
        <field name="author_sm">{ $author }</field>
    else
        ()
};

declare function local:languageValue($lang)
{
    switch($lang)
        case "English" return "English"
        case "French" return "French"
        case "Hebrew" return "Hebrew"
        case "an" return "Spanish"
        case "ang" return "English"
        case "ar" return "Arabic"
        case "ara" return "Arabic"
        case "ara-Latn-x-lc" return "Arabic"
        case "ara-Latn-x-lx" return "Arabic"
        case "br" return "French"
        case "ca" return "Catalan"
        case "cop" return "Coptic"
        case "cs" return "Czech"
        case "cu" return "Church Slavonic"
        case "cy" return "Welsh"
        case "de" return "German"
        case "dlm" return "Dalmatian"
        case "egy-Egyd" return "Egyptian in Demotic script"
        case "egy-Egyh" return "Egyptian in Hieratic script"
        case "el" return "Greek"
        case "en" return "English"
        case "eng" return "English"
        case "eng-Latn-x-lc" return "English"
        case "es" return "Spanish"
        case "fr" return "French"
        case "fre" return "French"
        case "fy" return "Frisian"
        case "ga" return "Irish"
        case "gd" return "Gaelic"
        case "ger" return "German"
        case "grc" return "Greek"
        case "he" return "Hebrew"
        case "hr" return "Croatian"
        case "hu" return "Hungarian"
        case "is" return "Icelandic"
        case "it" return "Italian"
        case "ita" return "Italian"
        case "kw" return "Cornish"
        case "la" return "Latin"
        case "lat" return "Latin"
        case "nah" return "Nahuatl"
        case "nl" return "Dutch/Flemish"
        case "pro" return "French"
        case "pt" return "Portugese"
        case "ru" return "Russian"
        case "rus" return "Russian"
        case "sco" return "Scots"
        case "spa" return "Spanish"
        case "syc" return "Syriac"
        case "zxx" return "No Linguistic Content"
        default return $lang
};

<add>
{
    let $doc := doc("../works.xml")
    let $collection := collection("../collections?select=*.xml;recurse=yes")
    let $works := $doc//tei:listBibl/tei:bibl[@xml:id]
   
    for $work in $works
        let $id := $work/@xml:id/string()
        let $title := fn:normalize-space($work//tei:title[@type="uniform"][1]/string())
        let $mss := $collection//tei:TEI[.//tei:title[@key = $id]]
        let $lang := $work/tei:textLang/string(@mainLang)
        let $subjects := fn:distinct-values($work/tei:note[@type = "subject"]/string())

        return if (count($mss) > 0) then
        <doc>
            <field name="type">work</field>
            <field name="pk">{ $id }</field>
            <field name="id">{ $id }</field>
            <field name="title">{ $title }</field>
            <field name="wk_title_s">{ $title }</field>
            <field name="alpha_title">
                { functx:capitalize-first(substring(replace($title, '[^\p{L}|\p{N}]+', ''), 1, 1))}
            </field>
            <field name="wk_lang_sm">{ local:languageValue($lang) }</field>
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
            local:logging('info', 'Skipping work in works.xml but not in any manuscript', ($id, $title))
            )
}

{
    let $controlledworkids := doc("../works.xml")//tei:listBibl/tei:bibl/@xml:id/string()
    let $allworks := collection("../collections?select=*.xml;recurse=yes")//tei:TEI//tei:title
    let $allworksids := distinct-values($allworks/@key/string())
    for $workid in $allworksids
        return if (not($controlledworkids[. = $workid])) then
            local:logging('warn', 'Work in manuscripts not in works.xml: will create broken link', ($workid, normalize-space(string-join($allworks[@key = $workid][1]/text(), ''))))
        else 
            ()
}

{
    let $allmsitems := collection("../collections?select=*.xml;recurse=yes")//tei:TEI//tei:msItem/tei:title
    return if (count($allmsitems[not(@key)]) > 0) then local:logging('info', concat(count($allmsitems[not(@key)]), ' msItems found in manuscripts which lack @key attributes'), ()) else ()
}

</add>