# Creating consistent descriptions of musical performances

## Introduction
The NYPR Archives contains many decades of remarkable performance recordings, including shows such as _Around New York_ or _New Sounds Live_. These performances are particularly valuable because they may be subject to fewer intellectual control restrictions than mass-replicated recordings and because they are unique.

We aim to provide:
- **normalised, reference-able listings** within each live performance of the following aspects:

1. musical works
2. performers
3. media of performance

- **standardised, parse-able** performance listings

This will allow us to answer questions such as: 
- What other performances do we have of the Mozart clarinet concerto?
- What instruments does Evan Ziporyn play in our collection?
- What published recordings exist of James P. Johnson’s “Charleston”?

## Musical works
We aim to have a **standardised, referenceable entry** for each work performed live.

Whenever possible, use a NameTitle entry from LCNAF:

    Mozart, Wolfgang Amadeus, 1756-1791. Quintets, clarinet, violins (2), viola, cello, K. 581, A major

    http://id.loc.gov/authorities/names/n81128331

The important part of the entry above is the URL.

Many non-classical and "new" musical works have no entries in LoC. 

We need to find at most two additional databases that include:

- A complete URL for each work
- (Preferably) serialization as json or xml
- (Preferably) a RESTFul API
- (Preferably) synchronization with WQXR exiting databases

### Movements, Sections, Arrangements and medleys
Devise a way to note these when not specified in LCNAF

## Performers
Use LCNAF entries whenever possible. 

If no LCNAF entry exist, use or create a wnyc.org/person entry. Here is an [example](https://www.wnyc.org/people/richard-borinstein/).

## Media of performance
Use [LCMPT](http://id.loc.gov/authorities/performanceMediums) whenever possible. 

LCMPT does not include some performance roles such as a non-performing conductor. We need to come up with an alternative. 

## Performance listings

Devise a parse-able description that clearly presents the structure of a performance recording, e.g.:

```
SECTION (e.g. hour)
  sectionDescription
  sectionTitle
  segment
    segmentDescription
    work
      workComposer
      workTitle
      performer : mediumOfPerformance
    segmentNotes
  sectionNotes
    
```

## Workflow
To be devised.

Options include:
- pre-loaded forms in cavafy, e.g. [this](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/blob/master/additionalDocs/performanceCataloging.md#sample-section-entry)
- spreadsheets
- OpenRefine interactive spreadsheets
- xhtml forms

## Cataloging resources
- https://web.library.yale.edu/cataloging/music
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
