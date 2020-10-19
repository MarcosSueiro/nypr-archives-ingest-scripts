<?xml version="1.0" encoding="UTF-8"?>
<!--    Route an input xml for processing.
        Identify the type of xml, 
        and create separate documents.-->

<!-- You will probably need to first log into cavafy.wnyc.org -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:XMP="http://ns.exiftool.ca/XMP/XMP/1.0/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" version="3.0"
    exclude-result-prefixes="#all">

    <xsl:import href="exif2NewExif.xsl"/>
    <xsl:import href="Exif2html.xsl"/>
    <xsl:import href="BWF2Exif.xsl"/>
    <xsl:import href="Exif2Slack.xsl"/>
    <xsl:import href="errorLog.xsl"/>

    <xsl:output name="log" method="html" version="4.0" indent="yes"/>
    <xsl:output name="logXml" method="xml" version="1.0" indent="yes"/>
    <xsl:output name="Exif" method="xml" version="1.0" indent="yes"/>
    <xsl:output name="FADGI" encoding="ASCII" method="xml" version="1.0" indent="yes"/>
    <xsl:output name="cavafy" encoding="UTF-8" method="xml" version="1.0" indent="yes"/>
    <xsl:output name="DAVID" encoding="ISO-8859-1" method="xml" version="1.0" indent="yes"/>
    <xsl:output name="email" encoding="UTF-8" method="xml" version="1.0" indent="yes"/>

    <xsl:variable name="baseURI" select="base-uri()"/>
    <xsl:variable name="parsedBaseURI" select="analyze-string($baseURI, '/')"/>
    <xsl:variable name="docFilename" select="$parsedBaseURI/fn:non-match[last()]"/>
    <xsl:variable name="docFilenameNoExtension" select="substring-before($docFilename, '.')"/>
    <xsl:variable name="baseFolder" select="substring-before($baseURI, $docFilename)"/>
    <xsl:variable name="logFolder" select="concat($baseFolder, 'instantiationUploadLOGS/')"/>
    <xsl:variable name="currentTime"
        select="substring(translate(string(current-time()), ':', ''), 1, 4)"/>
    <xsl:variable name="pbcorePhysicalInstantiations"
        select="doc('pbcore_instantiationphysicalaudio_vocabulary.xml')"/>
    <xsl:variable name="archiveAuthors" select="doc('archivesAuthors.xml')"/>

    <xsl:template name="masterRouter" match="/">
        <!-- Identify the type of document -->
        <xsl:message>
            <xsl:value-of
                select="
                    'Now processing file ', base-uri(),
                    ' on this fine day of ', current-dateTime()"
            />
        </xsl:message>
        <xsl:element name="choice">
            <xsl:apply-templates select="conformance_point_document" mode="BWFMetaEdit"/>
            <xsl:apply-templates select="ENTRIES" mode="DAVIDdbx"/>
            <xsl:apply-templates select="entries" mode="spreadsheet"/>
            <xsl:apply-templates select="MediaInfo"/>
            <xsl:apply-templates select="rdf:RDF" mode="masterRouter"/>
        </xsl:element>
    </xsl:template>

    <xsl:template name="BWFMetaEdit" match="conformance_point_document" mode="BWFMetaEdit">
        <!-- Accept a BWF MetaEdit xml document 
            and convert to an exiftool kind of rdf document-->
        <xsl:message>
            <xsl:value-of select="'This appears to be a BWF MetaEdit kind of document.'"/>
        </xsl:message>
        <xsl:variable name="exifFromFADGI">
            <rdf:RDF>
                <xsl:apply-templates select="File" mode="BWFMetaEdit"/>
            </rdf:RDF>
        </xsl:variable>
        <xsl:copy-of select="$exifFromFADGI"/>
        <xsl:apply-templates select="$exifFromFADGI/rdf:RDF" mode="masterRouter"/>
    </xsl:template>

    <xsl:template name="DAVIDdbx" match="ENTRIES" mode="DAVIDdbx">
        <!-- Accept an xml document (with extension '.DBX')
        as output from D.A.V.I.D.-->
        <xsl:message>
            <xsl:value-of select="'This appears to be a DAVID DBX kind of document.'"/>
        </xsl:message>
        <xsl:apply-templates select="ENTRY"/>
    </xsl:template>

    <xsl:template name="mediaInfo" match="Mediainfo">
        <!-- Accept a MediaInfo kind of xml document-->
        <xsl:message>
            <xsl:value-of select="'This appears to be a MediaInfo kind of document.'"/>
        </xsl:message>
        <xsl:apply-templates select="File"/>
    </xsl:template>

    <xsl:template name="exiftool" match="rdf:RDF" mode="masterRouter">
        <!-- Accept an exiftool kind of xml document
        as output from the command 
           exiftool -X -a -ext wav [directoryWithFiles]
        or something similar to this-->

        <!-- Basic info: type of document, number of instantiations -->
        <xsl:param name="input" select="."/>
        <xsl:message
            select="
                'Process rdf document',
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
                [upper-case(RIFF:Source) != 'NEW']"
            group-by="File:FileType">
            <xsl:message
                select="
                    count(current-group()),
                    current-grouping-key(),
                    'instantiations',
                    'with an existing asset.'"
            />
        </xsl:for-each-group>

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


        <!--Normally coming from a spreadsheet-->
        <xsl:variable name="newAssets">
            <newAssets>
                <xsl:copy-of
                    select="
                        $input/rdf:Description
                        [File:FileType = 'asset'][upper-case(RIFF:Source) = 'NEW']"
                />
            </newAssets>
        </xsl:variable>
        <xsl:variable name="totalNewAssets"
            select="
                count(
                $newAssets/newAssets/rdf:Description
                )"/>
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
        <xsl:variable name="totalUpdateAssets"
            select="
                count(
                $updateAssets/updateAssets/rdf:Description
                )"/>
        <xsl:variable name="physicalInstantiations">
            <physicalInstantiations>
                <xsl:copy-of
                    select="
                        $input/rdf:Description
                        [File:FileType =
                        $pbcorePhysicalInstantiations
                        /pbcoreInstantiationPhysicalAudioVocabulary
                        /pbcoreInstantiationPhysicalAudioTerm
                        /term]"
                />
            </physicalInstantiations>
        </xsl:variable>
        <xsl:variable name="totalPhysicalInstantiations"
            select="
                count(
                $physicalInstantiations
                /physicalInstantiations/rdf:Description
                )"/>
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
        <xsl:variable name="totalWavInstantiations"
            select="
                count(
                $wavInstantiations/wavInstantiations/rdf:Description
                )"/>
        <xsl:variable name="archivesINGESTWavInstantiations">
            <archivesINGESTWavInstantiations>
                <xsl:copy-of
                    select="
                        $wavInstantiations/wavInstantiations/rdf:Description
                        [contains(@rdf:about, 'ARCHIVESNAS1/INGEST/')]"
                />
            </archivesINGESTWavInstantiations>
        </xsl:variable>
        <xsl:variable name="totalArchivesINGESTWavInstantiations"
            select="
                count(
                $archivesINGESTWavInstantiations
                /archivesINGESTWavInstantiations/rdf:Description)"/>
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
                        select="$dbxData/dbxData/ENTRIES/ENTRY/MEDIUM/FILE/FILEREF[ends-with(., '.DBX')][1]"/>
                    <xsl:variable name="dbxTheme" select="$dbxData/dbxData/ENTRIES/ENTRY/MOTIVE"/>
                    <xsl:variable name="dbxAuthor" select="$dbxData/dbxData/ENTRIES/ENTRY/AUTHOR"/>
                    <xsl:variable name="dbxCreator" select="$dbxData/dbxData/ENTRIES/ENTRY/CREATOR"/>
                    <xsl:variable name="dbxDeleted"
                        select="$dbxData/dbxData/ENTRIES/ENTRY/SOFTDELETED"/>
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
        <xsl:variable name="totalDAVIDWavInstantiations"
            select="
                count(
                $DAVIDWavInstantiations
                /DAVIDWavInstantiations/DAVIDWavInstantiation/rdf:Description)"/>
        <xsl:variable name="DAVIDWavInstantiationsFromArchives">
            <DAVIDWavInstantiationsFromArchives>
                <xsl:copy-of
                    select="
                        $DAVIDWavInstantiations
                        /DAVIDWavInstantiations
                        /DAVIDWavInstantiation
                        [AUTHOR = $archiveAuthors/ARCHIVEAUTHORS/AUTHOR
                        or
                        CREATOR = $archiveAuthors/ARCHIVEAUTHORS/AUTHOR]"
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
                        [not(AUTHOR = $archiveAuthors/ARCHIVEAUTHORS/AUTHOR
                        or
                        CREATOR = $archiveAuthors/ARCHIVEAUTHORS/AUTHOR)]"
                />
            </DAVIDWavInstantiationsWNoThemeNotFromArchives>
        </xsl:variable>


        <!--        Check for errors in templates-->
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
                        $physicalInstantiations
                        /physicalInstantiations
                        /rdf:Description"
                />
            </physicalInstantiationResults>
        </xsl:variable>
        <xsl:variable name="archivesINGESTWavResults">
            <archivesINGESTWavResults>
                <xsl:apply-templates
                    select="
                        $archivesINGESTWavInstantiations
                        /archivesINGESTWavInstantiations
                        /rdf:Description"
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
                        /rdf:Description"
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
                        /rdf:Description"
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
                        /rdf:Description"
                />
            </DAVIDWavInstantiationsLatestNewscast>
        </xsl:variable>
        <xsl:variable name="DAVIDWavInstantiationsWNoThemeNotFromArchivesResults">
            <DAVIDWavInstantiationsWNoThemeNotFromArchivesResults>
                <xsl:apply-templates
                    select="
                        $DAVIDWavInstantiationsWNoThemeNotFromArchives
                        /DAVIDWavInstantiationsWNoThemeNotFromArchives
                        /DAVIDWavInstantiation
                        /rdf:Description"
                />
            </DAVIDWavInstantiationsWNoThemeNotFromArchivesResults>
        </xsl:variable>

        <!--        Check for duplicate instantiations-->
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
                        /parsedElements"/>
            </allParsedElements>
        </xsl:variable>

        <xsl:variable name="duplicateInstantiations">
            <xsl:apply-templates select="
                $allParsedElements
                /allParsedElements"
                mode="duplicateInstantiations"/>
        </xsl:variable>

        <!--        All errors-->
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


        <!--        ALL OUTPUTS-->

        <xsl:message select="concat('Directory: ', $baseURI)"/>
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
                        $physicalInstantiationResults
                        /result
                        /newExif
                        /rdf:Description"/>
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

<!--        Output 0.1: Complete Result Log-->
        <xsl:variable name="filenameLog"
            select="
                concat(
                $logFolder,
                $docFilenameNoExtension,
                '_LOG', format-date(current-date(),
                '[Y0001][M01][D01]'), '_T',
                $currentTime,
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
                concat(
                substring-before($baseURI, '.'),
                format-date(current-date(),
                '[Y0001][M01][D01]'),
                '.html'
                )"/>
        <xsl:result-document format="email" href="
            {$filenameHtml}">
            <xsl:apply-templates select="
                    $newExifOutput/rdf:RDF" mode="html"/>
        </xsl:result-document>

       <!-- Output 0.3: Error log
       (stop if errors)-->
        
        <xsl:call-template name="generateErrorLog">
            <xsl:with-param name="completeLog" select="$completeLog"/>
            <xsl:with-param name="duplicateInstantiations" select="$duplicateInstantiations"/>
            <xsl:with-param name="WARNINGS" select="$WARNINGS"/>
        </xsl:call-template>
        
        <!-- If errors, stop right here -->
        <xsl:if
            test="
            $completeLog
            //*[local-name() = 'error']
            ">
            <xsl:message terminate="yes">
                <xsl:value-of select="'Errors found.'"/>
                <xsl:copy-of select="$completeLog//*[local-name() = 'error']"/>
            </xsl:message>
        </xsl:if>
        
        <!-- If no errors, all other outputs -->

        <!--        Output 1: New ExifTool-->
        <xsl:variable name="filenameExif"
            select="concat(substring-before($baseURI, '.'), '_NewExif', format-date(current-date(), '[Y0001][M01][D01]'), '.xml')"/>
        <xsl:result-document format="Exif" href="{$filenameExif}">
            <xsl:copy-of select="$newExifOutput"/>
        </xsl:result-document>

        <!--        Output 2: FADGI-->
        <xsl:variable name="filenameFADGI"
            select="concat(substring-before($baseURI, '.'), '_ForFADGI', format-date(current-date(), '[Y0001][M01][D01]'), '.xml')"/>
        <xsl:result-document format="FADGI" href="{$filenameFADGI}">
            <xsl:apply-templates select="$newExifOutput/rdf:RDF" mode="ixmlFiller"/>
        </xsl:result-document>

        <!--        Output 3: cavafy-->
        <xsl:variable name="cavafyOutput">
            <xsl:apply-templates select="$newExifOutput/rdf:RDF" mode="cavafy"/>
        </xsl:variable>

        <!-- Needs to be split into bite-size chunks of about 40 assets -->
        <xsl:variable name="cavafyAssetsCount"
            select="count($cavafyOutput/pb:pbcoreCollection/pb:pbcoreDescriptionDocument)"/>
        <xsl:variable name="maxCavafyAssets" select="40" as="xs:integer"/>
        <xsl:comment select="'total instances', count(*)"/>

        <xsl:apply-templates select="$cavafyOutput/pb:pbcoreCollection" mode="breakItUp">
            <xsl:with-param name="maxOccurrences" select="$maxCavafyAssets"/>
        </xsl:apply-templates>

        <!--        Output 4: DAVID-->
        <!-- Output 4.1: MUNI -->

        <xsl:if
            test="
                $newExifOutput/rdf:RDF/rdf:Description/RIFF:Description
                [starts-with(., 'MUNI-')]
                ">
            <xsl:variable name="filenameDAVIDMuni"
                select="concat(substring-before($baseURI, '.'), '-MUNI_', format-date(current-date(), '[Y0001][M01][D01]'), '.DBX')"/>
            <xsl:result-document format="DAVID" href="{$filenameDAVIDMuni}">
                <ENTRIES>
                    <xsl:apply-templates
                        select="
                            $newExifOutput/rdf:RDF/rdf:Description
                            [starts-with(RIFF:Description, 'MUNI-')]"
                        mode="DAVID"/>
                </ENTRIES>
            </xsl:result-document>
        </xsl:if>
        <!-- Output 4.2: WQXR -->
        <xsl:if
            test="
                $newExifOutput/rdf:RDF/rdf:Description/RIFF:Description
                [starts-with(., 'WQXR-')]
                ">
            <xsl:variable name="filenameDAVIDWQXR"
                select="concat(substring-before($baseURI, '.'), '-WQXR_', format-date(current-date(), '[Y0001][M01][D01]'), '.DBX')"/>
            <xsl:result-document format="DAVID" href="{$filenameDAVIDWQXR}">
                <ENTRIES>
                    <xsl:apply-templates
                        select="
                            $newExifOutput/rdf:RDF/rdf:Description
                            [starts-with(RIFF:Description, 'WQXR-')]
                            "
                        mode="DAVID"/>
                </ENTRIES>
            </xsl:result-document>
        </xsl:if>
        <!-- Output 4.3: On the Media -->
        <xsl:if
            test="
                $newExifOutput/rdf:RDF/rdf:Description/RIFF:Description
                [contains(., '-OTM-')]
                ">
            <xsl:variable name="filenameDAVIDOTM"
                select="concat(substring-before($baseURI, '.'), '-OTM_', format-date(current-date(), '[Y0001][M01][D01]'), '.DBX')"/>
            <xsl:result-document format="DAVID" href="{$filenameDAVIDOTM}">
                <ENTRIES>
                    <xsl:apply-templates
                        select="
                            $newExifOutput/rdf:RDF/rdf:Description
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
                select="concat(substring-before($baseURI, '.'), '-96k24_', format-date(current-date(), '[Y0001][M01][D01]'), '.DBX')"/>
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
                select="concat(substring-before($baseURI, '.'), '-48k_', format-date(current-date(), '[Y0001][M01][D01]'), '.DBX')"/>
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
                $newExifOutput/rdf:RDF/rdf:Description
                [RIFF:SampleRate = '44100']
                [RIFF:BitsPerSample = '16']
                [not(starts-with(RIFF:Description, 'MUNI-'))]
                [not(starts-with(RIFF:Description, 'WQXR-'))]
                [not(contains(RIFF:Description, '-OTM-'))]">
            <xsl:variable name="filenameDAVID44k16"
                select="concat(substring-before($baseURI, '.'), '-44k16_', format-date(current-date(), '[Y0001][M01][D01]'), '.DBX')"/>
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
                select="concat(substring-before($baseURI, '.'), '-44k24_', format-date(current-date(), '[Y0001][M01][D01]'), '.DBX')"/>
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
                select="concat(substring-before($baseURI, '.'), '-WebEdit_', format-date(current-date(), '[Y0001][M01][D01]'), '.DBX')"/>
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

        <!-- Output 5: Slack -->
        <xsl:apply-templates select="
            $newExifOutput
            /rdf:RDF
            [not(//error)]" 
            mode="slack"/>

    </xsl:template>

    <xsl:template name="duplicateInstantiations" match="
        allParsedElements" mode="
        duplicateInstantiations">
        <!-- Check for duplicate instantiations within the document -->
        <xsl:message>
            <xsl:value-of select="
                'Check for duplicate instantiations ',
                'in values '"/>
            <xsl:value-of select="
                parsedElements
                /instantiationID" 
                separator=", "/>
        </xsl:message>
        <xsl:for-each
            select="
                parsedElements
                [./instantiationID =
                ./following-sibling::parsedElements
                /instantiationID]">
            <xsl:variable name="errorMessage">
                <xsl:value-of select="
                    concat(
                    'ATTENTION!! ',
                    'duplicate instantiation: ',
                    ./instantiationID, ' within ',
                    DAVIDTitle
                    )"/>
            </xsl:variable>
                
            <xsl:message select="$errorMessage"/>
            <xsl:element name="error">
                <xsl:attribute name="type" select="
                    'duplicate_instantiation'"/>
                <xsl:attribute name="instantiationID" select="instantiationID"/>
                <xsl:attribute name="DAVIDTitle" select="DAVIDTitle"/>
                <xsl:copy-of select="$errorMessage"/>
            </xsl:element>
        </xsl:for-each>
        <xsl:for-each
            select="
            parsedElements
            [./instantiationID =
            ./preceding-sibling::parsedElements
            /instantiationID]">
            <xsl:variable name="errorMessage">
                <xsl:value-of select="
                concat(
                'ATTENTION!! ',
                'duplicate instantiation: ',
                ./instantiationID, ' within ',
                DAVIDTitle
                )"/>
            </xsl:variable>
            <xsl:message select="$errorMessage"/>
            <xsl:element name="error">
                <xsl:attribute name="type" select="
                    'duplicate_instantiation'"/>
                <xsl:attribute name="instantiationID" select="instantiationID"/>
                <xsl:attribute name="DAVIDTitle" select="DAVIDTitle"/>
                <xsl:copy-of select="$errorMessage"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="breakItUp" match="
            pb:pbcoreCollection" mode="breakItUp">
        <!-- break up large cavafy files -->
        <xsl:param name="firstOccurrence" select="
            1" as="xs:integer"/>
        <xsl:param name="maxOccurrences" as="
            xs:integer" select="40"/>

        <xsl:variable name="lastPosition" select="
            count(
            *[position() ge $firstOccurrence]
            )"
            as="xs:integer"/>
        <xsl:comment select="
            'last position: ', $lastPosition, 
            'maxOcccurrences: ', $maxOccurrences"/>

        <xsl:choose>
            <xsl:when test="
                $lastPosition le $maxOccurrences">
                <xsl:variable name="
                    filenameCavafy"
                    select="concat(
                    substring-before(
                    $baseURI, '.'), 
                    '_ForCAVAFY', 
                    format-date(current-date(), 
                    '[Y0001][M01][D01]'), 
                    '_Assets', 
                    $firstOccurrence, '-', 
                    $firstOccurrence + $lastPosition - 1, 
                    '.xml'
                    )"/>
                <xsl:result-document format="
                    cavafy" href="{$filenameCavafy}">
                    <xsl:copy select=".">
                        <xsl:copy-of select="
                            ./*[position() ge $firstOccurrence]
                            "/>
                    </xsl:copy>
                </xsl:result-document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="filenameCavafy"
                    select="
                    concat(
                    substring-before($baseURI, '.'), 
                    '_ForCAVAFY', 
                    format-date(current-date(), 
                    '[Y0001][M01][D01]'), 
                    '_Assets', $firstOccurrence, '-', 
                    $firstOccurrence + $maxOccurrences - 1, 
                    '.xml'
                    )"/>
                <xsl:result-document format="
                    cavafy" href="{$filenameCavafy}">
                    <xsl:copy select=".">
                        <xsl:copy-of
                            select="
                            ./*
                            [position() ge $firstOccurrence 
                            and 
                            position() lt $firstOccurrence + $maxOccurrences]"
                        />
                    </xsl:copy>
                </xsl:result-document>
                <xsl:apply-templates select="." mode="breakItUp">
                    <xsl:with-param name="firstOccurrence"
                        select="
                        $firstOccurrence 
                        + 
                        $maxOccurrences"/>
                    <xsl:with-param name="
                        maxOccurrences" select="
                        $maxOccurrences"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    

</xsl:stylesheet>
