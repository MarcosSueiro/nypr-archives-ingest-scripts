<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:XMP="http://ns.exiftool.ca/XMP/XMP/1.0/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="3.0">

    <xsl:import href="exif2NewExif.xsl"/>

    <xsl:output method="xml" indent="yes"/>

    <xsl:template match="rdf:RDF">
        <conformance_point_document>
            <xsl:apply-templates/>
        </conformance_point_document>
    </xsl:template>

    <xsl:template match="rdf:Description
        [ends-with(@rdf:about, '.DBX')]
        [XMP:EntriesEntryMotive]">
        <xsl:param name="theme" select="
            XMP:EntriesEntryMotive"/>
        <xsl:param name="wavTitle">
            <xsl:value-of select="
                XMP:EntriesEntryMediumFileTitle
                [matches(., '\.WAV', 'i')]" separator=" ; "/>
        </xsl:param> 
        <xsl:param name="archivesTheme" select="
            starts-with($theme, 'archive')"/>
        <xsl:param name="dbxURL" select="
                @rdf:about[ends-with(., '.DBX')]"/>       
        <xsl:param name="dbxData" select="
            document($dbxURL)"/>
        <xsl:param name="wavFilesInDbx" select="
            $dbxData/ENTRIES/ENTRY/
            MEDIUM/FILE[TYPE='Audio']"/>        
        <xsl:param name="wavFileCount" select="
            count($wavFilesInDbx)"/>
        <xsl:param name="wavURL">
            <xsl:value-of select="
                $wavFilesInDbx/
                FILEREF/translate(., '\', '/')" separator=" ; "/>            
        </xsl:param>
        <xsl:param name="cmsData">
            <xsl:if test="not($archivesTheme)">
                <xsl:call-template name="getCMSData">
                    <xsl:with-param name="theme" select="
                            encode-for-uri($theme)"/>
                    <xsl:with-param name="minRecords" select="0"/>
                    <xsl:with-param name="maxRecords" select="1"/>
                    <xsl:with-param name="exactMP3" select="true()"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:param>
        <xsl:param name="cmsResults" select="$cmsData/cmsData/meta/pagination/count"/>
        
        <xsl:choose>
            <xsl:when test="$wavFileCount gt 1">
                <error>
                    <xsl:attribute name="theme" select="$theme"/>
                    <xsl:attribute name="multipleWAVFiles">
                        <xsl:value-of select="
                                $wavFileCount,
                                'audio files referred to in dbx', $dbxURL, ':', $wavTitle"
                        />
                        <xsl:copy-of select="$dbxData"/>
                    </xsl:attribute>
                </error>
            </xsl:when>
            <xsl:when test="$wavFileCount lt 1">
                <error>
                    <xsl:attribute name="theme" select="$theme"/>
                    <xsl:attribute name="noWAVFiles">
                        <xsl:value-of select="
                                $wavFileCount,
                                'audio files referred to in dbx', $dbxURL"/>
                    </xsl:attribute>
                    <xsl:copy-of select="$dbxData"/>
                </error>
            </xsl:when>
            <xsl:when test="$cmsResults = '1'">                
                <File>
                    <xsl:attribute name="name" select="$wavURL"/>
                    <xsl:comment select="'Theme: ', $theme"/>
                    
                    <Core>
                        <xsl:call-template name="exifFiller">
                            <xsl:with-param name="cmsData" select="$cmsData"/>
                            <xsl:with-param name="dbxURL" select="$dbxURL"/>
                            <xsl:with-param name="dbxData" select="$dbxData"/>
                        </xsl:call-template>
                    </Core>
                </File>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>