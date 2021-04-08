xquery version "3.0" encoding "utf-8";
declare namespace saxon = "http://saxon.sf.net/";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option output:method "text";

declare variable $tab as xs:string := '&#9;';
declare variable $newline as xs:string := '&#10;';

<dummy>
{
    let $bibls := 
        for $bibl in collection("../../collections/?select=*.xml;recurse=yes")//tei:bibl[@facs]
            let $facs as xs:string := normalize-space($bibl/@facs/string())
            let $type as xs:string := normalize-space($bibl/@type/string())
            let $ref as xs:string := normalize-space($bibl/string())
            let $file as xs:string := substring-after(base-uri($bibl), '/collections/')
            return
            <bibl facs="{ $facs }" type="{ $type }" file="{ $file }">{ $ref }</bibl>
     return
     for $fac in distinct-values($bibls/@facs/string())
         let $types as xs:string* := distinct-values($bibls[@facs = $fac]/@type/string())
         let $refs as xs:string* := distinct-values($bibls[@facs = $fac][1]/string())
         let $files as xs:string* := distinct-values($bibls[@facs = $fac]/@file/string())
         let $sortedfiles as xs:string* := for $f in $files order by xs:integer(replace($f, '\D', '')) return $f
         order by $sortedfiles[1], $refs[1]
         return
         string-join(
             (
                 $fac, 
                 string-join($types, ', '), 
                 string-join($refs, ' | '),
                 string-join($sortedfiles, ', '), 
                 $newline
             ), 
         $tab)
}
</dummy>
