<?xml version="1.0" encoding="UTF-8"?>
<!--This script transforms output from a file 
obtained through an exiftool command of the type

    exiftool -X -a -ext wav -struct -charset riff=utf8 "fileDirectory" > "output.xml"

checks against DBX, cavafy, the CMS and other sources
and outputs a new 'mergedFields' rdf.

Data for the fields is generated 
according to the following general priority:

1. Whatever is already written in the field
2. Whatever the well-formed filename suggests
  (using WNYC Archives naming convention
  "COLL-SERIES-YYYY-MM-DD-InstantiationNo[ Free text][ GENERATION].wav")
  e.g. WNYC-NOUE-199u-uu-uu-760361.3 Perlis on Ives WEB EDIT
3. Whatever is written in the cavafy catalog record, 
   pointed to by either the iXML ISRC field 
   or the XMP catalogURL field 
   (so it is very helpful to fill either of these fields in),
   e.g. https://cavafy.wnyc.org/assets/c5fb5a14-980b-4963-9de9-29dc3f8da74a
4. Whatever data exists in the DAVID DBX files
5. Info from cavafy's corresponding series entry,
   characterised by it srelation of type 'other'
   SRSLST
   e.g. https://cavafy.wnyc.org/assets/bf7bb1c5-1840-47cf-ae09-83b36ea4135f
5. (In progress) Info from the station's CMS,
   accessed via its API
   e.g. http://www.wnyc.org/story/charles-ives-as-viewed-by-vivian-perlis
6. Data from the American Archive web site
   e.g. https://americanarchive.org/catalog/cpb-aacip_510-3n20c4t76x
7. Default or boilerplate language -->

<!-- The script checks for conflicts or merges,
depending on various factors.

Fields that must be consistent include:
Collection / IARL
Copyright / ICOP
Unique date /ICRD
Genre / IGNR
Medium /IMED
Title / INAM
Series / IPRD
Abstract / ISBJ
Software /ISFT
Source / ISRC (this may change)
Provenance / ISRF
Transfer tech / ITCH

Fields that are merged include:
Contributors / IART
Creators and publishers / ICMS
Comments / ICMT
Engineers / IENG
Subject headings / IKEY
-->

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:XMP="http://ns.exiftool.ca/XMP/XMP/1.0/"
    xmlns:XMP-x="http://ns.exiftool.ca/XMP/XMP-x/1.0/"
    xmlns:XMP-xmp="http://ns.exiftool.ca/XMP/XMP-xmp/1.0/"
    xmlns:XMP-xmpDM="http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/"
    xmlns:XMP-xmpMM="http://ns.exiftool.ca/XMP/XMP-xmpMM/1.0/"
    xmlns:XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/"
    xmlns:XMP-WNYCSchema="http://ns.exiftool.ca/XMP/XMP-WNYCSchema/1.0/"
    xmlns:XMP-exif="http://ns.exiftool.ca/XMP/XMP-exif/1.0/" xmlns:lc="http://www.loc.gov/"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:et="http://ns.exiftool.ca/1.0/" et:toolkit="Image::ExifTool 10.82"
    xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/"
    xmlns:XMP-plus="http://ns.exiftool.ca/XMP/XMP-plus/1.0/"
    xmlns:XML="http://ns.exiftool.ca/XML/XML/1.0/" xmlns:WNYC="http://www.wnyc.org"
    xmlns:ASCII="https://www.ecma-international.org/publications/standards/Ecma-094.htm"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    default-collation="http://www.w3.org/2013/collation/UCA?ignore-symbols=yes;strength=primary"
    exclude-result-prefixes="#all">

    <xsl:mode on-no-match="deep-skip"/>
    <xsl:output indent="yes" encoding="UTF-8"/>

    <xsl:import href="Exif2BWF.xsl"/>
    <xsl:import href="Exif2Cavafy.xsl"/>
    <xsl:import href="Exif2Dbx.xsl"/>
    <xsl:import href="cms2BWFMetaEdit.xsl"/>
    <xsl:import href="cavafyQC.xsl"/>
    
    <xsl:param name="checkDAVIDForDupes" select="true()"/>
    <xsl:param name="utilityLists" select="doc('utilityLists.xml')"/>
    <xsl:param name="playbackParameters" select="
        $utilityLists/utilityLists/playbackParameters"/>
    
    <xsl:variable name="illegalCharacters">
        <xsl:text>&#x201c;&#x201d;&#xa0;&#x80;&#x93;&#x94;&#xa6;&#x2014;&#x2019;&#x2122;&#x2026;&#x201a;</xsl:text>
        <xsl:text>&#xc2;&#xc3;&#xb1;&#xe2;&#x99;&#x9c;&#x9d;&#x20ac;&#xac;</xsl:text>
    </xsl:variable>
    <xsl:variable name="legalCharacters">
        <xsl:text>"" '——…—''…'</xsl:text>
    </xsl:variable>
    <xsl:variable name="ISODatePattern"
        select="
            '^([0-9]{4})-?(1[0-2]|0[1-9])-?(3[01]|0[1-9]|[12][0-9])$'"/>

    <xsl:variable name="CMSShowList" select="doc('Shows.xml')"/>
    <xsl:variable name="CMSRoles" select="doc('file:CMSRoles.xml')"/>

    <xsl:variable name="illegalFileTypes" select="'RF64'"/>
    <xsl:variable name="validFormats" select="
        $utilityLists/utilityLists/validFormats"/>
    
    <xsl:variable name="digitalFormats">
        <xsl:value-of select="
            $validFormats/format[signalCapture = 'Analog']/
            formatName" separator="|"/>
    </xsl:variable>
    <xsl:variable name="analogFormats">
        <xsl:value-of select="
            $validFormats/format[signalCapture = 'Digital']/
            formatName" separator="$|^"/>
    </xsl:variable>
    <xsl:variable name="physicalFormats">
        <xsl:value-of select="
            $validFormats/format[formatType = 'FormatPhysical']/
            formatName" separator="$|^"/>
    </xsl:variable>
    <xsl:variable name="validatingCatalogString"
        select="
            'https://cavafy.wnyc.org'"/>
    <xsl:variable name="validatingCatalogDirectURLString"
        select="
        'https://cavafy.wnyc.org/assets/[a-z0-9\-]+'"/>
    <xsl:variable name="validatingCatalogSearchString"
        select="
        'https://cavafy.wnyc.org.*\?q='"/>
    <xsl:variable name="validatingKeywordString"
        select="
            'id.loc.gov/authorities/subjects/'"/>
    <xsl:variable name="validatingNameString" select="
            'id.loc.gov/authorities/names/'"/>
    <xsl:variable name="combinedValidatingStrings"
        select="
            string-join(
            ($validatingKeywordString, 
            $validatingNameString)
            , '|')"/>
    <xsl:variable name="separatingToken" select="';'"/>
    <xsl:variable name="separatingTokenLong"
        select="
            concat(' ', $separatingToken, ' ')"/>
    <!-- To avoid semicolons separating a single field -->
    <xsl:variable name="separatingTokenForFreeTextFields" select="'###===###'"/>
    <!-- These transfer techs 
        indicate that the file 
        was produced by the NYPR Archives -->
    <xsl:variable name="archivesAuthors">
        <xsl:value-of select="
                $utilityLists/
                utilityLists/
                archivesAuthors/
                archivesAuthor" separator="|"/>
    </xsl:variable>
    
    <!-- If we want to *exactly* match the archives author,
    use this variable -->
    <xsl:variable name="archivesAuthorsRegex"
        select="
            translate(
            concat('^',
            replace(
            $archivesAuthors, '\|', '\$|^'), '$'), ' ', '')"/>
    <xsl:variable name="instantiationIDsInDAVID" select="
        doc('file:/T:/02 CATALOGING/DAVIDLists/instantiationIDsInDAVID.xml')"/>

    <xsl:template match="rdf:RDF[rdf:Description]">
        <xsl:apply-templates select="rdf:Description[System:FileName]"/>
    </xsl:template>


    <xsl:template match="rdf:Description[System:FileName]">
        <!-- Match standard exif output -->
        <xsl:param name="originalExif" select="."/>

        <xsl:param name="welcomeMessage">
            <xsl:message select="
                    'Process file ',
                    $originalExif/System:FileName[1]"/>
        </xsl:param>
        <xsl:param name="checkDAVIDForDupes" select="
                $checkDAVIDForDupes"/>

        <!-- Make sure exiftool output 
            is structured xml -->
        <xsl:param name="checkXMPFormat">
            <xsl:apply-templates select="
                    $originalExif/
                    (XMP-xmpMM:* | XMP-xmpDM:*)" mode="
                checkXMPFormat"/>
        </xsl:param>

        <xsl:param name="illegalFileError">
            <xsl:apply-templates select="
                    $originalExif
                    [matches(File:FileType,
                    $illegalFileTypes, 'i')
                    ]"/>
        </xsl:param>
        <xsl:param name="isNewAsset" as="xs:boolean">
            <xsl:apply-templates select="
                $originalExif" mode="isNewAsset"/>
        </xsl:param>
        <!--<xsl:param name="entryType">
            <xsl:value-of
                select="
                    lower-case(
                    $originalExif/
                    RIFF:Source[matches(., 'NEW', 'i')])"/>
            <xsl:value-of
                select="
                    'update'
                    [$originalExif/
                    RIFF:Source[not(matches(., 'NEW', 'i'))]]"/>
            <xsl:value-of select="'_'"/>
            <xsl:value-of
                select="
                    lower-case(
                    $originalExif/
                    File:FileType)"
            />
        </xsl:param>-->

        <xsl:param name="directory">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="'fileDirectory'"/>
                <xsl:with-param name="field1" select="
                        $originalExif/System:Directory[1]"/>
                <xsl:with-param name="field2">
                    <xsl:value-of select="
                            WNYC:substring-before-last-regex(
                            $originalExif/@rdf:about,
                            '/|\\')"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="isInDAVID" select="
                contains($directory, 'wnycdavidmedia')"/>

        <xsl:param name="filename">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="'fileName'"/>
                <xsl:with-param name="field1">
                    <xsl:value-of select="
                            $originalExif/System:FileName[1]"/>
                </xsl:with-param>
                <xsl:with-param name="field2">
                    <xsl:value-of select="
                            tokenize(
                            $originalExif/@rdf:about,
                            '/|\\')[last()]"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="filenameNoExt">
            <xsl:value-of select="
                    WNYC:substring-before-last(
                    $filename,
                    concat('.',
                    $originalExif/File:FileTypeExtension)
                    )"/>
        </xsl:param>
        <xsl:param name="fileType">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="'fileType'"/>
                <xsl:with-param name="field1" select="
                        $originalExif/File:FileType"/>
                <xsl:with-param name="field2" select="
                        $originalExif/File:FileTypeExtension"/>
                <xsl:with-param name="field3">
                    <xsl:value-of select="
                            tokenize(
                            $originalExif/@rdf:about,
                            '\.'
                            )[last()]"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="isAsset" select="
                matches($fileType, 'asset', 'i')"/>
        <xsl:param name="isPhysical" select="
                matches($fileType, $physicalFormats)"/>
        <xsl:param name="isDigital" select="
                matches($fileType, $digitalFormats, 'i')"/>

        <!-- Obtain DBX data -->
        <xsl:param name="dbxData">
            <xsl:apply-templates select="
                    $originalExif[$isInDAVID]" mode="
                DAVIDdbx"/>
        </xsl:param>
        <xsl:param name="isDeleted" select="
                $dbxData//SOFTDELETED = '1'"/>

        <!-- Is the file produced by the Archives Dept? -->
        <xsl:param name="archivesProduced" select="
                contains($originalExif/System:Directory[1], 'ARCHIVESNAS1/INGEST/') or
                matches($originalExif/(RIFF:Originator | RIFF:Technician), $archivesAuthors) or
                matches($dbxData/ENTRIES/ENTRY/(AUTHOR | CREATOR), $archivesAuthors) or
                starts-with($dbxData/ENTRIES/ENTRY/MOTIVE, 'archive_import') or
                matches($originalExif/System:FileName[1], 'ARCH-DAW') or
                contains($originalExif/RIFF:Source, 'cavafy')" as="xs:boolean"/>

        <!-- If the file comes from Archives,
        check its naming convention
        and then parse it -->
        <xsl:param name="filenameToParse">
            <!-- If file is not in DAVID, use its filename -->            
            <xsl:value-of select="$filename[not($isInDAVID)]"/>
            <!-- If file is in DAVID and produced by the Archives, 
                use RIFF:Description -->
            <xsl:value-of select="
                    concat(
                    $originalExif/RIFF:Description, '.',
                    $fileType)
                    [$isInDAVID]
                    [$archivesProduced]
                    "/>
        </xsl:param>
        <xsl:param name="checkedDAVIDTitle">
            <xsl:apply-templates select="
                    $originalExif
                    [$archivesProduced]
                    [not($isDeleted)]/
                    System:FileName[1]" mode="
                checkDAVIDTitle">
                <xsl:with-param name="filenameToParse" select="
                        $filenameToParse"/>
            </xsl:apply-templates>
        </xsl:param>
        <xsl:param name="parsedDAVIDTitle">
            <xsl:apply-templates select="
                    $originalExif
                    [$archivesProduced]
                    [not($isDeleted)]/
                    System:FileName[1]" mode="
                parseDAVIDTitle">
                <xsl:with-param name="filenameToParse" select="
                        $filenameToParse"/>
                <xsl:with-param name="checkedDAVIDTitle" select="
                        $checkedDAVIDTitle"/>
                <xsl:with-param name="isNew" select="$isNewAsset"/>
            </xsl:apply-templates>
        </xsl:param>

        <xsl:param name="instantiationFirstTrack" select="
                $parsedDAVIDTitle//instantiationFirstTrack"/>
        <xsl:param name="isMultitrack" select="
                $parsedDAVIDTitle//@isMultiTrack" as="xs:boolean?"/>

        <!-- Only check CMS every eight tracks -->
        <!-- Multitrack info 
            comes in bunches of eight -->
        <xsl:param name="getCMSData" select="
                not($isMultitrack)
                or
                (number($instantiationFirstTrack)
                mod 8 = 1)"/>

        <!-- Check that an entry
            with the same instantiation ID
            does not already exist in DAVID 
            (optional but a good idea) -->
        <xsl:param name="
            instantiationsAlreadyInDAVID">
            <xsl:apply-templates select="
                    $parsedDAVIDTitle
                    /parsedDAVIDTitle
                    /parsedElements[$checkDAVIDForDupes]" mode="checkDAVIDForDupes"/>
        </xsl:param>

        <xsl:message>
            <xsl:value-of select="
                    'Is new asset: ', $isNewAsset, '.'"/>
            <xsl:value-of select="
                    'Is physical: ', $isPhysical, '.'"/>
            <xsl:value-of select="
                    'Is digital: ', $isDigital, '.'"/>
            <xsl:value-of select="
                    'In DAVID:', $isInDAVID, '. '"/>
            <xsl:value-of select="
                    'Is deleted: ', $isDeleted, '.'"/>
            <xsl:value-of select="
                    'Archives produced:',
                    $archivesProduced, '. '"/>
            <xsl:value-of select="
                    count($instantiationIDsInDAVID//error),
                    ' duplicate instantiation IDs in DAVID'"/>
        </xsl:message>

        <xsl:if test="$archivesProduced and not($isDeleted)">
            <!-- The cavafy entry corresponding to the file -->
            <!-- Check that this entry is acceptable -->
            <xsl:variable name="cavafyEntry">
                <xsl:apply-templates select="
                        $parsedDAVIDTitle
                        /parsedDAVIDTitle
                        /parsedElements
                        /finalCavafyEntry
                        /pb:pbcoreDescriptionDocument" mode="cavafyQC"/>
            </xsl:variable>

            <xsl:variable name="showName" select="
                    $cavafyEntry//
                    pb:pbcoreTitle
                    [@titleType = 'Series']"/>

            <xsl:variable name="bcastDateAsText" select="
                    min($cavafyEntry//
                    pb:pbcoreAssetDate
                    [@dateType = 'broadcast']
                    /normalize-space(.))"/>
            <xsl:variable name="date" select="
                    xs:date(min($bcastDateAsText
                    [matches(., $ISODatePattern)])
                    )"/>

            <!-- Potential duplicate assets -->
            <!-- Defined as 'same series, same date' -->
            <!-- Except for 'News' and 'Miscelleaneous' -->
            <xsl:variable name="potentialDupes">
                <xsl:apply-templates select="
                        $parsedDAVIDTitle
                        /parsedDAVIDTitle
                        /parsedElements
                        /finalCavafyEntry
                        /pb:pbcoreDescriptionDocument
                        [not($showName = 'News')]
                        [not($showName = 'Miscellaneous')]
                        [matches($bcastDateAsText, $ISODatePattern)]"
                    mode="sameDateAndSeries">
                    <xsl:with-param name="instantiationToMerge" select="
                            $parsedDAVIDTitle/parsedDAVIDTitle
                            /parsedElements/instantiationID"/>
                </xsl:apply-templates>
            </xsl:variable>

            <xsl:variable name="showSlug">
                <xsl:apply-templates select="
                        $cavafyEntry//
                        pb:pbcoreTitle[@titleType = 'Series']" mode="
                    generateShowSlug"/>
            </xsl:variable>

            <!-- Obtain CMS web site data via the WNYC API 
        See https://nyprpublisher.docs.apiary.io/# for info -->
            <xsl:variable name="DAVIDTheme" select="
                    $dbxData/ENTRIES/ENTRY/MOTIVE"/>
            <xsl:variable name="cmsData">
                <xsl:choose>
                    <xsl:when test="
                            $getCMSData and
                            matches($showSlug, '\w') and
                            matches($bcastDateAsText, $ISODatePattern)">
                        <xsl:message select="
                                'Get CMS data from slug and date',
                                $showSlug, $bcastDateAsText"/>
                        <xsl:call-template name="getCMSData">
                            <xsl:with-param name="date" select="$date"/>
                            <xsl:with-param name="showSlug" select="$showSlug"/>
                            <xsl:with-param name="minRecords" select="0"/>
                            <xsl:with-param name="maxRecords" select="20"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="
                            $getCMSData and
                            matches($DAVIDTheme, '\w')
                            and
                            not(starts-with($DAVIDTheme, 'news_latest_newscast'))
                            and
                            not(starts-with($DAVIDTheme, 'archive_import'))
                            ">
                        <xsl:message select="
                                'Get CMS data from theme/motive',
                                $DAVIDTheme"/>
                        <xsl:apply-templates select="$DAVIDTheme" mode="
                            getCMSData">
                            <xsl:with-param name="minResults" select="1"/>
                            <xsl:with-param name="maxResults" select="1"/>
                        </xsl:apply-templates>
                    </xsl:when>

                    <!--<xsl:when test="
                            $getData and
                            matches($builtMP3, '\w+\d+')">
                        <xsl:call-template name="getCMSData">
                            <xsl:with-param name="theme" select="$builtMP3"/>
                            <xsl:with-param name="exactMP3" select="false()"/>
                            <xsl:with-param name="minRecords" select="0"/>
                            <xsl:with-param name="maxRecords" select="5"/>
                        </xsl:call-template>
                    </xsl:when>-->

                </xsl:choose>
            </xsl:variable>



            <!-- The corresponding instantiation  -->
            <xsl:variable name="instantiationData">
                <xsl:apply-templates select="
                        $parsedDAVIDTitle/
                        parsedElements/
                        instantiationData"/>
            </xsl:variable>

            <!-- Cavafy series data,
                with information often used as default -->
            <xsl:variable name="seriesData">
                <xsl:copy-of select="$parsedDAVIDTitle//parsedElements/seriesData"/>
            </xsl:variable>

            <xsl:variable name="allInputs">
                <inputs>
                    <xsl:element name="originalExif">
                        <xsl:copy-of select="$originalExif"/>
                    </xsl:element>
                    <xsl:element name="dbxData">
                        <xsl:copy-of select="$dbxData"/>
                    </xsl:element>
                    <xsl:copy-of select="$parsedDAVIDTitle"/>
                    <xsl:copy-of select="$cavafyEntry"/>
                    <xsl:copy-of select="$potentialDupes"/>
                    <xsl:copy-of select="$instantiationsAlreadyInDAVID"/>
                    <xsl:copy-of select="$seriesData"/>
                    <xsl:copy-of select="$instantiationData"/>
                    <xsl:copy-of select="$cmsData"/>
                </inputs>
            </xsl:variable>
            <xsl:variable name="newExif">
                <newExif>
                    <xsl:apply-templates select="
                            $allInputs/inputs" mode="newExif"/>
                </newExif>
            </xsl:variable>
            <result>
                <xsl:attribute name="filename" select="
                        $originalExif/System:FileName[1]"/>
                <xsl:copy-of select="$allInputs"/>
                <xsl:copy-of select="$newExif"/>
            </result>
        </xsl:if>
    </xsl:template>

    <xsl:template match="(XMP-xmpMM:* | XMP-xmpDM:*)" mode="checkXMPFormat">
        <!-- Make sure exiftool XMP output is structured -->
        <xsl:param name="flagNames" select="'History|DerivedFrom|Tracks|Bwfxml'"/>
        <xsl:param name="localName" select="local-name()"/>
        <xsl:param name="flagNamesExact"
            select="
                translate(
                concat('^',
                replace(
                $flagNames, '\|', '\$|^'), '$'), ' ', '')"/>
        <xsl:param name="includesFlaggedName" select="matches($localName, $flagNames)"/>
        <xsl:param name="matchesFlaggedNameExactly" select="matches($localName, $flagNamesExact)"/>

        <xsl:if test="$includesFlaggedName and not($matchesFlaggedNameExactly)">
            <xsl:message terminate="yes"
                select="
                    'WRONG EXIFTOOL OUTPUT: ',
                    'Field', '_', $localName, '_',
                    'suggests that exiftool is not outputting structured XMP.',
                    ' Please make sure your exiftool parameters are: ',
                    '    exiftool -X -a -ext wav -struct -charset riff=utf8'"
            />
        </xsl:if>
        <xsl:message select="'XMP Output is valid'"/>
    </xsl:template>

    <xsl:template name="newExif" match="inputs" mode="newExif">
        <!-- Generate a new rdf:Description document 
        by merging and checking various sources -->
        <xsl:param name="occupationsAreSubjects" select="false()"/>
        <!-- Change if you want to include 
            contributors' and subjects' occupations 
        as subject headings -->
        <xsl:param name="originalExif" select="
                /inputs/originalExif"/>
        <xsl:param name="parsedDAVIDTitle" select="
                /inputs/parsedDAVIDTitle"/>
        <xsl:param name="inDAVID" select="inDAVID"/>
        <xsl:param name="isDub" select="
            not($originalExif/rdf:Description/RIFF:Medium
            = 'Original')"/>
        <xsl:param name="isNewAsset" as="xs:boolean">
            <xsl:apply-templates select="$originalExif" mode="isNewAsset"/>
        </xsl:param>
        <xsl:param name="isPhysical" select="
            matches($originalExif/rdf:Description/File:FileType, $physicalFormats)"/>
        
        <xsl:param name="originalFilename">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="'originalFileName'"/>
                <xsl:with-param name="field1">
                    <xsl:value-of select="
                        $originalExif/rdf:Description/System:FileName[1]"/>
                </xsl:with-param>
                <xsl:with-param name="field2">
                    <xsl:value-of select="
                        tokenize(
                        $originalExif/rdf:Description/@rdf:about,
                        '/|\\')[last()]"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="cavafyEntry"
            select="
                /inputs
                /parsedDAVIDTitle/parsedElements
                /finalCavafyEntry"/>
        <xsl:param name="instantiationID"
            select="
            /inputs
            /parsedDAVIDTitle/parsedElements
            /instantiationID"/>
        <xsl:param name="seriesData"
            select="
                /inputs
                /parsedDAVIDTitle/parsedElements
                /seriesData"/>
        <xsl:param name="instantiationData"
            select="
                /inputs
                /parsedDAVIDTitle/parsedElements
                /pb:instantiationData"/>
        <xsl:param name="dbxData" select="
                /inputs/dbxData"/>
        <xsl:param name="cmsData" select="
                /inputs/cmsData"/>
        <xsl:param name="validatingCatalogString" select="
                $validatingCatalogString"/>
        <xsl:param name="validatingKeywordString" select="
                $validatingKeywordString"/>
        <xsl:param name="validatingNameString" select="
                $validatingNameString"/>
        <xsl:param name="fileType"
            select="
                $originalExif/
                rdf:Description/
                File:FileType"/>
        <xsl:param name="isDigital" select="
            matches($fileType, $digitalFormats, 'i')"/>
        <xsl:param name="instantiationSegmentSuffix"
            select="
            $parsedDAVIDTitle/
            parsedElements/instantiationSegmentSuffix"/>
        <xsl:param name="segmentFlag"
            select="
            $parsedDAVIDTitle/
            parsedElements/segmentFlag"/>
        <xsl:param name="instantiationFirstTrack"
            select="
            $parsedDAVIDTitle/           
            parsedElements/instantiationFirstTrack[matches(string(.), '^\d+$')]"
            as="xs:integer?"/>
        <xsl:param name="instantiationLastTrack"
            select="
            $parsedDAVIDTitle/
            parsedElements/instantiationLastTrack[matches(string(.), '^\d+$')]"
            as="xs:integer?"/>
        <xsl:param name="isMultitrack" select="
            $instantiationFirstTrack gt 0"/>
        <xsl:param name="mergingMessage">
            <xsl:message> ******** GENERATE NEW COMBINED EXIF *********</xsl:message>
        </xsl:param>
        <xsl:param name="cmsArticle" select="
            $cmsData/data/
            attributes[item-type='article']"/>
        <xsl:param name="cmsEpisode" select="
            $cmsData/data/
            attributes[item-type='episode']"/>
        <xsl:param name="cmsIsSegmented" select="
            boolean(
            $cmsData/data/
            attributes/segments[slug])"/>
        <xsl:param name="cmsSegments">
            <!-- Segments in an episode, in order -->
            <xsl:for-each select="$cmsData//
                data/attributes/
                segments/slug">
                <xsl:sort select="preceding-sibling::segment-number[1]"/>
                <xsl:variable name="segmentSlug" select="."/>
                <segment>
                    <xsl:attribute name="segment-number" select="preceding-sibling::segment-number[1]"/>
                    <xsl:copy-of select="$cmsData//data/
                        attributes
                        [item-type='segment']
                        [slug=$segmentSlug]"/>
                </segment>
            </xsl:for-each>
        </xsl:param>

        <!-- LET THE MERGING BEGIN -->

        <!-- Basics -->
        
        <xsl:param name="assetID">
            <xsl:value-of select="$parsedDAVIDTitle/
                parsedElements/assetID[not($isNewAsset)]"/>
            <xsl:apply-templates select="
                $parsedDAVIDTitle/
                parsedElements/
                assetID[$isNewAsset]" mode="
                generateNewAssetID"/>
        </xsl:param>
        
        <xsl:param name="directory">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="'fileDirectory'"/>
                <xsl:with-param name="field1" select="
                    $originalExif/rdf:Description/System:Directory[1]"/>
                <xsl:with-param name="field2">
                    <xsl:value-of select="
                        WNYC:substring-before-last-regex(
                        $originalExif/rdf:Description/@rdf:about,
                        '/|\\')"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:param>
        
        <xsl:param name="DAVIDTitle">
            <xsl:choose>
                <xsl:when test="contains($fileType, 'ASSET')">
                    <xsl:value-of select="
                        $originalExif/rdf:Description/System:FileName[1]"/>
                </xsl:when>
                <xsl:when test="$isNewAsset">
                    <xsl:variable name="updatedDAVIDTitle">
                        <xsl:call-template name="generateNextFilename">
                            <xsl:with-param name="instantiationID" select="$instantiationID"/>
                            <xsl:with-param name="message">
                                <xsl:message select="
                                    'Generate new filename for instantiation ID ',
                                    $instantiationID,
                                    ' using Asset ID ', $assetID"
                                />
                            </xsl:with-param>
                            <xsl:with-param name="assetID" select="$assetID"/>
                            <xsl:with-param name="foundAsset"/>
                            <xsl:with-param name="foundInstantiation"/>
                            <xsl:with-param name="collection" select="
                                $parsedDAVIDTitle/parsedElements/collectionAcronym"/>
                            <xsl:with-param name="seriesXML"/>
                            <xsl:with-param name="seriesAcronym" select="
                                $parsedDAVIDTitle/parsedElements/seriesAcronym"/>
                            <xsl:with-param name="filenameDate" select="
                                $parsedDAVIDTitle/parsedElements/DAVIDTitleDate"/>
                            <xsl:with-param name="instantiationIDOffset" select="0"/>
                            <xsl:with-param name="nextInstantiationSuffixDigit" select="
                                $parsedDAVIDTitle/parsedElements/instantiationSuffixDigit"/>
                            <xsl:with-param name="freeTextOtherAssetIDs"/>
                            <xsl:with-param name="freeTextShortenedTitle"/>
                            <xsl:with-param name="freeTextComplete" select="
                                $parsedDAVIDTitle/parsedElements/freeText"
                            />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:value-of select="
                        normalize-space(
                        $updatedDAVIDTitle/pb:inputs/pb:parsedDAVIDTitle/@DAVIDTitle)"/>                    
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="
                        tokenize($originalFilename, '\.')
                        [not(position() = last())]" separator="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        
        <xsl:param name="filename">
            <xsl:value-of select="$DAVIDTitle"/>
            <xsl:value-of select="'.'"/>
            <xsl:value-of select="'00.'[contains($fileType, 'ASSET')]"/>
            <xsl:value-of select="
                $originalExif/rdf:Description/
                File:FileTypeExtension"/>            
        </xsl:param>
        
        <xsl:param name="fullFilePath">
            <xsl:value-of select="$directory"/>
            <xsl:value-of select="'/'"/>
            <xsl:value-of select="$filename"/>
        </xsl:param>
        

        <!-- MUNI ID -->
        <xsl:param name="MuniID">
            <xsl:apply-templates select="." mode="checkConflicts">
                <xsl:with-param name="field1"
                    select="
                        $parsedDAVIDTitle/parsedElements/muniNumber"/>
                <xsl:with-param name="field2"
                    select="
                        $cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreIdentifier[@source = 'Municipal Archives']"/>
                <xsl:with-param name="fieldName" select="'MuniID'"/>
            </xsl:apply-templates>
        </xsl:param>


        <!-- Generation -->
        <!-- Note: If 'Generation' includes 'segment', 
            this has consequences for the treatment of metadata.
        Specifically:
         * Embedded IART, ICMS, IKEY are not merged with 
         pbcoreContributor, pbcoreCreator and pbcoreSubject respectively; 
        but, if empty, the values come from pbcore
         * Embedded IGNR takes precedence over pbcoreGenre;
         but, if empty, the value comes from pbcore
         * Embedded INAM takes precedence over 
         pbcoreTitle[@titleType='Episode'];
         but, if empty, will append ", part [segmentsuffix]" to  
         pbcoreTitle. (E.g. 'Ravi Shankar, part b')  
         * Embedded ISBJ takes precedence over 
         pbcoreDescription[@descriptionType='Abstract'];
         but, if empty, will prepend "Part [segmentsuffix] of:" to  
         pbcoreDescription. 
         (E.g. 'Part b of: Interview and concert with Ravi Shankar')
        -->
        <xsl:param name="parsedGeneration"
            select="
                $parsedDAVIDTitle
                /parsedElements/parsedGeneration"/>
        <xsl:param name="parseGenerationMessage">
        <xsl:message select="'Parsed generation:', $parsedGeneration"/>
        </xsl:param>
        <xsl:param name="physicalGeneration">
            <xsl:value-of select="'Audio/Original recording'[not($isDub)]"/>
            <xsl:value-of select="'Audio/Audio dub'[$isDub]"/>
        </xsl:param>
        <xsl:param name="generation">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="'Generation'"/>
                <xsl:with-param name="field1" select="
                        $parsedGeneration[not($isPhysical)], $physicalGeneration[$isPhysical]"/>                
                <xsl:with-param name="field2"
                    select="
                        $instantiationData
                        /pb:pbcoreInstantiation
                        /pb:instantiationGenerations"/>                
            </xsl:call-template>
        </xsl:param>
        
        <xsl:message select="'Generation: ', $generation"/>
        <xsl:variable name="isSegment" select="
            contains($generation, 'segment')"/>
        <xsl:message select="'Is segment: ', $isSegment"/>
        <xsl:message select="'Is multitrack: ', $isMultitrack"/>
        <xsl:message select="'Is physical: ', $isPhysical"/>

        <xsl:variable name="producingOrganizations">
            <!-- Culled from CMS data -->
            <xsl:choose>
                <xsl:when
                    test="
                        $cmsData
                        /data/attributes/
                        producing-organizations">
                    <xsl:value-of
                        select="
                            distinct-values(
                            $cmsData
                            /data/attributes
                            /producing-organizations/name)"
                        separator="{$separatingTokenLong}"/>
                </xsl:when>
                <xsl:when
                    test="
                        $cmsData
                        /data/attributes
                        /npr-analytics-dimensions
                        [contains(lower-case(./*), 'wnyc')]">
                    <xsl:message>NPR analytics!</xsl:message>
                    <xsl:value-of select="'WNYC'"/>
                </xsl:when>
                <xsl:when
                    test="
                        $cmsData
                        /data/attributes
                        /npr-analytics-dimensions
                        [contains(lower-case(./*), 'wqxr')]">
                    <xsl:message>NPR analytics!</xsl:message>
                    <xsl:value-of select="'WQXR'"/>
                </xsl:when>
                <xsl:when
                    test="
                        contains(
                        $cmsData
                        /data/attributes/
                        headers/brand/url,
                        'wqxr')"
                    >WQXR</xsl:when>
                <xsl:when
                    test="
                        contains(
                        $cmsData
                        /data/attributes
                        /headers/brand/url,
                        'wnyc')"
                    >WNYC</xsl:when>
            </xsl:choose>
        </xsl:variable>

        <!--1. Collection (and archival location) 
            as RIFF:ArchivalLocation-->
        <!--Embedded collection is of the type 'US, WNYC' 
                    So we look after the country code -->
        <xsl:variable name="exifCollection"
            select="
                $originalExif
                /rdf:Description/RIFF:Collection
                /substring-after(., ',')"/>
        <xsl:variable name="collectionInfo"
            select="
                $parsedDAVIDTitle
                /parsedElements
                /collectionData
                /collectionInfo"/>
        <xsl:variable name="collectionURL"
            select="
                $collectionInfo
                /collURL"/>
        
        <xsl:variable name="collection">
            <xsl:if test="matches($producingOrganizations, '\w') and matches($exifCollection, '\w')">
                <xsl:call-template name="field1MustContainField2">
                    <xsl:with-param name="field1Name" select="'ProducingOrgs'"/>
                    <xsl:with-param name="field2Name" select="'exifCollection'"/>
                    <xsl:with-param name="field1" select="$producingOrganizations"/>
                    <xsl:with-param name="field2" select="$exifCollection"/>
                </xsl:call-template>
            </xsl:if>
            <xsl:apply-templates select="." mode="checkConflicts">
                <xsl:with-param name="fieldName" select="'Collection'"/>
                <xsl:with-param name="field1" select="
                        $exifCollection"/>
                <xsl:with-param name="field2" select="
                        $collectionInfo
                        /collAcro"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="collectionName">
            <xsl:value-of select="
                    $collectionInfo/collName"/>
        </xsl:variable>

        <xsl:variable name="collectionLocation">
            <xsl:value-of select="
                    $collectionInfo/collLocation"/>
        </xsl:variable>
        <xsl:variable name="producingOrgsParsed">
            <xsl:apply-templates select="
                $producingOrganizations
                [matches(., '\w')]
                [matches($collection, '\w')]" mode="
                splitParseValidate">
                <xsl:with-param name="validatingString" select="
                    $collection"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="additionalProducingOrgs">
            <xsl:value-of select="
                $producingOrgsParsed//invalid" separator="
                {$separatingToken}"/>
        </xsl:variable> 
        <xsl:variable name="RIFF:ArchivalLocation">
            <RIFF:ArchivalLocation>
                <xsl:copy-of select="$collection[//error]"/>
                <xsl:value-of
                    select="
                        concat(
                        $collectionLocation, ', ',
                        normalize-space(
                        $collection[not(//error)])
                        )"
                />
            </RIFF:ArchivalLocation>
        </xsl:variable>

        <!-- 2. Merge all Creators, Producers, Hosts, Publishers 
            as 'RIFF:Commissioned' -->
        <xsl:variable name="exiftoolCommissioned"
            select="
                $originalExif/rdf:Description/
                RIFF:Commissioned"/>
        <xsl:variable name="assetCreatorsPublishers">
            <xsl:value-of
                select="
                    $cavafyEntry/pb:pbcoreDescriptionDocument
                    /pb:*/(pb:creator | pb:publisher)
                    /@ref[matches(., $validatingNameString)]"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>

        <xsl:variable name="cmsPeople"
            select="
                $cmsData/data/attributes
                /appearances"/>
        <xsl:variable name="cmsCreators">
            <xsl:value-of
                select="
                    $cmsPeople/
                    (producers | authors | hosts)/
                    name"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>

        <xsl:variable name="seriesCreatorsPublishers">
            <xsl:value-of
                select="
                    $seriesData/pb:pbcoreDescriptionDocument
                    /pb:*/(pb:creator | pb:publisher)
                    /@ref[matches(., $validatingNameString)]"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>

        <xsl:message
            select="
                'seriesCreatorsPublishers: ',
                $seriesCreatorsPublishers"/>

        <xsl:variable name="defaultCreatorsPublishers">
            <xsl:value-of
                select="
                    if
                    ($seriesCreatorsPublishers != '')
                    then
                        $seriesCreatorsPublishers
                    else
                        $collectionURL"
                separator=" ; "/>
        </xsl:variable>

        <xsl:message
            select="
                'defaultCreatorsPublishers: ',
                $defaultCreatorsPublishers"/>

        <xsl:variable name="mergedCommissioned">
            <xsl:apply-templates select="." mode="mergeData">
                <xsl:with-param name="fieldName" select="'Creators'"/>
                <xsl:with-param name="field1" select="$exiftoolCommissioned"/>
                <xsl:with-param name="field2" select="$assetCreatorsPublishers"/>
                <xsl:with-param name="field3" select="$cmsCreators"/>
                <xsl:with-param name="defaultValue" select="$defaultCreatorsPublishers"/>
                <xsl:with-param name="validatingString" select="$combinedValidatingStrings"/>                
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="RIFF:Commissioned">
            <xsl:comment select="'Exif commissioned: ', $exiftoolCommissioned"/>
            <xsl:comment select="'Cavafy creators and publishers: ', $assetCreatorsPublishers"/>
            <xsl:comment select="'CMS creators: ', $cmsCreators"/>
            <RIFF:Commissioned>
                <xsl:if test="$defaultCreatorsPublishers = $collectionURL">
                    <xsl:attribute name="warning" select="'defaultCommissioned'"/>
                </xsl:if>
                <xsl:copy-of
                    select="
                        WNYC:splitParseValidate(
                        $mergedCommissioned, $separatingToken, 'id.loc.gov'
                        )/valid/WNYC:getLOCData(.)//
                        error"/>
                <xsl:choose>
                    <xsl:when test="(not($isSegment) or $isPhysical)">
                        <xsl:value-of select="$mergedCommissioned"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="mergeData">
                            <xsl:with-param name="fieldName" select="
                                'Creators'"/>
                            <xsl:with-param name="field1" select="
                                $exiftoolCommissioned"/>
                            <xsl:with-param name="defaultValue" select="
                                $mergedCommissioned"/>
                            <xsl:with-param name="validatingString"
                                select="$combinedValidatingStrings"/>                            
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </RIFF:Commissioned>
        </xsl:variable>

        <!-- 3. Contributors as RIFF:Artist -->
        <xsl:variable name="exiftoolArtists"
            select="
            $originalExif/rdf:Description/RIFF:Artist/
            replace(., 'https://id.loc.', 'http://id.loc.')"/>
        <xsl:variable name="cavafyContributors">
            <xsl:value-of
                select="
                    $cavafyEntry/pb:pbcoreDescriptionDocument
                    /pb:pbcoreContributor/pb:contributor
                    /@ref[matches(., $validatingNameString)]/
                    replace(., 'https://id.loc.', 'http://id.loc.')"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="cmsContributors"
            select="
                $cmsData/data
                /attributes
                /appearances/contributors/name"/>
        <xsl:variable name="cmsHosts"
            select="
                $cmsData/data
                /attributes
                /appearances/hosts/name"/>
        <xsl:variable name="cmsEditors"
            select="
                $cmsData
                /data
                /attributes
                /appearances
                /*[contains(name(.), 'Editor')]
                /name"/>
        <xsl:variable name="cmsGuests"
            select="
                $cmsData/data
                /attributes
                /appearances/guests/name"/>
        <xsl:variable name="cmsAllContributors">
            <xsl:value-of
                select="
                    fn:distinct-values(
                    $cmsContributors
                    | $cmsEditors
                    | $cmsGuests
                    | $cmsHosts
                    )"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="seriesContributors">
            <xsl:value-of
                select="
                    $seriesData/pb:pbcoreDescriptionDocument
                    /pb:pbcoreContributor/pb:contributor
                    /@ref[matches(., $validatingNameString)]/replace(., 'https://id.loc.', 'http://id.loc.')"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="defaultArtists">
            <xsl:value-of
                select="
                    if
                    ($seriesContributors ne '')
                    then
                        $seriesContributors
                    else
                        $collectionURL"
            />
        </xsl:variable>
        <xsl:variable name="mergedArtists">
            <xsl:apply-templates select="." mode="mergeData">
                <xsl:with-param name="field1" select="
                    $exiftoolArtists"/>
                <xsl:with-param name="field2" select="
                    $cavafyContributors"/>
                <xsl:with-param name="field3" select="
                    $cmsAllContributors"/>
                <xsl:with-param name="defaultValue" select="
                    $defaultArtists"/>
                <xsl:with-param name="validatingString" select="
                    $validatingNameString"/>
                <xsl:with-param name="fieldName" select="
                    'Contributors'"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="RIFF:Artist">
            <xsl:comment select="'Exif artists: ', $exiftoolArtists"/>
            <xsl:comment select="'Cavafy contributors: ', $cavafyContributors"/>
            <xsl:comment select="'CMS contributors: ', $cmsContributors"/>
            <RIFF:Artist>
                <xsl:copy-of
                    select="
                        WNYC:splitParseValidate(
                        $mergedArtists, $separatingToken, 'id.loc.gov'
                        )/valid/WNYC:getLOCData(.)//
                        error"/>
                <xsl:if test="$mergedArtists = $defaultArtists">
                    <xsl:attribute name="warning" select="'defaultArtists'"/>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="(not($isSegment) or $isPhysical) or $isPhysical">
                        <xsl:value-of select="$mergedArtists"/>
                    </xsl:when>
                    <xsl:when test="$isSegment">
                        <xsl:variable name="segmentArtistWarning"
                            select="
                                'Make sure the artists for',
                                $parsedDAVIDTitle/parsedElements/DAVIDTitle,
                                'segment are right!'"/>
                        <xsl:message select="$segmentArtistWarning"/>
                        <xsl:comment select="$segmentArtistWarning"/>
                        <xsl:apply-templates select="." mode="mergeData">
                            <xsl:with-param name="field1"
                                select="
                                    $exiftoolArtists"/>
                            <xsl:with-param name="defaultValue" select="$mergedArtists"/>
                            <xsl:with-param name="validatingString" select="$validatingNameString"/>
                            <xsl:with-param name="fieldName" select="'Contributors'"/>
                        </xsl:apply-templates>
                    </xsl:when>
                </xsl:choose>
            </RIFF:Artist>
        </xsl:variable>

        <xsl:variable name="contributorsAsXMP">
            <rdf:bag>
                <xsl:for-each
                    select="
                        analyze-string(
                        $RIFF:Artist/RIFF:Artist, $separatingToken)
                        /fn:non-match/normalize-space(.)[. ne '']
                        ">
                    <rdf:li>
                        <xsl:value-of select="."/>
                    </rdf:li>
                </xsl:for-each>
            </rdf:bag>
        </xsl:variable>

        <!-- 4. Relevant date -->
        <xsl:variable name="RIFF:DateCreated">
            <RIFF:DateCreated>
                <xsl:call-template name="RIFFDate">
                    <xsl:with-param name="inputDate" select="
                        $parsedDAVIDTitle/parsedElements/DAVIDTitleDate"/>
                </xsl:call-template>                
            </RIFF:DateCreated>
        </xsl:variable>

        <xsl:variable name="DAVIDDateIsApproximate"
            select="
                contains(
                $parsedDAVIDTitle/parsedElements/
                DAVIDTitleDate, 'u')"/>

        <!-- 5. Genre -->
        <xsl:variable name="seriesGenre"
            select="
                $seriesData/pb:pbcoreDescriptionDocument/
                pb:pbcoreGenre"/>
        <xsl:variable name="defaultSegmentGenre">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="field1"
                    select="
                        $cavafyEntry/pb:pbcoreDescriptionDocument/
                        pb:pbcoreGenre"/>
                <xsl:with-param name="defaultValue" select="$seriesGenre"/>
                <xsl:with-param name="fieldName" select="'defaultSegmentGenre'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="genre">
            <xsl:choose>
                <xsl:when test="(not($isSegment) or $isPhysical)">
                    <xsl:apply-templates select="." mode="checkConflicts">
                        <xsl:with-param name="field1"
                            select="
                            $originalExif/
                            rdf:Description/
                            RIFF:Genre[not(. = $seriesGenre)]"/>
                        <xsl:with-param name="field2"
                            select="
                            $cavafyEntry/
                            pb:pbcoreDescriptionDocument/
                            pb:pbcoreGenre[not(. = $seriesGenre)]"/>
                        <xsl:with-param name="defaultValue" select="$seriesGenre"/>
                        <xsl:with-param name="fieldName" select="'Genre'"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="segmentGenreWarning"
                        select="
                        'Make sure the genre for',
                        $parsedDAVIDTitle/parsedElements/DAVIDTitle,
                        'segment is right!'"/>
                    <xsl:message select="$segmentGenreWarning"/>
                    <xsl:comment select="$segmentGenreWarning"/>
                    <xsl:apply-templates select="." mode="checkConflicts">
                        <xsl:with-param name="field1"
                            select="$originalExif/
                            rdf:Description/
                            RIFF:Genre[not(. = $defaultSegmentGenre)]"/>
                        <xsl:with-param name="defaultValue" select="$defaultSegmentGenre"/>
                        <xsl:with-param name="fieldName" select="'Genre'"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="RIFF:Genre">
            <RIFF:Genre>
                <xsl:value-of select="$genre"/>
            </RIFF:Genre>
        </xsl:variable>

        <!--Title -->
        <xsl:variable name="exifTitle"
            select="
                $originalExif/rdf:Description/RIFF:Title"/>
        <xsl:variable name="cavafyTitle"
            select="
                $cavafyEntry/pb:pbcoreDescriptionDocument/
                pb:pbcoreTitle[@titleType = 'Episode']"/>
        <xsl:variable name="checkedTitle">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="
                    'Title'"/>
                <xsl:with-param name="field1" select="
                    $exifTitle[not($isSegment) or $isPhysical]"/>
                <xsl:with-param name="field2"
                    select="
                    $cavafyTitle
                    [(not($isSegment) or $isPhysical)]
                    [not($isMultitrack)]"/>
                <xsl:with-param name="defaultValue" select="
                    $cavafyTitle"/>
                
                <!-- To avoid semicolons 
                                separating a single field -->
                <xsl:with-param name="separatingToken"
                    select="
                        $separatingTokenForFreeTextFields"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="segmentTitleSuffix">
            <!-- The 'part' bit -->
            <xsl:if test="$isSegment">
                <xsl:variable name="warningMessage"
                    select="
                        'Make sure the title for ',
                        $parsedDAVIDTitle/parsedElements/DAVIDTitle,
                        ' segment is right!'
                        "/>
                <xsl:message select="$warningMessage"/>
                <xsl:comment select="$warningMessage"/>
                <!-- From the instantiation segment bit... -->
                <xsl:value-of
                    select="
                        (concat(', Part ', $instantiationSegmentSuffix))
                        [not(empty($instantiationSegmentSuffix))]"/>
                <!-- ...or from the segment flag -->
                <xsl:value-of
                    select="
                        (concat(' (', $segmentFlag, ')'))
                        [empty($instantiationSegmentSuffix)]"
                />
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="multitrackTitleSuffix">
            <!-- The 'multitrack' bit -->
            <xsl:value-of
                select="
                    (concat(', Track ', $instantiationFirstTrack))
                    [$isMultitrack]"
            />
        </xsl:variable>


        <xsl:variable name="RIFF:Title">
            <!--This is dealt with differently 
                when audio is a segment 
            or a multitrack-->
            <RIFF:Title>
                <xsl:copy-of select="$checkedTitle[//error]"/>
                <xsl:value-of select="$checkedTitle"/>
                <!-- If the file does not have an embedded title, 
                    add the segment and multitrack bits -->
                <xsl:value-of select="$segmentTitleSuffix
                    [$checkedTitle = $cavafyTitle]
                    [not(matches($checkedTitle, $segmentTitleSuffix))]"/>
                <xsl:value-of select="$multitrackTitleSuffix[not(matches($exifTitle, $multitrackTitleSuffix))]"/>
            </RIFF:Title>
        </xsl:variable>
        <!--Medium (included as ref only) -->
        <xsl:variable name="pbcorePhysicalMediums"
            select="
                doc('http://metadataregistry.org/vocabulary/show/id/462.xsd')"/>
        
        <xsl:variable name="acceptableMediums">
            <xsl:value-of select="'Audio material|Original|'"/>
            <xsl:value-of select="
                doc('utilityLists.xml')/utilityLists/validFormats/format/formatName"
                separator="|"/>
        </xsl:variable>
        <xsl:variable name="defaultMedium"
            select="
                if ($collection eq 'MUNI')
                then
                    $parsedDAVIDTitle
                    /parsedElements
                    /MUNIMedium
                else
                    'audio material'"/>
        <xsl:variable name="originalMedium">
            <xsl:apply-templates select="." mode="mergeData">
                <xsl:with-param name="field1" select="$originalExif/rdf:Description/RIFF:Medium"/>
                <xsl:with-param name="defaultValue" select="$defaultMedium"/>
                <xsl:with-param name="fieldName" select="'Medium'"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="capitalizedMedium"
            select="
                WNYC:Capitalize($originalMedium, 1)"/>
        <xsl:variable name="RIFF:Medium">
            <RIFF:Medium>
                <xsl:if
                    test="
                        not(
                        matches(
                        $originalMedium,
                        $acceptableMediums, 'i'))">
                    <xsl:element name="error">
                        <xsl:attribute name="type" select="unacceptableMedium"/>
                        <xsl:value-of
                            select="
                                'Medium', $capitalizedMedium,
                                'is not an acceptable medium.',
                                'Acceptable mediums include',
                                $acceptableMediums"
                        />
                    </xsl:element>
                </xsl:if>
                <xsl:if test="contains($originalMedium, 'udio material')">
                    <xsl:attribute name="warning" select="'unknownOriginalMedium'"/>
                </xsl:if>
                <xsl:copy-of select="WNYC:Capitalize($originalMedium, 1)"/>
            </RIFF:Medium>
        </xsl:variable>
        <!-- Series as RIFF:Product -->

        <xsl:variable name="RIFF:Product">
            <RIFF:Product>
                <xsl:apply-templates select="." mode="checkConflicts">
                    <xsl:with-param name="fieldName" select="'Series'"/>
                    <xsl:with-param name="field1"
                        select="$originalExif/rdf:Description/
                        RIFF:Product"/>
                    <xsl:with-param name="field2"
                        select="$cavafyEntry/pb:pbcoreDescriptionDocument/
                        pb:pbcoreTitle[@titleType = 'Series']"/>
                    <xsl:with-param name="field3"
                        select="$parsedDAVIDTitle/
                        parsedElements/seriesName"/>
                    
                </xsl:apply-templates>
            </RIFF:Product>
        </xsl:variable>
        
        <xsl:variable name="broadcastDate" select="
            $originalExif/rdf:Description/System:FileAccessDate[$isPhysical]"/>
        
        <xsl:variable name="additionalInstIDs" select="
            $originalExif/rdf:Description/RIFF:BWF_UMID"/>

        <!-- Description as RIFF:Subject -->
        <xsl:variable name="exifSubject"
            select="
                $originalExif/rdf:Description/
                RIFF:Subject"/>
        <xsl:variable name="cavafyAbstract"
            select="
                $cavafyEntry
                /pb:pbcoreDescriptionDocument
                /pb:pbcoreDescription
                [@descriptionType = 'Abstract'][1]"/>
        <xsl:variable name="dbxAudioRemark"
            select="
                $dbxData/ENTRIES/ENTRY[CLASS = 'Audio']/REMARK"/>
        <!-- Trim the audio remark if it has additional tech, etc. info -->
        <xsl:variable name="dbxAudioRemarkTrimmed">
            <xsl:value-of
                select="
                    tokenize($dbxAudioRemark, 'Technical info')[1]"/>
        </xsl:variable>
        <!-- CMS Episode description -->
        
        <xsl:variable name="cmsEpisodeDescription">
            <!-- Description of full episode -->
            <xsl:value-of
                select="
                    $cmsEpisode//
                    body/
                    WNYC:strip-tags(
                    tokenize(
                    ., 'WNYC archives id:'
                    )[1]
                    )"
                separator="&#9;"/>
        </xsl:variable>
        <!-- Individual segment descriptions -->
        <xsl:variable name="cmsSegmentsTitleBody">
            <!-- Pick only segments' title and body, 
                in segment order -->
            <segmentDescriptions>                
                <xsl:for-each
                    select="
                    $cmsSegments//attributes">
                    <segment>
                        <xsl:copy-of select="title"/>
                        <xsl:copy-of select="body"/>
                    </segment>
                </xsl:for-each>
            </segmentDescriptions>
        </xsl:variable>        
        <xsl:variable name="cmsSegmentsTitleBodyFormatted">
            <!-- Format segment titles and bodies -->
            <xsl:for-each
                select="
                $cmsSegmentsTitleBody/
                segmentDescriptions/segment">
                <xsl:value-of select="title"/>
                <xsl:value-of select="'&#10;&#13;'"/>
                <xsl:value-of select="
                    WNYC:strip-tags(body)"/>
                <xsl:value-of select="'&#10;&#13;'"/>
                <xsl:value-of select="'&#10;&#13;'"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="cmsCompleteDescription">
            <xsl:value-of select="
                $cmsEpisodeDescription"/>
            <xsl:value-of select="
                '&#10;&#13;&#10;&#13;&#10;&#13;'
                [$cmsIsSegmented]"/>          
            <xsl:value-of select="
                $cmsSegmentsTitleBodyFormatted"/>
        </xsl:variable>
        <xsl:variable name="multitrackDescriptionPrefix">
            <!-- Add the multitrack bits -->
            <xsl:if test="$isMultitrack">
                <xsl:variable name="warningMessage"
                    select="
                        'Make sure the description for',
                        $parsedDAVIDTitle/parsedElements/DAVIDTitle,
                        'multitrack is right!'"/>
                <xsl:message select="$warningMessage"/>
                <xsl:comment select="$warningMessage"/>
                <xsl:value-of
                    select="
                        concat('TRACK ', $instantiationFirstTrack,
                        ' OF: &#x0D;')"
                />
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="segmentDescriptionPrefix">
            <xsl:if test="$isSegment">
                <xsl:variable name="warningMessage"
                    select="
                        'Make sure the description for ',
                        $parsedDAVIDTitle/parsedElements/DAVIDTitle,
                        'segment is right!'"/>
                <xsl:message select="$warningMessage"/>
                <xsl:comment select="$warningMessage"/>
                <xsl:value-of
                    select="
                        if ($instantiationSegmentSuffix)
                        then
                            concat('PART ', $instantiationSegmentSuffix,
                            ' OF: &#x0D;')
                        else
                            if ($segmentFlag)
                            then
                                concat($segmentFlag,
                                ' OF: &#x0D;')
                            else
                                ''"
                />
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="boilerplateDescription">
            <xsl:value-of
                select="
                    concat($checkedTitle,
                    ' on ',
                    $RIFF:Product,
                    ' on ',
                    $parsedDAVIDTitle/parsedElements/DAVIDTitleDate)"
            />
        </xsl:variable>
        <xsl:variable name="defaultDescription">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="
                    'defaultDescription'"/>
                <xsl:with-param name="field1" select="
                    $cavafyAbstract"/>
                <xsl:with-param name="defaultValue" select="
                    $boilerplateDescription"/>                
                <xsl:with-param name="separatingToken" select="
                    $separatingTokenForFreeTextFields"/>
                <xsl:with-param name="normalize" select="fn:false()"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="assetDescription">
            <!-- Cavafy abstract contains DBX REMARK -->
            <xsl:if test="(not($isSegment) or $isPhysical) and not($isMultitrack)">
                <xsl:if test="
                        not(
                        contains($cavafyAbstract, $dbxAudioRemarkTrimmed)
                        )">
                    <!-- DBX REMARK is limited to 4000 characters -->
                    <!-- So we can only check that 
                        the cavafy abstract contains it -->
                    <xsl:element name="error">
                        <xsl:value-of
                            select="'&#10;&#13;&#10;&#13;&#10;&#13;&#10;&#13;CAVAFY ABSTRACT&#10;&#13;&#10;&#13;'"/>
                        <xsl:copy-of select="$cavafyAbstract"/>
                        <xsl:value-of
                            select="'&#10;&#13;&#10;&#13;&#10;&#13;&#10;&#13;***********DOES NOT CONTAIN DBX REMARK**************&#10;&#13;&#10;&#13;'"/>
                        <xsl:copy-of select="$dbxAudioRemarkTrimmed"/>
                    </xsl:element>
                </xsl:if>
            </xsl:if>

            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="
                        'assetDescription'"/>
                <xsl:with-param name="field1" select="
                        $cavafyAbstract
                        [. ne 'No Description available']
                        "/>
                <xsl:with-param name="field2" select="
                    $cmsCompleteDescription
                    "/>
                <xsl:with-param name="field3" select="
                    $exifSubject
                    [not($isSegment) or $isPhysical]"/>
                <xsl:with-param name="defaultValue" select="
                        $defaultDescription"/>
                <xsl:with-param name="separatingToken" select="
                        $separatingTokenForFreeTextFields"/>
                <xsl:with-param name="normalize" select="fn:false()"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="exifDescribesFullAsset"
            select="
                contains(
                normalize-space($exifSubject),
                normalize-space($assetDescription)
                )"
        />
        <xsl:message select="
            'Exif', fn:normalize-space($exifSubject), 
            ' describes full asset ', 
            normalize-space($assetDescription), ': ', 
            $exifDescribesFullAsset"/>
        <xsl:variable name="exifIncludesMTPrefix" select="contains(
            $exifSubject,
            $multitrackDescriptionPrefix)"/>
        <xsl:variable name="exifIncludesSegmentPrefix" select="contains(
            $exifSubject,
            $segmentDescriptionPrefix)"/>
        
        <xsl:variable name="description">
            <!-- Add the multitrack and segment prefixes 
            if not already in description -->
            <xsl:value-of
                select="
                    $multitrackDescriptionPrefix
                    [$exifDescribesFullAsset 
                    or 
                    not(matches($exifSubject, '\w'))]
                    [not($exifIncludesMTPrefix)]
                    "/>
            <xsl:value-of select="$segmentDescriptionPrefix
                [$exifDescribesFullAsset 
                or 
                not(matches($exifSubject, '\w'))]
                [not($exifIncludesSegmentPrefix)]"/>            
            <!-- Parsed description -->
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="
                    'description'"/>
                <xsl:with-param name="field1" select="
                    $exifSubject"/>
                <xsl:with-param name="defaultValue" select="
                    $assetDescription"/>
                <xsl:with-param name="separatingToken" select="
                    $separatingTokenForFreeTextFields"/>
                <xsl:with-param name="normalize" select="fn:false()"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="descriptionNoHtml">
            <xsl:call-template name="strip-tags">
                <xsl:with-param name="text"
                    select="
                        $description[not(//error)]"/>
            </xsl:call-template>
            <xsl:copy-of select="$description[//error]"/>
        </xsl:variable>

        <xsl:variable name="RIFF:Subject">
            <RIFF:Subject>
                <!-- Warnings -->
                <xsl:if test="
                    $descriptionNoHtml = $boilerplateDescription">
                    <xsl:attribute name="warning" select="
                        'boilerplateDescription'"/>
                </xsl:if>
                <!-- Errors -->
                <xsl:copy-of select="
                        $assetDescription[//error]"/>
                <xsl:copy-of select="
                    $description[//error]
                    [not($assetDescription[//error])]"/>
                
                <xsl:copy-of select="
                        $descriptionNoHtml
                        [not($assetDescription//error)]"/>
            </RIFF:Subject>
        </xsl:variable>

        <!-- cavafy URL as RIFF:Source -->
        <!-- the cavafy URL 
            has historically been embedded 
            in different places -->
        
        <xsl:variable name="searchURL" select="
                $cavafyEntry/@cavafySearchString"/>
        <xsl:variable name="catalogURL">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="
                        'catalogURL'"/>
                <xsl:with-param name="field1" select="
                        $originalExif
                        /rdf:Description
                        /RIFF:Source"/>
                <xsl:with-param name="field2" select="
                        $originalExif
                        /rdf:Description
                        /XMP-WNYCSchema:CatalogURL"/>
                <xsl:with-param name="field3" select="
                        analyze-string(
                        $originalExif
                        /rdf:Description
                        /RIFF:Comment,
                        $validatingCatalogDirectURLString
                        )
                        /fn:match[1]"/>
                <xsl:with-param name="field4" select="
                        $parsedDAVIDTitle/parsedElements/
                        finalCavafyURL"/>
                <xsl:with-param name="validatingString" select="
                        $validatingCatalogDirectURLString"/>
                <xsl:with-param name="defaultValue" select="
                        $searchURL[matches(., $validatingCatalogSearchString)]"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="RIFF:Source">
            <RIFF:Source>
                <xsl:value-of select="$searchURL[$isNewAsset]"/>
                <xsl:value-of select="$catalogURL[not($isNewAsset)]"/>
            </RIFF:Source>
        </xsl:variable>

        <!-- Copyright info -->
        <xsl:variable name="seriesCopyright" select="$seriesData
            /pb:pbcoreDescriptionDocument
            /pb:pbcoreRightsSummary
            /pb:rightsSummary"/>
        <xsl:variable name="boilerplateCopyright">
            <xsl:value-of select="'Terms of Use and Reproduction: '"/>
            <xsl:value-of select="
                $collectionName, 
                $additionalProducingOrgs" separator="{$separatingToken}"/>
            <xsl:value-of
                select="'. Additional copyright may apply to musical selections.'"
            />
        </xsl:variable>
        <xsl:variable name="defaultCopyright">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="'defaultCopyright'"/>
                <xsl:with-param name="field1" select="
                        $seriesCopyright"/>
                <xsl:with-param name="defaultValue" select="
                        $boilerplateCopyright"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="RIFF:Copyright">
            <RIFF:Copyright>
                <xsl:apply-templates select="." mode="checkConflicts">
                    <xsl:with-param name="field1"
                        select="
                            $originalExif
                            /rdf:Description
                            /RIFF:Copyright[not(. = $defaultCopyright)]/
                            WNYC:stripNonASCII(.)"/>
                    <xsl:with-param name="field2"
                        select="
                            $cavafyEntry
                            /pb:pbcoreDescriptionDocument
                            /pb:pbcoreRightsSummary
                            /pb:rightsSummary[not(. = $defaultCopyright)]/
                            WNYC:stripNonASCII(.)"/>
                    <xsl:with-param name="defaultValue" select="$defaultCopyright"/>
                    <xsl:with-param name="fieldName" select="'Copyright'"/>
                    <xsl:with-param name="normalize" select="fn:false()"/>
                    <!-- To avoid semicolons separating a single field -->
                    <xsl:with-param name="separatingToken"
                        select="$separatingTokenForFreeTextFields"/>
                </xsl:apply-templates>
            </RIFF:Copyright>
        </xsl:variable>


        <!-- Software -->
        <xsl:variable name="RIFF:Software">
            <RIFF:Software>
                <xsl:value-of
                    select="
                        if
                        (normalize-space($originalExif/rdf:Description/RIFF:Software))
                        then
                            normalize-space($originalExif/rdf:Description/RIFF:Software)
                        else
                            'Unknown software'"
                />
            </RIFF:Software>
        </xsl:variable>


        <!-- Provenance as RIFF:SourceForm -->
        
        <xsl:variable name="boilerplateProvenance"
            select="
            concat(
            $collectionName, ' ',
            $originalMedium, ' ',
            $generation,
            ' from ', $assetID)"/>
        
        <xsl:variable name="exifProvenance"
            select="
                $originalExif
                /rdf:Description/RIFF:SourceForm"/>
        <xsl:variable name="instantiationProvenance"
            select="
                $instantiationData
                /pb:pbcoreInstantiation
                /pb:instantiationAnnotation
                [@annotationType = 'Provenance']"/>
        
        <xsl:variable name="assetProvenance"
            select="
                $cavafyEntry
                /pb:pbcoreDescriptionDocument
                /pb:pbcoreAnnotation
                [@annotationType = 'Provenance']"/>
        <xsl:variable name="muniProvenance"
            select="
            concat(
            'BWF created from the original WNYC Municipal Archives ',
            $originalMedium)[$collection = 'MUNI']"/>
        <xsl:variable name="assetLevelProvenance">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="field1" select="$assetProvenance"/>
                <xsl:with-param name="defaultValue" select="$muniProvenance"/>
                <xsl:with-param name="fieldName" select="'assetLevelProvenance'"/>
                <xsl:with-param name="separatingToken"
                    select="
                    $separatingTokenForFreeTextFields"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="instLevelProvenance">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="field1" select="$exifProvenance"/>
                <xsl:with-param name="field2" select="$instantiationProvenance"/>
                <xsl:with-param name="defaultValue" select="$assetLevelProvenance"/>
                <xsl:with-param name="fieldName" select="'instLevelProvenance'"/>
                <xsl:with-param name="separatingToken"
                    select="
                    $separatingTokenForFreeTextFields"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="defaultProvenance">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="field1" select="$assetLevelProvenance"/>
                <xsl:with-param name="defaultValue" select="$boilerplateProvenance"/>
                <xsl:with-param name="fieldName" select="'defaultProvenance'"/>
                <xsl:with-param name="separatingToken"
                    select="
                        $separatingTokenForFreeTextFields"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="provenance">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="
                    'Provenance'"/>
                <xsl:with-param name="field1"
                    select="$instLevelProvenance[not(. = $defaultProvenance)]"/>
                <xsl:with-param name="defaultValue" select="$defaultProvenance"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="RIFF:SourceForm">
            <RIFF:SourceForm>
                <xsl:copy-of select="($assetLevelProvenance, $instLevelProvenance, $defaultProvenance)[//error]"/>
                <xsl:copy-of select="$provenance"/>
            </RIFF:SourceForm>
        </xsl:variable>

        <!-- Engineers and Technicians -->
        <xsl:variable name="seriesEngineers">
            <xsl:value-of
                select="
                    $seriesData/pb:pbcoreDescriptionDocument
                    /pb:pbcoreContributor
                    [contains(pb:contributorRole, 'ngineer')]
                    /pb:contributor"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>

        <xsl:variable name="defaultEngineers">
            <xsl:value-of
                select="
                    if
                    ($seriesEngineers != '')
                    then
                        $seriesEngineers
                    else
                        'Unknown engineer'"
            />
        </xsl:variable>
        <xsl:variable name="DAVIDEngineers">
            <xsl:value-of
                select="
                    distinct-values(
                    $dbxData/ENTRIES/ENTRY/(AUTHOR | EDITOR))"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="engineer">
            <xsl:call-template name="mergeData">
                <xsl:with-param name="field1"
                    select="
                        $originalExif/
                        rdf:Description/
                        RIFF:Engineer
                        [. != $defaultEngineers]"/>
                <xsl:with-param name="field2">
                    <xsl:value-of
                        select="
                            $cavafyEntry/pb:pbcoreDescriptionDocument
                            /pb:pbcoreContributor
                            [contains(pb:contributorRole, 'ngineer')]
                            /pb:contributor[. != 'Unknown engineer']"
                        separator="{$separatingTokenLong}"/>
                </xsl:with-param>
                <xsl:with-param name="field3"
                    select="
                        $DAVIDEngineers[. != $defaultEngineers]"/>
                <xsl:with-param name="defaultValue"
                    select="
                        $defaultEngineers"/>
                <xsl:with-param name="fieldName" select="'Engineers'"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="RIFF:Engineer">
            <RIFF:Engineer>
                <xsl:if test="$engineer = $defaultEngineers">
                    <xsl:attribute name="warning" select="'defaultEngineer'"/>
                </xsl:if>
                <xsl:copy-of select="$engineer"/>
            </RIFF:Engineer>
        </xsl:variable>


        <xsl:variable name="defaultTechnician">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="
                    'DefaultTechnician'"/>
                <xsl:with-param name="field1"
                    select="$originalExif/rdf:Description/
                    RIFF:Originator[not(. = 'ARCHIVES')]"/>
                <xsl:with-param name="field2"
                    select="$dbxData/ENTRIES/
                    ENTRY/CREATOR[not(. = 'ARCHIVES')]"/>
                <xsl:with-param name="defaultValue" select="
                    'ARCHIVES'"/>                
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="technician">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="
                    'Technician'"/>
                <xsl:with-param name="field1"
                    select="
                        $originalExif/rdf:Description/
                        RIFF:Technician[not(. = $defaultTechnician)]"/>
                <xsl:with-param name="defaultValue" select="
                    $defaultTechnician"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="RIFF:Technician">
            <RIFF:Technician>
                <xsl:if test="$technician = $defaultTechnician">
                    <xsl:attribute name="warning" select="'defaultTechnician'"/>
                </xsl:if>
                <xsl:copy-of select="$technician"/>
            </RIFF:Technician>
        </xsl:variable>

        <!-- Coding history -->
        
        <xsl:variable name="goodExifCodingHistory">
            <xsl:value-of
                select="
                $originalExif/rdf:Description
                /RIFF:CodingHistory
                [not(contains(., 'D.A.V.I.D'))]
                [not(contains(., 'udio material'))]
                "
            />
        </xsl:variable>        
        <xsl:variable name="codingHistoryContainsStylusSize" select="
            contains(
            $originalExif/rdf:Description/
            RIFF:CodingHistory, '[St]')
            "/>
        <xsl:variable name="codingHistoryContainsTurnoverInfo" select="
            contains(
            $originalExif/
            rdf:Description/
            RIFF:CodingHistory, 
            '[TO]'
            )"/>        
        <xsl:variable name="codingHistoryContainsRolloffInfo" select="
            contains(
            $originalExif
            /rdf:Description/
            RIFF:CodingHistory,
            '[RO]'
            )"/>
        <xsl:variable name="codingHistoryContainsRumbleFilterInfo" select="
            contains(
            $originalExif/
            rdf:Description/
            RIFF:CodingHistory,
            '[RF]'
            )"/>
        <xsl:variable name="defaultCodingHistory">
            <xsl:value-of select="'T='"/>
            <xsl:value-of select="'Transfer from '[$isDub]"/>
            <xsl:value-of select="$parsedDAVIDTitle/parsedElements/collectionName"/>
            <xsl:value-of
                select="
                concat(' ', $originalMedium, '.')"/>
        </xsl:variable>
        <xsl:variable name="RIFF:CodingHistory">
            <RIFF:CodingHistory>
                <xsl:call-template name="checkConflicts">
                    <xsl:with-param name="fieldName"
                        select="
                            'CodingHistory'"/>
                    <xsl:with-param name="field1"
                        select="
                            $goodExifCodingHistory[not(. = $defaultCodingHistory)]"/>
                    <xsl:with-param name="defaultValue"
                        select="
                            $defaultCodingHistory"/>
                    <xsl:with-param name="separatingToken"
                        select="$separatingTokenForFreeTextFields"/>
                    <xsl:with-param name="normalize" select="false()"/>
                </xsl:call-template>
                <!-- Additional disc transfer info from XMP -->
                <xsl:value-of select="
                        concat(
                        '; [St]',
                        $originalExif/rdf:Description/
                        XMP-WNYCSchema:Stylus_size                        
                        )
                        [matches(., '\d')]
                        [not($codingHistoryContainsStylusSize)]"/>
                <xsl:value-of select="
                        concat(
                        '; [TO]',
                        $originalExif/rdf:Description/XMP-WNYCSchema:LF_turnover
                        )
                        [matches(., '\d')]
                        [not($codingHistoryContainsTurnoverInfo)]"/>       
                <xsl:value-of select="
                        concat(
                        '; [RO]',
                        $originalExif
                        /rdf:Description
                        /XMP-WNYCSchema:Tag_0kHz_att                        
                        )
                        [matches(., '\d')]
                        [not($codingHistoryContainsRolloffInfo)]"/>
                    <xsl:value-of
                        select="
                            concat(
                            ' ;[RF]',
                            $originalExif
                            /rdf:Description
                            /XMP-WNYCSchema:Rumble_filter
                            )
                            [matches(., '\d')]
                            [not($codingHistoryContainsRumbleFilterInfo)]"
                    />                
            </RIFF:CodingHistory>
        </xsl:variable>

        <!-- Transcript -->
        <xsl:variable name="transcript">
            <xsl:variable name="exifTranscript" select="
                $originalExif/rdf:Description/XMP-xmpDM:Lyrics"/>
            <xsl:variable name="cavafyTranscript"
                select="
                    $cavafyEntry/pb:pbcoreDescriptionDocument/
                    pb:pbcoreDescription[@descriptionType = 'Transcript']"/>
            <xsl:choose>
                <xsl:when test="$exifTranscript">
                    <xsl:comment select="'exif Transcript found'"/>
                    <xsl:choose>
                        <xsl:when
                            test="
                                contains(
                                $cavafyTranscript, $exifTranscript)">
                            <xsl:value-of select="$cavafyTranscript"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$exifTranscript"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$cavafyTranscript">
                    <xsl:value-of select="$cavafyTranscript"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <!--Subject headings and keywords -->
        <xsl:variable name="exifKeywords">
            <xsl:value-of select="
                    $originalExif/rdf:Description/RIFF:Keywords"
            />
        </xsl:variable>
        <xsl:variable name="cavafySubjects">            
            <xsl:value-of
                select="
                    $cavafyEntry/pb:pbcoreDescriptionDocument
                    /pb:pbcoreSubject
                    /@ref[matches(., $combinedValidatingStrings)]"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        

        <!-- Exif artist names and fields of activity
        as subjects -->
        <xsl:variable name="occupationsAndFieldsOfActivity">
            <xsl:if test="$occupationsAreSubjects">
                <xsl:call-template name="LOCOccupationsAndFieldsOfActivity">
                    <xsl:with-param name="artists" select="
                            $RIFF:Artist/RIFF:Artist"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        
        
        <xsl:variable name="subjectsKeywordsAndOccupationsAndFieldsOfActivity">
            <xsl:value-of
                select="
                    $cavafySubjects[. != ''],
                    $exifKeywords[. != ''],
                    $occupationsAndFieldsOfActivity[. != '']"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:message
            select="
                'Narrowize',
                $subjectsKeywordsAndOccupationsAndFieldsOfActivity"/>
        <xsl:variable name="subjectsAndKeywordsNarrowed">
            <xsl:apply-templates select="
                    $exifKeywords"
                mode="
                narrowSubjects"/>
        </xsl:variable>
        <xsl:variable name="subjectsAndKeywordsAndOccupationsAndFoANarrowed">
            <xsl:apply-templates
                select="
                    $subjectsKeywordsAndOccupationsAndFieldsOfActivity"
                mode="
                narrowSubjects"/>
        </xsl:variable>
        <xsl:variable name="seriesSubjectsRef">
            <xsl:value-of
                select="
                    $seriesData/pb:pbcoreDescriptionDocument
                    /pb:pbcoreSubject
                    /@ref[matches(., $combinedValidatingStrings)]"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="exifSubjectsAndKeywordsNarrowedRef">
            <xsl:value-of
                select="
                    $subjectsAndKeywordsAndOccupationsAndFoANarrowed
                    /madsrdf:*/@rdf:about
                    [matches(., $combinedValidatingStrings)]"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="subjectsAndKeywordsNarrowedRef">
            <xsl:value-of
                select="
                    $subjectsAndKeywordsAndOccupationsAndFoANarrowed
                    /madsrdf:*/@rdf:about
                    [matches(., $combinedValidatingStrings)]"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="assetKeywords">
            <xsl:call-template name="mergeData">
                <xsl:with-param name="field1">
                    <xsl:value-of
                        select="
                            $subjectsAndKeywordsNarrowedRef
                            "
                    />
                </xsl:with-param>
                <xsl:with-param name="defaultValue"
                    select="
                        $seriesSubjectsRef"/>
                <xsl:with-param name="fieldName" select="'Keywords'"/>
            </xsl:call-template>
        </xsl:variable>
        <!--<xsl:variable name="locKeywordsNotFound">
            <xsl:copy-of
                select="
                    WNYC:splitParseValidate(
                    $assetKeywords, $separatingToken, $combinedValidatingStrings
                    )/valid/WNYC:getLOCData(.)[/error]"
            /> 
        </xsl:variable>-->
        <xsl:variable name="assetKeywordsRDFBag">
            <rdf:bag>
                <xsl:for-each
                    select="
                        WNYC:splitParseValidate(
                        $assetKeywords, ';', $combinedValidatingStrings
                        )/valid">
                    <xsl:element name="rdf:li">
                        <xsl:value-of select="."/>
                    </xsl:element>
                </xsl:for-each>
            </rdf:bag>
        </xsl:variable>
        <xsl:variable name="instantiationKeywords">
            <xsl:call-template name="mergeData">
                <xsl:with-param name="fieldName" select="'instantiationKeywords'"/>
                <xsl:with-param name="field1" select="$exifKeywords"/>
                <xsl:with-param name="defaultValue" select="$assetKeywords"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:comment select="
                'Exif keywords: ', $exifKeywords"/>
        <xsl:comment select="
                'Cavafy subject headings: ', $cavafySubjects"/>
        <xsl:variable name="segmentKeywords">
            <xsl:call-template name="narrowSubjects">                
                <xsl:with-param name="subjectsToProcess">
                    <xsl:value-of
                        select="
                            $instantiationKeywords, $occupationsAndFieldsOfActivity
                            " separator="{$separatingTokenLong}"
                    />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="segmentKeywordsRDFBag">
            <rdf:bag>
                <xsl:for-each
                    select="
                        WNYC:splitParseValidate(
                        $segmentKeywords, ';', $combinedValidatingStrings
                        )/valid">
                    <xsl:element name="rdf:li">
                        <xsl:value-of select="."/>
                    </xsl:element>
                </xsl:for-each>
            </rdf:bag>
        </xsl:variable>


        <xsl:variable name="RIFF:Keywords">
            <xsl:choose>
                <xsl:when test="
                        (not($isSegment) or $isPhysical)">
                    <RIFF:Keywords>
                        <xsl:copy-of
                            select="
                                WNYC:splitParseValidate(
                                $assetKeywords, $separatingToken, 'id.loc.gov'
                                )/valid/WNYC:getLOCData(.)//
                                error"/>
                        <xsl:if test="$assetKeywords = $seriesSubjectsRef">
                            <xsl:attribute name="warning" select="'defaultKeywords'"/>
                        </xsl:if>
                        <xsl:value-of select="$assetKeywords"/>
                    </RIFF:Keywords>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="keywordMessage"
                        select="
                            concat(
                            'Make sure the keywords for ',
                            $parsedDAVIDTitle
                            /parsedElements
                            /DAVIDTitle,
                            ' segment are right!'
                            )"/>
                    <xsl:message select="$keywordMessage"/>
                    <xsl:comment select="$keywordMessage"/>
                    <RIFF:Keywords>
                        <xsl:value-of select="
                                $segmentKeywords/madsrdf:*/@rdf:about" separator="{$separatingTokenLong}"/>
                    </RIFF:Keywords>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Various and sundry comments -->
        <!-- The original embedded comment -->
        <xsl:variable name="exifComment"
            select="
                normalize-space(
                $originalExif/rdf:Description/
                RIFF:Comment)"/>
        <!-- Multitrack warning -->
        <xsl:variable name="multitrackWarning">
            <xsl:if test="$isMultitrack">
                <xsl:value-of
                    select="
                        'This audio file is intended to be played ',
                        'simultaneously with at least '
                        "/>
                <xsl:value-of
                    select="
                        $instantiationLastTrack,
                        'other tracks. '"/>
                <xsl:value-of
                    select="
                        'Look for other files named',
                        tokenize(
                        $parsedDAVIDTitle/@DAVIDTitle,
                        $multitrackFlag
                        )[1]"/>
                <xsl:value-of select="'_TK*'"/>
            </xsl:if>
        </xsl:variable>
        <!-- Cavafy generic comments
        not already embedded -->
        <xsl:variable name="cavafyInstantiationComments">
            <xsl:value-of
                select="
                    (
                    $instantiationData
                    /pb:pbcoreInstantiation
                    /pb:instantiationAnnotation
                    [not(@annotationType)])
                    [not(contains($exifComment, .))]/normalize-space()"
                separator="
                {$separatingTokenLong}"/>
        </xsl:variable>
        <!-- Embedded cavafy-url comment -->
        <xsl:variable name="cavafyURLComment"
            select="
                $RIFF:Source
                [starts-with(., $validatingCatalogString)]
                /concat('For additional details see ', .)"/>
        <!-- Approximate date comment -->
        <xsl:variable name="approximateDateComment"
            select="
                (concat(
                'Date is approximate. Given date is ',
                $parsedDAVIDTitle/parsedElements/
                DAVIDTitleDate, '.')
                )
                [$DAVIDDateIsApproximate]
                "/>
        <!-- AAPB Additions -->
        <xsl:variable name="aapbURLInSource"
            select="
                $originalExif/rdf:Description/
                RIFF:Source
                [contains(., '//americanarchive.org/catalog/')]
                /concat(
                'American Archive catalog entry available at: ', .)"/>
        <xsl:variable name="aapbTranscriptURLInComment"
            select="
                $originalExif/rdf:Description/RIFF:Comment
                [starts-with(., 'https://s3.amazonaws.com/americanarchive.org/transcripts/')]
                /concat(
                'Automated transcript available from ', .)"/>

        <!-- Gather all comments -->
        <xsl:variable name="RIFF:Comment">
            <RIFF:Comment>
                <!-- Generate error if the date is exact, 
                    but the comment says it is not -->
                <xsl:if
                    test="
                        contains(
                        $exifComment, 'Date is approximate.')
                        and
                        not($DAVIDDateIsApproximate)">
                    <xsl:variable name="dateNotApproximateMessage"
                        select="
                            'ATTENTION!',
                            'Embedded comment', $exifComment,
                            'implies an approximate date.',
                            'But in fact the date is',
                            $parsedDAVIDTitle/parsedElements/DAVIDTitleDate
                            "/>
                    <xsl:message select="$dateNotApproximateMessage"/>
                    <xsl:element name="error">
                        <xsl:attribute name="type" select="'dateNotApproximate'"/>
                        <xsl:value-of select="$dateNotApproximateMessage"/>
                    </xsl:element>
                </xsl:if>

                <!-- GATHER ALL COMMENTS: -->
                <!-- Multitrack warning -->
                <!-- Original RIFF comment, if not empty -->
                <!-- cavafyURL comment, if not already in -->
                <!-- Approximate date comment, if not already in -->
                <!-- American Archive comment, if not already in -->
                <!-- aapb transcript comment, if not already in -->

                <xsl:value-of
                    select="
                        $exifComment[. != ''],
                        $multitrackWarning
                        [not(contains($exifComment,
                        $multitrackWarning))],
                        $cavafyURLComment
                        [not(
                        contains(
                        $exifComment,
                        'For additional details see https://cavafy.')
                        )],
                        $approximateDateComment
                        [not(
                        contains(
                        $exifComment, 'Date is approximate')
                        )],
                        $aapbURLInSource
                        [not(
                        contains(
                        $exifComment, 'American Archive catalog entry available at: ')
                        )],
                        $aapbTranscriptURLInComment
                        [not(
                        contains(
                        $exifComment, 'Automated transcript available from')
                        )]"
                    separator="{$separatingTokenLong}"/>
            </RIFF:Comment>
        </xsl:variable>

        <!-- Originator field; not to be trusted much in DAVID -->
        <xsl:variable name="RIFF:Originator">
            <RIFF:Originator>
                <xsl:call-template name="checkConflicts">
                    <xsl:with-param name="field1">
                        <xsl:value-of
                            select="
                                $dbxData/ENTRIES/
                                ENTRY/AUTHOR
                                [not(. = $RIFF:Technician)]"
                        />
                    </xsl:with-param>
                    <xsl:with-param name="field2">
                        <xsl:value-of
                            select="
                                $originalExif/rdf:Description/
                                RIFF:Originator
                                [not(. = $RIFF:Technician)]"
                        />
                    </xsl:with-param>
                    <xsl:with-param name="defaultValue">
                        <xsl:value-of select="$RIFF:Technician"/>
                    </xsl:with-param> 
                    <xsl:with-param name="fieldName" select="
                        'RIFF:Originator'"/>
                </xsl:call-template>
                <xsl:text>&#013;</xsl:text>
            </RIFF:Originator>
        </xsl:variable>

        <!--  Originator reference field; 
            not to be trusted much in DAVID,
        as it often gets wiped out -->
        <xsl:variable name="RIFF:OriginatorReference">
            <RIFF:OriginatorReference>
                <xsl:value-of select="concat('Catalog number ', $assetID)"/>
            </RIFF:OriginatorReference>
        </xsl:variable>

        <!-- Other potentially useful variables: 
            CMS Image ID, Transcript, Coverage -->

        <xsl:variable name="defaultCMSImageID">
            <xsl:choose>
                <xsl:when
                    test="
                        $seriesData/pb:pbcoreDescriptionDocument
                        /pb:pbcoreAnnotation
                        [@annotationType = 'CMS Image']
                        ne ''">
                    <xsl:value-of
                        select="
                            $seriesData/pb:pbcoreDescriptionDocument
                            /pb:pbcoreAnnotation
                            [@annotationType = 'CMS Image']"
                    />
                </xsl:when>
                <xsl:when test="contains($originalMedium, 'disc')">
                    <xsl:value-of select="'166809'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'154339'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="cmsImageID">
            <xsl:apply-templates select="inputs" mode="checkConflicts">
                <xsl:with-param name="field1"
                    select="
                        $originalExif
                        /XMP-plus:ImageSupplierImageID
                        /fn:normalize-space(.)[not(. = $defaultCMSImageID)]"/>
                <xsl:with-param name="field2"
                    select="
                        $originalExif
                        /XMP-WNYCSchema:ImageCMS
                        /fn:normalize-space(.)[not(. = $defaultCMSImageID)]"/>
                <xsl:with-param name="field3"
                    select="
                        $cavafyEntry/pb:pbcoreDescriptionDocument
                        /pb:pbcoreAnnotation
                        [@annotationType = 'CMS Image']
                        [not(. = $defaultCMSImageID)]"/>
                <xsl:with-param name="defaultValue" select="
                    $defaultCMSImageID"/>
                <xsl:with-param name="fieldName" select="
                    'CMSImageID'"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="aapbTranscriptURL">
            <xsl:value-of
                select="
                    $originalExif
                    /RIFF:Comment
                    [starts-with(
                    ., 'https://s3.amazonaws.com/americanarchive.org/transcripts/'
                    )]"
            />
        </xsl:variable>
        <xsl:variable name="aapbTranscriptFromCommentField">
            <xsl:apply-templates
                select="
                    $originalExif
                    /RIFF:Comment
                    [starts-with(
                    ., 'https://s3.amazonaws.com/americanarchive.org/transcripts/'
                    )]"
            />
        </xsl:variable>

        <!-- Location coordinates as XMP-dc:Coverage -->
        <xsl:variable name="googleLocation">
            <xsl:value-of
                select="
                    $originalExif
                    /XMP-dc:Coverage"/>
        </xsl:variable>
        <xsl:variable name="exifCoordinates"
            select="
                concat(
                substring-before(substring-after($googleLocation, '@'), ','),
                ',',
                substring-before(substring-after(substring-after(@location, '@'), ','), ',')
                )"/>
        <xsl:variable name="cavafyCoordinates"
            select="
                $cavafyEntry/pb:pbcoreDocument
                /pb:pbcoreCoverage[pb:coverageType eq 'Spatial']
                /pb:coverage[matches(., '[0-9]+.*[0-9]*, *\-*[0-9]+.*[0-9]*')]"/>

        <xsl:variable name="seriesCoordinates"
            select="
                $seriesData/pb:pbcoreDocument
                /pb:pbcoreCoverage[pb:coverageType eq 'Spatial']
                /pb:coverage[matches(., '[0-9]+.*[0-9]*, *\-*[0-9]+.*[0-9]*')]"/>

        <xsl:variable name="XMP-dc:Coverage">
            <xsl:apply-templates select="inputs" mode="checkConflicts">
                <xsl:with-param name="field1" select="$exifCoordinates"/>
                <xsl:with-param name="field2"
                    select="
                        $cavafyEntry/pb:pbcoreDocument
                        /pb:pbcoreCoverage[pb:coverageType eq 'Spatial']
                        /pb:coverage"/>
                <xsl:with-param name="defaultValue" select="$seriesCoordinates"/>
                <xsl:with-param name="fieldName" select="'Location'"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="systemFileSizeMB" as="xs:decimal">
            <xsl:choose>
                <xsl:when
                    test="
                        contains(
                        $originalExif/rdf:Description
                        /System:FileSize[1], ' GB')">
                    <xsl:value-of
                        select="
                            xs:decimal(
                            substring-before(
                            $originalExif/rdf:Description
                            /System:FileSize[1], ' GB'
                            ))
                            * 1000"
                    />
                </xsl:when>
                <xsl:when
                    test="
                        contains($originalExif/rdf:Description/System:FileSize[1], ' MB')">
                    <xsl:value-of
                        select="
                            xs:decimal(
                            substring-before(
                            $originalExif/rdf:Description
                            /System:FileSize[1], ' MB'))"
                    />
                </xsl:when>
                <xsl:when
                    test="
                        contains($originalExif/rdf:Description
                        /System:FileSize[1], ' KB')">
                    <xsl:value-of
                        select="
                            xs:decimal(
                            substring-before(
                            $originalExif/rdf:Description
                            /System:FileSize[1], ' KB'))
                            div 1000"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="no" select="'Unknown System file size!'"/>
                    <xsl:value-of select="-1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="DAVIDNumChannels">
            <xsl:choose>
                <xsl:when
                    test="
                        $dbxData/ENTRIES
                        /ENTRY/AUDIOMODE = 'Stereo'">
                    <xsl:value-of select="2"/>
                </xsl:when>
                <xsl:when
                    test="
                        $dbxData/ENTRIES
                        /ENTRY/AUDIOMODE = 'Mono'">
                    <xsl:value-of select="1"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="DAVIDEncoding">
            <xsl:choose>
                <xsl:when
                    test="
                        contains(
                        $dbxData/ENTRIES
                        /ENTRY/AUDIOFORMAT,
                        'BWF')">
                    <xsl:value-of select="'Microsoft PCM'"/>
                </xsl:when>
                <xsl:when
                    test="
                        contains(
                        $dbxData/ENTRIES
                        /ENTRY/MEDIUM
                        /FILE[TYPE = 'Audio']
                        /FORMAT,
                        'Linear')">
                    <xsl:value-of select="'Microsoft PCM'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="
                            $dbxData/ENTRIES
                            /ENTRY/MEDIUM
                            /FILE[TYPE = 'Audio']
                            /FORMAT"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- DAVID does not output bit depth, 
            so we calculate it using
            the following formula:
         bitDepth (approx) = 
         filesize(bits) div (duration (s) x sampleRate x numChannels)-->

        <xsl:variable name="DAVIDFileSizeBits"
            select="xs:integer($dbxData/ENTRIES/ENTRY/FILESIZE * 8)"/>
        <xsl:variable name="DAVIDFileSizeMB"
            select="round($dbxData/ENTRIES/ENTRY/FILESIZE div 1048576)"/>
        <xsl:variable name="DAVIDDurationSeconds" select="$dbxData/ENTRIES/ENTRY/DURATION div 1000"/>
        <xsl:variable name="DAVIDSampleRate" select="$dbxData/ENTRIES/ENTRY/SAMPLERATE"/>
        <xsl:variable name="DAVIDApproxBitDepth"
            select="$DAVIDFileSizeBits div ($DAVIDDurationSeconds * $DAVIDSampleRate * $DAVIDNumChannels)"/>
        <xsl:variable name="DAVIDBitDepth">
            <xsl:value-of select="floor($DAVIDApproxBitDepth)"/>
        </xsl:variable>
        <xsl:variable name="DAVIDApproxDataRate">
            <xsl:value-of
                select="
                    $dbxData/ENTRIES
                    /ENTRY/FILESIZE
                    div
                    $DAVIDDurationSeconds"
            />
        </xsl:variable>
        <xsl:variable name="DAVIDDataRate">
            <xsl:value-of select="round($DAVIDApproxDataRate[. ne ''], -3)"/>
        </xsl:variable>
        <xsl:variable name="DAVIDFileCreateDate"
            select="
                $dbxData
                /ENTRIES/ENTRY/MEDIUM
                /FILE[TYPE = 'Audio']
                /CREATEDATE/fn:translate(., '-', ':')"/>
        <xsl:variable name="DAVIDFileCreateTime"
            select="
                $dbxData
                /ENTRIES/ENTRY/MEDIUM
                /FILE[TYPE = 'Audio']
                /CREATETIME/fn:translate(., '-', ':')"/>
        <xsl:variable name="DAVIDFileCreateDateTime">
            <xsl:value-of
                select="
                    concat(
                    $DAVIDFileCreateDate, ' ',
                    $DAVIDFileCreateTime, '-4:00')"
            />
        </xsl:variable>
        <xsl:variable name="DAVIDFileModifyDate"
            select="
                $dbxData
                /ENTRIES/ENTRY
                /CHANGEDATE[. ne '']/fn:translate(., '-', ':')"/>
        <xsl:variable name="DAVIDFileModifyTime"
            select="
                $dbxData
                /ENTRIES/ENTRY
                /CHANGETIME[. ne '']/fn:translate(., '-', ':')"/>
        <xsl:variable name="DAVIDFileModifyDateTime">
            <xsl:value-of
                select="
                    concat(
                    $DAVIDFileModifyDate, ' ',
                    $DAVIDFileModifyTime, '-5:00')"
            />
        </xsl:variable>

        <xsl:variable name="newExif">
            <xsl:element name="rdf:Description">
                <xsl:attribute name="rdf:about">
                    <xsl:value-of select="$fullFilePath"/>
                </xsl:attribute>                
                <xsl:namespace name="ExifTool" select="'http://ns.exiftool.ca/ExifTool/1.0/'"/>
                <xsl:namespace name="et" select="'http://ns.exiftool.ca/1.0/'"/>
                <xsl:attribute name="et:toolkit" select="'Image::ExifTool 10.82'"/>
                <xsl:namespace name="System" select="'http://ns.exiftool.ca/File/System/1.0/'"/>
                <xsl:namespace name="File" select="'http://ns.exiftool.ca/File/1.0/'"/>
                <xsl:namespace name="RIFF" select="'http://ns.exiftool.ca/RIFF/RIFF/1.0/'"/>
                <xsl:namespace name="XMP-x" select="'http://ns.exiftool.ca/XMP/XMP-x/1.0/'"/>
                <xsl:namespace name="XMP-xmp" select="'http://ns.exiftool.ca/XMP/XMP-xmp/1.0/'"/>
                <xsl:namespace name="XMP-xmpDM" select="'http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/'"/>
                <xsl:namespace name="XMP-xmpMM" select="'http://ns.exiftool.ca/XMP/XMP-xmpMM/1.0/'"/>
                <xsl:namespace name="XMP-dc" select="'http://ns.exiftool.ca/XMP/XMP-dc/1.0/'"/>
                <xsl:namespace name="XMP-plus" select="'http://ns.exiftool.ca/XMP/XMP-plus/1.0/'"/>
                <xsl:namespace name="XML" select="'http://ns.exiftool.ca/XML/XML/1.0/'"/>
                <xsl:namespace name="Composite" select="'http://ns.exiftool.ca/Composite/1.0/'"/>

                <xsl:copy-of select="$originalExif/rdf:Description/ExifTool:ExifToolVersion" copy-namespaces="0"/>

                <System:FileName>
                    <xsl:value-of select="$filename"/>
                </System:FileName>

                <xsl:copy-of select="$originalExif/rdf:Description/System:Directory[1]" copy-namespaces="0"/>

                <System:FileSize>
                    <xsl:choose>
                        <!-- Checking for files dangerously close to 4 gigs in size -->
                        <xsl:when
                            test="
                                upper-case($fileType) eq 'WAV'
                                and (
                                $systemFileSizeMB gt 4265
                                or
                                $DAVIDFileSizeMB gt 4265
                                )
                                ">
                            <xsl:element name="error">
                                <xsl:attribute name="type"
                                    select="
                                        'file_too_big'"/>
                                <xsl:value-of
                                    select="
                                        'File', $originalExif/rdf:Description/System:FileName[1],
                                        'is dangerously large:', $DAVIDFileSizeMB, 'or', $systemFileSizeMB, 'MB.'"
                                />
                            </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:choose>
                                <!-- No file size anywhere -->
                                <xsl:when test="$systemFileSizeMB le 0 and $DAVIDFileSizeMB le 0">
                                    <xsl:element name="error">
                                        <xsl:attribute name="type" select="'missing_file_size'"/>
                                        <xsl:value-of
                                            select="
                                                'no file size for ',
                                                $originalExif/System:FileName[1]
                                                "
                                        />
                                    </xsl:element>
                                </xsl:when>
                                <!-- Conflicting size values -->
                                <xsl:when
                                    test="$systemFileSizeMB[. gt 0] ne $DAVIDFileSizeMB[. gt 0]">
                                    <xsl:element name="error">
                                        <xsl:attribute name="type"
                                            select="
                                                'conflicting_file_size'"/>
                                        <xsl:value-of select="'Conflicting file size: '"/>
                                        <xsl:text/>
                                        <xsl:value-of
                                            select="concat('system: ', $systemFileSizeMB, ' MB.')"/>
                                        <xsl:value-of
                                            select="concat('DAVID: ', $DAVIDFileSizeMB, ' MB.')"/>
                                    </xsl:element>
                                    <xsl:value-of select="$systemFileSizeMB[. gt 0]"/>
                                </xsl:when>
                                <!-- Filesize in system only -->
                                <xsl:when test="$systemFileSizeMB gt 0">
                                    <xsl:value-of
                                        select="
                                            concat($systemFileSizeMB, ' MB')"
                                    />
                                </xsl:when>
                                <!-- Filesize in DAVID only -->
                                <xsl:when test="$DAVIDFileSizeMB gt 0">
                                    <xsl:value-of
                                        select="
                                            concat($DAVIDFileSizeMB, ' MB')"
                                    />
                                </xsl:when>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </System:FileSize>
                <System:FileModifyDate>
                    <xsl:call-template name="checkConflicts">
                        <xsl:with-param name="field1">
                            <xsl:value-of select="$DAVIDFileModifyDateTime[. ne ' -5:00'][. ne ' -4:00']"/>
                        </xsl:with-param>                            
                        <xsl:with-param name="defaultValue">
                            <xsl:value-of select="$originalExif/rdf:Description/System:FileModifyDate"/>
                        </xsl:with-param>                            
                        <xsl:with-param name="fieldName" select="'FileModifyDate'"/>
                    </xsl:call-template>
                </System:FileModifyDate>
                <xsl:copy-of select="$originalExif/rdf:Description/System:FileAccessDate"/>
                <System:FileCreateDate>
                    <xsl:call-template name="checkConflicts">
                        <xsl:with-param name="fieldName" select="'FileCreateDate'"/>
                        <xsl:with-param name="field1"
                            select="$originalExif/rdf:Description/System:FileCreateDate"/>
                        <xsl:with-param name="defaultValue"
                            select="$DAVIDFileCreateDateTime[. ne ' -5:00'][. ne ' -4:00']"/>                
                    </xsl:call-template>
                </System:FileCreateDate>
                <xsl:copy-of select="$originalExif/rdf:Description/System:FilePermissions"/>

                <File:FileType>
                    <xsl:choose>
                        <!-- Reject RF64 files -->
                        <xsl:when test="contains($fileType, 'RF64')">
                            <xsl:element name="error">
                                <xsl:attribute name="type" select="'unacceptable_file_type'"/>
                                <xsl:value-of
                                    select="
                                        'Unacceptable file type: ',
                                        $fileType"
                                />
                            </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$fileType"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </File:FileType>
                <xsl:copy-of
                    select="
                        $originalExif/rdf:Description/File:FileTypeExtension" copy-namespaces="0"/>
                <xsl:copy-of select="$originalExif/rdf:Description/File:MIMEType"/>
                <RIFF:Description>                    
                    <xsl:value-of
                        select="$DAVIDTitle"
                    />
                </RIFF:Description>
                <xsl:copy-of select="$RIFF:Originator"/>
                <xsl:copy-of select="$RIFF:OriginatorReference"/>
                <xsl:copy-of select="$RIFF:Artist"/>
                <xsl:copy-of select="$RIFF:Commissioned"/>
                <xsl:copy-of select="$RIFF:DateCreated"/>
                <xsl:copy-of select="$RIFF:Keywords"/>
                <xsl:copy-of select="$RIFF:Subject"/>
                <xsl:copy-of select="$RIFF:Software"/>
                <xsl:copy-of select="$RIFF:Source"/>
                <xsl:copy-of select="$RIFF:ArchivalLocation"/>
                <xsl:copy-of select="$RIFF:Comment"/>
                <xsl:copy-of select="$RIFF:Copyright"/>
                <xsl:copy-of select="$RIFF:Engineer"/>
                <xsl:copy-of select="$RIFF:Genre"/>
                <xsl:copy-of select="$RIFF:Medium"/>
                <xsl:copy-of select="$RIFF:Title"/>
                <xsl:copy-of select="$RIFF:Product"/>
                <xsl:copy-of select="$RIFF:SourceForm"/>
                <xsl:copy-of select="$RIFF:Technician[$RIFF:Medium != 'Original']"/>
                <xsl:copy-of select="$originalExif/rdf:Description/RIFF:DateTimeOriginal[. != '']"/>
                <xsl:copy-of select="$originalExif/rdf:Description/RIFF:TimeReference[. != '']"/>
                <xsl:copy-of select="$originalExif/rdf:Description/RIFF:BWFVersion[. != '']"/>
                <xsl:copy-of select="$originalExif/rdf:Description/RIFF:BWF_UMID[. != '']"/>
                <xsl:copy-of select="$RIFF:CodingHistory"/>
                <xsl:if test="not(contains($fileType, 'ASSET'))">
                    <xsl:variable name="exifEncoding"
                        select="
                            ($originalExif/
                            rdf:Description/
                            RIFF:Encoding, 'Microsoft PCM'[$isDigital])[matches(., '\w')][1]"/>
                    <xsl:variable name="encoding">
                        <xsl:apply-templates select="." mode="checkConflicts">
                            <xsl:with-param name="field1" select="$exifEncoding"/>
                            <xsl:with-param name="field2" select="$DAVIDEncoding"/>                       
                            <xsl:with-param name="fieldName" select="'Encoding'"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:variable name="numChannels">
                        <xsl:call-template name="checkConflicts">
                            <xsl:with-param name="fieldName"
                                select="
                                'NumChannels'"/>
                            <xsl:with-param name="field1"
                                select="
                                $originalExif/rdf:Description/
                                RIFF:NumChannels"/>
                            <xsl:with-param name="field2"
                                select="
                                $DAVIDNumChannels"/>
                            
                        </xsl:call-template>
                    </xsl:variable>
                    <!-- Error for WAVE files improperly encoded -->
                    <xsl:if
                        test="
                            upper-case($fileType) = 'WAV' 
                            and not(
                            $exifEncoding = 'Microsoft PCM'
                            )">
                        <xsl:call-template name="
                            generateError">
                            <xsl:with-param name="fieldName" select="'ExifEncoding'"/>
                            <xsl:with-param name="errorType" select="'Invalid encoding: ', $exifEncoding"/>
                        </xsl:call-template>
                    </xsl:if>

                    <RIFF:Encoding>
                        <xsl:value-of select="$encoding"/>
                    </RIFF:Encoding>
                    <RIFF:NumChannels>
                        <xsl:value-of select="$numChannels"/>
                    </RIFF:NumChannels>
                    
                    <xsl:if test="true()">
                        <xsl:message select="'yo is this digital ', $isDigital"/>
                        <xsl:variable name="sampleRate">
                            <xsl:call-template name="checkConflicts">
                                <xsl:with-param name="fieldName" select="
                                    'SampleRate'"/>
                                <xsl:with-param name="field1"
                                    select="
                                    $originalExif/rdf:Description/
                                    RIFF:SampleRate"/>
                                <xsl:with-param name="field2"
                                    select="
                                    $dbxData/ENTRIES/
                                    ENTRY/SAMPLERATE"/>                                
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="bitsPerSample">
                            <xsl:apply-templates select="." mode="checkConflicts">
                                <xsl:with-param name="fieldName"
                                    select="
                                    'BitsPerSample'"
                                />
                                <xsl:with-param name="field1"
                                    select="
                                    $originalExif/rdf:Description/
                                    RIFF:BitsPerSample"/>
                                <xsl:with-param name="field2"
                                    select="
                                    $DAVIDBitDepth"/>                                
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:variable name="AvgBytesPerSec">
                            <xsl:call-template name="checkConflicts">
                                <xsl:with-param name="fieldName" select="
                                    'AvgBytesPerSec'"/>
                                <xsl:with-param name="field1"
                                    select="
                                    $originalExif/rdf:Description/
                                    RIFF:AvgBytesPerSec"/>
                                <xsl:with-param name="field2" select="$DAVIDDataRate"/>
                                <!-- Calculate if not provided -->
                                <xsl:with-param name="defaultValue">
                                    <xsl:choose>
                                        <xsl:when test="
                                            matches($sampleRate, '[0-9]') and 
                                            matches($bitsPerSample, '[0-9]') and 
                                            matches($numChannels, '[0-9]')">
                                            <xsl:value-of select="
                                                format-number(
                                                number($sampleRate) * number($bitsPerSample) * number($numChannels) * 0.125, 
                                                '#')"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="0"/>
                                        </xsl:otherwise>
                                    </xsl:choose>                                    
                                </xsl:with-param>                                
                            </xsl:call-template>
                        </xsl:variable>
                        
                        <RIFF:SampleRate>
                            <xsl:value-of select="$sampleRate"/>
                        </RIFF:SampleRate>
                        <RIFF:AvgBytesPerSec>
                            <xsl:value-of select="$AvgBytesPerSec"/>
                        </RIFF:AvgBytesPerSec>                        
                        <RIFF:BitsPerSample>
                            <xsl:value-of select="$bitsPerSample"/>
                        </RIFF:BitsPerSample>
                    </xsl:if>
                </xsl:if>
                <xsl:copy-of select="$originalExif/rdf:Description/RIFF:CuePoints"/>
                <xsl:copy-of select="$originalExif/rdf:Description/XML:*"/>
                <xsl:copy-of select="$originalExif/rdf:Description/XMP-x:*"/>
                <XMP-dc:Subject>
                    <xsl:choose>
                        <xsl:when test="
                                (not($isSegment) or $isPhysical)">
                            <xsl:copy-of select="$assetKeywordsRDFBag"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="$segmentKeywordsRDFBag"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </XMP-dc:Subject>

                <xsl:copy-of select="$originalExif/rdf:Description/XMP-dc:Format"/>

                <xsl:copy-of select="$originalExif/rdf:Description/XMP-xmp:*"/>
                <xsl:copy-of
                    select="$originalExif/rdf:Description/XMP-xmpDM:*[contains(name(), 'Tracks')]"/>
                <xsl:element name="XMP-xmpDM:Artist">
                    <xsl:copy-of select="$contributorsAsXMP"/>
                </xsl:element>
                <xsl:element name="XMP-xmpDM:Engineer">
                    <xsl:value-of select="normalize-space($RIFF:Engineer)"/>
                </xsl:element>
                <xsl:element name="XMP-xmpDM:Genre">
                    <xsl:value-of select="normalize-space($RIFF:Genre)"/>
                </xsl:element>
                <xsl:element name="XMP-dc:Rights">
                    <xsl:value-of select="normalize-space($RIFF:Copyright)"/>
                </xsl:element>
                <xsl:element name="XMP-dc:Source">
                    <xsl:value-of select="normalize-space($RIFF:Medium)"/>
                </xsl:element>
                <xsl:if
                    test="
                        $transcript ne '' and
                        (not($isSegment) or $isPhysical)">
                    <xsl:element name="XMP-xmpDM:Lyrics">
                        <xsl:value-of select="$transcript"/>
                    </xsl:element>
                </xsl:if>
                <xsl:copy-of select="$originalExif/rdf:Description/XMP-xmpMM:*"/>
                <xsl:copy-of select="$originalExif/rdf:Description/XMP-dc:Format"/>
                <XMP-dc:Description>
                    <xsl:value-of select="normalize-space($descriptionNoHtml)"/>
                </XMP-dc:Description>
                <XMP-plus:ImageSupplierImageID>
                    <xsl:value-of select="$cmsImageID"/>
                </XMP-plus:ImageSupplierImageID>
                <xsl:copy-of select="$originalExif/rdf:Description/Composite:*"/>
                <!-- WNYC special fields -->
                <xsl:copy-of select="$originalExif/rdf:Description/WNYC:*"/>                
            </xsl:element>
        </xsl:variable>

        <xsl:copy-of select="$newExif"/>
        <xsl:for-each select="$newExif/rdf:Description/RIFF:*[normalize-space(.) eq '']">
            <xsl:element name="error">
                <xsl:attribute name="type" select="
                        'empty_field'"/>
                <xsl:value-of select="local-name(.)"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="aapbData"
        match="
            rdf:Description/RIFF:Source
            [starts-with(., 'http://americanarchive.org/catalog/')]">
        <!--Obtain data and transcripts
            from American Archive (AAPB) 
            when an AAPB URL is in the RIFF:Source field -->
        <xsl:variable name="aapbURL" select="."/>
        <xsl:variable name="aapbData" select="document($aapbURL)"/>
        <xsl:copy-of select="$aapbData"/>
    </xsl:template>

    <xsl:template name="aapbData2"
        match="
            rdf:Description/RIFF:Comment
            [contains(., 'http://americanarchive.org/catalog/')]">
        <!--Obtain data and transcripts
            from American Archive (AAPB) 
            when an AAPB URL is in the RIFF:Comment field -->
        <xsl:variable name="aapbURL"
            select="
                concat(
                'http://americanarchive.org/catalog/',
                substring-before(
                substring-after(
                RIFF:Comment, 'http://americanarchive.org/catalog/'),
                '.pbcore'),
                '.pbcore')"/>
        <xsl:variable name="aapbData" select="document($aapbURL)"/>
        <xsl:copy-of select="$aapbData"/>
    </xsl:template>


    <!-- JSON utility templates -->
    <!--<xsl:template
        match="rdf:RDF[starts-with(rdf:Description/RIFF:Comment, 'https://s3.amazonaws.com/americanarchive.org/transcripts/')]">
        <xsl:apply-templates
            select="rdf:Description/RIFF:Comment[starts-with(., 'https://s3.amazonaws.com/americanarchive.org/transcripts/')]"
        />
    </xsl:template>-->

    <xsl:template name="DAVIDdbx" match="
            rdf:Description" mode="DAVIDdbx">
        <!-- Obtain DAVID fields -->
        <xsl:param name="originalExif" select="."/>
        <xsl:param name="welcomeMessage">
            <xsl:message select="
                    'Obtain DBX Data for',
                    $originalExif/
                    (@rdf:about | System:FileName)[1]"/>
        </xsl:param>
        <xsl:param name="fileURI" select="
                translate(concat(System:Directory[1], '/', System:FileName[1]), '\', '/')"/>

        <xsl:param name="fileURInoExt">
            <xsl:value-of select="WNYC:substring-before-last($fileURI, '.')"/>
        </xsl:param>
        <xsl:param name="dbxURI" select="concat($fileURInoExt, '.DBX')"/>
        <xsl:param name="dbxExists">
            <xsl:copy-of select="doc-available($dbxURI)"/>
        </xsl:param>
        <xsl:param name="dbxData">
            <xsl:copy-of select="(document($dbxURI))[$dbxExists]"/>
        </xsl:param>

        <xsl:message select="'Find DBX file for', $fileURI"/>
        <xsl:message select="'DBX exists:', $dbxExists"/>
        <xsl:message>
            <xsl:value-of select="'DBX data:'"/>
            <xsl:copy-of select="$dbxData"/>
        </xsl:message>
        <!-- dbx output -->
        <xsl:copy-of select="$dbxData"/>
    </xsl:template>

    <xsl:template
        match="
            rdf:Description
            [matches(File:FileType, $illegalFileTypes, 'i')]">
        <xsl:param name="badFile" select="."/>
        <xsl:param name="errorType">
            <xsl:value-of select="
                    $badFile/
                    File:FileType"
            />
        </xsl:param>
        <xsl:param name="badFileErrorMessage"
            select="
                'File', $badFile/@rdf:about,
                'is of type', $errorType, '(not acceptable)'"/>
        <xsl:message select="$badFileErrorMessage"/>
        <xsl:element name="error">
            <xsl:attribute name="type" select="'badFile'"/>
            <xsl:value-of select="$badFileErrorMessage"/>
        </xsl:element>
    </xsl:template>

    <xsl:template name="checkDAVIDForDupes" match="
        parsedElements"
        mode="
        checkDAVIDForDupes">
        <xsl:param name="parsedElements" select="."/>
        <xsl:param name="instantiationID" select="
            $parsedElements/instantiationID"/>
        <!-- Check for duplicate instantiation IDs 
            in DAVID -->
        <xsl:message select="
                'Check for duplicate instantiations ',
                'in DAVID for ', $instantiationID"/>        
        <xsl:variable name="matchedDAVIDTitle" select="
            $instantiationIDsInDAVID/instantiationIDs/
            instantiationID[. = $instantiationID]/@DAVIDTitle"/>
        <xsl:for-each
            select="
            $matchedDAVIDTitle">
            <xsl:variable name="DAVIDDupeEntryErrorMessage">
                <xsl:value-of
                    select="                    
                    'ATTENTION!! DAVID Title(s) ',
                    $matchedDAVIDTitle,
                    ' includes instantiation ID pattern',
                    $instantiationID, '. '
                    "
                />
                <xsl:value-of select="'Either change the instantiation ID of the current WAVE file, or delete the DAVID entry.'"/>
            </xsl:variable>
            <xsl:message select="$DAVIDDupeEntryErrorMessage"/>
            <xsl:element name="error">
                <xsl:attribute name="type" select="
                    'instantiationInDAVID'"/>
                <xsl:attribute name="instantiationID" select="
                    $instantiationID"/>
                <xsl:attribute name="titleInDAVID" select="$matchedDAVIDTitle/XMP:EntriesEntryMediumFileTitle"/>
                <xsl:copy-of select="$DAVIDDupeEntryErrorMessage"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="isNewAsset" match="
        rdf:Description" mode="isNewAsset">
        <xsl:param name="sourceRDF" select="."/>
        <xsl:param name="parsedDAVIDTitle">
            <xsl:apply-templates select="
                $sourceRDF/System:FileName[1]" mode="
                parseDAVIDTitle"/>                
        </xsl:param>
        <xsl:param name="assetID" select="
            $parsedDAVIDTitle/parsedDAVIDTitle/parsedElements/assetID"/>        
        <xsl:param name="lowAssetID" select="
            number($assetID) lt 250"/>
        <xsl:param name="tempRIFFSource" select="
                matches(
                $sourceRDF/RIFF:Source, $validatingCatalogSearchString)
                or
                matches(
                $sourceRDF/RIFF:Source, '^NEW')"/>        
        <xsl:copy-of select="
            ($lowAssetID or $tempRIFFSource)"/>        
    </xsl:template>

</xsl:stylesheet>
