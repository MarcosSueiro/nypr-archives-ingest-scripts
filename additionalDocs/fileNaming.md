# File naming in the New York Public Radio Archives #

The New York Public Radio Archives uses a descriptive, unique filename that reflects the file's [classification](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/blob/master/additionalDocs/archivesClassification.md), provenance and other characteristics. Together with the file's embedded metadata, the filename provides a robust, relatively system-independent description of the file.

A NYPR Archives filename has four alphanumeric sections, joined by one dash ("-"): Collection, Series, Date and Instantiation ID. An optional free text, separated from the rest of the filename by a space, can provide additional information such as external IDs or the file's provenance.

For example, a filename such as
**WNYC-OTM-1997-10-05-84475.4 Refugees Reformers Media Scrutiny WEB EDIT**
  
breaks down as follows:

<p align="center">
          <img src="http://www.plantuml.com/plantuml/png/NP1DQuD048Rl-ok6xSKUX0GCIMv9OmeUqa8LGYazRFLL5ZOhx8x1KFhVkzhceBUPvvtzc6VdMJdkBaQe1fRf_F9-e0TzRTtjdxmMfocGo-rs7IyNyM8bINboCBWgowbYp2OtoMQzaZEOpC4Rwgu1F8MYTHSuJoTKMb5UkewrlT7v-4J7D2l6zse75EZvVejHNp0aOqdxdAgMXKF9oZO69BNreMIjMBUMibJIjn3Htdjmw1ufZcdyeuYooMJUrRNknpmHFoASERJ6e1p2aNuCeZv5bCDf-3yKJ0KoQ1ZwYHSXecS74AFdCRml8NQmLT3_2m00"/>
          </p>
          
Let's analyze each section.

## Collection
NYPR materials are organized into 121 Collections, which represent either the material's original creator (WNYC, WQXR) or its current archival steward (NARA, MUNI). Their acronym, name, location, and Library of Congress URL are stored in this [document](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/blob/master/currentTemplates/CollectionConcordance.xml).

The filename reflects the collection's three- or four-character acronym.

## Series
Collections are divided into about 600 Series, which often reflect the material's original show (Brian Lehrer Show, New Sounds). Details about the collections are stored in special assets in cavafy with a relation of type "other" and value "SRSLST". You can see an updated list [here](https://cavafy.wnyc.org/assets?q=SRSLST&x=0&y=0&search_fields%5B%5D=relation), and a less-maintained version [here](https://wiki.nypr.digital/display/AR/NYPR+Series+Titles).

The filename reflects the series' three- or four-character acronym.

## Date
An piece of audio can have many relevant dates, from the original recording date to the date where its metadata was updated. At the conceptual, pbcore ["asset"](https://pbcore.org/elements/asset) level we are mostly concerned with recording and broadcast dates of the original material.

That can still mean several dates to choose from. In that case, choose the *earliest date relevant to the particular file*.

Dates are always formatted YYYY-MM-DD, with unknown data as "u" (e.g. (1985-uu-uu").

## Instantiation ID
The instantiation ID is unique to the filename. It consists of a numeric **asset ID** and an alphanumeric **instantiation suffix** joined by a period (".")
#### Asset ID
The asset ID is the unique number assigned to one of about 70,000 conceptual "assets" in the NYPR catalogue under which one or more manifestations ("instantiations", in pbcore parlance) are grouped. Asset IDs are between four and six digits long, non-continuous.
#### Instantiation suffix
The instantiation suffix is unique within an asset for each instantiation. In the example above, ".4" denotes the fourth instantiation of that asset.

The instantiation suffix is always a number, but:
* An additional letter (e.g. "4a") denotes a partial rendering (e.g. "Part a of several")
* An aditional "\_TK" suffix plus a number indicates the file is part of a multitrack recording (e.g. ".4\_TK2")

## Free text
After a space, there may be additional text, which may include
* Part of the asset's title
* Additional IDs (e.g. "LT435")
* Generation indicators (e.g. "WEB EDIT")

The Archives [ingest scripts](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/tree/master/currentTemplates) parse and react to some of these indicators.
