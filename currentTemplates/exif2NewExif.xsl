<?xml version="1.0" encoding="UTF-8"?>
<!--This script transforms output from a file 
obtained through an exiftool command of the type

    exiftool -X -a -struct "fileDirectory" > "output.xml"

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
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#" exclude-result-prefixes="#all">

    <xsl:mode on-no-match="deep-skip"/>

    <xsl:import href="Exif2BWF.xsl"/>
    <xsl:import href="Exif2Cavafy.xsl"/>
    <xsl:import href="Exif2Dbx.xsl"/>
    <xsl:import href="cms2BWFMetaEdit.xsl"/>
    <xsl:import href="cavafyQC.xsl"/>

    <xsl:variable name="illegalCharacters">
        <xsl:text>&#x201c;&#x201d;&#xa0;&#x80;&#x93;&#x94;&#xa6;&#x2014;&#x2019;&#x2122;&#x2026;&#x201a;</xsl:text>
        <xsl:text>&#xc2;&#xc3;&#xb1;&#xe2;&#x99;&#x9c;&#x9d;&#x20ac;&#xac;</xsl:text>
    </xsl:variable>
    <xsl:variable name="legalCharacters">
        <xsl:text>"" '——…—''…'</xsl:text>
    </xsl:variable>
    <xsl:variable name="CMSRoles" select="doc('file:CMSRoles.xml')"/>

    <xsl:variable name="validatingCatalogString" select="'https://cavafy.wnyc.org/assets/'"/>
    <xsl:variable name="validatingKeywordString" select="'id.loc.gov/authorities/subjects/'"/>
    <xsl:variable name="validatingNameString" select="'id.loc.gov/authorities/names/'"/>
    <xsl:variable name="separatingToken" select="';'"/>
    <xsl:variable name="separatingTokenLong" select="
        concat(' ', $separatingToken, ' ')"/>
    <!-- To avoid semicolons separating a single field -->
    <xsl:variable name="separatingTokenForFreeTextFields"
        select="'###===###'"/>

    <xsl:template match="rdf:Description">
        <!--Match standard exif output-->
        <xsl:param name="originalExif" select="."/>

        <!--obtain DBX data-->
        <xsl:param name="dbxData">
            <xsl:apply-templates select=".[contains(System:Directory, 'wnycdavidmedia')]"
                mode="DAVIDdbx"/>
        </xsl:param>

        <!-- figure out what the MP3 name is -->
        <xsl:param name="dbxTheme"
            select="
                concat($dbxData
                /ENTRY[contains(FILENAME, 'wnycdavidmedia')]
                /MOTIVE, '.mp3')"/>

        <!--obtain CMS data via its API-->
        <xsl:param name="cmsData">
            <xsl:apply-templates
                select="
                    $dbxData/dbxData/ENTRIES/ENTRY/MOTIVE
                    [. != '']
                    [. != 'news_latest_newscast']"
            />
        </xsl:param>
        <xsl:message>
            <xsl:value-of select="'Process', @rdf:about"/>
        </xsl:message>

        <!-- If the file comes from Archives,
        check its naming convention
        and then parse it-->
        <xsl:if
            test="
                $dbxTheme = '.mp3'
                or
                starts-with($dbxTheme, 'archive_import')">

            <!-- Check the WNYC Archives naming convention -->
            <!-- Parse the title or filename -->
            <xsl:variable name="parsedDAVIDTitle">
                <xsl:choose>
                    <!-- When file is in DAVID,
                    parse its title -->
                    <xsl:when test="contains(System:Directory, 'wnycdavidmedia')">
                        <xsl:message select="concat(System:FileName, ' is in DAVID.')"/>
                        <xsl:message
                            select="'Use ', concat(RIFF:Description, '.', File:FileType), 'to parse.'"/>
                        <xsl:apply-templates select="System:FileName" mode="parseDAVIDTitle">
                            <xsl:with-param name="filenameToParse"
                                select="concat(RIFF:Description, '.', File:FileType)"/>
                        </xsl:apply-templates>
                    </xsl:when>

                    <!-- Otherwise, 
                    use its filename-->
                    <xsl:otherwise>
                        <xsl:apply-templates select="System:FileName" mode="parseDAVIDTitle"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- The cavafy entry corresponding to the file -->
            <!-- Check that this entry is acceptable -->
            <xsl:variable name="cavafyEntry">
                <xsl:apply-templates
                    select="
                        $parsedDAVIDTitle
                        /parsedDAVIDTitle
                        /parsedElements
                        /finalCavafyEntry
                        /pb:pbcoreDescriptionDocument"
                    mode="cavafyQC"/>
            </xsl:variable>

            <xsl:message
                select="
                    'parsed DAVID title: ',
                    $parsedDAVIDTitle"/>
            <xsl:message select="
                    'cavafy entry: ', $cavafyEntry"/>

            <!-- The corresponding instantiation  -->
            <xsl:variable name="instantiationData">
                <xsl:apply-templates select="$parsedDAVIDTitle/parsedElements/instantiationData"/>
            </xsl:variable>

            <!-- Cavafy series data,
                with information often used as default-->
            <xsl:variable name="seriesData">
                <xsl:copy-of select="$parsedDAVIDTitle//parsedElements/seriesData"/>
            </xsl:variable>

            <xsl:variable name="allInputs">
                <inputs>
                    <xsl:element name="originalExif">
                        <xsl:copy-of select="$originalExif"/>
                    </xsl:element>
                    <xsl:copy-of select="$parsedDAVIDTitle"/>
                    <xsl:copy-of select="$cavafyEntry"/>
                    <!--                    <xsl:copy-of select="$seriesData"/>-->
                    <xsl:copy-of select="$instantiationData"/>
                    <xsl:copy-of select="$dbxData"/>
                    <xsl:copy-of select="$cmsData"/>
                </inputs>
            </xsl:variable>
            <xsl:variable name="newExif">
                <newExif>
                    <xsl:apply-templates select="$allInputs/inputs" mode="newExif"/>
                </newExif>
            </xsl:variable>
            <result>
                <xsl:attribute name="filename" select="$originalExif/System:FileName"/>
                <xsl:copy-of select="$allInputs"/>
                <xsl:copy-of select="$newExif"/>
            </result>
        </xsl:if>

    </xsl:template>

    <xsl:template name="newExif" match="inputs" mode="newExif">
        <!-- Generate a new rdf:Description document 
        by merging and checking various sources -->
        <xsl:param name="originalExif" select="/inputs/originalExif"/>
        <xsl:param name="parsedDAVIDTitle" select="/inputs/parsedDAVIDTitle"/>
        <xsl:param name="inDAVID" select="inDAVID"/>
        <xsl:param name="cavafyEntry"
            select="/inputs/parsedDAVIDTitle/parsedElements/finalCavafyEntry"/>
        <xsl:param name="seriesData" select="/inputs/parsedDAVIDTitle/parsedElements/seriesData"/>
        <xsl:param name="instantiationData" select="/inputs/instantiationData"/>
        <xsl:param name="dbxData" select="/inputs/dbxData"/>
        <xsl:param name="cmsData" select="/inputs/cmsData"/>
        <xsl:param name="validatingCatalogString" select="$validatingCatalogString"/>
        <xsl:param name="validatingKeywordString" select="$validatingKeywordString"/>
        <xsl:param name="validatingNameString" select="$validatingNameString"/>

        <xsl:message> ******** GENERATE NEW COMBINED EXIF *********</xsl:message>

        <!-- LET THE MERGING BEGIN -->

        <!-- Basics -->
        <xsl:variable name="filenameTranslated">
            <xsl:value-of select="translate($originalExif/rdf:Description/@rdf:about, '/', '\')"/>
        </xsl:variable>

        <!-- Asset ID -->
        <xsl:variable name="assetID" select="$parsedDAVIDTitle/parsedElements/assetID"/>

        <!-- MUNI ID -->
        <xsl:variable name="MuniID">
            <xsl:apply-templates select="." mode="checkConflicts">
                <xsl:with-param name="field1" select="$parsedDAVIDTitle/parsedElements/muniNumber"/>
                <xsl:with-param name="field2"
                    select="$cavafyEntry/pb:pbcoreDescriptionDocument/pb:pbcoreIdentifier[@source = 'Municipal Archives']"/>
                <xsl:with-param name="fieldName" select="'MuniID'"/>
            </xsl:apply-templates>
        </xsl:variable>


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
        <xsl:variable name="parsedGeneration"
            select="$parsedDAVIDTitle/parsedElements/parsedGeneration"/>
        <xsl:message select="'Parsed generation:', $parsedGeneration"/>
        <xsl:variable name="generation">
            <xsl:apply-templates select="." mode="checkConflicts">
                <xsl:with-param name="field1" select="$parsedGeneration"/>
                <xsl:with-param name="field2"
                    select="
                        $instantiationData
                        /pb:pbcoreInstantiation
                        /pb:instantiationGenerations"/>
                <xsl:with-param name="fieldName" select="'Generation'"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:message select="'Generation: ', $generation"/>
        <xsl:variable name="instantiationSegmentSuffix"
            select="
                $parsedDAVIDTitle
                //parsedElements/instantiationSegmentSuffix"/>
        <xsl:variable name="segmentFlag"
            select="
                $parsedDAVIDTitle
                //parsedElements/segmentFlag"/>

        <xsl:variable name="producingOrganizations">
            <!-- Culled from CMS data -->
            <xsl:choose>
                <xsl:when
                    test="
                        normalize-space(
                        $cmsData
                        /data/attributes/
                        producing-organizations)">
                    <xsl:value-of
                        select="
                            $cmsData
                            /data/attributes
                            /producing-organizations/name"
                        separator=" ; "/>
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

        <!--1. Collection (and archival location)-->
        <!--Embedded collection is of the type 'US, WNYC' 
                    So we look after the comma-->
        <xsl:variable name="exifCollection">
            <xsl:copy-of
                select="
                    $originalExif
                    /rdf:Description/RIFF:Collection
                    /substring-after(., ',')"
            />
        </xsl:variable>
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
            <xsl:apply-templates select="." mode="checkConflicts">
                <xsl:with-param name="field1" select="$exifCollection"/>
                <xsl:with-param name="field2"
                    select="
                        $collectionInfo
                        /collAcro"/>
                <xsl:with-param name="field3" select="$producingOrganizations"/>
                <xsl:with-param name="fieldName" select="'Collection'"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="collectionName">
            <xsl:value-of select="$collectionInfo/collName"/>
        </xsl:variable>

        <xsl:variable name="collectionLocation">
            <xsl:value-of select="$collectionInfo/collLocation"/>
        </xsl:variable>

        <xsl:variable name="RIFF:ArchivalLocation">
            <RIFF:ArchivalLocation>
                <xsl:copy-of select="$collection[//error]"/>
                <xsl:value-of
                    select="
                        concat(
                        $collectionLocation, ', ',
                        normalize-space($collection[not(//error)]))"
                />
            </RIFF:ArchivalLocation>
        </xsl:variable>

        <!-- 2. Merge all Creators, Producers, Hosts, Publishers 
            as 'RIFF:Commissioned' -->
        <xsl:variable name="exiftoolCommissioned"
            select="
                $originalExif/rdf:Description/RIFF:Commissioned"/>
        <xsl:variable name="assetCreatorsPublishers">
            <xsl:value-of
                select="
                    $cavafyEntry/pb:pbcoreDescriptionDocument
                    /pb:*/(pb:creator | pb:publisher)
                    /@ref[contains(., $validatingNameString)]"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>

        <xsl:variable name="cmsPeople"
            select="
                $cmsData/data/attributes
                /appearances"/>
        <xsl:variable name="cmsCreators">
            <xsl:value-of
                select="
                    $cmsPeople/(producers | authors | hosts)/name"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>

        <xsl:variable name="seriesCreatorsPublishers">
            <xsl:value-of
                select="
                    $seriesData/pb:pbcoreDescriptionDocument
                    /pb:*/(pb:creator | pb:publisher)
                    /@ref[contains(., $validatingNameString)]"
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
                <xsl:with-param name="field1" select="$exiftoolCommissioned"/>
                <xsl:with-param name="field2" select="$assetCreatorsPublishers"/>
                <xsl:with-param name="field3" select="$cmsCreators"/>
                <xsl:with-param name="defaultValue" select="$defaultCreatorsPublishers"/>
                <xsl:with-param name="validatingString" select="$combinedValidatingStrings"/>
                <xsl:with-param name="fieldName" select="'Creators'"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="RIFF:Commissioned">
            <xsl:comment select="'Exif commissioned: ', $exiftoolCommissioned"/>
            <xsl:comment select="'Cavafy creators and publishers: ', $assetCreatorsPublishers"/>
            <xsl:comment select="'CMS creators: ', $cmsCreators"/>            
            <RIFF:Commissioned>
                <xsl:choose>
                    <xsl:when test="not(contains($generation, 'segment'))">
                        <xsl:value-of select="$mergedCommissioned"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="mergeData">
                            <xsl:with-param name="field1" select="$exiftoolCommissioned"/>                    
                            <xsl:with-param name="defaultValue" select="$mergedCommissioned"/>                                            
                            <xsl:with-param name="validatingString" select="$combinedValidatingStrings"/>
                            <xsl:with-param name="fieldName" select="'Creators'"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </RIFF:Commissioned>
        </xsl:variable>

        <!-- 3. Contributors as RIFF:Artist -->
        <xsl:variable name="exiftoolArtists" select="
            $originalExif/rdf:Description/RIFF:Artist"/>
        <xsl:variable name="cavafyContributors">
            <xsl:value-of
                select="
                    $cavafyEntry/pb:pbcoreDescriptionDocument
                    /pb:pbcoreContributor/pb:contributor
                    /@ref[contains(., $validatingNameString)]"
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
                    /@ref[contains(., $validatingNameString)]"
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

        <xsl:variable name="RIFF:Artist">
            <xsl:comment select="'Exif artists: ', $exiftoolArtists"/>
            <xsl:comment select="'Cavafy contributors: ', $cavafyContributors"/>
            <xsl:comment select="'CMS contributors: ', $cmsContributors"/>
            <xsl:variable name="mergedArtists">
                <xsl:apply-templates select="." mode="mergeData">
                    <xsl:with-param name="field1" select="$exiftoolArtists"/>
                    <xsl:with-param name="field2" select="$cavafyContributors"/>
                    <xsl:with-param name="field3" select="$cmsAllContributors"/>
                    <xsl:with-param name="defaultValue" select="$defaultArtists"/>
                    <xsl:with-param name="validatingString" select="$validatingNameString"/>
                    <xsl:with-param name="fieldName" select="'Contributors'"/>
                </xsl:apply-templates>
            </xsl:variable>
            <RIFF:Artist>
                <xsl:choose>
                    <xsl:when test="not(contains($generation, 'segment'))">
                        <xsl:value-of select="$mergedArtists"/>
                    </xsl:when>
                    <xsl:when test="contains($generation, 'segment')">
                        <xsl:variable name="segmentArtistWarning" select="
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
                <xsl:value-of
                    select="
                    translate(
                    $parsedDAVIDTitle/parsedElements/DAVIDTitleDateTranslated, 
                    ':', '-'
                    )"
                />
            </RIFF:DateCreated>
        </xsl:variable>


        <!-- 5. Genre -->
        <xsl:variable name="seriesGenre">
            <xsl:value-of select="
                $seriesData
                //pb:pbcoreDescriptionDocument
                /pb:pbcoreGenre"/>
        </xsl:variable>

        <xsl:variable name="RIFF:Genre">
            <RIFF:Genre>
                <xsl:choose>
                    <xsl:when test="not(contains($generation, 'segment'))">
                        <xsl:apply-templates select="." mode="checkConflicts">
                            <xsl:with-param name="field1"
                                select="$originalExif
                                /rdf:Description/RIFF:Genre"/>
                            <xsl:with-param name="field2"
                                select="$cavafyEntry
                                /pb:pbcoreDescriptionDocument/pb:pbcoreGenre"/>
                            <xsl:with-param name="defaultValue" select="$seriesGenre"/>
                            <xsl:with-param name="fieldName" select="'Genre'"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="segmentGenreWarning"
                            select="'Make sure the genre for', 
                            $parsedDAVIDTitle/parsedElements/DAVIDTitle, 
                            'segment is right!'"/>
                        <xsl:message select="$segmentGenreWarning"/>
                        <xsl:comment select="$segmentGenreWarning"/>
                        <xsl:apply-templates select="." mode="checkConflicts">
                            <xsl:with-param name="field1"
                                select="$originalExif/rdf:Description/RIFF:Genre"/>
                            <xsl:with-param name="defaultValue"
                                select="$cavafyEntry
                                /pb:pbcoreDescriptionDocument/pb:pbcoreGenre"/>
                            <xsl:with-param name="fieldName" select="'Genre'"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </RIFF:Genre>
        </xsl:variable>

        <!--Title-->

        <xsl:variable name="ASCIIfiedCavafyTitle">
            <xsl:call-template name="ASCIIFy">
                <xsl:with-param name="inputText"
                    select="
                        $cavafyEntry/pb:pbcoreDescriptionDocument
                        /pb:pbcoreTitle[@titleType = 'Episode']"
                />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="ASCIIfiedExifTitle">
            <xsl:call-template name="ASCIIFy">
                <xsl:with-param name="inputText"
                    select="
                        $originalExif/rdf:Description/RIFF:Title"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="RIFF:Title">
            <!--This is dealt differently when audio is a segment-->
            <RIFF:Title>
                <xsl:choose>
                    <!--Audio is not a segment-->
                    <xsl:when test="not(contains($generation, 'segment'))">
                        <xsl:apply-templates select="." mode="checkConflicts">
                            <xsl:with-param name="field1"
                                select="
                                    $ASCIIfiedExifTitle
                                    /ASCIIResult/ASCIIFiedText"/>
                            <xsl:with-param name="field2"
                                select="
                                    $ASCIIfiedCavafyTitle
                                    /ASCIIResult/ASCIIFiedText"/>
                            <xsl:with-param name="fieldName"
                                select="
                                    'Title'"/>
                            <!-- To avoid semicolons separating a single field -->
                            <xsl:with-param name="separatingToken"
                                select="
                                    $separatingTokenForFreeTextFields"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <!--Audio is a clip or segment-->
                    <xsl:otherwise>
                        <xsl:variable name="warningMessage"
                            select="
                                'Make sure the title for',
                                $parsedDAVIDTitle/parsedElements/DAVIDTitle,
                                'segment is right!'
                                "/>
                        <xsl:message select="$warningMessage"/>
                        <xsl:comment select="$warningMessage"/>
                        <xsl:variable name="defaultSegmentTitle">
                            <!-- Create a default segment title based on an existing asset title-->
                            <xsl:if test="$ASCIIfiedCavafyTitle/ASCIIResult/ASCIIFiedText != ''">
                                <xsl:value-of
                                    select="$ASCIIfiedCavafyTitle/ASCIIResult/ASCIIFiedText"/>
                                <!-- Add the part bit to the default title -->
                                <!-- From the instantiation segment bit -->
                                <xsl:value-of
                                    select="
                                        $instantiationSegmentSuffix/concat(', Part ', $instantiationSegmentSuffix)"/>
                                <!-- ...or from the segment flag -->
                                <xsl:if test="empty($instantiationSegmentSuffix)">
                                    <xsl:value-of select="$segmentFlag/concat(' (', ., ')')"/>
                                </xsl:if>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:call-template name="checkConflicts">
                            <xsl:with-param name="field1"
                                select="
                                    $ASCIIfiedExifTitle
                                    /ASCIIResult
                                    /ASCIIFiedText"/>
                            <xsl:with-param name="defaultValue" select="$defaultSegmentTitle"/>
                            <xsl:with-param name="fieldName" select="'SegmentTitle'"/>
                            <xsl:with-param name="separatingToken" select="$separatingTokenForFreeTextFields"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </RIFF:Title>
        </xsl:variable>

        <!--Description as RIFF:Subject-->
        <xsl:variable name="ASCIIfiedExifSubject">
            <xsl:call-template name="ASCIIFy">
                <xsl:with-param name="inputText"
                    select="
                        normalize-space($originalExif/rdf:Description/RIFF:Subject)"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="ASCIIfiedCavafyAbstract">
            <xsl:call-template name="ASCIIFy">
                <xsl:with-param name="inputText"
                    select="
                        $cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreDescription
                        [@descriptionType = 'Abstract']
                        [. ne 'No Description available']
                        [not(//error)]"
                />
            </xsl:call-template>
        </xsl:variable>
        <xsl:message
            select="
                'ASCIIFied Asbtract: ',
                $ASCIIfiedCavafyAbstract"/>
        <xsl:variable name="defaultAbstract">
            <xsl:value-of
                select="
                    if ($ASCIIfiedCavafyAbstract/ASCIIResult/ASCIIFiedText != '')
                    then
                        $ASCIIfiedCavafyAbstract/ASCIIResult/ASCIIFiedText
                    else
                        concat(
                        $cavafyEntry/pb:pbcoreDescriptionDocument/pb:pbcoreTitle[@titleType = 'Episode'],
                        ' on ',
                        $cavafyEntry/pb:pbcoreDescriptionDocument/pb:pbcoreTitle[@titleType = 'Series'],
                        ' on ',
                        $parsedDAVIDTitle/parsedElements/DAVIDTitleDate)"
            />
        </xsl:variable>
        <xsl:variable name="description">
            <!--This is dealt differently when audio is a segment-->
            <xsl:choose>
                <!-- Audio is not a clip-->
                <xsl:when test="not(contains($generation, 'segment'))">
                    <xsl:apply-templates select="." mode="checkConflicts">
                        <xsl:with-param name="field1"
                            select="$ASCIIfiedExifSubject/ASCIIResult/ASCIIFiedText"/>
                        <xsl:with-param name="field2"
                            select="
                            $ASCIIfiedCavafyAbstract/ASCIIResult/ASCIIFiedText"/>
                        <xsl:with-param name="fieldName" select="'Description'"/>
                        <!-- To avoid semicolons separating a single field -->
                        <xsl:with-param name="separatingToken" select="$separatingTokenForFreeTextFields"/>
                        <xsl:with-param name="defaultValue" select="$defaultAbstract"/>
                    </xsl:apply-templates>
                </xsl:when>
                <!-- Audio is a clip or segment -->
                <xsl:when test="contains($generation, 'segment')">
                    <xsl:variable name="warningMessage"
                        select="
                            'Make sure the description for',
                            $parsedDAVIDTitle/parsedElements/DAVIDTitle,
                            'segment is right!'"/>
                    <xsl:message select="$warningMessage"/>
                    <xsl:comment select="$warningMessage"/>
                    <xsl:variable name="defaultSegmentDescription">
                        <!-- Create a default segment description based on an existing asset title-->
                        <xsl:if
                            test="
                                $ASCIIfiedCavafyAbstract/ASCIIResult/ASCIIFiedText != ''">
                            <!-- Add the segment bits -->
                            <xsl:value-of
                                select="
                                    if ($instantiationSegmentSuffix)
                                    then
                                        concat('Part ', $instantiationSegmentSuffix, ' of: &#x0D;')
                                    else
                                        if ($segmentFlag)
                                        then
                                            concat($segmentFlag, ' OF: &#x0D;')
                                        else
                                            ''"/>
                            <xsl:value-of
                                select="
                                    $defaultAbstract
                                    "
                            />
                        </xsl:if>
                    </xsl:variable>
                    <xsl:call-template name="checkConflicts">
                        <xsl:with-param name="field1"
                            select="
                                $ASCIIfiedExifSubject
                                /ASCIIResult/ASCIIFiedText"/>
                        <xsl:with-param name="defaultValue" select="$defaultSegmentDescription"/>
                        <xsl:with-param name="separatingToken" select="$separatingTokenForFreeTextFields"/>
                        <xsl:with-param name="fieldName" select="'SegmentDescription'"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="descriptionNoHtml">
            <xsl:call-template name="strip-tags">
                <xsl:with-param name="text" select="
                    $description[not(//error)]"/>
            </xsl:call-template>
            <xsl:copy-of select="$description[//error]"/>
        </xsl:variable>

        <xsl:variable name="RIFF:Subject">
            <RIFF:Subject>
                <xsl:copy-of select="$descriptionNoHtml"/>
            </RIFF:Subject>
        </xsl:variable>

        <!--Medium-->
        <xsl:variable name="pbcorePhysicalMediums" select="
            doc('http://metadataregistry.org/vocabulary/show/id/462.xsd')"/>
        <xsl:variable name="cavafyFormats" select="
            doc('cavafyFormats.xml')"/>
        <xsl:variable name="acceptableMediums">
            <xsl:value-of select="'Audio material|'"/>
            <xsl:value-of select="
                $cavafyFormats/cavafyFormats/format"
                separator="|"/>
        </xsl:variable>
        <xsl:message select="
            $acceptableMediums"/>

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
        <xsl:variable name="RIFF:Medium">
            <RIFF:Medium>
                <xsl:variable name="capitalizedMedium" select="
                    WNYC:Capitalize($originalMedium, 1)"/>
                <xsl:if test="
                    not(
                    matches(
                    $capitalizedMedium, 
                    $acceptableMediums))">
                    <xsl:element name="error">
                        <xsl:attribute name="type" select="unacceptableMedium"/>
                        <xsl:value-of select="
                            'Medium', $capitalizedMedium, 
                            'is not an acceptable medium.', 
                            'Acceptable mediums include', 
                            $acceptableMediums"/>
                    </xsl:element>
                </xsl:if>
                <xsl:copy-of select="WNYC:Capitalize($originalMedium, 1)"/>
            </RIFF:Medium>
        </xsl:variable>

        <!-- Series as RIFF:Product-->
        <xsl:variable name="RIFF:Product">
            <RIFF:Product>
                <xsl:apply-templates select="." mode="checkConflicts">
                    <xsl:with-param name="field1"
                        select="$originalExif/rdf:Description/RIFF:Product"/>
                    <xsl:with-param name="field2"
                        select="$cavafyEntry/pb:pbcoreDescriptionDocument/pb:pbcoreTitle[@titleType = 'Series']"/>
                    <xsl:with-param name="field3"
                        select="$parsedDAVIDTitle/parsedElements/seriesName"/>
                    <xsl:with-param name="fieldName" select="'Series'"/>
                </xsl:apply-templates>
            </RIFF:Product>
        </xsl:variable>

        <!-- cavafy URL as RIFF:Source-->
        <!-- the cavafy URL has historically been embedded in different places -->
        <xsl:variable name="embeddedCatalogURL">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="field1"
                    select="
                        $originalExif
                        /rdf:Description
                        /RIFF:Source
                        [contains(., $validatingCatalogString)]"/>
                <xsl:with-param name="field2"
                    select="
                        $originalExif
                        /rdf:Description
                        /XMP-WNYCSchema:CatalogURL
                        [contains(., $validatingCatalogString)]"/>
                <xsl:with-param name="field3"
                    select="
                        $originalExif
                        /rdf:Description
                        /RIFF:Comment
                        [starts-with(., $validatingCatalogString)]"/>
                <xsl:with-param name="field4">
                    <xsl:copy-of
                        select="
                            analyze-string(
                            $originalExif
                            /rdf:Description
                            /RIFF:Comment
                            [starts-with(., 'For additional details')],
                            concat($validatingCatalogString, '[0-z,-]*')
                            )
                            /fn:match[1]"
                    />
                </xsl:with-param>
                <xsl:with-param name="fieldName" select="'embeddedURL'"/>
                <xsl:with-param name="defaultValue" select="''"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="RIFF:Source">
            <RIFF:Source>
                <xsl:choose>
                    <xsl:when test="$originalExif/rdf:Description/File:FileType = 'NEWASSET'">
                        <!-- There is no cavafy asset yet, so we give it a search URL -->
                        <xsl:value-of
                            select="
            concat('https://cavafy.wnyc.org/?q=', $parsedDAVIDTitle/parsedElements/assetID, '&amp;search_fields[]=identifier')"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="checkConflicts">
                            <xsl:with-param name="field1" select="$embeddedCatalogURL"/>
                            <xsl:with-param name="field2"
                                select="$parsedDAVIDTitle/parsedElements/finalCavafyURL"/>
                            <xsl:with-param name="fieldName" select="'CatalogURL'"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </RIFF:Source>
        </xsl:variable>

        <!-- Copyright info -->
        <xsl:variable name="ASCIIFiedExifCopyright">
            <xsl:call-template name="ASCIIFy">
                <xsl:with-param name="inputText"
                    select="
                        $originalExif
                        /rdf:Description
                        /RIFF:Copyright"
                />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="ASCIIFiedCavafyCopyright">
            <xsl:call-template name="ASCIIFy">
                <xsl:with-param name="inputText"
                    select="
                        $cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreRightsSummary
                        /pb:rightsSummary"
                />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="ASCIIFiedSeriesCopyright">
            <xsl:call-template name="ASCIIFy">
                <xsl:with-param name="inputText"
                    select="
                        $seriesData
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreRightsSummary
                        /pb:rightsSummary"
                />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="defaultCopyright"
            select="
            if ($ASCIIFiedSeriesCopyright/ASCIIResult/ASCIIFiedText != '')
                then
                $ASCIIFiedSeriesCopyright/ASCIIResult/ASCIIFiedText
                else
                    concat(
                    'Terms of Use and Reproduction: ',
                    $parsedDAVIDTitle/parsedElements/collectionName, '.',
                    ' Additional copyright may apply to musical selections.')"/>
        <xsl:variable name="RIFF:Copyright">

            <RIFF:Copyright>
                <xsl:apply-templates select="." mode="checkConflicts">
                    <xsl:with-param name="field1"
                        select="$ASCIIFiedExifCopyright/ASCIIResult/ASCIIFiedText"/>
                    <xsl:with-param name="field2"
                        select="$ASCIIFiedCavafyCopyright/ASCIIResult/ASCIIFiedText"/>
                    <xsl:with-param name="defaultValue" select="$defaultCopyright"/>
                    <xsl:with-param name="fieldName" select="'Copyright'"/>
                    <!-- To avoid semicolons separating a single field -->
                    <xsl:with-param name="separatingToken" select="$separatingTokenForFreeTextFields"/>
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


        <!-- Provenance as RIFF:SourceForm-->
        <xsl:variable name="defaultProvenance">
            <xsl:choose>
                <xsl:when test="$collection = 'MUNI'">
                    <xsl:value-of
                        select="concat('BWF created from the original WNYC Municipal Archives ', $originalMedium)"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="concat($collectionName, ' ', $originalMedium, ' ', $generation, ' from ', $assetID)"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="cavafyProvenance"
            select="$cavafyEntry/pb:pbcoreDescriptionDocument/pb:pbcoreAnnotation[@annotationType = 'Provenance'][. ne '']"/>
        <xsl:variable name="exifProvenance" select="$originalExif/rdf:Description/RIFF:SourceForm"/>

        <xsl:variable name="provenance">
            <xsl:apply-templates select="." mode="checkConflicts">
                <xsl:with-param name="field1" select="$cavafyProvenance"/>
                <xsl:with-param name="field2" select="$exifProvenance"/>
                <xsl:with-param name="defaultValue" select="$defaultProvenance"/>
                <xsl:with-param name="fieldName" select="'Provenance'"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="RIFF:SourceForm">
            <RIFF:SourceForm>
                <xsl:copy-of select="$provenance"/>
            </RIFF:SourceForm>
        </xsl:variable>

        <!-- Engineers and Technicians -->
        <xsl:variable name="seriesEngineers"
            select="
                $seriesData/pb:pbcoreDescriptionDocument
                /pb:pbcoreContributor/pb:contributor
                [contains(contributorRole, 'ngineer')]/contributor"/>
        <xsl:variable name="defaultEngineers">
            <xsl:value-of
                select="
                    if
                    ($seriesEngineers)
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
                    $dbxData/ENTRY/(AUTHOR | EDITOR))"
                separator=" ; "/>
        </xsl:variable>
        <xsl:variable name="RIFF:Engineer">
            <RIFF:Engineer>
                <xsl:apply-templates select="." mode="mergeData">
                    <xsl:with-param name="field1"
                        select="
                            $originalExif/rdf:Description/
                            RIFF:Engineer"/>
                    <xsl:with-param name="field2"
                        select="
                            $cavafyEntry/pb:pbcoreDescriptionDocument
                            /pb:pbcoreContributor/pb:contributor
                            [contains(contributorRole, 'ngineer')]
                            /contributor"/>
                    <xsl:with-param name="field3" select="$DAVIDEngineers"/>
                    <xsl:with-param name="defaultValue" select="$defaultEngineers"/>
                    <xsl:with-param name="fieldName" select="'Engineers'"/>
                </xsl:apply-templates>
            </RIFF:Engineer>
        </xsl:variable>


        <xsl:variable name="defaultTechnician">
            <xsl:apply-templates select="." mode="checkConflicts">
                <xsl:with-param name="field1" select="$originalExif/rdf:Description/RIFF:Originator"/>
                <xsl:with-param name="field2" select="$dbxData/ENTRY/CREATOR"/>
                <xsl:with-param name="defaultValue" select="'ARCHIVES'"/>
                <xsl:with-param name="fieldName" select="'DefaultTechnician'"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="RIFF:Technician">
            <RIFF:Technician>
                <xsl:apply-templates select="." mode="checkConflicts">
                    <xsl:with-param name="field1"
                        select="
                            $originalExif/rdf:Description
                            /RIFF:Technician"/>
                    <xsl:with-param name="defaultValue" select="$defaultTechnician"/>
                    <xsl:with-param name="fieldName" select="'Technician'"/>
                </xsl:apply-templates>
            </RIFF:Technician>
        </xsl:variable>

        <!-- Coding history -->
        <xsl:variable name="RIFF:CodingHistory">
            <xsl:variable name="goodExifCodingHistory">
                <xsl:value-of
                    select="
                        normalize-space(
                        $originalExif/rdf:Description
                        /RIFF:CodingHistory
                        [not(contains(., 'D.A.V.I.D'))]
                        [not(contains(., 'udio material'))]
                        )"
                />
            </xsl:variable>
            <xsl:variable name="defaultCodingHistory">
                <xsl:value-of
                    select="
                        concat(
                        'Transfer from ',
                        $parsedDAVIDTitle/parsedElements/collectionName,
                        ' ', $originalMedium, '.'
                        )"
                />
            </xsl:variable>
            <RIFF:CodingHistory>
                <xsl:apply-templates select="." mode="checkConflicts">
                    <xsl:with-param name="field1" select="$goodExifCodingHistory"/>
                    <xsl:with-param name="defaultValue" select="$defaultCodingHistory"/>
                    <xsl:with-param name="separatingToken" select="$separatingTokenForFreeTextFields"/>
                    <xsl:with-param name="fieldName" select="'CodingHistory'"/>
                </xsl:apply-templates>
                <xsl:if
                    test="
                        $originalExif/rdf:Description/XMP-WNYCSchema:Stylus_size
                        and
                        not(
                        contains($originalExif/rdf:Description/RIFF:CodingHistory, 'Stylus size:')
                        )">
                    <xsl:value-of
                        select="
                            concat(
                            '&#xA;Stylus size: ',
                            $originalExif/rdf:Description/XMP-WNYCSchema:Stylus_size
                            )"
                    />
                </xsl:if>
                <xsl:if
                    test="
                        $originalExif/rdf:Description/XMP-WNYCSchema:LF_turnover
                        and
                        not(
                        contains($originalExif/rdf:Description/RIFF:CodingHistory, 'Turnover:')
                        )">
                    <xsl:value-of
                        select="
                            concat(
                            '&#xA;Turnover: ',
                            rdf:Description/XMP-WNYCSchema:LF_turnover, ' Hz'
                            )"
                    />
                </xsl:if>
                <xsl:if
                    test="
                        $originalExif
                        /rdf:Description
                        /XMP-WNYCSchema:Tag_0kHz_att
                        and
                        not(
                        contains(
                        $originalExif
                        /rdf:Description
                        /RIFF:CodingHistory,
                        'Att. at 10kHz'
                        )
                        )">
                    <xsl:value-of
                        select="
                            concat(
                            '&#xA;Att. at 10kHz: ',
                            $originalExif
                            /rdf:Description
                            /XMP-WNYCSchema:Tag_0kHz_att,
                            ' dB'
                            )"
                    />
                </xsl:if>
                <xsl:if
                    test="
                        $originalExif
                        /rdf:Description
                        /XMP-WNYCSchema:Rumble_filter
                        and
                        not(
                        contains(
                        $originalExif
                        /rdf:Description
                        /RIFF:CodingHistory,
                        'Rumble filter'
                        ))">
                    <xsl:value-of
                        select="
                            concat(
                            '&#xA;Rumble filter: ',
                            $originalExif
                            /rdf:Description
                            /XMP-WNYCSchema:Rumble_filter,
                            ' Hz'
                            )"
                    />
                </xsl:if>
            </RIFF:CodingHistory>
        </xsl:variable>

        <!-- Transcript -->
        <xsl:variable name="transcript">
            <xsl:variable name="exifTranscript"
                select="$originalExif/rdf:Description/XMP-xmpDM:Lyrics"/>
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

        <!--Subject headings and keywords-->

        <xsl:variable name="cavafySubjects">
            <xsl:value-of
                select="
                    $cavafyEntry/pb:pbcoreDescriptionDocument
                    /pb:pbcoreSubject
                    /@ref[matches(., $combinedValidatingStrings)]"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="exifKeywords">
            <xsl:value-of select="
                    $originalExif/rdf:Description/RIFF:Keywords"
            />
        </xsl:variable>
        <!-- Artist names and fields of activity
        as subjects-->
        <xsl:variable name="LOCOccupationsAndFieldsOfActivity">
            <xsl:call-template name="LOCOccupationsAndFieldsOfActivity">
                <xsl:with-param name="artists"
                    select="
                        $RIFF:Artist/RIFF:Artist"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="exifSubjectsAndKeywords">
            <xsl:value-of
                select="
                    $exifKeywords[. != ''] |
                    $LOCOccupationsAndFieldsOfActivity[. != '']"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="subjectsKeywordsOccupationsAndFieldsOfActivity">
            <xsl:value-of
                select="
                    $cavafySubjects[. != ''] |
                    $exifKeywords[. != ''] |
                    $LOCOccupationsAndFieldsOfActivity[. != '']"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:message select="
            'Narrowize', 
            $subjectsKeywordsOccupationsAndFieldsOfActivity"/>
        <xsl:variable name="exifSubjectsAndKeywordsNarrowed">
            <xsl:apply-templates select="
                    $exifSubjectsAndKeywords"
                mode="
                narrowSubjects"/>
        </xsl:variable>
        <xsl:variable name="subjectsAndKeywordsNarrowed">
            <xsl:apply-templates select="$subjectsKeywordsOccupationsAndFieldsOfActivity"
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
                    $exifSubjectsAndKeywordsNarrowed
                    /madsrdf:*/@rdf:about
                    [matches(., $combinedValidatingStrings)]"
                separator="{$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="subjectsAndKeywordsNarrowedRef">
            <xsl:value-of
                select="
                    $subjectsAndKeywordsNarrowed
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

        <xsl:comment select="
                'Exif keywords: ', $exifKeywords"/>
        <xsl:comment select="
                'Cavafy subject headings: ', $cavafySubjects"/>
        <xsl:variable name="segmentKeywords">
            <xsl:call-template name="mergeData">
                <xsl:with-param name="field1">
                    <xsl:value-of
                        select="
                            $exifSubjectsAndKeywordsNarrowedRef
                            "
                    />
                </xsl:with-param>
                <xsl:with-param name="defaultValue" select="
                        $assetKeywords"/>
                <xsl:with-param name="fieldName" select="
                        'segmentKeywords'"
                />
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
                <xsl:when
                    test="
                        not(
                        contains($generation, 'segment')
                        )">
                    <RIFF:Keywords>
                        <xsl:value-of select="$assetKeywords"/>
                    </RIFF:Keywords>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="message"
                        select="concat(
                            'Make sure the keywords for ',
                            $parsedDAVIDTitle
                            /parsedElements
                            /DAVIDTitle,
                            ' segment are right!'
                            )"/>
                    <xsl:message select="$message"/>
                    <xsl:comment select="$message"/>
                    <RIFF:Keywords>
                        <xsl:value-of select="
                                $segmentKeywords"/>
                    </RIFF:Keywords>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Various and sundry comments -->
        <xsl:variable name="RIFF:Comment">
            <!-- The original embedded comment -->            
            <xsl:variable name="exifComment"
                select="
                    $originalExif
                    /rdf:Description
                    /RIFF:Comment"/>
            <!-- Embedded cavafy-url comment -->            
            <xsl:variable name="cavafyURLComment"
                select="
                    $RIFF:Source
                    [starts-with(., $validatingCatalogString)]
                    /concat('For additional details see ', .)"/>
            <!-- Approximate date comment -->
            <xsl:variable name="approximateDateComment"
                select="
                    if (
                    contains($parsedDAVIDTitle/parsedElements/DAVIDTitleDate, 'u')
                    )
                    then
                        concat(
                        '&#xA;Date is approximate. Given date is ',
                        $parsedDAVIDTitle/parsedElements/DAVIDTitleDate, '.'
                        )
                    else
                        ''"/>
            <!-- AAPB Additions -->
            <xsl:variable name="aapbURLInSource"
                select="
                    $originalExif/rdf:Description/RIFF:Source
                    [contains(., '//americanarchive.org/catalog/')]
                    /concat('&#xA;American Archive catalog entry available at: ', .)"/>
            <xsl:variable name="aapbTranscriptURLInComment"
                select="
                    $originalExif/rdf:Description/RIFF:Comment
                    [starts-with(., 'https://s3.amazonaws.com/americanarchive.org/transcripts/')]
                    /concat('&#xA;Automated transcript available from ', .)"/>

            <RIFF:Comment>
                <xsl:if test="contains($exifComment, 'Date is approximate.')
                    and 
                    not(
                    contains(
                    $parsedDAVIDTitle/parsedElements/DAVIDTitleDate, 'u')
                    )">
                    <xsl:variable name="dateNotApproximateMessage" select="
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
                <xsl:value-of select="$exifComment"/>
                <xsl:value-of
                    select="
                        $cavafyURLComment
                        [not(
                        contains(
                        $exifComment, 'For additional details see https://cavafy.')
                        )]"/>

                <xsl:value-of
                    select="
                        $approximateDateComment
                        [not(
                        contains(
                        $exifComment, 'Date is approximate')
                        )]"/>
                <xsl:value-of
                    select="
                        $aapbURLInSource
                        [not(
                        contains(
                        $exifComment, 'American Archive catalog entry available at: ')
                        )]"/>
                <xsl:value-of
                    select="
                        $aapbTranscriptURLInComment
                        [not(
                        contains(
                        $exifComment, 'Automated transcript available from')
                        )]"
                />
            </RIFF:Comment>
        </xsl:variable>
        
        <!--                Originator field; not to be trusted much in DAVID-->
        <xsl:variable name="RIFF:Originator">
            <RIFF:Originator>
                <xsl:value-of select="$RIFF:Technician"/>
                <xsl:text>&#013;</xsl:text>
            </RIFF:Originator>
        </xsl:variable>

        <!--  Originator reference field; 
            not to be trusted much in DAVID,
        as it often gets wiped out-->
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
                        $originalExif/rdf:Description
                        /XMP-plus:ImageSupplierImageID
                        /fn:normalize-space(.)"/>
                <xsl:with-param name="field2"
                    select="
                        $originalExif/rdf:Description
                        /XMP-WNYCSchema:ImageCMS
                        /fn:normalize-space(.)"/>
                <xsl:with-param name="field3"
                    select="
                        $cavafyEntry/pb:pbcoreDescriptionDocument
                        /pb:pbcoreAnnotation
                        [@annotationType = 'CMS Image']"/>
                <xsl:with-param name="defaultValue" select="$defaultCMSImageID"/>
                <xsl:with-param name="fieldName" select="'CMSImageID'"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="aapbTranscriptURL">
            <xsl:value-of
                select="
                    $originalExif/rdf:Description
                    /RIFF:Comment
                    [starts-with(
                    ., 'https://s3.amazonaws.com/americanarchive.org/transcripts/'
                    )]"
            />
        </xsl:variable>
        <xsl:variable name="aapbTranscriptFromCommentField">
            <xsl:apply-templates
                select="
                    $originalExif/rdf:Description
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
                    $originalExif/rdf:Description
                    /XMP-dc:Coverage"
            />
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
                        /System:FileSize, ' GB')">
                    <xsl:value-of
                        select="
                            xs:decimal(
                            substring-before(
                            $originalExif/rdf:Description
                            /System:FileSize, ' GB'
                            ))
                            * 1000"
                    />
                </xsl:when>
                <xsl:when
                    test="
                        contains($originalExif/rdf:Description/System:FileSize, ' MB')">
                    <xsl:value-of
                        select="
                            xs:decimal(
                            substring-before(
                            $originalExif/rdf:Description
                            /System:FileSize, ' MB'))"
                    />
                </xsl:when>
                <xsl:when
                    test="
                        contains($originalExif/rdf:Description
                        /System:FileSize, ' KB')">
                    <xsl:value-of
                        select="
                            xs:decimal(
                            substring-before(
                            $originalExif/rdf:Description
                            /System:FileSize, ' KB'))
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
         bitDepth (approx) = filesize(bits) / (duration (s) x sampleRate x numChannels)-->

        <xsl:variable name="DAVIDFileSizeBits"
            select="xs:integer($dbxData/ENTRIES/ENTRY/FILESIZE * 8)"/>
        <xsl:variable name="DAVIDFileSizeMB"
            select="xs:integer($dbxData/ENTRIES/ENTRY/FILESIZE div 1000000)"/>
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
                <xsl:copy select="$originalExif/rdf:Description/@rdf:about"/>
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

                <xsl:copy-of select="$originalExif/rdf:Description/ExifTool:ExifToolVersion"/>

                <System:FileName>
                    <xsl:choose>
                        <xsl:when
                            test="contains($originalExif/rdf:Description/File:FileType, 'ASSET')">
                            <xsl:value-of
                                select="
                                    concat(
                                    $originalExif/rdf:Description/System:FileName,
                                    '.00.',
                                    $originalExif/rdf:Description/File:FileType)"
                            />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$originalExif/rdf:Description/System:FileName"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </System:FileName>

                <xsl:copy-of select="$originalExif/rdf:Description/System:Directory"/>

                <System:FileSize>
                    <xsl:choose>
                        <!-- Checking for files dangerously close to 4 gigs in size -->
                        <xsl:when
                            test="
                                upper-case($originalExif/rdf:Description/File:FileType) eq 'WAV'
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
                                        'File', $originalExif/rdf:Description/System:FileName,
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
                                                $originalExif/rdf:Description/System:FileName
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
                        <xsl:with-param name="field1"
                            select="$originalExif/rdf:Description/System:FileModifyDate"/>
                        <xsl:with-param name="field2"
                            select="$DAVIDFileModifyDateTime[. ne ' -5:00'][. ne ' -4:00']"/>
                        <xsl:with-param name="fieldName" select="'FileModifyDate'"/>
                    </xsl:call-template>
                </System:FileModifyDate>
                <xsl:copy-of select="$originalExif/rdf:Description/System:FileAccessDate"/>
                <System:FileCreateDate>
                    <xsl:call-template name="checkConflicts">
                        <xsl:with-param name="field1"
                            select="$originalExif/rdf:Description/System:FileCreateDate"/>
                        <xsl:with-param name="field2"
                            select="$DAVIDFileCreateDateTime[. ne ' -5:00'][. ne ' -4:00']"/>
                        <xsl:with-param name="fieldName" select="'FileCreateDate'"/>
                    </xsl:call-template>
                </System:FileCreateDate>
                <xsl:copy-of select="$originalExif/rdf:Description/System:FilePermissions"/>

                <File:FileType>
                    <xsl:choose>
                        <!-- Reject RF64 files -->
                        <xsl:when
                            test="contains($originalExif/rdf:Description/File:FileType, 'RF64')">
                            <xsl:element name="error">
                                <xsl:attribute name="type" select="'unacceptable_file_type'"/>
                                <xsl:value-of
                                    select="
                                        'Unacceptable file type: ',
                                        $originalExif/rdf:Description/File:FileType"
                                />
                            </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$originalExif/rdf:Description/File:FileType"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </File:FileType>
                <xsl:copy-of select="$originalExif/rdf:Description/File:FileTypeExtension"/>



                <xsl:copy-of select="File:FileTypeExtension"/>
                <xsl:copy-of select="File:MIMEType"/>
                <RIFF:Description>
                    <xsl:value-of select="$parsedDAVIDTitle/parsedElements/DAVIDTitle"/>
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
                <xsl:copy-of select="$RIFF:Technician"/>
                <xsl:copy-of select="$originalExif/rdf:Description/RIFF:DateTimeOriginal[. != '']"/>
                <xsl:copy-of select="$originalExif/rdf:Description/RIFF:TimeReference[. != '']"/>
                <xsl:copy-of select="$originalExif/rdf:Description/RIFF:BWFVersion[. != '']"/>
                <xsl:copy-of select="$originalExif/rdf:Description/RIFF:BWF_UMID[. != '']"/>
                <xsl:copy-of select="$RIFF:CodingHistory"/>
                <xsl:if test="not(contains($originalExif/rdf:Description/File:FileType, 'ASSET'))">
                    <RIFF:Encoding>
                        <xsl:apply-templates select="." mode="checkConflicts">
                            <xsl:with-param name="field1"
                                select="$originalExif/rdf:Description/RIFF:Encoding"/>
                            <xsl:with-param name="field2" select="$DAVIDEncoding"/>
                            <xsl:with-param name="fieldName" select="'Encoding'"/>
                        </xsl:apply-templates>
                    </RIFF:Encoding>
                    <RIFF:NumChannels>
                        <xsl:apply-templates select="." mode="checkConflicts">
                            <xsl:with-param name="field1"
                                select="$originalExif/rdf:Description/RIFF:NumChannels"/>
                            <xsl:with-param name="field2" select="$DAVIDNumChannels"/>
                            <xsl:with-param name="fieldName" select="'NumChannels'"/>
                        </xsl:apply-templates>
                    </RIFF:NumChannels>
                    <RIFF:SampleRate>
                        <xsl:apply-templates select="." mode="checkConflicts">
                            <xsl:with-param name="field1"
                                select="$originalExif/rdf:Description/RIFF:SampleRate"/>
                            <xsl:with-param name="field2" select="$dbxData/ENTRIES/ENTRY/SAMPLERATE"/>
                            <xsl:with-param name="fieldName" select="'SampleRate'"/>
                        </xsl:apply-templates>
                    </RIFF:SampleRate>
                    <RIFF:AvgBytesPerSec>
                        <xsl:call-template name="checkConflicts">
                            <xsl:with-param name="field1"
                                select="$originalExif/rdf:Description/RIFF:AvgBytesPerSec"/>
                            <xsl:with-param name="field2" select="$DAVIDDataRate"/>
                            <xsl:with-param name="fieldName" select="'AvgBytesPerSec'"/>
                        </xsl:call-template>
                    </RIFF:AvgBytesPerSec>
                    <xsl:variable name="bitsPerSample">
                        <xsl:apply-templates select="." mode="checkConflicts">
                            <xsl:with-param name="field1"
                                select="$originalExif/rdf:Description/RIFF:BitsPerSample"/>
                            <xsl:with-param name="field2" select="$DAVIDBitDepth"/>                            
                            <xsl:with-param name="fieldName" select="'BitsPerSample'"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <RIFF:BitsPerSample>
                        <xsl:value-of select="$bitsPerSample"/>
                    </RIFF:BitsPerSample>
                </xsl:if>
                <xsl:copy-of select="$originalExif/rdf:Description/RIFF:CuePoints"/>
                <xsl:copy-of select="$originalExif/rdf:Description/XML:*"/>
                <xsl:copy-of select="$originalExif/rdf:Description/XMP-x:*"/>
                <XMP-dc:Subject>
                    <xsl:choose>
                        <xsl:when
                            test="
                                not(
                                contains($generation, 'segment')
                                )">
                            <xsl:copy-of select="$assetKeywordsRDFBag"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="$segmentKeywordsRDFBag"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </XMP-dc:Subject>

                <xsl:copy-of select="XMP-dc:Format"/>

                <xsl:copy-of select="$originalExif/rdf:Description/XMP-xmp:*"/>
                <xsl:copy-of
                    select="$originalExif/rdf:Description/XMP-xmpDM:*[contains(name(), 'Tracks')]"/>
                <xsl:element name="XMP-xmpDM:Artist">
                    <xsl:copy-of select="$contributorsAsXMP"/>
                </xsl:element>
                <xsl:if
                    test="
                        $transcript ne '' and
                        not(contains($generation, 'segment'))">
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
            when an AAPB URL is in the RIFF:Source field-->
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
            when an AAPB URL is in the RIFF:Comment field-->
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
    <xsl:template
        match="rdf:RDF[starts-with(rdf:Description/RIFF:Comment, 'https://s3.amazonaws.com/americanarchive.org/transcripts/')]">
        <xsl:apply-templates
            select="rdf:Description/RIFF:Comment[starts-with(., 'https://s3.amazonaws.com/americanarchive.org/transcripts/')]"
        />
    </xsl:template>

    <xsl:template name="getCMSData" match="rdf:Description" mode="getCMSData">
        <xsl:param name="dbxURI" select="concat(substring-before(@rdf:about, '.'), '.DBX')"/>
        <xsl:param name="dbxData" select="doc($dbxURI)"/>
        <xsl:param name="motive" select="$dbxData/ENTRIES/ENTRY/MOTIVE"/>
        <!--        <xsl:message select="*[local-name() = 'EntriesEntryMotive']"/>-->
        <xsl:apply-templates
            select="
                $dbxData/ENTRIES/ENTRY/MOTIVE
                [. != 'news_latest_newscast']
                [not(starts-with(., 'archive_import'))]"
        />
    </xsl:template>

    <xsl:template name="DAVIDdbx"
        match="
            rdf:Description
            [contains(System:Directory, 'wnycdavidmedia')]"
        mode="DAVIDdbx">
        <!-- Obtain DAVID fields -->
        <xsl:param name="wavURI"
            select="translate(concat(System:Directory, '/', System:FileName), '\', '/')"/>
        <xsl:message select="'Find DBX file for', $wavURI"/>
        <xsl:variable name="dbxURI" select="replace($wavURI, '.WAV', '.DBX')"/>
        <xsl:variable name="dbxData">
            <xsl:copy-of select="document(concat('file:///', $dbxURI))"/>
        </xsl:variable>
        <xsl:message select="'DBX Data: ', $dbxData"/>
        <dbxData>
            <xsl:copy-of select="$dbxData[//SOFTDELETED eq '0']"/>
        </dbxData>
    </xsl:template>

    <!--    <xsl:template name="jsonTranscripts"
        match="rdf:Description/RIFF:Comment[starts-with(., 'https://s3.amazonaws.com/americanarchive.org/transcripts/')]"
        >
        <xsl:param name="url" select="."/>
        <transcript>
            <xsl:call-template name="json">
                <xsl:with-param name="url" select="$url"/>
            </xsl:call-template>
        </transcript>
    </xsl:template>-->

    <!--   <xsl:template name="json">
        <xsl:param name="url"/>
        <xsl:param name="jsonData">
            <xsl:element name="File">
                <xsl:value-of select="unparsed-text($url, 'UTF-8')"/>
            </xsl:element>
        </xsl:param>
        <xsl:apply-templates select="json-to-xml($jsonData)/*"/>
    </xsl:template>

    <xsl:template match="*[@key]" xpath-default-namespace="">
        <xsl:variable name="jsonAsXml">
            <xsl:element name="{@key}">
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:variable>
        <xsl:apply-templates select="$jsonAsXml/*"/>
    </xsl:template>

    <xsl:template match="*">
        <xsl:value-of
            select="/*[local-name() = 'map']/*[local-name() = 'array']/*[local-name() = 'map']/*[local-name() = 'string'][@key = 'text']"
        />
    </xsl:template>-->



</xsl:stylesheet>
