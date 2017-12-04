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

declare function local:orgRole($role)
{
    (:  Most of the roles just need to be capitalized. These are the exceptions. Copied from people.xquery because it's going in the same index field. TODO: Put this in a shared module :)
    switch($role)
        case "formerOwner" return "Owner or signer"
        case "signer" return "Owner or signer"
        case "commissioner" return "Commissioner, dedicatee, or patron"
        case "dedicatee" return "Commissioner, dedicatee, or patron"
        case "patron" return "Commissioner, dedicatee, or patron"
        default return functx:capitalize-first($role)
};

<add>
{
    let $doc := doc("../places.xml")
    let $collection := collection("../collections/?select=*.xml;recurse=yes")
    let $orgs := $doc//tei:org

    for $org in $orgs
        let $orgid := $org/string(@xml:id)
        let $orgname := fn:normalize-space($org/tei:orgName[@type="display"][1]/string())
        let $mss := $collection//tei:TEI[.//tei:orgName[@key = $orgid]]
        let $variants := $org/tei:orgName[@type="variant"]
        let $roles := fn:distinct-values($collection//tei:orgName[@key = $orgid]/@role/fn:tokenize(., ' '))
        let $notelinks := $org/tei:note[@type="links"]//tei:item

        (:
            Organizations are indexed as places so that we do not need another section to display them.
        :)
        return if (count($mss) > 0) then
        <doc>
            <field name="type">place</field>
            <field name="title">{ $orgname }</field>
            <field name="alpha_title">
                { functx:capitalize-first(substring(replace($orgname, '[^\p{L}|\p{N}]+', ''), 1, 1))}
            </field>
            <field name="id">{ $orgid }</field>
            <field name="pk">{ $orgid }</field>
            { for $variant in $variants
                let $vname := fn:normalize-space($variant/string())
                order by $vname
                return <field name="pl_variant_sm">{ $vname }</field>
            }
            { for $item in $notelinks
                let $refs := $item//tei:ref
                for $ref in $refs
                    let $linktarget := $ref/string(@target)
                    let $linktext := $ref/fn:normalize-space(tei:title/string())
                    order by $linktarget
                    return <field name="link_external_smni">{ concat($linktarget, "|", $linktext)}</field>
            }
            { 
              if (count($roles) > 0) then
                  for $role in $roles
                      order by $role
                      return <field name="pp_roles_sm">{ local:orgRole($role) }</field>
                      (: NOTE: Using same index field as for people so we don't create two "Roles" filters :)
              else
                  ()
            }
            { for $ms in $mss
                let $msid := $ms/string(@xml:id)
                let $url := concat("/catalog/", $msid[1])
                let $linktext := $ms//tei:idno[@type = "shelfmark"]/text()
                order by $msid
                return (
                    <field name="link_manuscripts_smni">{ concat($url, "|", $linktext[1]) }</field>,
                    <field name="pl_manuscripts_sm">{ $ms//tei:idno[@type = "shelfmark"]/data() }</field>)
            }
        </doc>
        else
            (
            local:logging('info', 'Skipping organization in places.xml but not in any manuscript', ($orgid, $orgname))
            )

}

{
    let $controlledorgids := doc("../places.xml")//tei:org/@xml:id/string()
    let $allorgs := collection("../collections?select=*.xml;recurse=yes")//tei:orgName
    let $allorgids := distinct-values($allorgs/@key/string())
    for $orgid in $allorgids
        return if (not($controlledorgids[. = $orgid])) then
            local:logging('warn', 'Organization in manuscripts not in places.xml: will create broken link', ($orgid, normalize-space(string-join($allorgs[@key = $orgid][1]/text(), ''))))
        else 
            ()
}

{
    let $allorgs := collection("../collections?select=*.xml;recurse=yes")//tei:sourceDesc//tei:orgName
    return if (count($allorgs[not(@key)]) > 0) then local:logging('info', concat(count($allorgs[not(@key)]), ' organizations found in manuscripts which lack @key attributes'), ()) else ()
}
</add>
