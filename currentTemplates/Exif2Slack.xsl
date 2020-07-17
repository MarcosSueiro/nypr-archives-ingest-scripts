<?xml version="1.0" encoding="UTF-8"?>
<!-- Take an exiftool type of xml and:
1. Generate Slack markup json files
of 40 items max
2. Generate the CURL POST commands -->

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    xmlns:WNYC="http://www.wnyc.org" exclude-result-prefixes="#all">

    <xsl:import href="
        file:/T:/02%20CATALOGING/Instantiation%20uploads/InstantiationUploadTEMPLATES/currentTemplates/cavafySearch.xsl"/>
    
    <xsl:mode on-no-match="deep-skip"/>
    <!--Gives line breaks etc-->
    <xsl:output encoding="UTF-8" method="xml" indent="yes" omit-xml-declaration="yes"/>

    <xsl:param name="todaysDate" select="xs:date(current-date())"/>
    <xsl:param name="todaysDateFormatted"
        select="format-date($todaysDate, '[Y0001]-[M01]-[D01]')"/>
    <xsl:param name="publishDate" select="xs:date($todaysDate)"/>    
    <xsl:param name="validatingSubjectString" select="'id.loc.gov'"/>
    <xsl:param name="webhookFileLocation" select="concat(
        'file:/T:/02%20CATALOGING/Instantiation%20uploads/', 
        'InstantiationUploadTEMPLATES/slackWebhooks.xml')"/>
    <xsl:param name="webhookURLMarcos">
        <xsl:value-of select="
            doc($webhookFileLocation)
            /slackWebhooks/marcosWebhook"/>
    </xsl:param>
    <xsl:param name="webhookURLArchivesNewlyAdded">
        <xsl:value-of select="
            doc($webhookFileLocation)
            /slackWebhooks/archivesNewlyAddedWebhook"/>
    </xsl:param>
    <xsl:param name="baseURI" select="base-uri()"/>
    <xsl:param name="parsedBaseURI" select="
        analyze-string($baseURI, '/')"/>
    <xsl:param name="docFilename" select="
        $parsedBaseURI/fn:non-match[last()]"/>
    <xsl:param name="docFilenameNoExtension" 
        select="substring-before($docFilename, '.')"/>
    <xsl:param name="baseFolder" 
        select="'file:///T:/04 PROMOTION/slack/'"/>
    <xsl:param name="logFolder" 
        select="concat($baseFolder, 'instantiationUploadLOGS/')"/>
    <xsl:param name="currentTime"
        select="substring(
        translate(string(current-time()),
        ':', ''), 1, 4)"/>
    <xsl:param name="twentyFiveYearResult">
        <xsl:call-template name="anniversaries">
            <xsl:with-param name="xYears" select="25"/>
        </xsl:call-template>
    </xsl:param>
    <xsl:param name="fiftyYearResult">
        <xsl:call-template name="anniversaries">
            <xsl:with-param name="xYears" select="50"/>
        </xsl:call-template>
    </xsl:param>
    
    <xsl:variable name="buttonBlock">
        <!-- 25 year and 50 year ago buttons -->
        <fn:map>
            <fn:string key="type">actions</fn:string>
            <fn:array key="elements">
                <xsl:if
                    test="
                    $twentyFiveYearResult
                    [not(*[//local-name() = 'error'])]
                    ">
                    <xsl:variable name="twentyFiveYrCavafySearchString" select="
                        $twentyFiveYearResult//@searchString"/>
                    <fn:map>
                        <fn:string key="type">button</fn:string>
                        <fn:map key="text">
                            <fn:string key="type">plain_text</fn:string>
                            <fn:string key="text">25 yrs ago</fn:string>
                        </fn:map>
                        <fn:string key="url">
                            <xsl:value-of select="
                                $twentyFiveYrCavafySearchString"/>
                        </fn:string>
                    </fn:map>
                </xsl:if>
                <xsl:if
                    test="
                    $fiftyYearResult
                    [not(*[//local-name() = 'error'])]
                    ">
                    <xsl:variable name="fiftyYrCavafySearchString" select="
                        $fiftyYearResult//@searchString"/>
                    <fn:map>
                        <fn:string key="type">button</fn:string>
                        <fn:map key="text">
                            <fn:string key="type">plain_text</fn:string>
                            <fn:string key="text">50 yrs ago</fn:string>
                        </fn:map>
                        <fn:string key="url">
                            <xsl:value-of select="
                                $fiftyYrCavafySearchString"/>
                        </fn:string>
                    </fn:map>
                </xsl:if>
                
            </fn:array>
        </fn:map>
    </xsl:variable>
    
    <xsl:template name="headerBlock">
        <!-- Create header block -->
        <xsl:param name="noOfAssets"/>
        <xsl:param name="seriesIncluded"/>
        <fn:map>
            <fn:string key="type">section</fn:string>
            <fn:map key="text">
                <fn:string key="type">mrkdwn</fn:string>
                <fn:string key="text">
                    <xsl:text>:speaker: </xsl:text>
                    <xsl:text>*</xsl:text>
                    <xsl:text>Newly added Archives items for </xsl:text>
                    <xsl:value-of select="$todaysDateFormatted"/>
                    <xsl:text>*</xsl:text>
                    <xsl:text> :radio:</xsl:text>
                    <xsl:text>
</xsl:text>
                    <xsl:value-of 
                        select="'       ',
                        $noOfAssets, 'assets', 
                        'from series ', $seriesIncluded"/>
                    <xsl:text/>
                </fn:string>
            </fn:map>
        </fn:map>
        <xsl:copy-of select="$buttonBlock"/>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="slack">
        <!-- Match top-level element 
        and group by pbcore assets, not files-->
        <xsl:variable name="uniqueAssets">
            <xsl:copy>
            <xsl:for-each-group select="
                rdf:Description" group-by="
                RIFF:Source">
                <xsl:copy-of select="."/>
            </xsl:for-each-group>
            </xsl:copy>
        </xsl:variable>
        <xsl:apply-templates select="$uniqueAssets" mode="breakItUp"/>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="map">
        <!-- Create an xml array
        and convert it to json
        for use in Slack-->
        <xsl:variable name="xmlOutput">
            <fn:map>
                <fn:array key="blocks">
                    <fn:map>
                        <fn:string key="type">actions</fn:string>
                        <fn:array key="elements">
                            <fn:map>
                                <fn:string key="type">button</fn:string>
                                <fn:map key="text">
                                    <fn:string key="type">plain_text</fn:string>
                                    <fn:string key="text">cavafy</fn:string>
                                </fn:map>
                                <fn:string key="url">http://www.cavafy.wnyc.org</fn:string>
                            </fn:map>
                            <fn:map>
                                <fn:string key="type">button</fn:string>
                                <fn:map key="text">
                                    <fn:string key="type">plain_text</fn:string>
                                    <fn:string key="text">cavafy</fn:string>
                                </fn:map>
                                <fn:string key="url">http://www.cavafy.wnyc.org</fn:string>
                            </fn:map>
                        </fn:array>
                    </fn:map>
                    <fn:map>
                        <fn:string key="type">section</fn:string>
                        <fn:map key="text">
                            <fn:string key="type">mrkdwn</fn:string>
                            <fn:string key="text">
                                <xsl:text>:speaker: </xsl:text>
                                <xsl:text>*</xsl:text>
                                <xsl:text>Newly added Archives items for </xsl:text>
                                <xsl:value-of select="$todaysDateFormatted"/>
                                <xsl:text>*</xsl:text>
                                <xsl:text> :radio:</xsl:text>
                                <xsl:text/>
                            </fn:string>
                        </fn:map>
                    </fn:map>
                    <xsl:for-each-group select="
                        rdf:Description[position() le 40]" 
                        group-by="RIFF:Source">
                        <fn:map>
                            <fn:string key="type">section</fn:string>
                            <fn:map key="text">
                                <fn:string key="type">mrkdwn</fn:string>
                                <fn:string key="text">
                                    <xsl:value-of
                                        select="
                                            WNYC:slackURL(RIFF:Source,
                                            RIFF:Title)"
                                        disable-output-escaping="yes"/>
                                </fn:string>
                            </fn:map>
                        </fn:map>
                    </xsl:for-each-group>
                </fn:array>
            </fn:map>
        </xsl:variable>
        <xsl:value-of select="xml-to-json($xmlOutput, map{'indent':true()})"
            disable-output-escaping="yes"/>
    </xsl:template>    

    <xsl:template name="generateCurl">
        <!-- Generate Slack posting CURL commands,
            including 'webhooks' 
        This is output as a text which you can copy,
        not as a file-->
        <xsl:param name="filenameSlack"/>
        <xsl:param name="filenameSlackRaw" select="replace(fn:substring-after($filenameSlack, 'file:/'), '%20', ' ')"/>
        <xsl:param name="webhookURL" select="'https://hooks.slack.com/services/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'"></xsl:param>
        <xsl:text>
</xsl:text>
        <xsl:text>curl -X POST -H </xsl:text>
        <xsl:text>"Content-type: application/json" </xsl:text>
        <xsl:text>-d @</xsl:text>
        <xsl:value-of 
            select="
            concat(
            '&quot;', 
            $filenameSlackRaw, 
            '&quot; ')" disable-output-escaping="yes"/>
        <xsl:value-of select="$webhookURL"/>
        <xsl:text>
</xsl:text>
    </xsl:template>
    
    <xsl:function name="WNYC:slackURL">
        <!-- Create a Slack markup hyperlink
        from a URL and a string-->
        <xsl:param name="URL"/>
        <xsl:param name="text"/>
        <xsl:text disable-output-escaping="yes">&lt;</xsl:text>
        <xsl:value-of select="normalize-space($URL)"/>
        <xsl:text>|</xsl:text>
        <xsl:value-of select="normalize-space($text)"/>
        <xsl:text disable-output-escaping="yes">&gt;</xsl:text>
    </xsl:function>

    <xsl:template match="rdf:RDF" mode="breakItUp" name="breakItUp">
        <!-- break up large files 
        and generate Slack json documents -->
        <xsl:param name="firstOccurrence" select="1" as="xs:integer"/>
        <xsl:param name="maxOccurrences" as="xs:integer" select="40"/>

        <xsl:variable name="lastPosition" select="
            count(
            *[position() ge $firstOccurrence]
            )"
            as="xs:integer"/>
        <xsl:text>
                                                    </xsl:text>
        <xsl:comment select="
            'last position: ', $lastPosition, 
            'maxOcccurrences: ', $maxOccurrences"/>

        <xsl:choose>
            <xsl:when test="$lastPosition le $maxOccurrences">
                <xsl:variable name="filenameSlack"
                    select="
                    concat(
                    substring-before($baseURI, '.'), 
                    '_ForSlack', 
                    format-date(
                    current-date(), '[Y0001][M01][D01]'
                    ), 
                    '_Assets', 
                    $firstOccurrence, 
                    '-', 
                    $firstOccurrence + $lastPosition - 1, 
                    '.json'
                    )"/>
                <xsl:text>
   </xsl:text>
                <xsl:comment>   marcosCURL   </xsl:comment>
                <xsl:call-template name="generateCurl">
                    <xsl:with-param name="filenameSlack" select="
                        $filenameSlack"/>
                    <xsl:with-param name="webhookURL"
                        select="$webhookURLMarcos"/>
                </xsl:call-template>
                
                <xsl:text>
</xsl:text>
                <xsl:comment>archivesNewlyAddedCURL</xsl:comment>
                <xsl:call-template name="generateCurl">
                    <xsl:with-param name="filenameSlack" select="
                        $filenameSlack"/>
                    <xsl:with-param name="webhookURL"
                        select="$webhookURLArchivesNewlyAdded"/>
                </xsl:call-template>
                
                <xsl:result-document href="{$filenameSlack}">
                    
                    <xsl:variable name="xmlOutput">
                        <fn:map>
                            <fn:array key="blocks">
                                <xsl:call-template name="headerBlock">
                                    <xsl:with-param name="noOfAssets" 
                                        select="$lastPosition"/>
                                    <xsl:with-param name="seriesIncluded">
                                        <xsl:value-of select="
                                            distinct-values(
                                            rdf:Description
                                            [position() ge $firstOccurrence] 
                                            [position() le 40]
                                            /RIFF:Product
                                            )" 
                                            separator=", "/>
                                    </xsl:with-param>
                                </xsl:call-template>
                                <xsl:for-each-group select="
                                    rdf:Description
                                    [position() ge $firstOccurrence]" group-by="
                                    RIFF:Source">
                                    <fn:map>
                                        <fn:string key="type">section</fn:string>
                                        <fn:map key="text">
                                            <fn:string key="type">mrkdwn</fn:string>
                                            <fn:string key="text">
                                                <xsl:value-of
                                                    select="
                                                    WNYC:slackURL(RIFF:Source,
                                                    RIFF:Title)"
                                                    disable-output-escaping="yes"/>
                                            </fn:string>
                                        </fn:map>
                                    </fn:map>
                                </xsl:for-each-group>
                            </fn:array>
                        </fn:map>
                        
                    </xsl:variable>
                    <xsl:value-of select="xml-to-json($xmlOutput, map{'indent':true()})"
                        disable-output-escaping="yes"/>
                </xsl:result-document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="filenameSlack"
                    select="concat(substring-before($baseURI, '.'), '_ForSlack', format-date(current-date(), '[Y0001][M01][D01]'), '_Assets', $firstOccurrence, '-', $firstOccurrence + $maxOccurrences - 1, '.json')"/>
                <xsl:text>
   </xsl:text>
                <xsl:comment>   marcosCURL   </xsl:comment>
                <xsl:call-template name="generateCurl">
                    <xsl:with-param name="filenameSlack" select="$filenameSlack"/>
                    <xsl:with-param name="webhookURL"
                        select="$webhookURLMarcos"/>
                </xsl:call-template>
                
                <xsl:text>
</xsl:text>
                <xsl:comment>archivesNewlyAddedCURL</xsl:comment>
                <xsl:call-template name="generateCurl">
                    <xsl:with-param name="filenameSlack" select="$filenameSlack"/>
                    <xsl:with-param name="webhookURL"
                        select="$webhookURLArchivesNewlyAdded"/>
                </xsl:call-template>
                
                <xsl:result-document href="{$filenameSlack}">                    
                    <xsl:variable name="xmlOutput">
                        <fn:map>
                            <fn:array key="blocks">
                                <xsl:copy-of select="$buttonBlock"/>
                                <xsl:call-template name="headerBlock">
                                    <xsl:with-param name="noOfAssets" 
                                        select="$maxOccurrences"/>
                                    <xsl:with-param name="seriesIncluded">
                                        <xsl:value-of select="
                                            distinct-values(
                                            rdf:Description
                                            [position() ge $firstOccurrence] 
                                            [position() le 40]
                                            /RIFF:Product
                                            )" 
                                            separator=", "/>
                                    </xsl:with-param>
                                </xsl:call-template>
                                <xsl:for-each-group select="rdf:Description[position() ge $firstOccurrence and position() lt $firstOccurrence + $maxOccurrences]" group-by="RIFF:Source">
                                    <fn:map>
                                        <fn:string key="type">section</fn:string>
                                        <fn:map key="text">
                                            <fn:string key="type">mrkdwn</fn:string>
                                            <fn:string key="text">
                                                <xsl:value-of
                                                    select="
                                                    WNYC:slackURL(RIFF:Source,
                                                    RIFF:Title)"
                                                    disable-output-escaping="yes"/>
                                            </fn:string>
                                        </fn:map>
                                    </fn:map>
                                </xsl:for-each-group>
                            </fn:array>
                        </fn:map>
                        
                    </xsl:variable>
                    <xsl:value-of select="xml-to-json($xmlOutput, map{'indent':true()})"
                        disable-output-escaping="yes"/>
                </xsl:result-document>

                <xsl:apply-templates select="." mode="breakItUp">
                    <xsl:with-param name="firstOccurrence"
                        select="$firstOccurrence + $maxOccurrences"/>
                    <xsl:with-param name="maxOccurrences" select="$maxOccurrences"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <!--<xsl:template match="rdf:Description" mode="json">
        <xsl:for-each-group select="." group-by="RIFF:Source">
            <xsl:text>\n</xsl:text>
            <xsl:value-of
                select="
                    WNYC:slackURL(RIFF:Source,
                    RIFF:Title)"
                disable-output-escaping="yes"/>
        </xsl:for-each-group>
    </xsl:template>-->
    
    <!--<xsl:template match="rdf:RDF" mode="jaon">
        <![CDATA[curl -X POST -H "Content-type: application/json" -\-data "{'type': 'mrkdwn','text': 'This message contains a URL http://foo.com/\nSo does this one: www.foo.com\nThis message contains a URL <http://foo.com/>\n<http://www.foo.com|This message *is* a link>\n<mailto:bob@example.com|Email Bob Roberts>'}" https://hooks.slack.com/services/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]]>
        <xsl:variable name="filenameSlack"
            select="
            concat(
            $baseFolder,
            format-date($publishDate, '[Y0001][M01][D01]'),
            'Slack',
            'From',
            $docFilenameNoExtension,
            '.txt')"/>
        <xsl:result-document format="slack" href="{$filenameSlack}">
            <xsl:apply-templates select="." mode="html"/>
        </xsl:result-document>
    </xsl:template>-->
</xsl:stylesheet>
