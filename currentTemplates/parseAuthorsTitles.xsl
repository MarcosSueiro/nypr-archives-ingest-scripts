<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:json="http://marklogic.com/xdmp/json/basic"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:bf="http://id.loc.gov/ontologies/bibframe/"
    xmlns:bflc="http://id.loc.gov/ontologies/bflc/" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:cc="http://creativecommons.org/ns#" xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    exclude-result-prefixes="#all" version="3.0">

    <xsl:output method="xml" indent="yes"/>
    <xsl:import
        href="masterRouter.xsl"/>

    
    <!--   Examples of LoC searches  
        doc('https://id.loc.gov/search/?q=rdftype:Work%20PETER%20CAREY%20Jack%20Maggs&amp;start=1&amp;format=atom')" 
    -->
    
    <xsl:param name="allCapsGuest" select='
        "([A-Z\-’&#39;\.]{2,})"'/>    
    <xsl:param name="allCapsGuestNew" select='
        "(([A-Z]([A-Z\-’&#39;\.ce]|[A-Z ,])+){2,}){2,}"'/>
    <xsl:param name="professions" select="'(writer|author|actor|editor|senator|director|playwright|scientist|journalist|star|adviser|poet|artist|filmmaker|photographer|analyst|astrophysicist|speaker of the house|novelist|designer|engineer|critic|curator|musician|player|restaurateur|historian|violinist|actress|dr\.|doctor|diva|singer|etymologist|punster|dancer|choreographer|chef|rabbi|surgeon|cartoonist|baritone|comedian|gourmand|correspondent|biographer|fighter)'"/>
    <xsl:param name="role" select="'(as told in|who curated|creator( of)?|shares|: h.. new|and h..|discusses|on h..|on the|star of|who edited|author( of)?|(former )?editor-in-chief|co-authors( of)?|who wrote|with h..|(former )?editor( of)?)'"/>
    <xsl:param name="workType" select="'(exhibit|memoir|novel|book|movie|best-seller|play|collection|essays|latest|autobiography|biography( of)?|stories|film|history)'"/>
    <xsl:param name="authorBookDivider" select="concat($role, '(.*', $workType, ')?')"/>
    <xsl:param name="professionSuffixes" select="
        '.+or$|.+wright$|.+er$|.+ess$|.+man$|.+ist$'"/>
    <xsl:param name="workDelimiters" select="
        '(&quot;.+&quot;|“.+”|\(.+\))'"/>  
    
    
    
    <xsl:template match="pma_xml_export">
        <!-- Many descriptions in cavafy
        conform to a pattern where
        authors are preceded by an asterisk
        on each line
        -->

        <!-- For example,
            This mySQL search in phpMyAdmin 
            retrieves such abstracts:
    SELECT description, 
    CONCAT('https://cavafy.wnyc.org/assets/', a.uuid) AS URL
FROM `descriptions` d
JOIN assets a ON d.asset_id = a.id
WHERE `description` REGEXP '^\\*[A-Z][A-z]+ [A-z].*\\*' -->


        <xsl:param name="completeData">
            <pbcoreCollection xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <xsl:apply-templates select="database"/>
            </pbcoreCollection>
        </xsl:param>
        <xsl:apply-templates select="$completeData" mode="breakItUp">
            <xsl:with-param name="baseURI" select="base-uri()"/>
            <xsl:with-param name="filename" select="'NYACLoC'"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="database">
        <!-- disable repeat entries -->
        <xsl:param name="newLoCs">
            <xsl:for-each-group select="table" group-by="column[@name='URL']">
                <xsl:apply-templates select="."/>
            </xsl:for-each-group>            
        </xsl:param>
        <!-- Disable entries with no new data -->
        <xsl:copy-of
            select="$newLoCs/pb:pbcoreDescriptionDocument[pb:pbcoreSubject | pb:pbcoreContributor]"
        />
    </xsl:template>
    
    <xsl:template match="table">
        <xsl:param name="url" select="column[@name = 'URL']"/>
        <xsl:param name="cavafyEntry" select="doc(concat($url, '.xml'))"/>
        <xsl:param name="abstract"
            select="
                $cavafyEntry/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreDescription
                [@descriptionType = 'Abstract']"/>
        <xsl:param name="cavafyID"
            select="
                $cavafyEntry/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreIdentifier
                [@source = 'WNYC Archive Catalog']"/>
        <xsl:param name="collection"
            select="
                $cavafyEntry/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreTitle[@titleType = 'Collection']"/>
        <xsl:param name="goodCavafyContributors"
            select="
                $cavafyEntry/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreContributor/
                pb:contributor
                [contains(@ref, 'id.loc.gov')]"/>
        <xsl:param name="badCavafyContributors"
            select="
                $cavafyEntry/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreContributor/
                pb:contributor
                [not(contains(@ref, 'id.loc.gov'))]"/>
        <xsl:param name="badCavafySubjects" select="
            $cavafyEntry/
            pb:pbcoreDescriptionDocument/
            pb:pbcoreSubject
            [not(contains(@ref, 'id.loc.gov'))]"/>
        <xsl:param name="goodCavafySubjects" select="
            $cavafyEntry/
            pb:pbcoreDescriptionDocument/
            pb:pbcoreSubject
            [contains(@ref, 'id.loc.gov')]"/>
        <xsl:param name="allLoCData">
            <cavafyEntry>
                <xsl:attribute name="cavafyID">
                    <xsl:value-of select="$cavafyID"/>
                </xsl:attribute>
                <xsl:attribute name="URL">
                    <xsl:value-of select="$url"/>
                </xsl:attribute>
                <xsl:attribute name="collection">
                    <xsl:value-of select="$collection"/>
                </xsl:attribute>
                <!-- Search LoC with contributors in cavafy -->
                <cavafyContributors>
                    <xsl:for-each select="$badCavafyContributors">
                        <locContributor>
                            <xsl:call-template name="searchLoC">
                                <xsl:with-param name="searchTerms" select="."/>
                                <xsl:with-param name="database" select="'/authorities/names'"/>
                                <xsl:with-param name="rdftype" select="'PersonalName'"/>
                                <xsl:with-param name="count" select="'1'"/>
                            </xsl:call-template>
                        </locContributor>
                    </xsl:for-each>
                </cavafyContributors>
                <cavafySubjects>
                    <xsl:for-each select="$badCavafySubjects">
                        <cavafySubject>
                            <xsl:call-template name="directLOCSubjectSearch">
                                <xsl:with-param name="termToSearch" select="."/>                                
                            </xsl:call-template>
                            <xsl:call-template name="directLOCNameSearch">
                                <xsl:with-param name="termToSearch" select="."/>                                
                            </xsl:call-template>
                        </cavafySubject>
                    </xsl:for-each>
                </cavafySubjects>
                
                <!-- Parse the cavafy abstract -->
                <abstract>
                    <xsl:copy-of select="$abstract"/>
                    <parsedAbstract>
                        <xsl:apply-templates
                            select="
                                $abstract[matches(., '\*[A-z]')]"
                            mode="lineAsteriskBreakup"/>
                    </parsedAbstract>
                </abstract>
            </cavafyEntry>
        </xsl:param>
        <xsl:param name="cavafyContributorsURLs">
            <xsl:value-of
                select="$allLoCData/cavafyEntry/cavafyContributors/locContributor/json:json[json:count = '1']/json:hits/json:hit/json:uri"
                separator=" ; "/>
        </xsl:param>
        <xsl:param name="cavafySubjectsURLs" 
                select="$allLoCData/cavafyEntry/cavafySubjects/cavafySubject/rdf:RDF/madsrdf:*/@rdf:about"
                />
        <xsl:param name="cavafyParsedAbstractWorkContributorURLs">
            <xsl:value-of
                select="$allLoCData/cavafyEntry/abstract/parsedAbstract/newLine/parsedAuthorTitle[number(searchResult/json:json/json:count) lt 5]/work/locAuthor/authorURI"
                separator=" ; "/>
        </xsl:param>
        <xsl:param name="cavafyParsedAbstractParsedContributorURLs">
            <xsl:value-of
                select="$allLoCData/cavafyEntry/abstract/parsedAbstract/newLine/parsedAuthorTitle/justGuests/json:json[json:count = '1']/json:hits/json:hit/json:uri"
                separator=" ; "/>
        </xsl:param>
        <xsl:param name="allContributorURLs">
            <xsl:value-of
                select="$cavafyContributorsURLs | $cavafyParsedAbstractWorkContributorURLs | $cavafyParsedAbstractParsedContributorURLs"
                separator=" ; "/>
        </xsl:param>
        <xsl:param name="LoCSubjects">
            <xsl:value-of
                select="($allLoCData/
                cavafyEntry/
                abstract/
                parsedAbstract/
                newLine/
                parsedAuthorTitle
                [number(searchResult/json:json/json:count) lt 5]/
                work/
                subjects/
                subject/
                subjectURL) | $cavafySubjectsURLs"
                separator=" ; "/>
        </xsl:param>

        <xsl:param name="processedSubjects">
            <xsl:call-template name="processSubjects">
                <xsl:with-param name="subjectsToProcess" select="$LoCSubjects"/>
                <xsl:with-param name="subjectsProcessed">
                    <xsl:value-of select="$goodCavafySubjects/@ref/replace(., 'https:', 'http:')" separator=" ; "/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:param>
        
        <xsl:copy select="$cavafyEntry/pb:pbcoreDescriptionDocument">            
            <xsl:copy-of select="$cavafyID"/>
            <xsl:copy-of select="$collection"/>
            <xsl:apply-templates select="$processedSubjects" mode="LOCtoPBCore"/>
            <xsl:call-template name="parseContributors">
                <xsl:with-param name="contributorsToProcess" select="$allContributorURLs"/>
                <xsl:with-param name="contributorsAlreadyInCavafy">
                    <xsl:value-of
                        select="$goodCavafyContributors/@ref/replace(., 'https:', 'http:')"
                        separator=" ; "/>
                </xsl:with-param>
            </xsl:call-template>
            <!--            <xsl:copy-of select="$allLoCData"/>-->
        </xsl:copy>
     
    </xsl:template>
    
    <xsl:template match="node()" mode="lineAsteriskBreakup">
        <xsl:param name="line" select="
            analyze-string(., '\*')/fn:non-match"/>        
        <xsl:apply-templates select="$line" mode="parseAuthorTitle"/>
    </xsl:template>
    
    <xsl:template name="parseAuthorTitle" match="
            text()" mode="parseAuthorTitle">
        <xsl:param name="line" select="."/>
        <xsl:param name="lineNoBrackets">
            <xsl:value-of select="tokenize($line, $workDelimiters)"/>
        </xsl:param>
        <xsl:param name="guestIsInCAPS" select="
            matches($lineNoBrackets, $allCapsGuestNew)"/>
        <!-- Extract CAPS guests -->
        <xsl:param name="CAPSGuestExtracted">
            <xsl:apply-templates select="
                $lineNoBrackets[$guestIsInCAPS]"
                mode="extractCAPSGuest"/>
        </xsl:param>
        
        <!-- Extract author if author and work
        are related by strings such as
        '...who wrote...', '...author of...', etc. -->
        <xsl:param name="authorWorkAreRelated" select="
            matches($line, $authorBookDivider)"/>
        <xsl:param name="relatedAuthorWorkExtracted">
            <xsl:apply-templates select="
                $line[$authorWorkAreRelated]" 
                mode="extractRelatedAuthorWork"/>
        </xsl:param>
        <xsl:param name="relatedAuthorExtracted">
            <xsl:value-of select="tokenize(
                $relatedAuthorWorkExtracted/author, $workDelimiters)"/>
        </xsl:param>
        
        <!-- Get rid of profession in parsed author -->
        <xsl:param name="authorExtractedTokenized" select="
            tokenize($relatedAuthorExtracted, ' ')"/>
        <xsl:param name="author"
            select="tokenize(
            $relatedAuthorExtracted, 
            concat('(former )?', $professions, '+'), 'i')
            [last()]"/>
        <xsl:param name="finalAuthors">
            <xsl:value-of select="$CAPSGuestExtracted"/>
            <xsl:value-of select="$author[not($guestIsInCAPS)]"/>
        </xsl:param>
        <xsl:param name="lastSurname" select="
            tokenize($finalAuthors, ' ')[last()]"/>
        <xsl:param name="textAfterLastSurname" select="
            substring-after($line, $lastSurname)"/>
        
        <!-- Extract work if author and work
         are related by strings such as
        '...who wrote...', '...author of...', etc. -->
        <xsl:param name="relatedWorkExtracted" select="
            $relatedAuthorWorkExtracted/work"/>
        
        <!-- Extract the work if it is delimited 
        by quotation marks, parentheses, etc. -->
        <xsl:param name="workIsDelimited" select="
            matches($textAfterLastSurname, $workDelimiters)"/>
        <xsl:param name="workDelimited"
            select="
            analyze-string(
            $textAfterLastSurname[$workIsDelimited],
            $workDelimiters)/fn:match[last()]/
            normalize-space(tokenize(., ':')[1])"/>
        
        <xsl:param name="work">
            <xsl:value-of select="
                $workDelimited[contains($textAfterLastSurname, $workDelimited)]"/>
            <xsl:value-of
                select="
                tokenize($relatedWorkExtracted, ':')[1]
                [not($workIsDelimited)]
                [contains($textAfterLastSurname, $relatedWorkExtracted)]"
            />
        </xsl:param>
        <xsl:param name="workClean" select="
            replace($work, '\W', ' ')"/>
        
        <xsl:param name="searchResult">
            <xsl:if test="$finalAuthors != '' and $workClean != ''">
                <xsl:call-template name="searchLoC">
                    <xsl:with-param name="searchTerms"
                        select="
                            string-join(
                            ($finalAuthors, $workClean),
                            ' ')"/>
                    <xsl:with-param name="count" select="
                            '5'"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:param>
        <xsl:param name="workURI"
            select="
            $searchResult/
            json:json[json:count/number() lt 6]/
            json:hits/json:hit/json:uri"/>
        
        <newLine>
            <xsl:attribute name="guestIsInCaps" select="$guestIsInCAPS"/>
            <xsl:attribute name="workIsDelimited" select="$workIsDelimited"/>
            <xsl:attribute name="authorWorkAreRelated" select="$authorWorkAreRelated"/>
            <xsl:value-of select="$line"/>
            <parsedAuthorTitle>
                <guests>
                    <xsl:value-of select="$finalAuthors"/>
                </guests>
                
                <work>
                    <xsl:value-of select="$workClean"/>
                </work>
                <searchResult>
                    <xsl:copy-of select="$searchResult"/>
                </searchResult>
                <workURI>
                    <xsl:value-of select="$workURI"/>
                </workURI>
                <xsl:apply-templates select="
                    $workURI[contains(., 'id.loc.gov')]" mode="
                    workNAF_LCSH">
                    <xsl:with-param name="authorToMatch">
                        <xsl:value-of select="$finalAuthors"/>
                    </xsl:with-param>
                </xsl:apply-templates>
                <xsl:if test="$finalAuthors != '' and not($searchResult/json:json/json:count ='1')">
                    <justGuests>
                        <xsl:call-template name="searchLoC">
                            <xsl:with-param name="searchTerms" select="$finalAuthors"/>
                            <xsl:with-param name="database" select="'/authorities/names'"/>
                            <xsl:with-param name="rdftype" select="'PersonalName'"/>
                            <xsl:with-param name="count" select="'5'"/>
                        </xsl:call-template>
                    </justGuests>
                </xsl:if>
            </parsedAuthorTitle>
        </newLine>
    </xsl:template>
    
    <xsl:template match="text()" mode="extractCAPSGuest">
        <!-- Extract the author if it is ALL CAPS -->
        <xsl:param name="text" select="."/>
        <xsl:param name="parsedCAPSText" select="fn:analyze-string($text, $allCapsGuestNew)"/>
        <xsl:value-of select="
            $parsedCAPSText/fn:match/
            fn:normalize-space(replace(., '\W', ' '))"/>
    </xsl:template>
    
    <xsl:template match="text()" mode="extractRelatedAuthorWork">
        <xsl:param name="text" select="."/>
        <xsl:param name="tokenizedText"
            select="
            tokenize(
            $text,
            $authorBookDivider)"/>
        <author>
            <xsl:value-of
                select="
                fn:normalize-space(translate($tokenizedText[1], ',', ''))"
            />
        </author>
        <work>
            <xsl:value-of select="
                tokenize($tokenizedText[last()], ':')[1]"/>
        </work>
    </xsl:template>
    
</xsl:stylesheet>