<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#' 
    xmlns:XMP='http://ns.exiftool.ca/XMP/XMP/1.0/'
    version="3.0">
    <xsl:output indent="true"/>
    <xsl:template match="rdf:RDF">
        <xsl:apply-templates select="
            rdf:Description
            [matches(XMP:EntriesEntryMediumFileTitle[2], 'Cat#|-\d{5,6}(\.|-)|_\d{5,6}(\.|-)', 'i')]
            [not (matches(XMP:EntriesEntryMediumFileTitle[2], ' - CD'))]"/>
    </xsl:template>
    
    <xsl:template match="rdf:Description">
        <xsl:copy>
            <xsl:copy-of select="XMP:EntriesEntryMediumFileTitle[2]"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>