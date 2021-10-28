<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
    
    <xsl:output method="xml" indent="yes"/>
    
    <!-- Get rid of unnecessary assets 
    for upload -->
    
    <xsl:param name="currentTime" select="format-dateTime(current-dateTime(),'[Y][M][D][h][m][s]')"/>
    
    <xsl:template match="pb:pbcoreCollection">
        <xsl:param name="filename" select="concat('NYACBeta_', $currentTime, '.xml')"/>
        <xsl:result-document href="{$filename}">
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
        </xsl:result-document>
    </xsl:template>
    <xsl:template match="pb:pbcoreDescriptionDocument">
        <xsl:copy-of select=".[pb:pbcoreSubject|pb:pbcoreContributor]"/>
    </xsl:template>
</xsl:stylesheet>