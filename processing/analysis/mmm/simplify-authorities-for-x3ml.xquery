declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

declare variable $authorityfile as xs:string external;
declare variable $chunk as xs:integer external;
declare variable $numchunks as xs:integer external;

declare function local:logging($level as xs:string, $msg as xs:string, $values)
{
    (: Trick XQuery into doing trace() to output message to STDERR but not insert it into the XML :)
    substring(trace('', concat(upper-case($level), '	', $msg, '	', string-join($values, '	'), '	')), 0, 0)
};

declare function local:dateConversion($datestring as xs:string, $begin as xs:boolean)
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
        (local:logging('error', 'Unreadable date format', $datestring), ())[2]
};

declare function local:extractDates($elem as element()) as element()*
{
    (: Convert dates into to/from child elements needed for mapping to CIDOC-CRM :)
    let $begindates := (
        for $date in $elem/(@when|@notBefore|@from)/data()
            return
            local:dateConversion(normalize-space($date), true())
    )
    let $enddates := (
        for $date in $elem/(@when|@notAfter|@to)/data()
            return
            local:dateConversion(normalize-space($date), false())
    )
    return
    if (count($begindates) gt 0 and count($enddates) gt 0) then
        (
        <from>{ min($begindates) }</from>,
        <to>{ max($enddates) }</to>
        )
    else if (count($begindates) gt 0) then
        <from>{ min($begindates) }</from>
    else if (count($enddates) gt 0) then
        <to>{ max($enddates) }</to>
    else
        ()
};

declare function local:links($elem as element()) as element()*
{
let $links := $elem/tei:note[@type='links']//tei:ref[starts-with(@target, 'http')]
return
if (count($links) gt 0) then
    <note type="links">
        <list>
            {
            for $l in $links
                return
                <item>
                    <ref target="{ $l/@target }">{ normalize-space($l/string()) }</ref>
                </item>
            }
        </list>
    </note>
else ()
};

declare function local:otherNotes($elem as element()) as element()*
{
let $notes := ($elem/tei:note[not(@type='links')], $elem/ancestor::tei:*[starts-with(local-name(), 'list')]/tei:head/tei:note)
for $n in $notes
    return
    element { 'note' } { $n/@*, normalize-space($n/string()) }
};

declare variable $authorityentries as element()* := (
    for $e at $pos in doc($authorityfile)//(tei:bibl|tei:person|tei:place|tei:org)[@xml:id and not(ancestor::tei:bibl or ancestor::tei:person or ancestor::tei:place or ancestor::tei:org)]
        return
        if ($pos mod $numchunks = $chunk) then $e else ()
    );

<TEI>
    <text>
        <body>
            {
            (
            if (count($authorityentries[self::tei:bibl]) gt 0) then
                <listBibl>
                    {
                    for $e in $authorityentries[self::tei:bibl]
                        return
                        <bibl xml:id="{ $e/@xml:id }">
                            <title type="uniform">{ normalize-space($e/tei:title[@type='uniform'][1]/string()) }</title>
                            {
                            let $variants as xs:string* := for $t in $e/tei:title[not(@type='uniform')] return normalize-space($t/string())
                            for $v in distinct-values($variants)[string-length(.) gt 0]
                                return
                                <title type="variant">{ $v }</title>
                            }
                            {
                            for $n in $e/(tei:author|tei:textLang)
                                return
                                element { local-name($n) } { $n/@*, normalize-space($n/string()) }
                            }
                            {
                            local:links($e)
                            }
                            {
                            local:otherNotes($e)
                            }
                        </bibl>
                    }
                </listBibl>
            else (),
            if (count($authorityentries[self::tei:person]) gt 0) then
                <listPerson>
                    {
                    for $e in $authorityentries[self::tei:person]
                        return
                        <person xml:id="{ $e/@xml:id }">
                            <persName type="display">{ normalize-space($e/tei:persName[@type='display'][1]/string()) }</persName>
                            {
                            let $variants as xs:string* := for $p in $e/tei:persName[not(@type='display')] return normalize-space($p/string())
                            for $v in distinct-values($variants)[string-length(.) gt 0]
                                return
                                <persName type="variant">{ $v }</persName>
                            }
                            {
                            for $d in $e/(tei:birth|tei:death)
                                return
                                element { local-name($d) } { 
                                    local:extractDates($d)
                                }
                            }
                            {
                            local:links($e)
                            }
                            {
                            local:otherNotes($e)
                            }
                        </person>
                    }
                </listPerson>
            else (),
            if (count($authorityentries[self::tei:place]) gt 0) then
                <listPlace>
                    {
                    for $e in $authorityentries[self::tei:place]
                        return
                        <place xml:id="{ $e/@xml:id }">
                            <placeName type="index">{ normalize-space($e/tei:placeName[@type='index'][1]/string()) }</placeName>
                            {
                            let $variants as xs:string* := for $p in $e/tei:placeName[not(@type='index')] return normalize-space($p/string())
                            for $v in distinct-values($variants)[string-length(.) gt 0]
                                return
                                <placeName type="variant">{ $v }</placeName>
                            }
                            {
                            for $n in $e/(tei:country|tei:location)
                                return
                                element { local-name($n) } { $n/@*, normalize-space($n/string()) }
                            }
                            {
                            if ($e/tei:location/tei:geo) then
                                <location>
                                    <geo>{ normalize-space($e/tei:location/tei:geo[1]/string()) }</geo>
                                </location>
                            else ()
                            }
                            {
                            local:links($e)
                            }
                            {
                            local:otherNotes($e)
                            }
                        </place>
                    }
                </listPlace>
            else (),
            if (count($authorityentries[self::tei:org]) gt 0) then
                <listOrg>
                    {
                    for $e in $authorityentries[self::tei:org]
                        return
                        <org xml:id="{ $e/@xml:id }">
                            <orgName type="display">{ normalize-space($e/tei:orgName[@type='display'][1]/string()) }</orgName>
                            {
                            let $variants as xs:string* := for $o in $e/tei:orgName[not(@type='display')] return normalize-space($o/string())
                            for $v in distinct-values($variants)[string-length(.) gt 0]
                                return
                                <orgName type="variant">{ $v }</orgName>
                            }
                            {
                            for $n in $e/tei:country
                                return
                                element { local-name($n) } { $n/@*, normalize-space($n/string()) }
                            }
                            {
                            if ($e/tei:location/tei:geo) then
                                <location>
                                    <geo>{ normalize-space($e/tei:location/tei:geo[1]/string()) }</geo>
                                </location>
                            else ()
                            }
                            {
                            local:links($e)
                            }
                            {
                            local:otherNotes($e)
                            }
                        </org>
                    }
                </listOrg>
            else ()
            )
            }
        </body>
    </text>
</TEI>
