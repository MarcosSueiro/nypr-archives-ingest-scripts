<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
    <xsl:output indent="1"/>
    <xsl:template match="urbanAbstracts">
        <pbcoreCollection
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <xsl:apply-templates/>
        </pbcoreCollection>
    </xsl:template>
    <xsl:template match="entry">
        <pbcoreDescriptionDocument>
            <xsl:apply-templates/>
        </pbcoreDescriptionDocument>
    </xsl:template>
    <xsl:template match="audioFile">
        <pbcoreTitle titleType="Collection">WNYC</pbcoreTitle>
        <pbcoreIdentifier source="WNYC Archive Catalog">
            <xsl:value-of select="tokenize(tokenize(tokenize(., ' ')[1], '-')[6], '\.')[1]"/>
        </pbcoreIdentifier>
    </xsl:template>
    <xsl:template match="transcript">
        <pbcoreDescription descriptionType="Abstract">
            <xsl:value-of select="."/>
        </pbcoreDescription>
    </xsl:template>
    
</xsl:stylesheet>