# INGESTING PHYSICAL ITEMS

Ingesting physical items (tapes, discs, prints, etc.) benefits from creating a spreadsheet inventory. Archives staff can provide a special spreadsheet, which is mapped to an rdf-like schema. 

Once you determine which items you want to keep, the cataloging process is iterative and follows the following steps:

1. Segregate by format
2. Organise by collection and series, then by date
3. Identify related assets in cavafy
4. Group related uncataloged items
5. Enter descriptive metadata
6. Ingest into catalog

## 1. Segregate by format

Use ample space and segregate your materials by format

## 2. Organise items

1. Segregate by collection
2. Segregate by series
3. Place in date order, when possible (unknown dates at end)

## 3. Identify related assets in cavafy

The Archives catalog (colloquially known as &quot;[cavafy](https://cavafy.wnyc.org/)&quot;) uses the [pbcore](https://pbcore.org/) standard, which differentiates between conceptual &quot;assets&quot; and their associated &quot;instantiations&quot; (recordings). Look in the archives catalog for related assets; you can use dates (in the YYYY-MM-DD format), series or keywords.

If you find a related asset in cavafy, apply a label with an instantiation ID. The ID must follow this pattern: assetID.instSuffix

The instantiation suffix will be the next integer after the current instantiations listed in cavafy. E.g., if the highest instantation ID in cavafy is 12345.2, the instantiation suffix will be 3, so the complete instantiation ID will be 12345.3.

Add an additional segment suffix (a, b, c...) for partial instantiations designed to play sequentially (for example, first hour of a two-hour show).

    Examples of instantiation IDs
    12345.3
    45678.7a

See [instantiation IDs](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/blob/master/additionalDocs/fileNaming.md#instantiation-id) for more information.

Set aside the items that have labels, in asset number order. 

Now you are ready to enter information in the archives spreadsheet. This is much faster nd accurate than entering individual items in the catalogue.

Create a copy of the archives template spreadsheet for each format group and collection group. For example: WQXR DATs can go in one spreadsheet. 

Enter each asset and instantiation suffix in the archives spreadsheet.

## 4. Group related uncataloged items

Labeled items with the same asset number will clearly belong together. Do the same with unlabeled items that appear to "belong" together: use rubber bands, temporary labels, etc. to accomplish this.

Determine how many new assets you will need to create. Archives staff will then provide you with a spreadsheet that includes the existing asset IDs you identified in [Step 3](#3-identify-related-assets-in-cavafy), as well as new asset IDs. Label the physical items with the new instantiation IDs.

## 5. Enter descriptive metadata

Enter as much descriptive metadata in the spreadsheet as you can.

## 6. Ingest into catalog

The spreadsheet can export an rdf-like xml which can then be processed via the [Archives ingest protocol](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/blob/master/additionalDocs/ArchivesWorkflow.md). This will be ingested into cavafy.

