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
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all">

    <xsl:mode on-no-match="deep-skip"/>
    <!-- Format XMP markers into text -->

    
    
    <xsl:template name="hoursInSeconds">
        <xsl:param name="timeSec"/>
        <xsl:value-of
            select="
            format-number(
            floor($timeSec div 3600),
            '00'
            )"
        />
    </xsl:template>
    <xsl:template name="minutesInSeconds">
        <xsl:param name="timeSec"/>
        <xsl:value-of
            select="
            format-number(
            floor(
            (
            $timeSec
            mod 3600)
            div 60),
            '00'
            )"
        />
    </xsl:template>
    <xsl:template name="secondsLeft">
        <xsl:param name="timeSec"/>
        <xsl:value-of
            select="
            format-number(
            floor(
            (
            $timeSec
            mod 3600
            ) mod 60
            ),
            '00'
            )"
        />
    </xsl:template>
    <xsl:template name="secondsToTimecode">
        <xsl:param name="timeSec"/>
        <xsl:param name="hours">
            <xsl:call-template name="hoursInSeconds">
                <xsl:with-param name="timeSec" select="$timeSec"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="minutes">
            <xsl:call-template name="minutesInSeconds">
                <xsl:with-param name="timeSec" select="$timeSec"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="seconds">
            <xsl:call-template name="secondsLeft">
                <xsl:with-param name="timeSec" select="$timeSec"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:value-of select="concat($hours, ':', $minutes, ':', $seconds)"/>
    </xsl:template>
    
    <xsl:template match="XMP-xmpDM:Tracks" mode="tracksToText">
        <xsl:param name="xmpTracks" select="."/>
        <xsl:param name="frameRate" select="
            number(
            substring-after(
            $xmpTracks/rdf:Bag/rdf:li[@rdf:parseType='Resource'][1]/
            XMP-xmpDM:FrameRate, 'f'))[. &gt; 0][1]"/>
        <xsl:param name="markerCount" select="
            count(
            $xmpTracks/rdf:Bag/rdf:li[@rdf:parseType='Resource']/
            XMP-xmpDM:Markers/
            rdf:Bag/rdf:li[@rdf:parseType='Resource']
            )"/>
        <xsl:message>
            <xsl:value-of select="
                concat($markerCount, ' markers found')"/>
        </xsl:message>
        <xsl:apply-templates select="
            $xmpTracks/rdf:Bag/rdf:li[@rdf:parseType='Resource']/
            XMP-xmpDM:Markers">
            <xsl:with-param name="frameRate" select="
                $frameRate[. &gt; 0]"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="XMP-xmpDM:Markers">
        <xsl:param name="frameRate"
            select="
                number(
                substring-after(
                preceding-sibling::XMP-xmpDM:FrameRate, 'f'))
                [. &gt; 0]"/>
        
        <xsl:message>
            <xsl:value-of select="concat('Frame rate: ', $frameRate)"/>
        </xsl:message>
        <xsl:apply-templates select="
            rdf:Bag/rdf:li[@rdf:parseType = 'Resource']">
            <xsl:with-param name="frameRate" select="$frameRate"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="
            XMP-xmpDM:Markers/rdf:Bag/rdf:li[@rdf:parseType = 'Resource']">
        <xsl:param name="frameRate"
            select="
                number(
                substring-after(
                ../../preceding-sibling::XMP-xmpDM:Markers,
                'f')
                )"/>
        <xsl:param name="markerName" select="XMP-xmpDM:Name"/>
        <xsl:param name="timeSamples" select="
            if (contains(XMP-xmpDM:StartTime, 'f')) 
            then 
            number(substring-before(XMP-xmpDM:StartTime, 'f')) 
            else 
            number(XMP-xmpDM:StartTime)"/>
        <xsl:param name="startTimeFrameRate" select="
            if (contains(XMP-xmpDM:StartTime, 'f')) 
            then 
            number(substring-after(XMP-xmpDM:StartTime, 'f')) 
            else 
            $frameRate"/>
        <xsl:param name="timeSec"
            select="
                xs:integer(
                $timeSamples div $startTimeFrameRate
                )"/>
        <xsl:param name="startTimeCode">
            <xsl:call-template name="secondsToTimecode">
                <xsl:with-param name="timeSec" select="$timeSec"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="durationSamples" select="
            if (contains(XMP-xmpDM:Duration, 'f')) 
            then 
            number(substring-before(XMP-xmpDM:Duration, 'f')) 
            else 
            number(XMP-xmpDM:Duration)"/>
        <xsl:param name="durationFrameRate" select="
            if (contains(XMP-xmpDM:Duration, 'f')) 
            then 
            number(substring-after(XMP-xmpDM:Duration, 'f')) 
            else 
            $frameRate"/>
        <xsl:param name="durationSec"
            select="
                number($durationSamples[. &gt; 0] div $durationFrameRate)"/>
        <xsl:param name="durationMinutes" select="
                number($durationSec div 60)"/>

        <xsl:value-of select="'&#xA;'"/>
        <xsl:value-of select="concat($startTimeCode, ' - ', $markerName)"/>
        <xsl:value-of
            select="concat(' ', '(', format-number($durationMinutes, '##.#'), ' m)')[$durationMinutes &gt; 0.99]"/>
    </xsl:template>
    
    
    
    
</xsl:stylesheet>
