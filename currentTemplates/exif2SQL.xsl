<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
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
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    
    <!-- Transform an exiftool input
    to a document that pretends to be 
    a MySQL search from cavafy -->
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:template match="rdf:RDF">
        <pma_xml_export version="1.0" xmlns:pma="https://www.phpmyadmin.net/some_doc_url/">
            <database name="cavafy-prod">
                <xsl:apply-templates select="rdf:Description"/>
            </database>
        </pma_xml_export>
    </xsl:template>
    
    
    <xsl:template match="rdf:Description">
        <table name="descriptions">
            <column name="URL">
                <xsl:value-of select="RIFF:Source"/>
            </column>
        </table>
    </xsl:template>

</xsl:stylesheet>


