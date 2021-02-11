<?xml version="1.0" encoding="UTF-8"?>
<!-- Perform QC on cavafy pbcore entries -->

<!-- Test whether each cavafy entry has any errors, with the following defaults: -->

<!-- ASSET LEVEL: -->
<!--    Exactly one asset ID with @source = 'WNYC Media Archive Label' -->
<!--    At least one properly formatted asset date -->
<!--    Exactly one collection, Series and Episode titles -->
<!--    At least one subject heading with @ref='id.loc.gov/authorities/' -->
<!--    Exactly one abstract with decent length and content -->
<!--    Exactly one genre -->
<!--    At least one Creator or publisher with @ref='id.loc.gov/authorities/' -->
<!--    At least one Contributor with @ref='id.loc.gov/authorities/' -->        
<!--    At most one CMS Image -->
<!--    Exactly one Copyright notice -->

<!-- INSTANTIATION LEVEL: -->
<!--    Exactly one instantiation ID 
            with @source = 'WNYC Media Archive Label' and format 'asset.xx' -->
<!--    Exactly one Format, Format Location, and Media Type -->
<!--    At most one Generation -->
<!--    At most one essence track -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" version="2.0">

    <xsl:import href="cavafySearch.xsl"/>
    <xsl:import href="errorLog.xsl"/>
    <xsl:import href="processCollection.xsl"/>

    <xsl:output method="xml" version="1.0" indent="yes"/>
    <xsl:mode on-no-match="deep-skip"/>

    <xsl:template match="pb:pbcoreCollection" mode="
        cavafyStrictQC">
        <!-- Match top-level element -->
            <xsl:apply-templates select="
                pb:pbcoreDescriptionDocument" mode="
                cavafyStrictQC"/>        
    </xsl:template>

    <xsl:template match="pb:pbcoreDescriptionDocument
        [not (pb:pbcoreRelation/pb:pbcoreRelationIdentifier = 'SRSLST')]" mode="cavafyStrictQC">
        <!-- Test whether each cavafy entry has any errors -->
        
        <xsl:param name="cavafyURL"
            select="
            concat(
            'https://cavafy.wnyc.org/assets/', 
            pb:pbcoreIdentifier
            [@source = 'pbcore XML database UUID'][1]
            )"/>
        <xsl:param name="cavafyxml" select="concat($cavafyURL, '.xml')"/>
        <xsl:param name="datePattern" select="
            '^[12u][0123456789u]{3}-[01u][0123456789u]-[0123u][0123456789u]$'"/>
        <xsl:message select="
            'Test whether the cavafy entry ',
            $cavafyURL,
            ' has any errors'
            "/>
        <xsl:variable name="cavafyWarnings">
            <xsl:apply-templates select="." mode="defaultValuesWarning"/>
        </xsl:variable>
      
        <xsl:variable name="cavafyErrors">            
            <xsl:variable name="assetIDCount"
                select="
                    count(
                    pb:pbcoreIdentifier
                    [@source = 'WNYC Archive Catalog']
                    )"/>
            <xsl:apply-templates select="
                .[$assetIDCount ne 1]
                " 
                mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'cavafyID'"/>
                <xsl:with-param name="nodeCount" select="$assetIDCount"/>
                <xsl:with-param name="minCount" select="1"/>
                <xsl:with-param name="maxCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
            <xsl:variable name="dateCount"  select="
                count(
                pb:pbcoreAssetDate
                [matches(., $datePattern)]
                )"/>         
            <xsl:apply-templates select="
                .[$dateCount lt 1]" mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'assetDate'"/>
                <xsl:with-param name="nodeCount" select="
                    $dateCount"/>
                <xsl:with-param name="minCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
            
            <xsl:variable name="collectionCount"
                select="
                    count(
                    pb:pbcoreTitle[@titleType = 'Collection']
                    )"/>
            <xsl:apply-templates select="
                .
                [$collectionCount ne 1]
                " 
                mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'collection'"/>
                <xsl:with-param name="nodeCount" select="$collectionCount"/>
                <xsl:with-param name="minCount" select="1"/>
                <xsl:with-param name="maxCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
          
            <xsl:variable name="seriesCount"
                select="
                    count(
                    pb:pbcoreTitle[@titleType = 'Series']
                    )"/>
            <xsl:apply-templates select="
                .[$seriesCount ne 1]
                " 
                mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'series'"/>
                <xsl:with-param name="nodeCount" select="$seriesCount"/>
                <xsl:with-param name="minCount" select="1"/>
                <xsl:with-param name="maxCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
            
            <xsl:variable name="episodeCount"
                select="
                    count(
                    pb:pbcoreTitle[@titleType = 'Episode']
                    )"/>
            <xsl:apply-templates select="
                .[$episodeCount ne 1]" 
                mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'episodeTitle'"/>
                <xsl:with-param name="nodeCount" select="$episodeCount"/>
                <xsl:with-param name="minCount" select="1"/>
                <xsl:with-param name="maxCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
             
            <xsl:variable name="abstractCount"
                select="
                    count(pb:pbcoreDescription
                    [@descriptionType = 'Abstract'])"/>
            <xsl:apply-templates select="
                .[$abstractCount ne 1]" 
                mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'abstract'"/>
                <xsl:with-param name="nodeCount" select="$abstractCount"/>
                <xsl:with-param name="minCount" select="1"/>
                <xsl:with-param name="maxCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
            
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
                    <xsl:attribute name="type"
                        select="'short_abstract'"/>
                    <xsl:value-of select="'ATTENTION: Very short abstract in ', $cavafyxml, ': '"/>
                    <xsl:copy-of select="pb:pbcoreDescription[@descriptionType = 'Abstract'][string-length(.) lt 20]"/>
                </xsl:element>
            </xsl:if>
            <xsl:variable name="genreCount" select="count(pb:pbcoreGenre)"/>
            <xsl:apply-templates select="
                .[$genreCount ne 1]" 
                mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'genre'"/>
                <xsl:with-param name="nodeCount" select="$genreCount"/>
                <xsl:with-param name="minCount" select="1"/>
                <xsl:with-param name="maxCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
            
            <xsl:variable name="subjectHeadingCount" select="
                count(pb:pbcoreSubject[contains(@ref, 'id.loc.gov/authorities/')])"/>
            <xsl:apply-templates select="
                .[$subjectHeadingCount lt 1]" 
                mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'subjectHeading'"/>
                <xsl:with-param name="nodeCount" select="$subjectHeadingCount"/>
                <xsl:with-param name="minCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
            
            <xsl:variable name="creatorPublisherCount" select="
                count(
                pb:pbcoreCreator[contains(pb:creator/@ref, 'id.loc.gov/authorities/')]
                |
                pb:pbcorePublisher[contains(pb:publisher/@ref, 'id.loc.gov/authorities/')]
                )"/>
            <xsl:apply-templates select="
                .[$creatorPublisherCount lt 1]" 
                mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'creatorPublisher'"/>
                <xsl:with-param name="nodeCount" select="$creatorPublisherCount"/>
                <xsl:with-param name="minCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
            
            <xsl:variable name="contributorCount" select="
                count(pb:pbcoreContributor[contains(pb:contributor/@ref, 'id.loc.gov/authorities/')])"/>
            <xsl:apply-templates select="
                .[$contributorCount lt 1]" 
                mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'contributor'"/>
                <xsl:with-param name="nodeCount" select="$contributorCount"/>
                <xsl:with-param name="minCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
            
            <xsl:variable name="cmsImageIDCount"
                select="
                    count(
                   pb:pbcoreAnnotation
                    [@annotationType = 'CMS Image']
                    )"/>
            <xsl:apply-templates select="
                .[$cmsImageIDCount gt 1]" 
                mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'cmsImage'"/>
                <xsl:with-param name="nodeCount" select="$cmsImageIDCount"/>
                <xsl:with-param name="maxCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
            
            <xsl:variable name="copyrightCount" select="count(pb:pbcoreRightsSummary)"/>
            <xsl:apply-templates select="
                .[$copyrightCount ne 1]" 
                mode="generateError">
                <xsl:with-param name="nodeName" select="
                    'copyrightNotice'"/>
                <xsl:with-param name="nodeCount" select="$copyrightCount"/>
                <xsl:with-param name="minCount" select="1"/>
                <xsl:with-param name="maxCount" select="1"/>
                <xsl:with-param name="cavafyxml" select="
                    $cavafyxml"/>
            </xsl:apply-templates>
            
            <xsl:apply-templates select="pb:pbcoreInstantiation" mode="instantiationStrictQC">
                <xsl:with-param name="cavafyxml" select="$cavafyxml"/>
                <xsl:with-param name="cavafyAssetID" select="
                    pb:pbcoreIdentifier
                    [@source = 'WNYC Archive Catalog']"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <result>
            <xsl:attribute name="filename" select="$cavafyURL"/>
                    <xsl:copy-of select="$cavafyErrors"/>
            <xsl:copy-of select="$cavafyWarnings"/>
            <xsl:message select="$cavafyWarnings"/>
        </result>
    </xsl:template>

    <xsl:template match="pb:pbcoreInstantiation" mode="instantiationStrictQC">
        <!-- INSTANTIATION LEVEL:-->
        <!--    Exactly one instantiation ID with @source = 'WNYC Archive Media Archive Label' and format 'asset.xx'-->
        <!--    Exactly one Format, Format Location, and Media Type -->
        <!--    At most one Generation -->
        <!--    At most one essence track -->
        <xsl:param name="cavafyxml"/>
        <xsl:param name="cavafyAssetID" select="
            $cavafyxml
            /pb:pbcoreDescriptionDocument
            /pb:pbcoreIdentifier
            [@source = 'WNYC Archive Catalog']"/>
        <xsl:param name="instantiationIDPattern" select="concat(
            '^', $cavafyAssetID[1], '\.', '[0-9]+', '[a-z]', '*'
            )"/>
        <xsl:variable name="instantiationIDCount"
            select="
                count(
                pb:instantiationIdentifier
                [@source = 'WNYC Media Archive Label']
                [matches(., $instantiationIDPattern)]
                )"/>
        <xsl:apply-templates select="
            .[$instantiationIDCount ne 1]" 
            mode="generateError">
            <xsl:with-param name="nodeName" select="
                'instantiationID'"/>
            <xsl:with-param name="nodeCount" select="$instantiationIDCount"/>
            <xsl:with-param name="minCount" select="1"/>
            <xsl:with-param name="maxCount" select="1"/>
            <xsl:with-param name="cavafyxml" select="
                $cavafyxml"/>
        </xsl:apply-templates>
        
        <xsl:variable name="instantiationFormatCount"
            select="
            count(
            (pb:instantiationPhysical | pb:instantiationDigital)            
            )"/>
        <xsl:apply-templates select="
            .[$instantiationFormatCount ne 1]" 
            mode="generateError">
            <xsl:with-param name="nodeName" select="
                'format'"/>
            <xsl:with-param name="nodeCount" select="$instantiationFormatCount"/>
            <xsl:with-param name="minCount" select="1"/>
            <xsl:with-param name="maxCount" select="1"/>
            <xsl:with-param name="cavafyxml" select="
                $cavafyxml"/>
        </xsl:apply-templates>
        
        <xsl:variable name="instantiationLocationCount"
            select="
            count(
            pb:instantiationLocation
            [normalize-space(.) != '']
            )"/>
        <xsl:apply-templates select="
            .[$instantiationLocationCount ne 1]" 
            mode="generateError">
            <xsl:with-param name="nodeName" select="
                'instantiationLocation'"/>
            <xsl:with-param name="nodeCount" select="$instantiationLocationCount"/>
            <xsl:with-param name="minCount" select="1"/>
            <xsl:with-param name="maxCount" select="1"/>
            <xsl:with-param name="cavafyxml" select="
                $cavafyxml"/>
        </xsl:apply-templates>
        
        <xsl:variable name="instantiationMediaTypeCount"
            select="
            count(
            pb:instantiationMediaType            
            )"/>
        <xsl:apply-templates select="
            .[$instantiationMediaTypeCount ne 1]" 
            mode="generateError">
            <xsl:with-param name="nodeName" select="
                'mediaType'"/>
            <xsl:with-param name="nodeCount" select="$instantiationMediaTypeCount"/>
            <xsl:with-param name="minCount" select="1"/>
            <xsl:with-param name="maxCount" select="1"/>
            <xsl:with-param name="cavafyxml" select="
                $cavafyxml"/>
        </xsl:apply-templates>
        
        <xsl:variable name="instantiationGenerationsCount"
            select="
            count(
            pb:instantiationGenerations
            )"/>
        <xsl:apply-templates select="
            .[$instantiationGenerationsCount gt 1]" 
            mode="generateError">
            <xsl:with-param name="nodeName" select="
                'instantiationGenerations'"/>
            <xsl:with-param name="nodeCount" select="$instantiationGenerationsCount"/>
            <xsl:with-param name="minCount" select="0"/>
            <xsl:with-param name="maxCount" select="1"/>
            <xsl:with-param name="cavafyxml" select="
                $cavafyxml"/>
        </xsl:apply-templates>
        
        <xsl:variable name="essenceTrackCount"
            select="
                count(
                pb:instantiationEssenceTrack
                )"/>
        <xsl:apply-templates select="
            .[$essenceTrackCount gt 1]" 
            mode="generateError">
            <xsl:with-param name="nodeName" select="
                'essenceTrack'"/>
            <xsl:with-param name="nodeCount" select="$essenceTrackCount"/>            
            <xsl:with-param name="maxCount" select="1"/>
            <xsl:with-param name="cavafyxml" select="
                $cavafyxml"/>
        </xsl:apply-templates>        
    </xsl:template>
    
    <xsl:template name="generateError" match="node()" mode="generateError">
        <xsl:param name="nodeName" select="local-name(.)"/>
        <xsl:param name="nodeCount"/>
        <xsl:param name="minCount"/>
        <xsl:param name="maxCount"/>
        <xsl:param name="cavafyxml"/>
        <xsl:param name="errorMessage">
            <xsl:element name="error">
                <xsl:attribute name="type" select="concat($nodeName, '_count')"/>
                <xsl:attribute name="xml" select="$cavafyxml"/>
                <xsl:value-of
                    select="
                        concat(
                        'ATTENTION: ',
                        $nodeCount, ' ', $nodeName, 's in ',
                        $cavafyxml,
                        ' (range allowed:', $minCount, '-', $maxCount, ')',
                        ': '
                        )"
                />
            </xsl:element>            
        </xsl:param>
        <xsl:message>
            <xsl:value-of select="$errorMessage"/>
        </xsl:message>
        <xsl:copy-of select="$errorMessage"/>
    </xsl:template>

    <xsl:template match="pb:pbcoreDescriptionDocument"
        name="defaultValuesWarning" mode="defaultValuesWarning">
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
            'Check to see if cavafy entry', $cavafyURL, 
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
        <xsl:variable name="collectionurl" select="$collectionInfo/collectionInfo/collURL"/>        
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
        <xsl:variable name="assetContributors">
            <xsl:value-of select="
            pb:pbcoreContributor
            /pb:contributor
            /@ref[contains(., 'id.loc.gov')]" separator="{$separatingTokenLong}"/>
        </xsl:variable>
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
            [. = $seriesAbstract]" 
            mode="generateWarning">
            <xsl:with-param name="fieldName" select="'abstract'"/>
        </xsl:apply-templates>
        <xsl:message select="'assetContributors', $assetContributors"/>
        <xsl:if test="$assetContributors[. != ''] = $collectionurl[. != '']">
            <xsl:call-template name="generateWarning">
                <xsl:with-param name="fieldName" select="'contributors'"/>
                <xsl:with-param name="fieldValue" select="pb:pbcoreContributor"/>
            </xsl:call-template>
        </xsl:if>
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
            <xsl:attribute name="type" select="$warningType"/>
            <xsl:value-of select="$warningMessage"/>
            <xsl:copy-of select="$fieldValue"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
