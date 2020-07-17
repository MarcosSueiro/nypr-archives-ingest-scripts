<?xml version="1.0" encoding="UTF-8"?>


<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:op="https://www.w3.org/TR/2017/REC-xpath-functions-31-20170321"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xsi:schemaLocation="http://www.pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:et="http://ns.exiftool.ca/1.0/"
    et:toolkit="Image::ExifTool 9.46" xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:XMP-x="http://ns.exiftool.ca/XMP/XMP-x/1.0/"
    xmlns:XMP-xmp="http://ns.exiftool.ca/XMP/XMP-xmp/1.0/"
    xmlns:XMP-xmpDM="http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/"
    xmlns:XMP-xmpMM="http://ns.exiftool.ca/XMP/XMP-xmpMM/1.0/"
    xmlns:XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/"
    xmlns:XMP-WNYCSchema="http://ns.exiftool.ca/XMP/XMP-WNYCSchema/1.0/"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#" exclude-result-prefixes="#all">

    <xsl:import href="Exif2html.xsl"/>
    


    <!--Gives line breaks etc-->
    <xsl:output name="email" encoding="UTF-8" method="html" html-version="5.0" indent="yes"/>


    <xsl:param name="todaysDate" select="xs:date(current-date())"/>
    <xsl:param name="publishDate" select="xs:date($todaysDate)"/>
    <xsl:param name="validatingSubjectString" select="'id.loc.gov'"/>

    <xsl:param name="baseURI" select="base-uri()"/>
    <xsl:param name="parsedBaseURI" select="analyze-string($baseURI, '/')"/>
    <xsl:param name="docFilename" select="$parsedBaseURI/fn:non-match[last()]"/>
    <xsl:param name="docFilenameNoExtension" select="substring-before($docFilename, '.')"/>
    <xsl:param name="baseFolder" select="'file:///T:/04 PROMOTION/biWeeklyEmails/'"/>
    <xsl:param name="logFolder" select="concat($baseFolder, 'instantiationUploadLOGS/')"/>
    <xsl:param name="currentTime"
        select="substring(translate(string(current-time()), ':', ''), 1, 4)"/>
    
    <!--Output definitions -->
    <xsl:template match="rdf:RDF">
        <xsl:variable name="filenameHtml"
            select="
                concat(
                $baseFolder,
                format-date($publishDate, '[Y0001][M01][D01]'),
                'EMAIL',
                'From',
                $docFilenameNoExtension,
                '.html')"/>
        <xsl:result-document format="email" href="{$filenameHtml}">
            <xsl:apply-templates select="." mode="html"/>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>
