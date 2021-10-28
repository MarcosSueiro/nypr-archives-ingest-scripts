<?xml version="1.0" encoding="UTF-8"?>
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

    <xsl:import href="masterRouter.xsl"/>

    <xsl:output name="cavafy" encoding="UTF-8" method="xml" version="1.0" indent="yes"/>
    
    <!-- 
        This script merges a source instantiation 
        into a destination asset, 
        and deletes the source instantiation from the source asset.
        
        This is used to merge 
        instantiations from a source asset
        into a destination asset
        which you think is more suitable.
        
        It has seven parameters,
        two of which are required*:
        
        sourceInstantiationID*
        destinationAssetID*
        newInstantiationID
        newTitle
        newAbstract
        newGenre
        newCopyright
        
        If you just supply the two required parameters,
        the script will generate
        three documents. 
        Documents 1 and 2 
        will be ready for import
        into cavafy.
        
        (DOCUMENT 1)
        1. Add the source instantiation 
        to the destination asset 
        using the next instantiation ID available
        (and note the original instantiation ID)
        2. Delete the source instantiation 
        from the source asset
        3. Merge all the unique asset-level fields:
        titles, descriptions, etc.
        4. If the source asset
        ends up with no instantiations,
        mark it for deletion
        
        (DOCUMENT 2)
        5. Take a snapshot of cavafy 
        before the merge,
        lest something go awry
        
        (DOCUMENT 3)
        6. List errors (e.g. if the values supplied
        are not consistent)
        
        The other five parameters allow you to create new values for
        new instantiation ID, episode title, 
        abstract, genre, and copyright
        (and thus 
        LOSE ALL ORIGINAL VALUES FROM SOURCE
        AND DESTINATION ASSETS)
        
        The xml source document 
        should look like this, e.g.:
        
        <mergeAllAssets>
            <mergeAssets>
                <sourceInstantiationID>250437.1</sourceInstantiationID>
                <destinationAssetID>250702</destinationAssetID>
                <newInstantiationID>250702.6</newInstantiationID>
                <newTitle></newTitle>
                <newAbstract>The poet Jessica Care Moore and the actor and director Roger Guenveur Smith live at Central Park SummerStage.</newAbstract>
                <newGenre>Reading</newGenre>
                <newCopyright>Terms of Use and Reproduction: WNYC Radio. Additional copyright may apply to musical selections.</newCopyright>
            </mergeAssets>
            <mergeAssets>
                <sourceInstantiationID>250437.1</sourceInstantiationID>
                <destinationAssetID>250702</destinationAssetID>
                <newInstantiationID>250702.7</newInstantiationID>
                <newTitle></newTitle>
                <newAbstract>The poet Jessica Care Moore and the actor and director Roger Guenveur Smith live at Central Park SummerStage.</newAbstract>
                <newGenre>Reading</newGenre>
                <newCopyright>Terms of Use and Reproduction: WNYC Radio. Additional copyright may apply to musical selections.</newCopyright>
            </mergeAssets>    
        </mergeAllAssets>
    -->

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

    <xsl:variable name="filenameRestore"
        select="
            concat(
            $logFolder,
            $masterDocFilenameNoExtension,
            '_RESTORE', format-date(current-date(),
            '[Y0001][M01][D01]'), '_T',
            $currentTime,
            '.xml'
            )"/>
    
    <xsl:variable name="filenameError"
        select="
        concat(
        $logFolder,
        $masterDocFilenameNoExtension,
        '_ERRORLOG', format-date(current-date(),
        '[Y0001][M01][D01]'), '_T',
        $currentTime,
        '.html'
        )"/>

    <xsl:variable name="filenameMerged"
        select="
            concat(
            $baseFolder,
            $masterDocFilenameNoExtension,
            '_MERGED', format-date(current-date(),
            '[Y0001][M01][D01]'),
            '.xml'
            )"/>

    <xsl:template match="mergeAllAssets">
        <xsl:param name="instIDsToDelete" select="
            mergeAssets[newInstantiationID]
            [newInstantiationID != sourceInstantiationID]/
            sourceInstantiationID"/>
        <xsl:param name="newInstantiationIDs" select="
            mergeAssets[newInstantiationID]
            [newInstantiationID != sourceInstantiationID]/newInstantiationID"/>
        <xsl:param name="dupNewInstIDs">
            <xsl:copy-of select="
                $newInstantiationIDs
                [. = preceding::newInstantiationID]
                [matches(., $instIDRegex)]"/>
        </xsl:param>
        <xsl:param name="mergeAssets">
            <!-- Mark as errors
                repeated destination IDs -->
            <xsl:for-each select="$dupNewInstIDs/newInstantiationID">
                <error type="duplicateNewInstantiationID">
                    <xsl:value-of
                        select="
                        'ERROR: more than one instantiation ID',
                        'with value', ."
                    />
                </error>
            </xsl:for-each>
            <xsl:for-each-group select="
                mergeAssets[newInstantiationID]
                [newInstantiationID != sourceInstantiationID]" group-by="
                destinationAssetID">
                <xsl:variable name="destinationAssetXML">
                    <xsl:call-template name="findSpecificCavafyAssetXML">
                        <xsl:with-param name="assetID"
                            select="
                            current-grouping-key()"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="nextInstantiationSuffixDigit">
                    <xsl:call-template name="nextInstantiationSuffixDigit">
                        <xsl:with-param name="instantiationID"/>
                        <xsl:with-param name="assetID"
                            select="
                            destinationAssetID"/>
                        <xsl:with-param name="foundAsset"
                            select="
                            $destinationAssetXML"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="newTitle">                    
                    <xsl:call-template name="checkConflicts">
                        <xsl:with-param name="field1">
                            <xsl:value-of select="
                                fn:current-group()/newTitle" separator="
                                {$separatingTokenForFreeTextFields}"/>
                        </xsl:with-param>
                        <xsl:with-param name="fieldName"
                            select="
                            'newTitle'"/>
                        <xsl:with-param name="defaultValue" select="''"/>
                        <xsl:with-param name="separatingToken"
                            select="
                            $separatingTokenForFreeTextFields"
                        />
                    </xsl:call-template>                    
                </xsl:variable>
                <xsl:variable name="newAbstract">
                    <xsl:call-template name="checkConflicts">
                        <xsl:with-param name="field1">
                            <xsl:value-of select="
                                fn:current-group()/newAbstract" separator="
                                {$separatingTokenForFreeTextFields}"/>
                        </xsl:with-param>
                        <xsl:with-param name="fieldName"
                            select="
                            'newAbstract'"/>
                        <xsl:with-param name="defaultValue" select="''"/>
                        <xsl:with-param name="separatingToken"
                            select="
                            $separatingTokenForFreeTextFields"
                        />
                    </xsl:call-template>                    
                </xsl:variable>
                <xsl:variable name="newGenre">
                    <xsl:call-template name="checkConflicts">
                        <xsl:with-param name="field1">
                            <xsl:value-of select="
                                fn:current-group()/newGenre" separator="
                                {$separatingToken}"/>
                        </xsl:with-param>
                        <xsl:with-param name="fieldName"
                            select="
                            'newGenre'"/>
                        <xsl:with-param name="defaultValue" select="''"/>
                        <xsl:with-param name="separatingToken"
                            select="
                            $separatingToken"
                        />
                    </xsl:call-template>                    
                </xsl:variable>
                <xsl:variable name="newCopyright">
                    <xsl:call-template name="checkConflicts">
                        <xsl:with-param name="field1">
                            <xsl:value-of select="
                                fn:current-group()/newCopyright" separator="
                                {$separatingTokenForFreeTextFields}"/>
                        </xsl:with-param>
                        <xsl:with-param name="fieldName"
                            select="
                            'newCopyright'"/>
                        <xsl:with-param name="defaultValue" select="''"/>
                        <xsl:with-param name="separatingToken"
                            select="
                            $separatingTokenForFreeTextFields"
                        />
                    </xsl:call-template>                    
                </xsl:variable>
               
                <xsl:variable name="sourceInstantiationData">
                    <xsl:for-each select="fn:current-group()">
                        <xsl:message select="'POSITION: ', position()"/>
                        <xsl:variable name="sourceInstantiationID"
                            select="
                                sourceInstantiationID"/>
                        <xsl:variable name="sourceInstIDParsed">
                            <xsl:call-template name="parseInstantiationID">
                                <xsl:with-param name="instantiationID"
                                    select="
                                        $sourceInstantiationID"
                                />
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="newInstIDParsed">
                            <xsl:apply-templates
                                select="
                                    newInstantiationID
                                    [matches(., '[0-9]{4,6}\.[0-9]')]"
                                mode="parseInstantiationID"/>
                        </xsl:variable>
                        <xsl:variable name="destinationAssetID">
                            <xsl:call-template name="checkConflicts">
                                <xsl:with-param name="field1"
                                    select="
                                        current-grouping-key()
                                        [matches(., '[0-9]{4,6}')]"/>
                                <xsl:with-param name="field2"
                                    select="
                                        $newInstIDParsed/instantiationIDParsed/
                                        assetID"/>
                                <xsl:with-param name="fieldName"
                                    select="
                                        'destinationAssetID'"
                                />
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="sourceAssetID"
                            select="
                                $sourceInstIDParsed/instantiationIDParsed/assetID"/>
                        <xsl:variable name="sourceInstAssetXML">
                            <xsl:call-template name="findSpecificCavafyAssetXML">
                                <xsl:with-param name="assetID"
                                    select="
                                        $sourceAssetID"
                                />
                            </xsl:call-template>
                        </xsl:variable>

                        <xsl:variable name="sourceInstantiation">
                            <xsl:call-template name="findInstantiation">
                                <xsl:with-param name="instantiationID"
                                    select="$sourceInstantiationID"/>
                                <xsl:with-param name="cavafyEntry" select="$sourceInstAssetXML"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <instantiationToAdd>
                            <xsl:copy-of select="$sourceInstAssetXML"/>
                            <xsl:copy-of select="$sourceInstantiation"/>
                            <sourceInstantiationID>
                                <xsl:value-of select="$sourceInstantiationID"/>
                            </sourceInstantiationID>
                            <sourceAssetID>
                                <xsl:value-of select="$sourceAssetID"/>
                            </sourceAssetID>
                            <destinationAssetID>
                                <xsl:copy-of select="$destinationAssetID"/>
                            </destinationAssetID>
                            <newInstantiationID>
                                <xsl:choose>
                                    <xsl:when
                                        test="
                                            matches(newInstantiationID,
                                            concat($destinationAssetID, '\.[0-9]'))">
                                        <xsl:value-of select="newInstantiationID"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$destinationAssetID"/>
                                        <xsl:value-of select="'.'"/>
                                        <xsl:value-of
                                            select="
                                                $nextInstantiationSuffixDigit + position() - 1"
                                        />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </newInstantiationID>
                        </instantiationToAdd>
                    </xsl:for-each>
                </xsl:variable>
             
                <xsl:element name="restoreDoc">
                    <xsl:variable name="destinationUUID"
                        select="
                            $destinationAssetXML/
                            pb:pbcoreDescriptionDocument/
                            pb:pbcoreIdentifier
                            [@source = 'pbcore XML database UUID']"/>
                    <xsl:copy-of select="$destinationAssetXML"/>
                    <xsl:for-each-group
                        select="
                            $sourceInstantiationData/
                            instantiationToAdd"
                        group-by="sourceAssetID">
                        <xsl:copy-of
                            select="
                                pb:pbcoreDescriptionDocument
                                [
                                not(
                                pb:pbcoreIdentifier
                                [@source = 'pbcore XML database UUID'] =
                                $destinationUUID)]"
                        />
                    </xsl:for-each-group>
                </xsl:element>
                <xsl:element name="mergeDoc">
                    <!-- New asset with additional instantiation -->
                    <xsl:copy
                        select="
                            $destinationAssetXML/
                            pb:pbcoreDescriptionDocument">

                        <!-- Merge Asset Dates -->
                        <xsl:for-each-group
                            select="
                                ($destinationAssetXML | 
                                $sourceInstantiationData/instantiationToAdd)/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreAssetDate"
                            group-by=".">
                            <xsl:copy-of select=".[not(@dateType)]"/>
                            <xsl:for-each-group select="current-group()" group-by="@dateType">
                                <xsl:copy-of select="."/>
                            </xsl:for-each-group>
                        </xsl:for-each-group>

                        <!-- Merge asset identifiers -->
                        <xsl:for-each-group
                            select="
                                ($destinationAssetXML/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreIdentifier) | ($sourceInstantiationData/instantiationToAdd/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreIdentifier
                                [not(@source = 'WNYC Archive Catalog')]
                                [not(@source = 'pbcore XML database UUID')])"
                            group-by=".">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>

                        <!-- Create / check new titles -->
                        <!-- Episode -->
                        <xsl:choose>
                            <xsl:when test="matches($newTitle, '[A-Z]')">
                                <xsl:element name="pbcoreTitle"
                                    namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                                    <xsl:attribute name="titleType" select="'Episode'"/>
                                    <xsl:copy-of select="$newTitle"/>
                                </xsl:element>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:for-each-group
                                    select="
                                        (
                                        $destinationAssetXML |
                                        $sourceInstantiationData/instantiationToAdd)/
                                        pb:pbcoreDescriptionDocument/
                                        pb:pbcoreTitle
                                        [@titleType = 'Episode']"
                                    group-by=".">
                                    <xsl:copy-of select="."/>
                                </xsl:for-each-group>
                            </xsl:otherwise>
                        </xsl:choose>

                        <!-- Series -->
                        <xsl:for-each-group
                            select="
                                ($destinationAssetXML |
                                $sourceInstantiationData/instantiationToAdd)/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreTitle[@titleType = 'Series']"
                            group-by=".">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>

                        <!-- Collection -->
                        <xsl:for-each-group
                            select="
                                ($destinationAssetXML | 
                                $sourceInstantiationData/instantiationToAdd)/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreTitle
                                [@titleType = 'Collection']"
                            group-by=".">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>

                        <!-- Subjects -->
                        <xsl:for-each-group
                            select="
                                ($destinationAssetXML | 
                                $sourceInstantiationData/instantiationToAdd)/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreSubject"
                            group-by=".">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>

                        <!-- Create new abstract -->
                        <xsl:choose>
                            <xsl:when test="matches($newAbstract, '[A-Z]')">
                                <xsl:element name="pbcoreDescription"
                                    namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                                    <xsl:attribute name="descriptionType"
                                        select="
                                            'Abstract'"/>
                                    <xsl:copy-of select="$newAbstract"/>
                                </xsl:element>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:for-each-group
                                    select="
                                        ($destinationAssetXML | 
                                        $sourceInstantiationData/instantiationToAdd)/
                                        pb:pbcoreDescriptionDocument/
                                        pb:pbcoreDescription
                                        [@descriptionType = 'Abstract']"
                                    group-by=".">
                                    <xsl:copy-of select="."/>
                                </xsl:for-each-group>
                            </xsl:otherwise>
                        </xsl:choose>

                        <!-- Merge other descriptions -->
                        <xsl:for-each-group
                            select="
                                (
                                $destinationAssetXML |
                                $sourceInstantiationData/instantiationToAdd
                                )/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreDescription
                                [not(@descriptionType = 'Abstract')]"
                            group-by=".">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>

                        <!-- Create new genre -->
                        <xsl:choose>
                            <xsl:when test="matches($newGenre, '\w')">
                                <xsl:element name="pbcoreGenre"
                                    namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                                    <xsl:copy-of select="$newGenre"/>
                                </xsl:element>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:for-each-group
                                    select="
                                        ($destinationAssetXML | 
                                        $sourceInstantiationData/instantiationToAdd)/
                                        pb:pbcoreDescriptionDocument/
                                        pb:pbcoreGenre"
                                    group-by=".">
                                    <xsl:copy-of select="."/>
                                </xsl:for-each-group>
                            </xsl:otherwise>
                        </xsl:choose>


                        <!-- Merge relations -->
                        <xsl:for-each-group
                            select="
                                ($destinationAssetXML | 
                                $sourceInstantiationData/instantiationToAdd)/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreRelation"
                            group-by="pb:pbcoreRelationIdentifier">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>

                        <!-- Merge coverage -->
                        <xsl:for-each-group
                            select="
                                ($destinationAssetXML | 
                                $sourceInstantiationData/instantiationToAdd)/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreCoverage"
                            group-by="pb:coverage">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>

                        <!-- Merge creators -->
                        <xsl:for-each-group
                            select="
                                ($destinationAssetXML | 
                                $sourceInstantiationData/instantiationToAdd)/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreCreator"
                            group-by="pb:creator">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>

                        <!-- Merge contributors -->
                        <xsl:for-each-group
                            select="
                                ($destinationAssetXML | 
                                $sourceInstantiationData/instantiationToAdd)/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreContributor"
                            group-by="pb:contributor">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>

                        <!-- Merge publishers -->
                        <xsl:for-each-group
                            select="
                                ($destinationAssetXML | $sourceInstantiationData/instantiationToAdd)/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcorePublisher"
                            group-by="pb:publisher">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>

                        <!-- Create new copyright -->
                        <xsl:choose>
                            <xsl:when test="matches($newCopyright, '\w')">
                                <xsl:element name="pbcoreRightsSummary"
                                    namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                                    <xsl:element name="rightsSummary"
                                        namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                                        <xsl:copy-of select="$newCopyright"/>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:for-each-group
                                    select="
                                        ($destinationAssetXML | 
                                        $sourceInstantiationData/instantiationToAdd)/
                                        pb:pbcoreDescriptionDocument/
                                        pb:pbcoreRightsSummary"
                                    group-by="pb:rightsSummary">
                                    <xsl:copy-of select="."/>
                                </xsl:for-each-group>
                            </xsl:otherwise>
                        </xsl:choose>

                        <!-- Merge annotations -->
                        <xsl:for-each-group
                            select="
                                ($destinationAssetXML | 
                                $sourceInstantiationData/instantiationToAdd)/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreAnnotation"
                            group-by=".">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>
                        
                        

                        <!-- Do not allow new instantiation numbers 
                            that would overwrite 
                            destination asset instantiations -->
                        <xsl:variable name="dupInstIDs"
                            select="
                                $destinationAssetXML/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreInstantiation/
                                pb:instantiationIdentifier
                                [@source = 'WNYC Media Archive Label']
                                [. = $newInstantiationIDs]"/>

                        <xsl:for-each select="$dupInstIDs">
                            <error type="duplicateInstantiationID">
                                <xsl:value-of
                                    select="
                                        'ERROR: ', .,
                                        'would overwrite an instantiation in the destination asset'"
                                />
                            </error>
                        </xsl:for-each>

                        <!-- Copy instantiations, 
                            except the one it refers to 
                            (in case the ID is being changed) -->
                        <xsl:copy-of
                            select="
                                $destinationAssetXML/
                                pb:pbcoreDescriptionDocument/
                                pb:pbcoreInstantiation
                                [not(pb:instantiationIdentifier
                                [@source = 'WNYC Media Archive Label']
                                = $instIDsToDelete)]"/>

                        <!-- Add new instantiations -->
                        <xsl:apply-templates
                            select="
                                $sourceInstantiationData/instantiationToAdd"
                            mode="addInstantiation"/> 
                    </xsl:copy>
                    
                    <!-- Original assets minus removed instantiations -->                    
                    <xsl:variable name="updatedSourceAssets">
                        <xsl:for-each-group
                            select="
                                $sourceInstantiationData/instantiationToAdd[not(sourceAssetID = destinationAssetID)]"
                            group-by="sourceAssetID">
                            <xsl:apply-templates select="pb:pbcoreDescriptionDocument"
                                mode="deleteInstantiation">
                                <xsl:with-param name="instIDsToDelete" select="$instIDsToDelete"/>
                            </xsl:apply-templates>
                        </xsl:for-each-group>
                    </xsl:variable>
                    
                    <!-- Include source assets
                    with any instantiations left -->
                    <xsl:copy-of select="
                        $updatedSourceAssets/
                        pb:pbcoreDescriptionDocument
                        [pb:pbcoreInstantiation]"/>
                    
                    <!-- Mark empty assets for deletion -->
                    <xsl:apply-templates
                        select="
                            $updatedSourceAssets/
                            pb:pbcoreDescriptionDocument
                            [not(pb:pbcoreInstantiation)]"
                        mode="prepareToErase"/>
                </xsl:element>
                
            </xsl:for-each-group>
        </xsl:param>

        <xsl:result-document format="
            cavafy" href="
            {$filenameRestore}">
            <xsl:element name="pbcoreCollection"
                namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                <xsl:apply-templates select="
                        $mergeAssets/restoreDoc"
                    mode="
                importReady"/>
            </xsl:element>
        </xsl:result-document>

        <xsl:result-document href="{$filenameError}" format="log">
            <html>
                <head>
                    <xsl:value-of
                        select="
                            concat(
                            'Error log for ',
                            $docFilenameNoExtension,
                            ' on ',
                            format-date(
                            current-date(), '[Y0001][M01][D01]'),
                            ' at ', $currentTime)"
                    />
                </head>
                <body>
                    <p/>
                    <xsl:variable name="paragraphMark">
                        <p/>
                    </xsl:variable>

                    <xsl:for-each
                        select="
                            $mergeAssets/
                            *[local-name() = 'error']">
                        <div>
                            <p>
                                <br/>
                                <p>
                                    <xsl:value-of select="@type, ': '"/>
                                    <xsl:copy-of
                                        select="replace(WNYC:stripNonASCII(.), '&#xD;', $paragraphMark)"/>
                                    <br/>
                                </p>
                            </p>
                        </div>
                    </xsl:for-each>

                    <xsl:for-each
                        select="
                            $mergeAssets/mergeDoc/pb:pbcoreDescriptionDocument
                            [.//*[local-name() = 'error']]">

                        <!-- Link to the source file -->
                        <xsl:variable name="sourceURL"
                            select="
                                concat(
                                'https://cavafy.wnyc.org/assets/',
                                pb:pbcoreIdentifier
                                [@source = 'pbcore XML database UUID'])"/>
                        <xsl:variable name="destinationURL"
                            select="
                                concat(
                                'https://cavafy.wnyc.org/assets/',
                                pb:pbcoreIdentifier
                                [@source = 'pbcore XML database UUID'])"/>

                        <div>
                            <p>
                                <b> ERRORS when trying to merge instantiation(s) <xsl:value-of
                                        select="
                                            distinct-values(pb:pbcoreInstantiation/pb:instantiationIdentifier)
                                            [. = $instIDsToDelete]"
                                        separator=" and "/> INTO <a>
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="$destinationURL"/>
                                        </xsl:attribute> <xsl:value-of
                                            select="pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog']"
                                        />
                                    </a>
                                </b>
                                <br/>
                                <p>
                                    <xsl:variable name="paragraphMark">
                                        <p/>
                                    </xsl:variable>
                                    <xsl:for-each select=".//*[local-name() = 'error']">
                                        <xsl:value-of select="@type, ': '"/>
                                        <xsl:copy-of
                                            select="replace(WNYC:stripNonASCII(.), '&#xD;', $paragraphMark)"/>
                                        <br/>
                                    </xsl:for-each>
                                </p>
                            </p>
                        </div>
                    </xsl:for-each>
                </body>
            </html>
        </xsl:result-document>

        <xsl:if test="$mergeAssets/mergeDoc[//*[local-name()='error']]">
            <xsl:message terminate="yes">ERRORS FOUND WHEN MERGING</xsl:message>
        </xsl:if>

        <xsl:result-document format="
            cavafy" href="
            {$filenameMerged}">
            <xsl:variable name="completeMergeDoc">
                <xsl:element name="pbcoreCollection"
                    namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">

                    <xsl:apply-templates
                        select="
                            $mergeAssets/mergeDoc[not(//error)]"
                        mode="
                importReady"/>
                </xsl:element>
            </xsl:variable>
            <xsl:copy-of select="$completeMergeDoc"/>
            <xsl:apply-templates select="$completeMergeDoc" mode="
                breakItUp">
                <xsl:with-param name="baseURI" select="base-uri()"/>
                <xsl:with-param name="filename" select="substring-before($filenameMerged, '.xml')"/>
            </xsl:apply-templates>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="addInstantiation" match="
        instantiationToAdd" mode="addInstantiation">
        <xsl:param name="instantiationData" select="pb:instantiationData"/>
        <xsl:param name="newInstantiationID" select="newInstantiationID"/>
        <xsl:param name="sourceInstantiationID" select="sourceInstantiationID"/>
        <xsl:copy select="$instantiationData/pb:pbcoreInstantiation">
            <!-- Create new ID -->
            <xsl:element name="instantiationIdentifier"
                namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                <xsl:attribute name="source" select="
                    'WNYC Media Archive Label'"/>
                <xsl:value-of select="$newInstantiationID"/>
            </xsl:element>
            <!-- Add original identifier -->
            <xsl:element name="instantiationIdentifier"
                namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                <xsl:attribute name="source" select="'Former WNYC Media Archive Label'"/>
                <xsl:value-of select="$sourceInstantiationID"/>
            </xsl:element>
            <!-- Copy other instantiation IDs -->
            <xsl:copy-of
                select="
                    $instantiationData/pb:instantiationIdentifier
                    [not(@source = 'WNYC Media Archive Label')]
                    [not(@source = 'pbcore XML database UUID')]"/>
            <!-- Copy all other instantiation elements -->
            <xsl:copy-of
                select="$instantiationData/pb:pbcoreInstantiation/
                    *
                    [not(name() = 'instantiationIdentifier')]
                    "/>            
        </xsl:copy>
    </xsl:template>

    <xsl:template name="deleteInstantiation" match="
        pb:pbcoreDescriptionDocument"
        mode="deleteInstantiation">
        <xsl:param name="instIDsToDelete"/>
        <xsl:copy>
            <!-- copy asset-level elements
            except instantiaions-->
            <xsl:copy-of select="*[not(name() = 'pbcoreInstantiation')]"/>
            <xsl:copy-of
                select="
                    pb:pbcoreInstantiation
                    [not(pb:instantiationIdentifier
                    [@source = 'WNYC Media Archive Label']
                    = $instIDsToDelete)]"
            />
        </xsl:copy>
    </xsl:template>

    <xsl:template name="prepareToErase" match="
        pb:pbcoreDescriptionDocument"
        mode="
        prepareToErase">
        <xsl:copy>
            <xsl:copy-of select="
                pb:pbcoreIdentifier
                [@source = 'WNYC Archive Catalog']"/>
            <xsl:copy-of select="
                pb:pbcoreIdentifier
                [@source = 'pbcore XML database UUID']"/>
            <xsl:copy-of select="
                pb:pbcoreTitle
                [@titleType = 'Collection']"/>
            <xsl:element name="
                pb:pbcoreDescription">
                <xsl:attribute name="descriptionType" select="'Abstract'"/>
                <xsl:value-of select="
                    'PLEASE ERASE - NO INSTANTIATIONS LEFT'"/>
            </xsl:element>
            </xsl:copy>
    </xsl:template>
</xsl:stylesheet>