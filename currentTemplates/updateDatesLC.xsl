<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
    xmlns:WNYC="http://www.wnyc.org"
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
    <xsl:import href="masterRouter.xsl" exclude-result-prefixes="#all"/>
    
    <!-- This script generates one or more
    xml documents to upload into cavafy
    which merge additional data
    into each asset:
    
    1. A recorded date
    2. A broadcast date 
    3. Subject headings
    4. Contributors
    
    The source document is as follows:
    
    <updateAssets>
    <updateAsset>
        <url></url>
        <assetID></assetID>
        <collection></collection>
        <instantiationID></instantiationID>        
        <recordedDate></recordedDate>
        <bcastDate></bcastDate>
        <contributors></contributors>
        <subjects></subjects>
    </updateAsset>
    <updateAsset>
        <url></url>
        <assetID></assetID>
        <collection></collection>
        <instantiationID></instantiationID>        
        <recordedDate></recordedDate>
        <bcastDate></bcastDate>
        <contributors></contributors>
        <subjects></subjects>
    </updateAsset>
</updateAssets>
    
    -->
    
    <xsl:variable name="dateRegex" select="
        concat(
        '^', 
        $yearRegex, '-', 
        $monthRegex, '-', 
        $dayRegex, '$')"/>
    
    <xsl:template match="updateAssets">
        <xsl:param name="fullDoc">
            <xsl:element name="
            pbcoreCollection"
                namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                <xsl:apply-templates select="updateAsset
                    [recordedDate | bcastDate | contributors | subjects]"/>
            </xsl:element>
        </xsl:param>
        <xsl:apply-templates select="$fullDoc/pb:pbcoreCollection" mode="breakItUp">
<xsl:with-param name="maxOccurrences" select="200"/>            
            <xsl:with-param name="filename" select="WNYC:substring-before-last(base-uri(), '.')"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="updateAsset
        ">
        <xsl:param name="url" select="url"/>
        <xsl:param name="cavafyEntry" select="doc(concat($url, '.xml'))"/>
        <xsl:param name="collection"
            select="
                $cavafyEntry/pb:pbcoreDescriptionDocument/pb:pbcoreTitle[@titleType = 'Collection']"/>
        <xsl:param name="assetID" select="substring-before(instantiationID, '.')"/>
        <xsl:param name="bcastDate">
            <xsl:element name="pbcoreAssetDate"
                namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                <xsl:attribute name="dateType">broadcast</xsl:attribute>
                <xsl:value-of select="
                    bcastDate[not(. = '1900-01-00')]"/>
            </xsl:element>
        </xsl:param>
        <xsl:param name="recordedDate">
            <xsl:element name="pbcoreAssetDate"
                namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                <xsl:attribute name="dateType">created</xsl:attribute>
                <xsl:value-of select="recordedDate
                    [not(. = '1900-01-00')]"/>
            </xsl:element>
        </xsl:param>
        <xsl:param name="subjects">
            <RIFF:Keywords>
                <xsl:value-of select="subjects[matches(., $combinedValidatingStrings)]"/>
            </RIFF:Keywords>
        </xsl:param> 
        <xsl:param name="contributors" select="contributors[matches(., $validatingNameString)]"/>
        <xsl:param name="subjectsAlreadyInCavafy"
            select="
                $cavafyEntry/pb:pbcoreDescriptionDocument/
                pb:pbcoreSubject/@ref[matches(., $combinedValidatingStrings)]"/>
        <xsl:param name="contributorsAlreadyInCavafy">
            <xsl:value-of
                select="
                $cavafyEntry
                /pb:pbcoreDescriptionDocument
                /pb:pbcoreContributor
                /pb:contributor
                /@ref[matches(., $validatingNameString)]"
                separator=" ; "/>
        </xsl:param>
        <xsl:param name="createDatesAlreadyInCavafy" select="$cavafyEntry/
            pb:pbcoreDescriptionDocument/
            pb:pbcoreAssetDate
            [@dateType = 'created']"/>
        <xsl:param name="bcastDatesAlreadyInCavafy" select="$cavafyEntry/
            pb:pbcoreDescriptionDocument/
            pb:pbcoreAssetDate
            [@dateType = 'broadcast']"/>
    

        <xsl:copy select="
            $cavafyEntry/
            pb:pbcoreDescriptionDocument">
            <xsl:copy-of
                select="
                pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog']"/>
            <xsl:copy-of
                select="
                pb:pbcoreTitle[@titleType = 'Collection']"/>
            <xsl:copy-of
                select="
                    $bcastDate
                    [matches(., $dateRegex)]
                    [not(. = $bcastDatesAlreadyInCavafy)]
                    "/>                
            <xsl:copy-of
                select="
                $recordedDate
                [matches(., $dateRegex)]
                [not(. = $createDatesAlreadyInCavafy)]
                "/>
            <xsl:variable name="locSubjects">
                <xsl:apply-templates select="$subjects" mode="
                    processSubjects">
                    <xsl:with-param name="subjectsProcessed" select="$subjectsAlreadyInCavafy"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:apply-templates select="
                    $locSubjects" mode="LOCtoPBCore"/>
            <xsl:call-template name="parseContributors">
                <xsl:with-param name="contributorsToProcess" select="
                    $contributors"/>
                <xsl:with-param name="contributorsAlreadyInCavafy" select="
                    $contributorsAlreadyInCavafy">                    
                </xsl:with-param>                
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>