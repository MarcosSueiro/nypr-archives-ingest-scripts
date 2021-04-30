<?xml version="1.0" encoding="UTF-8"?>
<!-- Find a cms entry from a 'motive / theme' field 
and output its data in BWF MetaEdit Core format -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:XMP="http://ns.exiftool.ca/XMP/XMP-x/1.0/"
    xmlns:XMP-xmp="http://ns.exiftool.ca/XMP/XMP-xmp/1.0/"
    xmlns:XMP-xmpDM="http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/"
    xmlns:XMP-xmpMM="http://ns.exiftool.ca/XMP/XMP-xmpMM/1.0/"
    xmlns:XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" exclude-result-prefixes="#all"
    version="3.0">

    <xsl:mode on-no-match="text-only-copy"/>

    <xsl:param name="ISODatePattern"
        select="
            '^([0-9]{4})-?(1[0-2]|0[1-9])-?(3[01]|0[1-9]|[12][0-9])$'"/>
    <xsl:param name="showList" select="doc('Shows.xml')"/>

    <xsl:template match="MOTIVE" mode="getCMSData" name="getCMSData">
        <!-- Input: 'motive/theme' field
            Output: cms data from the API
            as xml
        -->
        <xsl:param name="theme" select="."/>
        <xsl:param name="exactMatch" select="true()"/>
        <xsl:param name="queryURL">
            <xsl:value-of select="'https://api.wnyc.org/api/v3/story/?audio_file=/'"/>
            <xsl:value-of select="$theme"/>
            <xsl:value-of select="'.mp3'[$exactMatch]"/>
        </xsl:param>
        <xsl:param name="minRecords" select="1"/>
        <xsl:param name="maxRecords" select="1"/>
        <xsl:message
            select="
                concat(
                'Search WNYC CMS for entry with MP3 ', $theme,
                ' using search string ', $queryURL
                )"/>
        <xsl:variable name="searchResultJson">
            <searchResultJson>
                <xsl:copy-of select="unparsed-text($queryURL)" copy-namespaces="no"/>
            </searchResultJson>
        </xsl:variable>

        <xsl:variable name="searchResultXml" select="json-to-xml($searchResultJson)/*"/>
        <xsl:message select="
                'xml search data: ',
                $searchResultXml"/>
        <xsl:variable name="cmsRecordsFoundCount"
            select="
                $searchResultXml
                /fn:map[@key = 'meta']
                /fn:map[@key = 'pagination']
                /fn:number[@key = 'count']"/>
        <xsl:variable name="cmsRecordsFoundMessage"
            select="
                concat($cmsRecordsFoundCount,
                ' entries for ',
                $theme,
                ' with query ',
                $queryURL)"/>
        <xsl:message select="$cmsRecordsFoundMessage"/>
        <xsl:choose>
            <xsl:when
                test="
                    number($cmsRecordsFoundCount) ge $minRecords
                    and
                    number($cmsRecordsFoundCount) le $maxRecords">
                <xsl:variable name="cmsData">
                    <cmsData>
                        <xsl:apply-templates select="$searchResultXml/*[@key]" mode="mapToElement"/>
                    </cmsData>
                </xsl:variable>
                <xsl:message select="'CMS DATA:'"/>
                <xsl:message select="$searchResultXml"/>
                <xsl:copy-of select="$cmsData"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'cms_records_found_count'"/>
                    <xsl:value-of select="
                            $cmsRecordsFoundMessage"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[@key]" xpath-default-namespace="http://www.w3.org/2005/xpath-functions"
        mode="mapToElement">
        <!-- Convert @keys to elements -->
        <xsl:element name="{@key}">
            <xsl:apply-templates mode="mapToElement"/>
        </xsl:element>
    </xsl:template>

    <xsl:template name="exifFiller">
        <!-- Map cms data as xml
        to a bwf metaEdit kind of output -->
        <xsl:param name="cmsData"/>
        <xsl:param name="dbxURL"/>
        <xsl:message>exifFiller!</xsl:message>
        <xsl:message select="'xmlData:', $cmsData"/>

        <xsl:variable name="producingOrganizations">
            <xsl:choose>
                <xsl:when test="normalize-space($cmsData//data/attributes/producing-organizations)">
                    <xsl:value-of select="$cmsData//data/attributes/producing-organizations/name"
                        separator=" ; "/>
                </xsl:when>
                <xsl:when test="$cmsData//npr-analytics-dimensions[contains(./*, 'wnyc')]">
                    <xsl:message>NPR analytics!</xsl:message>
                    <xsl:value-of select="'WNYC'"/>
                </xsl:when>
                <xsl:when test="$cmsData//npr-analytics-dimensions[contains(./*, 'wqxr')]">
                    <xsl:message>NPR analytics!</xsl:message>
                    <xsl:value-of select="'WQXR'"/>
                </xsl:when>
                <xsl:when test="contains($cmsData//attributes/headers/brand/url, 'wqxr')"
                    >WQXR</xsl:when>
                <xsl:when test="contains($cmsData//attributes/headers/brand/url, 'wnyc')"
                    >WNYC</xsl:when>
                <xsl:otherwise>NYPR</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="producers">
            <xsl:choose>
                <xsl:when test="$cmsData//data/attributes/appearances/producers">
                    <xsl:value-of select="$cmsData//data/attributes/appearances/producers/name"
                        separator=" ; "/>
                </xsl:when>
                <xsl:when test="contains($cmsData//attributes/headers/brand/url, 'wqxr')"
                    >WQXR</xsl:when>
                <xsl:otherwise>NYPR</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="authors">
            <xsl:choose>
                <xsl:when test="$cmsData//data/attributes/appearances/authors">
                    <xsl:value-of select="$cmsData//data/attributes/appearances/authors/name"
                        separator=" ; "/>
                </xsl:when>
                <xsl:when test="contains($cmsData//attributes/headers/brand/url, 'wqxr')"
                    >WQXR</xsl:when>
                <xsl:otherwise>NYPR</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="hosts">
            <xsl:choose>
                <xsl:when test="$cmsData//data/attributes/appearances/hosts">
                    <xsl:value-of select="$cmsData//data/attributes/appearances/hosts/name"
                        separator=" ; "/>
                </xsl:when>
                <xsl:otherwise>NYPR Host</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!--        <originaldata>
            <xsl:copy-of select="$xmlData"></xsl:copy-of>
        </originaldata>-->

        <IARL>
            <xsl:copy-of select="concat('US, ', $producingOrganizations)"/>
            <xsl:text>&#013;</xsl:text>
        </IARL>
        <IART>
            <xsl:value-of select="$cmsData/data/attributes/appearances/*/name" separator=" ; "/>
            <xsl:if test="not($cmsData//data/attributes/appearances/*/name)">
                <xsl:value-of select="$producingOrganizations"/>
            </xsl:if>
            <xsl:text>&#013;</xsl:text>
        </IART>
        <ICMS>
            <!--<xsl:variable name="producingOrganizationsAndProducers">
                <xsl:call-template name="mergeFields">
                    <xsl:with-param name="field1" select="$producingOrganizations"/>
                    <xsl:with-param name="field2" select="$producers"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="producingOrganizationsAndProducersAndAuthors">
                <xsl:call-template name="mergeFields">
                    <xsl:with-param name="field1" select="$producingOrganizationsAndProducers"/>
                    <xsl:with-param name="field2" select="$authors"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="recursive-out-trim">
                <xsl:with-param name="input" select="$producingOrganizationsAndProducersAndAuthors"/>
                <xsl:with-param name="endStr" select="';'"/>
            </xsl:call-template>
            <xsl:text>&#013;</xsl:text>-->
        </ICMS>

        <ICMT>
            <xsl:if test="normalize-space(document($cmsData//dbxURL)/ENTRIES/ENTRY/REMARK)">
                <xsl:value-of select="document($cmsData//dbxURL)/ENTRIES/ENTRY/REMARK"/>
                <xsl:text> ; </xsl:text>
            </xsl:if>
            <xsl:call-template name="strip-tags">
                <xsl:with-param name="text"
                    select="concat('Story published at ', $cmsData//data/attributes/url, ' on ', $cmsData//data/attributes/newsdate)"
                />
            </xsl:call-template>
            <xsl:call-template name="strip-tags">
                <xsl:with-param name="text"
                    select="concat('. mp3 available at ', $cmsData//data/attributes/audio, ' as of ', current-date())"
                />
            </xsl:call-template>
            <!--<xsl:value-of
                select="concat('Story published at ', $xmlData//data/attributes/url, ' on ', $xmlData//data/attributes/newsdate)"/>-->

            <!--            <xsl:value-of
                select="concat('. mp3 available at ', $xmlData//data/attributes/audio, ' as of ', current-date())"/>-->
            <!--<xsl:text>&#013;</xsl:text>-->
        </ICMT>

        <ICOP>
            <xsl:value-of
                select="concat('Terms of Use and Reproduction: ', $producingOrganizations)"/>
            <xsl:if test="$cmsData//data/attributes/audio-may-download = 'true'">
                <xsl:value-of select="concat('&#013;Audio may download as of ', current-date())"/>
            </xsl:if>
            <xsl:if test="$cmsData//data/attributes/audio-may-download = 'false'">
                <xsl:value-of select="concat('&#013;Audio may NOT download as of ', current-date())"
                />
            </xsl:if>
            <xsl:if test="$cmsData//data/attributes/audio-may-embed = 'true'">
                <xsl:value-of select="concat('&#013;Audio may be embedded as of ', current-date())"
                />
            </xsl:if>
            <xsl:if test="$cmsData//data/attributes/audio-may-embed = 'false'">
                <xsl:value-of
                    select="concat('&#013;Audio may NOT be embedded as of ', current-date())"/>
            </xsl:if>
            <xsl:if test="$cmsData//data/attributes/audio-may-stream = 'true'">
                <xsl:value-of select="concat('&#013;Audio may stream as of ', current-date())"/>
            </xsl:if>
            <xsl:if test="$cmsData//data/attributes/audio-may-stream = 'false'">
                <xsl:value-of select="concat('&#013;Audio may NOT stream as of ', current-date())"/>
            </xsl:if>
            <xsl:text>&#013;For more information, visit http://www.wnyc.org&#013;</xsl:text>
        </ICOP>
        <ICRD>
            <xsl:value-of select="$cmsData//data/attributes/newsdate"/>
            <xsl:text>&#013;</xsl:text>
        </ICRD>
        <IENG>
            <!--<xsl:choose>
                <xsl:when test="document($dbxURL)/ENTRIES/ENTRY/EDITOR">
                    <xsl:value-of select="document($dbxURL)/ENTRIES/ENTRY/EDITOR"/>
                </xsl:when>
                <xsl:when test="document($dbxURL)/ENTRIES/ENTRY/AUTHOR">
                    <xsl:value-of select="document($dbxURL)/ENTRIES/ENTRY/AUTHOR"/>
                </xsl:when>
                <xsl:when test="document($dbxURL)/ENTRIES/ENTRY/CHANGEUSER">
                    <xsl:value-of select="document($dbxURL)/ENTRIES/ENTRY/CHANGEUSER"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($producingOrganizations, ' engineer')"/>
                </xsl:otherwise>
            </xsl:choose>-->
            <xsl:text>&#013;</xsl:text>
        </IENG>
        <IGNR>
            <!--<xsl:value-of select="document($dbxURL)/ENTRIES/ENTRY/CLASS"/>
            <xsl:value-of select="concat(' ', $xmlData//data/type)"/>-->
            <xsl:text>&#013;</xsl:text>
        </IGNR>
        <IKEY>
            <xsl:choose>
                <xsl:when test="$cmsData//data/attributes/keywords != ''">
                    <xsl:value-of select="$cmsData//data/attributes/keywords"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$producingOrganizations"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>&#013;</xsl:text>
        </IKEY>
        <IMED>
            <xsl:value-of select="'audio'"/>
            <xsl:text>&#013;</xsl:text>
        </IMED>
        <INAM>
            <xsl:choose>
                <xsl:when test="normalize-space($cmsData//data/attributes/title)">
                    <xsl:call-template name="strip-tags">
                        <xsl:with-param name="text"
                            select="translate($cmsData//data/attributes/title, $illegalCharacters, $legalCharacters)"
                        />
                    </xsl:call-template>
                    <!--                    <xsl:value-of
                        select="translate($xmlData//data/attributes/title, $illegalCharacters, $legalCharacters)"
                    />-->
                </xsl:when>
                <xsl:when test="normalize-space($cmsData//data/attributes/twitter-headline)">
                    <xsl:call-template name="strip-tags">
                        <xsl:with-param name="text"
                            select="$cmsData//data/attributes/twitter-headline"/>
                    </xsl:call-template>
                    <!--                    <xsl:value-of select="$xmlData//data/attributes/twitter-headline"/>-->
                </xsl:when>
                <xsl:when test="normalize-space($cmsData//data/attributes/tease)">
                    <xsl:call-template name="strip-tags">
                        <xsl:with-param name="text"
                            select="translate($cmsData//data/attributes/tease, $illegalCharacters, $legalCharacters)"
                        />
                    </xsl:call-template>
                    <!--<xsl:value-of
                        select="translate($xmlData//data/attributes/tease, $illegalCharacters, $legalCharacters)"
                    />-->
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="strip-tags">
                        <xsl:with-param name="text" select="$cmsData//data/attributes/slug"/>
                    </xsl:call-template>
                    <!--                    <xsl:value-of select="$xmlData//data/attributes/slug"/>-->
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>&#013;</xsl:text>
        </INAM>
        <IPRD>
            <xsl:choose>
                <xsl:when test="$cmsData//data/attributes/show-title != ''">
                    <xsl:value-of
                        select="translate($cmsData//data/attributes/show-title, $illegalCharacters, $legalCharacters)"/>
                    <xsl:value-of select="concat(' (', $producingOrganizations, ' show)')"/>
                </xsl:when>
                <xsl:when test="$cmsData//data/attributes/series != ''">
                    <xsl:value-of
                        select="translate($cmsData//data/attributes/series/title, $illegalCharacters, $legalCharacters)"/>
                    <xsl:value-of select="concat(' (', $producingOrganizations, ' series)')"/>
                </xsl:when>
                <xsl:when test="$cmsData//data/attributes/channel-title != ''">
                    <xsl:value-of
                        select="translate($cmsData//data/attributes/channel-title, $illegalCharacters, $legalCharacters)"/>
                    <xsl:value-of select="concat(' (', $producingOrganizations, ' channel)')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$producingOrganizations"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>&#013;</xsl:text>
        </IPRD>
        <ISBJ>
            <xsl:call-template name="strip-tags">
                <xsl:with-param name="text"
                    select="translate($cmsData//data/attributes/body, $illegalCharacters, $legalCharacters)"
                />
            </xsl:call-template>

            <!--<xsl:value-of
                select="translate($xmlData//data/attributes/body, $illegalCharacters, $legalCharacters)"/>-->
            <xsl:value-of select="'&#013;&#013;'"/>

            <xsl:if test="document($cmsData//dbxURL)/ENTRIES/ENTRY/REMARK">
                <xsl:value-of select="document($cmsData//dbxURL)/ENTRIES/ENTRY/REMARK"/>
            </xsl:if>
            <xsl:if test="contains($cmsData//data/attributes/url, '-dummy-post-')"> DUMMY POST </xsl:if>
            <xsl:if test="$cmsData//data/attributes/body = ''">NO DESCRIPTION</xsl:if>
            <xsl:text>&#013;</xsl:text>
        </ISBJ>
        <!--        <ISFT>
            <xsl:choose>
                <xsl:when test="document($xmlData//dbxURL)/ENTRIES/ENTRY/GENERATOR">
                    <xsl:value-of select="document($xmlData//dbxURL)/ENTRIES/ENTRY/GENERATOR"/>
                </xsl:when>
                <xsl:otherwise>UNKNOWN SOFTWARE</xsl:otherwise>
            </xsl:choose>
            <xsl:text>&#013;</xsl:text>
        </ISFT>-->
        <ISRC>
            <xsl:value-of select="$cmsData//data/attributes/url"/>
            <xsl:text>&#013;</xsl:text>
        </ISRC>
        <ISRF>
            <xsl:value-of
                select="concat($producingOrganizations, ' audio. ', upper-case(substring($cmsData//data/type, 1, 1)), substring($cmsData//data/type, 2), ' id is ', $cmsData//data/id, '.')"/>
            <xsl:text>&#013;</xsl:text>
        </ISRF>
        <ITCH>
            <!--<xsl:choose>
                <xsl:when test="document($dbxURL)/ENTRIES/ENTRY/EDITOR">
                    <xsl:value-of select="document($dbxURL)/ENTRIES/ENTRY/EDITOR"/>
                </xsl:when>
                <xsl:when test="document($dbxURL)/ENTRIES/ENTRY/AUTHOR">
                    <xsl:value-of select="document($dbxURL)/ENTRIES/ENTRY/AUTHOR"/>
                </xsl:when>
                <xsl:when test="document($dbxURL)/ENTRIES/ENTRY/CHANGEUSER">
                    <xsl:value-of select="document($dbxURL)/ENTRIES/ENTRY/CHANGEUSER"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($producingOrganizations, ' engineer')"/>
                </xsl:otherwise>
            </xsl:choose>-->
            <xsl:text>&#013;</xsl:text>
        </ITCH>



    </xsl:template>

    <xsl:template match="*[@key]">
        <xsl:choose>
            <xsl:when test="@key = 'tags'">
                <xsl:element name="keywords">
                    <xsl:copy>
                        <xsl:value-of select="./*" separator=" ; "/>
                    </xsl:copy>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{@key}">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>




    <xsl:template match="cmsData" mode="sortCMSResults">
        <xsl:copy>
            <xsl:copy-of select="links"/>
            <xsl:copy select="data">
                <xsl:for-each select="id">
                    <xsl:sort select="."/>
                    <xsl:copy-of select="preceding-sibling::type[1]"/>
                    <xsl:copy-of select="."/>
                    <xsl:copy-of select="following-sibling::attributes[1]"/>
                </xsl:for-each>
            </xsl:copy>
            <xsl:copy-of select="meta"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
