<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:json="http://marklogic.com/xdmp/json/basic"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:bf="http://id.loc.gov/ontologies/bibframe/"
    xmlns:bflc="http://id.loc.gov/ontologies/bflc/"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:cc="http://creativecommons.org/ns#"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    exclude-result-prefixes="#all"
    version="3.0">

    <xsl:mode on-no-match="deep-skip"/>

    <xsl:output method="xml" indent="yes"/>
    
    <xsl:import href="processLoCURL.xsl"/>
    
    <xsl:param name="utilityLists" select="
        doc('utilityLists.xml')"/>
    
    <xsl:param name="alwaysUC">
        <xsl:value-of select="
            $utilityLists/utilityLists/
            alwaysUC/acronym
            [position() gt 1]" separator="|"/>
    </xsl:param>
    <xsl:param name="alwaysUCExact">
        <xsl:value-of select="'^'"/>
        <xsl:value-of select="
            replace($alwaysUC, '\|', '\$|^')"/>
        <xsl:value-of select="'$'"/>
    </xsl:param>
    <xsl:param name="allCapsGuestIndividualNameRegex">[A-Z\.\-’']{2,}</xsl:param>
    <xsl:param name="allCapsGuestExact">
        <xsl:value-of select="'^'"/>
        <xsl:value-of select="$allCapsGuestIndividualNameRegex"/>
        <xsl:value-of select="'$'"/>
    </xsl:param>
    <xsl:param name="allCapsGuestRegex">
        <xsl:value-of select="'( ?'"/>
        <xsl:value-of select="$allCapsGuestIndividualNameRegex"/>
        <xsl:value-of select="'){2,5}'"/>
    </xsl:param>
    <xsl:param name="possessivePlus">(his|hers|their|the)</xsl:param>
    <xsl:param name="professionQualifier">(co\-|former\senior)</xsl:param>
    <xsl:param name="professionalRelation">(of the |in the |with the )</xsl:param>
    <xsl:param name="professions">
        <xsl:value-of select="
            $utilityLists/utilityLists/
            professions/profession" separator="s?|"/>
        <xsl:value-of select="'s?'"/>
    </xsl:param>
    <!-- Regex patterns for parsing -->
    <xsl:param name="inParentheses">\(.+?\)</xsl:param>
    <xsl:param name="inQuotes">".+?"</xsl:param>
    <xsl:param name="inApostrophes">'.+?'</xsl:param>
    <xsl:param name="inSmartQuotes">“.+?”</xsl:param>
    <xsl:param name="inParenthesesQuotes">\(".+?"\)</xsl:param>
    <xsl:param name="inParenthesesApostrophes">\('.+?'\)</xsl:param>    
    <xsl:param name="inParenthesesSmartQuotes">\(“.+?”\)</xsl:param>
    <xsl:param name="enclosedTitleRegex">
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
    <xsl:param name="role">
        <!-- E.g. 'talks about', 'analyzes', ' on ', ... -->
        <xsl:value-of select="
            $utilityLists/utilityLists/
            roles/role" separator="|"/>
    </xsl:param>    
    <xsl:param name="professionInCommas">
        <xsl:value-of select="','"/>
        <xsl:value-of select="'.*'"/>
        <xsl:value-of select="'('"/>
        <xsl:value-of select="$professions"/>
        <xsl:value-of select="')'"/>
        <xsl:value-of select="'.+?'"/>
        <xsl:value-of select="','"/>
    </xsl:param>    
    <xsl:param name="typeOfWork">
        <!-- E.g. 'book', 'film', etc. -->
        <xsl:value-of select="
            $utilityLists/utilityLists/
            typesOfWork/typeOfWork" separator="|"/>
    </xsl:param>
    <xsl:param name="guestWorkDivider" select="
        concat($professions, '(.*', $typeOfWork, ')?')"/>
    <xsl:param name="workSubjectDivider" select="
        ', about | on the '"/>
    <xsl:param name="LoCReplaceRegex">[^A-Za-z0-9'\.’\- ]</xsl:param>
    <xsl:param name="associations">, (from |of ).+?,</xsl:param>    
    <xsl:param name="conjunctions">,| and</xsl:param>
    <xsl:param name="surnameSuffixes"> Jr\.| Sr\.</xsl:param>
    <xsl:param name="peopleDividers" select="
        concat(
        '(', $conjunctions, ')', 
        '|', 
        '(', $enclosedTitleRegex, ')', 
        '|', 
        '(', $surnameSuffixes, ')'
        )"/>
    <xsl:param name="workQualifiers" select="' new '"/>
    <xsl:param name="possessives" select="'his |her |their '"/>
    
    <xsl:param name="ignoreLineRegex">Open phones|listener call\-ins</xsl:param>
    
    

    <xsl:template match="pma_xml_export">
        <xsl:apply-templates select="database" mode="distinctEntries"/>
    </xsl:template>

    <xsl:template match="database" mode="distinctEntries">
        <!-- disable repeat entries -->
        <xsl:param name="cavafyEntries">
            <xsl:for-each-group select="table" group-by="
                    column[@name = 'URL']">
                <xsl:apply-templates select="." mode="parseAbstract"/>
            </xsl:for-each-group>
        </xsl:param>
        <cavafyEntries>
            <xsl:attribute name="totalLines" select="
                    count($cavafyEntries//line)"/>
            <xsl:copy-of select="$cavafyEntries"/>
        </cavafyEntries>
    </xsl:template>

    <xsl:template match="table" mode="parseAbstract">
        <xsl:param name="abstract" select="
                column[@name = 'abstract']"/>
        <xsl:param name="cavafyEntry">
            <cavafyEntry>
                <xsl:apply-templates select="
                    column[not(@name='abstract')]" 
                    mode="generateAttributes"/>                
                <abstract>
                    <xsl:attribute name="text" select="$abstract"/>
                    <xsl:apply-templates select="
                        $abstract" mode="lineBreakup"/>
                </abstract>
            </cavafyEntry>
        </xsl:param>
        <xsl:param name="badLines" select="
                $cavafyEntry/cavafyEntry/
                abstract/
                line
                [not(
                guestsDomain/guest/firstName
                [matches(., '[A-Z]')]
                )]"/>
        <xsl:copy-of select="$cavafyEntry"/>
    </xsl:template>


    <xsl:template match="
            pb:pbcoreDescription[@descriptionType = 'Abstract'] |
            column[@name = 'abstract'] | text()" mode="
            lineBreakup" name="lineBreakup">
        <xsl:param name="abstract" select=".[text()]"/>
        <xsl:param name="line" select="
                analyze-string(
                $abstract, '^.?\*.+', 'm'
                )/fn:match[matches(., '\w')]"/>
        <xsl:param name="lineParsed">
            <xsl:apply-templates select="
                    $line[not(matches(., $ignoreLineRegex, 'i'))]"
                mode="parseGuestTitle"/>
        </xsl:param>
        <xsl:copy-of select="$lineParsed"/>
    </xsl:template>

    <xsl:template match="text()" mode="parseGuestTitle">
        <xsl:param name="line" select="substring-after(., '*')"/>
        <xsl:param name="lineNoAcronyms" select="
                normalize-space(replace(
                $line, $alwaysUC, ''))"/>
        <xsl:param name="guestIsInCAPS" select="
            matches($lineNoAcronyms, $allCapsGuestRegex)"/>
        <xsl:param name="titleIsEnclosed" select="
            matches($line, $enclosedTitleRegex)"/>
        <xsl:param name="lineAnalyzed" select="
                analyze-string($line, $role)"/>
        <xsl:param name="guestsDomain" select="
                $lineAnalyzed/fn:non-match[1]"/>
        <xsl:param name="guestsCAPS" select="
                analyze-string(
                $lineNoAcronyms, $conjunctions)/
                fn:non-match[matches(., $allCapsGuestIndividualNameRegex)]/
                analyze-string(
                ., $allCapsGuestRegex
                )/fn:match"/>
        <!--<xsl:param name="guestsDomainAnalyzed" select="
                analyze-string(
                $guestsDomain, $enclosedTitleRegex
                )"/>-->
        <xsl:param name="guestsParsed">
            <xsl:apply-templates select="
                $guestsDomain" mode="separateGuests"/>
        </xsl:param>
        <xsl:param name="eachGuest">
            <xsl:copy-of select="
                    $guestsParsed/separateGuests/
                    guest[matches(., '\w')]"/>
            <!-- If the parsing of CAPped guests did not work out -->
            <xsl:copy-of select="
                    $guestsCAPS
                    [$guestIsInCAPS]
                    [not(matches($guestsDomain, $allCapsGuestIndividualNameRegex))]"/>
        </xsl:param> 
        
        <xsl:param name="workDomain" select="
            $lineAnalyzed/fn:non-match[2]"/>
        
        <xsl:param name="workDomainAnalyzed">
            <xsl:apply-templates select="
                $workDomain" mode="analyzeWork"/>
        </xsl:param>
        <xsl:param name="guestsProcessed">
            <xsl:apply-templates select="
                    $eachGuest[matches(., '[A-Z]')]" mode="
                processGuest">
                <xsl:with-param name="
                    guestIsInCAPS" select="
                        $guestIsInCAPS" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:param>
        <xsl:param name="workParsedFromLine">
            <xsl:for-each select="$guestsProcessed//guest
                [matches(firstName, '^[A-Z]')]
                [matches($workDomainAnalyzed/work/workTitle, '\w')]">
                <xsl:variable name="workTitle" select="$workDomainAnalyzed/work/workTitle"/>
                <xsl:variable name="workClean" select="
                    replace($workTitle, $LoCReplaceRegex, ' ')"/>
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
        <xsl:param name="workParsedFromLineResult" select="
            $workParsedFromLine/json:json/json:hits/json:hit"/>
        <xsl:param name="workParedFromLineUniqueInfo">
            <xsl:for-each-group select="$workParsedFromLineResult" group-by="json:uri">                    
                <xsl:apply-templates select="." mode="getWorkBasics"/>
            </xsl:for-each-group>
        </xsl:param>
        <line>
            <xsl:attribute name="line" select="$line"/>
            <xsl:attribute name="
                guestIsInCAPS" select="
                $guestIsInCAPS"/>
            <xsl:attribute name="
                titleIsEnclosed" select="
                $titleIsEnclosed"/>
            <guestsDomain>
                <xsl:attribute name="guestsDomain" select="$guestsDomain"/>
                <xsl:copy-of select="$guestsProcessed"/>                
            </guestsDomain>
            <workDomain>
                <xsl:attribute name="workDomain" select="$workDomain"/>
                <xsl:copy-of select="$workDomainAnalyzed"/>
            </workDomain>
            <results>
                <locWorks>
                    <xsl:copy-of select="$workParedFromLineUniqueInfo"/>
                </locWorks>
                <locGuestsFromWork>
                    <xsl:for-each select="$guestsProcessed//guest[firstName][lastName]">
                        <xsl:variable name="firstName" select="firstName"/>
                        <xsl:variable name="lastName" select="lastName"/>                        
                        <xsl:for-each-group select="$workParedFromLineUniqueInfo/rdf:RDF/bf:Agent
                            [matches(rdfs:label, $firstName, 'i')]
                            [matches(rdfs:label, $lastName, 'i')]" group-by="@rdf:about">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>
                    </xsl:for-each>
                </locGuestsFromWork>
            </results>
        </line>
    </xsl:template>

    <xsl:template match="." mode="separateGuests">
        <xsl:param name="guestsDomain" select="."/>
        <xsl:param name="splitGuests" select="
                analyze-string(
                $guestsDomain, $peopleDividers
                )"/>        
        <separateGuests>
            <xsl:for-each select="
                    $splitGuests/
                    fn:non-match
                    ">
                <xsl:variable name="guestName" select="
                        .[matches(replace(., $professions, ''), '\w')]
                        [not(matches(preceding-sibling::fn:match[1], $enclosedTitleRegex))]"/>
                <xsl:variable name="knownWork" select="analyze-string(., $enclosedTitleRegex)/fn:match"/>
                <!-- If last name appears after work -->
                <!-- E.g. Duke ("Mood Indigo") Ellington -->
                <xsl:variable name="lastNameAfterWork" select="
                        following-sibling::fn:non-match
                        [matches(preceding-sibling::fn:match[1], $enclosedTitleRegex)]
                        [1]"/>
                <xsl:variable name="guest">
                    <xsl:value-of select="
                            $guestName,
                            $knownWork,
                            $lastNameAfterWork"/>
                </xsl:variable>

                <guest>
                    
                    <xsl:attribute name="knownWork" select="replace($knownWork, '[\(\)]', '')"/>
                    
                    <xsl:value-of select="normalize-space($guest)"/>
                </guest>
            </xsl:for-each>
        </separateGuests>
    </xsl:template>
    
    <xsl:template match="node()" mode="processGuest">
        <xsl:param name="guest" select="."/>        
        <xsl:param name="analyzeGuestProfessions" select="
            analyze-string($guest, $professions, 'i')"/>
        <xsl:param name="profession">
            <xsl:value-of select="$analyzeGuestProfessions/fn:match"/>
        </xsl:param>
        <xsl:param name="guestNoProfession">
            <xsl:value-of select="$analyzeGuestProfessions/fn:non-match"/>
        </xsl:param>
        <xsl:param name="knownWork" select="
            analyze-string(
            $guestNoProfession, $enclosedTitleRegex
            )/fn:match"/>
        <xsl:param name="guestNoProfessionNoWork">
            <xsl:value-of select="
                analyze-string(
                $guestNoProfession, $enclosedTitleRegex)/fn:non-match"/>
        </xsl:param>
        <xsl:param name="parseAssociation" select="
            analyze-string(
            $guestNoProfessionNoWork, 
            $associations)"/>
        <xsl:param name="association" select="
            $parseAssociation/fn:match"/>
        <xsl:param name="guestName" select="
                replace(
                replace(
                ($parseAssociation/fn:non-match[1]),
                $LoCReplaceRegex, ''),
                ' the ', ' ', 'i')
                "/>        
        <xsl:param name="guestNames">
            <xsl:apply-templates select="
                $guestName[matches(., '[A-Z].+')]" mode="
                analyzeName"/>
        </xsl:param>
        <guest>
            <xsl:attribute name="profession" select="$profession[matches(., '\w')]"/>
            <xsl:attribute name="knownWork" select="$knownWork[matches(., '\w')]/replace(., '\(|\)', '')"/>
            <xsl:attribute name="association" select="$association[matches(., '\w')]"/>
            <xsl:attribute name="guest" select="$guest[matches(., '\w')]"/>            
            <xsl:attribute name="guestNoProfession" select="
                    $guestNoProfession[matches(., '\w')]"/>
            <xsl:attribute name="guestNoProfessionNoWork" select="
                    $guestNoProfessionNoWork[matches(., '\w')]"/>
            <xsl:attribute name="guestName" select="$guestName"/>
            <xsl:copy-of select="$guestNames"/>
        </guest>
    </xsl:template>
    
    <xsl:template match="." mode="analyzeName">
        <xsl:param name="guestName">
            <xsl:value-of select="tokenize(., $enclosedTitleRegex)"/>
        </xsl:param>
        <xsl:param name="guestIsInCAPS" select="true()" tunnel="yes"/>
        <xsl:param name="tokenizeName" select="
            analyze-string($guestName, ' ')/
            fn:non-match/normalize-space(.)
            [matches(., '^[A-Z].+')]"/>
        <xsl:param name="tokenizeNameCAPS" select='
            analyze-string($guestName, " ")/
            fn:non-match                   
            [matches(., "^[A-Z][A-Za-z&apos;].+")]'/>
        
        <xsl:variable name="firstName" select="
            $tokenizeNameCAPS[1]
            [$guestIsInCAPS]
            , 
            $tokenizeName[1]
            [not($guestIsInCAPS)]"/>
        <xsl:variable name="middleNames" select="
            ($tokenizeNameCAPS
            [position() gt 1]
            [position() lt last()]
            [$guestIsInCAPS])
            ,
            ($tokenizeName
            [position() gt 1]
            [position() lt last()]
            [not($guestIsInCAPS)])"/>            
        <xsl:variable name="lastName" select="
            $tokenizeNameCAPS
            [position() gt 1]
            [last()]
            [$guestIsInCAPS]
            ,
            $tokenizeName
            [position() gt 1]
            [last()]
            [not($guestIsInCAPS)]"/>
        
        <firstName>            
            <xsl:value-of select="normalize-space($firstName)"/>
        </firstName>        
        <xsl:for-each select="$middleNames">
            <middleName>
                <xsl:value-of select="normalize-space(.)"/>
            </middleName>
        </xsl:for-each>        
        <lastName>
            <xsl:value-of select="normalize-space($lastName)"/>
        </lastName>
    </xsl:template>
    
    <xsl:template match="text()" mode="analyzeWork">
        <xsl:param name="workDomain" select="."/>
        <xsl:param name="analyzeWork" select="analyze-string($workDomain, $enclosedTitleRegex)"/>
        <xsl:param name="workSubject">
            <xsl:apply-templates select="$analyzeWork/fn:non-match" mode="extractSubject"/>
        </xsl:param> 
        <xsl:param name="workTitleTokenized" select="$analyzeWork/fn:match/tokenize(., ':')"/>
        <xsl:param name="workSubtitle">
            <xsl:value-of select="$workTitleTokenized[position() gt 1]"/>
        </xsl:param>
        <xsl:param name="workType" select="analyze-string(., $typeOfWork)/fn:match"/>
        
        <work>
            <xsl:attribute name="workType" select="$workType"/>
            <workSubject>
                <xsl:value-of select="normalize-space($workSubject[matches(., '\w')])"/>
            </workSubject>
            <workTitle>
                <xsl:value-of select="replace(normalize-space($workTitleTokenized[1]), '\(|\)', '')"/>
            </workTitle>
            <workSubtitle>
                <xsl:value-of select="replace(normalize-space($workSubtitle), '\(|\)', '')"/>
            </workSubtitle>
        </work>
    </xsl:template>
    
    <xsl:template match="." mode="extractSubject">
        <xsl:param name="workDomain" select="."/>
        <xsl:param name="irrelevantWords">
            <xsl:value-of select="$workQualifiers, $possessives, $enclosedTitleRegex, $typeOfWork, $role" separator="|"/>
        </xsl:param>
        <xsl:param name="workDomainAnalyzed" select="analyze-string($workDomain, $irrelevantWords)"/>
        <subject>
            <xsl:value-of select="$workDomainAnalyzed/fn:non-match"/>
        </subject>
    </xsl:template>
    
    <xsl:template match="column" mode="generateAttributes">
        <xsl:attribute name="{replace(@name, ' ', '')}">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

</xsl:stylesheet>