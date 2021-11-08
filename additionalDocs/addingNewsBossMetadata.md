# Adding NewsBoss Metadata
## Introduction
Since 2011, New York Public Radio automatically records every day several hourly WNYC local newscasts. There are currently about 52,000 full-resolution WAVE files stored in the station's production system, [DAVID](https://www.davidsystems.com/).

The DAVID recording process automatically starts the recording at :04 after the hour, which is when the local newscast is broadcast. It assigns a unique filename and a 'title' following the following pattern: *'WNYC-NWSC-[YYYY-MM-DD hhmm]m';* for example *'WNYC-NWSC-2021-11-07 19h11m'.* This pinpoints which hourly broadcast is recorded (the part indicating the minutes after the hour seems to vary). Each recording is always less than five minutes long.

On the other hand, the station's newsroom automation system, [NewsBoss](https://www.newsboss.com/), stores the text that the station's host reads during the local newscasts, as well as additional information such as other audio files to play and the names of the writers and editors of each news story.

This document describes a project in the Fall of 2021 that matched the original WAVE files to the NewsBoss descriptions. We then embedded the NewsBoss metadata in the WAVE files for easier ingest into the station's DAMS, and for better discoverability.

## Preparing NewsBoss data
NewsBoss can export its data as an .htm file. But the data needs to be manipulated slightly in order to render it more usable.

Here are the steps:
1. Log in to NewsBoss
2. Find the newscasts in NewsBoss:
  * Search NewsBoss 'Acrhive' for the text ":04" *in slugs*...
     * ...limiting the search to one year (this may no longer be strictly necessary, but it likely has beefits later on with regards to managing large files, etc.)
     * ...limiting results to Newscasts, not stories
4. Select all results
5. Retrieve to your queue
6. Select your entire queue and export as an .htm file with the following name: '[YYYY]newscasts.htm' (e.g. '2015newscasts.htm')
7. Clean up htm file in a text editor: 
  * Fix ```<meta>``` tag: replace ```'charset=utf-8">'```  with   ```'charset=utf-8"/>'```
  * Replace ```</A><HR></TD>``` with ```</A><HR/></TD>```
  * Clean up all ```'&nbsp;'```   
  * Clean up control-code Unicodes, e.g. 0x1f, 0x1a (regex ```"\u001F"``` and ```"\u001A"```)
  * Clean everything else until you have a well-formed html
8. Parse out the broadcast date. (This makes for more efficient text-matching later) 
  * Make two replacements:
    * ```"<br/>Archived at"``` with ```"<br/><archiveDate>Archived at"``` and 
    * ```"by NewsBoss Wires<br/>-------"``` with ```"by NewsBoss Wires</archiveDate><br/>-------"```
    
## Generating DAVID titles
Generate an xml list of appropriate DAVID titles. For example, you can use this exiftool command:
```exiftool -ext dbx -m -if "$EntriesEntryTitle =~ /NWSC/i" -EntriesEntryTitle -X "[sourceDirectory]" >"[destinationFile].xml"```

## Matching the scripts to the files
The [xslt stylesheet](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/blob/master/currentTemplates/NewsBossExiftoolDBX2ixml.xsl) that matches the files works as follows:

You must enter a year after 2010 in ["year to process"](https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/blob/1941c7c0247f85e18c5ed13b14be284fefa0d304/currentTemplates/NewsBossExiftoolDBX2ixml.xsl#L24). The script then only focuses on that year.

The "Archived at" date in the .htm document is the date of the newscast. Because newscasts are often revised, the scripts favors the one archived automatically by NewsBoss at :40 past the hour (e.g. Archived at 7:40 for the 7:04 newscast). If that is not found, it finds the last version available.

Each newscast is divided into stories. The script parses each story out and extracts data about its writer, slug, editor, and additional files. This is all reflected in the generated log. The log also registers the number of original matches, and flags files shorter than 120 seconds. It also flags stories marked as weather in NewsBoss.

## Embedding the NewsBoss matadata
The script generates a "Core" type file to embed metadata using [BWF MetaEdit](https://mediaarea.net/BWFMetaEdit). All newscasts from 2012 to 2020 for which the script found a match in the NewsBoss data now have the following embedded information:

Archival Location: 'US, WNYC'
Artists (a.k.a. contributors): All story editors ('subs'), separated by semicolons
CommissionedBy (a.k.a. Creators): All story writers, separated by semicolons
Comment: All related files' ('cuts') filenames and titles, separated by semicolons
Copyright: 'Terms of Use and Reproduction: WNYC Radio. Additional copyright may apply to musical selections.'
Date: Newscast date, in [ISO 8601 format](https://www.iso.org/iso-8601-date-and-time-format.html)
Engineer: 'Unknown engineer'
Genre: 'News'
Keywords: 'https://id.loc.gov/authorities/subjects/sh85034883' (and 'http://id.loc.gov/authorities/subjects/sh85145856' if there are weather stories)
Medium: 'Aircheck'
Name: Newscast name, e.g. 'Newscast Archive NEWSCASTS.Weekdays.Midday.1:04 pm'
Product: 'News'
Subject: NewsBoss script, stripped of potentially bothersome characters
Software: Whatever DAVID lists as the generator, e.g. 'MultiCoder3'
Source: 'https://www.wnyc.org/story/latest-newscast/'
SourceReference [a.k.a. provenance]: 'WNYC Radio Aircheck'
Technician: DAVID Author / Creator (e.g. 'SVCCSX')
