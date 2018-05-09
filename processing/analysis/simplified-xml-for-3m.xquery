declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

declare variable $website := 'https://medieval.bodleian.ox.ac.uk';

declare function local:logging($level as xs:string, $msg as xs:string, $values)
{
    (: Trick XQuery into doing trace() to output message to STDERR but not insert it into the XML :)
    substring(trace('', concat(upper-case($level), '	', $msg, '	', string-join($values, '	'), '	')), 0, 0)
};

declare function local:languageCodeLookup($lang as xs:string) as xs:string*
{
    (: These cover the language codes presented in the Medieval and Islamic collections as of May 2018 :)
    switch($lang)
    case 'ar' return ('Arabic', 'http://vocab.getty.edu/aat/300387843')
    case 'fa' return ('Persian', 'http://vocab.getty.edu/aat/300389088')
    case 'pers' return ('Persian', 'http://vocab.getty.edu/aat/300389088')
    case 'ang' return ('English', 'http://vocab.getty.edu/aat/300388277')
    case 'ara' return ('Arabic', 'http://vocab.getty.edu/aat/300387843')
    case 'ara-Latn-x-lc' return ('Arabic', 'http://vocab.getty.edu/aat/300387843')
    case 'ara-Latn-x-lx' return ('Arabic', 'http://vocab.getty.edu/aat/300387843')
    case 'br' return ('French', 'http://vocab.getty.edu/aat/300388306')
    case 'cop' return ('Coptic', 'http://vocab.getty.edu/aat/300388268')
    case 'el' return ('Greek', 'http://vocab.getty.edu/aat/300389734')
    case 'en' return ('English', 'http://vocab.getty.edu/aat/300388277')
    case 'eng' return ('English', 'http://vocab.getty.edu/aat/300388277')
    case 'eng-Latn-x-lc' return ('English', 'http://vocab.getty.edu/aat/300388277')
    case 'es' return ('Spanish', 'http://vocab.getty.edu/aat/300389311')
    case 'fr' return ('French', 'http://vocab.getty.edu/aat/300388306')
    case 'grc' return ('Greek', 'http://vocab.getty.edu/aat/300389734')
    case 'he' return ('Hebrew', 'http://vocab.getty.edu/aat/300388401')
    case 'la' return ('Latin', 'http://vocab.getty.edu/aat/300388693')
    case 'lat' return ('Latin', 'http://vocab.getty.edu/aat/300388693')
    case 'pro' return ('French', 'http://vocab.getty.edu/aat/300388306')
    case 'spa' return ('Spanish', 'http://vocab.getty.edu/aat/300389311')
    case 'syc' return ('Syriac', 'http://vocab.getty.edu/aat/300389337')
    case 'ota' return ('Ottoman Turkish', 'https://www.wikidata.org/wiki/Q36730')
    case 'ps' return ('Pashto', 'http://vocab.getty.edu/aat/300389070')
    case 'syr' return ('Syriac', 'http://vocab.getty.edu/aat/300389337')
    case 'ur' return ('Urdu', 'http://vocab.getty.edu/aat/300389502')
    case 'ara-Arab' return ('Arabic', 'http://vocab.getty.edu/aat/300387843')
    case 'pes' return ('Persian', 'http://vocab.getty.edu/aat/300389088')
    case 'chg' return ('Chagatai', 'http://vocab.getty.edu/aat/300388081')
    case 'ms' return ('Malay', 'http://vocab.getty.edu/aat/300388786')
    case 'jrb' return ('Judeo-Arabic', 'https://www.wikidata.org/wiki/Q37733')
    case 'gre' return ('Greek', 'http://vocab.getty.edu/aat/300389734')
    case 'kas' return ('Kashmiri', 'http://vocab.getty.edu/aat/300388558')
    case 'arm' return ('Armenian', 'http://vocab.getty.edu/aat/300387870')
    case 'uig' return ('Uighur', 'http://vocab.getty.edu/aat/300389509')
    case 'ave' return ('Avestan', 'https://www.wikidata.org/wiki/Q29572')
    case 'bn' return ('Bengali', 'http://vocab.getty.edu/aat/300387971')
    case 'sa' return ('Sanskrit', 'http://vocab.getty.edu/aat/300389205')
    case 'ara-Latn' return ('Arabic', 'http://vocab.getty.edu/aat/300387843')
    case 'dan' return ('Danish', 'http://vocab.getty.edu/aat/300388204')
    case 'mn' return ('Mongolian', 'http://vocab.getty.edu/aat/300388900')
    case 'prs' return ('Dari Persian', 'http://vocab.getty.edu/aat/300388208')
    case 'hy' return ('Armenian', 'http://vocab.getty.edu/aat/300387870')
    case 'it' return ('Italian', 'http://vocab.getty.edu/aat/300388474')
    case 'ita' return ('Italian', 'http://vocab.getty.edu/aat/300388474')
    case 'jv' return ('Javanese', 'http://vocab.getty.edu/aat/300388490')
    case 'fre' return ('French', 'http://vocab.getty.edu/aat/300388306')
    case 'an' return ('Spanish', 'http://vocab.getty.edu/aat/300389311')
    case 'de' return ('German', 'http://vocab.getty.edu/aat/300388344')
    case 'nl' return ('Dutch/Flemish', 'http://vocab.getty.edu/aat/300388301')
    case 'ga' return ('Irish', 'http://vocab.getty.edu/aat/300111259')
    case 'egy-Egyd' return ('Egyptian in Demotic script', 'http://vocab.getty.edu/aat/300206213')
    case 'cu' return ('Church Slavonic', 'http://vocab.getty.edu/aat/300389289')
    case 'ru' return ('Russian', 'http://vocab.getty.edu/aat/300389168')
    case 'cy' return ('Welsh', 'http://vocab.getty.edu/aat/300389555')
    case 'pt' return ('Portuguese', 'http://vocab.getty.edu/aat/300389115')
    case 'kw' return ('Cornish', 'http://vocab.getty.edu/aat/300388179')
    case 'is' return ('Icelandic', 'http://vocab.getty.edu/aat/300388449')
    case 'ca' return ('Catalan', 'http://vocab.getty.edu/aat/300388072')
    case 'hr' return ('Croatian', 'http://vocab.getty.edu/aat/300388185')
    case 'egy-Egyh' return ('Egyptian in Hieratic script', 'http://vocab.getty.edu/aat/300206211')
    case 'cs' return ('Czech', 'http://vocab.getty.edu/aat/300388191')
    case 'sco' return ('Scots', 'http://vocab.getty.edu/aat/300389222')
    case 'nah' return ('Nahuatl', 'http://vocab.getty.edu/aat/300388932')
    case 'hu' return ('Hungarian', 'http://vocab.getty.edu/aat/300388770')
    case 'gd' return ('Gaelic', 'http://vocab.getty.edu/aat/300388323')
    case 'fy' return ('Frisian', 'http://vocab.getty.edu/aat/300388308')
    case 'dlm' return ('Dalmatian', 'http://vocab.getty.edu/aat/300388199')
    case 'zxx' return ()
    default return (local:logging('error', 'Unrecognized language code', $lang), ())[2]
};

declare function local:dateConversion($datestring as xs:string, $begin as xs:boolean) as xs:dateTime*
{
    let $isbce := starts-with($datestring, '-')
    let $datestring := if ($isbce) then substring($datestring, 2) else $datestring
    let $year := if (string-length($datestring) eq 0) then '' else if (matches($datestring, '^\d\d\d\d$')) then $datestring else if (matches($datestring, '^\d\d\d$')) then concat('0', $datestring) else if (matches($datestring, '^\d\d\d\d')) then substring($datestring, 1, 4) else if (matches($datestring, '^\d\d\d')) then concat('0', substring($datestring, 1, 3)) else ''
    let $year := if ($isbce) then concat('-', $year) else $year
    let $month := if (matches($datestring, '^\d?\d\d\d-\d\d')) then substring(substring-after($datestring, '-'), 1, 2) else ''
    let $day := if (matches($datestring, '^\d?\d\d\d-\d\d-\d\d')) then substring(substring-after(substring-after($datestring, '-'), '-'), 1, 2) else ''
    
    return
    if ($year ne '' and $month ne '' and $day ne '') then
        if ($begin) then
            xs:dateTime(concat($year, '-', $month, '-', $day, 'T00:00:00'))
        else
            xs:dateTime(concat($year, '-', $month, '-', $day, 'T23:59:59'))
    else if ($year ne '' and $month ne '') then
        if ($begin) then
            xs:dateTime(concat($year, '-', $month, '-01', 'T00:00:00'))
        else
            let $nextmonth := xs:integer($month) + 1
            return if ($nextmonth le 12) then
                let $nextmonthstring := if ($nextmonth lt 10) then concat('0',xs:string($nextmonth)) else xs:string($nextmonth)
                let $dayafter := xs:dateTime(concat($year, '-', $nextmonthstring, '-01', 'T00:00:00'))
                return $dayafter - xs:dayTimeDuration('PT1S')
            else
                xs:dateTime(concat($year, '-', $month, '-31', 'T23:59:59'))
    else if ($year ne '') then
        if ($begin) then
            xs:dateTime(concat($year, '-01-01', 'T00:00:00'))
        else
            xs:dateTime(concat($year, '-12-31', 'T23:59:59'))
    else
        (local:logging('error', 'Unrecognized date format', $datestring), ())[2]
};

declare function local:listItems($manuscript as element(tei:TEI), $mscontent as element(tei:msContents)) as element()*
{
    for $msItem in $mscontent//tei:msItem[tei:title/@key]
        (: This flattens all works (msItem) into one list. In the TEI, there can be a hierarchy of works-within-works. :)
        let $itemid := $msItem/@xml:id/data()
        let $workid := ($msItem/tei:title/@key)[1]/data()
        return
        <item>
            <uri>{ $website }/catalog/{ $manuscript/@xml:id/data() }#{ $itemid }</uri>
            <title>
                <uri>{ $website }/catalog/{ $workid }</uri>
                <label>{ normalize-space(string-join($msItem/tei:title[@key = $workid]//text(), '')) }</label>
            </title>
            {
            for $author in ($msItem/tei:author|$msItem/*/tei:persName[@role='author'])[@key]
                return
                <author>
                    <uri>{ $website }/catalog/{ $author/@key/data() }</uri>
                    <label>{ normalize-space(string-join($author//text(), '')) }</label>
                </author>
            }
            {
            for $lang in distinct-values(tokenize(string-join(($msItem//tei:textLang/@mainLang/data(), $msItem//tei:textLang/@otherLangs/data()), ' '), ' '))
                let $langLabelAndUri := local:languageCodeLookup($lang)
                return
                if (count($langLabelAndUri) eq 2) then
                    <language>
                        <uri>{ $langLabelAndUri[2] }</uri>
                        <label>{ $langLabelAndUri[1] }</label>
                    </language>
                else
                    ()
            }
            {
            local:listPeoplePlacesEtc($msItem)
            }
        </item>
};

declare function local:extractPhysicalFields($physdesc as element(tei:physDesc)?) as element()*
{
    (
    for $material in $physdesc//tei:supportDesc/@material/data()
        return 
        switch ($material)
        case 'perg' return <material><uri>http://vocab.getty.edu/aat/300011851</uri><label>Parchment</label></material>
        case 'chart' return <material><uri>http://vocab.getty.edu/aat/300014109</uri><label>Paper</label></material>
        case 'paper' return <material><uri>http://vocab.getty.edu/aat/300014109</uri><label>Paper</label></material>
        case 'papyrus' return <material><uri>http://vocab.getty.edu/aat/300014127</uri><label>Papyrus</label></material>
        case 'mixed' return <material><uri>http://vocab.getty.edu/aat/300404821</uri><label>Mixed</label></material>
        default return ()
    ,
    for $dimension in $physdesc//tei:dimensions[@unit and @type]
        let $units := $dimension/@unit/data()
        let $type := $dimension/@type/data()
        return
        <dimensions>
            {
            for $dim in $dimension/(tei:width|tei:height)
                return
                if ($dim/self::tei:width) then
                    <width type="{ $type }" units="{ $units }">{ normalize-space(string-join($dim//text(), '')) }</width>
                else
                    <height type="{ $type }" units="{ $units }">{ normalize-space(string-join($dim//text(), '')) }</height>
            }        
        </dimensions>
    ,
    for $layout in $physdesc//tei:layout[@columns or @ruledLines or @writtenLines]
        return
        <layout>
            {
            if ($layout/@columns) then
                let $values := tokenize($layout/@columns/data(), ' ')
                return
                <columns>
                    <min>{ $values[1] }</min>
                    <max>{ $values[last()]}</max>
                </columns>
            else
                ()
            }
            {
            if ($layout/@ruledLines) then
                let $values := tokenize($layout/@ruledLines/data(), ' ')
                return
                <linespercolumn type="ruled">
                    <min>{ $values[1] }</min>
                    <max>{ $values[last()]}</max>
                </linespercolumn>
            else
                ()
            }
            {
            if ($layout/@writtenLines) then
                let $values := tokenize($layout/@writtenLines/data(), ' ')
                return
                <linespercolumn type="written">
                    <min>{ $values[1] }</min>
                    <max>{ $values[last()]}</max>
                </linespercolumn>
            else
                ()
            }
        </layout>
    )
};

declare function local:extractDates($history as element(tei:history)?) as element()*
{
    (: Simply dates to a single range for each type. This means losing some detail 
       (e.g. text written in one century, illustrations in the next.) but that would
       be difficult to model in 3M anyway. :)
    (
    (: Origin dates :)
    let $begindates := (
        for $date in $history//tei:origDate/(@when|@notBefore|@from)/data()
            return
            local:dateConversion(normalize-space($date), true())
    )
    let $enddates := (
        for $date in $history//tei:origDate/(@when|@notAfter|@to)/data()
            return
            local:dateConversion(normalize-space($date), false())
    )
    return if (count($begindates) gt 0 and count($enddates) gt 0) then
        <date context="origin">
            <from>{ min($begindates) }</from>
            <to>{ max($enddates) }</to>
        </date>
    else if (count($begindates) gt 0) then
        <date context="origin">
            <from>{ min($begindates) }</from>
        </date>
    else if (count($enddates) gt 0) then
        <date context="origin">
            <to>{ max($enddates) }</to>
        </date>
    else
        ()
    ,
    (: Provenance dates :)
    let $begindates := (
        for $date in ($history/tei:provenance//tei:date/(@when|@notBefore|@from)/data(), $history/tei:provenance/(@when|@notBefore|@from)/data())
            return
            local:dateConversion(normalize-space($date), true())
    )
    let $enddates := (
        for $date in ($history/tei:provenance//tei:date/(@when|@notAfter|@to)/data(), $history/tei:provenance/(@when|@notBefore|@from)/data())
            return
            local:dateConversion(normalize-space($date), false())
    )
    return if (count($begindates) gt 0 and count($enddates) gt 0) then
        <date context="provenance">
            <from>{ min($begindates) }</from>
            <to>{ max($enddates) }</to>
        </date>
    else if (count($begindates) gt 0) then
        <date context="provenance">
            <from>{ min($begindates) }</from>
        </date>
    else if (count($enddates) gt 0) then
        <date context="provenance">
            <to>{ max($enddates) }</to>
        </date>
    else
        ()
    ,
    (: Acquisition dates :)
    let $begindates := (
        for $date in ($history/tei:acquisition//tei:date/(@when|@notBefore|@from)/data(), $history/tei:acquisition/(@when|@notBefore|@from)/data())
            return
            local:dateConversion(normalize-space($date), true())
    )
    let $enddates := (
        for $date in ($history/tei:acquisition//tei:date/(@when|@notAfter|@to)/data(), $history/tei:acquisition/(@when|@notAfter|@to)/data())
            return
            local:dateConversion(normalize-space($date), false())
    )
    return if (count($begindates) gt 0 and count($enddates) gt 0) then
        <date context="acquisition">
            <from>{ min($begindates) }</from>
            <to>{ max($enddates) }</to>
        </date>
    else if (count($begindates) gt 0) then
        <date context="acquisition">
            <from>{ min($begindates) }</from>
        </date>
    else if (count($enddates) gt 0) then
        <date context="acquisition">
            <to>{ max($enddates) }</to>
        </date>
    else
        ()
    )
};

declare function local:listPeoplePlacesEtc($msorpartoritem as element()) as element()*
{
    (
    (: Places :)
    for $placename in $msorpartoritem//(tei:placeName|tei:country|tei:region|tei:settlement)[@key]
        let $contexts := (for $ancest in $placename/ancestor::* return if (name($ancest) = ('title','author','origin','provenance','acquisition','physDesc','bibl')) then lower-case(name($ancest)) else ())
        return if ($placename/ancestor::*[@xml:id][1]/@xml:id = $msorpartoritem/@xml:id) then
            <place>
                { if ($placename/@role) then attribute role { $placename/@role/data() } else () }
                { if (count($contexts) gt 0) then attribute context { string-join($contexts, ' ') } else () }
                <uri>{ $website }/catalog/{ $placename/@key/data() }</uri>
                <label>{ normalize-space(string-join($placename//text(), '')) }</label>
            </place>
        else
            ()
    ,
    (: Organizations :)
    for $orgname in $msorpartoritem//tei:orgName[@key]
        let $contexts := (for $ancest in $orgname/ancestor::* return if (name($ancest) = ('title','author','origin','provenance','acquisition','physDesc','bibl')) then lower-case(name($ancest)) else ())
        return if ($orgname/ancestor::*[@xml:id][1]/@xml:id = $msorpartoritem/@xml:id) then
            <org>
                { if ($orgname/@role) then attribute role { $orgname/@role/data() } else () }
                { if (count($contexts) gt 0) then attribute context { string-join($contexts, ' ') } else () }
                <uri>{ $website }/catalog/{ $orgname/@key/data() }</uri>
                <label>{ normalize-space(string-join($orgname//text(), '')) }</label>
            </org>
        else
            ()
    ,
    (: People mentioned but who are not authors :)
    for $otherperson in $msorpartoritem//tei:persName[not(ancestor::tei:author) and not(@role = 'author')][@key]
        let $contexts := (for $ancest in $otherperson/ancestor::* return if (name($ancest) = ('title','author','origin','provenance','acquisition','physDesc','bibl')) then lower-case(name($ancest)) else ())
        return if ($otherperson/ancestor::*[@xml:id][1]/@xml:id = $msorpartoritem/@xml:id) then
            <person>
                { if ($otherperson/@role) then attribute role { $otherperson/@role/data() } else () }
                { if (count($contexts) gt 0) then attribute context { string-join($contexts, ' ') } else () }
                <uri>{ $website }/catalog/{ $otherperson/@key/data() }</uri>
                <label>{ normalize-space(string-join($otherperson//text(), '')) }</label>
            </person>
        else
            ()
    )
};

processing-instruction xml-model {'href="simplified4oxlod.xsd" type="application/xml" schamtypens="http://www.w3.org/2001/XMLSchema"'},
<manuscripts>
    {
    for $manuscript at $pos in collection('../../collections/?select=*.xml;recurse=yes')/tei:TEI
    
        return if ($pos mod 200 = 0) then   (: This creates a pseudo-random sample, change to return if (true()) then to get everything :)
        
            <manuscript>
            
                <uri>{ $website }/catalog/{ $manuscript/@xml:id/data() }</uri>
                <classmark>{ $manuscript/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[1]/text() }</classmark>
                <collection>{ $manuscript/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type="collection"]/text() }</collection>
                <repository>{ $manuscript/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:repository/text() }</repository>
                <institution>{ $manuscript/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:institution/text() }</institution>
                
                {
                (: All manuscripts have at least one msContents element, but in multi-part manuscripts each is a child of an msPart :)
                for $mscontent in $manuscript//tei:msContents
                    return
                    if ($mscontent/parent::tei:msPart) then
                        <part>
                            <uri>{ $website }/catalog/{ $manuscript/@xml:id/data() }#{ $mscontent/parent::tei:msPart/@xml:id/data() }</uri>
                            <label>{ $mscontent/parent::tei:msPart/tei:msIdentifier[1]/tei:altIdentifier[1]/tei:idno[1]/text() }</label>
                            { local:extractPhysicalFields($mscontent/parent::tei:msPart/tei:physDesc) }
                            { local:extractDates($mscontent/parent::tei:msPart/tei:history) }
                            { local:listPeoplePlacesEtc($mscontent/parent::tei:msPart) }
                            { local:listItems($manuscript, $mscontent) }
                        </part>
                    else if ($mscontent/parent::tei:msDesc) then
                        (: This manuscript does not have parts (or, occassionally, there is some kind of preamble before the parts, or the parts are endleaves) :)
                        (
                        local:extractPhysicalFields($mscontent/parent::tei:msDesc/tei:physDesc),
                        local:extractDates($mscontent/parent::tei:msDesc/tei:history),
                        local:listPeoplePlacesEtc($mscontent/parent::tei:msDesc),
                        local:listItems($manuscript, $mscontent)
                        )
                    else
                        local:logging('error', 'Unrecognized file structure', base-uri($manuscript))
                }

            </manuscript>
        else
            ()
    }
</manuscripts>


