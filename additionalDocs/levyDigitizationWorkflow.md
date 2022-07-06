# Digitization Workflow per shipment 

_INPUT:_ A show and a physical format 

_OUTPUT:_ Self-described, compliant Broadcast WAVE Files 

## Choose and Describe Items
_Main task:_ Ensure items to ship are properly described 
1. Choose Shipment: a show restricted by a format (e.g. “Mostly Mozart” “DAT”) 
2. Gather supporting print and digital documentation for the show (press releases, logs, production notes, program guides, physical containers, etc.); OCR as needed 
3. Fully describe the overall show with values for genre, creators, subject headings and copyright; these will become the default values for all the episodes within that show.
4. Make sure each episode has correct values for title, dates, abstract and genre; merge episodes where appropriate.
5. Add Library of Congress contributors and subject headings

## Ship Items
_Main task:_ Locate and ship physical items
1. Create a manifest
2. Gather physical items from onsite and remote storage 
3. Print and affix barcodes
4. Pack and ship items

## Digitize (Done by Vendor)
_Main task:_ Create compliant, surrogate digital files of the shipped items
1. Check received items agains manifest
2. Reformat items according to Statement of Work (SOW)
3. Generate additional metadata (e.g. Coding History, transfer technician, condition report)
4. Communicate with NYPR about unforeseen issues
5. Embed supplied metadata in files 

## Control Quality
_Main task:_ Verify quality of files 
1. Check received files against manifest
2. Validate md5 on delivery drive
3. Validate file format, encoding and structure
4. Generate reports on quality of the file’s audio data
5. Check quality manually on a sample of files’ audio data via playback, with particular emphasis on files with outlying values for duration, levels, correlation, etc.
6. Check head, middle and tail for evidence of truncated content, speed issues, functionality, overall quality, etc. 
7. Contact vendor about issues

## Prepare for Ingest 
_Main task:_ Prepare compliant files for ingestion into DAMS
1. Ensure embedded metadata complies; fix if needed. If needed, include additional metadata by listening to the file
2. Notify DAMS team of new batch of files
3. Store physical carriers in Archives storage

For a more detailed explanation of all steps, see https://nypr.sharepoint.com/:w:/s/NYPRArchives/Ed938H9TBPxAnZ8oB3VvuTIBF_UAL6SZb0dELNTE_q4lIg?e=mCH45h (internal NYPR use only)

For more detailed description of the Archives workflow, see https://github.com/MarcosSueiro/nypr-archives-ingest-scripts/blob/master/additionalDocs/ArchivesWorkflow.md
