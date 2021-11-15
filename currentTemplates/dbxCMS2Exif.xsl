<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#' 
    xmlns:XMP='http://ns.exiftool.ca/XMP/XMP/1.0/'
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
    
    <xsl:import href="exif2NewExif.xsl"/>
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:template match="rdf:RDF">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="rdf:Description[ends-with(@rdf:about, '.DBX')][XMP:EntriesEntryMotive]">
        <xsl:param name="dbxURL">
            <xsl:value-of select="concat('file://', @rdf:about)"/>
        </xsl:param>
        <xsl:param name="dbxData" select="document($dbxURL)"/>
        <xsl:param name="cmsData">
            <xsl:call-template name="getCMSData">
                <xsl:with-param name="theme" select="XMP:EntriesEntryMotive"/>
            </xsl:call-template>
        </xsl:param>
        <!--<xsl:copy-of
            select="json-to-xml(unparsed-text('http://api.wnyc.org/api/v3/story/?audio_file=%2Fotm110521_cms1148380_pod.mp3'))"/>-->
        
        <xsl:call-template name="exifFiller">
            <xsl:with-param name="cmsData" select="$cmsData"/>
            <xsl:with-param name="dbxURL" select="$dbxURL"/>
            <xsl:with-param name="dbxData" select="$dbxData"/>
        </xsl:call-template>
    </xsl:template>
</xsl:stylesheet>