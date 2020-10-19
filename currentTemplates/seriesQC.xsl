<?xml version="1.0" encoding="UTF-8"?>
<!-- Accept a series list (with optional additional restrictions)
        and generate a detailed error log 
        according to the NYPR rules

Source document:

Enter the series name under <seriesName>
and any further refinements under <searchString>.

For example, to QC the series 'Central Park Summerstage' and
assets without a cassette instantiation from 'Memoirs of the Movies',
the source xml document would be:

<seriesList>
    <series>
        <seriesName>Central Park SummerStage</seriesName>
        <searchString></searchString>
    </series>
</seriesList>
<seriesList>
    <series>
        <seriesName>Memoirs of the Movies</seriesName>
        <searchString>https://cavafy.wnyc.org/?facet_Series+Title%5B%5D=Memoirs+of+the+Movies&amp;q=%22memoirs+of+the+movies%22+-cassette</searchString>
    </series>
</seriesList> -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" exclude-result-prefixes="#all"
    version="2.0">
    

    <xsl:import href="cavafyStrictQC.xsl"/>

    <xsl:template match="seriesList">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="series">
        <xsl:variable name="seriesEntry">
            <xsl:call-template name="findSeriesXMLFromName">
                <xsl:with-param name="seriesName" select="seriesName"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="seriesAssetsXMLs">
            <xsl:choose>
                <xsl:when test="contains(searchString, 'https://cavafy.wnyc.org/')">
                    <xsl:call-template name="findCavafyXMLs">
                        <xsl:with-param name="textToSearch"
                            select="
                                encode-for-uri(seriesName[. != ''])"/>
                        <xsl:with-param name="field1ToSearch" select="'title'"/>
                        <xsl:with-param name="series" select="seriesName[. != '']"/>
                        <xsl:with-param name="maxResults" select="10000"/>
                        <xsl:with-param name="searchString"
                            select="
                                searchString[contains(., 'https://cavafy.wnyc.org/')]"
                        />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="findCavafyXMLs">
                        <xsl:with-param name="textToSearch"
                            select="
                                encode-for-uri(seriesName[. != ''])"/>
                        <xsl:with-param name="field1ToSearch" select="'title'"/>
                        <xsl:with-param name="series" select="seriesName[. != '']"/>
                        <xsl:with-param name="maxResults" select="10000"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:variable>

        <xsl:variable name="completeLog">
            <completeLog>
                <seriesName>
                    <xsl:value-of select="seriesName"/>
                </seriesName>
                <seriesEntry>
                    <xsl:copy-of select="$seriesEntry"/>
                </seriesEntry>
                <seriesURL>
                    <xsl:value-of
                        select="
                            $seriesEntry
                            /pb:pbcoreCollection
                            /pb:pbcoreDescriptionDocument
                            /pb:pbcoreIdentifier
                            [@source = 'pbcore XML database UUID']
                            /concat(
                            'https://cavafy.wnyc.org/assets/', .
                            )"
                    />
                </seriesURL>
                <xsl:apply-templates
                    select="
                        $seriesAssetsXMLs/pb:pbcoreCollection"
                    mode="cavafyStrictQC"/>
            </completeLog>
        </xsl:variable>
        <xsl:call-template name="generateErrorLog">
            <xsl:with-param name="completeLog" select="$completeLog"/>
        </xsl:call-template>
        <xsl:copy-of select="$completeLog"/>
    </xsl:template>
</xsl:stylesheet>