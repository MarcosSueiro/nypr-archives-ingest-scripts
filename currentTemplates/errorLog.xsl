<?xml version="1.0" encoding="UTF-8"?>
<!-- Accept an error log in xml
and output an html error doc -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    exclude-result-prefixes="xs"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    version="2.0">
    
    <xsl:output name="log" method="html" version="4.0" indent="yes"/>
    <xsl:output name="csv" method="text" indent="yes"/>
    
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
    <xsl:variable name="archivesAuthors" select="doc('archivesAuthors.xml')"/>
    
    <xsl:template name="generateErrorLog">        
        <xsl:param name="completeLog"/>
        <xsl:param name="duplicateInstantiations" select="
            dummyNode"/>
        <xsl:param name="WARNINGS"/>
        <xsl:param name="seriesName" select="
            $completeLog/completeLog/seriesName"/>
        <xsl:param name="seriesNameNoSpace" select="
            replace($seriesName, '\P{L}', '')"/>
        <xsl:param name="seriesEntry" select="
            $completeLog/completeLog/seriesEntry"/>
        
        <xsl:message select="'Generate error log'"/>
        
        <xsl:variable name="errorFreeMessage">
            <xsl:value-of select="
                count(
                $completeLog//result
                [not(.//*[local-name() = 'error'])]
                )"/> files are all right: <br/>
            <xsl:for-each
                select="
                $completeLog
                //result
                [not(.//*[local-name() = 'error'])]
                ">
                <xsl:value-of select="
                    ./@filename"/>
                <br/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="duplicateInstantiationMessage">
            <b>
                <xsl:value-of
                    select="
                        count($duplicateInstantiations/error[@type = 'duplicate_instantiation']
                        )"
                /> files have duplicate instantiation numbers and must be renamed: <br/>
                <xsl:for-each select="$duplicateInstantiations/error">
                    <xsl:value-of select="@DAVIDTitle"/>
                    <br/>
                </xsl:for-each>
            </b>
        </xsl:variable>
        <xsl:variable name="errorCount" select="
            count(
            $completeLog//result[.//*[local-name() = 'error']]
            )"/>
        <xsl:variable name="warningCount" select="
            count(
            $completeLog
            //result
            [.//*[local-name() = 'warning']]
            )"/>
        <xsl:variable name="totalCount" select="
            count(
            $completeLog//
            result
            ) + count(
            $completeLog/completeLog/
            unacceptableFiles/error
            )"/>
        <xsl:variable name="errorPercent" select="format-number(
            $errorCount div $totalCount, '##%')"/>
        <xsl:variable name="warningPercent" select="format-number(
            $warningCount div $totalCount, '##%')"/>
        <xsl:variable name="errorMessage">
            <xsl:value-of select="$errorCount"/>
            <xsl:value-of select="' files ('"/>
            <xsl:value-of select="$errorPercent"/>
            <xsl:value-of select="') have errors: '"/>
            <br/>
            <xsl:for-each
                select="
                $completeLog//result
                [.//*[local-name() = 'error']]">
                <xsl:value-of select="@filename"/>
                <br/>
            </xsl:for-each>                
        </xsl:variable>
        <xsl:variable name="warningMessage">
            <xsl:value-of select="$warningCount"/>
            <xsl:value-of select="' files ('"/>
            <xsl:value-of select="$warningPercent"/>
            <xsl:value-of select="') have warnings: '"/>
            <br/>
            <xsl:for-each
                select="
                $completeLog//result
                [.//*[local-name() = 'warning']]">
                <xsl:value-of select="./@filename"/>
                <br/>
            </xsl:for-each>                
        </xsl:variable>
        
        <xsl:message select="$errorFreeMessage"/>        
        <xsl:message select="$duplicateInstantiationMessage"/>
        <xsl:message select="$errorMessage"/>
        <xsl:message select="$warningMessage"/>
        
        <!--    Error Log -->
        <xsl:variable name="filenameErrorLog"
            select="
            concat(
            $logFolder,
            $docFilenameNoExtension,
            '_ERRORLOG',
            $seriesNameNoSpace,
            format-date(current-date(), 
            '[Y0001][M01][D01]'),
            '_T', $currentTime,
            '.html')"/>
        <xsl:variable name="filenameErrorCSV"
            select="
            concat(
            $logFolder,
            $docFilenameNoExtension,
            '_ERRORLOG',
            $seriesNameNoSpace,
            '.csv')"/>
        <xsl:result-document format="log" href="
            {$filenameErrorLog}">
            <html>
                <head> <xsl:value-of select="concat(
                    'Error log for ',
                    $docFilenameNoExtension,
                    ' on ',
                    format-date(
                    current-date(), '[Y0001][M01][D01]'),
                    ' at ', $currentTime)"/> </head>
                <body>
                    <p/>
                    <h1><a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="$completeLog/completeLog/seriesURL"/>
                        </xsl:attribute>
                        <xsl:value-of select="
                        $completeLog/completeLog/seriesName/concat('Series: ', .)"/>
                    </a>
                    </h1>
                    <p><xsl:apply-templates select="
                        $seriesEntry
                        /*:pbcoreCollection
                        /*:pbcoreDescriptionDocument"
                    mode="cavafyBasicsHtml"/></p>                    
                    <xsl:copy-of select="
                        $errorFreeMessage"/>
                    <p> ******************* </p>
                    <xsl:copy-of select="
                        $duplicateInstantiationMessage"/>
                    <p> ******************* </p>
                    <xsl:copy-of select="
                        $errorMessage"/>
                    <xsl:copy-of select="
                        $warningMessage"/>
                    <p> ******************* </p>
                    <br/>
                    
                    <div>
                        <b><xsl:for-each select="
                            $duplicateInstantiations//error[. != '']">
                            <xsl:value-of select="concat(@type, ': ', @DAVIDTitle)"/>
                            <br/>
                        </xsl:for-each></b>
                    </div>
                    
                    <xsl:for-each
                        select="
                        $completeLog//result
                        [.//*[local-name() = 'error']]">
                        <xsl:variable name="justFilename">
                            <xsl:value-of
                                select="
                                tokenize(
                                translate(
                                @filename[not(contains(., 'cavafy'))], '\', '/'), '/')
                                [last()]"/> <!-- Extract just the filename -->
                            <xsl:value-of select="@filename[contains(., 'cavafy')]"/><!--Or the cavafy link -->
                        </xsl:variable>
                        <!-- Link to the file -->
                        <xsl:variable name="href" select="
                            if 
                            (contains(@filename, 'cavafy'))
                            then
                            @filename
                            else
                            concat('file:///', 
                            inputs/originalExif
                            /rdf:Description
                            /System:Directory, 
                            '/', 
                            $justFilename[. != ''])"/>
                            
                        <div>
                            <p>
                                <b> ERRORS related to filename or asset <a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of
                                            select="$href"
                                        /> 
                                    </xsl:attribute>
                                    <xsl:value-of select="$justFilename"/></a>: </b>
                                <br/>
                                <p>
                                    <xsl:for-each select=".//*:error">
                                        <xsl:value-of select="@type, ': '"/>
                                        <xsl:value-of select="."/>
                                        <br/>
                                    </xsl:for-each>
                                </p>
                                <a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of
                                            select="./inputs/parsedDAVIDTitle/parsedElements/finalCavafyURL"
                                        /> </xsl:attribute>
                                    <xsl:attribute name="
                                        target" select="
                                        '_blank'"/>cavafy entry
                                    (if found) </a>
                            </p>
                        </div>
                    </xsl:for-each>
                    
                    <xsl:for-each
                        select="
                        $completeLog//result
                        [.//*[local-name() = 'warning']]">
                        <xsl:variable name="justFilename">
                            <xsl:value-of
                                select="
                                tokenize(
                                translate(
                                @filename[not(contains(., 'cavafy'))], '\', '/'), '/')
                                [last()]"/> <!-- Extract just the filename -->
                            <xsl:value-of select="@filename[contains(., 'cavafy')]"/><!--Or the cavafy link -->
                        </xsl:variable>
                        <!-- Link to the file -->
                        <xsl:variable name="href" select="
                            if 
                            (contains(@filename, 'cavafy'))
                            then
                            @filename
                            else
                            concat('file:///', 
                            inputs/originalExif
                            /rdf:Description
                            /System:Directory, 
                            '/', 
                            $justFilename[. != ''])"/>
                        
                        <div>
                            <p>
                                <b> Warnings related to filename or asset <a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of
                                            select="$href"
                                        /> 
                                    </xsl:attribute>
                                    <xsl:value-of select="$justFilename"/></a>: </b>
                                <br/>
                                <p>
                                    <xsl:for-each select=".//*:warning">
                                        <xsl:value-of select="@type, ': '"/>
                                        <xsl:value-of select="."/>
                                        <br/>
                                    </xsl:for-each>
                                </p>
                                <a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of
                                            select="./inputs/parsedDAVIDTitle/parsedElements/finalCavafyURL"
                                        /> </xsl:attribute>
                                    <xsl:attribute name="
                                        target" select="
                                        '_blank'"/>cavafy entry
                                    (if found) </a>
                            </p>
                        </div>
                    </xsl:for-each>
                    
                    <xsl:element name="warnings">
                        <xsl:copy-of select="$WARNINGS"/>
                    </xsl:element>
                </body>
            </html>
        </xsl:result-document>
        <xsl:result-document format="csv" href="
            {$filenameErrorCSV}">
            <xsl:value-of
                select="
                string-join(
                    ('filename', 'assetID[1]', 'assetDate[1+]' ,
                    'Collection[1]', 'Series[1]', 'Episode[1]',
                    'LoCSH[1+]',
                    'Abstract[1]', 'Genre[1]',
                    'Creators[1+]', 'Contributors[1+]',
                    'CMSImage[0-1]', 'Copyright[1]',
                    'instID[1]', 'Format[1]',
                    'formatLocation[1]', 'mediaType[1]',
                    'Generation[0-1]', 'EssenceTrack[0-1]'
                    ),
                    ','
                    )"/>
            <xsl:for-each
                select="
                    $completeLog//result
                    [.//*[local-name() = 'error']]">
                <xsl:variable name="justFilename">
                    <!-- Extract just the filename -->
                    <xsl:value-of
                        select="
                            tokenize(
                            translate(
                            @filename[not(contains(., 'cavafy'))], '\', '/'), '/')
                            [last()]"/>
                    <!--Or the cavafy link -->
                    <xsl:value-of select="@filename[contains(., 'cavafy')]"/>                    
                </xsl:variable>
                <!-- Link to the file -->
                <xsl:variable name="href"
                    select="
                        if
                        (contains(@filename, 'cavafy'))
                        then
                            @filename
                        else
                            concat('file:///',
                            inputs/originalExif
                            /rdf:Description
                            /System:Directory,
                            '/',
                            $justFilename[. != ''])"/>

                <xsl:value-of select="'&#10;'"/>
                <xsl:value-of select="$justFilename"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'cavafyID')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'assetDate')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'collection')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'series')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'episode')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'subjectHeading')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'abstract')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'genre')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'creatorPublisher')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'contributor')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'cmsImage')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'copyright')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'instantiationID')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'format')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'location')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'media')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'eneration')])"/><xsl:value-of select="','"/>
                <xsl:value-of select="count(.//*:error/@type[contains(., 'essence')])"/><xsl:value-of select="','"/>
            </xsl:for-each>
        </xsl:result-document>
    </xsl:template>
    
</xsl:stylesheet>