<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:import href="file:/T:/02%20CATALOGING/Instantiation%20uploads/nypr-archives-ingest-scripts/currentTemplates/masterRouter.xsl"/>
    
    
    <xsl:template match="seriesList">
        <xsl:apply-templates select="
            series" mode="
            generateManifest"/>
    </xsl:template>
        
    <xsl:template match="series" mode="generateManifest">
        <!-- Generate an instantiation-level manifest -->
        <xsl:param name="seriesName" select="seriesName"/>
        <xsl:param name="format" select="format"/>        
        <xsl:param name="textToSearch">
            <xsl:value-of select="
                encode-for-uri(
                string-join(
                ($seriesName, $format[. != '']),
                ' '))"/>
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
                    $generatedSearchString"
        />
        <xsl:param name="cavafyXMLs">
            <xsl:call-template name="findCavafyXMLs">
                <xsl:with-param name="searchString"
                    select="$searchString"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:variable name="compactSeries" select="
            replace($seriesName, '\W', '')"/>
        <xsl:variable name="compactFormat" select="
            replace($format, '\W', '')"/>
        <xsl:variable name="instantiationIDs">
            <xsl:element name="instantiationIDs">
                <xsl:attribute name="series" select="$seriesName"/>
                <xsl:attribute name="searchString" select="$searchString"/>
                <xsl:apply-templates
                    select="
                        $cavafyXMLs/pb:pbcoreCollection/
                        pb:pbcoreDescriptionDocument"
                    mode="generateManifest">
                    <xsl:with-param name="format" select="
                            $format"/>
                </xsl:apply-templates>
            </xsl:element>
        </xsl:variable>
        <xsl:variable name="instantiationIDsSorted">
            <xsl:apply-templates select="
                    $instantiationIDs/instantiationIDs"
                mode="sortInstantiationIDs"/>
        </xsl:variable>
        
        <xsl:variable name="filenameInstantiationIDs">
            <xsl:value-of select="
                concat($baseFolder,
                'InstIDs',
                $compactSeries, $compactFormat,
                $masterDocFilenameNoExtension,
                $currentDate)"/>
            <xsl:if test="contains($searchString, 'cavafy')">
                <xsl:value-of select="
                        concat('_search', position())"/>
            </xsl:if>
            <xsl:value-of select="'.xml'"/>
        </xsl:variable>
            
        <xsl:result-document href="{$filenameInstantiationIDs}">
            <xsl:copy-of select="$instantiationIDsSorted"/>
        </xsl:result-document>
        <xsl:apply-templates select="
                $instantiationIDsSorted/instantiationIDs"
            mode="
            generateExif">
            <xsl:with-param name="
                stopIfError" select="false()" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    
    <xsl:template match="
            pb:pbcoreDescriptionDocument" mode="
        generateManifest">
        <xsl:param name="format"/>
        <xsl:for-each
            select="
                pb:pbcoreInstantiation
                [pb:instantiationPhysical = $format]">

            <xsl:element name="instantiationID">
                <xsl:attribute name="format" select="$format"/>
                <xsl:attribute name="location">
                    <xsl:value-of select="
                        pb:instantiationLocation"/>
                    <xsl:value-of select="
                        pb:instantiationIdentifier
                        [@source='WNYC Media Archive Shipping ID'][1]/concat(' ', .)"/>
                </xsl:attribute>
                <xsl:attribute name="otherIDs">
                    <xsl:value-of select="pb:instantiationIdentifier
                        [not(@source='WNYC Media Archive Shipping ID')]
                        [not(@source = 'WNYC Media Archive Label')]
                        [not(@source = 'pbcore XML database UUID')]
                        " separator=" ; "/>
                </xsl:attribute>
                <xsl:value-of
                    select="
                        pb:instantiationIdentifier
                        [@source = 'WNYC Media Archive Label']"/>                
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>