declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

declare variable $persondoc := doc('../../persons.xml');
declare variable $placedoc := doc('../../places.xml');
declare variable $workdoc := doc('../../works.xml');

<html>
    <body>
        <h1>Links to external authorities in medieval-mss local authority files</h1>
        
        <h2>People</h2>
        <table border="1">
            <tr><th>Authority</th><th>Count</th></tr>
            {
            let $personauthories := (
                for $ref in $persondoc/tei:TEI/tei:text/tei:body/tei:listPerson/tei:person/tei:note[@type='links']//tei:ref
                    let $authority := normalize-space(concat(string-join($ref/tei:title//text(), ''), ' (', tokenize($ref/@target, '/')[3], ')'))
                    group by $authority
                    return
                    <tr>
                        <td>{ $authority }</td>
                        <td>{ count(distinct-values($ref/ancestor::tei:person/@xml:id)) }</td>
                    </tr>
                ,
                <tr>
                    <td>No links to any external authority</td>
                    <td>{ count($persondoc/tei:TEI/tei:text/tei:body/tei:listPerson/tei:person[not(tei:note[@type='links']//tei:ref)]) }</td>
                </tr>
                )
            for $a in $personauthories
                order by xs:integer($a/td[2]) descending
                return $a
            }
        </table>
        
        <h2>Places</h2>
        <table border="1">
            <tr><th>Authority</th><th>Count</th></tr>
            {
            let $placeauthories := (
                for $ref in $placedoc/tei:TEI/tei:text/tei:body/tei:listPlace/tei:place/tei:note[@type='links']//tei:ref
                    let $authority := normalize-space(concat(string-join($ref/tei:title//text(), ''), ' (', tokenize($ref/@target, '/')[3], ')'))
                    group by $authority
                    return
                    <tr>
                        <td>{ $authority }</td>
                        <td>{ count(distinct-values($ref/ancestor::tei:place/@xml:id)) }</td>
                    </tr>
                ,
                <tr>
                    <td>Based on Getty but no link</td>
                    <td>{ count($placedoc/tei:TEI/tei:text/tei:body/tei:listPlace/tei:place[not(tei:note[@type='links']//tei:ref) and tei:note[@type='source' and tei:ref[contains(@target, 'getty.edu')]]]) }</td>
                </tr>
                ,
                <tr>
                    <td>No links to any external authority and not based on Getty</td>
                    <td>{ count($placedoc/tei:TEI/tei:text/tei:body/tei:listPlace/tei:place[not(tei:note[@type='links']//tei:ref) and not(tei:note[@type='source' and tei:ref[contains(@target, 'getty.edu')]])]) }</td>
                </tr>
                )
            for $a in $placeauthories
                order by xs:integer($a/td[2]) descending
                return $a
            }
        </table>
        
        <h2>Organizations</h2>
        <table border="1">
            <tr><th>Authority</th><th>Count</th></tr>
            {
            let $orgauthories := (
                for $ref in $placedoc/tei:TEI/tei:text/tei:body/tei:listOrg/tei:org/tei:note[@type='links']//tei:ref
                    let $authority := normalize-space(concat(string-join($ref/tei:title//text(), ''), ' (', tokenize($ref/@target, '/')[3], ')'))
                    group by $authority
                    return
                    <tr>
                        <td>{ $authority }</td>
                        <td>{ count(distinct-values($ref/ancestor::tei:org/@xml:id)) }</td>
                    </tr>
                ,
                <tr>
                    <td>No links to any external authority</td>
                    <td>{ count($placedoc/tei:TEI/tei:text/tei:body/tei:listOrg/tei:org[not(tei:note[@type='links']//tei:ref)]) }</td>
                </tr>
                )
            for $a in $orgauthories
                order by xs:integer($a/td[2]) descending
                return $a
            }
        </table>
        
        <h2>Works</h2>
        <table border="1">
            <tr><th>Authority</th><th>Count</th></tr>
            {
            let $workauthories := (
                for $ref in $workdoc//tei:bibl/tei:note[@type='links']//tei:ref
                    let $authority := normalize-space(concat(string-join($ref/tei:title//text(), ''), ' (', tokenize($ref/@target, '/')[3], ')'))
                    group by $authority
                    return
                    <tr>
                        <td>{ $authority }</td>
                        <td>{ count(distinct-values($ref/ancestor::tei:bibl/@xml:id)) }</td>
                    </tr>
                ,
                <tr>
                    <td>No links to any external authority</td>
                    <td>{ count($workdoc/tei:TEI/tei:text/tei:body/tei:listBibl/tei:bibl[not(tei:note[@type='links']//tei:ref)]) }</td>
                </tr>
                )
            for $a in $workauthories
                order by xs:integer($a/td[2]) descending
                return $a
            }
        </table>
        
    </body>
</html>