<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
    
    <xsl:output indent="yes"/>
    <xsl:mode on-no-match="shallow-copy"/>
    <xsl:import href="masterRouter.xsl"/>
    
    <xsl:template match="instantiationIDs">
        <xsl:param name="findInstantiationResults">
            <xsl:copy>
                <xsl:apply-templates select="instantiationID">
                    <xsl:sort select="number(substring-before(., '.'))"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:param>
        <xsl:param name="DAVIDInstantiationIDsNotInCavafy">
            <xsl:copy select="$findInstantiationResults">
                <xsl:copy-of select="instantiationIDs/
                    instantiationID[not(pb:instantiationData/pb:pbcoreInstantiation)]"/>
            </xsl:copy>
        </xsl:param> 
        <DAVIDInstantiationIDsNotInCavafy>
            <xsl:attribute name="numberOfIDs" select="count($DAVIDInstantiationIDsNotInCavafy/instantiationID)"/>
            <xsl:copy-of
                select="$DAVIDInstantiationIDsNotInCavafy"
            />
        </DAVIDInstantiationIDsNotInCavafy>
    </xsl:template>
    
    <xsl:template match="instantiationID">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:value-of select="."/>
            <xsl:call-template name="findInstantiation">
                <xsl:with-param name="instantiationID" select="."/>
                <xsl:with-param name="format" select="'wav'"/>
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="DAVIDInstantiationIDsNotInCavafy">
        <xsl:apply-templates select="instantiationID[pb:instantiationData/pb:error][1]" mode="getDBX"/>
    </xsl:template>
    
    <xsl:template match="instantiationID" mode="getDBX">
        <xsl:param name="instantiationID" select="."/>
        <xsl:param name="dbxData" select="doc($instantiationID/@dbxFilename)"/>
        <xsl:apply-templates select="$dbxData/ENTRIES/ENTRY[SOFTDELETED = '0']" mode="createPBCoreInstantiation"/>
    </xsl:template>
    
    <xsl:template match="ENTRY" mode="createPBCoreInstantiation">
        <xsl:param name="checkedDAVIDTitle">
        <xsl:call-template name="checkDAVIDTitle">
            <xsl:with-param name="filenameToCheck" select="MEDIUM/FILE[TYPE='Audio']/TITLE"/>
            <xsl:with-param name="DAVIDTitleToCheck" select="TITLE"/>            
        </xsl:call-template>
        </xsl:param>
        <xsl:call-template name="parseDAVIDTitle">
            <xsl:with-param name="checkedDAVIDTitle" select="$checkedDAVIDTitle"></xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
</xsl:stylesheet>