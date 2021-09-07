# Archives Organization #

NYPR Archival materials are organized into **Collections**, which represent either the material's original creator (WNYC, WQXR) or its current archival steward (NARA, MUNI). Collections are divided into **Series**, which often reflect the material's original show (Brian Lehrer Show, New Sounds). Series contain conceptual [pbcore] **Assets**, whose physical (1/4 inch audio tape, DAT) or digital (WAVE files) manifestations are called [pbcore] **Instantiations**.

The pbcore standard [defines](https://pbcore.org/glossary) asset as "A single piece of content, such as a program, clip, or episode. One asset may exist in many different forms (for example, on DVD, on a U-matic tape in English, and on a VHS tape in French). If the content is the same, those would all be considered instantiations of the same asset" and instantiation as "A manifestation of an asset that is embodied in physical or digital form, such as a tape, DVD, or digital file. One asset can have many instantiations, but generally, each instantiation holds the same intellectual content." 

The NYPR Archives' interpretation of what consitutes the *same* intellectual content has been historically inconsistent. Generally, the catalog adheres to the pbcore concepts above: thus, an original 1/4 inch tape of a show and a Beta PCM F-1 recording of its aircheck will be grouped under the same asset. But the catalog includes plenty of examples deviating in both directions: some complex assets include multitracks, safety copies, and several versions of mixes; while, on the other hand, two tapes with content from the first and second hour of a broadcast may be cataloged as different assets.

Regarding these inconsistencies, the Archives' efforts to improve data quality for reformatted materials focus on the latter --that is, on grouping together instantiations that should be under one asset. But we have yet to define a strict asset-instantiation relationship, and pbcore definitions are vague as to what constitutes "same intellectual content".

However, our [ingest scripts](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts) will flag inconsistencies between instantiaion-level and asset-level metadata. The following table summarizes the guidelines implied in the scripts:

asset metadata | Relationship | Instantiation MD | Embedded MD | Notes
-------------- | ------------ | ---------------- | ----------- | -----
pbcoreTitle [@titleType='Collection'] | MUST MATCH | | Archival Location (IARL) | Including country, e.g. "US, WNYC"
pbcoreContributor/@ref | MUST INCLUDE | | Artists (IART) | As URL, e.g. https://id.loc.gov/authorities/names/n50080187
pbcoreCreator/pbcorePublisher/@ref | MUST INCLUDE | | Commissioned by (ICMS) | As URL, e.g. https://id.loc.gov/authorities/names/n50080187
instantiationAnnotation[@annotationType='Embedded_Comments'] | MUST MATCH | | Comments (ICMT)
rightsSummary | MUST MATCH | | Copyright (ICOP)
pbcoreAssetDate | MUST INCLUDE | | Create Date (ICRD)
contributor[@contributorType='Engineer'] | MUST INCLUDE | | Engineer (IENG)



