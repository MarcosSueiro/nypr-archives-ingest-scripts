<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" 
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:WNYC="http://www.wnyc.org"
    xmlns:File="http://ns.exiftool.ca/File/1.0/"
    version="2.0">
    
    <xsl:import href="cavafy2BWFMetaEdit.xsl"/>
    <xsl:import href="BWF2Exif.xsl"/>
    <xsl:import href="cavafySearch.xsl"/>
    <xsl:import href="errorLog.xsl"/>
    <xsl:import href="processCollection.xsl"/>
    
    <!--<xsl:template match="pb:pbcoreCollection">
        <xsl:apply-templates select="pb:pbcoreDescriptionDocument"/>
    </xsl:template> -->
    
<!--    <xsl:template match="pb:pbcoreDescriptionDocument">
        <xsl:apply-templates select="pb:pbcoreInstantiation" mode="
            generateSourceExif"/>
    </xsl:template>-->
    
    <xsl:template match="pb:pbcoreInstantiation" mode="
        generateSourceExif" name="generateSourceExif">

        <!-- Generate an rdf document
        from a current instantiation -->
        <xsl:param name="instantiationID"
            select="
                pb:instantiationIdentifier
                [@source = 'WNYC Media Archive Label']"/>

        <xsl:param name="message">
            <xsl:message
                select="
                    'Generate an rdf document',
                    'from current instantiation ', $instantiationID"
            />
        </xsl:param>
        <xsl:param name="instantiationIDParsed">
            <xsl:call-template name="parseInstantiationID">
                <xsl:with-param name="instantiationID" select="
                    $instantiationID"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="instantiationSuffixComplete">
            <xsl:value-of
                select="
                    $instantiationIDParsed/
                    instantiationIDParsed/
                    instantiationSuffixComplete"
            />
        </xsl:param>
        <xsl:param name="cavafyEntry">
            <xsl:message
                select="
                    'Parent document of ',
                    $instantiationID, ' is ',
                    parent::pb:pbcoreDescriptionDocument/
                    *[position() lt 6],
                    ', etc.'"/>
            <xsl:copy-of select="
                    parent::pb:pbcoreDescriptionDocument"/>
        </xsl:param>
        <xsl:param name="generatedFilename">
            <xsl:apply-templates
                select="
                    pb:instantiationIdentifier
                    [@source = 'WNYC Media Archive Label']"
                mode="generateNextFilename">
                <xsl:with-param name="foundAsset" select="$cavafyEntry"/>
                <xsl:with-param name="foundInstantiation" select="."/>
                <xsl:with-param name="instantiationIDOffset" select="0"/>
                <xsl:with-param name="nextInstantiationSuffixDigit"
                    select="$instantiationSuffixComplete"/>
                <!-- Just generating a source exif, 
                    so no future WAVE filenames needed -->
                <xsl:with-param name="isMultitrack" select="false()"/>
                <xsl:with-param name="instantiationFirstTrack" select="0"/>
                <!--                    <xsl:with-param name="freeTextComplete" select="''"/>-->
            </xsl:apply-templates>
        </xsl:param>
        <xsl:param name="format">
            <xsl:value-of
                select="
                    pb:instantiationDigital |
                    pb:instantiationPhysical"
            />
        </xsl:param>
        <xsl:param name="compactFormat" select="
                replace($format, '\W', '')"/>
        <xsl:param name="parsedDAVIDTitle" select="
            $generatedFilename/
            pb:inputs/
            pb:parsedDAVIDTitle"/>
        <xsl:param name="fullFilename">
            <xsl:value-of
                select="
                    normalize-space(
                    $parsedDAVIDTitle/
                    @DAVIDTitle)"/>
            <xsl:value-of select="'.'"/>
            <xsl:value-of select="$compactFormat"/>
        </xsl:param>

        <xsl:param name="location" select="
                pb:instantiationLocation"/>
        <xsl:param name="offsiteBox"
            select="
                pb:instantiationIdentifier[@source = 'WNYC Archive Offsite ID']"/>
        <xsl:param name="collectionAcronym"
            select="
                $cavafyEntry/pb:pbcoreDescriptionDocument/pb:pbcoreTitle
                [@titleType = 'Collection']"/>
        <xsl:param name="RIFF:ArchivalLocation"
            select="
                WNYC:generateIARL($collectionAcronym)"/>
        <xsl:param name="generation" select="
                pb:instantiationGenerations"/>
        <xsl:param name="isSegment" select="
            contains($generation, 'segment')"/>
        <xsl:param name="instantiationSegmentSuffix"
            select="
            $parsedDAVIDTitle
            //parsedElements/instantiationSegmentSuffix"/>
        <xsl:param name="segmentFlag"
            select="
            $parsedDAVIDTitle
            //parsedElements/segmentFlag"/>
        <xsl:param name="missing"
            select="
                contains($location, 'MISSING')
                or
                contains($location, 'NOT FOUND')"/>

        <xsl:param name="cavafySeriesTitle"
            select="
                $cavafyEntry/pb:pbcoreDescriptionDocument/
                pb:pbcoreTitle[@titleType = 'Series']"/>

        <xsl:param name="directory">
            <xsl:value-of select="$location, $offsiteBox" separator="\"/>
            <xsl:value-of select="'\'"/>
        </xsl:param>
        <xsl:param name="System:FileName"
            select="
                concat(
                $fullFilename,
                '.',
                $compactFormat)"/>
        <xsl:param name="System:FileSize" select="
                pb:instantiationFileSize"/>
        <xsl:param name="System:FileCreateDate"
            select="
                pb:instantiationDate
                [@dateType = 'Created'][1]"/>
        <xsl:param name="File:FileType" select="$format"/>
        <xsl:param name="File:FileTypeExtension" select="
                $compactFormat"/>
        <xsl:param name="RIFF:Encoding"
            select="
                pb:instantiationEssenceTrack/
                pb:essenceTrackStandard"/>

        <xsl:param name="foundInstantiation"
            select="
                $cavafyEntry/pb:pbcoreDescriptionDocument/
                pb:pbcoreInstantiation
                [pb:instantiationIdentifier = $instantiationID]"/>

        <xsl:param name="medium">
            <xsl:value-of
                select="
                    $foundInstantiation/pb:instantiationPhysical,
                    $foundInstantiation/pb:instantiationDigital,
                    $instantiationID"
                separator=" "/>
        </xsl:param>
        <xsl:param name="provenance"
            select="
                $foundInstantiation/
                pb:instantiationAnnotation[
                @annotationType = 'Provenance']"
        />
        <xsl:param name="instantiationCreatedDate" select="
            $foundInstantiation/pb:instantiationDate[@dateType='Created']"/>
        <xsl:param name="instantiationIssuedDate" select="
            $foundInstantiation/pb:instantiationDate[@dateType='Issued']"/>
        <xsl:param name="noTypeInstantiationDates">
            <xsl:value-of select="$foundInstantiation/pb:instantiationDate[not(@dateType)]" separator=" ; "/>
        </xsl:param>
        <xsl:param name="instantiationTitle" select="
            $foundInstantiation/pb:instantiationAnnotation
            [@annotationType='instantiation_title']"/>
        <xsl:param name="instantiationDescription" select="
            $foundInstantiation/pb:instantiationAnnotation
            [@annotationType='instantiation_description']"/>
        <xsl:param name="BWFCoreOutput">
            <conformance_point_document>
                <xsl:apply-templates
                    select="
                        parent::pb:pbcoreDescriptionDocument"
                    mode="
                    generateBWFME">
                    <xsl:with-param name="filename">
                        <xsl:value-of select="$fullFilename"/>
                    </xsl:with-param>
                    <xsl:with-param name="RIFF:Medium" select="$foundInstantiation/pb:pbcoreRelation
                        [pb:pbcoreRelationType = 'Is Dub Of']"
                    />
                    <xsl:with-param name="generation" select="$generation"/>
                    <xsl:with-param name="RIFF:SourceForm" select="$provenance"/>
                    <xsl:with-param name="RIFF:Title">
                        <xsl:call-template name="checkConflicts">
                            <xsl:with-param name="fieldName" select="'instantiationTitle'"/>
                            <xsl:with-param name="field1" select="
                                $foundInstantiation/
                                pb:instantiationAnnotation
                                [@annotationType='instantiation_title']"/>
                                <xsl:with-param name="defaultValue">
                                    <xsl:value-of select="$cavafyEntry/pb:pbcoreDescriptionDocument/
                                        pb:pbcoreTitle[@titleType = 'Episode']"/>
                                </xsl:with-param>
                            <xsl:with-param name="separatingToken" select="$separatingTokenForFreeTextFields"/>
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="RIFF:Subject">
                        <xsl:call-template name="checkConflicts">
                            <xsl:with-param name="fieldName" select="'instantiationDescription'"/>
                            <xsl:with-param name="field1" select="
                                $foundInstantiation/
                                pb:instantiationAnnotation
                                [@annotationType='instantiation_description']"/>
                            <xsl:with-param name="defaultValue">
                                <xsl:value-of select="$cavafyEntry/pb:pbcoreDescriptionDocument/
                                    pb:pbcoreDescription[@descriptionType = 'Abstract']"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:with-param>
                    <!-- Extra descriptors -->
                    <xsl:with-param name="location" select="$location"/>
                    <xsl:with-param name="physicalLabel" select="
                        pb:instantiationIdentifier
                        [@source='Physical label']"/>                    
                    <xsl:with-param name="mergeID" select="$instantiationID"/>
                </xsl:apply-templates>
            </conformance_point_document>
        </xsl:param>
        <xsl:message select="
                'Found cavafy entry',
                $cavafyEntry//pb:pbcoreTitle[@titleType='Episode']"/>
        <xsl:message
            select="
                'Found instantiation',
                $foundInstantiation"/>

        <!-- First the BWFME Core output -->
        <xsl:copy-of select="$BWFCoreOutput"/>

        <!-- Then, its exif version -->
        <xsl:apply-templates select="$BWFCoreOutput" mode="
            BWFMetaEdit">
            <xsl:with-param name="directory" select="
                $directory" tunnel="yes"/>
        </xsl:apply-templates>

    </xsl:template>
        
    
    
</xsl:stylesheet>