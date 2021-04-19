declare namespace tei="http://www.tei-c.org/ns/1.0";

<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    {
        for $ms in collection('../collections/?select=*.xml;recurse=yes')
            let $msid := $ms//tei:TEI/@xml:id/data()
            return <url>
                <loc>{ concat("https://medieval.bodleian.ox.ac.uk/catalog/", $msid) }</loc>
            </url>
    }
</urlset>