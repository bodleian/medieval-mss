declare namespace tei="http://www.tei-c.org/ns/1.0";

<add>
{
for $x in collection('/db/tei')
return <doc>
    <field name="type">manuscript</field>
    <field name="pk">{$x//tei:altIdentifier/tei:idno[@type="SCN"]/text()}</field>
    <field name="ms_title_s">{$x//tei:titleStmt/tei:title[not(@*)]/text()}</field>
    <field name="ms_collection_s">{$x//tei:titleStmt/tei:title[@type="collection"]/text()}</field>
</doc>
}
</add>