# Duplicate management
Duplicate files are wasteful and expensive. We know that NYPR's internal audio file storage system, DAVID, holds many thousands of 'duplicate' WAVE files. It is best practice that we de-dupe these files before importing them into the new DAMS system, Cortex. How to go about it?

Successful duplicate managament involves
1. A definition of duplicates
2. A way to identify them
3. A process to de-dupe

Let's look at these processes in turn.

## Duplicate definition

We can define two files as duplicate if they **share a particular attribute**. 

Different systems choose different attributes. For example, most operating systems will treat these two files as duplicate:
* ```C:/myDrive/myfile.txt```
* ```C:/myDrive/MYFILE.txt```

That is, the filenames cannot have the same 'letters', regardless of capitalization.

**For NYPR assets, we propose we consider two files as duplicate if they share the following characteristics:**
1. **Audio-only MD5**
2. **'theme' in DAVID**


#### Audio-only MD5s
BWF MetaEdit [provides a hash](https://mediaarea.net/BWFMetaEdit/md5) to determine if the audio in two files is identical, regardless of other data in the file. BWF MetaEdit can embed the MD5 hash in the file, and can also verify the data.

Ffmpeg can provide the same hash, provided one uses [specific options](https://superuser.com/questions/1044413/audio-md5-checksum-with-ffmpeg).

#### theme/MOTIVE
DAVID's 'theme' is used as a link to the the station's [web] Publisher, which can then have metadata of interest. So it behooves us to treat two such files as essentially different, even if they are sonically identical.

_(Incidentally, other possible attributes and combinations have been evaluated, including: filesize; file length in miliseconds; embedded UMID; filenames; UMIDs in sidecar DBX files; etc., but they all seem to produce false positives or false negatives for our purposes.)_

## Duplicate identification
All valid WAVE files in archives-managed DAVID subfolders (plus 'News Broadcast Archives' and 'News in Progress Archives') currently have an MD5 hash embedded. This metadata has then been exported as xmls, one for each DAVID subfolder.

DAVIDDupesByMD5.xsl identifies files with matching audio-only MD5s in those exported documents. 
- [ ] TO DO: Look up the corresponding DAVID sidecar .DBX file, particularly its theme/MOTIVE. 
- [ ] TO DO: Compare across folders.

## De-duping
Different systems deal with potential duplicates in different ways. For example, when you download a file with into an 'identical' filepath, you may be asked to overwrite the previous file, or the systen may add some characters (e.g. '(1)') to the end of the file.

For example, within systems at the station:

- DAVID generates a new filepath with each new ingestion for each file
- The station's CMS overwrites files coming from DAVID with the same theme

Given two sonically identical files with matching 'theme' (our suggested definition for duplicate), we propose we keep:

1. The file with most complete metadata in DAVID (largest sidecar .DBX file); failing that, 
2. The file with most recently updated metadata in DAVID (most recent sidecar .DBX file); failing that,
3. The file most recently created

Once the script determies which files can be erased, their filepaths can be submitted for deletion to administrators.
