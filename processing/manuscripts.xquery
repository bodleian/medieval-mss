import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

declare function local:origin($doc, $solrfield)
{
    (: Lookup place keys, which are specific to medieval-mss :)
    (: TODO: Replace this with lookup to places.xml authority file? :)
    for $origin in distinct-values($doc/string(@key))
        let $place := 
        switch($origin)
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
            default return normalize-space($origin)
        return <field name="{ $solrfield }">{ $place }</field>
};

<add>
{
    for $x in collection('../collections/?select=*.xml;recurse=yes')
        let $msid := $x//tei:TEI/@xml:id/data()
        let $subfolders := string-join(tokenize(substring-after(base-uri($x), 'collections/'), '/')[position() lt last()], '/')
        let $htmlfilename := concat($x//tei:sourceDesc/tei:msDesc[1]/@xml:id/data(), '.html')
        let $htmldoc := doc(concat("html/", $subfolders, '/', $htmlfilename))
        
        (:
        The following three date fields have been removed from the doc output below
        Reinstate them if advanced search on precise dates is developed
        bod:dateEarliest($x//tei:msPart/tei:history/tei:origin/tei:origDate, 'ms_date_earliest_i')
        bod:dateLatest($x//tei:msPart/tei:history/tei:origin/tei:origDate, 'ms_date_latest_i')
        <field name="ms_date_stmt_s"> $x//tei:history/tei:origin/tei:origDate/text() </field>
        :)
        
        (:
            Guide to Solr field naming conventions:
                ms_ = manuscript index field
                _i = integer field
                _b = boolean field
                _s = string field (tokenized)
                _t = text field (not tokenized)
                _?m = multiple field (typically facets)
                *ni = not indexed (except _tni fields which are copied to the fulltext index)
        :)
    
        return <doc>
            <field name="type">manuscript</field>
            <field name="pk">{ $msid }</field>
            <field name="id">{ $msid }</field>
            { bod:one2one($x//tei:msDesc/tei:msIdentifier/tei:idno[@type="shelfmark"], 'title', 'error') }
            { bod:one2one($x//tei:titleStmt/tei:title[@type="collection"], 'ms_collection_s') }
            { bod:one2one($x//tei:msDesc/tei:msIdentifier/tei:settlement, 'ms_settlement_s') }
            { bod:one2one($x//tei:msDesc/tei:msIdentifier/tei:institution, 'ms_institution_s') }
            { bod:many2one($x//tei:msDesc/tei:msIdentifier/tei:repository, 'ms_repository_s') }
            { bod:one2one($x//tei:msDesc/tei:msIdentifier/tei:idno[@type="shelfmark"], 'ms_shelfmark_s') }
            { bod:one2one($x//tei:msDesc/tei:msIdentifier/tei:idno[@type="shelfmark"], 'ms_shelfmark_sort') }
            { bod:many2one($x//tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:altIdentifier[@type="internal"]/tei:idno, 'ms_altid_s') }
            <field name="filename_sni">{ base-uri($x) }</field>
            { bod:many2many($x//tei:msContents/tei:msItem/tei:title, 'ms_works_sm') }
            { bod:many2many($x//tei:msContents/tei:msItem/tei:author/tei:persName, 'ms_authors_sm') }
            { bod:materials($x//tei:msDesc//tei:physDesc//tei:supportDesc[@material], 'ms_materials_sm') }
            { bod:many2many($x//tei:sourceDesc//tei:name[@type="corporate"]/tei:persName, 'ms_corpnames_sm') }
            { bod:many2many($x//tei:sourceDesc//tei:persName, 'ms_persnames_sm') }
            { bod:trueIfExists($x//tei:sourceDesc//tei:decoDesc/tei:decoNote, 'ms_deconote_b') }
            { bod:languages($x//tei:sourceDesc//tei:textLang, 'ms_lang_sm') }
            { local:origin($x//tei:sourceDesc//tei:origPlace/tei:country, 'ms_origin_sm') }
            { bod:centuries($x//tei:origin//tei:origDate, 'ms_date_sm') }
            { bod:many2one($x//tei:incipit, 'ms_textcontent_smni') }
            { bod:many2one($x//tei:explicit, 'ms_textcontent_smni') }
            { bod:many2one($x//tei:note, 'ms_textcontent_smni') }
            { bod:many2one($x//tei:decoNote, 'ms_textcontent_smni') }
            { bod:many2one($x//tei:additions, 'ms_textcontent_smni') }
            { bod:many2one($x//tei:provenance, 'ms_textcontent_smni') }
            { bod:indexHTML($htmldoc, 'ms_textcontent_tni') }
            { bod:displayHTML($htmldoc, 'display') }
        </doc>
}
</add>


