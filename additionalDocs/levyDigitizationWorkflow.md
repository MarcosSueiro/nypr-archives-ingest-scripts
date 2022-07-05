# Digitization Workflow per shipment 

INPUT: A show and a physical format 

OUTPUT: Self-described, compliant Broadcast WAVE Files 

## Choose and describe series
_Main task:_ Ensure show is properly described 

1. Choose Shipment: a show restricted by a format (e.g. “Mostly Mozart” “DAT”) 
2. Gather supporting print and digital documentation for the show (press releases, logs, production notes, program guides, physical containers, etc.); OCR as needed 
3. Fully describe the show with values for genre, creators, subject headings and copyright; these will become the default values for assets within that series.

## Describe and ship items within the show
_Main task:_ Ensure each item in show is properly described
1. Make sure each asset has correct values for title, dates, abstract and genre; merge assets where appropriate.
2. Add Library of Congress contributors and subject headings

## Ship items
_Main task:_ Locate and ship physical items
1. Gather physical items from onsite and remote storage 
2. Print and affix barcodes
3. Pack and ship items

## Digitize (vendor)
_Main task:_ Create compliant, surrogate digital files of the shipped items
1. Check received items agains manifest
2. Reformat items according to Statement of Work (SOW)
3. Generate additional metadata (e.g. Coding History, transfer technician, condition report)
4. Communicate with NYPR about unforeseen issues
5. Embed metadata as BWF MetaEdit Core 

## Control Quality
_Main task:_ Verify quality of files 
1. Check received files agains manifest
2. Validate md5 on delivery drive
3. Confirm file specs with MediaConch
4. Confirm the existence of file extension chunks, file format validation and errors with BWF MetaEdit 
5. Confirm quality of the file’s audio data with ffmpeg (via astat audit)
6. Confirm quality manually on a sample of files’ audio data via playbackwith particular emphasis on files with outlying values for duration, levels, correlation, etc.
7. Check head, middle and tail for evidence of truncated content, speed issues, functionality, overall quality, etc. 
8. Contact vendor about issues

## Prepare for Ingest 
_Main task:_ Prepare compliant files for ingestion into DAMS
1. Ensure embedded metadata complies; fix if needed. If needed, include additional metadata by monitoring the file
2. Notify DAMS team of new batch of files
3. Store physical carriers in Archives storage

For a more detailed explanation of all steps, see https://nypr.sharepoint.com/:w:/s/NYPRArchives/Ed938H9TBPxAnZ8oB3VvuTIBF_UAL6SZb0dELNTE_q4lIg?e=mCH45h (internal NYPR use only)
