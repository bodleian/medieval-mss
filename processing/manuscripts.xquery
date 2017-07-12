import module namespace functx = "http://www.functx.com" at "functx.xq";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";

declare function local:authors($contents)
{
    for $item in distinct-values($contents/tei:msItem/tei:author/tei:persName/text())
    return <field name="ms_authors_sm">{ normalize-space($item) }</field>
};

declare function local:works($contents)
{
    for $item in distinct-values(fn:data($contents/tei:msItem/tei:title))
    return <field name="ms_works_sm">{ normalize-space($item) }</field>
};


declare function local:corpnames($contents)
{
    for $item in distinct-values($contents//tei:name[@type="corporate"]/tei:persName/text())
    return <field name="ms_corpnames_sm">{ normalize-space($item) }</field>
};

declare function local:persnames($contents)
{
    for $item in distinct-values($contents//tei:persName/text())
    return <field name="ms_persnames_sm">{ normalize-space($item) }</field>
};

declare function local:deconotes($contents)
{
    let $hasDeco := exists($contents//tei:decoDesc/tei:decoNote)
    return if ($hasDeco) then
        <field name="ms_deconote_b">true</field>
    else
        <field name="ms_deconote_b">false</field>
};

declare function local:dateEarliest($doc)
{
    let $dateEarliest := $doc//tei:msPart/tei:history/tei:origin/tei:date[@notBefore]/string(@notBefore)
    return if (empty($doc//tei:msPart/tei:history/tei:origin/tei:date[@notBefore])) then
        ()
    else
        <field name="ms_date_earliest_i">{ min($dateEarliest) }</field>
};

declare function local:dateLatest($doc)
{
    let $dateLatest := $doc//tei:msPart/tei:history/tei:origin/tei:date[@notAfter]/string(@notAfter)
    return if (empty($doc//tei:msPart/tei:history/tei:origin/tei:date[@notAfter])) then
        ()
    else
        <field name="ms_date_latest_i">{ max($dateLatest) }</field>
};

declare function local:ordinal($num)
{
    switch($num)
    case 1 return "st"
    case 2 return "nd"
    case 3 return "rd"
    default return "th"
};

declare function local:formatCenturyBCE($dateEarliest, $dateLatest)
{
    (:
        BCE dates need to be calculated in reverse.
    :)
    (:
        - Cast to abs, add 1
        - Ceiling it
        - Take value
        - Take first two digits
        - If original starts with "-" append "BC"

        -200 => 200 => 201 => ceil() => 300 => 3rd C.
        -199 => 199 => 200 => ceil() => 200 => 2nd C.

    :)

    let $absDateEarliest := fn:abs(functx:if-empty($dateEarliest, -1000000))
    let $absDateLatest := fn:abs(functx:if-empty($dateLatest, -1000000))

    let $ceilEarliestCentury := fn:ceiling($absDateEarliest div 100)
    let $ceilLatestCentury := fn:ceiling($absDateLatest div 100)

    return if ($ceilEarliestCentury = $ceilLatestCentury and fn:starts-with($dateEarliest, "-") and $ceilEarliestCentury != 10000) then
        <field name="ms_date_sm">{ $ceilEarliestCentury }{ local:ordinal($ceilEarliestCentury) } Century BCE</field>
    else if (fn:starts-with($dateEarliest, "-") and fn:starts-with($dateLatest, "-") and $ceilEarliestCentury != 10000) then
        (<field name="ms_date_sm">{ $ceilEarliestCentury }{ local:ordinal($ceilEarliestCentury) } Century BCE</field>,
        <field name="ms_date_sm">{ $ceilLatestCentury }{ local:ordinal($ceilLatestCentury) } Century BCE</field>)
    else
        ()

};

declare function local:formatCentury($dateEarliest, $dateLatest)
{
    (:
        The value of -10000 is an integer that is unlikely to occur in the corpus, (since we're only
         ever taking the first two digits) so it essentially stands for 'null' (but we don't like nulls in our XML,
         do we precious?)
    :)
    let $earliestCentury := xs:integer(functx:if-empty(substring($dateEarliest, 1, 2), -10000))
    let $latestCentury := xs:integer(functx:if-empty(substring($dateLatest, 1, 2), -10000))
    let $latestDecade := functx:if-empty(substring($dateLatest, 3, 2), "-10000")
    (: If they're the same century, and that century is not -10,000, then return one of them :)

    return if ($earliestCentury = -10000 or $latestCentury = -10000) then
        ()
    else if ($earliestCentury = $latestCentury and $earliestCentury != -10000) then
        <field name="ms_date_sm">{ $earliestCentury + 1 }{ local:ordinal(($earliestCentury + 1)) } Century</field>
    else if ($earliestCentury != $latestCentury and $latestDecade = "00") then
        <field name="ms_date_sm">{ $earliestCentury + 1 }{ local:ordinal(($earliestCentury + 1)) } Century</field>
    else if ($earliestCentury != $latestCentury and $latestDecade != "00") then
        (<field name="ms_date_sm">{ $earliestCentury + 1 }{ local:ordinal(($earliestCentury + 1)) } Century</field>,
        <field name="ms_date_sm">{ $latestCentury + 1 }{ local:ordinal(($latestCentury + 1)) } Century</field>)
    else
        ()
};

declare function local:centuries($doc)
{
    let $dates := $doc//tei:origin//tei:origDate
    for $date in $dates
        let $dateEarliest := $date/@notBefore/data()
        let $dateLatest := $date/@notAfter/data()
        return if (fn:starts-with($dateEarliest, "-")) then
            local:formatCenturyBCE($dateEarliest, $dateLatest)
        else
            local:formatCentury($dateEarliest, $dateLatest)
};

declare function local:when($doc)
{
    let $dates := $doc//tei:origin//tei:origDate
    for $date in $dates
        let $dateWhen := $date/@when/data()
        return if (fn:starts-with($dateWhen, "-")) then
            local:formatCenturyBCE($dateWhen, $dateWhen)
        else
            local:formatCentury($dateWhen, $dateWhen)
};

declare function local:materialValue($material)
{
    switch ($material)
        case "perg" return "Parchment"
        case "chart" return "Paper"
        case "papyrus" return "Papyrus"
        case "mixed" return "Mixed"
        case "unknown" return "Unknown"
        default return "Other"
};

declare function local:materials($contents)
{
    for $item in distinct-values($contents//tei:physDesc//tei:supportDesc[@material]/string(@material))
    return <field name="ms_materials_sm">{ normalize-space(local:materialValue($item)) }</field>
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

declare function local:countryValue($place)
{
    switch($place)
        case "place_7002445" return "England"
        case "place_1000080" return "Italy"
        case "place_7014986" return "Egypt (ancient)"
        case "place_1000070" return "France"
        case "place_7000084" return "Germany"
        case "place_7024407" return "Byzantine Empire"
        case "place_7024097" return "Flanders"
        case "place_7016845" return "Netherlands"
        case "place_1000095" return "Spain"
        case "place_1000078" return "Ireland"
        case "place_1006894" return "Cyprus"
        case "place_1000062" return "Austria"
        case "place_8697461" return "Greece"
        case "place_7012056" return "Crete"
        case "place_1000003" return "Europe"
        case "place_7004540" return "Palestine"
        case "place_7006366" return "Poland"
        case "place_7011731" return "Switzerland"
        case "place_1000077" return "Iceland"
        case "place_7002443" return "Wales"
        case "place_1000090" return "Portugal"
        case "place_7002435" return "Russia"
        case "place_7015451" return "Dalmatia"
        case "place_7005560" return "Mexico"
        case "place_7002444" return "Scotland"
        case "place_7006470" return "Bohemia"
        case "place_1000063" return "Belgium"
        case "place_7006413" return "Bulgaria"
        case "place_7030216" return "Catalonia"
        case "place_7006278" return "Hungary"
        case "place_7029439" return "Low Countries"
        case "place_7003514" return "Luxemburg"
        case "place_7009155" return "Moldavia"
        case "place_7006669" return "Serbia"
        case "place_1000097" return "Sweden"
        case "place_1000140" return "Syria"
        case "" return "[MISSING]"
        default return $place
};

declare function local:mainLang($doc)
{
    let $mainLang := distinct-values($doc//tei:textLang/@mainLang)
    for $lang in $mainLang
    return <field name="ms_lang_sm">{ normalize-space(local:languageValue($lang)) }</field>
};

declare function local:otherLangs($doc)
{
    let $otherLangs := tokenize(string-join(distinct-values($doc//tei:textLang/@otherLangs), " "), "\s")
    for $lang in $otherLangs
    return <field name="ms_lang_sm">{ normalize-space(local:languageValue($lang))}</field>
};

declare function local:origin($doc)
{
    let $origins := distinct-values($doc//tei:origPlace/tei:country/string(@key))
    for $origin in $origins
    return <field name="ms_origin_sm">{ local:countryValue($origin) }</field>
};

declare function local:form($doc)
{
    let $forms := distinct-values($doc//tei:objectDesc/@form)
    for $form in $forms
    return <field name="ms_form_sm">{ fn:normalize-space($form) }</field>
};

(: Create a fairly generic field for dumping text content from the MSS record to allow for fulltext searching of the MSS :)
(: Stored multiple but not indexed since it's not used for retrieval. This field will automatically get copied into
    the fulltext index on Solr. :)
declare function local:textcontent($content)
{
    let $text := $content/text()
    return if (empty($text)) then
        ()
    else
        <field name="ms_textcontent_smni">{ fn:normalize-space(fn:string-join($text, " ")) }</field>
};

<add>
{
for $x in collection('../collections/?select=*.xml;recurse=yes')
    let $filepath := fn:tokenize(fn:base-uri($x), '/')
    let $htmlfile := concat($filepath[count($filepath) - 1], "/", $filepath[count($filepath)])
    let $htmldoc := doc(concat("html/", replace($htmlfile, ".xml", ".html")))
    let $msid := $x//tei:TEI/@xml:id/data()
    let $title := $x//tei:msDesc/tei:msIdentifier/tei:idno[@type="shelfmark"]/text()
    let $htmlcontent := fn:normalize-space(fn:serialize($htmldoc//div[@id = $msid]))

return <doc>
    <field name="type">manuscript</field>
    <field name="pk">{ $msid }</field>
    <field name="id">{ $msid }</field>
    <field name="title">{ $title }</field>
    <field name="ms_collection_s">{ $x//tei:titleStmt/tei:title[@type="collection"]/text() }</field>
    <field name="ms_settlement_s">{ $x//tei:msDesc/tei:msIdentifier/tei:settlement/text() }</field>
    <field name="ms_institution_s">{ $x//tei:msDesc/tei:msIdentifier/tei:repository/text() }</field>
    <field name="ms_repository_s">{ $x//tei:msDesc/tei:msIdentifier/tei:repository/text() }</field>
    <field name="ms_shelfmark_s">{ $x//tei:msDesc/tei:msIdentifier/tei:idno[@type="shelfmark"]/text() }</field>
    <field name="ms_shelfmark_sort">{ $x//tei:msDesc/tei:msIdentifier/tei:idno[@type="shelfmark"]/text() }</field>
    <field name="ms_altid_s">{ $x//tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:altIdentifier[@type="internal"]/tei:idno/text() }</field>
    { local:dateEarliest($x) }
    { local:dateLatest($x) }
    <field name="ms_date_stmt_s">{ $x//tei:history/tei:origin/tei:date/text() }</field>
    <field name="filename_sni">{ fn:base-uri($x) }</field>
    { local:works($x//tei:msContents) }
    { local:authors($x//tei:msContents) }
    { local:materials($x//tei:msDesc) }
    { local:corpnames($x//tei:sourceDesc) }
    { local:persnames($x//tei:sourceDesc) }
    { local:deconotes($x//tei:sourceDesc) }
    { local:mainLang($x//tei:sourceDesc) }
    { local:otherLangs($x//tei:sourceDesc) }
    { local:origin($x//tei:sourceDesc) }
    { local:centuries($x) }
    { local:when($x) }
    { local:textcontent($x//tei:incipit) }
    { local:textcontent($x//tei:explicit) }
    { local:textcontent($x//tei:note) }
    { local:textcontent($x//tei:decoNote) }
    { local:textcontent($x//tei:additions) }
    { local:textcontent($x//tei:provenance) }
    <field name="ms_display_txt">{ $htmlcontent }</field>
</doc>
}
</add>