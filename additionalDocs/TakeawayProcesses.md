# Takeaway end-of-life processes
## Intro
The Takeaway was a radio newsmagazine that broadcast between XXX and XXXX. 
The Takeaway used DAVID as a production tool.
After sunset, there were two issues:
1. We wanted to make sure that we could get all the finished product
2. We wanted to make sure that we could identify substantial production files
## Complete runs
- The Takeaway broadcast mostly on weekdays but it occasionally broadcast on weekends
- All of the finished products appeared to be in one of two folders: Archives_Takeaway and Archives_44k
- Most of the weekday finished products were already in the DAMS
1. We created a script that ran through all dates between XXX and XXX
2. We searched the DAVID titles in two folders looking for the following string matches:
    - "Takeaway", and
    - A date formatted in one of six formats (YYYY-MM-DD, MMDDYY, etc.)

Result: XXX files

## Matched production files
- Production raw files in the DAVID folder showed many different names
- 250k+ files
- Lots of name duplicates
1. Create a frequency list of all "words" in DAVID titles of files 30 min or longer
2. Create an entire run of published Takeaway online
3. Parse out guests:
  - Listed as guests
  - Links in the description
  - **Bold** in the description
3. Choose files at least 30 min long within five days previous to broadcast
4. Within those files, look for last-name string match
5. Generate a chooser html document (radio buttons):
    - Alphabetical by last name
    - Showing context
    - Show exact length, name, etc
    - Warn of common last names ("Smith")
6. A human chooses file(s) from this list
7. We transcode/export the desired files, renaming them according to Archives protocol
Result: 1k files
- Complication: "Project" files saved as multi-chunk wave files --will need to export as valid WAV
 



