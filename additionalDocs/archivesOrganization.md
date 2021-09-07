# Organization of items in the NYPR Archives #

This document outlines how NYPR Archival materials are organized.

* NYPR materials are organized into **Collections**, which represent either the material's original creator (WNYC, WQXR) or its current archival steward (NARA, MUNI).
* Collections are divided into **Series**, which often reflect the material's original show (Brian Lehrer Show, New Sounds). 
* Series contain conceptual **Assets**, 
* whose physical (1/4 inch audio tape, DAT) or digital (WAVE files) manifestations are called **Instantiations**.

The NYPR catalogue uses the pbcore schema, which [defines](https://pbcore.org/glossary) **asset** as 
> A single piece of content, such as a program, clip, or episode. 
> One asset may exist in many different forms (for example, on DVD, on a U-matic tape in English, and on a VHS tape in French). 
> If the content is the same, those would all be considered instantiations of the same asset" 

and **instantiation** as 
> A manifestation of an asset that is embodied in physical or digital form, such as a tape, DVD, or digital file.
> One asset can have many instantiations, but generally, each instantiation holds the same intellectual content." 

The NYPR Archives' interpretation of what consitutes the *same* intellectual content varies widely. Generally, the catalog adheres to the pbcore concepts above: thus, an original 1/4 inch tape of a broadcast and a Beta PCM F-1 recording of its aircheck will be grouped under the same asset (even if the latter includes, say, the top-of-the-hour news). But the catalog includes plenty of examples deviating in both directions: some complex assets include multitracks, safety copies, and several versions of mixes; while, on the other hand, two tapes with content from the first and second hour of a broadcast may be cataloged as different assets. Current efforts to improve data quality for reformatted materials focus on the latter --that is, on grouping together instantiations that should be under one asset.

Despite the wide range of asset-instantiation relationships, the Archives [ingest scripts](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts) detect inconsistencies between instantiation-level (i.e., embedded) and asset-level metadata. The following table summarizes the rules followed by the scripts:

Asset metadata | Relationship | Embedded metadata | Notes
--------------- | ------------ | ----------- | -----
pbcoreTitle[@titleType='Collection'] | MUST MATCH | Archival Location (IARL) | Including country, e.g. "US, WNYC"
pbcoreContributor/@ref | MUST INCLUDE | Artists (IART) | As URLs, e.g. https://id.loc.gov/authorities/names/n50080187
pbcoreCreator/pbcorePublisher/@ref | MUST INCLUDE | Commissioned by (ICMS) | As URL, e.g. https://id.loc.gov/authorities/names/n50080187
rightsSummary | MUST MATCH | Copyright (ICOP)
pbcoreAssetDate | MUST INCLUDE | Create Date (ICRD)
pbcoreContributor[Role='Engineer']/contributor | MUST INCLUDE | Engineer (IENG)
pbcoreGenre | MUST MATCH | Genre (IGNR)
pbcoreSubject/@ref | MUST INCLUDE | Keywords (IKEY)
pbcoreTitle[@titleType='Episode'] | MUST MATCH | Title (INAM) | For full-length instantiations
pbcoreTitle[@titleType='Series'] | MUST MATCH | Product (IPRD)
pbcoreDescription[@descriptionType='Abstract'] | MUST MATCH | Subject (ISBJ) | For full-length instantiations
pbcoreIdentifier[@source='pbcore XML database UUID'] | MUST MATCH | Source (ISRC) | As URL, e.g. https://cavafy.wnyc.org/assets/4a483b27-3959-472b-827e-0825c5165176

This table shows that seven fields must match between the asset and instantiation levels, while five asset-level fields function as containers ('MUST INCLUDE') for instantiation-level metadata. Thus, an asset cannot contain two instantiations from two different shows, and the genre must be applied uniformly to all instantiations. 

On the other hand, in order to better describe an instantiation that only encompasses part of an asset (e.g. "Hour 1"), such an instantiation may only include the contributors relevant to that segment. Thus, if an artist appears during the first half of a show but not the second, we may choose to embed their URL only in the instantiation that covers that half, and give it a specific title as well. However, as indicated above, *all* artists in the instantiations will be included at the asset level; and, as we will see below, the title is included at the instantiation level.

Partial instantiations pose a particular challenge with a one-to-many cataloging schema such as pbcore (as opposed to Dublin Core, which is one-to-one). The advantage of being able to describe several items at once is often [counterbalanced by lack of granularity and vague hyerarchical relations](https://www.oclc.org/research/activities/frbr/clinker.html). An alternative approach is to apply metadata to physical and digital items and establish relations among them, without necessarily having an umbrella, conceptual element.

Additional embedded metadata is mapped at the instantiation level as per the following table:

Instantiation metadata | Relationship | Embedded metadata | Notes
--------------- | ------------ | ----------- | -----
instantiationAnnotation[@annotationType='Embedded_Comments'] | MUST MATCH | Comments (ICMT)
instantiationRelation[instantiationRelationType='Is Dub Of']/instantiationRelationIdentifier | MUST MATCH | Original Medium (IMED)
instantiationAnnotation[@annotationType='Embedded Title'] | MUST MATCH | Title (INAM) | For partial instantiations
instantiationAnnotation[@annotationType='Embedded Description'] | MUST MATCH | Subject (ISBJ) | For partial instantiations
 || not captured | Software (ISFT)
instantiationAnnotation[@annotationType='Provenance'] | MUST MATCH | Source reference (ISRF)
instantiationAnnotation[@annotationType='Transfer_Technician'] | MUST MATCH | Technician (ITCH)
instantiationAnnotation[@annotationType='codingHistory'] | MUST MATCH | CodingHistory | Parsed additionally by step and parameter
