<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:WNYC="http://www.wnyc.org"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">

    <xsl:import href="cavafySearch.xsl"/>
    <xsl:import href="cms2BWFMetaEdit.xsl"/>

    <xsl:output indent="yes" encoding="UTF-8"/>

    <!-- Get only asset-level descriptions
    from cavafy
    and compare to CMS.    
    If different, generate pbcore document
    to ingest -->

    <xsl:param name="CMSShowList" select="doc('Shows.xml')"/>

    <xsl:variable name="baseURI" select="
        base-uri()"/>

    <xsl:template match="instantiationIDs">
        <xsl:param name="parsedBaseURI" select="
            analyze-string($baseURI, '/')"/>
        <xsl:param name="masterDocFilename">
            <xsl:value-of select="
                $parsedBaseURI/
                fn:non-match[last()]"/>
        </xsl:param>
        <xsl:param name="masterDocFilenameNoExtension">
            <xsl:value-of select="
                WNYC:substring-before-last(
                $masterDocFilename, '.'
                )"/>
        </xsl:param>
        <xsl:param name="baseFolder" select="
            substring-before(
            $baseURI,
            $masterDocFilename
            )"/>
        <xsl:param name="logFolder" select="
            concat(
            $baseFolder,
            'instantiationUploadLOGS/'
            )"/>
        <xsl:param name="currentDate" select="
            format-date(current-date(),
            '[Y0001][M01][D01]')"/>
        
        
        <xsl:param name="newPBCoreDoc">
            <result>
                <xsl:for-each-group select="instantiationID" group-by="substring-before(., '.')">
                    <xsl:apply-templates select="." mode="cavafyAndCMS"/>
                </xsl:for-each-group>
            </result>
        </xsl:param>
        <xsl:param name="originalPBCoreDocName">
            <xsl:value-of select="$baseFolder"/>
            <xsl:value-of select="$masterDocFilenameNoExtension"/>
            <xsl:value-of select="'WOriginalAbstract'"/>
            <xsl:value-of select="'.xml'"/>
        </xsl:param>
        <xsl:param name="updatedAbstractPBCoreDocName">
            <xsl:value-of select="$baseFolder"/>
            <xsl:value-of select="$masterDocFilenameNoExtension"/>
            <xsl:value-of select="'WUpdatedAbstract'"/>
            <xsl:value-of select="'.xml'"/>
        </xsl:param>
        <xsl:param name="differentAbstractsDocName">
            <xsl:value-of select="$baseFolder"/>
            <xsl:value-of select="$masterDocFilenameNoExtension"/>
            <xsl:value-of select="'differentAbstracts'"/>
            <xsl:value-of select="'.xml'"/>
        </xsl:param>
        <xsl:param name="newResults" select="
            boolean($newPBCoreDoc/result[differentAbstracts])"/>
        <xsl:copy-of select="$newPBCoreDoc/result[differentAbstracts]"/>
        <xsl:if test="$newResults">
            <xsl:result-document href="{$differentAbstractsDocName}">
                <xsl:element name="differentBastracts">
                    <xsl:copy-of select="$newPBCoreDoc/result/differentAbstracts/error"/>
                </xsl:element>
            </xsl:result-document>
            <xsl:result-document href="{$originalPBCoreDocName}">
                <xsl:element name="pb:pbcoreCollection">
                    <xsl:namespace name="xsi" select="'http://www.w3.org/2001/XMLSchema-instance'"/>
                    <xsl:attribute name="xsi:schemaLocation"
                        select="'http://pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd'"/>
                    <xsl:apply-templates
                        select="$newPBCoreDoc/result/originalPBCore/pb:pbcoreDescriptionDocument"
                        mode="importReady"/>
                </xsl:element>
            </xsl:result-document>
            <xsl:result-document href="{$updatedAbstractPBCoreDocName}">
                <xsl:element name="pb:pbcoreCollection">
                    <xsl:namespace name="xsi" select="'http://www.w3.org/2001/XMLSchema-instance'"/>
                    <xsl:attribute name="xsi:schemaLocation"
                        select="'http://pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd'"/>
                    <xsl:apply-templates
                        select="$newPBCoreDoc/result/updatedPBCore/pb:pbcoreDescriptionDocument"
                        mode="importReady"/>
                </xsl:element>
            </xsl:result-document>
        </xsl:if>
    </xsl:template>

    <xsl:template match="instantiationID" mode="cavafyAndCMS">
        <xsl:param name="instantiationID" select="."/>
        <xsl:param name="originalCavafyXML">
            <xsl:call-template name="findSpecificCavafyAssetXML">
                <xsl:with-param name="assetID" select="
                        substring-before($instantiationID, '.')"/>
            </xsl:call-template>
        </xsl:param>

        <xsl:param name="showName" select="
                $originalCavafyXML/pb:pbcoreDescriptionDocument/pb:pbcoreTitle
                [@titleType = 'Series']"/>
        <xsl:param name="articledShowName" select="
                WNYC:reverseArticle($showName)"/>
        <xsl:param name="bcastDateAsText" select="
                $originalCavafyXML/pb:pbcoreDescriptionDocument/pb:pbcoreAssetDate
                [@dateType = 'broadcast']
                /normalize-space(.)
                [matches(., $ISODatePattern)]"/>
        <xsl:param name="date" select="
                xs:date(min($bcastDateAsText)
                )"/>

        <xsl:param name="cmsShowInfo">
            <xsl:copy-of select="
                    $CMSShowList/JSON/
                    data[type = 'show']/
                    attributes[title = $articledShowName]"/>
        </xsl:param>
        <xsl:param name="showSlug" select="
                $cmsShowInfo/attributes/slug"/>

        <xsl:param name="cmsArticleData">
            <xsl:call-template name="getCMSData">
                <xsl:with-param name="showSlug" select="
                        $showSlug"/>
                <xsl:with-param name="date" select="$date"/>
                <xsl:with-param name="item_type" select="
                        'article'"/>
                <xsl:with-param name="fields" select="'title,body,segments'"/>
                <xsl:with-param name="minRecords" select="0"/>
                <xsl:with-param name="maxRecords" select="1"/>
            </xsl:call-template>
        </xsl:param>

        <xsl:param name="cmsEpisodeData">
            <xsl:call-template name="getCMSData">
                <xsl:with-param name="showSlug" select="
                        $showSlug"/>
                <xsl:with-param name="date" select="$date"/>
                <xsl:with-param name="item_type" select="
                        'episode'"/>
                <xsl:with-param name="fields" select="'title,body,segments'"/>
                <xsl:with-param name="minRecords" select="0"/>
                <xsl:with-param name="maxRecords" select="1"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="cmsEpisodeIsSegmented" select="
                boolean(
                $cmsEpisodeData/cmsData
                [data/attributes/segments/segment-number])"/>
        <xsl:param name="cmsSegmentsData">
            <segments>
                <xsl:for-each select="$cmsEpisodeData/cmsData/data/attributes/segments/episode-id">
                    <xsl:sort select="following-sibling::segment-number[1]"/>
                    <xsl:call-template name="getCMSData">
                        <xsl:with-param name="slug" select="following-sibling::slug[1]"/>
                        <xsl:with-param name="fields" select="'title,body'"/>
                    </xsl:call-template>
                </xsl:for-each>
            </segments>
        </xsl:param>
        <xsl:param name="cmsArticleDescription">
            <!-- Description of full episode -->
            <xsl:value-of select="
                    $cmsArticleData/cmsData/data/
                    attributes/
                    body/
                    WNYC:strip-tags(
                    tokenize(
                    ., 'WNYC archives id:'
                    )[1]
                    )" separator="&#9;"/>
        </xsl:param>
        <xsl:param name="cmsEpisodeDescription">
            <!-- Description of full episode -->
            <xsl:value-of select="
                    $cmsEpisodeData/cmsData/data/
                    attributes/
                    body/
                    WNYC:strip-tags(
                    tokenize(
                    ., 'WNYC archives id:'
                    )[1]
                    )" separator="&#9;"/>
        </xsl:param>
        <!-- Individual segment descriptions -->
        <xsl:param name="cmsSegmentsTitleBody">
            <!-- Pick only segments' title and body, 
                in segment order -->
            <segmentDescriptions>
                <xsl:for-each select="
                        $cmsSegmentsData/segments/cmsData">
                    <segment>
                        <xsl:copy-of select="data/attributes/title"/>
                        <xsl:copy-of select="data/attributes/body"/>
                    </segment>
                </xsl:for-each>
            </segmentDescriptions>
        </xsl:param>
        <xsl:param name="cmsSegmentsTitleBodyFormatted">
            <!-- Format segment titles and bodies -->
            <xsl:for-each select="
                    $cmsSegmentsTitleBody/
                    segmentDescriptions/segment">
                <xsl:value-of select="title"/>
                <xsl:value-of select="'&#10;&#13;'"/>
                <xsl:value-of select="
                        WNYC:strip-tags(body)"/>
                <xsl:value-of select="'&#10;&#13;'"/>
                <xsl:value-of select="'&#10;&#13;'"/>
            </xsl:for-each>
        </xsl:param>
        <xsl:param name="cmsCompleteDescription">
            <xsl:value-of select="
                    $cmsEpisodeDescription"/>
            <xsl:value-of select="
                    '&#10;&#13;&#10;&#13;&#10;&#13;'[$cmsEpisodeIsSegmented]"/>
            <xsl:value-of select="
                    $cmsSegmentsTitleBodyFormatted"/>
        </xsl:param>
        <xsl:param name="originalCavafyAbstract" select="
                $originalCavafyXML/pb:pbcoreDescriptionDocument/
                pb:pbcoreDescription
                [@descriptionType = 'Abstract']"/>
        <xsl:param name="newAbstract">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="
                        'abstract'"/>
                <xsl:with-param name="field1" select="
                        $originalCavafyAbstract"/>
                <xsl:with-param name="field2" select="
                        $cmsCompleteDescription"/>
                <xsl:with-param name="normalize" select="false()"/>
                <xsl:with-param name="separatingToken" select="
                    $separatingTokenForFreeTextFields"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="cavafyWithUpdatedAbstract">
            <xsl:apply-templates select="$originalCavafyXML" mode="newAbstract">
                <xsl:with-param name="newAbstract" select="
                        $cmsCompleteDescription" tunnel="true"/>
            </xsl:apply-templates>
        </xsl:param>
        <xsl:param name="cmsAbstractIsLonger" select="
                string-length($cmsCompleteDescription) 
                gt 
                string-length($originalCavafyAbstract)"/>
        <xsl:param name="abstractsAreDifferent" select="
                boolean(
                $newAbstract[//error])"/>        
        <xsl:if test="$abstractsAreDifferent">
                <differentAbstracts>
                    <xsl:copy-of select="$newAbstract"/>
                </differentAbstracts>
                <originalPBCore>
                    <xsl:copy-of select="$originalCavafyXML"/>
                </originalPBCore>
                <updatedPBCore>
                    <xsl:copy-of select="$cavafyWithUpdatedAbstract"/>
                </updatedPBCore>
        </xsl:if>
        


    </xsl:template>



</xsl:stylesheet>