# Duplicate management
Duplicate files are wasteful and expensive. We know that NYPR's internal audio file storage system, DAVID, holds many thousands of 'duplicate' WAVE files. It is best practice that we de-dupe these files before importing them into the new DAMS system, Cortex. How to go about it?

Successful duplicate managament involves
1. A definition of duplicates
2. A way to identify them
3. A process to de-dupe

Let's look at these processes in turn.

## 1. Duplicate definition

We can define two files as duplicate if they **share a particular attribute** or set of attributes. 

Different systems choose different attributes. For example, most operating systems will treat these two files as duplicate:
* ```C:/myDrive/myfile.txt```
* ```C:/myDrive/MYFILE.txt```

That is, the filenames cannot have the same 'letters', regardless of capitalization.

**For NYPR assets, we propose we consider two files as duplicate if they share _both_ of the following attributes:**
   * **a. Sonic content**
   * **b. Published metadata**


#### a. Sonic content
BWF MetaEdit can [generate an MD5 hash](https://mediaarea.net/BWFMetaEdit/md5) to determine if the audio content in two files is identical, regardless of other data in the file. BWF MetaEdit can embed this MD5 hash in the file, and can also verify the data.

Ffmpeg can generate the same hash, provided one uses [specific options](https://superuser.com/questions/1044413/audio-md5-checksum-with-ffmpeg).

_(Incidentally, we have evaluated other possible attributes and combinations, including: filesize; file length in miliseconds; embedded UMID; filenames; UMIDs in sidecar DBX files; etc., but they all seem to produce false positives or false negatives for our purposes.)_

#### b. Published metadata
DAVID's 'theme' links an audio file to the the station's CMS, Publisher, which holds metadata of interest. So it behooves us to treat two such files as essentially different, even if they are sonically identical.

The 'theme' can be extracted from the DAVID sidecar .DBX file.

## 2. Duplicate identification
As of April 2023, all valid WAVE files in archives-managed DAVID subfolders (plus 'News Broadcast Archives' and 'News in Progress Archives') currently have an audio-only MD5 hash embedded. The metadata for all files has then been exported as xml documents, one for each DAVID subfolder.

```DAVIDDupesByMD5.xsl``` identifies files with matching audio-only MD5s in those exported documents. It then looks up the corresponding DAVID sidecar .DBX file.

As an example, ```DAVIDDupesByMD5.xsl``` has identified 2489 sets of duplicate files and potential excess files in the DAVID subfolder 'NewsBroadcastArchives'.

At the end of this document we include a partial sample output.

- [ ] TO DO: Group by theme/MOTIVE. 
- [ ] TO DO: Compare across folders.

## 3. De-duping
Different systems deal with potential duplicates in different ways. For example, when you download a file with into an 'identical' filepath, you may be asked to overwrite the previous file, or the systen may add some characters (e.g. '(1)') to the end of the file.

For example, within systems at the station:

- DAVID generates a new filepath with each new ingestion for each file
- The station's CMS overwrites files coming from DAVID with the same theme

Given two sonically identical files with matching 'theme' (our suggested definition for duplicate), **we propose we keep:**

1. **The file with most complete metadata in DAVID (largest sidecar .DBX file)**; failing that, 
2. **The file with most recently updated metadata in DAVID (most recent sidecar .DBX file)**; failing that,
3. **The file most recently created**

Once the script determies which files can be erased, their filepaths can be submitted for deletion to administrators.

#### Sample identical-MD5 document

Note the different level of metadata
```
<dupes count="2">
      <File>
         <Technical>
            <FileSize>936613576</FileSize>
            <Format>Wave</Format>
            <CodecID>0001</CodecID>
            <Channels>2</Channels>
            <SampleRate>44100</SampleRate>
            <BitRate>2116800</BitRate>
            <BitPerSample>24</BitPerSample>
            <Duration>00:58:59.729</Duration>
            <UnsupportedChunks>minf elm1 regn ovwf umid</UnsupportedChunks>
            <bext>Version 0</bext>
            <INFO>No</INFO>
            <Cue>No</Cue>
            <XMP>No</XMP>
            <aXML>No</aXML>
            <iXML>No</iXML>
            <MD5Stored>9D22A9AFFCF1C21C44EFFCEFD4252931</MD5Stored>
        </Technical>
         <ENTRY>
            <NUMBER>204</NUMBER>
            <FILESIZE>936613552</FILESIZE>
            <TITLE>WNYC-SCHK-2011-06-16- *DUPLICATE*British Folk_Kate Bush_Madeleine Peyroux</TITLE>
            <CREATOR>ITRUDEL</CREATOR>
            <TIMESTAMP>2011-10-28 18:23:22</TIMESTAMP>
         </ENTRY>
      </File>
      <File>
         <Technical>
            <FileSize>936613576</FileSize>
            <Format>Wave</Format>
            <CodecID>0001</CodecID>
            <Channels>2</Channels>
            <SampleRate>44100</SampleRate>
            <BitRate>2116800</BitRate>
            <BitPerSample>24</BitPerSample>
            <Duration>00:58:59.729</Duration>
            <UnsupportedChunks>minf elm1 regn ovwf umid</UnsupportedChunks>
            <bext>Version 0</bext>
            <INFO>No</INFO>
            <Cue>No</Cue>
            <XMP>No</XMP>
            <aXML>No</aXML>
            <iXML>No</iXML>
            <MD5Stored>9D22A9AFFCF1C21C44EFFCEFD4252931</MD5Stored>
        </Technical>
         <ENTRY>
            <NUMBER>203</NUMBER>
            <FILESIZE>936613552</FILESIZE>
            <TITLE>WNYC-SCHK-2011-06-16- British Folk_Kate Bush_Madeleine Peyroux</TITLE>
            <CREATOR>ITRUDEL</CREATOR>
            <TIMESTAMP>2011-10-28 18:23:22</TIMESTAMP>
            <REMARK>Engineer: Irene Trudel
A:In the late 1960s, as pop culture embraced the sounds of rock n roll, a group of British musicians - including Nick Drake, The Incredible String Band and Vashti Bunyan - turned to the pastoral roots of 19th century English folk music for inspiration. Rob Young, editor-at-large for UK's The Wire and author of the new book, &#x93;Electric Eden: Unearthing Britain&#x92;s Visionary Music&#x94; joins us to explain the mythic roots of modern folk.
B:After a 20 year wait, the British singer and songwriter Kate Bush finally received permission to include text from James Joyce's "Ulysses" in her song "The Sensual World." Irish music critic Siobhán Kane joins us on a most hallowed day for Joyce enthusiasts - Bloomsday - to explain.
C:Jazz songstress Madeleine Peyroux has garnered many a comparison to Billie Holiday- but her newest album, &#x93;Standing On The Rooftop,&#x94; shows a rootsy, Americana side that the singer hasn't shared before. She joins us to perform songs from this album.</REMARK>
         </ENTRY>
      </File>
   </dupes>
```