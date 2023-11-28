# Adding NewsBoss Metadata
## Introduction
Since noon of April 18, 2011, New York Public Radio automatically records every day several hourly WNYC [local newscasts](https://www.wnyc.org/story/latest-newscast/). There are currently about 52,000 of these recordings, as full-resolution WAVE files, stored in the station's production system, [DAVID](https://www.davidsystems.com/).

The DAVID recording process automatically starts the recording at :04 after the hour, which is when the local newscast is broadcast. The process assigns a unique filename and a 'title' following the following pattern: *'WNYC-NWSC-[YYYY-MM-DD hh]h[mm]m';* for example *'WNYC-NWSC-2021-11-07 19h11m'.* This pinpoints which hourly broadcast is recorded (the part indicating the minutes after the hour seems to vary). Each recording is always less than five minutes long.

On the other hand, the station's newsroom automation system, [NewsBoss](https://www.newsboss.com/), stores the text that the station's host reads during the local newscasts, as well as additional information such as other audio files to play and the names of the writers and editors of each news story. NewsBoss data begins on May 30, 2008; the first :04 newscast in NewsBoss is from June 17, 2008.

This document describes an [NYPR Archives](https://www.wnyc.org/series/archives-preservation) project in the Fall of 2021 that matched the original WAVE files to the NewsBoss descriptions. We then embedded the NewsBoss metadata in the WAVE files for easier ingest into the station's DAMS, and for better discoverability.

## Preparing NewsBoss data
NewsBoss can export its data as an .htm file. But the data needs to be manipulated slightly in order to render it more usable.

Here are the steps:
1. Log in to NewsBoss
2. Find the newscasts in NewsBoss:
   * Search NewsBoss 'Archive' for the text ":04" *in slugs*...
     * ...limiting the search to one year (NewsBoss can retrieve up to 10,000 entries per search)
     * ...limiting results to Newscasts, not stories
3. Select all results
4. **Retrieve** to your 'queue'
5. Select your entire queue and export as an .htm file with the following name: '[YYYY]newscasts.htm' (e.g. '2015newscasts.htm')
6. Clean up the htm file in a text editor: 
   * Fix ```<meta>``` tag: replace ```'charset=utf-8">'```  with   ```'charset=utf-8"/>'```
   * Replace ```</A><HR></TD>``` with ```</A><HR/></TD>```
   * Clean up all ```'&nbsp;'```   
   * Clean up control-code Unicodes, e.g. 0x1f, 0x1a (regex ```"\u001F"``` and ```"\u001A"```)
   * Clean everything else (this may vary) until you have a [well-formed html](https://validator.w3.org/)
7. Parse out the broadcast date. (This makes for more efficient text-matching later) 
   * Make two replacements:
     * ```"<br/>Archived at"``` with ```"<br/><archiveDate>Archived at"``` and 
     * ```"by NewsBoss Wires<br/>-------"``` with ```"by NewsBoss Wires</archiveDate><br/>-------"```
    
## Generating DAVID titles
Generate an RDF list of appropriate DAVID titles. For example, you can use this exiftool command:
```exiftool -ext dbx -m -if "$EntriesEntryTitle =~ /NWSC/i" -EntriesEntryTitle -X "[sourceDirectory]" >"[destinationFile].xml"```
The script needs the following schema:
```
<rdf:RDF>
   <rdf:Description about="[filename]">
      <XMP:EntriesEntryMediumFileTitle>
```

## Matching the scripts to the files
The [xslt stylesheet](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/blob/master/currentTemplates/NewsBossExiftoolDBX2ixml.xsl) that matches the files works as follows:

First, you enter a year after 2010 in ["year to process"](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/blob/1941c7c0247f85e18c5ed13b14be284fefa0d304/currentTemplates/NewsBossExiftoolDBX2ixml.xsl#L24). The script then only focuses on that year.

The "Archived at" date in the .htm document is the date of the newscast. Because newscasts are often revised, the scripts favors the one archived automatically by NewsBoss at :40 past the hour (e.g. Archived at 7:40 for the 7:04 newscast). If that is not found, it finds the last version available.

Each newscast is divided into stories. The script parses each story out and extracts data about its writer, slug, editor, and additional files. This is all reflected in the generated log. The log also registers the number of original matches; flags files shorter than 120 seconds; and flags stories marked as weather in NewsBoss.

## Embedding NewsBoss metadata
The script generates a "Core" type file to embed metadata using [BWF MetaEdit](https://mediaarea.net/BWFMetaEdit). All newscasts from 2011 to 2020 for which the script found a match in the NewsBoss data now have the following embedded information:

* Archival Location: 'US, WNYC'
* Artists (a.k.a. contributors): All story editors ('subs'), separated by semicolons
* CommissionedBy (a.k.a. creators): All story writers, separated by semicolons
* Comment: All related files' ('cuts') filenames and titles, separated by semicolons
* Copyright: 'Terms of Use and Reproduction: WNYC Radio. Additional copyright may apply to musical selections.'
* Date: Newscast date, in [ISO 8601 format](https://www.iso.org/iso-8601-date-and-time-format.html)
* Engineer: 'Unknown engineer'
* Genre: 'News'
* Keywords: 'https://id.loc.gov/authorities/subjects/sh85034883' (and 'http://id.loc.gov/authorities/subjects/sh85145856' if there are weather stories)
* Medium: 'Aircheck'
* Name: Newscast name (e.g. 'Newscast Archive NEWSCASTS.Weekdays.Midday.1:04 pm')
* Product: 'News'
* Subject: Text of NewsBoss script, stripped of potentially bothersome characters
* Software: DAVID Generator (e.g. 'MultiCoder3')
* Source: 'https://www.wnyc.org/story/latest-newscast/'
* SourceReference (a.k.a. provenance): 'WNYC Radio Aircheck'
* Technician: DAVID Author / Creator (e.g. 'SVCCSX'),

## Results

The project matched 42,063 WAVE files with NewsBoss scripts out of a total 47,179 files, a success rate of 89%. Files more recent than 2014 fared consideraby better:

| Year   | Total  | Successful | Failed | Percent |
| ------ | ------ | ---------- | ------ | ------- |
| 2020   | 4,160  | 3,954      | 206    | 95.05   |
| 2019   | 5,037  | 4,679      | 358    | 92.89   |
| 2018   | 4,965  | 4,543      | 422    | 91.50   |
| 2017   | 4,555  | 4,371      | 184    | 95.96   |
| 2016   | 4,554  | 4,396      | 158    | 96.53   |
| 2015   | 4,834  | 4,698      | 136    | 97.19   |
| 2014   | 5,007  | 4,092      | 915    | 81.73   |
| 2013   | 5,321  | 4,271      | 1,050  | 80.27   |
| 2012   | 5,334  | 4,210      | 1,124  | 78.93   |
| 2011   | 3,412  | 2,849      | 563    | 83.50   |
| **TOTALS** | **47,179** | **42,063**     | **5,116**  | **89.35**   |

A 50-file sample of files (see below) shows that, aside from the weather stories (often used to precisely adjust the length of the newscast), the matched NewsBoss script sometimes (12%) shows more, but never fewer, stories than its corresponding audio file. This may be due to:
*	The somewhat improvisatory nature of the newscast, where announcers need to fill the time exactly
*	The occasional special broadcast
*	The occasional short file
*	The occasional file recorded at the wrong time

*Table: Comparing stories in audio files vs in NewsBoss scripts. 
w = weather; A' = variation of A; x = no match; \[NPR\] = content other than newscast*
| File                        | Audio stories | NewsBoss stories |
| --------------------------- | ------------- | ---------------- |
| WNYC-NWSC-2020-10-02 18h10m | ABCw          | ABCw             |
| WNYC-NWSC-2020-08-21 15h08m | ABCw          | ABCw             |
| WNYC-NWSC-2020-06-08 07h06m | ABCw          | A'BCDEw          |
| WNYC-NWSC-2020-04-22 18h04m | ABCw          | ABCw             |
| WNYC-NWSC-2020-02-06 18h02m | ABCw          | ABCw             |
| WNYC-NWSC-2020-02-23 17h02m | ABCw          | ABC              |
| WNYC-NWSC-2020-09-07 06h09m | ABCw          | ABC              |
| WNYC-NWSC-2020-04-24 21h04m | ABw           | AB               |
| WNYC-NWSC-2020-09-29 09h09m | ABCw          | ABC              |
| WNYC-NWSC-2020-09-16 08h09m | ABCw          | ABCw             |
| WNYC-NWSC-2020-04-03 15h04m | ABw           | ABw              |
| WNYC-NWSC-2020-07-23 15h07m | ABw           | ABw              |
| WNYC-NWSC-2020-03-14 13h03m | ABCw          | ABCDE            |
| WNYC-NWSC-2020-11-18 15h11m |               | x                |
| WNYC-NWSC-2020-11-29 10h11m | \[NPR\]       | AB               |
| WNYC-NWSC-2020-01-26 19h01m | ABw           | AB               |
| WNYC-NWSC-2020-03-12 20h03m | ABCw          | ABC              |
| WNYC-NWSC-2020-04-24 17h04m | ABCw          | ABCw             |
| WNYC-NWSC-2020-06-07 19h06m | ABw           | AB               |
| WNYC-NWSC-2020-08-24 15h08m |               | x                |
| WNYC-NWSC-2020-10-17 18h10m |               | x                |
| WNYC-NWSC-2020-04-14 21h04m | ABw           | AB               |
| WNYC-NWSC-2020-07-22 15h07m | ABw           | ABw              |
| WNYC-NWSC-2020-03-05 22h03m | ABw           | AB               |
| WNYC-NWSC-2020-06-25 22h06m | ABw           | AB               |
| WNYC-NWSC-2020-02-13 13h02m | ABw           | ABw              |
| WNYC-NWSC-2020-10-23 15h10m | ABC           | ABC              |
| WNYC-NWSC-2020-04-08 15h04m | ABw           | ABw              |
| WNYC-NWSC-2020-12-18 18h12m | ABCw          | ABC              |
| WNYC-NWSC-2020-08-04 20h08m | \[:08\]       | AB               |
| WNYC-NWSC-2020-08-20 07h08m | ABCDw         | ABCD             |
| WNYC-NWSC-2020-05-19 09h05m | ABCw          | ABCw             |
| WNYC-NWSC-2020-06-23 16h06m | ABCw          | ABCw             |
| WNYC-NWSC-2020-06-24 16h06m | ABCw          | ABC              |
| WNYC-NWSC-2020-12-01 08h12m | ABCDw         | ABCDw            |
| WNYC-NWSC-2020-11-23 22h11m | ABC           | ABC              |
| WNYC-NWSC-2020-03-12 15h03m | ABw           | ABwC             |
| WNYC-NWSC-2020-08-11 22h08m | ABw           | AB               |
| WNYC-NWSC-2020-12-15 22h12m | ABw           | AB               |
| WNYC-NWSC-2020-04-07 06h04m | ABCw          | ABC              |
| WNYC-NWSC-2020-06-10 19h06m | ABC           | ABCwDE           |
| WNYC-NWSC-2020-12-08 12h12m | ABw           | ABw              |
| WNYC-NWSC-2020-01-16 15h01m | ABw           | ABw              |
| WNYC-NWSC-2020-04-18 21h04m |               | x                |
| WNYC-NWSC-2020-04-13 20h04m | ABw           | AB               |
| WNYC-NWSC-2020-05-02 20h05m |               | x                |
| WNYC-NWSC-2020-06-26 17h06m | ABC           | ABCw             |
| WNYC-NWSC-2020-03-05 15h03m | ABw           | ABw              |
| WNYC-NWSC-2020-01-07 15h01m | ABw           | ABw              |

## Future work
*	NYPR Archives still has 5,116 newscast files with no descriptive metadata; but, given the iterative nature of hourly newscasts, it may not be a huge deal
* With the additional metadata, these newscasts are probably prime candidates for additional “aboutness” parsing
* It may be good to add the original files listed in ICMT and the log to the same record, as they will likely have better audio
* **NOTE**: The newscast WAVE files have not been checked for file integrity. Some files, for example, appear to have zero length.
