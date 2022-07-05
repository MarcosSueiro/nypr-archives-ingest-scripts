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
    <xsl:import href="parseAuthorsTitlesLOGTotallyNew.xsl"/>

    
    <!--   Examples of LoC searches  
        doc('https://id.loc.gov/search/?q=rdftype:Work%20PETER%20CAREY%20Jack%20Maggs&amp;start=1&amp;format=atom')" 
    -->
    
    <!-- Many descriptions in cavafy
        conform to a pattern where
        authors are preceded by an asterisk (*)
        on each line
        -->
    
    <!-- For example,
            This mySQL search in phpMyAdmin 
            retrieves such abstracts:
    SELECT description AS abstract, 
    CONCAT('https://cavafy.wnyc.org/assets/', a.uuid) AS URL
FROM `descriptions` d
JOIN assets a ON d.asset_id = a.id
WHERE `description` REGEXP '^\\*[A-Z][A-z]+ [A-z].*\\*' -->
    
    <!-- This template parses out authors and their works, 
        then looks for them in LoC -->
    
    <xsl:mode on-no-match="deep-skip"/>
    
    <xsl:param name="role">
        <xsl:value-of select="
            $utilityLists/utilityLists/
            roles/role" separator="|"/>
    </xsl:param>
    <xsl:param name="typeOfWork">
        <xsl:value-of select="
            $utilityLists/utilityLists/
            typesOfWork/typeOfWork" separator="|"/>
    </xsl:param>
    <xsl:param name="guestWorkDivider" select="
        concat($role, '(.*', $typeOfWork, ')?')"/>
    <!--<xsl:param name="professionSuffixes" select="
        '.+or$|.+wright$|.+er$|.+ess$|.+man$|.+ist$'"/>-->
    <!--<xsl:param name="workDelimiters">(".+")|“.+”|\(.+\))</xsl:param>
        
    <xsl:param name="workSubjectDivider" select="', about | on the '"/>
    <xsl:param name="replaceRegex">[^A-Za-z0-9'\.’\- ]</xsl:param>
    <xsl:param name="alwaysUC">
        <xsl:value-of select="
            $utilityLists/utilityLists/
            alwaysUC/acronym
            [position() gt 1]" separator="|"/>
    </xsl:param>
    <xsl:param name="alwaysUCExact">
        <xsl:value-of select="'^'"/>
        <xsl:value-of select="replace($alwaysUC, '\|', '\$|^')"/>
        <xsl:value-of select="'$'"/>
    </xsl:param>
    
    <xsl:param name="inParentheses" select="'\(.+?\)'"/>
    <xsl:param name="inQuotes" select="'&quot;.+?&quot;'"/>
    <xsl:param name="inApostrophes" select='"&apos;.+?&apos;"'/>
    <xsl:param name="inParenthesesQuotes" select="'\(&quot;.+?&quot;\)'"/>
    <xsl:param name="inParenthesesApostrophes" select='"\(&apos;.+?&apos;\)"'/>
    <xsl:param name="inSmartQuotes">“.+?”</xsl:param>
    <xsl:param name="inParenthesesSmartQuotes">\(“.+?”\)</xsl:param>
    <xsl:param name="enclosedTitle">
        <xsl:value-of select="
            $inParentheses, 
            $inQuotes, 
            $inApostrophes, 
            $inParenthesesQuotes, 
            $inParenthesesApostrophes,
            $inSmartQuotes,
            $inParenthesesSmartQuotes" 
            separator="|"/>
    </xsl:param>
    
    <xsl:param name="conjunctions" select="
        ',| and'"/>
    <xsl:param name="suffixes" select="' Jr\.| Sr\.'"/>
    <xsl:param name="peopleDividers" select="
        concat(
        '(', $conjunctions, ')', 
        '|', 
        '(', $enclosedTitle, ')', 
        '|', 
        '(', $suffixes, ')'
        )"/>
    <xsl:param name="workQualifiers" select="'new'"/>
    <xsl:param name="possessives" select="'his |her |their '"/>
    
    <xsl:param name="ignoreLineRegex">Open phones|listener call\-ins</xsl:param>
    -->
    <xsl:import href="utilities.xsl"/>
    
    
    <xsl:template match="pma_xml_export">
        <xsl:param name="completeData">
            <xsl:apply-templates select="database" mode="distinctEntries"/>
        </xsl:param>
        <xsl:param name="newData">
            <xsl:copy select="$completeData/cavafyEntries">
                <xsl:apply-templates select="
                        pb:pbcoreDescriptionDocument
                        [pb:pbcoreSubject | pb:pbcoreContributor]"
                    mode="onlyNewData"/>
            </xsl:copy>
        </xsl:param>
        <xsl:param name="baseURI" select="base-uri(.)"/>
        <xsl:param name="parsedBaseURI" select="
            analyze-string($baseURI, '/')"/>
        <xsl:param name="docFilename" select="
            $parsedBaseURI/fn:non-match[last()]"/>
        <xsl:param name="docFilenameNoExtension" 
            select="substring-before($docFilename, '.')"/>
        <xsl:param name="baseFolder" select="
            substring-before($baseURI, $docFilename)"/>
        <xsl:param name="logFolder" 
            select="concat($baseFolder, 'instantiationUploadLOGS/')"/>
        <xsl:param name="currentTime"
            select="substring(
            translate(string(current-time()),
            ':', ''), 1, 4)"/>
        <xsl:param name="filenameLog"
            select="
            concat(
            $logFolder,
            $masterDocFilenameNoExtension,                
            '_LOG', format-date(current-date(),
            '[Y0001][M01][D01]'), '_T',
            $currentTime,
            '.xml'
            )"/>
        <xsl:param name="filename"
            select="
            concat($baseFolder,
            $masterDocFilenameNoExtension
            )"/>
        <xsl:result-document href="{$filenameLog}">
            <xsl:copy-of select="$completeData"/>
        </xsl:result-document>
        <xsl:apply-templates select="$newData" mode="breakItUp">
            <xsl:with-param name="breakupDocBaseURI" select="$baseURI"/>
            <xsl:with-param name="filename" select="$filename"/>
        </xsl:apply-templates>
    </xsl:template>
    
    
    
    <xsl:template name="processCavafyEntry" match="table" mode="processCavafyEntry">
        <xsl:param name="url" select="column[@name = 'URL']"/>
        <xsl:param name="cavafyEntryMessage">
            <xsl:message select="'Process cavafy entry ', $url"/>
        </xsl:param>
        <xsl:param name="abstractProvided" select="
            column[@name = 'abstract']
            [not(. = 'NULL')]"/>
        <xsl:param name="collectionProvided" select="
            column[@name = 'collection']
            [not(. = 'NULL')]"/>
        <xsl:param name="seriesProvided" select="
            column[@name = 'series']
            [not(. = 'NULL')]"/>
        <xsl:param name="locContributorsProvided" select="
            column[@name = 'locContr']
            [not(. = 'NULL')]"/>
        <xsl:param name="otherContProvided" select="
            column[@name = 'otherCont']
            [not(. = 'NULL')]"/>
        <xsl:param name="locSubjectsProvided" select="
            column[@name = 'locSubj']
            [not(. = 'NULL')]"/>
        <xsl:param name="otherSubjectsProvided" select="
            column[@name = 'otherSubj']
            [not(. = 'NULL')]"/>
        <xsl:param name="cavafyIDProvided" select="
            column[@name = 'cavafyID']
            [not(. = 'NULL')]"/>
        <xsl:param name="cavafyDoc" select="
            doc(concat($url, '.xml'))"/>
        <xsl:param name="abstract">
            <xsl:value-of select="
                    $abstractProvided
                    [matches(., '\w')]"/>
            <xsl:value-of select="
                    $cavafyDoc/
                    pb:pbcoreDescriptionDocument/
                    pb:pbcoreDescription
                    [@descriptionType = 'Abstract']
                    [not(
                    matches($abstractProvided, '\w')
                    )]"/>
        </xsl:param>
        <xsl:param name="cavafyID">
            <xsl:value-of select="
                $cavafyIDProvided
                [matches(., '\w')]"/>
            <xsl:value-of select=" $cavafyDoc/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreIdentifier
                [@source = 'WNYC Archive Catalog']
                [not(
                matches($cavafyIDProvided, '\w')
                )]"/>
        </xsl:param>
        <xsl:param name="collection">
            <xsl:value-of select="
                $collectionProvided
                [matches(., '\w')]"/>
            <xsl:value-of select="$cavafyDoc/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreTitle[@titleType = 'Collection']
                [not(
                matches($collectionProvided, '\w')
                )]"/>
        </xsl:param>
        <xsl:param name="series">
            <xsl:value-of select="
                $seriesProvided
                [matches(., '\w')]"/>
            <xsl:value-of select="$cavafyDoc/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreTitle[@titleType = 'Series']
                [not(
                matches($seriesProvided, '\w')
                )]"/>
        </xsl:param>
        <xsl:param name="abstractToLines">
            <xsl:call-template name="lineBreakup">
                <xsl:with-param name="text" select="$abstract"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="lineParsed">
            <xsl:apply-templates select="
                $abstractToLines/line
                [not(matches(., $ignoreLineRegex, 'i'))]
                [matches(., '\w')]"
                mode="parseLine"/>
        </xsl:param>
        <xsl:param name="linesCount" select="count($abstractToLines/line)"/>
        <xsl:param name="guestsCount" select="count($abstractToLines/line/subject/guest)"/>
        <xsl:param name="worksCount" select="count($abstractToLines/line/predicate/work)"/>
        <xsl:param name="goodCavafyContributors"
            select="
            $cavafyDoc/
            pb:pbcoreDescriptionDocument/
            pb:pbcoreContributor/
            pb:contributor
            [contains(@ref, 'id.loc.gov')]"/>
        <xsl:param name="badCavafyContributors"
            select="
            $cavafyDoc/
            pb:pbcoreDescriptionDocument/
            pb:pbcoreContributor/
            pb:contributor
            [not(contains(@ref, 'id.loc.gov'))]"/>
        <xsl:param name="badCavafySubjects" select="
            $cavafyDoc/
            pb:pbcoreDescriptionDocument/
            pb:pbcoreSubject
            [not(contains(@ref, 'id.loc.gov'))]"/>
        <xsl:param name="goodCavafySubjects" select="
            $cavafyDoc/
            pb:pbcoreDescriptionDocument/
            pb:pbcoreSubject
            [contains(@ref, 'id.loc.gov')]"/>
        <xsl:param name="cavafyEntry">
            <cavafyEntry>
                <xsl:attribute name="URL" select="$url"/>
                <xsl:attribute name="cavafyID" select="$cavafyID"/>
                <xsl:attribute name="series" select="$series"/>
                <xsl:attribute name="collection" select="$collection"/>
                <abstract>
                    <xsl:attribute name="lines" select="$linesCount"/>
                    <xsl:attribute name="guests" select="$guestsCount"/>
                    <xsl:attribute name="works" select="$worksCount"/>
                    <xsl:attribute name="abstractText" select="$abstract"/>
                    <xsl:for-each select="$lineParsed/line">
                        <line>
                            <subject>
                                <xsl:apply-templates select="subject" mode="analyzeSubject"/>
                            </subject>
                            <predicate>
                                <xsl:apply-templates select="predicate" mode="analyzePredicate"/>
                            </predicate>
                        </line>
                    </xsl:for-each>
                </abstract>
            </cavafyEntry>
        </xsl:param>
        <xsl:param name="badLines" select="
            $cavafyEntry/cavafyEntry/
            abstract/
            line[not(guestsDomain/guest/firstName[matches(., '[A-Z]')])]"/>
        <xsl:param name="allLoCData">
                <!-- Search LoC with contributors in cavafy -->
                <cavafyContributors>
                    <xsl:for-each select="$badCavafyContributors">
                        <locContributor>
                            <xsl:call-template name="searchLoC">
                                <xsl:with-param name="searchTerms" select="."/>
                                <xsl:with-param name="database" select="'/authorities/names'"/>
                                <xsl:with-param name="rdftype" select="'PersonalName'"/>                                
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
            <xsl:for-each select="$abstractToLines/
                line/guestsDomain/guest[matches(firstName, '[A-Z]')]">
                <xsl:variable name="workTitle" select="../../workDomain/work/workTitle"/>
                <xsl:variable name="workClean" select="
                    replace($workTitle, '\W', ' ')"/>
                <xsl:call-template name="searchLoC">
                    <xsl:with-param name="searchTerms"
                        select="
                        firstName, lastName, $workClean"/>
                    <xsl:with-param name="count" select="
                        '5'"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:param>
        <xsl:param name="cavafyContributorsURLs">
            <xsl:value-of
                select="$allLoCData/
                cavafyContributors/
                locContributor/
                json:json/
                json:hits/json:hit/json:uri"
                separator=" ; "/>
        </xsl:param>
        <xsl:param name="cavafySubjectsURLs" 
                select="$allLoCData/
                cavafySubjects/
                cavafySubject/
                rdf:RDF/madsrdf:*/
                @rdf:about"
                />
        <xsl:param name="workParsedFromLine">
            <xsl:for-each select="$abstractToLines/
                line/guestsDomain/guest[matches(firstName, '[A-Z]')]">
                <xsl:variable name="workTitle" select="../../workDomain/work/workTitle"/>
                <xsl:variable name="workClean" select="
                    replace($workTitle, '\W', ' ')"/>
                <xsl:call-template name="searchLoC">
                    <xsl:with-param name="searchTerms"
                        select="
                        string-join(
                        (firstName, lastName, $workClean),
                        ' ')"/>
                    <xsl:with-param name="count" select="
                        '5'"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:param>
        <xsl:param name="cavafyParsedAbstractWorkContributorURLs">
            
            <!--<xsl:value-of
                select="$allLoCData/
                cavafyEntry/
                abstract/
                parsedAbstract/
                newLine[number(searchResult/json:json/json:count) lt 50]/
                work/locAuthor/authorURI"
                separator=" ; "/>-->
        </xsl:param>
        <xsl:param name="cavafyParsedAbstractParsedContributorURLs">
            <xsl:value-of
                select="$allLoCData/cavafyEntry/
                abstract/parsedAbstract/
                newLine/
                justGuests/json:json/
                json:hits/json:hit/json:uri"
                separator=" ; "/>
        </xsl:param>
        <xsl:param name="allContributorURLs">
            <xsl:value-of
                select="
                $cavafyContributorsURLs, 
                $cavafyParsedAbstractWorkContributorURLs, 
                $cavafyParsedAbstractParsedContributorURLs"
                separator=" ; "/>
        </xsl:param>
        <xsl:param name="LoCSubjects">
            <xsl:value-of
                select="($allLoCData/
                cavafyEntry/
                abstract/
                parsedAbstract/
                newLine
                [number(searchResult/json:json/json:count) lt 5]/
                work/
                subjects/
                subject/
                subjectURL), $cavafySubjectsURLs"
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
        
        <xsl:copy-of select="$cavafyEntry"/>
        <xsl:for-each select="
            $cavafyEntry/cavafyEntry/
            abstract/line
            [predicate/work/workTitle
            [matches(., '\w')]]">
            <xsl:call-template name="searchLoC">
            <xsl:with-param name="searchTerms">
                <xsl:value-of select="subject/guest/guestName/firstName, subject/guest/guestName/lastName, predicate/work/workTitle"/>
            </xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
        <!--<xsl:copy-of select="$allLoCData"/>-->
        
        <!--<xsl:copy select="$cavafyDoc/pb:pbcoreDescriptionDocument">
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
            <xsl:copy-of select="$allLoCData"/>
        </xsl:copy>-->
     
    </xsl:template>
    
    <!--<xsl:template name="parseAuthorTitle" match="
            text()" mode="parseAuthorTitle">
        <xsl:param name="line" select="."/>
        <xsl:param name="lineNoBrackets">
            <xsl:value-of select="tokenize($line, $workDelimiters)"/>
        </xsl:param>
        <xsl:param name="guestIsInCAPS" select="
            matches($lineNoBrackets, $allCapsGuest)"/>
        <!-\- Extract CAPS guests -\->
        <xsl:param name="CAPSGuestExtracted">
            <xsl:apply-templates select="
                $lineNoBrackets[$guestIsInCAPS]"
                mode="extractCAPSGuest"/>
        </xsl:param>
        
        <!-\- Extract author if author and work
        are related by strings such as
        '...who wrote...', '...author of...', etc. -\->
        <xsl:param name="authorWorkAreRelated" select="
            matches($line, $guestWorkDivider)"/>
        <xsl:param name="relatedAuthorWorkExtracted">
            <xsl:apply-templates select="
                $line[$authorWorkAreRelated]" 
                mode="extractRelatedAuthorWork"/>
        </xsl:param>
        <xsl:param name="relatedAuthorExtracted">
            <xsl:value-of select="tokenize(
                $relatedAuthorWorkExtracted/author, $workDelimiters)"/>
        </xsl:param>
        
        <!-\- Get rid of profession in parsed author -\->
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
        
        <!-\- Extract work if author and work
         are related by strings such as
        '...who wrote...', '...author of...', etc. -\->
        <xsl:param name="relatedWorkExtracted" select="
            $relatedAuthorWorkExtracted/work"/>
        
        <!-\- Extract the work if it is delimited 
        by quotation marks, parentheses, etc. -\->
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
            
        </newLine>
    </xsl:template>-->
    
    <!--<xsl:template match="text()" mode="extractCAPSGuest">
        <!-\- Extract the author if it is ALL CAPS -\->
        <xsl:param name="text" select="."/>
        <xsl:param name="parsedCAPSText" select="fn:analyze-string($text, $allCapsGuest)"/>
        <xsl:value-of select="
            $parsedCAPSText/fn:match/
            fn:normalize-space(replace(., '\W', ' '))"/>
    </xsl:template>-->
    
    <xsl:template match="text()" mode="extractRelatedAuthorWork">
        <xsl:param name="text" select="."/>
        <xsl:param name="guestWorkDivider" select="$guestWorkDivider"/>
        <xsl:param name="tokenizedText"
            select="
            tokenize(
            $text,
            $guestWorkDivider)"/>
        <xsl:param name="authors" select="
            fn:normalize-space(translate($tokenizedText[1], ',', ''))"/>
        <xsl:param name="authorsTokenized" select="tokenize($authors, ', | and ', 'i')"/>
        <author>
            <xsl:value-of
                select="
                fn:normalize-space(translate($tokenizedText[1], ',', ''))"
            />
        </author>
        <work>
            <xsl:value-of select="
                fn:normalize-space(tokenize($tokenizedText[last()], ':')[1])"/>
        </work>
    </xsl:template>
    
    <xsl:template match="pb:pbcoreDescriptionDocument" mode="onlyNewData">
        <xsl:copy>
            <xsl:copy-of select="*[not(local-name()='cavafyEntry')]"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>