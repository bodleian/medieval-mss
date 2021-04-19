declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";
declare option saxon:output "encoding=utf-8";

declare variable $collection := collection('../../collections?select=*.xml;recurse=yes');
declare variable $websitecatalog := 'https://medieval.bodleian.ox.ac.uk/catalog/';

<html>
    <body>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
        </head>
        <h1>Differences between works.xml and the msItems in the manuscript descriptions</h1>
        <table border="1">
            <tr>
                <th>Work</th>
                <th>Authors only in works.xml</th>
                <th>Languages only in works.xml</th>
                <th>Authors only in manuscript descriptions</th>
                <th>Languages only in manuscript descriptions</th>
            </tr>
            {
            for $bibl in doc('../../works.xml')//tei:listBibl/tei:bibl
                let $workid := $bibl/@xml:id/data()
                let $worktitle := string-join($bibl/tei:title[@type = 'uniform']//text())
                let $msitems := $collection//tei:msItem[tei:title/@key/data() = $workid]
                let $authors1 := $bibl/tei:author[not(@role)]
                let $authors2 := $msitems/tei:author
                let $authorkeys1 := distinct-values($authors1/@key/data())
                let $authorkeys2 := distinct-values($authors2/@key/data())
                let $langs1 := distinct-values($bibl/tei:textLang/(@mainLang|@otherLangs)/tokenize(data(), ' '))
                let $langs2 := distinct-values($msitems/tei:textLang/(@mainLang|@otherLangs)/tokenize(data(), ' '))
                order by $worktitle
                return 
                if (
                    (some $a in $authorkeys1 satisfies not($a = $authorkeys2)) or 
                    (some $a in $authorkeys2 satisfies not($a = $authorkeys1)) or 
                    (some $l in $langs1 satisfies not($l = $langs2)) or 
                    (some $l in $langs2 satisfies not($l = $langs1))
                    ) then
                        <tr>
                            <td>
                            {
                            if (count($msitems) gt 0) then
                                <a href="{ $websitecatalog }{ $workid }">{ $worktitle }</a>
                            else
                                $worktitle
                            }
                            </td>
                            <td>{ for $a in $authorkeys1 return if (not($a = $authorkeys2)) then (<a href="{ $websitecatalog }{ $a }">{ distinct-values($authors1[@key/data() = $a]/text()) }</a>,<br/>) else () }</td>
                            <td>{ for $l in $langs1 return if (not($l = $langs2)) then ($l,<br/>) else () }</td>
                            {
                            if (count($msitems) eq 0) then
                                <td colspan="2" align="center">Work not found in manuscript descriptions</td>
                            else
                                <td>{ for $a in $authorkeys2 return if (not($a = $authorkeys1)) then (<a href="{ $websitecatalog }{ $a }">{ distinct-values($authors2[@key/data() = $a]/text()) }</a>,<br/>) else () }</td>
                            }
                            {
                            if (count($msitems) gt 0) then
                                <td>{ for $l in $langs2 return if (not($l = $langs1)) then ($l,<br/>) else () }</td>
                            else
                                ()
                            }
                        </tr>
                else
                    ()
            }
        </table>
    </body>
</html>