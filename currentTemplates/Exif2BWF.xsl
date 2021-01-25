<?xml version="1.0" encoding="UTF-8"?>
    <!-- Convert Exif to BWF MetaEdit Core document, 
    suitable for import -->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:et="http://ns.exiftool.ca/1.0/"
    et:toolkit="Image::ExifTool 10.82" xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/" exclude-result-prefixes="#all">

    <xsl:output name="FADGI" encoding="UTF-8" method="xml" version="1.0" standalone="yes"
        indent="yes"/>
    
    <xsl:variable name="illegalCharacters">
        <xsl:text>&#x201c;&#x201d;&#xa0;&#x80;&#x93;&#x94;&#xa6;&#x2014;&#x2019;</xsl:text>
        <xsl:text>&#xc2;&#xc3;&#xb1;&#xe2;&#x99;&#x9c;&#x9d;</xsl:text>
    </xsl:variable>
    <xsl:variable name="legalCharacters">
        <xsl:text>"" '——…—'</xsl:text>
    </xsl:variable>

    <xsl:template match="rdf:RDF" mode="ixmlFiller">
        <!-- Match top level element -->
        <conformance_point_document>
            <xsl:apply-templates select="rdf:Description" mode="ixmlFiller"/>
        </conformance_point_document>
    </xsl:template>

    <xsl:template match="rdf:Description" name="ixmlFiller" mode="ixmlFiller">
        <!-- Process each WAVE file -->
        
        <!-- CORE OUTPUT -->
        <File name="{@rdf:about}">
            <Core>
                <xsl:element name="Description">
                    <xsl:value-of select="
                        normalize-space(RIFF:Description)"/>
                </xsl:element>

                <!-- NOTE: Do not trust BEXT's Originator,
                    as it conflicts with DAVID's "Author" -->
                <xsl:element name="Originator">
                    <xsl:value-of select="RIFF:Originator"/>
                </xsl:element>

                <!--NOTE: Originator Reference is too small (32 char) 
                    to be used for storing cavafy UUIDs -->
                <OriginatorReference>  
                    <xsl:value-of select="RIFF:OriginatorReference"/>
                </OriginatorReference>

                <CodingHistory>
                    <xsl:value-of select="RIFF:CodingHistory"/>
                </CodingHistory>
                <IARL>
                    <xsl:value-of select="normalize-space(RIFF:ArchivalLocation)"/>
                    <xsl:text>&#013;</xsl:text>
                </IARL>
                <IART>
                    <xsl:value-of select="normalize-space(RIFF:Artist)"/>
                    <xsl:text>&#013;</xsl:text>
                </IART>
                <ICMS>
                    <xsl:value-of select="normalize-space(RIFF:Commissioned)"/>
                    <xsl:text>&#013;</xsl:text>
                </ICMS>
                <ICMT>
                    <xsl:variable name="endsWithParagraph" select="ends-with(RIFF:Comment, '&#032;')"/>
                    <xsl:value-of select="RIFF:Comment"/>
                <xsl:value-of select="'&#032;'[not($endsWithParagraph)]"/>
                </ICMT>
                <ICOP>
                    <xsl:variable name="endsWithParagraph" select="ends-with(RIFF:Copyright, '&#032;')"/>
                <xsl:value-of select="RIFF:Copyright"/>
                    <xsl:value-of select="'&#032;'[not($endsWithParagraph)]"/>                    
                </ICOP>
                <ICRD>
                    <xsl:value-of select="normalize-space(RIFF:DateCreated)"/>
                </ICRD>
                <IENG>
                    <xsl:value-of select="normalize-space(RIFF:Engineer)"/>
                    <xsl:text>&#013;</xsl:text>
                </IENG>
                <IGNR>
                    <xsl:value-of select="normalize-space(RIFF:Genre)"/>
                    <xsl:text>&#013;</xsl:text>
                </IGNR>
                <IKEY>
                    <xsl:value-of select="normalize-space(RIFF:Keywords)"/>
                    <xsl:text>&#013;</xsl:text>
                </IKEY>
                <IMED>
                    <xsl:value-of select="normalize-space(RIFF:Medium)"/>
                    <xsl:text>&#013;</xsl:text>
                </IMED>
                <INAM>
                    <xsl:value-of select="normalize-space(RIFF:Title)"/>
                    <xsl:text>&#013;</xsl:text>
                </INAM>
                <IPRD>
                    <xsl:value-of select="normalize-space(RIFF:Product)"/>
                    <xsl:text>&#013;</xsl:text>
                </IPRD>
                <ISBJ>
                    <xsl:variable name="endsWithParagraph" select="ends-with(RIFF:Subject, '&#032;')"/>
                    <xsl:value-of select="RIFF:Subject"/>
                <xsl:value-of select="'&#032;'[not($endsWithParagraph)]"/>
                </ISBJ>

                <xsl:element name="ISFT">
                    <xsl:value-of select="normalize-space(RIFF:Software)"/>
                    <xsl:text>&#013;</xsl:text>
                </xsl:element>

                <ISRC>
                    <xsl:value-of select="normalize-space(RIFF:Source)"/>
                    <xsl:text>&#013;</xsl:text>
                </ISRC>
                <ISRF>
                    <xsl:value-of select="normalize-space(RIFF:SourceForm)"/>
                    <xsl:text>&#013;</xsl:text>
                </ISRF>
                <ITCH>
                    <xsl:value-of select="normalize-space(RIFF:Technician)"/>
                    <xsl:text>&#013;</xsl:text>
                </ITCH>
            </Core>
        </File>
    </xsl:template>
</xsl:stylesheet>
