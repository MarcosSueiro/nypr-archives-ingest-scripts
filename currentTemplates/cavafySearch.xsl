<?xml version="1.1" encoding="UTF-8"?>
<!--    
    1. Accept cavafy search parameters
    2. Generate a cavafy API search string of the type
https://cavafy.wnyc.org/?facet_Collection%5B%5D=CMS&facet_Contributor%5B%5D=La+Guardia%2C+Fiorello+H.+%28Fiorello+Henry%29%2C+1882-1947&facet_Genre%5B%5D=Speech&facet_Location%5B%5D=Archives+Storage&facet_Series+Title%5B%5D=Talk+to+the+People&facet_Subject%5B%5D=Social+sciences&page=3&q=la+guardia&search_fields%5B%5D=contributor
https://cavafy.wnyc.org/?facet_Collection%5B%5D=CMS&facet_Contributor%5B%5D=La+Guardia%2C+Fiorello+H.+%28Fiorello+Henry%29%2C+1882-1947&facet_Genre%5B%5D=Speech&facet_Location%5B%5D=Archives+Storage&facet_Series+Title%5B%5D=Talk+to+the+People&facet_Subject%5B%5D=Social+sciences&page=3&q=la+guardia
    3. Output fields 
    corresponding to each of the resulting asset results.

Cavafy's RESTful API search string consists of 
    1. https://cavafy.wnyc.org/?
    2. facets
    3. page number
    4. text to search...
    5. ...in specific fields.

Make sure your are parameters in percent-encoded!! 
https://www.url-encode-decode.com/
-->

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:WNYC="http://www.wnyc.org"
    xmlns:pma="http://www.phpmyadmin.net/some_doc_url/"
    xmlns:op="https://www.w3.org/TR/2017/REC-xpath-functions-31-20170321/"
    xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:ASCII="https://www.ecma-international.org/publications/standards/Ecma-094.htm"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" 
    xmlns:et="http://ns.exiftool.ca/1.0/"
    exclude-result-prefixes="#all">

    <xsl:output method="xml" version="1.0" indent="yes"/>

    <xsl:import href="manageDuplicates.xsl"/>
    <xsl:import href="parseDAVIDTitle.xsl"/>

    <xsl:param name="cavafyValidatingString" select="'^https://cavafy.wnyc.org/assets/'"/>
    <xsl:param name="separatingToken" select="';'"/>
    <xsl:param name="separatingTokenLong" select="concat(' ', $separatingToken, ' ')"/>
    <xsl:param name="acceptedSearchFields">
        <acceptedSearchField>identifier</acceptedSearchField>
        <acceptedSearchField>title</acceptedSearchField>
        <acceptedSearchField>subject</acceptedSearchField>
        <acceptedSearchField>description</acceptedSearchField>
        <acceptedSearchField>genre</acceptedSearchField>
        <acceptedSearchField>relation</acceptedSearchField>
        <acceptedSearchField>coverage</acceptedSearchField>
        <acceptedSearchField>audience+level</acceptedSearchField>
        <acceptedSearchField>audience+rating</acceptedSearchField>
        <acceptedSearchField>creator</acceptedSearchField>
        <acceptedSearchField>contributor</acceptedSearchField>
        <acceptedSearchField>publisher</acceptedSearchField>
        <acceptedSearchField>rights</acceptedSearchField>
        <acceptedSearchField>extension</acceptedSearchField>
        <acceptedSearchField>location</acceptedSearchField>
        <acceptedSearchField>annotation</acceptedSearchField>
        <acceptedSearchField>date</acceptedSearchField>
        <acceptedSearchField>format</acceptedSearchField>
    </xsl:param>
    <xsl:param name="todaysDate" select="xs:date(current-date())"/>

    <xsl:template match="pma_xml_export">
        <!-- Process an xml export from cavafy's phpMyAdmin that includes urls -->
        <xsl:variable name="urls">
            <dc:url>
                <xsl:value-of select="
                        database/table/column[@name = 'url']"
                    separator="
                {$separatingTokenLong}"/>
            </dc:url>
        </xsl:variable>
        <xsl:variable name="newSoundsDupes">
            <xsl:apply-templates select="$urls"/>
        </xsl:variable>
        <xsl:variable name="newSoundsDupesDuplicated">
            <xsl:copy select="$newSoundsDupes/pb:pbcoreCollection">
                <xsl:for-each
                    select="$newSoundsDupes/pb:pbcoreCollection/pb:pbcoreDescriptionDocument">
                    <xsl:variable name="newAssetID" select="86536 + position()"/>
                    <xsl:copy>
                        <xsl:comment select="'************ORIGINAL ', pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog'], '**********'"/>
                        <xsl:copy-of select="*"/>
                    </xsl:copy>
                    <xsl:copy>
                        <xsl:comment select="'++++++++++++++++NEW ', $newAssetID, '++++++++++++++'"/>
                        <xsl:copy-of
                            select="*[following-sibling::pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog']]"/>
                        <pbcoreIdentifier source="WNYC Archive Catalog">
                            <xsl:value-of select="$newAssetID"/>
                        </pbcoreIdentifier>
                        <xsl:copy-of
                            select="*[preceding-sibling::pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog']]"
                        />
                    </xsl:copy>
                </xsl:for-each>
            </xsl:copy>
        </xsl:variable>
        <xsl:apply-templates select="$newSoundsDupesDuplicated" mode="importReady"/>
    </xsl:template>

    <xsl:template name="generateSearchString" match="." mode="generateSearchString">
        <!-- Generate a cavafy search string
        from given parameters -->

        <xsl:param name="textToSearch"/>
        <xsl:param name="field1ToSearch"/>
        <xsl:param name="field2ToSearch"/>

        <xsl:param name="searchTextMessage">
            <xsl:value-of
                select="
                    'Generate search string for text ',
                    '_',$textToSearch,'_',
                    '_ in field(s) ',
                    string-join(
                    ($field1ToSearch[. != ''],
                    $field2ToSearch[. != '']),
                    ', ')"
            />
        </xsl:param>

        <!-- Limiting facets in the search -->
        <xsl:param name="isPartOf"/>
        <!-- The 'collection' facet in cavafy
            actually looks for relations of type "is part of"-->
        <xsl:param name="series"/>
        <xsl:param name="subject"/>
        <xsl:param name="genre"/>
        <xsl:param name="coverage"/>
        <xsl:param name="contributor"/>
        <xsl:param name="location"/>

        <xsl:param name="facetsSearchMessage">
            <xsl:variable name="facetCount"
                select="
                    count(
                    ($isPartOf,
                    $series,
                    $subject,
                    $genre,
                    $coverage,
                    $contributor,
                    $location)
                    [. != '']
                    )"
            />
            <xsl:value-of
                select="
                    'Append a cavafy search string',                    
                    'with the following ', 
                    $facetCount, ' facets: '"/>
            <xsl:value-of
                select="
                    ('- relations is part of: ', $isPartOf)[$isPartOf != ''],
                    ('- series: ', $series)[$series != ''],
                    ('- subject: ', $subject)[$subject != ''],
                    ('- genre: ', $genre)[$genre != ''],
                    ('- coverage: ', $coverage)[$coverage != ''],
                    ('- contributor: ', $contributor)[$contributor != ''],
                    ('- location: ', $location)[$location != '']"
            />
        </xsl:param>

        <xsl:param name="facetsSearchString">
            <xsl:if test="$isPartOf">
                <xsl:value-of select="concat('&amp;facet_Collection%5B%5D=', $contributor)"/>
            </xsl:if>
            <xsl:if test="$series">
                <xsl:value-of select="concat('&amp;facet_Series+Title%5B%5D=', $series)"/>
            </xsl:if>
            <xsl:if test="$subject">
                <xsl:value-of select="concat('&amp;facet_Subject%5B%5D=', $subject)"/>
            </xsl:if>
            <xsl:if test="$genre">
                <xsl:value-of select="concat('&amp;facet_Genre%5B%5D=', $genre)"/>
            </xsl:if>
            <xsl:if test="$coverage">
                <xsl:value-of select="concat('&amp;facet_Genre%5B%5D=', $coverage)"/>
            </xsl:if>
            <xsl:if test="$contributor">
                <xsl:value-of select="concat('&amp;facet_Contributor%5B%5D=', $contributor)"/>
            </xsl:if>
            <xsl:if test="$location">
                <xsl:value-of select="concat('&amp;facet_Location%5B%5D=', $location)"/>
            </xsl:if>
        </xsl:param>

        <xsl:param name="appendSearchFieldString">
            <xsl:message select="
                'Make sure the fields to search ',
                '(',
                string-join(
                ($field1ToSearch, $field2ToSearch), ', '),
                ')',
                ' are kosher'"/>
            <xsl:if test="normalize-space($field1ToSearch)">
                <xsl:for-each
                    select="
                        WNYC:splitParseValidate($field1ToSearch, $separatingToken, '')
                        /valid
                        [translate(lower-case(normalize-space(.)), ' ', '+') = $acceptedSearchFields//*:acceptedSearchField]
                        ">
                    <xsl:value-of select="concat('&amp;search_fields%5B%5D=', $field1ToSearch)"/>
                </xsl:for-each>
            </xsl:if>
            <xsl:if test="normalize-space($field2ToSearch)">
                <xsl:for-each
                    select="
                        WNYC:splitParseValidate($field2ToSearch, $separatingToken, '')
                        /valid
                        [translate(lower-case(.), ' ', '+') = $acceptedSearchFields//*:acceptedSearchField]">
                    <xsl:value-of
                        select="concat('&amp;search_fields%5B%5D=', 
                        translate(lower-case(.), ' ', '+'))"
                    />
                </xsl:for-each>
            </xsl:if>
        </xsl:param>

        <xsl:param name="textSearchString"
            select="
            concat(
            '&amp;q=', 
            $textToSearch, 
            $appendSearchFieldString
            )"/>

        <!-- Convert spaces to plus signs -->
        <xsl:param name="completeSearchString"
            select="
                translate(
                concat(
                'https://cavafy.wnyc.org/?',
                $facetsSearchString,
                $textSearchString
                ),
                ' ', '+'
                )"/>

        <xsl:message select="$searchTextMessage"/>
        <xsl:message select="$facetsSearchMessage"/>
        <xsl:message
            select="
                'Complete search string: ',
                $completeSearchString"/>

        <completeSearchString>
            <xsl:value-of select="$completeSearchString"/>
        </completeSearchString>
    </xsl:template>

    <xsl:template name="checkResult"
        match="searchString[starts-with(., 'https://cavafy.wnyc.org/?')]" mode="checkResult">
        <!-- Retrieve and compile 
            paginated url results 
            from a cavafy search string -->

        <xsl:param name="searchString" select=".[starts-with(., 'https://cavafy.wnyc.org/?')]"/>

        <xsl:param name="minResults" as="xs:integer" select="1"/>
        <xsl:param name="maxResults" as="xs:integer" select="1000"/>
        <xsl:param name="stopIfTooMany" as="xs:boolean" select="false()"/>
        <xsl:param name="stopIfTooFew" as="xs:boolean" select="false()"/>
        <xsl:param name="htmlResult" select="document($searchString)"/>
<!--        <xsl:message select="'htmlResult: ', $htmlResult"/>-->
        <xsl:if test="$htmlResult/html/head/title[contains(., 'Sign in')]">
            <xsl:message terminate="yes">
                <xsl:value-of select="'Please log into cavafy.wnyc.org'"/>
            </xsl:message>
        </xsl:if>

        <xsl:if test="$minResults gt $maxResults">
            <xsl:message terminate="yes"
                select="
                    'ERROR: ',
                    'Your min results (', $minResults, ')',
                    'are bigger than your max results (', $maxResults, ').'"
            />
        </xsl:if>

        <xsl:variable name="totalResults">
            <xsl:value-of
                select="number(
                    $htmlResult
                    /xhtml:html/xhtml:head/xhtml:meta
                    [@name = 'totalResults']
                    /@content)"
            />
        </xsl:variable>
        <xsl:variable name="itemsPerPage">
            <xsl:value-of
                select="number(
                    $htmlResult
                    /xhtml:html/xhtml:head/xhtml:meta
                    [@name = 'itemsPerPage']
                    /@content)"
            />
        </xsl:variable>
        <xsl:variable name="totalPages"
            select="$totalResults
                div
                $itemsPerPage
                "/>
        <xsl:variable name="resultsMessage"
            select="
                concat(
                $totalResults, ' result(s)',
                ' from search string ', $searchString, '.',
                ' Allowed range: ', $minResults, '-', $maxResults,
                'Items Per Page: ', $itemsPerPage,
                'Total Pages: ', ceiling($totalPages)
                )
                "/>
        <xsl:message select="$resultsMessage"/>

        <xsl:choose>
            <xsl:when test="$totalResults &lt; $minResults">
                <xsl:message terminate="{$stopIfTooFew}" select="'ATTENTION!', $resultsMessage"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'too_few_cavafy_results'"/>
                    <xsl:value-of select="$resultsMessage"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$totalResults &gt; $maxResults">
                <xsl:message terminate="{$stopIfTooMany}" select="'ATTENTION!', $resultsMessage"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'too_many_cavafy_results'"/>
                    <xsl:value-of select="$resultsMessage"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment select="$resultsMessage"/>
                <searchResults>
                    <xsl:attribute name="searchString" select="$searchString"/>
                    <xsl:attribute name="totalResults" select="$totalResults"/>
                    <xsl:call-template name="pageResults">
                        <xsl:with-param name="pageNumber" select="1"/>
                        <xsl:with-param name="searchString" select="$searchString"/>
                        <xsl:with-param name="totalPages" select="$totalPages"/>
                    </xsl:call-template>
                </searchResults>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="pageResults">
        <!-- Retrieve the asset URLs
            from the html pages 
            with the search results -->
        <xsl:param name="pageNumber" select="1"/>
        <xsl:param name="searchString"/>
        <xsl:param name="pageSearchString" select="concat('&amp;page=', $pageNumber)"/>
        <xsl:param name="totalPages"/>

        <xsl:variable name="searchStringWithPage" select="concat($searchString, $pageSearchString)"/>
        <xsl:variable name="searchResult">
            <xsl:copy-of select="document($searchStringWithPage)"/>
        </xsl:variable>

        <xsl:message>
            <xsl:value-of
                select="
                    'Now searching page ', $pageNumber,
                    '... Using search ', $searchStringWithPage
                    "
            />
        </xsl:message>

        <!-- Navigate the html document
        to find the listed assets' URLs -->
        <xsl:for-each
            select="
                $searchResult
                /xhtml:html/xhtml:body
                /xhtml:table/xhtml:tr
                /xhtml:td/xhtml:table
                /xhtml:tr/xhtml:td
                /xhtml:div/xhtml:div
                /xhtml:h2/xhtml:a
                /@href">

            <xsl:message select="'cavafy url found: ', string(.)"/>

            <url>
                <xsl:value-of select="."/>
            </url>
        </xsl:for-each>

        <xsl:message>
            <xsl:value-of
                select="concat('Page number ', $pageNumber, ' of ', $totalPages, ' completed.')"/>
        </xsl:message>

        <xsl:if test="number($pageNumber) &lt; number($totalPages)">
            <xsl:call-template name="pageResults">
                <xsl:with-param name="searchString" select="$searchString"/>
                <xsl:with-param name="pageNumber" select="number(number($pageNumber) + 1)"/>
                <xsl:with-param name="totalPages" select="$totalPages"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="findCavafyXMLs" match="." mode="
        findCavafyXMLs">
        <!-- Obtain the cavafy XMLs 
        from a search using specific parameters.-->
        <!-- Inputs: 
            1. A string to search in cavafy
            plus two fields in which to search
            for that string
            2. Several facets to limit that search
            such as collection, series or subjects.
            
            Output:
            The cavafy xmls for each record found
            as a pbcoreCollection.
         -->

        <xsl:param name="textToSearch"/>
        <xsl:param name="field1ToSearch"/>
        <xsl:param name="field2ToSearch"/>
        <xsl:param name="isPartOf"/>
        <!-- Called 'Collection' in cavafy -->
        <xsl:param name="series"/>
        <xsl:param name="subject"/>
        <xsl:param name="genre"/>
        <xsl:param name="contributor"/>
        <xsl:param name="location"/>
        <xsl:param name="coverage"/>

        <xsl:param name="searchString">
            <xsl:call-template name="generateSearchString">
                <xsl:with-param name="textToSearch" select="$textToSearch"/>
                <xsl:with-param name="field1ToSearch" select="$field1ToSearch"/>
                <xsl:with-param name="field2ToSearch" select="$field2ToSearch"/>

                <xsl:with-param name="isPartOf" select="$isPartOf"/>
                <xsl:with-param name="series" select="$series"/>
                <xsl:with-param name="subject" select="$subject"/>
                <xsl:with-param name="genre" select="$genre"/>
                <xsl:with-param name="contributor" select="$contributor"/>
                <xsl:with-param name="location" select="$location"/>
                <xsl:with-param name="coverage" select="$coverage"/>
            </xsl:call-template>
        </xsl:param>

        <xsl:param name="minResults" as="xs:integer" select="1"/>
        <xsl:param name="maxResults" as="xs:integer" select="1000"/>
        <xsl:param name="stopIfTooMany" as="xs:boolean" select="false()"/>
        <xsl:param name="stopIfTooFew" as="xs:boolean" select="false()"/>

        <xsl:param name="cavafyURLs">
            <xsl:call-template name="checkResult">
                <xsl:with-param name="searchString"
                    select="$searchString[contains(., 'https://cavafy.wnyc.org/')]"/>
                <xsl:with-param name="minResults" select="$minResults"/>
                <xsl:with-param name="maxResults" select="$maxResults"/>
                <xsl:with-param name="stopIfTooMany" select="$stopIfTooMany"/>
                <xsl:with-param name="stopIfTooFew" select="$stopIfTooFew"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="urls">
            <xsl:value-of select="$cavafyURLs/*:searchResults/*:url"
                separator="{$separatingTokenLong}"/>
        </xsl:param>
        <xsl:param name="findResultsMessage">
            <xsl:value-of select="
                'Find between', $minResults, ' and ', $maxResults,
                'cavafy XMLs'"/>
            <xsl:value-of select="' with facets ',
                $textToSearch, $series, $subject, $contributor, 
                $genre, $isPartOf, $location"/>
            <xsl:value-of select="
                ' within fields ', $field1ToSearch, $field2ToSearch"/>
            <xsl:value-of select="
                ' using search string ', $searchString, '. '"/>
            <xsl:value-of select="'Result URLs: ', $cavafyURLs"/>
        </xsl:param>
        <xsl:message select="$findResultsMessage"/>
        <xsl:copy-of select="$cavafyURLs[//local-name() = 'error']"/>
        <xsl:call-template name="generatePbCoreCollection">
            <xsl:with-param name="urls" select="$urls"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="url"
        xpath-default-namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
        <xsl:apply-templates select="." mode="generatePbCoreCollectionWRepeats"/>
    </xsl:template>

    <xsl:template name="generatePbCoreCollectionWRepeats" match="url"
        mode="generatePbCoreCollectionWRepeats"
        xpath-default-namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
        <!-- From a token-separated list of URLs,
        generate a pbcore collection
        of xmls including repeats -->
        <xsl:param name="urls" select="."/>
        <xsl:message
            select="
                'From a token-separated list of URLs, ',
                'generate a pbcore collection of xmls ',
                'including repeats'"/>

        <xsl:element name="pbcoreCollection">
            <xsl:namespace name="xsi" select="'http://www.w3.org/2001/XMLSchema-instance'"/>
            <xsl:attribute name="xsi:schemaLocation"
                select="'http://pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd'"/>

            <xsl:for-each select="
                    tokenize($urls, $separatingToken)">
                <xsl:call-template name="generatePbCoreDescriptionDocument">
                    <xsl:with-param name="url" select="normalize-space(.)"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>

    <xsl:template match="dc:url">
        <!-- Process a set of urls 
        result of a mySQL search
        and exported as xml -->
        <xsl:apply-templates select="." mode="generatePbCoreCollection"/>
    </xsl:template>

    <xsl:template name="generatePbCoreCollection" match="dc:url" mode="generatePbCoreCollection">
        <!-- From a token-separated list of URLs,
        generate a pbcore collection
        of UNIQUE xmls ready for import -->
        <xsl:param name="urls" select="."/>
        <xsl:message
            select="
                'From a token-separated list of URLs, ',
                'generate a pbcore collection of unique xmls ',
                'ready for import: '">
            <xsl:value-of select="$urls"/>
        </xsl:message>
        <xsl:variable name="parsedURLS" select="
            WNYC:splitParseValidate(
            $urls, $separatingToken, $cavafyValidatingString)"/>
        <xsl:for-each
            select="
                $parsedURLS/invalid">
            <xsl:message select="'Invalid entry:', ."/>
            <xsl:element name="error">
                <xsl:attribute name="type" select="
                        'invalid_cavafy_URL'"/>
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:for-each>

        <xsl:element name="pbcoreCollection">
            <xsl:namespace name="xsi" select="'http://www.w3.org/2001/XMLSchema-instance'"/>
            <xsl:attribute name="xsi:schemaLocation"
                select="'http://pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd'"/>

            <xsl:for-each
                select="$parsedURLS/valid">
                <xsl:message select="'Valid entry: ', ."/>
                <xsl:call-template name="generatePbCoreDescriptionDocument">
                    <xsl:with-param name="url" select="."/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>

    <xsl:template name="generatePbCoreDescriptionDocument" match="dc:url"
        mode="generatePbCoreDescriptionDocument">
        <!-- From a single cavafy URL,
        generate a pbcore description document 
        -->

        <xsl:param name="url" select="."/>
        <xsl:param name="parsedURL"
            select="
                WNYC:splitParseValidate(
                $url, $separatingToken, $cavafyValidatingString
                )"/>
        <xsl:message
            select="
                'Generate a pbcore description document',
                ' from URL', $url"/>
        <!-- Reject non-cavafy URLs -->
        <xsl:for-each select="$parsedURL/invalid">
            <xsl:element name="error">
                <xsl:attribute name="type" select="'invalid_cavafy_URL'"/>
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:for-each>
        <xsl:for-each select="$parsedURL/valid[ends-with(., '.xml')]">
            <xsl:variable name="pbcoreDocument" select="document(.)"/>
            <xsl:copy-of select="$pbcoreDocument"/>
            <xsl:message>
                <xsl:value-of select="'pbcoreDocument from url', $url, ': '"/>
                <xsl:copy-of select="$pbcoreDocument"/>
            </xsl:message>
        </xsl:for-each>
        <xsl:for-each select="$parsedURL/valid[not(ends-with(., '.xml'))]">
            <xsl:variable name="pbcoreDocument" select="document(concat(., '.xml'))"/>
            <xsl:copy-of select="$pbcoreDocument"/>
            <xsl:message>
                <xsl:value-of select="'pbcoreDocument from url', $url, ': '"/>
                <xsl:value-of
                    select="
                        $pbcoreDocument/pb:pbcoreDescriptionDocument/
                        pb:pbcoreTitle, 'etc.'"
                    separator=" | "/>
            </xsl:message>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="findSpecificCavafyAssetXML" match="." mode="findSpecificCavafyAssetXML">
        <!-- Search for records with specific Asset ID 
        (which should be unique) -->

        <xsl:param name="assetID"/>
        <xsl:param name="additionalTextToSearch"/>
        <xsl:param name="textToSearch">
            <xsl:value-of select="$assetID"/>
            <xsl:if test="$additionalTextToSearch">
                <xsl:value-of select="concat('+', $additionalTextToSearch)"/>
            </xsl:if>
        </xsl:param>
        <xsl:param name="additionalFieldsToSearch"/>

        <xsl:param name="isPartOf"/>
        <xsl:param name="series"/>
        <xsl:param name="subject"/>
        <xsl:param name="genre"/>
        <xsl:param name="contributor"/>
        <xsl:param name="location"/>
        <xsl:param name="coverage"/>

        <xsl:param name="searchString">
            <xsl:call-template name="generateSearchString">
                <xsl:with-param name="textToSearch" select="$textToSearch"/>
                <xsl:with-param name="field1ToSearch" select="'identifier'"/>
                <xsl:with-param name="field2ToSearch" select="$additionalFieldsToSearch"/>

                <xsl:with-param name="isPartOf" select="$isPartOf"/>
                <xsl:with-param name="series" select="$series"/>
                <xsl:with-param name="subject" select="$subject"/>
                <xsl:with-param name="genre" select="$genre"/>
                <xsl:with-param name="contributor" select="$contributor"/>
                <xsl:with-param name="location" select="$location"/>
                <xsl:with-param name="coverage" select="$coverage"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="stopIfTooMany" as="xs:boolean" select="false()"/>
        <xsl:param name="stopIfTooFew" as="xs:boolean" select="false()"/>

        <xsl:message
            select="
                'Search for records with specific Asset ID ',
                string($assetID), '(which should be unique)'"/>

        <!-- Initial cavafy search -->
        <xsl:variable name="foundAssets">
            <xsl:call-template name="findCavafyXMLs">
                <xsl:with-param name="searchString" select="$searchString"/>
                <xsl:with-param name="minResults" select="1"/>
                <xsl:with-param name="maxResults" select="20"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:message>
            <xsl:value-of select="'Found asset IDs: '"/>
            <xsl:value-of select="
                $foundAssets/pb:pbcoreCollection/pb:pbcoreDescriptionDocument/
                pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog']" separator=" ; "/>
        </xsl:message>
        <xsl:variable name="matchingAssets">
            <xsl:copy-of
                select="
                    $foundAssets/pb:pbcoreCollection/pb:pbcoreDescriptionDocument
                    [pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog'] = $assetID]"
            />
        </xsl:variable>

        <xsl:variable name="resultsCount"
            select="
                count(
                $matchingAssets
                /pb:pbcoreDescriptionDocument
                )"/>

        <xsl:variable name="resultsMessage"
            select="
                concat($resultsCount, ' matching assets ',
                'with asset ID ', $assetID,
                ' using search string ', $searchString, ': ')
                "/>

        <xsl:message select="$resultsMessage"/>

        <!-- Errors when not a single matching asset -->
        <xsl:choose>
            <xsl:when test="$resultsCount &lt; 1">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'no_matching_asset'"/>
                    <xsl:attribute name="assetID" select="$assetID"/>
                    <xsl:copy-of
                        select="$resultsMessage"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$resultsCount &gt; 1">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'too_many__matching_assets'"/>
                    <xsl:attribute name="assetID" select="$assetID"/>
                    <xsl:copy-of
                        select="
                            'ATTENTION!',
                            $resultsMessage"
                    />
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="matchingAssetUUID" select="
                    $matchingAssets/
                    pb:pbcoreDescriptionDocument/
                    pb:pbcoreIdentifier[@source='pbcore XML database UUID']"/>
                <xsl:variable name="matchingAssetURL" select="
                    concat(
                    'https://cavafy.wnyc.org/assets/', 
                    $matchingAssetUUID)"/>                    
                <xsl:message select="'Final cavafy entry URL: ', 
                    $matchingAssetURL"/>
                <xsl:copy-of select="$matchingAssets"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="findSeriesXML" match="seriesAcronym" mode="findSeriesXML">
        <!-- Find the series info in cavafy
        from the series acronym -->
        <!-- Series information is stored in cavafy
                with a relation 'SRSLST' 
                of relationType 'other'.            
            It includes default hosts, 
            genres and subject headings -->
        <xsl:param name="seriesAcronym" select="."/>
        <xsl:param name="findSeriesMessage"
            select="
                concat(
                'Find the series data in cavafy ',
                'from the series acronym ', $seriesAcronym
                )"/>
        <xsl:message select="$findSeriesMessage"/>
        <xsl:variable name="seriesSearchResult">
            <xsl:call-template name="findSpecificCavafyAssetXML">
                <xsl:with-param name="textToSearch" select="concat('SRSLST+', $seriesAcronym)"/>
                <xsl:with-param name="assetID" select="$seriesAcronym"/>
                <xsl:with-param name="additionalFieldsToSearch" select="'relation'"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$seriesSearchResult[//*:error[@type = 'no_matching_asset']]">
                <xsl:variable name="noSeriesFound"
                    select="'No series found with acronym ', $seriesAcronym"/>
                <xsl:message select="$noSeriesFound"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'no_series_found'"/>
                    <xsl:value-of select="$noSeriesFound"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$seriesSearchResult[//*:error[@type = 'too_many_matching_assets']]">
                <xsl:variable name="multipleSeriesFound"
                    select="'Multiple series found with acronym ', $seriesAcronym"/>
                <xsl:message select="$multipleSeriesFound"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'multiple_series_found'"/>
                    <xsl:value-of select="$multipleSeriesFound"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$seriesSearchResult"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="findSeriesXMLFromName" match="
        seriesName|pb:pbcoreTitle[@titleType='Series']" mode="
        findSeriesXMLFromName">
        <!-- Find the series info in cavafy
        from the series name -->
        <!-- Series information is stored in cavafy
                with a relation 'SRSLST' 
                of relationType 'other'.            
            It includes default hosts, 
            genres and subject headings -->
        <xsl:param name="seriesName" select="."/>        
        <xsl:param name="searchString">
            <xsl:call-template name="generateSearchString">
                <xsl:with-param name="textToSearch" select="
                    concat('SRSLST+', encode-for-uri($seriesName[1]))"/>
                <xsl:with-param name="field1ToSearch" select="'title'"/>
                <xsl:with-param name="field2ToSearch" select="'relation'"/>
                <xsl:with-param name="series" select="encode-for-uri($seriesName[1])"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="message"
            select="concat(
            'Find the series info in cavafy ',
            'from the series name ', $seriesName[1],
            ' using search string ', $searchString)"/>
        <xsl:message select="$message"/>
        <xsl:call-template name="findCavafyXMLs">
            <xsl:with-param name="searchString" select="$searchString"/>
            <xsl:with-param name="minResults" select="1"/>
            <xsl:with-param name="maxResults" select="1"/>
            <xsl:with-param name="stopIfTooFew" select="true()"/>
            <xsl:with-param name="stopIfTooMany" select="true()"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="generateNextFilename" match="
        instantiationID | 
        pb:instantiationIdentifier
        [@source = 'WNYC Media Archive Label']"
        mode="generateNextFilename">
        <!-- Generate the name of the derivative file
        according to the NYPR naming convention:
        COLL-SERI-YYYY-MM-DD-1234.5 [Free text] -->
        <xsl:param name="instantiationID">
            <xsl:copy-of select="."/>
            <xsl:message select="
                'Generate the derivative filename',
                ' for instantiation ', ."/>
        </xsl:param>  
        <xsl:param name="instantiationIDParsed">
            <xsl:call-template name="parseInstantiationID">
                <xsl:with-param name="instantiationID" select="
                    $instantiationID"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="assetID" select="
            $instantiationIDParsed/instantiationIDParsed/assetID"/>  
        <xsl:param name="instantiationSuffixComplete" select="
            $instantiationIDParsed/instantiationIDParsed/
                instantiationSuffixComplete"/>
        <xsl:param name="instantiationSuffixDigit" select="
                $instantiationIDParsed/instantiationIDParsed/
                instantiationSuffixDigit"/>        
        <xsl:param name="instantiationSegmentSuffix" select="
            $instantiationIDParsed/instantiationIDParsed/
            instantiationSegmentSuffix"/>
        <xsl:param name="instantiationIDwOutSuffixSegment" select="
            $instantiationIDParsed/instantiationIDParsed/
            instantiationIDwOutSuffixSegment"/> 
        <xsl:param name="instantiationSuffixMT" select="
            $instantiationIDParsed/instantiationIDParsed/
            instantiationSuffixMT"/>
        <xsl:param name="instantiationFirstTrack" select="
            $instantiationIDParsed/instantiationIDParsed/
            instantiationFirstTrack[matches(., '\d')]" as="xs:integer*"/>
        <xsl:param name="instantiationLastTrack"
            select="$instantiationIDParsed/instantiationIDParsed/
            instantiationLastTrack[matches(., '\d')]" as="xs:integer*"/>
        <xsl:param name="precedingSiblings">
            <!-- Preceding instantiations
            from same asset in this document -->
            <xsl:copy-of select="
                preceding-sibling::instantiationID
                [starts-with(., concat($assetID, '.'))]
                [not(starts-with(., $instantiationIDwOutSuffixSegment))]"/>
        </xsl:param>
        <xsl:param name="precedingSiblingLevelsCount">
            <!-- Count of preceding instantiation levels
            (defined as 
            a group of one or more instantiations 
            sharing the same numeric ID, 
            e.g. 1234.5a and 1234.5b 
            are two instantiations 
            at the same level, 
            but 1234.5a and 1234.6
            are in separate levels) -->
            <xsl:value-of
                select="
                    count(distinct-values(
                    $precedingSiblings//instantiationID/
                    analyze-string(
                    ., '[a-zA-Z]'
                    )/fn:non-match[1]))"
            />
        </xsl:param>        
        <xsl:param name="foundAsset">
            <xsl:call-template name="findSpecificCavafyAssetXML">
                <xsl:with-param name="assetID" select="$assetID"/>
            </xsl:call-template>
        </xsl:param>
        
        <xsl:param name="foundInstantiation">
            <xsl:call-template name="findInstantiation">
                <xsl:with-param name="instantiationID" select="$instantiationID"/>
                <xsl:with-param name="cavafyEntry" select="$foundAsset"/>
                <xsl:with-param name="overwriteError" select="false()"/>
            </xsl:call-template>
        </xsl:param>        
        <xsl:param name="collection"
            select="
                $foundAsset/pb:pbcoreDescriptionDocument
                /pb:pbcoreTitle[@titleType = 'Collection']"/>
        <xsl:param name="seriesXML">
            <xsl:call-template name="findSeriesXMLFromName">
                <xsl:with-param name="seriesName"
                    select="
                        $foundAsset/pb:pbcoreDescriptionDocument
                        /pb:pbcoreTitle[@titleType = 'Series']"
                />
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="seriesAcronym">
            <xsl:value-of select="
                $seriesXML//pb:pbcoreIdentifier
                [@source = 'WNYC Archive Catalog']"
            />
        </xsl:param>
        <xsl:param name="filenameDate">
            <xsl:call-template name="earliestDate">
                <xsl:with-param name="cavafyXML" select="
                    $foundAsset/pb:pbcoreDescriptionDocument"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="instantiationIDOffset" select="
            number($precedingSiblingLevelsCount)"/>
        <xsl:param name="nextInstantiationSuffixDigit">
            <xsl:call-template name="nextInstantiationSuffixDigit">
                <xsl:with-param name="instantiationID"
                    select="
                        $instantiationID"/>
                <xsl:with-param name="foundAsset" select="
                        $foundAsset"/>
            <xsl:with-param name="instantiationIDOffset" select="
                    $instantiationIDOffset"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="freeTextInsert"/>
        <xsl:param name="freeTextOtherAssetIDs">
            <xsl:value-of
                select="
                    $foundAsset/pb:pbcoreDescriptionDocument/
                    pb:pbcoreIdentifier
                    [@source != 'WNYC Archive Catalog']
                    [@source != 'pbcore XML database UUID']"
                separator=" "/>
        </xsl:param>
        <xsl:param name="freeTextShortenedTitle">
            <!-- A shortened version of the title -->
            <xsl:variable name="abbreviatedText">
                <xsl:call-template name="abbreviateText">
                    <xsl:with-param name="maxTitleLength" select="
                            50"/>
                    <xsl:with-param name="text"
                        select="
                            $foundAsset/pb:pbcoreDescriptionDocument/
                            pb:pbcoreTitle[@titleType = 'Episode']"
                    />
                </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="ASCII:ASCIIFier($abbreviatedText/abbreviatedText)"/>
        </xsl:param>
        <xsl:param name="freeTextComplete">
            <xsl:value-of
                select="
                    normalize-space(
                    string-join(
                    ($freeTextInsert,
                    $freeTextOtherAssetIDs,
                    $freeTextShortenedTitle), ' ')
                    )"
            />
        </xsl:param>
        
        <xsl:message select="
            'Previous instantiation levels in this document for', 
            $instantiationID, ':', 
            $precedingSiblingLevelsCount"/>
        <!-- If instantiation is multitrack, generate one filename per track -->
        <xsl:choose>
            <xsl:when test="
                $instantiationLastTrack gt $instantiationFirstTrack">
                <xsl:for-each select="$instantiationFirstTrack to $instantiationLastTrack">
                    <xsl:call-template name="generateNextFilename">
                        <xsl:with-param name="instantiationID"
                            select="
                                concat(substring-before($instantiationID, '_TK'), '_TK', .)"/>
                        <xsl:with-param name="assetID" select="$assetID"/>
                        <xsl:with-param name="filenameDate" select="$filenameDate"/>
                        <xsl:with-param name="instantiationSuffixMT" select="."/>
                        <xsl:with-param name="instantiationFirstTrack" select="."/>
                        <xsl:with-param name="instantiationLastTrack" select="."/>
                        <xsl:with-param name="foundAsset" select="$foundAsset"/>
                        <xsl:with-param name="foundInstantiation" select="$foundInstantiation"/>
                        <xsl:with-param name="collection" select="$collection"/>
                        <xsl:with-param name="seriesAcronym" select="$seriesAcronym"/>
                        <xsl:with-param name="seriesXML" select="$seriesXML"/>
                        <xsl:with-param name="precedingSiblings" select="$precedingSiblings"/>
                        <xsl:with-param name="precedingSiblingLevelsCount"
                            select="$precedingSiblingLevelsCount"/>
                        <xsl:with-param name="freeTextComplete" select="$freeTextComplete"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="nextFilenameNoFreeText">
                    <xsl:value-of
                        select="
                        concat(
                        $collection, '-',
                        $seriesAcronym, '-',
                        $filenameDate, '-',
                        $assetID, '.',
                        $nextInstantiationSuffixDigit,
                        $instantiationSegmentSuffix,
                        (concat('_TK', $instantiationFirstTrack))[$instantiationFirstTrack gt 0],
                        ' SEGMENT'[$instantiationSegmentSuffix != ''])"
                    />
                </xsl:variable>
                <xsl:variable name="newFreeText">
                    <xsl:call-template name="abbreviateText">
                        <xsl:with-param name="maxTitleLength"
                            select="
                            79 - string-length($nextFilenameNoFreeText)"/>
                        <xsl:with-param name="text" select="$freeTextComplete[1]"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:message select="concat(
                    'New Free text: ', $newFreeText//abbreviatedText)"/>
                <xsl:variable name="newFilename">
                    <xsl:value-of
                        select="
                        string-join(
                        ($nextFilenameNoFreeText,
                        $newFreeText/abbreviatedText), ' ')"
                    />
                </xsl:variable>
                <xsl:message select="'NEW FILENAME: ', $newFilename"/>
                <inputs>
                    <originalInstantiationID>
                        <xsl:value-of select="$instantiationID"/>
                    </originalInstantiationID>
                    <cavafyEntry>
                        <xsl:copy-of select="$foundAsset"/>
                    </cavafyEntry>
                    <parsedDAVIDTitle>
                        <xsl:attribute name="DAVIDTitle" select="$newFilename"/>
                        <parsedElements>
                            <seriesData>
                                <xsl:copy-of select="$seriesXML"/>
                            </seriesData>
                            <xsl:copy-of select="$foundInstantiation"/>
                        </parsedElements>
                    </parsedDAVIDTitle>
                </inputs>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>

    <xsl:template name="findInstantiation" match="instantiationID" mode="
        processInstantiation">
        <!-- Find a specific instantiationID in cavafy -->
        <!-- NOTE: mode "processInstantiation"
        is part of a set
        along with template
        "nextInstantiationID"-->
        <xsl:param name="overwriteError" select="true()"/>
        <xsl:param name="instantiationID" select="."/>
        <xsl:param name="assetID" select="
                substring-before($instantiationID, '.')"/>
        <xsl:param name="cavafyEntry">
            <xsl:call-template name="findSpecificCavafyAssetXML">
                <xsl:with-param name="assetID" select="$assetID"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="instantiationSuffix" select="substring-after($instantiationID, '.')"/>
        <xsl:param name="format"/>
        <xsl:param name="translatedFormat"
            select="
                if (upper-case($format) = 'WAV')
                then
                    'BWF'
                else
                    $format"/>
        <xsl:message>
            <xsl:value-of select="'Find instantiation info for ', $instantiationID"/>
            <xsl:value-of select="(' of format ', $translatedFormat)[$translatedFormat !='']"/>            
        </xsl:message>
        <xsl:variable name="matchedInstantiation"
            select="
                $cavafyEntry
                //pb:pbcoreInstantiation
                [pb:instantiationIdentifier = $instantiationID]"/>
        <xsl:message select="'Matched instantiation:', $matchedInstantiation"/>
        <xsl:variable name="matchedInstantiationID"
            select="
                $matchedInstantiation
                /pb:instantiationIdentifier
                [. = $instantiationID]"/>
        <xsl:message>
            <xsl:value-of
                select="
                    count(
                    $matchedInstantiation),
                    ' instantiations with ID ',
                    $instantiationID,
                    ' found in cavafy.'"
            />
        </xsl:message>
        <xsl:variable name="matchedInstantiationIDSource">
            <xsl:value-of select="
                    $matchedInstantiationID/@source"/>
        </xsl:variable>
        <instantiationData>
            <!-- Generate error if
            there is more than one instantiation
            with this ID -->
            <xsl:if test="
                    count($matchedInstantiation) gt 1">
                <xsl:variable name="errorMessage"
                    select="
                        'ATTENTION!!!',
                        'Instantiation ID ', $instantiationID,
                        ' is not unique.'"/>
                <xsl:message select="$errorMessage"/>
                <xsl:element name="error">
                    <xsl:attribute name="type"
                        select="
                            'multiple_instantiation_IDs',
                            $instantiationID"/>
                    <xsl:value-of select="$errorMessage"/>
                </xsl:element>
            </xsl:if>
            
            <xsl:if test="$matchedInstantiationID">
                <xsl:variable name="matchedInstantiationFormat"
                    select="
                        $matchedInstantiation
                        /*:instantiationData
                        /pb:pbcoreInstantiation
                        /(pb:instantiationPhysical | pb:instantiationDigital)
                        [. != '']"/>
                <xsl:choose>
                    <!--Generate error if instantiation formats do not match -->
                    <xsl:when
                        test="
                            ($matchedInstantiationFormat
                            != $translatedFormat) and $overwriteError">
                        <xsl:variable name="errorMessage"
                            select="
                                'ATTENTION!!!',
                                ' You are about to wipe out instantiation ',
                                $instantiationID,
                                ', a ', $matchedInstantiationFormat, ', ',
                                ' with a ', $translatedFormat, '!!!'"/>
                        <xsl:message terminate="no" select="$errorMessage"/>
                        <xsl:element name="error">
                            <xsl:attribute name="type" select="'mismatched_format'"/>
                            <xsl:value-of select="$errorMessage"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when
                        test="
                            $matchedInstantiationIDSource != 'WNYC Media Archive Label'">
                        <xsl:variable name="errorMessage"
                            select="
                                'ATTENTION! ',
                                'Instantiation ID ',
                                $matchedInstantiationID,
                                ' has a nonstandard ID source: ',
                                $matchedInstantiationIDSource,
                                '&#10;',
                                'Please change to WNYC Media Archive Label.'"/>
                        <xsl:message select="$errorMessage"/>
                        <xsl:element name="error">
                            <xsl:attribute name="type"
                                select="
                                    'nonstandard_instantiationID_source',
                                    $matchedInstantiationID"/>
                            <xsl:value-of select="$errorMessage"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$matchedInstantiation"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </instantiationData>
    </xsl:template>

    <xsl:template name="earliestDate" match="pb:pbcoreDescriptionDocument" mode="earliestDate">
        <!-- Find the earliest specific date 
        or the most specific unknown date.
        This is used to generate filename dates.
        We assume that unknown dates
        are always earlier than known dates -->
        <xsl:param name="cavafyXML" select="."/>
        <xsl:message
            select="concat(
                'Find earliest date in asset ',
                $cavafyXML
                /pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog'])"/>

        <xsl:variable name="earliestKnownDate"
            select="
                min(
                $cavafyXML/pb:pbcoreAssetDate[not(contains(., 'u'))]
                /xs:date(.)
                )"/>
        <!-- The most specific unknown date 
        uses the min() function 
        because numbers come before 'u' -->
        <xsl:variable name="mostSpecificUnknownDate"
            select="
                min(
                $cavafyXML/pb:pbcoreAssetDate
                [contains(., 'u')]/
                xs:string(.)
                )"
        />
        <xsl:variable name="filenameDate"
            select="
                if ($mostSpecificUnknownDate)
                then
                    $mostSpecificUnknownDate
                else
                    if (string($earliestKnownDate) !='')
                    then
                        $earliestKnownDate
                    else
                        'uuuu-uu-uu'
                "
        />
        <xsl:value-of select="$filenameDate"/>
    </xsl:template>

    <xsl:template name="nextInstantiationSuffixDigit"
        match="
            instantiationID |
            pb:instantiationIdentifier
            [@source = 'WNYC Media Archive Label']"
        mode="processInstantiation">
        <!-- Generate the next instantiation ID
            in an asset.
        This is used for generating filenames. -->
        <!-- NOTE: mode "processInstantiation"
        is part of a set
        along with template
        "findInstantiation"-->
        <xsl:param name="instantiationID" select="."/>
        <xsl:param name="instantiationIDOffset" select="0"/>
        <xsl:param name="instantiationIDParsed">
            <xsl:apply-templates select="$instantiationID"
                mode="
                parseInstantiationID"/>
        </xsl:param>
        <xsl:param name="assetID"
            select="
                $instantiationIDParsed/instantiationIDParsed/assetID"/>
        <xsl:param name="foundAsset">
            <xsl:call-template name="findSpecificCavafyAssetXML">
                <xsl:with-param name="assetID"
                    select="
                        substring-before($instantiationID, '.')"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:message
            select="
                concat(
                'Find next instantiation suffix digit for ', $instantiationID,
                ' in asset ', $assetID,
                ' with offset of ', $instantiationIDOffset)"/>
        <xsl:variable name="cavafyInstantiationIDsParsed">
            <xsl:apply-templates
                select="
                    $foundAsset
                    /pb:pbcoreDescriptionDocument
                    /pb:pbcoreInstantiation
                    /pb:instantiationIdentifier
                    [@source = 'WNYC Media Archive Label']"
                mode="
                parseInstantiationID"/>
        </xsl:variable>
        <xsl:variable name="maxinstantiationSuffixDigit"
            select="
                max
                (
                $cavafyInstantiationIDsParsed/instantiationIDParsed/instantiationSuffixDigit
                )"/>
        <xsl:variable name="nextInstantiationSuffixDigit">
            <xsl:value-of select="$maxinstantiationSuffixDigit + $instantiationIDOffset + 1"/>
        </xsl:variable>
        <xsl:message>
            <xsl:value-of select="
                'Highest instantiation suffix digit in asset', 
                $assetID, 
                'is', $maxinstantiationSuffixDigit, '.'"/>
            <xsl:value-of select="
                ' The offset is', 
                $instantiationIDOffset, '.'"/>
            <xsl:value-of select="
                ' So the next instantiation suffix digit should be', 
                $nextInstantiationSuffixDigit, '.'"/>
        </xsl:message>
        <xsl:value-of select="$nextInstantiationSuffixDigit"/>
    </xsl:template>

    <xsl:template name="anniversaries" match="." mode="anniversaries">
        <!-- Find entries in cavafy 
            from x years ago (default 50) -->
        <xsl:param name="todaysDate" select="$todaysDate"/>
        <xsl:param name="xYears" select="50"/>
        <xsl:param name="year50YearsAgo"
            select="
                year-from-date($todaysDate) - $xYears"/>
        <xsl:param name="todaysDateFormatted"
            select="
                format-date(
                $todaysDate, '[Y0001]-[M01]-[D01]'
                )"/>
        <xsl:param name="dateXYearsAgo"
            select="
                concat(
                string($year50YearsAgo),
                '-',
                substring-after($todaysDateFormatted, '-'))"/>

        <xsl:param name="xYearsAgoCavafySearchString"
            select="
            concat(
            'https://cavafy.wnyc.org/assets?q=',
            $dateXYearsAgo,
            '&amp;search_fields%5B%5D=date'
            )"/>

        <xsl:element name="xYearsAgoResult">
            <xsl:call-template name="checkResult">
                <xsl:with-param name="searchString" select="$xYearsAgoCavafySearchString"/>
            </xsl:call-template>
        </xsl:element>
    </xsl:template>

    <xsl:template name="findSpecificNewSoundsProgramNoXML" match="programNo"
        mode="findSpecificNewSoundsProgramNoXML">
        <!-- Search for records with specific New Sounds Program ID 
        (which should be unique) -->

        <xsl:param name="newSoundsEpisodeID" select="."/>
        <xsl:param name="newSoundsEpisodeIDPadded"
            select="
                format-number($newSoundsEpisodeID, '0000')"/>
        <xsl:param name="additionalTextToSearch"/>
        <xsl:param name="textToSearch">
            <xsl:value-of select="$newSoundsEpisodeIDPadded"/>
            <xsl:if test="$additionalTextToSearch">
                <xsl:value-of select="concat('+', $additionalTextToSearch)"/>
            </xsl:if>
        </xsl:param>
        <xsl:param name="additionalFieldsToSearch"/>

        <xsl:param name="isPartOf"/>
        <xsl:param name="series" select="'New Sounds'"/>
        <xsl:param name="subject"/>
        <xsl:param name="genre"/>
        <xsl:param name="contributor"/>
        <xsl:param name="location"/>
        <xsl:param name="coverage"/>

        <xsl:param name="searchString">
            <xsl:call-template name="generateSearchString">
                <xsl:with-param name="textToSearch" select="$textToSearch"/>
                <xsl:with-param name="field1ToSearch" select="'identifier'"/>
                <xsl:with-param name="field2ToSearch" select="$additionalFieldsToSearch"/>

                <xsl:with-param name="isPartOf" select="$isPartOf"/>
                <xsl:with-param name="series" select="$series"/>
                <xsl:with-param name="subject" select="$subject"/>
                <xsl:with-param name="genre" select="$genre"/>
                <xsl:with-param name="contributor" select="$contributor"/>
                <xsl:with-param name="location" select="$location"/>
                <xsl:with-param name="coverage" select="$coverage"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="stopIfTooMany" as="xs:boolean" select="false()"/>
        <xsl:param name="stopIfTooFew" as="xs:boolean" select="false()"/>

        <xsl:message
            select="
                'Search for records ',
                'with specific New Sounds Episode ID ',
                string($newSoundsEpisodeIDPadded),
                ' (which should be unique)'"/>

        <!-- Initial cavafy search -->
        <xsl:variable name="foundAssets">
            <xsl:call-template name="findCavafyXMLs">
                <xsl:with-param name="searchString" select="$searchString"/>
                <xsl:with-param name="minResults" select="1"/>
                <xsl:with-param name="maxResults" select="20"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:message select="
                'Found assets', $foundAssets"/>

        <xsl:variable name="matchingAssets">
            <xsl:copy-of
                select="
                    $foundAssets
                    /pb:pbcoreCollection
                    /pb:pbcoreDescriptionDocument
                    [pb:pbcoreIdentifier[@source = 'New Sounds episode ID'] = $newSoundsEpisodeIDPadded]"
            />
        </xsl:variable>

        <xsl:variable name="resultsCount"
            select="
                count(
                $matchingAssets
                //pb:pbcoreDescriptionDocument
                )"/>

        <xsl:variable name="resultsMessage"
            select="
                concat($resultsCount, ' matching assets ',
                'with New Sounds episode ID ', $newSoundsEpisodeIDPadded,
                ' using search string ', $searchString, ': '),
                $matchingAssets"/>

        <xsl:message select="$resultsMessage"/>

        <!-- Errors when not a single matching asset -->
        <xsl:choose>
            <xsl:when test="$resultsCount &lt; 1">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'no_matching_asset'"/>
                    <xsl:attribute name="newSoundsEpisodeID" select="$newSoundsEpisodeIDPadded"/>
                    <xsl:copy-of
                        select="
                            'ATTENTION!',
                            $resultsMessage"
                    />
                </xsl:element>
            </xsl:when>
            <xsl:when test="$resultsCount &gt; 1">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'too_many__matching_assets'"/>
                    <xsl:attribute name="newSoundsEpisodeID" select="$newSoundsEpisodeIDPadded"/>
                    <xsl:copy-of
                        select="
                            'ATTENTION!',
                            $resultsMessage"
                    />
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$matchingAssets"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="pb:pbcoreDescriptionDocument" mode="maxInstantiationID">
        <xsl:param name="assetID" select="pbcoreIdentifier[@source = 'WNYC Archive Catalog']"/>
        <xsl:param name="instantiationIDRegexPattern" select="concat('^', $assetID, '\.[0-9]+$')"/>
        <xsl:param name="matchingInstantiationIDs">
            <matchingInstantiationIDs>
                <xsl:copy-of select="pbcoreInstantiation/instantiationIdentifier"/>
            </matchingInstantiationIDs>
        </xsl:param>
        <xsl:param name="matchingInstantiationIdSuffixes">
            <matchingInstantiationIDSuffixes>
                <xsl:for-each select="$matchingInstantiationIDs/instantiationIdentifier">
                    <instantiationIDSuffix>
                        <xsl:value-of select="xs:integer(substring-after(., '.'))"/>
                    </instantiationIDSuffix>
                </xsl:for-each>
            </matchingInstantiationIDSuffixes>
        </xsl:param>
        <xsl:message select="'Find highest instantiation ID'"/>
        <xsl:variable name="maxInstSuffix"
            select="
                max($matchingInstantiationIdSuffixes/instantiationIDSuffix)"/>
        <xsl:value-of select="$maxInstSuffix"/>
        <xsl:message select="$maxInstSuffix"/>
    </xsl:template>

    <xsl:template match="pb:pbcoreCollection" mode="importReady">
        <!-- Get a collection ready for import into Cavafy -->
        <!-- ATTENTION: If you copy the UUID (the default), 
            it will create a whole new set of instantiations -->
        <xsl:param name="copyUUID" select="true()"/>
        <xsl:copy>
            <xsl:apply-templates select="
                    pb:pbcoreDescriptionDocument"
                mode="importReady">
                <xsl:with-param name="copyUUID" select="$copyUUID"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="pb:pbcoreDescriptionDocument" mode="importReady">
        <!-- Get an asset ready for import into Cavafy -->
        <!-- ATTENTION: If you copy the UUID (the default), 
            it will wipe out all instantiations 
        and some of the asset fields -->
        <xsl:param name="copyUUID" select="true()"/>
        <xsl:message
            select="
                'ATTENTION: You are copying the UUID, which wipes out all instantiations and some of the asset fields'[$copyUUID]"/>
        <xsl:copy>
            <xsl:copy-of select="comment()"/>
            <!-- Copy asset level fields
            before UUID -->
            <xsl:copy-of select="*[following-sibling::pb:pbcoreIdentifier[@source = 'pbcore XML database UUID']]"/>
            <!-- Copy UUID, if flag says so -->
            <xsl:copy-of select="pb:pbcoreIdentifier[@source = 'pbcore XML database UUID'][$copyUUID]"/>
            <!-- Copy asset level fields after UUID
            except relation and instantiations -->
            <xsl:copy-of select="*
                [preceding-sibling::pb:pbcoreIdentifier[@source = 'pbcore XML database UUID']]
                [not(self::pb:pbcoreRelation)]
                [not(self::pb:pbcoreInstantiation)]"/>            
            <!-- Copy relation sans @ref,
                    which somehow throws an error upon import -->
            <xsl:apply-templates select="
                    pb:pbcoreRelation" mode="noAttributes"/>
            <!-- Generate new instantiation section -->
            <xsl:apply-templates select="pb:pbcoreInstantiation" mode="importReady"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="pb:pbcoreInstantiation" mode="importReady">
        <!-- Get an instantiation ready for import into Cavafy -->
        <xsl:copy>
            <!-- Copy instantiation IDs except UUID and empty essence tracks -->
            <xsl:copy-of
                select="
                    *
                    [not(self::pb:instantiationIdentifier[@source = 'pbcore XML database UUID'])]
                    [not(self::pb:instantiationEssenceTrack[not(descendant::*)])]"
            />
        </xsl:copy>
    </xsl:template>

    <xsl:template name="shortenTitle" match="pb:pbcoreTitle[@titleType = 'Episode']"
        mode="shortenTitle">
        <xsl:param name="title" select="."/>
        <xsl:param name="maxTitleLength" select="30"/>
        <xsl:param name="characterLength" select="string-length($title)"/>
        <xsl:message
            select="
                'Clean up and shorten title', $title,
                'to', $maxTitleLength, 'characters',
                'from', $characterLength, 'characters.'"/>
        <xsl:variable name="cleanTitle">
            <xsl:call-template name="abbreviateText">
                <xsl:with-param name="maxTitleLength" select="
                    $maxTitleLength"/>
                <xsl:with-param name="text" select="$title"/>
            </xsl:call-template>
            <xsl:value-of
                select="
                    analyze-string(
                    replace(., '-', ' '),
                    '[ A-Z a-z 0-9]')
                    /fn:match"
                separator=""/>
        </xsl:variable>
        <xsl:variable name="trimmedTitle"
            select="
                substring(
                replace($cleanTitle, ' {2,}', ' ')
                , 1, $maxTitleLength)"/>
        <xsl:variable name="shortTitle">
            <xsl:call-template name="substring-before-last">
                <xsl:with-param name="input" select="
                        $trimmedTitle"/>
                <xsl:with-param name="substr" select="' '"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="$shortTitle"/>
        <xsl:message select="
                'Short title:', $shortTitle"/>
    </xsl:template>

    <xsl:template name="sameDateAndSeries" mode="sameDateAndSeries"
        match="
        pb:pbcoreDescriptionDocument
        [not(
        pb:pbcoreTitle
        [@titleType = 'Series'] = 'News')]
        [not(
        pb:pbcoreTitle
        [@titleType = 'Series'] = 'Miscellaneous')]">        
        <!-- Find cavafy records with same series and date -->
        <!-- (thus possible duplicates) -->
        <xsl:param name="instantiationToMerge"/>
        <potentialDupes xmlns="">
            <xsl:if test="matches($instantiationToMerge, $instIDRegex)">
                <xsl:attribute name="instantiationToMerge" select="$instantiationToMerge"/>
            </xsl:if>            
        <xsl:apply-templates select="
            pb:pbcoreAssetDate
            [not(
            contains(., 'u'))]" mode="
            potentialDupes"/>   
        </potentialDupes>
    </xsl:template>
    
    <xsl:template match="
            pb:pbcoreAssetDate" mode="
        potentialDupes">
        <xsl:param name="series"
            select="
                ../pb:pbcoreTitle
                [@titleType = 'Series']"
            tunnel="yes"/>
        <xsl:param name="uuid">
            <xsl:value-of
                select="
                    ../pb:pbcoreIdentifier
                    [@source = 'pbcore XML database UUID']"
            />
        </xsl:param>
        <xsl:variable name="cavafyDate" select="."/>
        <xsl:variable name="sameDateAndSeries">
            <xsl:call-template name="
                findCavafyXMLs">
                <xsl:with-param name="
                    textToSearch"
                    select="
                        $cavafyDate"/>
                <xsl:with-param name="
                    field1ToSearch"
                    select="
                        'date'"/>
                <xsl:with-param name="series">
                    <xsl:value-of select="
                            $series"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="potentialDupes"
            select="
                $sameDateAndSeries/
                pb:pbcoreCollection/
                pb:pbcoreDescriptionDocument
                [not(
                pb:pbcoreIdentifier
                [@source = 'pbcore XML database UUID']
                = $uuid)]"/>
        <xsl:variable name="
            originalDateType"
            select="
                $cavafyDate/@dateType"/>
        <xsl:variable name="likelyDupes">
            <likelyDupes xmlns="">
                <xsl:copy-of
                    select="
                        $potentialDupes
                        [pb:pbcoreAssetDate/@dateType = $originalDateType]"
                />
            </likelyDupes>
        </xsl:variable>
        <xsl:variable name="possibleDupes">
            <possibleDupes xmlns="">
                <xsl:copy-of
                    select="
                        $potentialDupes
                        [not(
                        pb:pbcoreAssetDate/@dateType = $originalDateType)]"
                />
            </possibleDupes>
        </xsl:variable>
        
        <xsl:copy-of select="$likelyDupes[likelyDupes/pb:pbcoreDescriptionDocument]"/>
        <xsl:copy-of select="$possibleDupes[possibleDupes/pb:pbcoreDescriptionDocument]"/>

    </xsl:template>
    
    <xsl:template name="generateMissingInstantiationID" match="
        pb:pbcoreInstantiation[not(pb:instantiationIdentifier[@source='WNYC Media Archive Label'])]" mode="
        generateMissingInstantiationID">
        <xsl:param name="asset" select="parent::pb:pbcoreDescriptionDocument"/>
        <xsl:param name="assetID" select="$asset/pb:pbcoreIdentifier[@source='WNYC Archive Catalog']"/>
        
        
    </xsl:template>
    
    <xsl:template match="addInstantiations">
        <xsl:param name="instantiationsToAddLog">
            <xsl:element name="pbcoreCollection">
                <xsl:namespace name="xsi" select="'http://www.w3.org/2001/XMLSchema-instance'"/>
                <xsl:attribute name="xsi:schemaLocation"
                    select="'http://pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd'"/>
                <xsl:apply-templates
                    select="addInstantiation[Notes = 'change and add new instantiation']"/>
            </xsl:element>
        </xsl:param>
        <xsl:param name="instantiationsToAddOriginalData">
            <xsl:copy select="$instantiationsToAddLog/pb:pbcoreCollection">
                <xsl:apply-templates select="pb:originalData/pb:pbcoreDescriptionDocument" mode="importReady"/>
            </xsl:copy>
        </xsl:param>
        <xsl:param name="instantiationsToAdd">
            <xsl:copy select="$instantiationsToAddLog/pb:pbcoreCollection">
                <xsl:copy-of select="pb:newData/pb:pbcoreDescriptionDocument"/>
            </xsl:copy>
        </xsl:param>
        
        <xsl:apply-templates select="$instantiationsToAddLog" mode="breakItUp">
            <xsl:with-param name="baseURI" select="'file:/T:/02%20CATALOGING/SeriesCataloging/'"/>
            <xsl:with-param name="filename" select="'NYACinstToAdd'"/>
            <xsl:with-param name="filenameSuffix" select="'LOG'"/>
            <xsl:with-param name="maxOccurrences" select="100000"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="$instantiationsToAdd" mode="breakItUp">
            <xsl:with-param name="baseURI" select="'file:/T:/02%20CATALOGING/SeriesCataloging/'"/>
            <xsl:with-param name="filename" select="'NYACinstToAdd'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="$instantiationsToAddOriginalData" mode="breakItUp">
            <xsl:with-param name="baseURI" select="'file:/T:/02%20CATALOGING/SeriesCataloging/'"/>
            <xsl:with-param name="filename" select="'NYACinstToAddOriginalData'"/>
            <xsl:with-param name="filenameSuffix" select="'ORIGINAL_DATA'"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="addInstantiation">
        <xsl:param name="cavafyData" select="doc(concat(URL, '.xml'))/pb:pbcoreDescriptionDocument"/>
       <xsl:param name="idToMatch" select="lower-case(Scan1)"/>
        <xsl:param name="newInstID" select="lower-case(Scan2)"/>
        
        <originalData>
            <xsl:copy-of select="$cavafyData"/>
        </originalData>
        <newData>
        <xsl:copy select="$cavafyData">            
            <xsl:copy-of select="$cavafyData/pb:pbcoreIdentifier[@source='WNYC Archive Catalog']"/>
            <xsl:copy-of select="$cavafyData/pb:pbcoreTitle[@titleType='Collection']"/>
            <xsl:variable name="matchedInstantiation" select="$cavafyData/pb:pbcoreInstantiation[pb:instantiationIdentifier[@source='WNYC Media Archive Label'] = $idToMatch]"/>
            <xsl:copy select="$matchedInstantiation">
                <instantiationIdentifier source="WNYC Media Archive Label">
                    <xsl:value-of select="$newInstID"/>
                </instantiationIdentifier>
                <xsl:copy-of select="pb:instantiationDate"/>
                <xsl:copy-of select="pb:instantiationPhysical"/>
                <xsl:copy-of select="pb:instantiationLocation"/>
                <xsl:copy-of select="pb:instantiationMediaType"/>
                <xsl:copy-of select="pb:instantiationGenerations"/>
            </xsl:copy>
        </xsl:copy>
        </newData>
    </xsl:template>

    <!--<xsl:template match="node()" mode="breakItUp">
        <xsl:param name="firstOccurrence" select="1"/>
        <xsl:param name="maxOccurrences" select="200"/>
        <xsl:param name="total" select="count(child::*)"/>
        <xsl:param name="baseURI"/>
        <xsl:param name="filename" select="document-uri()"/>
        <xsl:param name="filenameSuffix" select="'_ForCAVAFY'"/>
        <xsl:param name="currentDate" select="format-date(current-date(), '[Y0001][M01][D01]')"/>
        <xsl:param name="assetName" select="name(child::*[1])"/>
        
        <xsl:message
            select="
            'Break up document into ',
            $maxOccurrences, '-size pieces'"/>
        
        <xsl:variable name="lastPosition"
            select="
            count(
            *[position() ge $firstOccurrence]
            [position() le $maxOccurrences])"/>
        <xsl:variable name="filenameCavafy"
            select="
            concat(
            substring-before(
            $baseURI, '.'),
            $filename,
            $filenameSuffix,
            $currentDate,
            '_', $assetName,
            $firstOccurrence, '-',
            ($firstOccurrence + $lastPosition - 1),
            '.xml'
            )"/>
        <xsl:result-document href="{$filenameCavafy}">
            <xsl:copy>
                <xsl:comment select="$assetName, $firstOccurrence, 'to', ($firstOccurrence + $lastPosition - 1), 'from a total of', $total"/>
                <xsl:copy-of
                    select="child::*[position() ge $firstOccurrence][position() le ($maxOccurrences)]"
                />
            </xsl:copy>
        </xsl:result-document>
        <xsl:if
            test="
            ($firstOccurrence + $maxOccurrences)
            le $total">
            <xsl:call-template name="breakItUp">
                <xsl:with-param name="firstOccurrence"
                    select="
                    $firstOccurrence + $maxOccurrences"/>
                <xsl:with-param name="maxOccurrences"
                    select="
                    $maxOccurrences"/>
                <xsl:with-param name="assetName" select="
                    $assetName"/>
                <xsl:with-param name="baseURI" select="$baseURI"/>
                <xsl:with-param name="filename" select="$filename"/>
                <xsl:with-param name="filenameSuffix" select="$filenameSuffix"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>-->

</xsl:stylesheet>
