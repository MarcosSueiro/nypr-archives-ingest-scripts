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
    xmlns:WNYC="http://www.wnyc.org"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" exclude-result-prefixes="#all"
    version="3.0">

    <xsl:mode on-no-match="text-only-copy"/>
    <xsl:mode name="noMatch" on-no-match="deep-skip"/>

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
                        <xsl:apply-templates select="
                            $searchResultXml/*[@key]" mode="mapToElement"/>
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

    <xsl:template match="*[@key]" 
        xpath-default-namespace="http://www.w3.org/2005/xpath-functions"
        mode="mapToElement">
        <!-- Convert @keys to elements -->
        <xsl:choose>
            <xsl:when test="@key = 'tags'">
                <xsl:element name="tags">
                        <xsl:copy-of select="string"/>                    
                </xsl:element>
            </xsl:when>
            <xsl:when test="@key = 'npr-analytics-dimensions'">
                <xsl:element name="npr-analytics-dimensions">
                    <xsl:for-each select="*">
                        <nprAnalyticsDimension>
                            <xsl:value-of select="."/>
                        </nprAnalyticsDimension>
                    </xsl:for-each>                    
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{@key}">
                    <xsl:apply-templates mode="mapToElement"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="exifFiller">
        <!-- Map cms data as xml
        to a bwf metaEdit kind of output -->
        <xsl:param name="orgFlags"
            select="'WNYC|WQXR|NJPR|Gothamist|Greene|NYPR|New York Public Radio'"/>
        <xsl:param name="creatorsFlags" select="'host|producer|author'"/>
        <xsl:param name="segmentFlags" select="'segment'"/>
        <xsl:param name="cmsData"/>
        <xsl:param name="dbxURL" select="$cmsData//dbxURL"/>
        <xsl:param name="dbxData" select="document($dbxURL)"/>
        <xsl:param name="cmsDataMessage">
            <xsl:message select="'xmlData:', $cmsData"/>
        </xsl:param>
        <xsl:param name="nprAnalytics"
            select="
                $cmsData/cmsData/data/attributes/
                npr-analytics-dimensions"/>
        <xsl:param name="episodeProducingOrganizations"
            select="
                $cmsData/cmsData/data/attributes/
                producing-organizations[matches(., '\w')]"/>
        <xsl:param name="nprAnalyticsProducingOrganizations"
            select="
                $nprAnalytics/
                nprAnalyticsDimension
                [matches(., $orgFlags, 'i')]"/>
        <xsl:param name="showProducingOrganizations"
            select="
                $cmsData/cmsData/data/attributes/
                show-producing-orgs[matches(., '\w')]"/>
        <xsl:param name="urlProducingOrganizations"
            select="
                tokenize(
                $cmsData/cmsData/data/attributes/
                headers/brand/url,
                '\.|/'
                )[matches(., $orgFlags, 'i')]"/>
        <xsl:param name="producingOrganizations"
            select="
                distinct-values(
                ($episodeProducingOrganizations,
                $nprAnalyticsProducingOrganizations))"/>

        <xsl:param name="producingOrganizationsParsed"
            select="
                distinct-values((
                $producingOrganizations,
                $showProducingOrganizations/name
                [empty($producingOrganizations)],
                $urlProducingOrganizations
                [empty($producingOrganizations)]
                [empty($showProducingOrganizations)]))"/>
        <xsl:param name="producingOrganizationsAsText">
            <xsl:value-of select="
                    $producingOrganizationsParsed"
                separator=" ; "/>
        </xsl:param>
        <xsl:param name="producingOrgW4Letters"
            select="
                $producingOrganizationsParsed
                [string-length(.) = 4][1]"/>


        <xsl:param name="ArchivalLocationCode">
            <xsl:value-of select="$producingOrgW4Letters"/>
            <xsl:value-of
                select="
                    substring(
                    $producingOrganizationsParsed[1], 1, 4)
                    [empty($producingOrgW4Letters)]"
            />
        </xsl:param>

        <xsl:param name="producers"
            select="
                $cmsData/cmsData/data/attributes/appearances/producers"/>
        <xsl:param name="authors"
            select="
                $cmsData/cmsData/data/attributes/appearances/authors"/>
        <xsl:param name="hosts"
            select="
                $cmsData/cmsData/data/attributes/appearances/hosts"/>
        <xsl:param name="creators" 
                select="
                    distinct-values(
                    ($producers/name,
                    $authors/name,
                    $hosts/name)
                    )"/>

        <xsl:param name="cmsEngineers"
            select="
                distinct-values(
                $cmsData/cmsData/data/attributes/appearances/engineers[matches(., '\w')])"/>
        <xsl:param name="DAVIDEditor"
            select="
                $dbxData/ENTRIES/ENTRY/EDITOR[matches(., '\w')]"/>
        <xsl:param name="DAVIDAuthor"
            select="
                $dbxData/ENTRIES/ENTRY/AUTHOR[matches(., '\w')]"/>
        <xsl:param name="DAVIDChangeUser"
            select="
                $dbxData/ENTRIES/ENTRY/CHANGEUSER[matches(., '\w')]"/>
        <xsl:param name="DAVIDEngineers"
            select="
                $DAVIDEditor,
                $DAVIDAuthor[empty($DAVIDEditor)],
                $DAVIDChangeUser[empty($DAVIDAuthor)]
                "/>
        <xsl:param name="otherContributors">
            <xsl:value-of
                select="
                    distinct-values($cmsData/cmsData/data/
                    attributes/appearances/
                    *
                    [not(matches(local-name(), $creatorsFlags, 'i'))]
                    [not(matches(local-name(), 'engineer', 'i'))]/
                    name)"
                separator=" ; "/>
        </xsl:param>

        <xsl:param name="isSegment"
            select="
                boolean($nprAnalytics/
                nprAnalyticsDimension[matches(.,
                $orgFlags, 'i')])"/>
        <xsl:param name="type" select="$cmsData/cmsData/data/type"/>
        <xsl:param name="DAVIDClass" select="$dbxData/ENTRIES/ENTRY/CLASS"/>

        <!--        <originaldata>
            <xsl:copy-of select="$xmlData"></xsl:copy-of>
        </originaldata>-->

        <IARL>
            <xsl:value-of select="'US, '"/>
            <xsl:value-of select="$ArchivalLocationCode"/>
            <xsl:value-of select="'&#013;'"/>
        </IARL>
        <IART>
            <xsl:value-of select="$otherContributors"/>
            <xsl:value-of
                select="$producingOrganizationsAsText[not(matches($otherContributors, '\w'))]"/>
            <xsl:value-of select="'&#013;'"/>
        </IART>
        <ICMS>
            <xsl:variable name="processedCreators">
                <xsl:for-each select="$creators">
                    <xsl:variable name="locData">
                        <xsl:call-template name="directLOCNameSearch">
                            <xsl:with-param name="termToSearch">
                                <xsl:value-of select="tokenize(., ' ')[last()]"/>
                                <xsl:value-of select="', '"/>
                                <xsl:value-of select="tokenize(., ' ')[position() lt last()]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="locURL"
                        select="
                            $locData/rdf:RDF/madsrdf:PersonalName"/>
                    <xsl:copy-of select="$locURL"/>
                    <madsrdf:PersonalName>
                        <xsl:attribute name="rdf:about">
                            <xsl:value-of select=".[empty($locURL)]"/>
                        </xsl:attribute>
                    </madsrdf:PersonalName>
                </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="processedCreatorsAsText">
                <xsl:value-of
                    select="
                        $processedCreators/
                        madsrdf:PersonalName/
                        @rdf:about[. != '']"
                    separator=" ; "/>
            </xsl:variable>
            <xsl:value-of select="$processedCreatorsAsText"/>
            <xsl:value-of
                select="$producingOrganizationsAsText
                [not(matches($processedCreatorsAsText, '\w'))]"/>
            <xsl:value-of select="'&#013;'"/>
        </ICMS>

        <ICMT>

            <xsl:call-template name="strip-tags">
                <xsl:with-param name="text"
                    select="
                        concat(
                        'Story published at ',
                        $cmsData/cmsData/data/attributes/url,
                        ' on ',
                        $cmsData/cmsData/data/attributes/newsdate,
                        '. '
                        )"
                />
            </xsl:call-template>
            <xsl:call-template name="strip-tags">
                <xsl:with-param name="text"
                    select="
                        concat(
                        'mp3 available at ',
                        $cmsData/cmsData/data/attributes/audio,
                        ' as of ',
                        current-date()
                        )"
                />
            </xsl:call-template>
            <xsl:value-of
                select="$dbxData/ENTRIES/ENTRY/REMARK[. != '']/concat('. DAVID Remark: ', .)"/>
        </ICMT>

        <ICOP>
            <xsl:value-of
                select="concat('Terms of Use and Reproduction: ', $producingOrganizationsAsText)"/>
            <xsl:if test="$cmsData/cmsData/data/attributes/audio-may-download = 'true'">
                <xsl:value-of select="concat('&#013;Audio may download as of ', current-date())"/>
            </xsl:if>
            <xsl:if test="$cmsData/cmsData/data/attributes/audio-may-download = 'false'">
                <xsl:value-of select="concat('&#013;Audio may NOT download as of ', current-date())"
                />
            </xsl:if>
            <xsl:if test="$cmsData/cmsData/data/attributes/audio-may-embed = 'true'">
                <xsl:value-of select="concat('&#013;Audio may be embedded as of ', current-date())"
                />
            </xsl:if>
            <xsl:if test="$cmsData/cmsData/data/attributes/audio-may-embed = 'false'">
                <xsl:value-of
                    select="concat('&#013;Audio may NOT be embedded as of ', current-date())"/>
            </xsl:if>
            <xsl:if test="$cmsData/cmsData/data/attributes/audio-may-stream = 'true'">
                <xsl:value-of select="concat('&#013;Audio may stream as of ', current-date())"/>
            </xsl:if>
            <xsl:if test="$cmsData/cmsData/data/attributes/audio-may-stream = 'false'">
                <xsl:value-of select="concat('&#013;Audio may NOT stream as of ', current-date())"/>
            </xsl:if>
            <xsl:text>&#013;For more information, visit http://www.wnyc.org&#013;</xsl:text>
        </ICOP>
        <ICRD>
            <xsl:value-of select="$cmsData/cmsData/data/attributes/newsdate"/>
            <xsl:value-of select="'&#013;'"/>
        </ICRD>
        <IENG>
            <xsl:value-of
                select="
                    distinct-values((
                    $cmsEngineers,
                    $DAVIDEngineers[empty($cmsEngineers)]))"
                separator=" ; "/>
            <xsl:value-of
                select="
                    concat(
                    $ArchivalLocationCode, ' engineer')
                    [empty($DAVIDEngineers)]"/>
            <xsl:value-of select="'&#013;'"/>
        </IENG>
        <IGNR>
            <xsl:value-of select="$dbxData/ENTRIES/ENTRY/CLASS"/>
            <xsl:value-of select="concat(' ', $cmsData/cmsData/data/type)"/>
            <xsl:value-of select="'&#013;'"/>
        </IGNR>
        <IKEY>
            <!--<xsl:value-of select="$cmsData/cmsData/data/attributes/tags/fn:string" separator=" ; "/>-->
            <xsl:variable name="LoCResults">
                <xsl:apply-templates
                    select="$cmsData/cmsData/data/attributes/tags/fn:string/replace(., '\[lc\]', '')"
                    mode="directLOCSubjectSearch">
                    <xsl:with-param name="passThrough" select="true()"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:value-of select="distinct-values($LoCResults/rdf:RDF/madsrdf:Topic/@rdf:about)"
                separator=" ; "/>
            <!--<xsl:value-of select="distinct-values($LoCResults/rdf:RDF/madsrdf:Topic/@rdf:about)" separator= " ; "/>-->
            <xsl:value-of select="'&#013;'"/>
        </IKEY>
        <IMED>
            <xsl:value-of select="'audio'"/>
            <xsl:value-of select="'&#013;'"/>
        </IMED>
        <INAM>
            <xsl:choose>
                <xsl:when test="normalize-space($cmsData/cmsData/data/attributes/title)">
                    <xsl:call-template name="strip-tags">
                        <xsl:with-param name="text"
                            select="translate($cmsData/cmsData/data/attributes/title, $illegalCharacters, $legalCharacters)"
                        />
                    </xsl:call-template>
                    <!--                    <xsl:value-of
                        select="translate($xmlData//data/attributes/title, $illegalCharacters, $legalCharacters)"
                    />-->
                </xsl:when>
                <xsl:when test="normalize-space($cmsData/cmsData/data/attributes/twitter-headline)">
                    <xsl:call-template name="strip-tags">
                        <xsl:with-param name="text"
                            select="$cmsData/cmsData/data/attributes/twitter-headline"/>
                    </xsl:call-template>
                    <!--                    <xsl:value-of select="$xmlData//data/attributes/twitter-headline"/>-->
                </xsl:when>
                <xsl:when test="normalize-space($cmsData/cmsData/data/attributes/tease)">
                    <xsl:call-template name="strip-tags">
                        <xsl:with-param name="text"
                            select="translate($cmsData/cmsData/data/attributes/tease, $illegalCharacters, $legalCharacters)"
                        />
                    </xsl:call-template>
                    <!--<xsl:value-of
                        select="translate($xmlData//data/attributes/tease, $illegalCharacters, $legalCharacters)"
                    />-->
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="strip-tags">
                        <xsl:with-param name="text" select="$cmsData/cmsData/data/attributes/slug"/>
                    </xsl:call-template>
                    <!--                    <xsl:value-of select="$xmlData//data/attributes/slug"/>-->
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="'&#013;'"/>
        </INAM>
        <IPRD>
            <xsl:choose>
                <xsl:when test="$cmsData/cmsData/data/attributes/show-title != ''">
                    <xsl:value-of
                        select="translate($cmsData/cmsData/data/attributes/show-title, $illegalCharacters, $legalCharacters)"
                    />
                </xsl:when>
                <xsl:when test="$cmsData/cmsData/data/attributes/series != ''">
                    <xsl:value-of
                        select="translate($cmsData/cmsData/data/attributes/series/title, $illegalCharacters, $legalCharacters)"/>
                    <xsl:value-of select="concat(' (', $episodeProducingOrganizations, ' series)')"
                    />
                </xsl:when>
                <xsl:when test="$cmsData/cmsData/data/attributes/channel-title != ''">
                    <xsl:value-of
                        select="translate($cmsData/cmsData/data/attributes/channel-title, $illegalCharacters, $legalCharacters)"/>
                    <xsl:value-of select="concat(' (', $episodeProducingOrganizations, ' channel)')"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$episodeProducingOrganizations"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="'&#013;'"/>
        </IPRD>
        <ISBJ>
            <xsl:call-template name="strip-tags">
                <xsl:with-param name="text"
                    select="translate($cmsData/cmsData/data/attributes/body, $illegalCharacters, $legalCharacters)"
                />
            </xsl:call-template>            
            <xsl:value-of select="'&#013;&#013;'"/>
            <xsl:value-of select="$dbxData/ENTRIES/ENTRY/REMARK[. != '']"/>            
            <xsl:if test="
                contains($cmsData/cmsData/data/attributes/url, '-dummy-post-')"> DUMMY
                POST </xsl:if>
            <xsl:if test="$cmsData/cmsData/data/attributes/body = ''">NO DESCRIPTION</xsl:if>
            <xsl:value-of select="'&#013;'"/>
        </ISBJ>
        <ISFT>
            <xsl:choose>
                <xsl:when test="$dbxData/ENTRIES/ENTRY/GENERATOR">
                    <xsl:value-of select="$dbxData/ENTRIES/ENTRY/GENERATOR"/>
                </xsl:when>
                <xsl:otherwise>UNKNOWN SOFTWARE</xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="'&#013;'"/>
        </ISFT>
        <ISRC>
            <xsl:value-of select="$cmsData/cmsData/data/attributes/url"/>
            <xsl:value-of select="'&#013;'"/>
        </ISRC>
        <ISRF>
            <xsl:value-of select="$producingOrganizations[1], $DAVIDClass"/>            
            <xsl:value-of select="' segment'[$isSegment]"/>
            <xsl:value-of select="'. '"/>
            <xsl:value-of select="WNYC:Capitalize($type, 1), 'id is '"/>
            <xsl:value-of select="$cmsData/cmsData/data/id"/>
            <xsl:value-of select="'&#013;'"/>
        </ISRF>
        <ITCH>
            <xsl:value-of select="$DAVIDEngineers"/>
            <xsl:value-of select="'&#013;'"/>
        </ITCH>
    </xsl:template>

    <xsl:template match="*[@key]">
        <xsl:choose>
            <xsl:when test="@key = 'tags'">
                <xsl:element name="keywords">
                    <xsl:copy>
                        <xsl:value-of select="*" separator=" ; "/>
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
