<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
    <xsl:import href="parseAuthorsTitlesLOG.xsl"/>
    
    <!-- Extract Capitalised Names from a text -->
    <xsl:template match="pma_xml_export">
        <xsl:param name="findLoCContributors">
            <findLoCContributors>
                <xsl:apply-templates select="database/table" mode="extractName"/>
            </findLoCContributors>
        </xsl:param>
        <xsl:call-template name="chooseContributors">
            <xsl:with-param name="findLoCContributors" select="$findLoCContributors"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="table" mode="extractName">
        <xsl:param name="cavafyURL" select="column[@name='url' or @name='URL']"/>
        <xsl:param name="cavafyEntry" select="doc(concat($cavafyURL, '.xml'))"/>
        <xsl:param name="abstract" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreDescription[@descriptionType='Abstract']"/>
        <xsl:param name="transcript" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreDescription[@descriptionType='Transcript']"/>        
        <xsl:param name="title" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreTitle[@titleType='Episode']"/>
        <xsl:param name="includeTranscript" select="false()"/>
        <xsl:param name="completeText">            
            <xsl:value-of select="
                $abstract, 
                $title, 
                $transcript[$includeTranscript]"/>
        </xsl:param>
        <xsl:param name="cavafyContributors" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/pb:pbcoreContributor"/>
        <xsl:param name="goodCavafyContributors" select="
            $cavafyContributors
            [pb:contributor/@ref[contains(., $validatingNameString)]]"/>
        <xsl:param name="badCavafyContributors" select="
            $cavafyContributors
            [not(pb:contributor/@ref[contains(., $validatingNameString)])]"/>
        <xsl:param name="message">
            <xsl:message select="'Extract names from cavafy url ', $cavafyURL"/>
        </xsl:param>
        <xsl:param name="namesExtracted">
            <xsl:call-template name="extractName">
                <xsl:with-param name="text">
                    <xsl:value-of select="$completeText"/>
                </xsl:with-param>
                <xsl:with-param name="eachNameRegex">([A-Z][A-Za-z\-’'\.]+ *)</xsl:with-param>                    
                <xsl:with-param name="textNoAcronyms" select="$completeText"/>
                <xsl:with-param name="guestIsInCAPS" select="false()"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="namesExtractedValid">
            <xsl:copy-of select="
                $namesExtracted/table/person/name[
                normalize-space()
                [matches(., '\w')]
                [matches(., ' ')]
                [string-length(.) gt 5]]"/>
        </xsl:param>
        <xsl:param name="namesExtractedAsPBCore">
            <xsl:for-each select="$namesExtractedValid/name">
                <pb:pbcoreContributor>
                    <pb:contributor>
                        <xsl:value-of select="normalize-space(.)"/>
                    </pb:contributor>
                    <pb:contributorRole>[fromText]</pb:contributorRole>
                </pb:pbcoreContributor>
            </xsl:for-each>
        </xsl:param>
        <xsl:param name="allContributorsToSearch" select="
            $badCavafyContributors, $namesExtractedAsPBCore"/>        
        
        <xsl:apply-templates select="." mode="findLoCContributor">
            <xsl:with-param name="cavafyURL" select="$cavafyURL"/>
            <xsl:with-param name="cavafyEntry" select="$cavafyEntry"/>            
            <xsl:with-param name="contributorsToSearch" select="$allContributorsToSearch"/>
            <xsl:with-param name="abstract" select="$completeText"/>
        </xsl:apply-templates>
        
    </xsl:template>
</xsl:stylesheet>