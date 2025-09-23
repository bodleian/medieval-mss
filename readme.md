## Medieval Manuscripts in Oxford Libraries

This repository contains the TEI data that represents the Bodleian Library's catalogue of manuscripts written from the Middle Ages, [Medieval Manuscripts in Oxford Libraries](https://medieval.bodleian.ox.ac.uk).

It also contains several scripts and tools for processing this data into a Solr instance for use with our
Blacklight search service.

For some additional information see the [Wiki](https://github.com/bodleian/medieval-mss/wiki).

For the TEI schema and guidelines, see the [msDesc repository](https://github.com/msDesc/).

For information on the collections themselves, see the [LibGuide](https://libguides.bodleian.ox.ac.uk/medieval-sc).

## Development

The Python scripts in this project use [uv](https://docs.astral.sh/uv/) for dependency management. To verify the XML files locally, run:

```bash
uv run python processing/validate.py
uv run python processing/check_entity_keys.py
```
