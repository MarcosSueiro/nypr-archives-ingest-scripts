<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
    
    <xsl:output indent="yes"/>
    <xsl:mode on-no-match="shallow-copy"/>
    <xsl:import href="file:/T:/02%20CATALOGING/Instantiation%20uploads/nypr-archives-ingest-scripts/currentTemplates/cavafySearch.xsl"/>
    
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
            <xsl:attribute name="numberofIDs" select="count($DAVIDInstantiationIDsNotInCavafy/instantiationID)"/>
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
    
</xsl:stylesheet>