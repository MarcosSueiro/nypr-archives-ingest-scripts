<?xml version="1.0" encoding="UTF-8"?>
<!--      Route an input xml for processing.
        Identify the type of xml, 
        and create separate documents.-->

<!-- Make sure you are logged into 
    cavafy.wnyc.org -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:XMP="http://ns.exiftool.ca/XMP/XMP/1.0/"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:WNYC="http://www.wnyc.org" xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    default-collation="http://www.w3.org/2013/collation/UCA?ignore-symbols=yes;strength=primary"
    version="3.0" exclude-result-prefixes="#all">

    <xsl:import href="exif2NewExif.xsl"/>
    <xsl:import href="Exif2html.xsl"/>
    <xsl:import href="BWF2Exif.xsl"/>
    <xsl:import href="Exif2Slack.xsl"/>
    <xsl:import href="errorLog.xsl"/>
    <xsl:import href="instantiationID2Exif.xsl"/>


    <xsl:output name="logXml" method="xml" version="1.0" indent="yes"/>
    <xsl:output name="Exif" encoding="UTF-8" method="xml" version="1.0" indent="yes"/>
    <xsl:output name="FADGI" encoding="US-ASCII" method="xml" version="1.0" indent="yes"/>
    <xsl:output name="cavafy" encoding="UTF-8" method="xml" version="1.0" indent="yes"/>
    <xsl:output name="DAVID" encoding="ISO-8859-1" method="xml" version="1.0" indent="yes"/>
    <xsl:output name="email" encoding="UTF-8" method="xml" version="1.0" indent="yes"/>

    <xsl:param name="outputFADGI" select="true()"/>
    <xsl:param name="outputCavafy" select="true()"/>
    <xsl:param name="outputDAVID" select="true()"/>
    <xsl:param name="outputEmail" select="true()"/>
    <xsl:param name="outputSlack" select="true()"/>

    <xsl:variable name="baseURI" select="
            base-uri()"/>
    <xsl:variable name="parsedBaseURI" select="
            analyze-string($baseURI, '/')"/>
    <xsl:variable name="masterDocFilename">
        <xsl:value-of select="
                $parsedBaseURI/
                fn:non-match[last()]"
        />
    </xsl:variable>
    <xsl:variable name="masterDocFilenameNoExtension">
        <xsl:value-of
            select="
                WNYC:substring-before-last(
                $masterDocFilename, '.'
                )"
        />
    </xsl:variable>
    <xsl:variable name="baseFolder"
        select="
            substring-before(
            $baseURI,
            $masterDocFilename
            )"/>
    <xsl:variable name="logFolder"
        select="
            concat(
            $baseFolder,
            'instantiationUploadLOGS/'
            )"/>
    <xsl:variable name="currentDate"
        select="
            format-date(current-date(),
            '[Y0001][M01][D01]')"/>
    <xsl:variable name="currentTime"
        select="
            substring(
            translate(
            string(
            current-time()),
            ':', ''), 1, 4)
            "/>
    <xsl:variable name="pbcorePhysicalInstantiations"
        select="
            doc(
            'pbcore_instantiationphysicalaudio_vocabulary.xml'
            )"/>
    <xsl:variable name="archivesAuthors"
        select="
            doc(
            'archivesAuthors.xml'
            )"/>

    <xsl:template match="/">
        <xsl:message
            select="
                'Now processing file ', base-uri(),
                ' on this fine day of ', current-dateTime()"/>
        <xsl:message>
            <xsl:value-of select="
                    'This', local-name(*), 'document contains'"/>
            <xsl:for-each-group select="*/*" group-by="local-name()">
                <xsl:value-of
                    select="
                        '&#10;', count(current-group()),
                        current-grouping-key(), 'elements.'"
                />
            </xsl:for-each-group>
            <xsl:for-each-group select="*"
                group-by="
                    rdf:Description/File:FileType">
                <xsl:value-of
                    select="
                        '&#10;', count(*),
                        current-grouping-key(), 'files.'"
                />
            </xsl:for-each-group>
        </xsl:message>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template name="BWFMetaEdit" match="conformance_point_document">
        <!-- Accept a BWF MetaEdit xml document 
            and convert to an exiftool kind of rdf document -->
        <xsl:message>
            <xsl:value-of select="'This appears to be a BWF MetaEdit kind of document.'"/>
        </xsl:message>
        <xsl:variable name="exifFromFADGI">
            <rdf:RDF>
                <xsl:apply-templates select="File" mode="BWFMetaEdit"/>
            </rdf:RDF>
        </xsl:variable>
        <xsl:copy-of select="$exifFromFADGI"/>
        <xsl:message select="'Exif from BWF MetaEdit', $exifFromFADGI"/>
        <xsl:apply-templates select="$exifFromFADGI/rdf:RDF[rdf:Description]"/>
    </xsl:template>

    <xsl:template name="DAVIDdbx" match="ENTRIES">
        <!-- Accept an xml document (with extension '.DBX')
        as output from D.A.V.I.D.-->
        <xsl:message>
            <xsl:value-of select="'This appears to be a DAVID DBX kind of document.'"/>
        </xsl:message>
        <xsl:apply-templates select="ENTRY"/>
    </xsl:template>

    <xsl:template name="exiftool" match="rdf:RDF[rdf:Description]">
        <!-- Accept an exiftool kind of xml document
        as output from the command 
        
        exiftool -X -a -ext wav -struct -charset riff=utf8 "fileDirectory" > "output.xml"
        
        or something similar to this -->

        <!-- Basic info: type of document, number of instantiations -->
        <xsl:param name="input" select="."/>
        
        <xsl:param name="outputFADGI" select="$outputFADGI"/>
        <xsl:param name="outputCavafy" select="$outputCavafy"/>
        <xsl:param name="outputDAVID" select="$outputDAVID"/>
        <xsl:param name="outputEmail" select="$outputEmail"/>
        <xsl:param name="outputSlack" select="$outputSlack"/>
        
        <xsl:param name="stopIfErrors" select="true()" tunnel="true"/>
        <xsl:param name="filenameAddendum" tunnel="yes"/>
        <xsl:message
            select="
                'Process ', $masterDocFilenameNoExtension, ', a ', local-name(), ' document, ',
                'with', count(*), 'elements.'"/>

        <!-- Sort according to what type of instantiation 
            (at the rdf:Description/File:FileType level)
        
        1. New assets (from a spreadsheet)
        2. Wav files 
            2.1. Wav files from Archives INGEST folder
            (these should have parseable file names)
            2.2. Wav files in DAVID
            (these will have associated .DBX files with metadata)
                2.2.1. DAVID Wav files with no 'theme' (MOTIVE)
                2.2.2. DAVID Wav files with 'archiveImport' 'theme' (MOTIVE)
                (these should have paresable BWF Descriptions)
                2.2.3. DAVID Wav files with 'cms' type of 'theme' (MOTIVE)
                (these should have CMS metadata)
                2.2.4. DAVID Wav files with 'news_latest_newscast' 'theme' (MOTIVE)
                (these should have NewsBoss metadata)-->

        <!-- Message with format count -->
        <xsl:for-each-group
            select="
                $input/rdf:Description
                [upper-case(RIFF:Source) = 'NEW']"
            group-by="File:FileType">
            <xsl:message
                select="
                    count(current-group()),
                    current-grouping-key(),
                    'with no existing asset.'"
            />
        </xsl:for-each-group>

        <xsl:for-each-group
            select="
                $input/rdf:Description
                [not(upper-case(RIFF:Source) = 'NEW')]"
            group-by="File:FileType">
            <xsl:message
                select="
                    count(current-group()),
                    current-grouping-key(),
                    'instantiations',
                    'with a presumed existing cavafy asset.'"
            />
        </xsl:for-each-group>


        <!--Normally coming from a spreadsheet -->
        <xsl:variable name="newAssets">
            <newAssets>
                <xsl:copy-of
                    select="
                        $input/rdf:Description
                        [File:FileType = 'asset'][upper-case(RIFF:Source) = 'NEW']"
                />
            </newAssets>
        </xsl:variable>
        <xsl:variable name="updateAssets">
            <updateAssets>
                <xsl:copy-of
                    select="
                        $input/rdf:Description
                        [File:FileType = 'asset']
                        [not(upper-case(RIFF:Source) = 'NEW')]"
                />
            </updateAssets>
        </xsl:variable>
        <xsl:variable name="physicalInstantiations">
            <physicalInstantiations>
                <xsl:copy-of
                    select="
                        $input/rdf:Description
                        [File:FileType =
                        'DAT']"
                />
            </physicalInstantiations>
        </xsl:variable>
        <xsl:variable name="wavInstantiations">
            <wavInstantiations>
                <xsl:copy-of
                    select="
                        $input/rdf:Description
                        [upper-case(File:FileType) = 'WAV']"
                />
            </wavInstantiations>
        </xsl:variable>
        <xsl:variable name="unacceptableFiles">
            <unacceptableFiles>
                <xsl:for-each
                    select="
                        $input/rdf:Description
                        [contains(upper-case(File:FileType), 'RF64')]">
                    <xsl:element name="error">
                        <xsl:attribute name="type" select="'unacceptable_files'"/>
                        <xsl:value-of
                            select="
                                'unacceptable RF64 files: ',
                                @rdf:about"
                        />
                    </xsl:element>
                </xsl:for-each>
            </unacceptableFiles>
        </xsl:variable>
        <xsl:variable name="archivesINGESTWavInstantiations">
            <archivesINGESTWavInstantiations>
                <xsl:copy-of
                    select="
                        $wavInstantiations/wavInstantiations/rdf:Description
                        [contains(@rdf:about, 'ARCHIVESNAS1/INGEST/')]"
                />
            </archivesINGESTWavInstantiations>
        </xsl:variable>

        <xsl:variable name="DAVIDWavInstantiations">
            <DAVIDWavInstantiations>
                <xsl:for-each
                    select="
                        $wavInstantiations/wavInstantiations/rdf:Description
                        [contains(@rdf:about, 'wnycdavidmedia')]">
                    <xsl:variable name="dbxData">
                        <xsl:apply-templates
                            select=".[contains(System:Directory, 'wnycdavidmedia')]" mode="DAVIDdbx"
                        />
                    </xsl:variable>
                    <xsl:variable name="dbxURL"
                        select="$dbxData/ENTRIES/ENTRY/MEDIUM/FILE/FILEREF[ends-with(., '.DBX')][1]"/>
                    <xsl:variable name="dbxTheme" select="$dbxData/ENTRIES/ENTRY/MOTIVE"/>
                    <xsl:variable name="dbxAuthor" select="$dbxData/ENTRIES/ENTRY/AUTHOR"/>
                    <xsl:variable name="dbxCreator" select="$dbxData/ENTRIES/ENTRY/CREATOR"/>
                    <xsl:variable name="dbxDeleted" select="$dbxData/ENTRIES/ENTRY/SOFTDELETED"/>
                    <DAVIDWavInstantiation>
                        <xsl:copy-of select="."/>
                        <xsl:copy-of select="$dbxURL"/>
                        <xsl:copy-of select="$dbxTheme"/>
                        <xsl:copy-of select="$dbxAuthor"/>
                        <xsl:copy-of select="$dbxCreator"/>
                        <xsl:copy-of select="$dbxDeleted"/>
                        <xsl:copy-of select="$dbxData"/>
                    </DAVIDWavInstantiation>
                </xsl:for-each>
            </DAVIDWavInstantiations>
        </xsl:variable>
        <xsl:variable name="DAVIDWavInstantiationsFromArchives">
            <DAVIDWavInstantiationsFromArchives>
                <xsl:copy-of
                    select="
                        $DAVIDWavInstantiations
                        /DAVIDWavInstantiations
                        /DAVIDWavInstantiation
                        [AUTHOR = $archivesAuthors/ARCHIVEAUTHORS/AUTHOR
                        or
                        CREATOR = $archivesAuthors/ARCHIVEAUTHORS/AUTHOR]"
                />
            </DAVIDWavInstantiationsFromArchives>
        </xsl:variable>
        <xsl:variable name="DAVIDWavInstantiationsWCMSTheme">
            <DAVIDWavInstantiationsWCMSTheme>
                <xsl:copy-of
                    select="
                        $DAVIDWavInstantiations
                        /DAVIDWavInstantiations/DAVIDWavInstantiation
                        [MOTIVE != '']
                        [MOTIVE != 'news_latest_newscast']
                        [not(starts-with(MOTIVE, 'archive_import'))]"
                />
            </DAVIDWavInstantiationsWCMSTheme>
        </xsl:variable>
        <xsl:variable name="DAVIDWavInstantiationsLatestNewscast">
            <DAVIDWavInstantiationsLatestNewscast>
                <xsl:copy-of
                    select="
                        $DAVIDWavInstantiations
                        /DAVIDWavInstantiations/DAVIDWavInstantiation
                        [MOTIVE = 'news_latest_newscast']"
                />
            </DAVIDWavInstantiationsLatestNewscast>
        </xsl:variable>
        <xsl:variable name="DAVIDWavInstantiationsWNoThemeNotFromArchives">
            <DAVIDWavInstantiationsWNoThemeNotFromArchives>
                <xsl:copy-of
                    select="
                        $DAVIDWavInstantiations
                        /DAVIDWavInstantiations
                        /DAVIDWavInstantiation
                        [not(MOTIVE)]
                        [not(AUTHOR = $archivesAuthors/ARCHIVEAUTHORS/AUTHOR
                        or
                        CREATOR = $archivesAuthors/ARCHIVEAUTHORS/AUTHOR)]"
                />
            </DAVIDWavInstantiationsWNoThemeNotFromArchives>
        </xsl:variable>


        <!--        Check for errors in templates -->
        <xsl:variable name="newAssetResults">
            <newAssetResults>
                <xsl:apply-templates
                    select="
                        $newAssets
                        /newAssets
                        /rdf:Description"
                />
            </newAssetResults>
        </xsl:variable>
        <xsl:variable name="updateAssetResults">
            <updateAssetResults>
                <xsl:apply-templates
                    select="
                        $updateAssets
                        /updateAssets
                        /rdf:Description"
                />
            </updateAssetResults>
        </xsl:variable>
        <xsl:variable name="physicalInstantiationResults">
            <physicalInstantiationResults>
                <xsl:apply-templates
                    select="
                    $physicalInstantiations/physicalInstantiations/rdf:Description"
                />
            </physicalInstantiationResults>
        </xsl:variable>
        <xsl:variable name="archivesINGESTWavResults">
            <archivesINGESTWavResults>
                <xsl:apply-templates
                    select="
                        $archivesINGESTWavInstantiations
                        /archivesINGESTWavInstantiations
                        /rdf:Description[System:FileName]"
                />
            </archivesINGESTWavResults>
        </xsl:variable>

        <xsl:variable name="DAVIDWavInstantiationsFromArchivesResults">
            <DAVIDWavInstantiationsFromArchivesResults>
                <xsl:apply-templates
                    select="
                        $DAVIDWavInstantiationsFromArchives
                        /DAVIDWavInstantiationsFromArchives
                        /DAVIDWavInstantiation
                        /rdf:Description[System:FileName]"
                />
            </DAVIDWavInstantiationsFromArchivesResults>
        </xsl:variable>
        <xsl:variable name="DAVIDWavInstantiationsWCMSThemeResults">
            <DAVIDWavInstantiationsWCMSThemeResults>
                <xsl:apply-templates
                    select="
                        $DAVIDWavInstantiationsWCMSTheme
                        /DAVIDWavInstantiationsWCMSTheme
                        /DAVIDWavInstantiation
                        /rdf:Description[System:FileName]"
                />
            </DAVIDWavInstantiationsWCMSThemeResults>
        </xsl:variable>
        <xsl:variable name="DAVIDWavInstantiationsLatestNewscastResults">
            <DAVIDWavInstantiationsLatestNewscast>
                <xsl:apply-templates
                    select="
                        $DAVIDWavInstantiationsLatestNewscast
                        /DAVIDWavInstantiationsLatestNewscast
                        /DAVIDWavInstantiation
                        /rdf:Description[System:FileName]"
                />
            </DAVIDWavInstantiationsLatestNewscast>
        </xsl:variable>
        <xsl:variable name="DAVIDWavInstantiationsWNoThemeNotFromArchivesResults">
            <xsl:apply-templates
                select="
                    $DAVIDWavInstantiationsWNoThemeNotFromArchives
                    /DAVIDWavInstantiationsWNoThemeNotFromArchives
                    /DAVIDWavInstantiation
                    /rdf:Description[System:FileName]"
            />
        </xsl:variable>

        <!--        Check for duplicate instantiations -->
        <xsl:variable name="allParsedElements">
            <allParsedElements>
                <xsl:copy-of
                    select="
                        (
                        ($newAssetResults/newAssetResults) |
                        ($physicalInstantiationResults/physicalInstantiationResults) |
                        ($DAVIDWavInstantiationsFromArchivesResults/DAVIDWavInstantiationsFromArchivesResults) |
                        ($archivesINGESTWavResults/archivesINGESTWavResults)
                        )
                        /result
                        /inputs
                        /parsedDAVIDTitle
                        /parsedElements"
                />
            </allParsedElements>
        </xsl:variable>

        <xsl:variable name="duplicateInstantiations">
            <xsl:apply-templates
                select="
                    $allParsedElements
                    /allParsedElements"
                mode="duplicateInstantiations"/>
        </xsl:variable>

        <!--        All errors -->
        <xsl:variable name="ERRORS">
            <xsl:copy-of select="
                    $duplicateInstantiations"/>
            <xsl:copy-of
                select="
                    $unacceptableFiles
                    //*[local-name() = 'error']/.."/>
            <xsl:copy-of
                select="
                    $newAssetResults
                    /newAssetResults
                    /result
                    //*[local-name() = 'error']/.."/>
            <xsl:copy-of
                select="
                    $physicalInstantiationResults
                    /physicalInstantiationResults
                    /result
                    //*[local-name() = 'error']/.."/>
            <xsl:copy-of
                select="
                    $DAVIDWavInstantiationsFromArchivesResults
                    /DAVIDWavInstantiationsFromArchivesResults
                    /result
                    //*[local-name() = 'error']/.."/>
            <xsl:copy-of
                select="
                    $archivesINGESTWavResults
                    /archivesINGESTWavResults
                    /result
                    //*[local-name() = 'error']/.."/>
            <xsl:for-each
                select="
                    $newAssetResults
                    /newAssetResults
                    /result
                    /newExif
                    /rdf:Description
                    /RIFF:*
                    [normalize-space(.) eq '']">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="
                            'no_value'"/>
                    <xsl:value-of
                        select="
                            concat(
                            'empty value for ',
                            local-name(.),
                            ' in ', ../@rdf:about)"
                    />
                </xsl:element>
            </xsl:for-each>
            <xsl:for-each
                select="
                    $physicalInstantiationResults
                    /physicalInstantiationResults/result
                    /newExif
                    /rdf:Description
                    /RIFF:*[normalize-space(.) eq '']">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="
                            'no_value'"/>
                    <xsl:value-of
                        select="
                            concat(
                            'empty value for',
                            local-name(.),
                            ' in ', ../@rdf:about)"
                    />
                </xsl:element>
            </xsl:for-each>
            <xsl:for-each
                select="
                    $DAVIDWavInstantiationsFromArchivesResults
                    /DAVIDWavInstantiationsFromArchivesResults
                    /result
                    /newExif
                    /rdf:Description
                    /RIFF:*[normalize-space(.) eq '']">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="
                            'no_value'"/>
                    <xsl:value-of
                        select="
                            concat(
                            'empty value for ',
                            local-name(.),
                            ' in ', ../@rdf:about
                            )"
                    />
                </xsl:element>
            </xsl:for-each>
            <xsl:for-each
                select="
                    $archivesINGESTWavResults/result
                    /newExif
                    /rdf:Description
                    /RIFF:*[normalize-space(.) eq '']">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="
                            'no_value'"/>
                    <xsl:value-of
                        select="
                            concat(
                            'empty value for ',
                            local-name(.),
                            ' in ', ../@rdf:about)"
                    />
                </xsl:element>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="WARNINGS">
            <xsl:copy-of
                select="
                    $unacceptableFiles
                    //*[@warning]"/>
            <xsl:copy-of
                select="
                    $newAssetResults
                    /newAssetResults/result
                    //*[@warning]"/>
            <xsl:copy-of
                select="
                    $physicalInstantiationResults
                    /physicalInstantiationResults/result
                    //*[@warning]"/>
            <xsl:copy-of
                select="
                    $DAVIDWavInstantiationsFromArchivesResults
                    /DAVIDWavInstantiationsFromArchivesResults/result
                    //*[@warning]"/>
            <xsl:copy-of
                select="
                    $archivesINGESTWavResults
                    /archivesINGESTWavResults/result
                    //*[@warning]"
            />
        </xsl:variable>


        <!--  ALL OUTPUTS -->
        
        <!-- NEW EXIF -->
        <xsl:variable name="newExifOutput">
            <xsl:element name="rdf:RDF">
                <xsl:namespace name="rdf"
                    select="
                        'http://www.w3.org/1999/02/22-rdf-syntax-ns#'"/>
                <xsl:copy-of
                    select="
                        $newAssetResults
                        /result
                        /newExif
                        /rdf:Description"/>
                <xsl:copy-of
                    select="
                        $updateAssetResults
                        /result
                        /newExif
                        /rdf:Description"/>
                <xsl:copy-of
                    select="
                        $physicalInstantiationResults"/>
                <xsl:copy-of
                    select="
                        $archivesINGESTWavResults
                        /archivesINGESTWavResults
                        /result
                        /newExif
                        /rdf:Description"/>
                <xsl:copy-of
                    select="
                        $DAVIDWavInstantiationsFromArchivesResults
                        /DAVIDWavInstantiationsFromArchivesResults
                        /result/newExif/rdf:Description"/>
                <xsl:copy-of
                    select="
                        $DAVIDWavInstantiationsWCMSThemeResults
                        /result/newExif/rdf:Description"/>
                <xsl:copy-of
                    select="
                        $DAVIDWavInstantiationsLatestNewscast
                        /result/newExif/rdf:Description"/>
                <xsl:copy-of
                    select="
                        $DAVIDWavInstantiationsWNoThemeNotFromArchivesResults
                        /result/newExif/rdf:Description"
                />
            </xsl:element>
        </xsl:variable>

        <!--        Output 0.1: Complete Result Log -->
        <xsl:variable name="filenameLog"
            select="
                concat(
                $logFolder,
                $masterDocFilenameNoExtension,                
                '_LOG', format-date(current-date(),
                '[Y0001][M01][D01]'), '_T',
                $currentTime,
                $filenameAddendum,
                '.xml'
                )"/>
        <xsl:variable name="completeLog">
            <completeLog>
                <xsl:copy-of select="$duplicateInstantiations"/>
                <xsl:copy-of select="$unacceptableFiles"/>
                <xsl:copy-of select="$newAssetResults"/>
                <xsl:copy-of select="$updateAssetResults"/>
                <xsl:copy-of select="$physicalInstantiationResults"/>
                <xsl:copy-of select="$archivesINGESTWavResults"/>
                <xsl:copy-of select="$DAVIDWavInstantiationsFromArchivesResults"/>
                <xsl:copy-of select="$DAVIDWavInstantiationsWCMSThemeResults"/>
                <xsl:copy-of select="$DAVIDWavInstantiationsLatestNewscast"/>
                <xsl:copy-of
                    select="
                        $DAVIDWavInstantiationsWNoThemeNotFromArchivesResults"
                />
            </completeLog>
        </xsl:variable>

        <xsl:result-document format="
            logXml" href="
            {$filenameLog}">
            <xsl:copy-of select="$completeLog"/>
        </xsl:result-document>

        <!-- Output 0.2: html for email and checking -->

        <xsl:variable name="filenameHtml"
            select="
                concat($baseFolder,
                $masterDocFilenameNoExtension,
                format-date(current-date(),
                '[Y0001][M01][D01]'),
                $filenameAddendum,
                '.html'
                )"></xsl:variable>
        <xsl:result-document format="email" href="
            {$filenameHtml}">
            <xsl:apply-templates select="
                    $newExifOutput/rdf:RDF[$outputEmail]"
                mode="html"/>
        </xsl:result-document>

        <!-- Output 0.3: Error log
       (stop if errors)-->

        <xsl:call-template name="generateErrorLog">
            <xsl:with-param name="completeLog" select="$completeLog"/>
            <xsl:with-param name="duplicateInstantiations" select="$duplicateInstantiations"/>
            <xsl:with-param name="WARNINGS" select="$WARNINGS"/>            
        </xsl:call-template>

        <!-- If errors, stop right here -->
        <xsl:if test="$stopIfErrors and 
                $completeLog//*[local-name() = 'error']
                ">
            <xsl:message terminate="yes">
                <xsl:value-of select="'Errors found.'"/>
                <xsl:copy-of select="$completeLog//
                    *[local-name() = 'error']"/>
            </xsl:message>
        </xsl:if>

        <!-- If no errors, all other outputs -->

        <!--        Output 1: New ExifTool -->
        <xsl:variable name="filenameExif"
            select="
                concat($baseFolder,
                $masterDocFilenameNoExtension,
                '_NewExif',
                $currentDate,
                $filenameAddendum,
                '.xml'
                )"/>
        <xsl:result-document format="Exif" href="{$filenameExif}">
            <xsl:copy-of select="$newExifOutput"/>
        </xsl:result-document>

        <!--        Output 2: FADGI -->
        <xsl:if test="$outputFADGI">
            <xsl:variable name="filenameFADGI"
                select="
                    concat($baseFolder,
                    $masterDocFilenameNoExtension,
                    '_ForFADGI',
                    $currentDate,
                    '.xml')"/>
            <xsl:result-document format="FADGI" href="{$filenameFADGI}">
                <xsl:apply-templates
                    select="
                        $newExifOutput/rdf:RDF[$outputFADGI]"
                    mode="BWFCoreFiller"/>
            </xsl:result-document>
        </xsl:if>

        <!--        Output 3: cavafy -->       
        <xsl:variable name="cavafyOutput">
            <xsl:apply-templates select="
                    $newExifOutput/rdf:RDF[$outputCavafy]"
                mode="cavafy"/>
        </xsl:variable>

        <!-- Needs to be split into bite-size chunks of about 40 assets -->
        <xsl:variable name="cavafyAssetsCount"
            select="
                count(
                $cavafyOutput/
                pb:pbcoreCollection/
                pb:pbcoreDescriptionDocument)"/>
        <xsl:variable name="maxCavafyAssets" select="200" as="xs:integer"/>
        <xsl:comment select="'total instances', count(*)"/>

        <xsl:apply-templates
            select="
                $cavafyOutput/
                pb:pbcoreCollection[$outputCavafy]"
            mode="
            breakItUp">
            <xsl:with-param name="filename"
                select="
                    concat($baseFolder,
                    $masterDocFilenameNoExtension)"/>
            <xsl:with-param name="maxOccurrences" select="
                    $maxCavafyAssets"/>
        </xsl:apply-templates>

        <!--        Output 4: DAVID -->
        <xsl:if test="$outputDAVID">
            <!-- Output 4.1: MUNI -->

            <xsl:if
                test="
                    $newExifOutput/rdf:RDF/
                    rdf:Description/
                    RIFF:Description
                    [starts-with(., 'MUNI-')]
                    ">
                <xsl:variable name="filenameDAVIDMuni"
                    select="
                        concat($baseFolder,
                        $masterDocFilenameNoExtension,
                        '-MUNI_',
                        $currentDate, '.DBX')"/>
                <xsl:result-document format="DAVID" href="{$filenameDAVIDMuni}">
                    <ENTRIES>
                        <xsl:apply-templates
                            select="
                                $newExifOutput/rdf:RDF/
                                rdf:Description
                                [starts-with(RIFF:Description, 'MUNI-')]"
                            mode="DAVID"/>
                    </ENTRIES>
                </xsl:result-document>
            </xsl:if>
            <!-- Output 4.2: WQXR -->
            <xsl:if
                test="
                    $newExifOutput/rdf:RDF/
                    rdf:Description/RIFF:Description
                    [starts-with(., 'WQXR-')]
                    ">
                <xsl:variable name="filenameDAVIDWQXR"
                    select="
                        concat(
                        $baseFolder,
                        $masterDocFilenameNoExtension,
                        '-WQXR_',
                        $currentDate,
                        '.DBX'
                        )"/>
                <xsl:result-document format="DAVID" href="
                    {$filenameDAVIDWQXR}">
                    <ENTRIES>
                        <xsl:apply-templates
                            select="
                                $newExifOutput/rdf:RDF/
                                rdf:Description
                                [starts-with(RIFF:Description, 'WQXR-')]
                                "
                            mode="DAVID"/>
                    </ENTRIES>
                </xsl:result-document>
            </xsl:if>
            <!-- Output 4.3: On the Media -->
            <xsl:if
                test="
                    $newExifOutput/rdf:RDF/
                    rdf:Description/
                    RIFF:Description
                    [contains(., '-OTM-')]
                    ">
                <xsl:variable name="filenameDAVIDOTM"
                    select="
                        concat(
                        $baseFolder,
                        $masterDocFilenameNoExtension,
                        '-OTM_',
                        $currentDate, '.DBX')"/>
                <xsl:result-document format="DAVID" href="{$filenameDAVIDOTM}">
                    <ENTRIES>
                        <xsl:apply-templates
                            select="
                                $newExifOutput/rdf:RDF/
                                rdf:Description
                                [contains(RIFF:Description, '-OTM-')]"
                            mode="DAVID"/>
                    </ENTRIES>
                </xsl:result-document>
            </xsl:if>
            <!-- Output 4.4: 96kHz / 24 bit files -->
            <xsl:if
                test="
                    $newExifOutput/rdf:RDF/rdf:Description
                    [RIFF:SampleRate = '96000']
                    [not(starts-with(RIFF:Description, 'MUNI-'))]
                    [not(starts-with(RIFF:Description, 'WQXR-'))]
                    [not(starts-with(RIFF:Description, 'WQXR-'))]
                    [not(contains(RIFF:Description, '-OTM-'))]
                    ">
                <xsl:variable name="filenameDAVID96k24"
                    select="
                        concat(
                        $baseFolder,
                        $masterDocFilenameNoExtension,
                        '-96k24_',
                        $currentDate,
                        '.DBX'
                        )"/>
                <xsl:result-document format="DAVID" href="{$filenameDAVID96k24}">
                    <ENTRIES>
                        <xsl:apply-templates
                            select="
                                $newExifOutput/rdf:RDF/rdf:Description
                                [RIFF:SampleRate = '96000']
                                [not(starts-with(RIFF:Description, 'MUNI-'))]
                                [not(starts-with(RIFF:Description, 'WQXR-'))]
                                [not(starts-with(RIFF:Description, 'WQXR-'))]
                                [not(contains(RIFF:Description, '-OTM-'))]"
                            mode="DAVID"/>
                    </ENTRIES>
                </xsl:result-document>
            </xsl:if>
            <!-- Output 4.5: 48kHz -->
            <xsl:if
                test="
                    $newExifOutput/rdf:RDF/rdf:Description
                    [RIFF:SampleRate = '48000']
                    [not(starts-with(RIFF:Description, 'MUNI-'))]
                    [not(starts-with(RIFF:Description, 'WQXR-'))]
                    [not(starts-with(RIFF:Description, 'WQXR-'))]
                    [not(contains(RIFF:Description, '-OTM-'))]
                    ">
                <xsl:variable name="filenameDAVID48k"
                    select="
                        concat(
                        $baseFolder,
                        $masterDocFilenameNoExtension,
                        '-48k_',
                        $currentDate,
                        '.DBX'
                        )"/>
                <xsl:result-document format="DAVID" href="{$filenameDAVID48k}">
                    <ENTRIES>
                        <xsl:apply-templates
                            select="
                                $newExifOutput/rdf:RDF/rdf:Description
                                [RIFF:SampleRate = '48000']
                                [not(starts-with(RIFF:Description, 'MUNI-'))]
                                [not(starts-with(RIFF:Description, 'WQXR-'))]
                                [not(contains(RIFF:Description, '-OTM-'))]"
                            mode="DAVID"/>
                    </ENTRIES>
                </xsl:result-document>
            </xsl:if>
            <!-- Output 4.6: 44.1kHz, 16 bit -->
            <xsl:if
                test="
                    $newExifOutput/rdf:RDF/
                    rdf:Description
                    [RIFF:SampleRate = '44100']
                    [RIFF:BitsPerSample = '16']
                    [not(starts-with(RIFF:Description, 'MUNI-'))]
                    [not(starts-with(RIFF:Description, 'WQXR-'))]
                    [not(contains(RIFF:Description, '-OTM-'))]">
                <xsl:variable name="filenameDAVID44k16"
                    select="
                        concat(
                        $baseFolder,
                        $masterDocFilenameNoExtension,
                        '-44k16_',
                        $currentDate,
                        '.DBX'
                        )"/>
                <xsl:result-document format="DAVID" href="{$filenameDAVID44k16}">
                    <ENTRIES>
                        <xsl:apply-templates
                            select="
                                $newExifOutput/rdf:RDF/rdf:Description
                                [RIFF:SampleRate = '44100']
                                [RIFF:BitsPerSample = '16']
                                [not(starts-with(RIFF:Description, 'MUNI-'))]
                                [not(starts-with(RIFF:Description, 'WQXR-'))]
                                [not(contains(RIFF:Description, '-OTM-'))]"
                            mode="DAVID"/>
                    </ENTRIES>
                </xsl:result-document>
            </xsl:if>
            <!-- Output 4.7: 44.1 kHz, 24 bit -->
            <xsl:if
                test="
                    $newExifOutput/rdf:RDF/rdf:Description
                    [RIFF:SampleRate = '44100']
                    [RIFF:BitsPerSample = '24']
                    [not(starts-with(RIFF:Description, 'MUNI-'))]
                    [not(starts-with(RIFF:Description, 'WQXR-'))]
                    [not(contains(RIFF:Description, '-OTM-'))]">
                <xsl:variable name="filenameDAVID44k24"
                    select="
                        concat(
                        $baseFolder,
                        $masterDocFilenameNoExtension,
                        '-44k24_',
                        $currentDate,
                        '.DBX'
                        )"/>
                <xsl:result-document format="DAVID" href="{$filenameDAVID44k24}">
                    <ENTRIES>
                        <xsl:apply-templates
                            select="
                                $newExifOutput/rdf:RDF/rdf:Description
                                [RIFF:SampleRate = '44100']
                                [RIFF:BitsPerSample = '24']
                                [not(starts-with(RIFF:Description, 'MUNI-'))]
                                [not(starts-with(RIFF:Description, 'WQXR-'))]
                                [not(contains(RIFF:Description, '-OTM-'))]"
                            mode="DAVID"/>
                    </ENTRIES>
                </xsl:result-document>
            </xsl:if>
            <!-- Output 4.8: To Web for Automatic Upload -->
            <xsl:if
                test="
                    $newExifOutput/rdf:RDF/rdf:Description/RIFF:Description
                    [contains(., 'WEB EDIT')]">
                <xsl:variable name="filenameDAVIDUploadToWeb"
                    select="
                        concat(
                        $baseFolder,
                        $masterDocFilenameNoExtension,
                        '-WebEdit_',
                        $currentDate,
                        '.DBX'
                        )"/>
                <xsl:result-document format="DAVID" href="{$filenameDAVIDUploadToWeb}">
                    <ENTRIES>
                        <xsl:apply-templates
                            select="
                                $newExifOutput/rdf:RDF/rdf:Description
                                [contains(RIFF:Description, 'WEB EDIT')]"
                            mode="DAVID"/>
                    </ENTRIES>
                </xsl:result-document>
            </xsl:if>

        </xsl:if>

        <!-- Output 5: Slack -->
        <xsl:apply-templates
            select="
                $newExifOutput
                /rdf:RDF
                [not(//error)]
                [$outputSlack]"
            mode="slack"/>

    </xsl:template>

    <xsl:template name="duplicateInstantiations" match="
            allParsedElements"
        mode="
        duplicateInstantiations">
        <!-- Check for duplicate instantiations 
            within the document -->
        <xsl:message>
            <xsl:value-of
                select="
                    'Check for duplicate instantiations ',
                    'in values '"/>
            <xsl:value-of
                select="
                    parsedElements
                    /instantiationID"
                separator=", "/>
        </xsl:message>
        <xsl:for-each
            select="
                parsedElements
                [./instantiationID[. != ''] =
                ./following-sibling::parsedElements
                /instantiationID]">
            <xsl:variable name="errorMessage">
                <xsl:value-of
                    select="
                        concat(
                        'ATTENTION!! ',
                        'duplicate instantiation: ',
                        ./instantiationID, ' within ',
                        DAVIDTitle
                        )"
                />
            </xsl:variable>

            <xsl:message select="$errorMessage"/>
            <xsl:element name="error">
                <xsl:attribute name="type"
                    select="
                        'duplicate_instantiation'"/>
                <xsl:attribute name="instantiationID" select="instantiationID"/>
                <xsl:attribute name="DAVIDTitle" select="DAVIDTitle"/>
                <xsl:copy-of select="$errorMessage"/>
            </xsl:element>
        </xsl:for-each>
        <xsl:for-each
            select="
                parsedElements
                [./instantiationID[. != ''] =
                ./preceding-sibling::parsedElements
                /instantiationID]">
            <xsl:variable name="errorMessage">
                <xsl:value-of
                    select="
                        concat(
                        'ATTENTION!! ',
                        'duplicate instantiation: ',
                        ./instantiationID, ' within ',
                        DAVIDTitle
                        )"
                />
            </xsl:variable>
            <xsl:message select="$errorMessage"/>
            <xsl:element name="error">
                <xsl:attribute name="type"
                    select="
                        'duplicate_instantiation'"/>
                <xsl:attribute name="instantiationID" select="instantiationID"/>
                <xsl:attribute name="DAVIDTitle" select="DAVIDTitle"/>
                <xsl:copy-of select="$errorMessage"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="node()" name="breakItUp" mode="breakItUp">
        <xsl:param name="firstOccurrence" select="1"/>
        <xsl:param name="maxOccurrences" select="200"/>
        <xsl:param name="total" select="count(child::*)"/>
        <xsl:param name="baseURI" select="$baseURI"/>
        <xsl:param name="filename" select="document-uri()"/>
        <xsl:param name="filenameSuffix" select="'_ForCAVAFY'"/>
        <xsl:param name="currentDate" select="$currentDate"/>
        <xsl:param name="assetName" select="name(child::*[1])"/>

        <xsl:message
            select="
                'Break up document into ',
                $maxOccurrences, '-size pieces'"/>

        <xsl:variable name="lastPosition"
            select="
                count(
                *[position() ge $firstOccurrence]
                [position() le $maxOccurrences])"/>
        <xsl:variable name="filenameCavafy"
            select="
                concat(
                substring-before(
                $baseURI, '.'),
                $filename,
                $filenameSuffix,
                $currentDate,
                '_', $assetName,
                $firstOccurrence, '-',
                ($firstOccurrence + $lastPosition - 1),
                '.xml'
                )"/>
        <xsl:result-document href="{$filenameCavafy}">
            <xsl:copy>
                <xsl:comment select="$assetName, $firstOccurrence, 'to', ($firstOccurrence + $lastPosition - 1), 'from a total of', $total"/>
                <xsl:copy-of
                    select="child::*[position() ge $firstOccurrence][position() le ($maxOccurrences)]"
                />
            </xsl:copy>
        </xsl:result-document>
        <xsl:if
            test="
                ($firstOccurrence + $maxOccurrences)
                le $total">
            <xsl:call-template name="breakItUp">
                <xsl:with-param name="firstOccurrence"
                    select="
                        $firstOccurrence + $maxOccurrences"/>
                <xsl:with-param name="maxOccurrences"
                    select="
                        $maxOccurrences"/>
                <xsl:with-param name="assetName" select="
                        $assetName"/>
                <xsl:with-param name="baseURI" select="$baseURI"/>
                <xsl:with-param name="filename" select="$filename"/>
                <xsl:with-param name="filenameSuffix" select="$filenameSuffix"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
