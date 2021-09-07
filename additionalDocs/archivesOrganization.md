# Archives Organization #

This document outlines how NYPR Archival materials are organized.

* NYPR materials are organized into **Collections**, which represent either the material's original creator (WNYC, WQXR) or its current archival steward (NARA, MUNI).
* Collections are divided into **Series**, which often reflect the material's original show (Brian Lehrer Show, New Sounds). 
* Series contain conceptual **Assets**, 
* whose physical (1/4 inch audio tape, DAT) or digital (WAVE files) manifestations are called **Instantiations**.

The pbcore standard [defines](https://pbcore.org/glossary) asset as "A single piece of content, such as a program, clip, or episode. One asset may exist in many different forms (for example, on DVD, on a U-matic tape in English, and on a VHS tape in French). If the content is the same, those would all be considered instantiations of the same asset" and instantiation as "A manifestation of an asset that is embodied in physical or digital form, such as a tape, DVD, or digital file. One asset can have many instantiations, but generally, each instantiation holds the same intellectual content." 

The NYPR Archives' interpretation of what consitutes the *same* intellectual content varies widely. Generally, the catalog adheres to the pbcore concepts above: thus, an original 1/4 inch tape of a show and a Beta PCM F-1 recording of its aircheck will be grouped under the same asset (even if the latter includes the top-of-the-hour news). But the catalog includes plenty of examples deviating in both directions: some complex assets include multitracks, safety copies, and several versions of mixes; while, on the other hand, two tapes with content from the first and second hour of a broadcast may be cataloged as different assets.

Regarding these inconsistencies, the Archives' efforts to improve data quality for reformatted materials focus on the latter --that is, on grouping together instantiations that should be under one asset. But we have yet to define a strict asset-instantiation relationship, and pbcore definitions are vague as to what constitutes "same intellectual content".

However, our [ingest scripts](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts) flag inconsistencies between instantiation-level (i.e., embedded) and asset-level metadata. The following table summarizes the rules followed by the scripts:

pbcore metadata | Relationship | Embedded MD | Notes
--------------- | ------------ | ----------- | -----
pbcoreTitle[@titleType='Collection'] | MUST MATCH | Archival Location (IARL) | Including country, e.g. "US, WNYC"
pbcoreContributor/@ref | MUST INCLUDE | Artists (IART) | As URL, e.g. https://id.loc.gov/authorities/names/n50080187
pbcoreCreator/pbcorePublisher/@ref | MUST INCLUDE | Commissioned by (ICMS) | As URL, e.g. https://id.loc.gov/authorities/names/n50080187
instantiationAnnotation[@annotationType='Embedded_Comments'] | MUST MATCH | Comments (ICMT)
rightsSummary | MUST MATCH | Copyright (ICOP)
pbcoreAssetDate | MUST INCLUDE | Create Date (ICRD)
pbcoreContributor[Role='Engineer']/contributor | MUST INCLUDE | Engineer (IENG)
pbcoreGenre | MUST MATCH | Genre (IGNR)
pbcoreSubject/@ref | MUST INCLUDE | Keywords (IKEY)
instantiationRelation[instantiationRelationType='Is Dub Of']/instantiationRelationIdentifier | MUST MATCH | Original Medium (IMED)
pbcoreTitle[@titleType='Episode'] | MUST MATCH | Title (INAM) | For full-length instantiations
instantiationAnnotation[@annotationType='Embedded Title'] | MUST MATCH | Title (INAM) | For partial instantiations
pbcoreTitle[@titleType='Series'] | MUST MATCH | Product (IPRD)
pbcoreDescription[@descriptionType='Abstract'] | MUST MATCH | Subject (ISBJ) | For full-length instantiations
instantiationAnnotation[@annotationType='Embedded Description'] | MUST MATCH | Subject (ISBJ) | For partial instantiations
 || not captured | Software (ISFT)
pbcoreIdentifier[@source='pbcore XML database UUID'] | MUST MATCH | Source (ISRC)
instantiationAnnotation[@annotationType='Provenance'] | MUST MATCH | Source reference (ISRF)
instantiationAnnotation[@annotationType='Transfer_Technician'] | MUST MATCH | Technician (ITCH)
instantiationAnnotation[@annotationType='codingHistory'] | MUST MATCH | CodingHistory | Parsed additionally by step and parameter

This table shows that an asset, for example, cannot contain two instantiations from two different shows or collections, and that the genre must be applied uniformly to all instantiations. However, in order to better describe instantiations that only encompass part of an asset (e.g. "Hour 1", "Hour 2"), partial contributors or keywords may be embedded in an instantiation. Thus, if an artist appears during the first half of a show but not the second, we may only embed their URL in the instantiation that covers that half. However, as indicated above, *all* artists in the instantiations will be included at the asset level.

Partial instantiations pose a particular challenge with a one-to-many cataloging schema such as pbcore (as opposed to Dublin Core, which is one-to-one). The advantage of being able to describe several items at once is often counterbalanced by lack of granularity and vague hyerarchical relations. An alternative approach is to apply metadata to physical and digital items and establish relations among them, without necessarily having an umbrella conceptual element.
