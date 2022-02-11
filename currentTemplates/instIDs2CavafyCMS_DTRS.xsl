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
        <xsl:variable name="instIDsByBin">
            <instIDsByBin>
            <xsl:for-each-group select="instantiationID" group-by="@location">
                <xsl:copy select="..">
                    <xsl:attribute name="location" select="fn:current-grouping-key()"/>
                    <xsl:copy-of select="current-group()"/>
                </xsl:copy>
            </xsl:for-each-group>
            </instIDsByBin>
        </xsl:variable>
        <xsl:apply-templates select="$instIDsByBin/instIDsByBin/instantiationIDs" mode="cavafyAndCMS"/>
            
    </xsl:template>

    <xsl:template match="instantiationIDs" mode="cavafyAndCMS">
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
        
        <xsl:param name="filenameAddendum" select="@location"/>
        
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
            <xsl:value-of select="$filenameAddendum"/>
            <xsl:value-of select="'WOriginalAbstract'"/>
            <xsl:value-of select="'.xml'"/>
        </xsl:param>
        <xsl:param name="updatedAbstractPBCoreDocName">
            <xsl:value-of select="$baseFolder"/>
            <xsl:value-of select="$masterDocFilenameNoExtension"/>
            <xsl:value-of select="$filenameAddendum"/>
            <xsl:value-of select="'WUpdatedAbstract'"/>
            <xsl:value-of select="'.xml'"/>
        </xsl:param>
        <xsl:param name="differentAbstractsDocName">
            <xsl:value-of select="$baseFolder"/>
            <xsl:value-of select="$masterDocFilenameNoExtension"/>
            <xsl:value-of select="$filenameAddendum"/>
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
        <xsl:param name="originalCavafyAbstract" select="
            $originalCavafyXML/pb:pbcoreDescriptionDocument/
            pb:pbcoreDescription
            [@descriptionType = 'Abstract']"/>

        <xsl:param name="showName" select="
                $originalCavafyXML/pb:pbcoreDescriptionDocument/pb:pbcoreTitle
                [@titleType = 'Series']"/>
        <xsl:param name="articledShowName" select="
                WNYC:reverseArticle($showName[matches(., '\w')])"/>
        <xsl:param name="bcastDateAsText" select="
                min($originalCavafyXML/pb:pbcoreDescriptionDocument/pb:pbcoreAssetDate
                [@dateType = 'broadcast']
                /normalize-space(.)
                [matches(., $ISODatePattern)])"/>
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

        <xsl:param name="cmsData">
            <xsl:choose>
                <xsl:when test="
                    matches($showSlug, '\w') and
                    matches($bcastDateAsText, $ISODatePattern)">
                    <xsl:message select="
                        'Get CMS data from slug and date',
                        $showSlug, $bcastDateAsText"/>
                    <xsl:call-template name="getCMSData">
                        <xsl:with-param name="date" select="$date"/>
                        <xsl:with-param name="showSlug" select="$showSlug"/>
                        <xsl:with-param name="maxRecords" select="20"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:param>
        <xsl:param name="cmsArticle" select="
            $cmsData/data/
            attributes[item-type='article']"/>
        <xsl:param name="cmsEpisode" select="
            $cmsData//
            attributes[item-type='episode']"/>
        <xsl:param name="cmsIsSegmented" select="
            boolean(
            $cmsData/data/
            attributes/segments[slug])"/>
        <xsl:param name="cmsSegments">
            <!-- Segments in an episode, in order -->
            <xsl:for-each select="$cmsData//
                data/attributes/
                segments/slug">
                <xsl:sort select="preceding-sibling::segment-number[1]"/>
                <xsl:variable name="segmentSlug" select="."/>
                <segment>
                    <xsl:attribute name="segment-number" select="preceding-sibling::segment-number[1]"/>
                    <xsl:copy-of select="$cmsData//data/
                        attributes
                        [item-type='segment']
                        [slug=$segmentSlug]"/>
                </segment>
            </xsl:for-each>
        </xsl:param>
        
        <xsl:param name="cmsEpisodeDescription">
            <!-- Description of full episode -->
            <xsl:value-of
                select="
                $cmsEpisode//
                body/
                WNYC:strip-tags(
                tokenize(
                ., 'WNYC archives id:'
                )[1]
                )"
                separator="&#9;"/>
        </xsl:param>
        <!-- Individual segment descriptions -->
        <xsl:param name="cmsSegmentsTitleBody">
            <!-- Pick only segments' title and body, 
                in segment order -->
            <segmentDescriptions>                
                <xsl:for-each
                    select="
                    $cmsSegments//attributes">
                    <segment>
                        <xsl:copy-of select="title"/>
                        <xsl:copy-of select="body"/>
                    </segment>
                </xsl:for-each>
            </segmentDescriptions>
        </xsl:param>        
        <xsl:param name="cmsSegmentsTitleBodyFormatted">
            <!-- Format segment titles and bodies -->
            <xsl:for-each
                select="
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
                '&#10;&#13;&#10;&#13;&#10;&#13;'
                [$cmsIsSegmented]"/>          
            <xsl:value-of select="
                $cmsSegmentsTitleBodyFormatted"/>
        </xsl:param>
        
        
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