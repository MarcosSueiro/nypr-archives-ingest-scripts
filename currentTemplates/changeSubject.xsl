<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:et="http://ns.exiftool.ca/1.0/"
    xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/"
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:XMP-x="http://ns.exiftool.ca/XMP/XMP-x/1.0/"
    xmlns:XMP-xmp="http://ns.exiftool.ca/XMP/XMP-xmp/1.0/"
    xmlns:XMP-xmpDM="http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/"
    xmlns:XMP-xmpMM="http://ns.exiftool.ca/XMP/XMP-xmpMM/1.0/"
    xmlns:XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/"
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
     exclude-result-prefixes="#all"
    version="3.0">
    
    <xsl:output encoding="UTF-8" method="xml" indent="yes"/>
    
    
    <xsl:template match="/completeLog/
        DAVIDWavInstantiationsFromArchivesResults">
        <conformance_point_document>
         
        
        <xsl:apply-templates select="result
            [newExif/rdf:Description/RIFF:Subject[error]]"/>
        </conformance_point_document>
    </xsl:template>
    
    <xsl:template match="result        
        [newExif/rdf:Description/RIFF:Subject[error]]">
        <xsl:element name="File">
            <xsl:attribute name="name">
                <xsl:value-of select="translate(newExif/rdf:Description/@rdf:about, '/', '\')"/>
            </xsl:attribute>
        
        <Core>
            <ISBJ>
        
                <xsl:value-of select="inputs/cavafyEntry/pb:pbcoreDescriptionDocument/pb:pbcoreDescription[@descriptionType='Abstract']"/>
        
            </ISBJ>
        </Core>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>