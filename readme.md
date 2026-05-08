## Medieval Manuscripts in Oxford Libraries

This repository contains the TEI data that represents the Bodleian Library's catalogue of manuscripts written from the Middle Ages, [Medieval Manuscripts in Oxford Libraries](https://medieval.bodleian.ox.ac.uk).

It also contains several scripts and tools for processing this data into a Solr instance for use with our
Blacklight search service.

For some additional information see the [Wiki](https://github.com/bodleian/medieval-mss/wiki).

For the TEI schema and guidelines, see the [msDesc repository](https://github.com/msDesc/).

For information on the collections themselves, see the [LibGuide](https://libguides.bodleian.ox.ac.uk/medieval-sc).

## Development

The Python scripts in this project use [uv](https://docs.astral.sh/uv/) for dependency management.

### Local Validation

XML model validation uses the same Java validator as the GitHub Action:

```bash
sh processing/validate_xml.sh
```

```bash
sh processing/validate_xml.sh collections/e_Mus/MS_e_Mus_229.xml
```

In VS Code, the `Validate Current XML File` task validates the active editor file and surfaces matching diagnostics in the Problems panel.

To check entity key consistency locally, run:

```bash
uv run python processing/check_entity_keys.py -d collections
```

The shared authority tooling is intended to come from the public [`msDesc/tei-msdesc-authorities`](https://github.com/msDesc/tei-msdesc-authorities) repository via `uv`.

### Testing

To install development dependencies, including `pytest`, run:

```bash
uv sync --dev
```

To run the Python regression tests, use:

```bash
uv run pytest
```
