<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:et="http://ns.exiftool.ca/1.0/"
    et:toolkit="Image::ExifTool 11.69" xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" exclude-result-prefixes="#all"
    version="2.0">
    <!-- Generate an Exif document and html 
        from a list of cavafy pbcoreInstantiation IDs. 
        Source document must have the format
        <instantiationIDs>
          <instantiationID>12345.3</instantiationID>
          <instantiationID>56789.4</instantiationID>
        </instantiationIDs>
        
        Error Checking:
        
        The script can perform a couple of cross-checks 
        to minimize mistyping of instantiation IDs.
        
        (1) If all the instantiation IDs 
        come from one series,
        you can add its name as an attribute @series 
        to the top element instantiationIDs:
        
        <instantiationIDs series="Around New York">
                
        (2) If you know it, 
        you may include a @format attribute 
        at the instantiationID level: 
        <instantiationID format="1/4 inch audio tape">19719.1</instantiationID>
        
    -->

    <xsl:param name="vendorName"/>
    <!-- Generic filepath for future files -->
    <xsl:param name="System:Directory" select="concat('W:/ARCHIVESNAS1/INGEST/', $vendorName)"/>
    <!-- Type of future files -->
    <xsl:param name="File:FileType" select="'WAV'"/>



    <xsl:template match="instantiationIDs">
        <xsl:param name="instantiationIDs" select="."/>
        <xsl:param name="instantiationIDsSorted">
            <xsl:apply-templates select="$instantiationIDs" mode="
                sortInstantiationIDs"/>
        </xsl:param>
        <xsl:apply-templates select="
                $instantiationIDsSorted" mode="generateExif"/>
    </xsl:template>

    <xsl:template match="instantiationIDs" mode="sortInstantiationIDs">
        <!-- Sort instantiation IDs by asset and then
        by the number part of the instantiation Extension -->
        <xsl:param name="instantiationIDs" select="."/>
        <xsl:param name="instantiationIDsParsed">
            <xsl:apply-templates select="
                    $instantiationIDs/
                    instantiationID" mode="
                parseInstantiationID"/>
        </xsl:param>
        <xsl:param name="instantiationIDsSorted">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:for-each select="$instantiationIDsParsed//instantiationIDParsed">
                    <!-- Sort by asset ID -->
                    <xsl:sort select="number(assetID)"/>
                    <!-- Sort by instantiation suffix -->
                    <xsl:sort select="number(instantiationSuffixDigit)"/>
                    <!-- Sort by first track in multitrack -->
                    <xsl:sort select="instantiationFirstTrack"/>
                    <xsl:copy-of select="instantiationID"/>
                </xsl:for-each>
            </xsl:copy>
        </xsl:param>
        <xsl:message>
            <xsl:value-of select="'Sorted instantiaiton IDs from '"/>
            <xsl:value-of select="$instantiationIDsParsed//instantiationIDParsed/instantiationID"
                separator=", "/>
            <xsl:value-of select="' ...to... '"/>
            <xsl:value-of select="$instantiationIDsSorted//instantiationID" separator=", "/>
        </xsl:message>
        <xsl:copy-of select="$instantiationIDsSorted"/>
    </xsl:template>

    <xsl:template match="instantiationIDs" mode="generateExif">
        <xsl:param name="instantiationIDs" select="."/>
        <xsl:param name="location" select="
                $instantiationIDs/@location[matches(., '\w')]"/>
        <xsl:param name="filenameAddendum" select="$location" tunnel="yes"/>
        <xsl:param name="generateOutputDocs" select="true()"/>
        <xsl:message select="
                'Generate a fake Exif document from',
                count($instantiationIDs/instantiationID), 'instantiationIDs.'"/>
        <xsl:variable name="fakeExif">
            <xsl:element name="rdf:RDF">
                <xsl:namespace name="rdf" select="
                        'http://www.w3.org/1999/02/22-rdf-syntax-ns#'"/>
                <xsl:apply-templates select="
                        $instantiationIDs/instantiationID" mode="generateExif"/>
            </xsl:element>
        </xsl:variable>
        <xsl:copy-of select="$fakeExif[not($generateOutputDocs)]"/>
        <xsl:apply-templates select="$fakeExif/rdf:RDF[$generateOutputDocs]">
            <xsl:with-param name="filenameAddendum" select="$filenameAddendum" tunnel="yes"/>

            <xsl:with-param name="outputEmail" select="true()"/>
            <xsl:with-param name="outputFADGI" select="false()"/>
            <xsl:with-param name="outputCavafy" select="false()"/>
            <xsl:with-param name="outputDAVID" select="false()"/>
            <xsl:with-param name="outputSlack" select="false()"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="instantiationID" mode="
        generateExif">
        <xsl:param name="instantiationID" select="."/>
        <xsl:param name="generatedNextFilename">
            <xsl:apply-templates select="
                    $instantiationID[matches(., '[0-9]{4,6}\.[0-9]')]" mode="
                generateNextFilename"/>
        </xsl:param>
        <xsl:param name="reportedSourceFormat">
            <xsl:value-of select="$instantiationID/@format"/>
        </xsl:param>
        <xsl:param name="reportedLocation">
            <xsl:value-of select="$instantiationID/@location"/>
        </xsl:param>
        <xsl:param name="reportedGeneration">
            <xsl:value-of select="$instantiationID/@generation"/>
        </xsl:param>
        <xsl:param name="cavafyEntry" select="
                $generatedNextFilename/pb:inputs/
                pb:cavafyEntry/pb:pbcoreDescriptionDocument"/>
        <xsl:apply-templates select="
                $generatedNextFilename/pb:inputs" mode="generateFakeExif">
            <xsl:with-param name="reportedSourceFormat" select="
                    $reportedSourceFormat"/>
            <xsl:with-param name="instantiationID" select="
                    $instantiationID"/>
            <xsl:with-param name="cavafyEntry" select="
                    $cavafyEntry"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="pb:inputs" mode="generateFakeExif">
        <xsl:param name="instantiationID"/>
        <xsl:param name="cavafyEntry"/>
        <xsl:param name="parsedDAVIDTitle" select="
                pb:parsedDAVIDTitle"/>
        <xsl:param name="sourceInstantiation" select="
                $parsedDAVIDTitle/pb:parsedElements/
                pb:instantiationData/pb:pbcoreInstantiation"/>
        <xsl:param name="cavafySourceFormat" select="
                $sourceInstantiation/
                (pb:instantiationDigital |
                pb:instantiationPhysical)"/>
        <xsl:param name="cavafyLocation" select="
                $sourceInstantiation/
                pb:instantiationLocation
                "/>
        <xsl:param name="reportedSourceFormat"/>
        <xsl:param name="missing" select="
                contains($cavafyLocation, 'MISSING')
                or
                contains($cavafyLocation, 'NOT FOUND')"/>
        <xsl:param name="sourceFormat">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="field1" select="$reportedSourceFormat"/>
                <xsl:with-param name="field2" select="$cavafySourceFormat"/>
                <xsl:with-param name="fieldName" select="'reportedFormat'"/>
                <xsl:with-param name="filename" select="$instantiationID"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="expectedSeries" select="
                parent::instantiationIDs/@series"/>
        <xsl:param name="cavafySeriesTitle" select="
                $cavafyEntry/
                pb:pbcoreTitle[@titleType = 'Series']"/>
        <xsl:param name="System:Directory" select="$System:Directory"/>
        <xsl:param name="System:FileSize" select="'0 MB'"/>
        <xsl:param name="System:FileCreateDate" select="
                format-dateTime(
                current-dateTime(),
                '[Y0001]-[M01]-[D01] [H01]:[m01]:[s01][Z]'
                )"/>
        <xsl:param name="File:FileType" select="$File:FileType"/>
        <xsl:param name="File:FileTypeExtension" select="$File:FileType"/>

        <xsl:param name="RIFF:Encoding" select="'Microsoft PCM'"/>
        <xsl:param name="RIFF:NumChannels" select="'0'"/>
        <xsl:param name="RIFF:SampleRate" select="'1000'"/>
        <xsl:param name="RIFF:AvgBytesPerSec" select="'2000'"/>
        <xsl:param name="RIFF:BitsPerSample" select="'8'"/>

        <xsl:param name="RIFF:Medium">
            <xsl:copy-of select="$sourceFormat[//error]"/>
            <xsl:value-of select="concat($sourceFormat[not(//error)], ' ', $instantiationID)"/>
        </xsl:param>
        <xsl:param name="RIFF:Product">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="field1" select="$expectedSeries"/>
                <xsl:with-param name="field2" select="$cavafySeriesTitle"/>
                <xsl:with-param name="fieldName" select="'expectedSeries'"/>
                <xsl:with-param name="filename" select="$instantiationID"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="RIFF:Title">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="'RIFFTitle'"/>
                <xsl:with-param name="field1" select="
                        $sourceInstantiation/
                        pb:instantiationAnnotation
                        [@annotationType = 'instantiation_title']"/>
                <xsl:with-param name="defaultValue">
                    <xsl:value-of select="
                            $cavafyEntry/
                            pb:pbcoreTitle[@titleType = 'Episode']"/>
                </xsl:with-param>
                <xsl:with-param name="separatingToken" select="$separatingTokenForFreeTextFields"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="RIFF:Subject">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="
                    'instantiationDescription'"/>
                <xsl:with-param name="field1" select="
                        $sourceInstantiation/
                        pb:instantiationAnnotation
                        [@annotationType = 'instantiation_description']"/>
                <xsl:with-param name="defaultValue">
                    <xsl:value-of select="
                            $cavafyEntry/pb:pbcoreDescriptionDocument/
                            pb:pbcoreDescription[@descriptionType = 'Abstract']"
                    />
                </xsl:with-param>
                <xsl:with-param name="separatingToken" select="$separatingTokenForFreeTextFields"/>
            </xsl:call-template>
        </xsl:param>

        <!-- Generate fake exif -->
        <xsl:for-each select="
                $parsedDAVIDTitle/@DAVIDTitle[not($missing)]">
            <xsl:variable name="DAVIDTitle" select="."/>
            <xsl:variable name="System:FileName" select="
                    concat(
                    $DAVIDTitle, '.', $File:FileTypeExtension)"/>

            <!-- Output exif -->
            <xsl:element name="rdf:Description">
                <xsl:attribute name="rdf:about" select="
                        concat(
                        $System:Directory, '/', $System:FileName)"/>
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
                <xsl:comment>
                ************************************************
                A NON-EXISTENT FILE FOR PROCESSING PURPOSES ONLY
                ************************************************
            </xsl:comment>
                <ExifTool:ExifToolVersion> ****************0.0 (FAKE VERSION)****************** </ExifTool:ExifToolVersion>
                <System:FileName>
                    <xsl:value-of select="$System:FileName"/>
                </System:FileName>
                <System:Directory>
                    <xsl:value-of select="$System:Directory"/>
                </System:Directory>
                <System:FileSize>
                    <xsl:value-of select="$System:FileSize"/>
                </System:FileSize>
                <xsl:comment>Date of metadata creation, actually</xsl:comment>
                <System:FileCreateDate>
                    <xsl:value-of select="$System:FileCreateDate"/>
                </System:FileCreateDate>
                <System:FilePermissions>rw-rw-rw-</System:FilePermissions>
                <File:FileType>
                    <xsl:value-of select="$File:FileType"/>
                </File:FileType>
                <File:FileTypeExtension>
                    <xsl:value-of select="$File:FileTypeExtension"/>
                </File:FileTypeExtension>
                <File:MIMEType>audio/x-wav</File:MIMEType>
                <RIFF:Encoding>
                    <xsl:value-of select="$RIFF:Encoding"/>
                </RIFF:Encoding>
                <RIFF:NumChannels>
                    <xsl:value-of select="$RIFF:NumChannels"/>
                </RIFF:NumChannels>
                <RIFF:SampleRate>
                    <xsl:value-of select="$RIFF:SampleRate"/>
                </RIFF:SampleRate>
                <RIFF:AvgBytesPerSec>
                    <xsl:value-of select="$RIFF:AvgBytesPerSec"/>
                </RIFF:AvgBytesPerSec>
                <RIFF:BitsPerSample>
                    <xsl:value-of select="$RIFF:BitsPerSample"/>
                </RIFF:BitsPerSample>
                <RIFF:Description>
                    <xsl:value-of select="$DAVIDTitle"/>
                </RIFF:Description>
                <RIFF:Originator>
                    <xsl:value-of select="$vendorName"/>
                </RIFF:Originator>
                <RIFF:Medium>
                    <xsl:copy-of select="$RIFF:Medium"/>
                </RIFF:Medium>
                <RIFF:Product>
                    <xsl:copy-of select="$RIFF:Product"/>
                </RIFF:Product>
                <RIFF:Title>
                    <xsl:copy-of select="$RIFF:Title"/>
                </RIFF:Title>
                <RIFF:Subject>
                    <xsl:copy-of select="$RIFF:Subject"/>
                </RIFF:Subject>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>


</xsl:stylesheet>