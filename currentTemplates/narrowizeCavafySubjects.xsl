<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html">

    
    <xsl:import href="masterRouter.xsl"/>
    
    <xsl:param name="searchString"
        select="
        'https://cavafy.wnyc.org/?facet_Series+Title%5B%5D=World+Trade+Center+Attack&amp;q=%22world+trade+center+attack%22'"/>
    <xsl:param name="copyNonLoCSH" select="true()"/>
    
    
    <xsl:template match="/">
        <xsl:param name="eachURL">
            <xsl:call-template name="checkResult">
                <xsl:with-param name="searchString" select="$searchString"/>
                <!--<xsl:with-param name="pageNumber" select="1"/>-->
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="urls">
            <urls>
                <xsl:copy-of select="$eachURL/pb:searchResults/pb:url"/>
            </urls>
        </xsl:param>
        <xsl:apply-templates select="$urls" mode="narrowizeSubjects"/>
    </xsl:template>

    <xsl:template match="urls" mode="narrowizeSubjects">
        <xsl:variable name="originalPbcoreCollection">
            <xsl:call-template name="generatePbCoreCollection">
                <xsl:with-param name="urls">
                    <xsl:value-of select=".//*:url" separator=" ; "/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="pbcoreCollectionNarrowSH">
            <xsl:copy select="
                $originalPbcoreCollection/pb:pbcoreCollection">
                <xsl:apply-templates
                    select="$originalPbcoreCollection/pb:pbcoreCollection/pb:pbcoreDescriptionDocument[pb:pbcoreSubject]"
                    mode="narrowizeSubjects"/>
            </xsl:copy>
        </xsl:variable>
        <xsl:variable name="originalPbcoreCollectionImportReady">
            <xsl:apply-templates select="
                $originalPbcoreCollection/pb:pbcoreCollection"
                mode="importReady"/>
        </xsl:variable>
        <xsl:variable name="narrowSHImportReady">
            <xsl:apply-templates select="
                $pbcoreCollectionNarrowSH/pb:pbcoreCollection"
                mode="importReady"/>
        </xsl:variable>
        <xsl:apply-templates select="
            $originalPbcoreCollection/pb:pbcoreCollection" mode="breakItUp">
            <xsl:with-param name="maxOccurrences" select="100"/>
            <xsl:with-param name="breakupDocBaseURI" select="
                'file:/T:/02%20CATALOGING/Instantiation%20uploads/instantiationUploadLOGS/OriginalSubjects.xml'"/>
                        
        </xsl:apply-templates>
        <xsl:apply-templates select="
            $narrowSHImportReady/pb:pbcoreCollection" mode="breakItUp">
            <xsl:with-param name="maxOccurrences" select="100"/>
            <xsl:with-param name="breakupDocBaseURI" select="
                'file:/T:/02%20CATALOGING/Instantiation%20uploads/NarrowSubjects.xml'"/>
            
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="
        pb:pbcoreDescriptionDocument" mode="narrowizeSubjects">
        <xsl:variable name="validatingKeywordString" select="'id.loc.gov/authorities/subjects/'"/>
        <xsl:variable name="validatingNameString" select="'id.loc.gov/authorities/names/'"/>
        <xsl:variable name="validatingHubString" select="'id.loc.gov/resources/hubs/'"/>
        <xsl:variable name="combinedValidatingStrings"
            select="
            string-join(($validatingKeywordString, $validatingNameString, $validatingHubString), '|')"/>
        
        <xsl:copy>
            <xsl:copy-of
                select="
                    *[following-sibling::pb:pbcoreSubject]
                    [not(self::pb:pbcoreSubject)]"/>
            <xsl:variable name="narrowSubjects">
                <xsl:call-template name="narrowSubjects">
                    <xsl:with-param name="subjectsToProcess">
                        <xsl:value-of select="
                            pb:pbcoreSubject
                            [matches(@ref, $combinedValidatingStrings)]/
                            @ref" separator=" ; "/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:variable>
            <xsl:apply-templates select="$narrowSubjects" mode="LOCtoPBCore"/>
            <xsl:copy-of select="
                pb:pbcoreSubject
                [not(matches(@ref, $combinedValidatingStrings)) or not(@ref)][$copyNonLoCSH]"/>
            <xsl:copy-of
                select="
                    *[preceding-sibling::pb:pbcoreSubject]
                    [not(self::pb:pbcoreSubject)]"
            />
        </xsl:copy>
    </xsl:template>


</xsl:stylesheet>