<?xml version="1.0" encoding="UTF-8"?>
<!-- Perform QC on cavafy pbcore entries -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" version="2.0">

    <xsl:import href="cavafySearch.xsl"/>
    <xsl:import href="processCollection.xsl"/>

    <xsl:output method="xml" version="1.0" indent="yes"/>
    <xsl:mode on-no-match="deep-skip"/>

    <xsl:template match="pb:pbcoreCollection">
        <!-- Match top-level element -->
        <xsl:copy select=".">
            <xsl:apply-templates select="
                pb:pbcoreDescriptionDocument" mode="cavafyQC"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="pb:pbcoreDescriptionDocument" mode="cavafyQC">
        <!-- Test whether the cavafy entry has any errors, with the following defaults: -->

        <!-- ASSET LEVEL: -->
        <!--    Exactly one asset ID with @source = 'WNYC Archive Catalog' -->
        <!--    At least one asset date -->
        <!--    Exactly one collection, Series and Episode titles -->
        <!--    Exactly one genre -->
        <!--    Exactly one abstract with decent length and content -->
        <!--    At most one CMS Image -->
        <!--    Exactly one Copyright notice -->

        <!-- INSTANTIATION LEVEL:-->
        <!--    Exactly one instantiation ID with @source = 'WNYC Archive Catalog' -->
        <!--    Exactly one Format, Format Location, Media Type and Generation -->
        <!--    At most one essence track -->
        
        <xsl:param name="minAssetIDCount" select="1"/>
        <xsl:param name="maxAssetIDCount" select="1"/>
        <xsl:param name="minAssetDateCount" select="1"/>
        <xsl:param name="maxAssetDateCount" select="100"/>
        <xsl:param name="minCollectionCount" select="1"/>
        <xsl:param name="maxCollectionCount" select="1"/>
        <xsl:param name="minSeriesCount" select="1"/>
        <xsl:param name="maxSeriesCount" select="1"/>
        <xsl:param name="minEpisodeCount" select="1"/>
        <xsl:param name="maxEpisodeCount" select="1"/>
        <xsl:param name="minGenreCount" select="1"/>
        <xsl:param name="maxGenreCount" select="1"/>
        <xsl:param name="minAbstractCount" select="1"/>
        <xsl:param name="maxAbstractCount" select="1"/>
        <xsl:param name="minCopyrightCount" select="1"/>
        <xsl:param name="maxCopyrightCount" select="1"/>
        <xsl:param name="cavafyURL"
            select="
                concat(
                'https://cavafy.wnyc.org/assets/',
                pb:pbcoreIdentifier
                [@source = 'pbcore XML database UUID'][1]
                )"/>
        <xsl:param name="cavafyxml" select="concat($cavafyURL, '.xml')"/>

        <xsl:message
            select="
                'Test whether the cavafy entry ',
                $cavafyURL,
                ' has any errors'
                "/>

        <xsl:variable name="cavafyErrors">
            <xsl:variable name="assetIDCount"
                select="
                    count(
                    pb:pbcoreIdentifier
                    [@source = 'WNYC Archive Catalog']
                    )"/>
            <xsl:if
                test="
                    $assetIDCount lt $minAssetIDCount
                    or
                    $assetIDCount gt $maxAssetIDCount">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'asset_ID_count'"/>
                    <xsl:value-of
                        select="
                            concat(
                            'ATTENTION: ',
                            $assetIDCount,
                            ' cavafy asset numbers in ',
                            $cavafyxml,
                            '(range allowed:', $minAssetIDCount, '-', $maxAssetIDCount, ')',
                            ': ')"/>
                    <xsl:copy-of select="pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog']"/>
                </xsl:element>
            </xsl:if>
            <xsl:variable name="assetDateCount"
                select="
                    count(
                    pb:pbcoreAssetDate
                    )"/>
            <xsl:if
                test="
                    $assetDateCount lt $minAssetDateCount
                    or
                    $assetDateCount gt $maxAssetDateCount">
                <xsl:message>
                    <xsl:value-of
                        select="
                            concat(
                            'ATTENTION: ',
                            $assetDateCount, ' Asset Dates in ',
                            $cavafyxml,
                            '(range allowed:', $minAssetDateCount, '-', $maxAssetDateCount, ')',
                            ': '
                            )"/>
                    <xsl:copy-of select="pb:pbcoreAssetDate"/>
                </xsl:message>
            </xsl:if>
            <xsl:variable name="collectionCount"
                select="
                    count(
                    pb:pbcoreTitle[@titleType = 'Collection']
                    )"/>
            <xsl:if
                test="
                    $collectionCount lt $minCollectionCount
                    or
                    $collectionCount gt $maxCollectionCount">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'collection_title_count'"/>
                    <xsl:value-of
                        select="
                            concat(
                            'ATTENTION: ',
                            $collectionCount,
                            ' Collection titles in ',
                            $cavafyxml,
                            '(range allowed:', $minCollectionCount, '-', $maxCollectionCount, ')',
                            ': '
                            )"/>
                    <xsl:copy-of select="pb:pbcoreTitle[@titleType = 'Collection']"/>
                </xsl:element>
            </xsl:if>
            <xsl:variable name="seriesCount"
                select="
                    count(
                    pb:pbcoreTitle[@titleType = 'Series']
                    )"/>
            <xsl:if
                test="
                    $seriesCount lt $minSeriesCount
                    or
                    $seriesCount gt $maxSeriesCount">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'series_title_count'"/>
                    <xsl:value-of
                        select="
                            concat(
                            'ATTENTION: ',
                            $seriesCount,
                            ' Series titles in ',
                            $cavafyxml,
                            '(range allowed:', $minSeriesCount, '-', $maxSeriesCount, ')',
                            ': '
                            )"/>
                    <xsl:copy-of select="pb:pbcoreTitle[@titleType = 'Series']"/>
                </xsl:element>
            </xsl:if>
            <xsl:variable name="episodeCount"
                select="
                    count(
                    pb:pbcoreTitle[@titleType = 'Episode']
                    )"/>
            <xsl:if
                test="
                    $episodeCount lt $minEpisodeCount
                    or
                    $episodeCount gt $maxEpisodeCount">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'episode_title_count'"/>
                    <xsl:value-of
                        select="
                            concat(
                            'ATTENTION: ',
                            $episodeCount,
                            ' episode titles in ',
                            $cavafyxml,
                            '(range allowed:', $minEpisodeCount, '-', $maxEpisodeCount, ')',
                            ': '
                            )"/>
                    <xsl:copy-of select="pb:pbcoreTitle[@titleType = 'Episode']"/>
                </xsl:element>
            </xsl:if>
            <xsl:variable name="genreCount" select="count(pb:pbcoreGenre)"/>
            <xsl:if
                test="
                    $genreCount lt $minGenreCount
                    or
                    $genreCount gt $maxGenreCount">
                <xsl:message>
                    <xsl:value-of
                        select="
                            concat(
                            'ATTENTION: ',
                            $genreCount, ' genres in ',
                            $cavafyxml,
                            '(range allowed:', $minGenreCount, '-', $maxGenreCount, ')',
                            ': '
                            )"/>
                    <xsl:copy-of select="pb:pbcoreGenre"/>
                </xsl:message>
            </xsl:if>
            <xsl:variable name="abstractCount"
                select="
                    count(pb:pbcoreDescription
                    [@descriptionType = 'Abstract'])"/>
            <xsl:if test="$abstractCount gt 1">
                <xsl:message terminate="no"
                    select="
                        'ATTENTION: Multiple abstracts in ',
                        $cavafyxml"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'abstract_count'"/>
                    <xsl:value-of
                        select="
                            'ATTENTION: Multiple abstracts in ',
                            $cavafyxml, ': '"/>
                    <xsl:value-of
                        select="
                            pb:pbcoreDescription[@descriptionType = 'Abstract']"
                        separator="*************************************************************************************"
                    />
                </xsl:element>
            </xsl:if>
            <xsl:if
                test="pb:pbcoreDescription[@descriptionType = 'Abstract'][contains(., 'No description available')]">
                <xsl:message terminate="no" select="'ATTENTION: Useless abstract in ', $cavafyxml"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'useless_abstract'"/>
                    <xsl:value-of select="'ATTENTION: Useless abstract in ', $cavafyxml, ': '"/>
                    <xsl:copy-of select="pb:pbcoreDescription[@descriptionType = 'Abstract']"/>
                </xsl:element>
            </xsl:if>
            <xsl:if
                test="pb:pbcoreDescription[@descriptionType = 'Abstract'][string-length(.) lt 20]">
                <xsl:message terminate="no"
                    select="'ATTENTION: Very short abstract in ', $cavafyxml"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'short_abstract'"/>
                    <xsl:value-of select="'ATTENTION: Very short abstract in ', $cavafyxml, ': '"/>
                    <xsl:copy-of select="pb:pbcoreDescription[@descriptionType = 'Abstract']"/>
                </xsl:element>
            </xsl:if>
            <xsl:variable name="cmsImageIDCount"
                select="
                    count(
                    pb:pbcoreAnnotation
                    [@annotationType = 'CMS Image']
                    )"/>
            <xsl:if test="$cmsImageIDCount gt 1">
                <xsl:message terminate="no"
                    select="
                        'ATTENTION: ',
                        $cmsImageIDCount,
                        ' in ', $cavafyxml"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'multiple_CMS_image_IDs'"/>
                    <xsl:value-of select="'ATTENTION: Multiple CMS Image IDs in ', $cavafyxml, ': '"/>
                    <xsl:value-of
                        select="pb:pbcoreDescription/pbcoreAnnotation[@annotationType = 'CMS Image']"
                        separator=" ; "/>
                </xsl:element>
            </xsl:if>
            <xsl:variable name="copyrightCount" select="count(pb:pbcoreRightsSummary)"/>
            <xsl:if
                test="
                    $copyrightCount lt $minCopyrightCount
                    or
                    $copyrightCount gt $maxCopyrightCount">
                <xsl:message>
                    <xsl:value-of
                        select="
                            concat(
                            'ATTENTION: ',
                            $copyrightCount, ' rights notices in ',
                            $cavafyxml,
                            '(range allowed:', $minCopyrightCount, '-', $maxCopyrightCount, ')',
                            ': '
                            )"/>
                    <xsl:copy-of select="pb:pbcoreRightsSummary"/>
                </xsl:message>
            </xsl:if>
            <xsl:apply-templates select="pb:pbcoreInstantiation" mode="instantiationQC"/>
        </xsl:variable>

        <xsl:message select="'CAVAFY WARNINGS for ', ."/>
        <xsl:variable name="cavafyWarnings">
            
            <xsl:apply-templates select="." mode="defaultValuesWarning"/>
        </xsl:variable>

        <cavafyEntry>
            <xsl:copy-of select="$cavafyWarnings"/>
            <xsl:message select="$cavafyWarnings"/>
            <xsl:choose>
                <xsl:when test="$cavafyErrors//error">
                    <xsl:copy-of select="$cavafyErrors"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>            
        </cavafyEntry>
    </xsl:template>

    <xsl:template match="pb:pbcoreInstantiation" mode="instantiationQC">
        <!-- INSTANTIATION LEVEL:-->
        <!--    Exactly one instantiation ID with @source = 'WNYC Archive Catalog' -->
        <!--    Exactly one Format, Format Location, Media Type and Generation -->
        <!--    At most one essence track -->
        <xsl:param name="minInstantiationIDCount" select="1"/>
        <xsl:param name="maxInstantiationIDCount" select="1"/>
        <xsl:param name="minFormatCount" select="1"/>
        <xsl:param name="maxFormatCount" select="1"/>
        <xsl:param name="minLocationCount" select="1"/>
        <xsl:param name="maxLocationCount" select="1"/>
        <xsl:param name="minGenerationCount" select="1"/>
        <xsl:param name="maxGenerationCount" select="1"/>
        <xsl:param name="minEssenceTrackCount" select="0"/>
        <xsl:param name="maxEssenceTrackCount" select="1"/>
        
        <xsl:variable name="instantiationIDCount"
            select="
                count(
                pb:instantiationIdentifier
                [@source = 'WNYC Media Archive Label']
                )"/>
        <xsl:if test="$instantiationIDCount != 1">
            <xsl:element name="error">
                <xsl:attribute name="type"
                    select="'instantiation_ID_count'"/>
                <xsl:value-of
                    select="
                        concat(
                        'ATTENTION: ',
                        $instantiationIDCount,
                        ' instantiation IDs in ',
                        ../pb:pbcoreAssetID[@source = 'WNYC Archive Catalog'][1]
                        )"/>
                <xsl:copy-of select="pb:instantiationIdentifier"/>
            </xsl:element>
        </xsl:if>
        <xsl:variable name="essenceTrackCount"
            select="
                count(
                pb:instantiationEssenceTrack
                )"/>
        <xsl:if test="$essenceTrackCount gt 1">
            <xsl:element name="error">
                <xsl:attribute name="type" 
                    select="'essence_track_count'"/>
                <xsl:value-of
                    select="
                        'ATTENTION: ',
                        $essenceTrackCount,
                        ' essence tracks in ',
                        pb:instantiationIdentifier[1], '. ',
                        'Please keep each instantiation to one essence track.'"/>
                <xsl:copy-of select="."/>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="pb:pbcoreDescriptionDocument" mode="defaultValuesWarning"
        name="defaultValuesWarning">
        <!-- Check to see if a cavafy asset 
            has default values 
            for abstract, contributors, or subject headings -->
        <xsl:param name="cavafyURL"
            select="
                concat(
                'https://cavafy.wnyc.org/assets/',
                pb:pbcoreIdentifier
                [@source = 'pbcore XML database UUID'][1]
                )"/>
        <xsl:param name="cavafyxml" select="concat($cavafyURL, '.xml')"/>
        <xsl:param name="cavafyData" select="."/>
        <xsl:message select="
            'Check to see if a cavafy asset', $cavafyURL, 
            ' has default values for',
            ' abstract, contributors, or subject headings'"/>
        <xsl:variable name="collectionInfo">
            <xsl:call-template name="processCollection">
                <xsl:with-param name="
                    collectionAcronym"
                    select="
                        pb:pbcoreTitle[@titleType = 'Collection']"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="collectionurl" select="$collectionInfo//collURL"/>
        <xsl:variable name="seriesName" select="pb:pbcoreTitle[@titleType = 'Series']"/>
        <xsl:variable name="seriesData">
            <xsl:call-template name="findSeriesXMLFromName">
                <xsl:with-param name="seriesName" select="$seriesName"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="seriesKeywords">
            <xsl:value-of
                select="
                    $seriesData//pb:pbcoreSubject
                    /@ref[contains(., 'id.loc.gov')]"
                separator="
                {$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="assetKeywords">
            <xsl:value-of
                select="
                    pb:pbcoreSubject
                    /@ref[contains(., 'id.loc.gov')]"
                separator="
                {$separatingTokenLong}"/>
        </xsl:variable>
        <xsl:variable name="seriesAbstract"
            select="
                $seriesData
                /pb:pbcoreDescriptionDocument
                /pb:pbcoreDescription
                [@descriptionType = 'Abstract']
                [. != '']"/>
        <xsl:variable name="defaultAbstractStart"
            select="
                concat(
                pb:pbcoreTitle[@titleType = 'Episode'],
                ' on ',
                pb:pbcoreTitle[@titleType = 'Series'],
                ' on ')"/>
        
        <xsl:if test="$seriesKeywords[. != ''] = $assetKeywords[. != '']">
            <xsl:call-template name="generateWarning">
                <xsl:with-param name="fieldName" select="'subjectHeadings'"/>
                <xsl:with-param name="fieldValue" select="$assetKeywords"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:apply-templates select="
            pb:pbcoreDescription
            [@descriptionType='Abstract']
            [starts-with(., $defaultAbstractStart)]" 
            mode="generateWarning">
            <xsl:with-param name="warningMessage" select="
                'Possibly default value for abstract'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="
            pb:pbcoreDescription
            [@descriptionType='Abstract']
             = $seriesAbstract" 
            mode="generateWarning">
            <xsl:with-param name="fieldName" select="'abstract'"/>
        </xsl:apply-templates>
        
    </xsl:template>
    
    <xsl:template name="generateWarning" match="node()" mode="generateWarning">
        <xsl:param name="fieldName" select="local-name()"/>
        <xsl:param name="warningType" select="'defaultValue'"/>
        <xsl:param name="warningMessage" select="
            concat(
            'Default series values in ', $fieldName
            )"/>
        <xsl:param name="fieldValue" select="."/>
        <xsl:message select="$warningMessage, ."/>
        <xsl:element name="warning">
            <xsl:attribute name="{$warningType}"/>
            <xsl:value-of select="$warningMessage"/>
            <xsl:copy-of select="."/>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
