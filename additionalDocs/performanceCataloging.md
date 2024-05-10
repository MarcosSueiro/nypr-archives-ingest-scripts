# Creating consistent descriptions of musical performances

## Introduction
The NYPR Archives contains many decades of remarkable performance recordings, including shows such as _Around New York_ or _New Sounds Live_. These performances are particularly valuable because they may be subject to fewer intellectual control restrictions than mass-replicated recordings and because they are unique.

We aim to provide **consistent, reference-able listings** within each live performance of the following aspects:
- musical works
- performers
- media of performance

This will allow us to answer questions such as: 
- What other performances do we have of the Mozart clarinet concerto?
- What instruments does Evan Ziporyn play in our collection?
- What published recordings exist of James P. Johnson’s “Charleston”?

This will be done by creating, first, mezzanine parse-able descriptions that, after parsing, will eventually result in the following data:
- LCNAF entries for works or composers (whichever is more specific) as _subjects_
- LCNAF or WNYC entries for performers as _contributors_
- (maybe) URLs (TBD) for media of performance as _contributorRoles_
- Consistent, parse-able descriptions of the performance as _abstract_

## Workflow
1. Catalogers will work on the Archives' cataloging tool (known as "cavafy") using a template for each major section of the concert or performance (see [below](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/blob/master/additionalDocs/performanceCataloging.md#sample-section-entry) for a sample)
2. An xslt script will use LoC's API to suggest entries that match titles, composers, performers and media of performance. Catalogers will choose the appropriate entry
3. Catalog records will be updated as stated above

## Cataloging resources
- https://www.iasa-web.org/sound-archives/cataloguing
- https://www.iasa-web.org/cataloguing-rules
- https://wiki.lyrasis.org/display/LD4P/Performed+Music+Ontology
- https://www.fiafnet.org/pages/E-Resources/Cataloguing-Manual.html 

## Appendix
### Sample section entry 
The following is a filled-out template for the mezzanine description of a musical performance. Note that there are extra segments that will be ignored when creating the final abstract.
```HOUR PERFORMANCE DATE: 1996-03-04
HOUR SEQUENCE: 
HOUR DESCRIPTION: Jordan Sandke and his Sunset Serenaders with guest violinist Joel Smirnoff. Listed as "Sunrise Serenaders" on box. (Note: There have been several bands called "Sunset Serenaders". This is the New York-based ensemble led by Jordan Sandke)
HOUR HOST: John Schaefer
HOUR ENGINEER:  
HOUR NOTES: 
<SEGMENT>
** LIVE WORK TITLE: Taking a chance on love
** LIVE WORK COMPOSER: Duke, Vernon
** LIVE WORK PERFORMERS: [SUNSET SERENADERS: Jordan Sandke|cornet ; John Di Martino|piano ; Rob Thomas|bass]
** GUEST PERFORMERS, INTERVIEWEES: Joel Smirnoff | violin
** SEGMENT NOTES: 
</SEGMENT>
<SEGMENT>
** LIVE WORK TITLE: Tin tin deo
** LIVE WORK COMPOSER: Dizzy Gillespie ; Chano Pozo
** LIVE WORK PERFORMERS: [SUNSET SERENADERS: Jordan Sandke|cornet ; John Di Martino|piano ; Rob Thomas|bass]
** GUEST PERFORMERS, INTERVIEWEES: Joel Smirnoff | violin
** SEGMENT NOTES: 
</SEGMENT>
<SEGMENT>
** LIVE WORK TITLE: Black Satin
** LIVE WORK COMPOSER: Joe Venuti ; Russ Morgan
** LIVE WORK PERFORMERS: [SUNSET SERENADERS: Jordan Sandke|cornet ; John Di Martino|piano ; Rob Thomas|bass]
** GUEST PERFORMERS, INTERVIEWEES: Joel Smirnoff | violin
** SEGMENT NOTES: 
</SEGMENT>
<SEGMENT>
** LIVE WORK TITLE: Medley: Beethoven violin concerto with Sweet Georgia Brown
** LIVE WORK COMPOSER: 
** LIVE WORK PERFORMERS: [SUNSET SERENADERS: Jordan Sandke|cornet ; John Di Martino|piano ; Rob Thomas|bass]
** GUEST PERFORMERS, INTERVIEWEES: Joel Smirnoff | violin
** SEGMENT NOTES: 
</SEGMENT>
<SEGMENT>
** LIVE WORK TITLE: 
** LIVE WORK COMPOSER: 
** LIVE WORK PERFORMERS: 
** GUEST PERFORMERS, INTERVIEWEES: 
** SEGMENT NOTES: 
</SEGMENT>
<SEGMENT>
** LIVE WORK TITLE: 
** LIVE WORK COMPOSER: 
** LIVE WORK PERFORMERS: 
** GUEST PERFORMERS, INTERVIEWEES: 
** SEGMENT NOTES: 
</SEGMENT>
<SEGMENT>
** LIVE WORK TITLE: 
** LIVE WORK COMPOSER: 
** LIVE WORK PERFORMERS: 
** GUEST PERFORMERS, INTERVIEWEES: 
** SEGMENT NOTES: 
</SEGMENT>
<SEGMENT>
** LIVE WORK TITLE: 
** LIVE WORK COMPOSER: 
** LIVE WORK PERFORMERS: 
** GUEST PERFORMERS, INTERVIEWEES: 
** SEGMENT NOTES: 
</SEGMENT>
<SEGMENT>
** LIVE WORK TITLE: 
** LIVE WORK COMPOSER: 
** LIVE WORK PERFORMERS: 
** GUEST PERFORMERS, INTERVIEWEES: 
** SEGMENT NOTES: 
</SEGMENT>
<SEGMENT>
** LIVE WORK TITLE: 
** LIVE WORK COMPOSER: 
** LIVE WORK PERFORMERS: 
** GUEST PERFORMERS, INTERVIEWEES: 
** SEGMENT NOTES: 
</SEGMENT>```
