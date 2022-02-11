<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/" exclude-result-prefixes="xs" version="2.0">

    <xsl:import href="masterRouter.xsl"/>
    <xsl:import href="cavafy2Exif.xsl"/>

    <!-- Generate a manifest 
    based on a series name
    and a format -->

    <!-- 
Enter the series name under <seriesName>
and any further refinements under <searchString>.

For example, to generate the manifest 
for the series 'Central Park Summerstage' DBX tapes
and
reels without a cassette instantiation
from 'Memoirs of the Movies',
enter:

<seriesList>
    <series>
        <seriesName>Central Park SummerStage</seriesName>
        <format>DBX 700 VHS tape</format>
        <searchString></searchString>
    </series>
    <series>
        <seriesName>Memoirs of the Movies</seriesName>
        <format>1/4 inch audio tape</format>
        <searchString>https://cavafy.wnyc.org/?facet_Series+Title%5B%5D=Memoirs+of+the+Movies&amp;q=%22memoirs+of+the+movies%22+-cassette</searchString>
    </series>
</seriesList>

-->

    <xsl:template match="seriesList">
        <xsl:apply-templates select="
                series" mode="
            generateManifest"/>
    </xsl:template>
    
    

    <xsl:template name="generateManifest" match="series" mode="generateManifest">
        <!-- Generate an instantiation-level manifest 
        from a series name and a format -->
        <xsl:param name="seriesName">
            <xsl:value-of select="seriesName"/>
        </xsl:param>
        <xsl:param name="format">
            <xsl:value-of select="format"/>
            <xsl:message
                select="
                    'Generate an instantiation-level manifest',
                    'for series ', $seriesName, ' and format ', format"
            />
        </xsl:param>
        <xsl:param name="textToSearch">
            <xsl:value-of
                select="
                    encode-for-uri(
                    string-join(
                    ($seriesName, $format[. != '']),
                    ' '))"
            />
        </xsl:param>
        <xsl:param name="generatedSearchString">
            <xsl:call-template name="generateSearchString">
                <xsl:with-param name="textToSearch" select="$textToSearch"/>
                <xsl:with-param name="field1ToSearch" select="'title'"/>
                <xsl:with-param name="field2ToSearch" select="'format'"/>
                <xsl:with-param name="series" select="$seriesName"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="searchString"
            select="
                if (
                contains(searchString, 'cavafy')
                )
                then
                    searchString
                else
                    $generatedSearchString"/>
        <xsl:param name="cavafyXMLs">
            <xsl:call-template name="findCavafyXMLs">
                <xsl:with-param name="searchString" select="
                        $searchString"/>
                <xsl:with-param name="maxResults" select="3000"/>
            </xsl:call-template>
        </xsl:param>

        <xsl:param name="filenameAddendum" select="
                concat('_search', position())"/>
        <xsl:param name="compactSeries" select="
                replace($seriesName, '\W', '')"/>
        <xsl:param name="compactFormat" select="
                replace($format, '\W', '')"/>

        <!-- This is the list of all the instantiation IDs -->
        <xsl:param name="instantiationIDs">
            <xsl:message
                select="
                    'Generate a list ',
                    'of instantiation IDs'"/>
            <xsl:element name="instantiationIDs">
                <xsl:attribute name="series" select="
                        $seriesName"/>
                <xsl:attribute name="searchString" select="
                        $searchString"/>
                <xsl:apply-templates
                    select="
                        $cavafyXMLs/pb:pbcoreCollection/
                        pb:pbcoreDescriptionDocument"
                    mode="generateManifest">
                    <xsl:with-param name="format" select="
                            $format"/>
                </xsl:apply-templates>
            </xsl:element>
        </xsl:param>

        <!-- The same list, sorted -->
        <xsl:param name="instantiationIDsSorted">
            <xsl:apply-templates select="
                    $instantiationIDs/instantiationIDs"
                mode="sortInstantiationIDs"/>
        </xsl:param>

        <xsl:param name="filenameInstantiationIDs">
            <xsl:value-of
                select="
                    concat($baseFolder,
                    'InstIDs',
                    $compactSeries, $compactFormat,
                    $masterDocFilenameNoExtension,
                    $currentDate,
                    $filenameAddendum)"/>
            <xsl:value-of select="'.xml'"/>
        </xsl:param>
        
        <xsl:param name="sourceData">
            <xsl:apply-templates
                select="
                $cavafyXMLs/
                pb:pbcoreCollection/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreInstantiation
                [pb:instantiationPhysical = $format]"
                mode="
                generateSourceExif"/> 
        </xsl:param>

        <!-- This is the document
            with all the instantiation IDs 
            (and some other info 
        as attributes) -->
        <xsl:result-document href="{$filenameInstantiationIDs}">
            <xsl:copy-of select="$instantiationIDsSorted"/>
        </xsl:result-document>

        <!-- This is an exif-like rdf document 
        with info about the source instantiations -->

        <xsl:variable name="filenameSourceExif">
            <xsl:value-of
                select="
                    concat($baseFolder,
                    'sourceExif',
                    $compactSeries, $compactFormat,
                    $masterDocFilenameNoExtension,
                    $currentDate,
                    $filenameAddendum)"/>
            <xsl:value-of select="'.xml'"/>
        </xsl:variable>



        <xsl:result-document href="{$filenameSourceExif}">
            <xsl:copy select="$sourceData/rdf:RDF[1]">
                <xsl:copy-of select="$sourceData/rdf:RDF/rdf:Description"/>
            </xsl:copy>
        </xsl:result-document>

        <!-- Now we generate a 'fake' exif-like rdf document
            of future WAVE files
            from the instantiation IDs data -->
        <!--<xsl:variable name="nextFilenames">
            <nextFilenames>
                <xsl:apply-templates
                    select="
                        $instantiationIDsSorted//instantiationID"
                    mode="
            generateNextFilename"/>
            </nextFilenames>
        </xsl:variable>-->
        
        <xsl:apply-templates select="
                $instantiationIDsSorted/instantiationIDs"
            mode="
            generateExif">
            <xsl:with-param name="
                stopIfError" select="true()" tunnel="yes"/>
            <xsl:with-param name="filenameAddendum" tunnel="yes"
                select="
                    $filenameAddendum"/>
        </xsl:apply-templates>
    </xsl:template>


    <xsl:template match="
            pb:pbcoreDescriptionDocument" mode="
        generateManifest">
        <xsl:param name="format"/>

        <!-- Output:
            A list of instantiation IDs
            from instantiations matching the format
            (with some additional info as attributes) -->
        <xsl:for-each
            select="
                pb:pbcoreInstantiation
                [pb:instantiationPhysical = $format]">
            <xsl:apply-templates select="
                    parent::pb:pbcoreDescriptionDocument">
                <xsl:with-param name="filename">
                    <xsl:value-of
                        select="
                            pb:instantiationIdentifier
                            [@source = 'WNYC Media Archive Label']"
                    />
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:variable name="cavafyID"
                select="
                    pb:instantiationIdentifier
                    [@source = 'WNYC Media Archive Label']"/>
            
            <xsl:element name="instantiationID">
                <xsl:attribute name="format" select="$format"/>
                <xsl:attribute name="location">
                    <xsl:value-of select="
                            pb:instantiationLocation"/>
                    <xsl:value-of
                        select="
                            pb:instantiationIdentifier
                            [@source = 'WNYC Media Archive Shipping ID'][1]/concat(' ', .)"
                    />
                </xsl:attribute>
                <xsl:attribute name="physicalLabel">
                    <xsl:value-of
                        select="
                            pb:instantiationIdentifier
                            [(@source = 'Physical label')]
                            "
                        separator=" ; "/>
                </xsl:attribute>
                <xsl:attribute name="otherIDs">
                    <xsl:value-of
                        select="
                            pb:instantiationIdentifier
                            [not(@source = 'WNYC Media Archive Shipping ID')]
                            [not(@source = 'WNYC Media Archive Label')]
                            [not(@source = 'pbcore XML database UUID')]
                            [not(@source = 'Physical label')]
                            "
                        separator=" ; "/>
                </xsl:attribute>
                <xsl:attribute name="generation">
                    <xsl:value-of select="pb:instantiationGenerations"/>
                </xsl:attribute>
                <xsl:attribute name="newCavafyID" select="$cavafyID"/>
                <xsl:attribute name="instantiationCreatedDate" select="
                    pb:instantiationDate[@dateType='Created']"/>
                <xsl:attribute name="instantiationIssuedDate" select="
                    pb:instantiationDate[@dateType='Issued']"/>
                <xsl:attribute name="noTypeInstantiationDates">
                    <xsl:value-of select="pb:instantiationDate[not(@dateType)]" separator=" ; "/>
                </xsl:attribute>
                <xsl:attribute name="instantiationTitle" select="
                    pb:instantiationAnnotation
                    [@annotationType='instantiation_title']"/>
                <xsl:attribute name="instantiationDescription" select="
                    pb:instantiationAnnotation
                    [@annotationType='instantiation_description']"/>
                <xsl:value-of select="$cavafyID"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <!-- If you already have
        a list of instantiations -->
    <xsl:template match="instantiationIDs">
        <xsl:apply-templates select="."
            mode="
            generateExif">
            <xsl:with-param name="
                stopIfError" select="true()" tunnel="yes"/>
            <xsl:with-param name="filenameAddendum" tunnel="yes"
                select="
                '_fromInstIDs_'"/>
        </xsl:apply-templates>
    </xsl:template>

</xsl:stylesheet>