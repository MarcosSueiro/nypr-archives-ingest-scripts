# Creating consistent descriptions of musical performances

## Introduction
The NYPR Archives contains many decades of remarkable performance recordings, including shows such as Around New York or New Sounds Live. These performances are particularly valuable because they may be subject to fewer intellectual control restrictions than mass-replicated recordings and because they are unique.

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
1. Catalogers will work on the Archives' cataloging tool (known as "cavafy") using a template for each major section of the concert or performance (see below for a sample)
2. An xslt script will use LoC's API to suggest entries that match titles, composers, performers and media of performance. Catalogers will choose the appropriate entry
3. Catalog records will be updated as stated above
