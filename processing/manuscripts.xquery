import module namespace functx = "http://www.functx.com" at "functx.xq";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";
declare option saxon:output "indent=yes";
declare variable $disablelogging as xs:boolean external := false();

declare function local:logging($level, $msg, $values)
{
    if (not($disablelogging)) then
        (: Trick XQuery into doing trace() to output message to STDERR but not insert it into the XML :)
        substring(trace('', concat(upper-case($level), '	', $msg, '	', string-join($values, '	'), '	')), 0, 0)
    else ()
};

declare function local:authors($contents)
{
    for $item in distinct-values($contents/tei:msItem/tei:author/tei:persName/text())
    return <field name="ms_authors_sm">{ normalize-space($item) }</field>
};

declare function local:works($contents)
{
    for $item in distinct-values(fn:data($contents/tei:msItem/tei:title))
    let $titletext := normalize-space($item)
    return
        if (string-length($titletext) > 0) then
            <field name="ms_works_sm">{ $titletext }</field>
        else ()   
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
    let $dateEarliest := $doc//tei:msPart/tei:history/tei:origin/tei:origDate[string(number(@notBefore)) != 'NaN']/@notBefore
    return if (empty($dateEarliest)) then
        ()
    else
        <field name="ms_date_earliest_i">{ min($dateEarliest) }</field>
};

declare function local:dateLatest($doc)
{
    let $dateLatest := $doc//tei:msPart/tei:history/tei:origin/tei:origDate[string(number(@notAfter)) != 'NaN']/@notAfter
    return if (empty($dateLatest)) then
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

declare function local:formatCentury($centuryNum)
{
    (: Converts century in number form (negative integers for BCE, positive integers for CE) into human-readable form :)
    if ($centuryNum gt 0) then
        concat($centuryNum, local:ordinal($centuryNum), ' Century')
    else
        concat(abs($centuryNum), local:ordinal(abs($centuryNum)), ' Century BCE')
};

declare function local:findCenturies($earliestYear, $latestYear)
{
    (: Converts a year range (or single year) into a sequence of century names :)

    (: Zero below stands for null, as there is no Year 0 :)
    let $ey := number(functx:if-empty($earliestYear, 0))
    let $ly := number(functx:if-empty($latestYear, 0))
    
    let $earliestIsTurnOfCentury := ends-with($earliestYear, '00')
    let $latestIsTurnOfCentury := ends-with($latestYear, '00')
    
    (: Convert years to centuries. Special cases required for turn-of-the-century years, e.g. 1500 AD is treated 
       as 16th century if at the start of a range, or the only known year, but as 15th if at the end of a range; 
       while 200 BC is treated as 3rd century BCE if at the end of a range but as 2nd BCE at the start. :)
    let $earliestCentury := (
        if ($ey gt 0 and $earliestIsTurnOfCentury) then 
            ($ey div 100) + 1
        else if ($ey lt 0) then
            floor($ey div 100)
        else 
            ceiling($ey div 100)
        )      
    let $latestCentury := (
        if ($ly lt 0 and $latestIsTurnOfCentury) then 
            ($ly div 100) - 1
        else if ($ly lt 0) then
            floor($ly div 100)
        else 
            ceiling($ly div 100)
        )

    return    
        if ($ey gt $ly and $ly ne 0) then
            local:logging('info', 'Date range not valid so will not be added to century filter', concat($earliestYear, '-', $latestYear))
            
        else if ($earliestCentury ne 0 and $latestCentury ne 0) then
            (: A date range, something like "After 1400 and before 1650", so fill in all the possible centuries between :)
            for $century in (-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21)
                return
                    if ($century ge $earliestCentury and $century le $latestCentury) then
                        local:formatCentury($century)
                    else
                        ()
         else
            (: Only a single date, either a precise year or an open-ended range like "Before 1500" or "After 1066", so just output the known century :)
            local:formatCentury(($earliestCentury, $latestCentury)[. ne 0])
};

declare function local:centuries($doc)
{
    let $dates := $doc//tei:origin//tei:origDate
    let $centuries := (
        for $date in $dates
            return
            if ($date[@when]) then 
                local:findCenturies($date/@when/data(), '')
            else if ($date[@notBefore] or $date[@notAfter]) then
                local:findCenturies($date/@notBefore/data(), $date/@notAfter/data())
            else
                ()
        )
    for $century in distinct-values($centuries)
        order by $century
        return if (string-length($century) gt 0) then <field name="ms_date_sm">{ $century }</field> else ()
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
    let $text := $content//text()
    return if (empty($text)) then
        ()
    else
        <field name="ms_textcontent_smni">{ fn:normalize-space(fn:string-join($text, " ")) }</field>
};

<add>
{
for $x in collection('../collections/?select=*.xml;recurse=yes')
    let $subfolder := fn:tokenize(fn:base-uri($x), '/')[last() - 1]
    let $htmlfile := concat($x//tei:sourceDesc/tei:msDesc[1]/@xml:id/data(), '.html')
    let $htmldoc := doc(concat("html/", $subfolder, '/', $htmlfile))
    let $msid := $x//tei:TEI/@xml:id/data()
    let $htmlcontent := $htmldoc//html:div[@id = $msid]
    let $title := $x//tei:msDesc/tei:msIdentifier/tei:idno[@type="shelfmark"]/text()
    let $htmlcontent := fn:normalize-space(fn:serialize($htmlcontent))
  
(:
The following three date fields have been removed from the doc output below
Reinstate them if advanced search on precise dates is developed
local:dateEarliest($x)
local:dateLatest($x)
<field name="ms_date_stmt_s"> $x//tei:history/tei:origin/tei:origDate/text() </field>
:)

return <doc>
    <field name="type">manuscript</field>
    <field name="pk">{ $msid }</field>
    <field name="id">{ $msid }</field>
    <field name="title">{ $title }</field>
    <field name="ms_collection_s">{ $x//tei:titleStmt/tei:title[@type="collection"]/text() }</field>
    <field name="ms_settlement_s">{ $x//tei:msDesc/tei:msIdentifier/tei:settlement/text() }</field>
    {
        if (string-length($x//tei:msDesc/tei:msIdentifier/tei:institution/text()) > 0) then
            <field name="ms_institution_s">{ $x//tei:msDesc/tei:msIdentifier/tei:institution/text() }</field>
        else
            local:logging('info', 'Manuscript lacks institution', ($msid, $title))
    }
    <field name="ms_repository_s">{ $x//tei:msDesc/tei:msIdentifier/tei:repository/text() }</field>
    <field name="ms_shelfmark_s">{ $x//tei:msDesc/tei:msIdentifier/tei:idno[@type="shelfmark"]/text() }</field>
    <field name="ms_shelfmark_sort">{ $x//tei:msDesc/tei:msIdentifier/tei:idno[@type="shelfmark"]/text() }</field>
    <field name="ms_altid_s">{ $x//tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:altIdentifier[@type="internal"]/tei:idno/text() }</field>
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