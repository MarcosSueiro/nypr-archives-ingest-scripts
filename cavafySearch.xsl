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

<xsl:stylesheet version="3.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" 
    xmlns:WNYC="http://www.wnyc.org"
    xmlns:pma="http://www.phpmyadmin.net/some_doc_url/"
    xmlns:op="https://www.w3.org/TR/2017/REC-xpath-functions-31-20170321/"
    xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html" 
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    exclude-result-prefixes="#all">
    
    <xsl:output method="xml" version="1.0" indent="yes"/>

    <xsl:import href="manageDuplicates.xsl"/>

    <xsl:param name="cavafyValidatingString" 
        select="'https://cavafy.wnyc.org/assets/'"/>
    <xsl:param name="separatingToken" 
        select="';'"/>
    <xsl:param name="separatingTokenLong" 
        select="concat(' ', $separatingToken, ' ')"/>
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
    <xsl:param name="todaysDate" 
        select="xs:date(current-date())"/>
    
    <xsl:template match="pma_xml_export">
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
                    select="$newSoundsDupes/*:pbcoreCollection/*:pbcoreDescriptionDocument">
                    <xsl:variable name="newAssetID" select="86536 + position()"/>
                    <xsl:copy>
                        <xsl:comment select="'************ORIGINAL ', *:pbcoreIdentifier[@source = 'WNYC Archive Catalog'], '**********'"/>
                        <xsl:copy-of select="*"/>
                    </xsl:copy>
                    <xsl:copy>
                        <xsl:comment select="'++++++++++++++++NEW ', $newAssetID, '++++++++++++++'"/>
                        <xsl:copy-of
                            select="*[following-sibling::*:pbcoreIdentifier[@source = 'WNYC Archive Catalog']]"/>
                        <pbcoreIdentifier source="WNYC Archive Catalog">
                            <xsl:value-of select="$newAssetID"/>
                        </pbcoreIdentifier>
                        <xsl:copy-of
                            select="*[preceding-sibling::*:pbcoreIdentifier[@source = 'WNYC Archive Catalog']]"
                        />
                    </xsl:copy>
                </xsl:for-each>
            </xsl:copy>
        </xsl:variable>
        <xsl:apply-templates select="$newSoundsDupesDuplicated" mode="importReady"/>
    </xsl:template>
    
    <xsl:template name="generateSearchString" 
        match="." mode="generateSearchString">
        <!-- Generate a cavafy search string
        from given parameters -->
        
        <xsl:param name="textToSearch"/>
        <xsl:param name="field1ToSearch"/>
        <xsl:param name="field2ToSearch"/>
        
        <xsl:param name="searchTextMessage">
            <xsl:value-of select="
                'Generate search string for text _', $textToSearch, 
                '_ in fields ', 
                $field1ToSearch, $field2ToSearch"/>
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
            <xsl:value-of select="
                'Generate search string', 
                'for a search in cavafy',
                'with the following parameters: ',
                '- relations is part of: ', $isPartOf[.!=''], 
                '- series: ',               $series,
                '- subject: ',              $subject,
                '- genre: ',                $genre,
                '- coverage: ',             $coverage,
                '- contributor: ' ,         $contributor,
                '- location: ', $location"/>
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
                    <xsl:value-of select="concat('&amp;search_fields%5B%5D=', 
                        translate(lower-case(.), ' ', '+'))"/>
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
        <xsl:message select="
            'Complete search string: ', 
            $completeSearchString"/>
        
        <completeSearchString>
            <xsl:value-of select="$completeSearchString"/>
        </completeSearchString>
    </xsl:template>

    <xsl:template name="checkResult" 
        match="searchString[starts-with(., 'https://cavafy.wnyc.org/?')]" 
        mode="checkResult">
        <!-- Retrieve paginated url results 
            from a cavafy search string -->

        <xsl:param name="searchString"
            select=".[starts-with(., 'https://cavafy.wnyc.org/?')]"/>

        <xsl:param name="minResults" as="xs:integer" select="1"/>
        <xsl:param name="maxResults" as="xs:integer" select="1000"/>
        <xsl:param name="stopIfTooMany" as="xs:boolean" select="false()"/>
        <xsl:param name="stopIfTooFew" as="xs:boolean" select="false()"/>
        <xsl:param name="htmlResult" select="document($searchString)"/>
        <xsl:message select="'htmlResult: ', $htmlResult"/>
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
                select="
                    $htmlResult
                    /xhtml:html/xhtml:head/xhtml:meta
                    [@name = 'totalResults']
                    /@content"
            />
        </xsl:variable>
        <xsl:variable name="itemsPerPage">
            <xsl:value-of
                select="
                    $htmlResult
                    /xhtml:html/xhtml:head/xhtml:meta
                    [@name = 'itemsPerPage']
                    /@content"
            />
        </xsl:variable>
        <xsl:variable name="totalPages"
            select="
                number($totalResults)
                div
                number($itemsPerPage)
                "/>
        <xsl:variable name="resultsMessage"
            select="concat(
            $totalResults, ' results',
            ' from search string ', $searchString, '.',
            ' Allowed range: ', $minResults, '-', $maxResults,
            'Items Per Page: ', $itemsPerPage,
            'Total Pages: ', ceiling($totalPages)
            )
            "/>
        <xsl:message select="$resultsMessage"/>

        <xsl:choose>
            <xsl:when test="$totalResults &lt; $minResults">
                <xsl:message terminate="{$stopIfTooFew}" 
                    select="'ATTENTION!', $resultsMessage"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'too_few_cavafy_results'"/>
                    <xsl:value-of select="$resultsMessage"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$totalResults &gt; $maxResults">
                <xsl:message terminate="{$stopIfTooMany}" 
                    select="'ATTENTION!', $resultsMessage"/>              
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
        to find the listed assets' URLs-->
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

    <xsl:template name="findCavafyXMLs" 
        match="." 
        mode="findCavafyXMLs">
        <!-- Obtain the cavafy XMLs 
        from a search using specific parameters.-->
        <!-- Inputs: 
            1. A string to search in cavafy
            plus two fields in which to search
            for that string
            2. Several facets to limit that search
            such as collection, series or subjects.
            
            Output:
            The cavafy xmls for each record found.
         -->
        
        <xsl:param name="textToSearch"/>
        <xsl:param name="field1ToSearch"/>
        <xsl:param name="field2ToSearch"/>        
        <xsl:param name="isPartOf"/><!-- Called 'Collection' in cavafy -->        
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
                <xsl:with-param name="searchString" select="$searchString[contains(., 'https://cavafy.wnyc.org/')]"/>
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
        <xsl:param name="message" select="
            'Find between', $minResults, ' and ', $maxResults, 
            'cavafy XMLs ',
            'with parameters ',
            $textToSearch, $series, $subject, $contributor, $genre, $isPartOf,
            $location,
            ' in fields ', $field1ToSearch, $field2ToSearch, 
            ' using search string ', $searchString,
            'Result URLs: ', $cavafyURLs"/>
        <xsl:message select="$message"/>
        <xsl:copy-of select="$cavafyURLs[//local-name()='error']"/>
        <xsl:call-template name="generatePbCoreCollection">
            <xsl:with-param name="urls" select="$urls"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="url" xpath-default-namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
        <xsl:apply-templates select="." mode="
            generatePbCoreCollectionWRepeats"/>
    </xsl:template>
    
    <xsl:template name="generatePbCoreCollectionWRepeats" match="url"
        mode="generatePbCoreCollectionWRepeats" xpath-default-namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
        <!-- From a token-separated list of URLs,
        generate a pbcore collection
        of xmls including repeats-->
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
                <xsl:call-template name="
                    generatePbCoreDescriptionDocument">
                    <xsl:with-param name="url" select="normalize-space(.)"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="dc:url">
        <xsl:apply-templates select="." mode="
            generatePbCoreCollection"/>
    </xsl:template>
    
    
    <xsl:template name="generatePbCoreCollection" 
        match="dc:url" 
        mode="generatePbCoreCollection">
        <!-- From a token-separated list of URLs,
        generate a pbcore collection
        of UNIQUE xmls ready for import-->
        <xsl:param name="urls" select="."/>
        <xsl:message select="
            'From a token-separated list of URLs, ', 
            'generate a pbcore collection of unique xmls ', 
            'ready for import'"/>
        <xsl:for-each
            select="
                WNYC:splitParseValidate($urls, $separatingToken, $cavafyValidatingString)
                /invalid">
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
                select="
                    WNYC:splitParseValidate($urls, ';', $cavafyValidatingString)
                    /valid">
                <xsl:call-template name="generatePbCoreDescriptionDocument">
                    <xsl:with-param name="url" select="."/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>

    <xsl:template name="generatePbCoreDescriptionDocument" 
        match="dc:url"
        mode="generatePbCoreDescriptionDocument">
        <!-- From a single cavafy URL,
        generate a pbcore description document 
        -->
        
        <xsl:param name="url" select="."/>
        
        <!-- Reject non-cavafy URLs -->
        <xsl:for-each
            select="
                WNYC:splitParseValidate($url, $separatingToken, $cavafyValidatingString)
                /invalid
                |
                WNYC:splitParseValidate($url, $separatingToken, $cavafyValidatingString)
                /valid[not(starts-with(., $cavafyValidatingString))]">
            <xsl:element name="error">
                <xsl:attribute name="type" select="'invalid_cavafy_URL'"/>
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:for-each>
        <xsl:for-each
            select="
                WNYC:splitParseValidate($url, ';', $cavafyValidatingString)
                /valid[starts-with(., $cavafyValidatingString)][ends-with(., '.xml')]">
            <xsl:copy-of select="document(.)"/>
        </xsl:for-each>
        <xsl:for-each
            select="
                WNYC:splitParseValidate($url, ';', $cavafyValidatingString)
                /valid[starts-with(., $cavafyValidatingString)][not(ends-with(., '.xml'))]">
            <xsl:copy-of select="document(concat(., '.xml'))"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="findSpecificCavafyAssetXML" 
        match="."
        mode="findSpecificCavafyAssetXML">
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
                
        <xsl:message select="'Search for records with specific Asset ID ',
            string($assetID), ' (which should be unique)'"/>

        <!-- Initial cavafy search -->
        <xsl:variable name="foundAssets">
            <xsl:call-template name="findCavafyXMLs">
                <xsl:with-param name="searchString" 
                    select="$searchString"/>
                <xsl:with-param name="minResults" select="1"/>
                <xsl:with-param name="maxResults" select="10"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:message select="
            'Found assets', $foundAssets"/>

        <xsl:variable name="matchingAssets">
            <xsl:copy-of
                select="
                    $foundAssets
                    /*:pbcoreCollection
                    /*:pbcoreDescriptionDocument
                    [*:pbcoreIdentifier[@source='WNYC Archive Catalog'] = $assetID]"
            />
        </xsl:variable>        
        
        <xsl:variable name="resultsCount"
            select="count(
            $matchingAssets
            /*:pbcoreDescriptionDocument
            )"/>

        <xsl:variable name="resultsMessage" select="
            concat($resultsCount, ' matching assets ', 
            'with asset ID ' , $assetID,
            ' using search string ', $searchString, ': '), 
            $matchingAssets"/>
        
        <xsl:message select="$resultsMessage"/>
        
        <!-- Errors when not a single matching asset -->
        <xsl:choose>
            <xsl:when test="$resultsCount &lt; 1">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'no_matching_asset'"/>
                    <xsl:attribute name="assetID" select="$assetID"/>
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
                    <xsl:attribute name="assetID" select="$assetID"/>
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

    <xsl:template name="findSeriesXML" 
        match="seriesAcronym" 
        mode="findSeriesXML">
        <!-- Find the series info in cavafy
        from the series acronym-->
        <!-- Series information is stored in cavafy
                with a relation 'SRSLST' 
                of relationType 'other'.            
            It includes default hosts, 
            genres and subject headings-->
        <xsl:param name="seriesAcronym" select="."/>
        <xsl:param name="message" select="
            concat(
            'Find the series data in cavafy ',
            'from the series acronym ', $seriesAcronym
            )"/>
        <xsl:message select="$message"/>
        <xsl:variable name="seriesSearchResult">
        <xsl:call-template name="findSpecificCavafyAssetXML">
            <xsl:with-param name="textToSearch" select="concat('SRSLST+', $seriesAcronym)"/>
            <xsl:with-param name="assetID" select="$seriesAcronym"/>
            <xsl:with-param name="additionalFieldsToSearch" select="'relation'"/>
        </xsl:call-template>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$seriesSearchResult[//*:error[@type='no_matching_asset']]">
                <xsl:variable name="noSeriesFound" select="'No series found with acronym ', $seriesAcronym"/>
                <xsl:message select="$noSeriesFound"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'no_series_found'"/>
                    <xsl:value-of select="$noSeriesFound"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$seriesSearchResult[//*:error[@type='too_many_matching_assets']]">
                <xsl:variable name="multipleSeriesFound" select="'Multiple series found with acronym ', $seriesAcronym"/>
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
    
    <xsl:template name="findSeriesXMLFromName" 
        match="seriesName" 
        mode="findSeriesXMLFromName">
        <!-- Find the series info in cavafy
        from the series name-->
        <!-- Series information is stored in cavafy
                with a relation 'SRSLST' 
                of relationType 'other'.            
            It includes default hosts, 
            genres and subject headings-->
        <xsl:param name="seriesName" select="'New Sounds'"/>
        <xsl:param name="message" select="
            'Find the series info in cavafy',
            'from the series name ', $seriesName"/>
        <xsl:message select="$message"/>
        <xsl:variable name="searchString">
            <xsl:call-template name="generateSearchString">
                <xsl:with-param name="textToSearch" select="concat('SRSLST+', $seriesName)"/>
                <xsl:with-param name="field1ToSearch" select="'title'"/>
                <xsl:with-param name="field2ToSearch" select="'relation'"/>
                <xsl:with-param name="series" select="$seriesName"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="findCavafyXMLs">
            <xsl:with-param name="searchString" select="$searchString"/>
            <xsl:with-param name="minResults" select="1"/>
            <xsl:with-param name="maxResults" select="1"/>
            <xsl:with-param name="stopIfTooFew" select="true()"/>
            <xsl:with-param name="stopIfTooMany" select="true()"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="findInstantiation" 
        match="instantiationID" mode="processInstantiation">
        <!-- Find a specific instantiationID in cavafy -->
        <!-- NOTE: mode "processInstantiation"
        is part of a set
        along with template
        "nextInstantiationID"-->
        <xsl:param name="instantiationID" select="."/>
        <xsl:param name="assetID" select="substring-before($instantiationID, '.')"/>
        <xsl:param name="cavafyEntry">
            <xsl:call-template name="findSpecificCavafyAssetXML">
                <xsl:with-param name="assetID" select="$assetID"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="instantiationSuffix" select="substring-after($instantiationID, '.')"/>
        <xsl:param name="format"/>
        <xsl:param name="translatedFormat" select="
            if (upper-case($format) = 'WAV')
            then 'BWF'
            else $format"/>
        
        <xsl:message select="
            concat(
            'Find instantiation info for ', $instantiationID,
            ' of format ', $translatedFormat
            )"/>        
        
        <xsl:variable name="matchedInstantiation"
            select="
            $cavafyEntry
            /*:pbcoreDescriptionDocument
            /*:pbcoreInstantiation
            [*:instantiationIdentifier = $instantiationID]"/>
        <xsl:variable name="matchedInstantiationID"
            select="$matchedInstantiation
            /*:instantiationIdentifier
            [. = $instantiationID]"/>
        <xsl:message select="            
            count($matchedInstantiation), 
            ' instantiations with ID ', 
            $instantiationID, 
            ' found in cavafy: ',
            $matchedInstantiation
            "/>
        <xsl:variable name="matchedInstantiationIDSource">
            <xsl:value-of select="
                $matchedInstantiationID/@source"/>
        </xsl:variable>
        <instantiationData>
            <!-- Generate error if
            there is more than one instantiation
            with this ID-->
            <xsl:if test="count($matchedInstantiation) gt 1">
                <xsl:variable name="errorMessage" 
                    select="
                    'ATTENTION!!!',  
                    'Instantiation ID ', $instantiationID, 
                    ' is not unique.'"/>
                <xsl:message select="$errorMessage"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'multiple_instantiation_IDs',
                        $instantiationID"/>
                    <xsl:value-of select="$errorMessage"/>
                </xsl:element>
            </xsl:if>
            
            
            <!--Generate error if instantiation formats do not match-->
            <xsl:if test="$matchedInstantiationID">                
                <xsl:variable name="matchedInstantiationFormat" select="
                    $matchedInstantiation
                    //(*:instantiationPhysical | *:instantiationDigital)
                    [. !='']"/>
                <xsl:choose>
                    <xsl:when test="
                        $matchedInstantiationFormat                         
                        != $translatedFormat">
                        <xsl:variable name="errorMessage"
                            select="
                            'ATTENTION!!!', 
                            ' You are about to wipe out instantiation ',
                            $instantiationID,
                            ', a ', $matchedInstantiationFormat, ', ',
                            ' with a ', $translatedFormat, '!!!'"/>
                        <xsl:message terminate="no" select="$errorMessage"/>
                        <xsl:element name="error">
                            <xsl:attribute name="type" 
                                select="'mismatched_format'"/>
                            <xsl:value-of select="$errorMessage"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="
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
                            <xsl:attribute name="type" select="
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
    
    <xsl:template name="earliestDate" 
        match="pbcoreDescriptionDocument" 
        mode="earliestDate">
        <!-- Find the earliest specific date 
        or the latest unknown date.
        This is used to generate filname dates.-->
        <xsl:param name="cavafyXML" select="."/>
        <xsl:message select="
            'Find earliest date in', 
            $cavafyXML/pbcoreIdentifier[@source='WNYC Archive Catalog']"/>
        
        <xsl:variable 
            name="earliestDate" 
            select="
            min(
            $cavafyXML/pbcoreAssetDate[not(contains(.,'u'))]
            /xs:date(.)
            )"/>
        <xsl:variable 
            name="unknownDate" 
            select="
            max($cavafyXML
            /pbcoreAssetDate[contains(., 'u')])"/>
        <xsl:variable name="filenameDate"
            select="if($unknownDate)
            then $unknownDate
            else $earliestDate
            "/>
        <xsl:value-of select="$filenameDate"/>
    </xsl:template>

    <xsl:template name="nextInstantiationID" 
        match="instantiationID" 
        mode="processInstantiation">
        <!-- Generate the next instantiation ID
            in an asset.
        This is used for generating filenames. -->
        <!-- NOTE: mode "processInstantiation"
        is part of a set
        along with template
        "findInstantiation"-->
        <xsl:param name="instantiationID" select="."/>
        <xsl:param name="assetID" select="substring-before($instantiationID, '.')"/>
        <xsl:param name="instantiationSuffix" select="substring-after($instantiationID, '.')"/>
        <xsl:param name="format"/>
        <xsl:param name="translatedFormat" select="if (upper-case($format) = 'WAV')
            then 'BWF'
            else $format"/>
        <xsl:param name="cavafyEntry">
            <xsl:call-template name="findSpecificCavafyAssetXML">
                <xsl:with-param name="assetID" select="$assetID"/>
            </xsl:call-template>
        </xsl:param>
        
        <xsl:message select="'Find cavafy info for ', $instantiationID,
            ' of format ', $format"/>
        
        
        <xsl:variable name="matchedInstantiation"
            select="
            $cavafyEntry
            //pbcoreInstantiation[instantiationIdentifier = $instantiationID]"/>
        <xsl:variable name="matchedInstantiationID"
            select="$matchedInstantiation/instantiationIdentifier[. = $instantiationID]"/>
        <xsl:variable name="matchedInstantiationIDSource">
            <xsl:value-of select="$matchedInstantiationID/@source"/>
        </xsl:variable>
        <instantiationData>
            <!-- Generate error if
            there is more than one instantiation
            with this ID-->
            <xsl:if test="count($matchedInstantiation) gt 1">
                <xsl:variable name="errorMessage" 
                    select="
                    'ATTENTION!!!',  
                    'Instantiation ID ', $instantiationID, 
                    ' is not unique.'"/>
                <xsl:message select="$errorMessage"/>
                <xsl:element name="error">
                    <xsl:attribute name="type" select="
                        'duplicate_instantiation_ID'"/>
                    <xsl:value-of select="$errorMessage"/>
                </xsl:element>
            </xsl:if>
            
            
            <!--Generate error if instantiation formats do not match-->
            <xsl:if test="$matchedInstantiationID">
                <xsl:call-template name="checkConflicts">
                    <xsl:with-param name="field1" select="$format"/>
                    <xsl:with-param name="field2" select="
                        $matchedInstantiation//(instantiationPhysical | instantiationDigital)"/>
                </xsl:call-template>
                <xsl:choose>
                    <xsl:when test="$matchedInstantiation//instantiationPhysical">
                        <xsl:variable name="errorMessage"
                            select="
                            'ATTENTION! You are about to wipe out physical instantiation ',
                            $instantiationID,
                            ', a ', $matchedInstantiation//instantiationPhysical"/>
                        <xsl:message terminate="no" select="$errorMessage"/>
                        <xsl:element name="error">
                            <xsl:attribute name="type" select="
                                'existing_physical_instantiation'"/>
                            <xsl:value-of select="$errorMessage"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$matchedInstantiationIDSource != 'WNYC Media Archive Label'">
                        <xsl:variable name="errorMessage"
                            select="
                            'ATTENTION! ',
                            'Instantiation ID ', $matchedInstantiationID,
                            ' has a nonstandard ID source: ', $matchedInstantiationIDSource,
                            '&#10;',
                            'Please change to WNYC Media Archive Label.'"/>
                        <xsl:message select="$errorMessage"/>
                        <xsl:element name="error">
                            <xsl:attribute name="type" select="
                                'nonstandard_instantiationID_source'"/>
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
    
    <xsl:template name="anniversaries" 
        match="." mode="anniversaries">
        <!-- Find entries in cavafy 
            from x years ago (default 50) -->
        <xsl:param name="todaysDate" select="$todaysDate"/>
        <xsl:param name="xYears" select="50"/>
        <xsl:param name="year50YearsAgo" 
            select="
            year-from-date($todaysDate) - $xYears"
        />        
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
                <xsl:with-param 
                    name="searchString" 
                    select="$xYearsAgoCavafySearchString"
                />
            </xsl:call-template>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="findSpecificNewSoundsProgramNoXML" 
        match="programNo"
        mode="findSpecificNewSoundsProgramNoXML">
        <!-- Search for records with specific New Sounds Program ID 
        (which should be unique) -->
        
        <xsl:param name="newSoundsEpisodeID" select="."/>
        <xsl:param name="newSoundsEpisodeIDPadded" select="
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
        
        <xsl:message select="
            'Search for records ',
            'with specific New Sounds Episode ID ',
            string($newSoundsEpisodeIDPadded), 
            ' (which should be unique)'"/>
        
        <!-- Initial cavafy search -->
        <xsl:variable name="foundAssets">
            <xsl:call-template name="findCavafyXMLs">
                <xsl:with-param name="searchString" 
                    select="$searchString"/>
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
                /*:pbcoreCollection
                /*:pbcoreDescriptionDocument
                [*:pbcoreIdentifier[@source='New Sounds episode ID'] = $newSoundsEpisodeIDPadded]"
            />
        </xsl:variable>        
        
        <xsl:variable name="resultsCount"
            select="count(
            $matchingAssets
            //*:pbcoreDescriptionDocument
            )"/>
        
        <xsl:variable name="resultsMessage" select="
            concat($resultsCount, ' matching assets ', 
            'with New Sounds episode ID ' , $newSoundsEpisodeIDPadded,
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
    
    <xsl:template match="pbcoreDescriptionDocument" mode="maxInstantiationID">
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
        <xsl:message select="'Find highes instantiation ID'"/>
        <xsl:variable name="maxInstSuffix" select="
            max($matchingInstantiationIdSuffixes/instantiationIDSuffix)"/>
        <xsl:value-of select="$maxInstSuffix"/>
        <xsl:message select="$maxInstSuffix"/>
    </xsl:template>
    
    <xsl:template match="pb:pbcoreCollection" mode="importReady">
        <!-- Get a collection ready for import into Cavafy -->
        <xsl:copy>
            <xsl:apply-templates select="
                pb:pbcoreDescriptionDocument" mode="importReady"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="pb:pbcoreDescriptionDocument" mode="importReady">
        <!-- Get an asset ready for import into Cavafy -->
        <xsl:copy>
            <xsl:copy-of select="comment()"/>
            <!-- Copy asset level fields
            except relation and instantiations-->
            <xsl:copy-of
                select="
                *
                [not(self::pb:pbcoreRelation)]
                [not(self::pb:pbcoreInstantiation)]
                "/>
            <!-- Copy relation sans @ref,
                    which somehow throws an error upon import-->
            <xsl:apply-templates select="
                pb:pbcoreRelation" mode="noAttributes"/>
            <!-- Generate new instantiation section -->
            <xsl:apply-templates select="pb:pbcoreInstantiation" mode="importReady"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template
        match="
        pb:pbcoreInstantiation" mode="importReady">
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
    
    
</xsl:stylesheet>
