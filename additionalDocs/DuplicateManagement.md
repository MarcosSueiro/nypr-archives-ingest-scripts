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

That is, the filenames cannot be the 'same', even if the actual characters are different.

For NYPR assets, we propose we consider two files as duplicate if they share the following characteristics:
1. Same audio-only MD5
2. If exisiting, same 'theme' (also known as 'MOTIVE') in DAVID
