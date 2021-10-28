<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:XMP="http://ns.exiftool.ca/XMP/XMP/1.0/"
    xmlns:XMP-xmp="http://ns.exiftool.ca/XMP/XMP-xmp/1.0/"
    xmlns:XMP-xmpDM="http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/"
    xmlns:XMP-xmpMM="http://ns.exiftool.ca/XMP/XMP-xmpMM/1.0/"
    xmlns:XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/" 
    xmlns:WNYC="http://www.wnyc.org"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:op="http://www.w3.org/2002/08/xquery-operators"
    xmlns:ASCII="https://www.ecma-international.org/publications/standards/Ecma-094.htm"
    exclude-result-prefixes="#all"
    version="3.0">
    
    <!-- This stylesheet embeds NewsBoss metadata into DAVID WAV files -->
    <!-- Source: exiftool listing of DBX files, e.g. 
     	exiftool -ext dbx -if "$FileModifyDate ge '2018:09:15'" -EntriesEntryMotive -EntriesEntryMediumFileTitle -X [directory] > [output.xml] 
         Matches to: NewsBoss .htm exports by year
    -->
    
    <!-- *************ENTER YEAR TO PROCESS HERE****************** -->    
    <xsl:variable name="yearToProcess" select="2012"/>

    <xsl:output name="LOG" encoding="UTF-8" method="xml" version="1.0" standalone="yes"
        indent="yes"/>
    <xsl:output name="DAVID" encoding="ISO-8859-1" method="xml" version="1.0" indent="yes"/>
    <xsl:output method="xml" indent="yes"/>

    <xsl:mode name="parseNewscastText" on-no-match="shallow-copy"/>
    <xsl:mode name="parseNewscast" on-no-match="deep-skip"/>
    <xsl:mode name="formatDate" on-no-match="deep-skip"/>
    <xsl:mode on-no-match="deep-skip"/>
    
    <xsl:include href="processLoCURL.xsl"/>
    
    <xsl:variable name="baseURI" select="base-uri()"/> 
    <xsl:variable name="currentDate" select="format-dateTime(current-dateTime(), '[Y0001][M01][D01]')"/>
    <xsl:variable name="currentDateTime" select="format-dateTime(current-dateTime(), '[Y0001][M01][D01]h[h01]')"/>
    
    <xsl:variable name="newsBossDateFormat" select="
        '\d{1,2}/\d{1,2}/\d{4} \d{2}:\d{2}'"/>
    <xsl:variable name="NewsBossStoryDivider"
        select="'-{30,}|\[STORY\]|\[WEATHER\]|\[WX\]|\[CUT/COPY\]|\[COPY\]|\[[0-9]\]'"
    />
    <xsl:variable name="newscastTimeFormat" select="
        '\d{1,2}:\d{2} (am|pm)'"/>
    <xsl:variable name="DAVIDTitleNewscastFormat" select="
        'WNYC-NWSC-\d{4}-\d{2}-\d{2} \d{2}h\d{2}m'"/>

    <xsl:variable name="illegalCharacters">
        <!--        <xsl:text>&#x2019;  </xsl:text>-->
        <xsl:text>&#x201c;&#x201d;&#xa0;&#x80;&#x93;&#x94;&#xa6;&#x2014;&#x2019;</xsl:text>
        <xsl:text>&#xc2;&#xc3;&#xb1;&#xe2;&#x99;&#x9c;&#x9d;</xsl:text>
    </xsl:variable>
    <xsl:variable name="legalCharacters">
        <xsl:text>"" '——…—'</xsl:text>
    </xsl:variable>
    <xsl:variable name="weatherFlag" select="'WEATHER|WX'"/>

    <xsl:template match="rdf:RDF">
        <xsl:message select="concat('Directory: ', $baseURI)"/>
        <xsl:variable name="logFilename"
            select="
                concat(
                substring-before($baseURI, '.'),
                '_LOG',
                'year', $yearToProcess, '_',
                $currentDateTime, '.xml')"
        />
        <xsl:variable name="FADGIFilename"
            select="
                concat(
                substring-before($baseURI, '.'),
                '_forFADGI',
                'year', $yearToProcess, '_',
                $currentDate,
                '.xml')"
        />
        <xsl:variable name="completeLog">
            <xsl:element name="newsBossLog">
                <xsl:apply-templates
                    select="
                        rdf:Description
                        [XMP:EntriesEntryMotive = 'news_latest_newscast'
                        or
                        contains(XMP:EntriesEntryTitle, '-NWSC-')]"
                    mode="newsBoss"/>
            </xsl:element>
        </xsl:variable>
        <xsl:result-document format="LOG" href="{$logFilename}">
            <xsl:copy-of select="$completeLog"/>
        </xsl:result-document>
        <xsl:result-document format="LOG" href="{$FADGIFilename}">
            <conformance_point_document>
                <xsl:apply-templates
                    select="
                        $completeLog/
                        newsBossLog/
                        matchedNews
                        [matches(newscastTitle, '\w')]"
                    mode="matchedNews2FADGI"/>
            </conformance_point_document>
        </xsl:result-document>
    </xsl:template>

    <xsl:template match="rdf:Description" mode="newsBoss">
        <xsl:param name="DBXurl" select="@rdf:about"/>
        <xsl:param name="DBXData" select="document($DBXurl)"/>
        <xsl:param name="DAVIDTitle"
            select="
                if (XMP:EntriesEntryTitle) then
                    XMP:EntriesEntryTitle
                else
                    $DBXData/ENTRIES/ENTRY[1]/TITLE"
        />
            
        <xsl:param name="theme"
            select="
                if (XMP:EntriesEntryMotive) then
                    XMP:EntriesEntryMotive
                else
                    $DBXData/ENTRIES/ENTRY[1]/MOTIVE"
        />            
        <xsl:message select="('Theme: ', $theme)"/>
        <xsl:message select="'Title: ', $DAVIDTitle"/>
        <xsl:if test="matches($DAVIDTitle, $DAVIDTitleNewscastFormat)">
            <xsl:variable name="DAVIDDateTimeString"
                select="
                    substring($DAVIDTitle, 11)"/>
            <xsl:variable name="DAVIDDate"
                select="
                    xs:date(substring($DAVIDDateTimeString, 1, 10))"/>
            <xsl:variable name="DAVIDTime">
                <xsl:value-of
                    select="
                        xs:time(concat(
                        substring($DAVIDDateTimeString, 12, 2),
                        ':',
                        substring($DAVIDDateTimeString, 15, 2),
                        ':00'))"
                />
            </xsl:variable>
            <xsl:variable name="DAVIDDateTime"
                select="
                    xs:dateTime(
                    concat(
                    $DAVIDDate,
                    'T',
                    $DAVIDTime))"/>
            <xsl:variable name="DAVIDDateTimeNewsBossFormat">
                <xsl:value-of
                    select="
                        format-dateTime(
                        $DAVIDDateTime,
                        '[M1]/[D1]/[Y0001] [H]:[m01]:[s01]'
                        )"
                />
            </xsl:variable>
            <xsl:variable name="newscastTime">
                <xsl:value-of
                    select="
                        format-number(hours-from-time($DAVIDTime), '00')"/>
                <xsl:value-of select="':04:00'"/>
            </xsl:variable>
            <xsl:variable name="newscastTimeFormatted">
                <xsl:value-of
                    select="
                        translate(
                        format-time(
                        xs:time($newscastTime),
                        '[h]:[m01] [Pn]'
                        ),
                        '.', '')"
                />
            </xsl:variable>
            <xsl:message
                select="
                    'Newscast time: ',
                    $newscastTimeFormatted"/>
            <xsl:variable name="
            DAVIDDateHourToMatch">
                <xsl:value-of
                    select="
                        format-dateTime(
                        $DAVIDDateTime,
                        '[M1]/[D1]/[Y0001] ( )?[H]:'
                        )"
                />
            </xsl:variable>
            <xsl:variable name="
                DAVIDDateToMatch">                
                <xsl:value-of
                    select="
                        format-dateTime(
                        $DAVIDDateTime,
                        '[M1]/[D1]/[Y0001]'
                        )"
                />
            </xsl:variable>
            <xsl:variable name="archiveDateStringToMatch">
                <xsl:value-of select="'Archived at '"/>
                <xsl:value-of select="$DAVIDDateToMatch"/>
            </xsl:variable>

            <xsl:message select="'Date and hour to match:', $DAVIDDateHourToMatch"/>
            <xsl:variable name="DBXLengthString"
                select="
                    $DBXData/ENTRIES/ENTRY[1]/LENGTH[1]"/>
            <xsl:variable name="DBXDurationInSeconds">
                <xsl:value-of
                    select="
                        $DBXData/ENTRIES/ENTRY[1]/DURATION[1]
                        div
                        1000"
                />
            </xsl:variable>
            <xsl:variable name="newscastYear"
                select="
                    year-from-dateTime($DAVIDDateTime)"/>
            <xsl:if test="$newscastYear = $yearToProcess">
                <xsl:variable name="minimumDurationInSeconds">
                    <xsl:value-of select="120.0"/>
                </xsl:variable>
                <xsl:variable name="shortAudio" as="xs:boolean"
                    select="$DBXDurationInSeconds lt $minimumDurationInSeconds"/>
                <xsl:variable name="wavURL"
                    select="
                        concat(substring-before($DBXurl, '.DBX'), '.WAV')"/>

                <!-- NewsBoss htm files are named by year -->
                <xsl:variable name="newsBossBaseURI"
                    select="'file:/T:/02 CATALOGING/NewsBoss/newsBossData/'"/>
                <xsl:variable name="newsBossFileToCheck"
                    select="
                        concat($newscastYear, 'newscasts', '.htm')"/>
                <xsl:variable name="newsBossCompleteURI"
                    select="concat($newsBossBaseURI, $newsBossFileToCheck)"/>
                <xsl:variable name="newsBossHtml"
                    select="
                        document($newsBossCompleteURI)"/>

                <!-- Find newscasts by Archive date
                and broadcast hour -->
                <xsl:variable name="matchedNewsByArchDateBcastHour"
                    select="
                        $newsBossHtml/HTML/BODY/TABLE/TR/TD/A[starts-with(@NAME, 'SLUG')]/P
                        [matches(archiveDate, $archiveDateStringToMatch)]
                        [contains(H3, $newscastTimeFormatted)]"/>
                <xsl:variable name="matchedNewsByArchDateBcastHourCount"
                    select="
                        count($matchedNewsByArchDateBcastHour)"/>

                <xsl:message
                    select="
                        $matchedNewsByArchDateBcastHourCount,
                        ' matched scripts by archive date and broadcast hour',
                        $DAVIDDateToMatch, ': ',
                        $matchedNewsByArchDateBcastHour/archiveDate"/>

                <!-- Matched newscasts archived in that hour
                (normally the most reliable version) -->
                <xsl:variable name="matchedNewsArchivedWithinTheHour"
                    select="
                        $matchedNewsByArchDateBcastHour
                        [matches(archiveDate, $DAVIDDateHourToMatch)]"/>
                <xsl:variable name="matchedNewsArchivedWithinTheHourCount"
                    select="
                        count($matchedNewsArchivedWithinTheHour)"/>

                <xsl:message
                    select="
                        $matchedNewsArchivedWithinTheHourCount,
                        ' matched scripts archived within the hour ',
                        $DAVIDDateHourToMatch, ': ',
                        $matchedNewsArchivedWithinTheHour/archiveDate"/>

                <!-- If no newscast matched within the hour, use last available -->
                <xsl:variable name="finalMatchedNews"
                    select="
                        if ($matchedNewsArchivedWithinTheHourCount = 1)
                        then
                            $matchedNewsArchivedWithinTheHour[1]
                        else
                            $matchedNewsByArchDateBcastHour[last()]"
                />

                <xsl:variable name="stories"
                    select="
                        analyze-string(
                        $finalMatchedNews, $NewsBossStoryDivider, 'i')/
                        fn:non-match[position() gt 1][matches(., '\w')]"/> <!-- There is a divider right at the top -->
                <xsl:message select="concat('DAVID Date Time String: ', $DAVIDDateTimeString)"/>
                <xsl:message
                    select="concat('DAVID Date Time as NB: ', $DAVIDDateTimeNewsBossFormat)"/>
                
                <xsl:message select="concat('Final matched News: ', $finalMatchedNews)"/>

                <xsl:element name="matchedNews">
                    <xsl:attribute name="matches" select="$matchedNewsByArchDateBcastHourCount"/>
                    <xsl:attribute name="href" select="$wavURL"/>
                    <xsl:attribute name="DAVIDTitle" select="$DAVIDTitle"/>
                    <xsl:attribute name="isShort" select="$shortAudio"/>
                    <xsl:attribute name="numberOfStories"
                        select="
                            count($stories)"/>
                    <xsl:attribute name="length" select="$DBXLengthString"/>

                    <xsl:apply-templates select="$finalMatchedNews">
                        <xsl:with-param name="newscastDate" select="$DAVIDDate" tunnel="yes"/>
                    </xsl:apply-templates>
                    <dbxData>
                        <xsl:copy-of select="$DBXData"/>
                    </dbxData>
                </xsl:element>
            </xsl:if>
        </xsl:if>
    </xsl:template>
     
    <xsl:template match="P" mode="addArchDateISO">
        <xsl:param name="archiveDate" select="archiveDate"/>
        <xsl:variable name="extractedArchiveDateISO">
            <xsl:apply-templates select="substring($archiveDate, 12, 29)" mode="formatDate"/>
        </xsl:variable> 
        <xsl:copy>
            <archiveDateISO>
                <xsl:value-of select="$extractedArchiveDateISO"/>
            </archiveDateISO>
            <xsl:copy-of select="*"/>        
        </xsl:copy>
    </xsl:template>

    <xsl:template match="P">
        <xsl:apply-templates mode="parseNewscast"/>
        <xsl:copy-of select="archiveDate"/>
        <xsl:variable name="newsCastText">
            <xsl:apply-templates select="." mode="parseNewscastText"/>
        </xsl:variable>
        <xsl:call-template name="parseNewsCastText">
            <xsl:with-param name="newsCastText" select="$newsCastText"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="H3" mode="parseNewscast">
        <xsl:param name="newscastDate" select="xs:date('0000-01-01')" tunnel="yes"/>
        <xsl:variable name="newscastTime">
            <xsl:value-of select="."/>
        </xsl:variable>
        <newscastTitle>
            <xsl:value-of select="."/>
        </newscastTitle> 
        <newscastDate>
            <xsl:value-of select="$newscastDate"/>
        </newscastDate>
        <xsl:variable name="newscastTime">
            <xsl:apply-templates select="$newscastTime" mode="formatNewscastTime"/>
        </xsl:variable>
        <newscastTime>
            <xsl:value-of select="$newscastTime"/>
        </newscastTime>
    </xsl:template>
    
    <xsl:template match="H4" mode="parseNewscast">        
        <newscastRetrieved>
            <xsl:value-of select="."/>
        </newscastRetrieved>
        <xsl:variable name="newscastRetrievedISO">
            <xsl:apply-templates select="substring-after(., 'Moved: ')[matches(., $newsBossDateFormat)]" mode="formatDate"/>
        </xsl:variable>
    </xsl:template>
    
    <xsl:template match="H4|H3|archiveDate" mode="parseNewscastText"/>
    
    <xsl:template match="br" mode="parseNewscastText">
        <xsl:value-of select="'&#x0D;&#x0A;'"/>
    </xsl:template>
    
    <xsl:template name="parseNewsCastText">
        <xsl:param name="newsCastText" select="."/>
        <xsl:param name="stories" select="
            analyze-string(
            $newsCastText, $NewsBossStoryDivider)/
            fn:non-match[position() gt 1][matches(., '\w')]" tunnel="yes"/>
        <newscastCode>
            <xsl:value-of select="normalize-space(tokenize($newsCastText, $NewsBossStoryDivider)[1])"/>
        </newscastCode>
        <xsl:apply-templates
            select="
                $stories"
            mode="
            parseStory"/>
    </xsl:template>
    
    <xsl:template name="parseStory" match="." mode="parseStory">
        <xsl:param name="storyText" select="."/>
        
        <xsl:param name="storyType" select="preceding-sibling::fn:match[1]"/>
        <xsl:param name="storySlug">
            <xsl:value-of
                select="normalize-space(substring-after(analyze-string($storyText, 'Slug: .+&#xD;')/fn:match[1], 'Slug: '))"
            />
        </xsl:param>
        <xsl:param name="storyMoved"
            select="normalize-space(substring-after(analyze-string($storyText, 'Moved: .+&#xD;')/fn:match[1], 'Moved: '))"/>
        <xsl:param name="emptyText" select="
            not(matches($storyText, '\w'))"/>
        <story>
            <xsl:attribute name="storyType"
                select="
                    if (matches($storyType, $weatherFlag, 'i')
                    or matches($storySlug, $weatherFlag, 'i')
                    )
                    then
                        'WEATHER'
                    else
                        'STORY'"
            />
                <storyNumber>
                <xsl:value-of
                    select="substring-after(analyze-string($storyText, 'Story [0-9]')/fn:match[1], 'Story ')"
                />
            </storyNumber>
            <slug>
                <xsl:value-of
                    select="normalize-space(substring-after(analyze-string($storyText, 'Slug: .+&#xD;')/fn:match[1], 'Slug: '))"
                />
            </slug>
            <writer>
                <xsl:value-of
                    select="normalize-space(substring-after(analyze-string($storyText, 'Writer: .+&#xD;')/fn:match[1], 'Writer: '))"
                />
            </writer>
            <sub>
                <xsl:value-of
                    select="normalize-space(substring-after(analyze-string($storyText, 'Sub: .+&#xD;')/fn:match[1], 'Sub: '))"
                />
            </sub>            
            <storyText>
                <xsl:value-of select="'[No text available]'[$emptyText]"/>
                <xsl:value-of
                    select="analyze-string($storyText, 'Moved: .+&#xD;')/fn:non-match[last()]"/>
            </storyText>
            <relatedFiles>
                <xsl:apply-templates
                    select="analyze-string($storyText, '\[CutID:.+&#xD;&#x0A;Time: .+s&#xD;&#x0A;Title: .+&#xD;&#x0A;Out-cue: .*')/fn:match"
                    mode="parseDAVIDCut"/>
            </relatedFiles>
            <storyMovedISO>
                <xsl:apply-templates select="$storyMoved[matches(., $newsBossDateFormat)]"
                    mode="formatDate"/>
            </storyMovedISO>
        </story>
    </xsl:template>
    
    <xsl:template match="." name="formatDate" mode="formatDate">
        <xsl:param name="dateTime" select=".[matches(., $newsBossDateFormat)]"/>
        <xsl:param name="dateTimeTokenized" select="tokenize($dateTime, ' ')"/>
        <xsl:param name="date" select="$dateTimeTokenized[1]"/>
        <xsl:param name="time" select="$dateTimeTokenized[2]"/>
        <xsl:param name="dateTokenized" select="tokenize($date, '/')"/>
        <xsl:param name="year" select="$dateTokenized[3]"/>
        <xsl:param name="month" select="$dateTokenized[1]"/>
        <xsl:param name="day" select="$dateTokenized[2]"/>
        <xsl:param name="ISODate">
            <xsl:value-of select="format-number(number($year), '0000')"/>
            <xsl:value-of select="'-'"/>
            <xsl:value-of select="format-number(number($month), '00')"/>
            <xsl:value-of select="'-'"/>
            <xsl:value-of select="format-number(number($day), '00')"/>
            <xsl:value-of select="'T'"/>
            <xsl:value-of select="$time"/>
            <xsl:value-of select="':'"/>
            <xsl:value-of select="'00'"/>
        </xsl:param>
        <xsl:value-of select="($ISODate)"/>
    </xsl:template>
    
    <xsl:template match="text()" mode="parseDAVIDCut">
        <xsl:param name="DAVIDCutInfo" select="."/>
        <xsl:variable name="DAVIDCutInfoParsed" select="analyze-string($DAVIDCutInfo, '\[.+\]{1}?')"/>
        <xsl:variable name="DAVIDCutFileInfo" select="analyze-string($DAVIDCutInfo, '\[CutID: .+')"/>
        
        <xsl:variable name="DAVIDCutText" select="$DAVIDCutInfoParsed/fn:match"/>
        <xsl:variable name="DAVIDFilename">
            <xsl:value-of select="normalize-space(analyze-string($DAVIDCutInfo, '\[CutID:.+\.(WAV|mp3)', 'i')/fn:match/substring-after(., 'DAVID:DigaSystem\NEWS&gt;'))"/>
        </xsl:variable>
        <relatedFile>
            <xsl:attribute name="DAVIDFilename" select="$DAVIDFilename"/>
            <time>
                <xsl:copy-of select="substring-after(analyze-string($DAVIDCutFileInfo, 'Time: [0-9]+s{1}?')/fn:match[1], 'Time: ')"/>
            </time>
            <DAVIDCutTitle>
                <xsl:value-of select="substring-after(analyze-string($DAVIDCutFileInfo, 'Title: .+')/fn:match, 'Title: ')"/>
            </DAVIDCutTitle>
            <DAVIDCutText>
                <xsl:value-of select="normalize-space(translate($DAVIDCutText, '[]', ''))"/>
            </DAVIDCutText>
        </relatedFile>
    </xsl:template>
    
    <xsl:template name="formatNewscastTime" match="text()" mode="formatNewscastTime">
        <xsl:param name="newscastTime" select="normalize-space(string(.)[matches(., $newscastTimeFormat)])"/>
        <xsl:param name="newscastTimeTokenized" select="tokenize($newscastTime, ' ')"/>
        <xsl:param name="newscastTimeNumbers" select="$newscastTimeTokenized[1]"/>        
        <xsl:param name="newscastTimeHour" select="number(tokenize($newscastTimeNumbers, ':')[1])"/>
        <xsl:param name="newscastTimeMinutes" select="number(tokenize($newscastTimeNumbers, ':')[2])"/>
        <xsl:param name="newscastTimeSeconds" select="number(0)"/>
        <xsl:param name="newscastTimeMeridianum" select="$newscastTimeTokenized[2]"/>
        <xsl:param name="newscastTimeHourISO" select="if (matches($newscastTimeMeridianum, 'pm', 'i') and $newscastTimeHour lt 12)
            then $newscastTimeHour + 12
            else $newscastTimeHour"/> 
        <xsl:param name="completeTime">
            <xsl:value-of select="format-number($newscastTimeHourISO, '00')"/>
            <xsl:value-of select="':'"/>
            <xsl:value-of select="format-number($newscastTimeMinutes, '00')"/>
            <xsl:value-of select="':'"/>
            <xsl:value-of select="format-number($newscastTimeSeconds, '00')"/>
        </xsl:param>
        <xsl:value-of select="$completeTime"/>
    </xsl:template>
    
    <xsl:template match="matchedNews" mode="matchedNews2FADGI">
        <xsl:param name="matchedNews" select="."/>
        <xsl:param name="wavData" select="dbxData/ENTRIES/ENTRY[CLASS = 'Audio']"/>
        <xsl:param name="relatedFilesExist" select="story/relatedFiles[relatedFile]"/>
        <File>
            <xsl:attribute name="name" select="@href"/>
            <Core>
                <Description>
                    <xsl:value-of select="$wavData/TITLE"/>
                </Description>
                <Originator>
                    <xsl:value-of select="$wavData/CREATOR"/>
                </Originator>
                <IARL>US, WNYC&#xD;</IARL>
                <IART>
                    <xsl:value-of select="
                        distinct-values(story/sub[. != ''])" separator=" ; "/>
                    <xsl:value-of select="'&#xD;'"/>
                </IART>
                <ICMS><xsl:value-of select="
                    distinct-values(story/writer[. != ''])" separator=" ; "/>
                    <xsl:value-of select="'&#xD;'"/>
                </ICMS>
                <ICMT>
                    <xsl:value-of select="'Related files: '[$relatedFilesExist]"/>
                    <xsl:for-each select="story/relatedFiles/relatedFile">
                        <xsl:value-of select="@DAVIDFilename"/>
                        <xsl:value-of select="concat(
                            '(', 
                            DAVIDCutTitle, 
                            ')')"/>
                        <xsl:if test="not(position() = last())">
                            <xsl:value-of select="' ; '"/>
                        </xsl:if>
                    </xsl:for-each>                    
                </ICMT>
                <ICOP>Terms of Use and Reproduction: WNYC Radio. Additional copyright may apply to musical selections. </ICOP>
                <ICRD>
                    <xsl:value-of select="newscastDate"/>
                </ICRD>
                <IENG>Unknown engineer&#xD;</IENG>
                <IGNR>News&#xD;</IGNR>
                <IKEY>
                    <xsl:value-of select="
                        'https://id.loc.gov/authorities/subjects/sh85034883&#xD;'"
                    />
                    <xsl:value-of
                        select="' ; http://id.loc.gov/authorities/subjects/sh85145856&#xD;'[$matchedNews/story/@storyType = 'WEATHER']"/>

                </IKEY>
                <IMED>Aircheck&#xD;</IMED>
                <INAM>
                    <xsl:value-of select="newscastCode"/>
                    <xsl:value-of select="'&#xD;'"/>
                </INAM>
                <IPRD>News&#xD;</IPRD>
                <ISBJ>
                    <xsl:for-each select="story">
                        <xsl:value-of select="ASCII:ASCIIFier(WNYC:strip-tags(storyText))"/>
                    </xsl:for-each>
                    <xsl:value-of select="'&#xD;'"/>
                </ISBJ>
                <ISFT>
                    <xsl:value-of select="$wavData/GENERATOR"/>
                    <xsl:value-of select="'&#xD;'"/>
                </ISFT>
                <ISRC>
                    <xsl:value-of select="'https://www.wnyc.org/story/latest-newscast/'"/>
                </ISRC>
                <ISRF>WNYC Radio Aircheck&#xD;</ISRF>
                <ITCH>
                    <xsl:value-of select="distinct-values($wavData/CREATOR|$wavData/AUTHOR)" separator=" ; "/>
                    <xsl:value-of select="'&#xD;'"/>
                </ITCH>
            </Core>
        </File>
    </xsl:template>

</xsl:stylesheet>
