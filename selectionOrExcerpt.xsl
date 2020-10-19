<?xml version="1.0" encoding="UTF-8"?>
<!-- Format XMP markers into text such as
    
Edited file timings:
00:00:00 - Intro (.49 m)

00:00:00 - Intro
00:26:00 - end hour
00:26:00 - Intro (.49 m)

00:26:00 - Intro
00:52:00 - Marker 22
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
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
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/" exclude-result-prefixes="#all">

    <xsl:template
        match="
            XMP-xmpDM:Tracks
            /rdf:Bag
            /rdf:li[@rdf:parseType = 'Resource']
            /XMP-xmpDM:Markers
            /rdf:Bag
            /rdf:li[@rdf:parseType = 'Resource']">
        <!-- Format XMP markers into text -->
        <xsl:param name="frameRate"
            select="
                number(
                substring-after(
                /rdf:RDF/rdf:Description
                /*[local-name() = 'Tracks']
                /rdf:Bag
                /rdf:li
                /*[local-name() = 'FrameRate']
                , 'f'
                ))"/>
        <xsl:message>
            <xsl:value-of select="'Frame rate is ', $frameRate"/>
        </xsl:message>
        <xsl:choose>
            <xsl:when test="contains(XMP-xmpDM:StartTime, 'f')">
                <xsl:variable name="startHours">
                    <xsl:value-of
                        select="
                            format-number(
                            floor(
                            (substring-before(
                            XMP-xmpDM:StartTime, 'f'
                            )
                            div
                            substring-after(XMP-xmpDM:StartTime, 'f')
                            ) div 3600),
                            '00'
                            )"
                    />
                </xsl:variable>
                <xsl:variable name="startMinutes">
                    <xsl:value-of
                        select="
                            format-number(
                            floor(
                            (
                            (substring-before(XMP-xmpDM:StartTime, 'f')
                            div
                            substring-after(XMP-xmpDM:StartTime, 'f')
                            ) mod 3600)
                            div 60),
                            '00'
                            )"
                    />
                </xsl:variable>
                <xsl:variable name="startSeconds">
                    <xsl:value-of
                        select="
                            format-number(
                            floor(
                            (
                            (substring-before(XMP-xmpDM:StartTime, 'f')
                            div substring-after(XMP-xmpDM:StartTime, 'f')
                            ) mod 3600
                            ) mod 60
                            ),
                            '00'
                            )"
                    />
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="normalize-space(XMP-xmpDM:Duration)">
                        <xsl:value-of
                            select="
                                concat(
                                $startHours, ':',
                                $startMinutes, ':',
                                $startSeconds
                                )"/>
                        <xsl:value-of select="' - '"/>
                        <xsl:value-of select="XMP-xmpDM:Name"/>
                        <xsl:value-of select="' ('"/>
                        <xsl:value-of
                            select="
                                format-number((
                                (substring-before(XMP-xmpDM:Duration, 'f')
                                div
                                substring-after(XMP-xmpDM:Duration, 'f'))
                                div 60),
                                '#.##'
                                )"/>
                        <xsl:value-of select="' m)&#xA;'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of
                            select="
                            concat(
                            $startHours, ':', 
                            $startMinutes, ':', 
                            $startSeconds, ' - ', 
                            XMP-xmpDM:Name, 
                            '&#xA;')"
                        />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="startHours">
                    <xsl:value-of
                        select="
                        format-number(
                        floor(
                        (XMP-xmpDM:StartTime div $frameRate) 
                        div 3600), 
                        '00')"
                    />
                </xsl:variable>
                <xsl:variable name="startMinutes">
                    <xsl:value-of
                        select="
                        format-number(
                        floor((
                        (XMP-xmpDM:StartTime div $frameRate) 
                        mod 3600) 
                        div 60), 
                        '00')"
                    />
                </xsl:variable>
                <xsl:variable name="startSeconds">
                    <xsl:value-of
                        select="
                        format-number(
                        floor((
                        (XMP-xmpDM:StartTime div $frameRate) 
                        mod 3600) 
                        mod 60), 
                        '00')"
                    />
                </xsl:variable>
                <xsl:if test="normalize-space(XMP-xmpDM:Duration)">
                    <xsl:choose>
                        <xsl:when test="contains(XMP-xmpDM:Duration, 'f')">
                            <xsl:value-of
                                select="
                                concat(
                                $startHours, ':', 
                                $startMinutes, ':', 
                                $startSeconds)"
                            />
                            <xsl:value-of select="' - '"/>
                            <xsl:value-of select="XMP-xmpDM:Name"/>
                            <xsl:value-of select="' ('"/>
                            <xsl:value-of
                                select="format-number((
                                (substring-before(XMP-xmpDM:Duration, 'f') 
                                div substring-after(XMP-xmpDM:Duration, 'f')
                                ) div 60), 
                                '#.##')"
                            />
                            <xsl:value-of select="' m)&#xA;'"/>
                            </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of
                                select="
                                concat(
                                $startHours, ':', 
                                $startMinutes, ':', 
                                $startSeconds
                                )"
                            />
                            <xsl:value-of select="' - '"/> 
                            <xsl:value-of select="XMP-xmpDM:Name"/>
                            <xsl:value-of select="' ('"/>
                            <xsl:value-of
                                select="format-number(
                                (XMP-xmpDM:Duration div $frameRate) 
                                div 60, 
                                '#.##')"
                            />
                            <xsl:value-of select="' m)&#xA;'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:value-of
                    select="
                    concat(
                    $startHours, ':', 
                    $startMinutes, ':', 
                    $startSeconds, ' - ', 
                    XMP-xmpDM:Name, 
                    '&#xA;')"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
