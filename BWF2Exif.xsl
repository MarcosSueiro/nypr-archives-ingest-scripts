<?xml version="1.1" encoding="UTF-8"?>
<!--Transform output from BWF Metaedit
    and output an exiftool-type xml.-->


<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:XMP-exif="http://ns.exiftool.ca/XMP/XMP-exif/1.0/" xmlns:lc="http://www.loc.gov/"
    xmlns="http://purl.org/dc/elements/1.1/" xmlns:XML="http://ns.exiftool.ca/XML/XML/1.0/"
    xmlns:default="http://www.w3.org/1999/xhtml" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xsi xi lc #default fn xhtml rdf XMP-WNYCSchema XMP-exif XML">

    <!--Gives line breaks etc-->
        <xsl:output encoding="UTF-8" method="xml" version="1.0" indent="yes"/>

    <xsl:template match="conformance_point_document" mode="BWFMetaEdit">
        <!-- Transform Core document from BWF MetaEdit -->
        <rdf:RDF namespace="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <xsl:apply-templates select="File" mode="BWFMetaEdit"/>
        </rdf:RDF>
    </xsl:template>

    <xsl:template match="File" mode="BWFMetaEdit">
        <!-- Transform each WAVE file -->
        <xsl:param name="fullFilename" select="@name"/>
        <xsl:param name="fullFilenameTranslated" select="translate(@name, '\', '/')"/>
        <xsl:param name="parsedFullFilename" select="analyze-string($fullFilenameTranslated, '/')"/>
        <xsl:param name="filename" select="$parsedFullFilename/fn:non-match[last()]"/>
        <xsl:param name="token" select="'.'"/>
        <xsl:param name="directory" select="substring-before($fullFilenameTranslated, $filename)"/>

        <xsl:param name="filenameNoExtensionRaw"
            select="
                if ($token)
                then
                    if (contains($filename, $token)) then
                        string-join(tokenize($filename, $token, 'q')
                        [position() ne last()], $token)
                    else
                        ''
                else
                    $filename"/>
        <xsl:param name="filenameExtension"
            select="
                substring-after(
                substring-after($filename, $filenameNoExtensionRaw),
                $token)"/>

        <rdf:Description>
            <xsl:attribute name="rdf:about">
                <xsl:value-of select="$fullFilenameTranslated"/>
            </xsl:attribute>
            <xsl:attribute name="et:toolkit">
                <xsl:value-of select="'Image::ExifTool 11.69'"/>
            </xsl:attribute>
            <xsl:comment select="'A new exiftool xml generated from', $filename"/>
            <System:FileName>
                <xsl:value-of select="$filename"/>
            </System:FileName>
            <System:Directory>
                <xsl:value-of select="substring(
                    $directory, 
                    1, 
                    string-length($directory)-1
                    )"/>
            </System:Directory>
            <File:FileType>
                <xsl:value-of select="upper-case($filenameExtension)"/>
            </File:FileType>
            <File:FileTypeExtension>
                <xsl:value-of select="lower-case($filenameExtension)"/>
            </File:FileTypeExtension>

            <RIFF:Artist>
                <xsl:value-of select="normalize-space(Core/IART)"/>
            </RIFF:Artist>
            <RIFF:Commissioned>
                <xsl:value-of select="normalize-space(Core/ICMS)"/>
            </RIFF:Commissioned>
            <RIFF:Copyright>
                <xsl:value-of select="normalize-space(Core/ICOP)"/>
            </RIFF:Copyright>
            <RIFF:DateCreated>
                <xsl:value-of select="fn:translate(Core/ICRD, '-', ':')"/>
            </RIFF:DateCreated>
            <RIFF:Engineer>
                <xsl:value-of select="normalize-space(Core/IENG)"/>
            </RIFF:Engineer>
            <RIFF:Genre>
                <xsl:value-of select="normalize-space(Core/IGNR)"/>
            </RIFF:Genre>
            <RIFF:Keywords>
                <xsl:value-of select="normalize-space(Core/IKEY)"/>
            </RIFF:Keywords>
            <RIFF:Medium>
                <xsl:value-of select="normalize-space(Core/IMED)"/>
            </RIFF:Medium>
            <RIFF:Software>
                <xsl:value-of select="normalize-space(Core/ISFT)"/>
            </RIFF:Software>
            <RIFF:Source>
                <xsl:value-of select="normalize-space(Core/ISRC)"/>
            </RIFF:Source>
            <RIFF:Technician>
                <xsl:value-of select="normalize-space(Core/ITCH)"/>
            </RIFF:Technician>
            <RIFF:ArchivalLocation>
                <xsl:value-of select="normalize-space(Core/IARL)"/>
            </RIFF:ArchivalLocation>
            <RIFF:Comment>
                <xsl:value-of select="normalize-space(Core/ICMT)"/>
            </RIFF:Comment>
            <RIFF:Title>
                <xsl:value-of select="normalize-space(Core/INAM)"/>
            </RIFF:Title>
            <RIFF:Product>
                <xsl:value-of select="normalize-space(Core/IPRD)"/>
            </RIFF:Product>
            <RIFF:Subject>
                <xsl:value-of select="normalize-space(Core/ISBJ)"/>
            </RIFF:Subject>
            <RIFF:SourceForm>
                <xsl:value-of select="normalize-space(Core/ISRF)"/>
            </RIFF:SourceForm>
            <RIFF:Description>
                <xsl:value-of select="normalize-space(Core/Description)"/>
            </RIFF:Description>
            <RIFF:Originator>
                <xsl:choose>
                    <xsl:when test="normalize-space(Core/Originator) ne ''">
                        <xsl:value-of select="normalize-space(Core/Originator)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space(Core/ITCH)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </RIFF:Originator>
            <xsl:if test="Core/OriginatorReference">
                <RIFF:OriginatorReference>
                    <xsl:value-of select="normalize-space(Core/OriginatorReference)"/>
                </RIFF:OriginatorReference>
            </xsl:if>
            <RIFF:DateTimeOriginal>
                <xsl:value-of select="translate(Core/ICRD, '-', ':'), '00:00:00'"/>
            </RIFF:DateTimeOriginal>
            <RIFF:TimeReference>
                <xsl:value-of select="normalize-space(Core/TimeReference)"/>
            </RIFF:TimeReference>
            <RIFF:BWFVersion>
                <xsl:value-of select="normalize-space(Core/BextVersion)"/>
            </RIFF:BWFVersion>
            <xsl:if test="Core/UMID">
                <RIFF:BWF_UMID>
                    <xsl:value-of select="normalize-space(Core/UMID)"/>
                </RIFF:BWF_UMID>
            </xsl:if>
            <RIFF:CodingHistory>
                <xsl:value-of select="normalize-space(Core/CodingHistory)"/>
            </RIFF:CodingHistory>
            <XMP-xmp:CreatorTool>
                <xsl:value-of select="normalize-space(Core/ISFT)"/>
            </XMP-xmp:CreatorTool>
            <XMP-xmp:CreateDate>
                <xsl:value-of
                    select="translate(Core/OriginationDate, '-', ':'), Core/OriginationTime"/>
            </XMP-xmp:CreateDate>
            <XMP-xmp:MetadataDate>
                <xsl:value-of
                    select="format-dateTime(fn:current-dateTime(), '[Y0001]:[M01]:[D01] [H01]:[m01]:[s01][Z]')"
                />
            </XMP-xmp:MetadataDate>
            <XMP-xmpDM:Artist>
                <xsl:value-of select="normalize-space(Core/IART)"/>
            </XMP-xmpDM:Artist>
            <XMP-xmpDM:Engineer>
                <xsl:value-of select="normalize-space(Core/IENG)"/>
            </XMP-xmpDM:Engineer>
            <XMP-xmpDM:Genre>
                <xsl:value-of select="normalize-space(Core/IGNR)"/>
            </XMP-xmpDM:Genre>

            <XMP-dc:Rights>
                <xsl:value-of select="normalize-space(Core/ICOP)"/>
            </XMP-dc:Rights>
            <XMP-dc:Source>
                <xsl:value-of select="normalize-space(Core/IMED)"/>
            </XMP-dc:Source>
            <XMP-dc:Subject>
                <xsl:variable name="parsedKeywords" select="fn:analyze-string(Core/IKEY, ';')"/>
                <rdf:Bag>
                    <xsl:for-each select="$parsedKeywords/fn:non-match">
                        <rdf:li>
                            <xsl:value-of select="normalize-space(.)"/>
                        </rdf:li>
                    </xsl:for-each>
                </rdf:Bag>
            </XMP-dc:Subject>
            <XML:BwfxmlBextBwfOriginationDate>
                <xsl:value-of select="Core/OriginationDate"/>
            </XML:BwfxmlBextBwfOriginationDate>
            <XML:BwfxmlBextBwfOriginationTime>
                <xsl:value-of select="Core/OriginationTime"/>
            </XML:BwfxmlBextBwfOriginationTime>
            <XML:BwfxmlBextBwfVersion>
                <xsl:value-of select="Core/BextVersion"/>
            </XML:BwfxmlBextBwfVersion>
            <XML:BwfxmlBextBwfCodingHistory>
                <xsl:value-of select="Core/CodingHistory"/>
            </XML:BwfxmlBextBwfCodingHistory>
        </rdf:Description>
    </xsl:template>
</xsl:stylesheet>
