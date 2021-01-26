# nypr-archives-ingest-scripts
Stylesheets for importing instantiations into the NYPR Archives

2021-01-25 Commit:

Simplified masterRouter, added more flexibility, added unstructured exiftool error
Fixed instantiationID2Exif bugs - orders instantiation IDs, better filename generation (better segment suffix handling), better date handling
Better parseDAVIDTitle  error handling, new parseInstantiationID template
better selectionOrExcerpt
Bug fixes

Issues:
Error log counts off
Simplify masterRouter further

Oct 2020 update:

1. "SeriesQC" takes a series name and performs quality control on cavafy entries
2. LoC entries accept new 'https' entries
2. New/improved connections among exiftool, cavafy, BWF MetaEdit and DAVID schemas
3. Better handling of segment files within an asset
4. Better CV control of physical items via cavafyFormats.xml
5. Bug fixes
