# Duplicate management
Duplicate files are wasteful and expensive.
Successful duplicate managament involves
1. A definition of duplicates
2. A way to identify them
3. A process to de-dupe
## Duplicate definition

We can define two files *a*, *b* as duplicate if they **share a particular characteristic**. 

Different systems choose different characteristics: 
for example, most operating systems will treat these two files as duplicate:
* ```C:/myDrive/myfile.txt```
* ```C:/myDrive/MYFILE.txt```

That is, the filenames cannot have the same 'letters', regardless of capitalization.

For NYPR assets, we propose we consider two files as duplicate if they share the following characteristics:
1. Audio-only MD5
2. 'theme' (also known as 'MOTIVE') in DAVID

### Audio-only MD5s
BWF MetaEdit provides a hash to determine if the audio in two files is identical, regardless of other data in the file. Ffmpeg can provide the same information, provided some additional options are exercised.
Generating a hash can take a bit of time (on average, it takes BWF MetaEdit about one hour to embed MD5s in 1,000 NYPR files in the ISILON). Embed-AudioMD5.ps1 can help you divide large folders by the file's creation year. It will then embed the MD5 hash in the file, and can verify the data.
### theme/MOTIVE
DAVID's 'theme' is used as a link to the CMS, which can then have metadata of interest. So it behooves us to treat two such files as essentially different, even if they are sonically identical

Incidentally, other possible characteristics and combinations have been evaluated (including file length in miliseconds; embedded UMID; filenames; UMIDs in sidecar DBX files), but they all seem to produce false positives or false negatives for our purposes.

## Duplicate identification
All valid WAVE files in archives-managed DAVID folders currently have an MD5 hash embedded. This metadata has then been exported to a specific drive.
