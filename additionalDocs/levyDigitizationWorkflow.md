Digitization Workflow per shipment 

INPUT: A series (a.k.s. show) and a physical format 

OUTPUT: Self-described, compliant Broadcast WAVE Files 

NYPR 

Describe series 
Main task: Ensure series’ assets are properly described 

Choose Shipment: a series restricted by a format (e.g. “Mostly Mozart” “DAT”) 

Gather supporting print and digital documentation for the series (press releases, logs, production notes, program guides, physical containers, etc.); OCR as needed 

Update the series entry with values for: 

Series description 

Genre 

Creators 

Subject Headings  

Copyright 
Data from fields ii-v will become the default values for assets within that series. 

(Optional) run seriesQC.xsl to get a general sense of the series’ metadata health 

Query Cavafy for the selected series and format 

Update each Cavafy asset entry with correct/additional values for: 

Episode title 

Dates 

Series title 

Abstract description 

Genre 

Page Break
 

Create manifest: 
Main tasks:  

Update Cavafy descriptions of physical items to be sent 

Merge assets where appropriate 

Add creators, contributors and subject headings 

Enter the series name and the format (or a search string) in a copy of seriesTemplate.xml, and save the document with an appropriate name (e.g. MOMO_DAT.xml) - NOTE: when series has ampersands, it is best to enter the API search string straight from Cavafy – e.g.  https://cavafy.wnyc.org/?facet_Series+Title%5B%5D=America+%26+the+World&1%2F4+inch+audio+tape&search_fields%5B%5D=title&search_fields%5B%5D=format 

Transform the new document with generateManifest.xsl.The script generates at least six documents. One of them will have the name “InstIDs....xml”. 

Open a copy of the spreadsheet rdfMasterTemplate.xlsx and save with appropriate name (e.g. MOMO_DAT.xlsx) 

Import the resulting InstIDs....xml document into the tab named “01_Inventory” of the newly-renamed spreadsheet 

Check against physical inventory 

Gather the physical items from onsite and remote storage 

Stage physical items by date and part sequence (tape 1 of 2, tape 2 of 2), interfiling items from onsite and offsite storage: 

Segregate the staged material by series 

Within each series, segregate by medium 

Within each medium, segregate by a logical attribute (e.g. type of recording, generation) 

Within each attribute, sort by a logical element (e.g. date, program number) 

Print and affix barcodes 

Update Cavafy location field 

Mark carriers that cannot be located as “MISSING” + date in Cavafy 

Conversely, add missing carriers directly in Cavafy 

Update spreadsheet, where necessary: 

New instantiation ID or asset ID (if a merge is necessary) 

Additional physical labels (E.g. ‘Deck A’) 

Generation (‘Broadcast Master’) 

Export spreadsheet data as instantiationIDs.xml, and rename the resulting xml document (e.g. CMLC_DATS_instantiationIDs.xml) 

Ingest confirmed/updated data in Cavafy via a [TBD].xml import 

Generate an updated series manifest: Rerun generateManifest.xsl and refresh master spreadsheet 

Enter expected shipment date and expected return date in master spreadsheet 

Repeat steps until satisfactory 

Augment metadata 
Main task: add Names and Subject headings from Library of Congress (LoC) controlled vocabularies 

Add LoC URLs for contributors, artists and subject headings to master spreadsheet. Use extractNames.xsl to manually choose from LoC options 

Export as RDF xml using exiftool format 

Run masterRouter.xsl and import resulting pbcore xml into Cavafy 

Ship 
Main task: Ship carriers to vendor  

Generate a new series manifest: Rerun generateManifest.xsl and refresh master spreadsheet 

Pack carriers 

Generate stickers with barcodes from master spreadsheet 

Affix stickers to carriers and pack into bins 

Add bin ID and box ID (if any) into master spreadsheet  

Ship carriers, manifests and master spreadsheet to vendor 

Enter actual shipment date in master spreadsheet 

Page Break
 

VENDOR 

Digitize 
Main task: Create SIP-compliant digitized surrogates of carriers according to Statement of Work (SOW) 

Receive carriers 

Check against manifest 

Generate additional metadata (e.g. Coding History, transfer technician, condition report) 

TRANSFER AUDIO 

Generate condition report 

Follow SOW 

Refine job 

Contact NYPR 

Mark on master spreadsheet items that will not be transferred and why 

Embed metadata as BWF MetaEdit Core 

Ship audio files with condition report as csv 

Page Break
 

NYPR 

Quality Control 
Main task: verify quality of files 

 Receive files 

 Generate exiftool report of files 

 Compare original master spreadsheet with actual files 

Ingest vendor files 

Validate md5 on delivery drive 

Sync the delivery drive files to a folder in W:\ARCHIVESNAS1\INGEST\01 PLEASE REVIEW 

Validate md5 on server 

Validate vendor files 

Confirm file specs with MediaConch using an appropriate policy 

Confirm the existence of file extension chunks, file format validation and errors with BWF MetaEdit 

Confirm quality of the file’s audio data with ffmpeg via astat audit 

Import condition report into master spreadsheet 

Confirm quality manually on a sample of files’ audio data via playback 

Include 'suspicious’ files: 

that failed ffmpeg audio QC 

with unexpectedly high/low duration  

with outlying measures for levels, correlation, etc 

Check head, middle and tail for evidence of truncated content, speed issues, functionality, overall quality, etc. 

Import file-level QC results into master spreadsheet. 

Improve/check metadata 

Audio files may allow for better metadata 

Contact vendor re: unsatisfactory transfers 

VENDOR/NYPR 

Mark master spreadsheet with “did not digitize” 

Mark master spreadsheet with unsatisfactory transfers 

Manually generate new/same filename onto a new spreadsheet 

Repeat transfers until satisfactory 

Page Break
 

NYPR 

Ingest 
Main task: Ingest SIP-compliant files into DAMS 

Transform exiftool output through masterRouter.xsl 

Fix any unexpected errors 

Embed MD into files via BWF ME 

Verify file-level MD5s 

Upload into Cavafy 

Place in INGEST folder 

NOTE: After 180 days, files go to the cloud 

Copy to DAMS system 

VENDOR  

Store 
Main task: Place physical carriers in long-term storage 

Ship carriers 

Check against master-list manifest 

NYPR 

Receive carriers 

Check against manifest 

Enter received date in master spreadsheet 

Store carriers in pre-determined space 

Update location in cavafy 
