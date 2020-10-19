<?xml version="1.0" encoding="ISO-8859-1"?>
<!-- Transform an exiftool xml
into an xml .DBX file suitable for ingest into D.A.V.I.D. -->
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
    xmlns:XMP-exif="http://ns.exiftool.ca/XMP/XMP-exif/1.0/"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:lc="http://www.loc.gov/"
    xmlns:skos="http://www.w3.org/2009/08/skos-reference/skos.html"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    exclude-result-prefixes="xsi rdf et ExifTool System File RIFF XMP-x XMP-xmp XMP-xmpDM XMP-xmpMM XMP-dc XMP-WNYCSchema Composite xi XMP-dc XMP-exif lc">



    <!--Output definitions -->
    <xsl:template match="rdf:RDF" mode="DAVID">
        <!-- Match top element -->
        <xsl:message select="'DAVID here we go'"/>
        <ENTRIES>
            <xsl:apply-templates select="rdf:Description"/>
        </ENTRIES>
    </xsl:template>

    <xsl:template match="rdf:Description" mode="DAVID">
        <!-- Process a file -->
        <xsl:variable name="filename" select="
                normalize-space(RIFF:Description)"/>
        <xsl:variable name="catalogURL">
            <xsl:value-of select="
                    normalize-space(RIFF:Source)"/>
        </xsl:variable>
        <xsl:variable name="instantiationDate"
            select="
                substring-before(System:FileCreateDate, ' ')"/>
        <xsl:variable name="instantiationDateMMDDYY"
            select="
                concat(
                substring($instantiationDate, 6, 2),
                substring($instantiationDate, 9, 2),
                substring($instantiationDate, 3, 2)
                )"/>

        <!--        Parse the DAVID Title-->
        <xsl:variable name="DAVIDTitleBeforeSpace">
            <xsl:value-of
                select="
                    analyze-string(RIFF:Description, ' ')/fn:non-match[1]"
            />
        </xsl:variable>

        <!--        First, the tokenized title-->
        <xsl:variable name="collectionAcronym">
            <xsl:value-of
                select="
                    analyze-string(
                    $DAVIDTitleBeforeSpace, '-')
                    /fn:non-match[1]"
            />
        </xsl:variable>
        <xsl:variable name="seriesAcronym">
            <xsl:value-of select="analyze-string($DAVIDTitleBeforeSpace, '-')/fn:non-match[2]"/>
        </xsl:variable>
        <xsl:variable name="parsedYear">
            <xsl:value-of select="analyze-string($DAVIDTitleBeforeSpace, '-')/fn:non-match[3]"/>
        </xsl:variable>
        <xsl:variable name="parsedMonth">
            <xsl:value-of select="analyze-string($DAVIDTitleBeforeSpace, '-')/fn:non-match[4]"/>
        </xsl:variable>
        <xsl:variable name="parsedDay">
            <xsl:value-of select="analyze-string($DAVIDTitleBeforeSpace, '-')/fn:non-match[5]"/>
        </xsl:variable>
        <xsl:variable name="DAVIDTitleDate">
            <xsl:value-of select="string-join(($parsedYear, $parsedMonth, $parsedDay), '-')"/>
        </xsl:variable>
        <xsl:variable name="DAVIDTitleDateTranslated"
            select="
                concat(
                translate(
                substring($DAVIDTitleDate, 1, 1),
                'u', '1'),
                translate(
                substring($DAVIDTitleDate, 2, 5),
                'u', '0'),
                translate(
                substring($DAVIDTitleDate, 7, 2),
                'u', '1'),
                translate(
                substring($DAVIDTitleDate, 9, 1),
                'u', '0'),
                translate(
                substring($DAVIDTitleDate, 10, 1),
                'u', '1')
                )"/>
        <xsl:variable name="instantiationID">
            <xsl:value-of select="analyze-string($DAVIDTitleBeforeSpace, '-')/fn:non-match[6]"/>
        </xsl:variable>
        <xsl:variable name="assetID">
            <xsl:value-of select="substring-before($instantiationID, '.')"/>
        </xsl:variable>
        <xsl:variable name="instantiationSuffix">
            <xsl:value-of select="substring-after($instantiationID, '.')"/>
        </xsl:variable>
        <xsl:variable name="freeText">
            <xsl:value-of
                select="
                    normalize-space(
                    substring-after(RIFF:Description, $DAVIDTitleBeforeSpace)
                    )"
            />
        </xsl:variable>
        <xsl:variable name="broadcastDate" select="RIFF:DateCreated"/>
        <xsl:variable name="broadcastDateTranslated"
            select="concat(translate(substring($broadcastDate, 1, 1), 'u', '1'), translate(substring($broadcastDate, 2, 5), 'u', '0'), translate(substring($broadcastDate, 7, 2), 'u', '1'), translate(substring($broadcastDate, 9, 1), 'u', '0'), translate(substring($broadcastDate, 10, 1), 'u', '1'))"/>
        <xsl:variable name="originalMedium" select="normalize-space(RIFF:Medium)"/>
        <xsl:variable name="theme">
            <xsl:choose>
                <xsl:when test="contains($freeText, 'ACLIP')">
                    <xsl:value-of
                        select="concat('archives', $instantiationDateMMDDYY, '_clip_from_', $assetID, '_', substring-after($instantiationID, '.'))"
                    />
                </xsl:when>
                <xsl:when
                    test="
                        matches(
                        $freeText, $segmentFlags
                        )
                        and contains($freeText, 'WEB EDIT')">
                    <xsl:variable name="matchedSegmentFlag">
                        <xsl:value-of
                            select="
                                analyze-string($freeText, $segmentFlags)
                                /fn:match
                                "/>
                    </xsl:variable>
                    <xsl:value-of
                        select="
                            concat(
                            'archives',
                            $instantiationDateMMDDYY, '_',
                            lower-case($matchedSegmentFlag),
                            '_from_', $assetID, '_', $instantiationSuffix)"
                    />
                </xsl:when>
                <xsl:when test="contains($filename, ' WEB EDIT')">
                    <xsl:value-of select="concat('archive_import', $assetID)"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="cmsURL"
            select="concat('http://audio.wnyc.org/archive_import', $theme, '.mp3')"/>

        <xsl:variable name="subjectNames">
            <xsl:value-of
                select="
                    document(
                    analyze-string(RIFF:Keywords, ';')/
                    fn:non-match[contains(., 'id.loc.gov')]/
                    concat(normalize-space(.), '.rdf')
                    )/
                    rdf:RDF/madsrdf:*/madsrdf:authoritativeLabel"
                separator=" ; "/>
        </xsl:variable>

        <xsl:variable name="sampleRate" select="
                normalize-space(RIFF:SampleRate)"/>
        <xsl:variable name="dbxURL">
            <xsl:choose>
                <xsl:when test="ends-with(System:FileName, '.WAV')">
                    <xsl:value-of select="concat(substring-before(System:FileName, '.WAV'), '.DBX')"
                    />
                </xsl:when>
                <xsl:when test="ends-with(System:FileName, '.wav')">
                    <xsl:value-of select="concat(substring-before(System:FileName, '.wav'), '.DBX')"
                    />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dbxFile" select="document($dbxURL[doc-available(.)])"/>
        <xsl:variable name="softDeleted" select="$dbxFile/ENTRIES/ENTRY/SOFTDELETED"/>

        <xsl:variable name="performerNames">
            <xsl:value-of
                select="
                    document(
                    analyze-string(
                    string-join((RIFF:Commissioned, RIFF:Artist), ' ; '),
                    ';')/
                    fn:non-match[contains(., 'id.loc.gov')]/
                    concat(normalize-space(.), '.rdf')
                    )/
                    rdf:RDF/madsrdf:*/madsrdf:authoritativeLabel"
                separator=" ; "/>
        </xsl:variable>

        <xsl:variable name="publisherNames">
            <xsl:value-of
                select="
                    document(
                    analyze-string(RIFF:Commissioned, ';')/
                    fn:non-match[contains(., 'id.loc.gov')]/
                    concat(normalize-space(.), '.rdf')
                    )/
                    rdf:RDF/madsrdf:*/madsrdf:authoritativeLabel"
                separator=" ; "/>
        </xsl:variable>

        <!-- DBX OUTPUT -->
        <xsl:choose>
            <xsl:when test="$sampleRate = ''">
                <xsl:message terminate="yes" select="'UNKNOWN SAMPLE RATE'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>
        <xsl:value-of select="
                            concat(
                            '***********************ONLY ', $sampleRate, ' FILES!!!!!!!!!!',
                            '***********************ONLY ', $sampleRate, ' FILES!!!!!!!!!!',
                            '***********************ONLY ', $sampleRate, ' FILES!!!!!!!!!!',
                            '***********************ONLY ', $sampleRate, ' FILES!!!!!!!!!!',
                            '***********************ONLY ', $sampleRate, ' FILES!!!!!!!!!!',
                            '***********************ONLY ', $sampleRate, ' FILES!!!!!!!!!!'
                            )"/>
    </xsl:comment>
                <ENTRY>
                    <CLASS>Audio</CLASS>
                    <xsl:comment select="concat('SAMPLE RATE: ', $sampleRate)"/>
                    <TITLE>
                        <xsl:choose>
                            <xsl:when test="contains($filename, '.wav')">
                                <xsl:value-of
                                    select="substring-before($filename, concat('.', 'wav'))"/>
                            </xsl:when>
                            <xsl:when test="contains($filename, '.WAV')">
                                <xsl:value-of
                                    select="substring-before($filename, concat('.', 'WAV'))"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$filename"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </TITLE>
                    <FILENAME>
                        <xsl:value-of select="concat(System:Directory, '/', System:FileName)"/>
                    </FILENAME>
                    <DATE>
                        <xsl:value-of select="$DAVIDTitleDateTranslated"/>
                    </DATE>
                    <TIME>00:00:00</TIME>
                    <TIMESTAMP>
                        <xsl:value-of select="normalize-space(RIFF:DateTimeOriginal)"/>
                    </TIMESTAMP>
                    <xsl:if test="contains($freeText, ' WEB EDIT') or contains($freeText, ' ACLIP')">
                        <READY>1</READY>
                    </xsl:if>
                    <PERFECT>1</PERFECT>
                    <PROGRAM>
                        <xsl:value-of select="normalize-space(RIFF:Product)"/>
                    </PROGRAM>
                    <SUBJECT>
                        <xsl:value-of select="normalize-space(RIFF:Genre)"/>
                    </SUBJECT>
                    <RESSORT>
                        <xsl:value-of select="normalize-space(RIFF:Genre)"/>
                    </RESSORT>
                    <BROADCASTDATE>
                        <xsl:value-of select="$broadcastDateTranslated"/>
                    </BROADCASTDATE>
                    <AUTHOR>
                        <xsl:value-of select="normalize-space(RIFF:Technician)"/>
                    </AUTHOR>
                    <EDITOR>
                        <xsl:value-of select="normalize-space(RIFF:Technician)"/>
                    </EDITOR>
                    <SOURCE>
                        <xsl:value-of select="normalize-space(RIFF:Medium)"/>
                    </SOURCE>
                    <KEYWORDS>
                        <!-- This field accepts up to 99 characters -->

                        <xsl:choose>
                            <xsl:when test="string-length($subjectNames) gt 99">
                                <xsl:variable name="trimmedSubjects"
                                    select="substring($subjectNames, 1, 99)"/>
                                <xsl:call-template name="substring-before-last">
                                    <xsl:with-param name="input" select="$trimmedSubjects"/>
                                    <xsl:with-param name="substr" select="';'"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$subjectNames"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </KEYWORDS>
                    <REMARK>
                        <xsl:value-of select="concat(RIFF:Subject, '&#xA;')"/>
                        <xsl:if
                            test="(RIFF:CodingHistory) and not(contains(RIFF:CodingHistory, 'D.A.V.I.D.'))">
                            <xsl:value-of
                                select="concat('Technical info: ', RIFF:CodingHistory, '&#xA;')"/>
                        </xsl:if>
                        <xsl:value-of select="concat('Comment: ', RIFF:Comment, '&#xA;')"/>
                    </REMARK>
                    <BITRATE>
                        <xsl:value-of select="RIFF:BitsPerSample"/>
                    </BITRATE>
                    <TYPE>Raw Audio</TYPE>
                    <xsl:if test="$theme ne ''">
                        <MOTIVE>
                            <xsl:value-of select="$theme"/>
                        </MOTIVE>
                    </xsl:if>
                    <GENERICTITLE>
                        <xsl:value-of select="normalize-space(RIFF:Title)"/>
                    </GENERICTITLE>
                    <PERFORMER>
                        <xsl:value-of select="$performerNames"/>
                    </PERFORMER>
                    <ALBUM>
                        <xsl:value-of select="normalize-space(RIFF:Product)"/>
                    </ALBUM>
                    <DISTRIBUTION>
                        <xsl:value-of select="normalize-space(RIFF:Copyright)"/>
                    </DISTRIBUTION>
                    <CDINFO>
                        <GENRE>
                            <xsl:value-of select="normalize-space(RIFF:Genre)"/>
                        </GENRE>
                        <PUBLISHER>
                            <xsl:value-of select="$publisherNames"/>
                        </PUBLISHER>
                    </CDINFO>
                    <USA>
                        <WNYC>
                            <CATALOG>
                                <xsl:value-of select="$catalogURL"/>
                            </CATALOG>
                            <xsl:if test="normalize-space(XMP-dc:Coverage)">
                                <LOCATION>
                                    <xsl:value-of
                                        select="concat(substring-before(substring-after(XMP-dc:Coverage, '@'), ','), ', ', substring-before(substring-after(substring-after(XMP-dc:Coverage, '@'), ','), ','))"
                                    />
                                </LOCATION>
                            </xsl:if>
                            <xsl:if test="normalize-space(XMP-xmpDM:Lyrics)">
                                <TRANSCRIPT>
                                    <xsl:value-of select="XMP-xmpDM:Lyrics"/>
                                </TRANSCRIPT>
                            </xsl:if>
                            <TYPE>
                                <xsl:value-of select="'Raw Audio'"/>
                            </TYPE>
                        </WNYC>
                    </USA>
                </ENTRY>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>





</xsl:stylesheet>
