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
    version="3.0">
    
    <xsl:output encoding="UTF-8" method="text"/>
    
    
    <xsl:template match="
        /completeLog/
        DAVIDWavInstantiationsFromArchivesResults">
        
        <xsl:value-of select="'instantiationID, provenance'"/> 
        
        <xsl:apply-templates select="result
            [newExif/rdf:Description/RIFF:SourceForm[error]]"></xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="
        /completeLog/
        DAVIDWavInstantiationsFromArchivesResults/
        result
        [newExif/rdf:Description/RIFF:SourceForm[error]]">
        <xsl:variable name="provenance">
            <xsl:value-of select="newExif/rdf:Description/RIFF:SourceForm/node()[not(self::error)]"/>
        </xsl:variable> 
        <xsl:value-of select="'&#10;&#13;'"/>
        <xsl:value-of select="inputs/parsedDAVIDTitle/parsedElements/pb:instantiationData/pb:pbcoreInstantiation/pb:instantiationIdentifier[@source='pbcore XML database UUID']"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="normalize-space($provenance)"/>
            
        
        
        
    </xsl:template>
</xsl:stylesheet>