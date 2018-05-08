declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

declare function local:logging($level as xs:string, $msg as xs:string, $values)
{
    (: Trick XQuery into doing trace() to output message to STDERR but not insert it into the XML :)
    substring(trace('', concat(upper-case($level), '	', $msg, '	', string-join($values, '	'), '	')), 0, 0)
};

declare function local:languageCodeLookup($lang as xs:string) as xs:string*
{
    (: TODO: Get these from a lookup file :)
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
    default return (local:logging('error', 'Unrecognized language code', $lang), ())[2]
};

declare function local:dateConversion($datestring as xs:string, $begin as xs:boolean) as xs:dateTime*
{
    let $year := if (string-length($datestring) eq 0) then '' else if (matches($datestring, '^\d\d\d\d$')) then $datestring else if (matches($datestring, '^\d\d\d$')) then concat('0', $datestring) else if (matches($datestring, '^\d\d\d\d')) then substring($datestring, 1, 4) else if (matches($datestring, '^\d\d\d')) then concat('0', substring($datestring, 1, 3)) else ''
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

processing-instruction xml-model {'href="simplified4oxlod.xsd" type="application/xml" schamtypens="http://www.w3.org/2001/XMLSchema"'},
<manuscripts>
    {
    let $collection := collection('../../collections/?select=*.xml;recurse=yes')
    let $works := doc('../../works.xml')
    let $people := doc('../../persons.xml')
    let $places := doc('../../places.xml')
    let $website := 'https://medieval.bodleian.ox.ac.uk'
    for $manuscript at $pos in $collection/tei:TEI
    
        return if (true()) then   (: This creates a pseudo-random sample, change to return if (true()) then to get everything :)
        
            <manuscript>
            
                <uri>{ $website }/catalog/{ $manuscript/@xml:id/data() }</uri>
                <classmark>{ $manuscript/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno[1]/text() }</classmark>
                <collection>{ $manuscript//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type="collection"]/text() }</collection>
                <repository>{ $manuscript//tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:repository/text() }</repository>
                <institution>{ $manuscript//tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:institution/text() }</institution>
                
                {
                (: Simplify origin dates to a single range. This is best for Fihrist, whose dates are a mess, 
                   but means losing some detail (e.g. text written in one century, illustrations in the next.) :)
                let $begindates := (
                    for $date in $manuscript//tei:origDate/(@when|@notBefore|@from)/data()
                        return
                        local:dateConversion(normalize-space($date), true())
                )
                let $enddates := (
                    for $date in $manuscript//tei:origDate/(@when|@notAfter|@to)/data()
                        return
                        local:dateConversion(normalize-space($date), false())
                )
                return if (count($begindates) gt 0 and count($enddates) gt 0) then
                    <date>
                        <from>{ min($begindates) }</from>
                        <to>{ max($enddates) }</to>
                    </date>
                else if (count($begindates) gt 0) then
                    <date>
                        <from>{ min($begindates) }</from>
                    </date>
                else if (count($enddates) gt 0) then
                    <date>
                        <to>{ max($enddates) }</to>
                    </date>
                else
                    ()
                }
                               
                {
                for $msItem in $manuscript//tei:msItem[tei:title/@key]
                    (: This flattens all works (msItem) in a manuscript into one list. In the TEI, there can be a hierarchy of works-within-works :)
                    let $work := $works//tei:bibl[@xml:id = $msItem/tei:title/@key]
                    return
                    if ($work) then
                        let $workid := $msItem/@xml:id/data()
                        return
                        <item>
                            <uri>{ $website }/catalog/{ $manuscript/@xml:id/data() }#{ $workid }</uri>
                            <title>
                                <uri>{ $website }/catalog/{ $work/@xml:id/data() }</uri>
                                <main>{ $work/tei:title[@type = 'uniform']/text() }</main>
                                {
                                for $variant in $work/tei:title[@type = 'variant']
                                    return
                                    <alt>{ $variant/text() }</alt>
                                }
                            </title>
                            
                            {
                            for $author in ($msItem/tei:author|$msItem/*/tei:persName[@role='author'])
                                let $person := $people//tei:person[@xml:id = $author/@key]
                                let $extrefs := $person/tei:note[@type='links']//tei:ref/@target/data()
                                return if ($person) then
                                    <author>
                                        <uri>{ $website }/catalog/{ $author/@key/data() }</uri>
                                        {
                                        for $extref in $extrefs
                                            order by boolean(contains($extref, 'viaf.org/')) descending
                                            return if (contains($extref, 'viaf.org/')) then
                                                <viaf>{ $extref }</viaf>
                                            else
                                                <extref>{ $extref }</extref>
                                        }
                                        <main>{ normalize-space(string-join($person/tei:persName[@type = 'display']//text(), '')) }</main>
                                        {
                                        for $variant in distinct-values($person/tei:persName[@type = 'variant']/string-join(.//text(), ''))
                                            return
                                            <alt>{ normalize-space($variant) }</alt>
                                        }
                                        {
                                        if ($person/floruit[@notBefore or @notAfter]) then
                                            <dates>{ $person/tei:floruit/@notBefore/data() }–{ $person/tei:floruit/@notAfter/data() }</dates>
                                        else if ($person/tei:birth/@when or $person/tei:death/@when) then
                                            <dates>{ $person/tei:birth/@when/data() }–{ $person/tei:death/@when/data() }</dates>
                                        else
                                            ()
                                        }
                                    </author>
                                else
                                    ()
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
                        </item>
                    else
                        ()
                }
                
                {
                (: More manuscript-level information :)
                
                (: Places :)
                for $placename in $manuscript//(tei:placeName)
                    let $place := $places//tei:place[@xml:id = $placename/@key]
                    let $contexts := (for $ancest in $placename/ancestor::* return if (name($ancest) = ('title','author','origin','provenance', 'acquisition')) then name($ancest) else ())
                    let $extrefs := $place/tei:note[@type='links']//tei:ref/@target/data()
                    return if ($place) then
                        <place>
                            {
                            if ($placename/@role) then attribute role { $placename/@role/data() } else ()
                            }
                            {
                            if (count($contexts) gt 0) then attribute context { string-join($contexts, ' ') } else ()
                            }
                            <uri>{ $website }/catalog/{ $placename/@key/data() }</uri>
                            {
                            for $extref in $extrefs
                                return
                                <extref>{ $extref }</extref>
                            }
                            <main>{ normalize-space(string-join($place/tei:placeName[@type = 'index']//text(), '')) }</main>
                            {
                            for $variant in distinct-values($place/tei:placeName[@type = 'variant']/string-join(.//text(), ''))
                                return
                                <alt>{ normalize-space($variant) }</alt>
                            } 
                        </place>
                    else
                        ()
                }
                
                {
                (: Organizations :)
                for $orgname in $manuscript//(tei:orgName)
                    let $org := $places//tei:org[@xml:id = $orgname/@key]
                    let $contexts := (for $ancest in $orgname/ancestor::* return if (name($ancest) = ('title','author','origin','provenance', 'acquisition')) then name($ancest) else ())
                    let $extrefs := $org/tei:note[@type='links']//tei:ref/@target/data()
                    return if ($org) then
                        <org>
                            {
                            if ($orgname/@role) then attribute role { $orgname/@role/data() } else ()
                            }
                            {
                            if (count($contexts) gt 0) then attribute context { string-join($contexts, ' ') } else ()
                            }
                            <uri>{ $website }/catalog/{ $orgname/@key/data() }</uri>
                            {
                            for $extref in $extrefs
                                order by boolean(contains($extref, 'viaf.org/')) descending
                                return if (contains($extref, 'viaf.org/')) then
                                    <viaf>{ $extref }</viaf>
                                else
                                    <extref>{ $extref }</extref>
                            }
                            <main>{ normalize-space(string-join($org/tei:orgName[@type = 'display']//text(), '')) }</main>
                            {
                            for $variant in distinct-values($org/tei:orgName[@type = 'variant']/string-join(.//text(), ''))
                                return
                                <alt>{ normalize-space($variant) }</alt>
                            }   
                        </org>
                    else
                        ()
                }
                
                {
                (: People mentioned but who are not authors :)
                for $otherperson in $manuscript//tei:persName[not(ancestor::tei:author) and not(@role = 'author')]
                    let $person := $people//tei:person[@xml:id = $otherperson/@key]
                    let $contexts := (for $ancest in $otherperson/ancestor::* return if (name($ancest) = ('title','bibl','origin','provenance', 'acquisition')) then name($ancest) else ())
                    let $extrefs := $person/tei:note[@type='links']//tei:ref/@target/data()
                    return if ($otherperson/@key = ($manuscript//tei:author//@key)) then
                        (: This person is also an author in the same TEI document:)
                        ()
                    else if ($person) then
                        <person>
                            {
                            if ($otherperson/@role) then attribute role { $otherperson/@role/data() } else ()
                            }
                            {
                            if (count($contexts) gt 0) then attribute context { string-join($contexts, ' ') } else ()
                            }
                            <uri>{ $website }/catalog/{ $otherperson/@key/data() }</uri>
                            {
                            for $extref in $extrefs
                                order by boolean(contains($extref, 'viaf.org/')) descending
                                return if (contains($extref, 'viaf.org/')) then
                                    <viaf>{ $extref }</viaf>
                                else
                                    <extref>{ $extref }</extref>
                            }
                            <main>{ normalize-space(string-join($person/tei:persName[@type = 'display']//text(), '')) }</main>
                            {
                            for $variant in distinct-values($person/tei:persName[@type = 'variant']/string-join(.//text(), ''))
                                return
                                <alt>{ normalize-space($variant) }</alt>
                            }
                            {
                            if ($person/floruit[@notBefore or @notAfter]) then
                                <dates>{ $person/tei:floruit/@notBefore/data() }–{ $person/tei:floruit/@notAfter/data() }</dates>
                            else if ($person/tei:birth/@when or $person/tei:death/@when) then
                                <dates>{ $person/tei:birth/@when/data() }–{ $person/tei:death/@when/data() }</dates>
                            else
                                ()
                            }
                        </person>
                    else
                        ()
                }

            </manuscript>
        else
            ()
    }
</manuscripts>


