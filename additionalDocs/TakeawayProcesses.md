# Takeaway end-of-life processes
## Intro
The Takeaway was a radio newsmagazine that broadcast between March 31, 2008 and June 2, 2023. 
The Takeaway used DAVID as a production tool.
After sunsetting the show, we wanted to make sure that NYPR had:
1. A **complete run** of all the finished product
2. Substantial **production files**: e.g. raw interviews
## Complete runs
- The Takeaway broadcast mostly on weekdays but it occasionally broadcast on weekends
- All of the finished products appeared to be in one of two folders: Archives_Takeaway and Archives_44k, with segments in 'TakeawayLoRes'
- Most of the weekday finished products were already in the DAMS
- No files in DAVID after October 5, 2022 (straight into DAMS)

### Process:
1. Run through all dates between March 31, 2008 and October 5, 2022
2. Search DAVID titles in DAVID folder 'Archives_Takeaway' looking for the following string matches:
    - "Takeaway", and
    - A date formatted as YYYY-MM-DD or MM-DD-YYYY
3. If not found (1,537 files --mostly week-end), search in 'Archives_44k' with date formats YYYY-MM-DD and MMDDYY (30 files found)
4. If not found but in online [schedule](https://www.wnyc.org/schedule/2023/oct/31/) (62 events), search in previous two folders using additional date formats (YYMMDD, etc.) (0 files found)
5. If not found during second attempt (1,507 dates), look for matches in DAVID folder 'TakeawayLoRes' and date formats YYYY-MM-DD, MM-DD-YYYY or MMDDYY (297 segments)

Conclusion: We may have missed most week-end broadcasts

## Matched production files
- Looking mostly for raw interviews with specific people
- 250k+ production raw files in the DAVID folder "Takeaway Lo Res" 
- Inconsistently named
- Lots of name duplicates

### Process:
1. Create a frequency list of all "words" in DAVID titles in this folder
2. From the CMS, create an entire run of published Takeaway online
3. From (2), parse out guests, identified as:
  - Listed as guests
  - Links in the CMS description
  - **Bold** in the CMS description
3. Choose files at least 5 min long within five days previous to broadcast
4. Within those files, look for last-name string match
5. Generate a [chooser html document](https://marcossueiro.github.io/takeawayChoose/) (with radio buttons):
    - Alphabetical by last name
    - Showing context
    - Show exact length, name, etc
    - Warn of common last names ("Smith")
6. A human chooses file(s) from this list
7. Transcode/export the chosen 720 files:
    - rename them according to Archives protocol, e.g. "WNYC-TAKE-2008-10-06-w6289.2 SEGMENT RAW Uchitelle.WAV"
    - embed metadata accroding to Archives protocol


- Complication: 115 "Project" files saved as multi-chunk wave files --need to export as valid WAV:
  1. Open "Project" file in DAVID MultiTrack editor
  2. Go to "SingleTrack" tab
  3. Place files one after another
  4. Export as .AAF
  5. Open AAF in ProTools; check that files are _copied_, not just referenced
  6. Save as PT session - files will now be in Audio Files subfolder of the PT session

- NOTE: No files longer than five minutes have any substantial descriptions (REMARK) in DAVID
 



