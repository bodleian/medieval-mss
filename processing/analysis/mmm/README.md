This folder contains:

 * XQuery scripts for extracting information in the TEI files in this repository (both manuscript records and authority files) into an intermediate form.
 * The mapping and generator files need by the [x3ml](https://github.com/delving/x3ml) tool to create RDF, using the CIDOC-CRM and FRBRoo ontologies, from that intermediate form.

Instructions for how to use these will be added here soon.

The information extracted, and the mappings to ontologies, are tailored to the needs of the [Mapping Manuscript Migrations](http://mappingmanuscriptmigrations.org/) project. The scripts will not work, without modification, on any TEI manuscript descriptions, even using [the same schema](https://github.com/bodleian/consolidated-tei-schema). Nor will the mappings produce RDF that covers any information anyone might be interested in. But they might be of interest to others building their own mappings.
