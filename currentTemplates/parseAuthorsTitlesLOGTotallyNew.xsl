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
    xmlns:WNYC="http://www.wnyc.org"
    exclude-result-prefixes="#all"
    version="3.0">

    <xsl:mode on-no-match="deep-skip"/>

    <xsl:output method="xml" indent="yes"/>
    
    <xsl:import href="processLoCURL.xsl"/>
    
    <xsl:param name="utilityLists" select="
        doc('utilityLists.xml')"/>
    <xsl:param name="
        ignoreLineRegex">Open phones|listener call\-ins</xsl:param>
    <xsl:param name="lineRegex">^.?\*.+</xsl:param>
    <!-- Words always in UPPER CASE -->
    <xsl:param name="alwaysUC" select="
        $utilityLists/utilityLists/
        alwaysUC/acronym
        [position() gt 1]"/>
    <xsl:param name="alwaysUCRegex">
        <xsl:value-of select="
            $alwaysUC" separator="|"/>
    </xsl:param>
    <xsl:param name="alwaysUCRegexExact">
        <xsl:value-of select="'^'"/>
        <xsl:value-of select="
            $alwaysUC" separator="\$|^"/>
        <xsl:value-of select="'$'"/>
    </xsl:param>
    <!-- Guests in UPPER CASE -->
    <xsl:param name="
        allCapsGuestEachNameRegex">([A-Z\-’'\.]{2,})</xsl:param>
    <xsl:param name="allCapsGuestRegex">
        <xsl:value-of select="'('"/>
        <xsl:value-of select="$allCapsGuestEachNameRegex"/>
        <xsl:value-of select="' ?){2,5}'"/>
    </xsl:param>
    <!-- Guests with First Upper Case -->
    <xsl:param name="eachNameRegex">([A-Z][A-Za-z\-’'\.]+,? *)</xsl:param>
    <xsl:param name="guestRegex">
        <xsl:value-of select="'('"/>
        <xsl:value-of select="$eachNameRegex"/>
        <xsl:value-of select="'\s?){2,5}'"/>
    </xsl:param>
    <xsl:param name="surnameSuffixes">(,? Jr\.|,? Sr\.|,? JR\.|,? SR\.)</xsl:param>
    <!-- Guest name Regex patterns -->
    <xsl:param name="fullNameRegex">
        <xsl:value-of select="'('"/>
        <xsl:value-of select="$allCapsGuestRegex"/>
        <xsl:value-of select="'|'"/>
        <xsl:value-of select="$guestRegex"/>
        <xsl:value-of select="$surnameSuffixes"/>
        <xsl:value-of select="'?)'"/>
    </xsl:param>
    <xsl:param name="allCapsGuestExact">
        <xsl:value-of select="'^'"/>
        <xsl:value-of select="$allCapsGuestEachNameRegex"/>
        <xsl:value-of select="'$'"/>
    </xsl:param>
    
    <!-- Title regex -->
    <xsl:param name="inParentheses">\(.+?\)</xsl:param>
    <xsl:param name="inQuotes">".+?"</xsl:param>
    <xsl:param name="inApostrophes">'.+?'</xsl:param>
    <xsl:param name="inSmartQuotes">“.+?”</xsl:param>
    <xsl:param name="inParenthesesQuotes">\(".+?"\)</xsl:param>
    <xsl:param name="inParenthesesApostrophes">\('.+?'\)</xsl:param>    
    <xsl:param name="inParenthesesSmartQuotes">\(“.+?”\)</xsl:param>
    <xsl:param name="enclosedTitleRegex">
        <xsl:value-of select="'('"/>
        <xsl:value-of select="
                $inParentheses,
                $inQuotes,
                $inApostrophes,
                $inSmartQuotes,
                $inParenthesesQuotes,
                $inParenthesesApostrophes,
                $inParenthesesSmartQuotes" separator="|"/>
        <xsl:value-of select="')'"/>
    </xsl:param>
    <xsl:param name="eachCapTitleWordRegex">([A-Z][a-z]+,? +)</xsl:param>
    <xsl:param name="capTitleRegex">
        <xsl:value-of select="'('"/>
        <xsl:value-of select="$eachCapTitleWordRegex"/>
        <xsl:value-of select="'\s?){2,}'"/>
    </xsl:param>
    
    <!-- Other useful regex expressions -->

    <xsl:param name="possessivePlus"> (his |her |their |the )</xsl:param>
    
    <!-- Nationality -->
    <xsl:param name="nationalityRegex">
        <xsl:value-of select="'('"/>
        <xsl:value-of select="
            $utilityLists/utilityLists/
            nationalities/nationality" separator=" |"/>
        <xsl:value-of select="')'"/>
    </xsl:param>
    
    <!-- Professions -->
    <xsl:param name="professionPrefix">(Acclaimed| Artistic |Co\-|Distinguished |Famed |Former |Guest |Hip |Hopeless| Leading |Legendary |Master |Senior |Star |Veteran |World\-class |World renowned)</xsl:param>
    <xsl:param name="professionRegex">
        <xsl:value-of select="'('"/>
        <xsl:value-of select="
            $utilityLists/utilityLists/
            professions/profession" separator="|"/>
        <xsl:value-of select="')'"/>
    </xsl:param>
    <xsl:param name="professionSuffix">(\-at\-large|\-in\-residence| emeritus| extraordinaire)</xsl:param>
    <xsl:param name="fullProfessionRegex">
        <xsl:value-of select="
            $professionPrefix, '?',
            $professionRegex, 
            $professionSuffix, '? '" separator=""/>
    </xsl:param>
    <xsl:param name="professionalRelation"> (of |in |with |at |from )</xsl:param>
        
    <xsl:param name="associationRegex">
        <xsl:value-of select="'(', 
            $professionalRelation,
            '(the)?', 
            $workTypeRegex, '?', 
            '(.+)$)'" separator=""/>
    </xsl:param>
    
    <xsl:param name="personPreIdentifier">
        <xsl:value-of select="'('"/>
        <xsl:value-of select="$nationalityRegex"/>
        <xsl:value-of select="'\s+'"/>
        <xsl:value-of select="$fullProfessionRegex"/>
        <xsl:value-of select="')'"/>
    </xsl:param>
    <xsl:param name="workOrPlace">(\(?"?'?[\w\s':\-]+'?"?\)?)</xsl:param>
    <xsl:param name="personPostIdentifier">
        <xsl:value-of select="'('"/>
        <xsl:value-of select="$fullProfessionRegex"/>
        <xsl:value-of select="'\s+'"/>
        <xsl:value-of select="$professionalRelation"/>
        <xsl:value-of select="'?.+'"/>
        <xsl:value-of select="$workTypeRegex"/>
        <xsl:value-of select="'?.+'"/>
        <xsl:value-of select="$enclosedTitleRegex"/>
        <xsl:value-of select="'?'"/>
        <xsl:value-of select="$workOrPlace"/>
        <xsl:value-of select="')'"/>
    </xsl:param>
    <xsl:param name="roleRegex">
        <!-- E.g. ' who directed', ' who wrote'... -->
        <xsl:value-of select="',?('"/>
        <xsl:value-of select="$utilityLists/utilityLists/roles/role" separator="|"/>
        <xsl:value-of select="')'"/>
    </xsl:param>
        <xsl:param name="verbRegex">
        <!-- E.g. 'talks about', 'analyzes', ' on ', ... -->
        <xsl:value-of select="'('"/>
        <xsl:value-of select="
            $utilityLists/utilityLists/
            verbs/verb" separator=" |"/>
        <xsl:value-of select="')'"/>
    </xsl:param>    
    <!--<xsl:param name="professionInCommas">
        <xsl:value-of select="','"/>
        <xsl:value-of select="'.*'"/>
        <xsl:value-of select="'('"/>
        <xsl:value-of select="$fullProfessionRegex"/>
        <xsl:value-of select="')'"/>
        <xsl:value-of select="'.+?'"/>
        <xsl:value-of select="','"/>
    </xsl:param>--> 
    <xsl:param name="workQualifiers">( new| hit| latest| long\-awaited| award\-winning)</xsl:param>
    
    <xsl:param name="workTypeRegex">
        <!-- E.g. 'book', 'film', etc. -->
        <xsl:value-of select="$workQualifiers"/>
        <xsl:value-of select="'?'"/>
        <xsl:value-of select="'('"/>
        <xsl:value-of select="
            $utilityLists/utilityLists/
            typesOfWork/typeOfWork" separator="|"/>
        <xsl:value-of select="')'"/>
    </xsl:param>
    <!--<xsl:param name="guestWorkDivider" select="
        concat($fullProfessionRegex, '(.*', $workTypeRegex, ')?')"/>
    <xsl:param name="workSubjectDivider" select="
        ', about | on the '"/> -->
    
    <xsl:param name="LoCReplaceRegex">[^A-Za-z0-9'\.’\- ]</xsl:param>
    <!--<xsl:param name="associations">, (from |of |at ).+?,</xsl:param>    
    <xsl:param name="conjunctions">,| and</xsl:param>-->
    
    <!--<xsl:param name="peopleDividers" select="
        concat(
        '(', $conjunctions, ')', 
        '|', 
        '(', $enclosedTitleRegex, ')', 
        '|', 
        '(', $surnameSuffixes, ')'
        )"/>-->
    
    
    <!--<xsl:template match="pma_xml_export">
        <xsl:apply-templates select="database" mode="distinctEntries"/>
    </xsl:template>-->

    <xsl:template match="database" mode="distinctEntries">
        <!-- disable repeat entries -->
        <xsl:param name="cavafyEntries">
            <xsl:for-each-group select="table" group-by="
                    column[@name = 'URL']">
                <xsl:apply-templates select="." mode="processCavafyEntry"/>                
            </xsl:for-each-group>
        </xsl:param>
        <cavafyEntries>
            <xsl:attribute name="totalLines" select="
                    count($cavafyEntries//line)"/>
            <xsl:copy-of select="$cavafyEntries"/>
        </cavafyEntries>
    </xsl:template>

    <xsl:template name="parseAbstract" match="table" mode="parseAbstract">
        <xsl:param name="abstract" select="
                column[@name = 'abstract']"/>
        <xsl:param name="url" select="
            column[@name = 'URL']"/>
        <xsl:param name="parseAbstractMessage">
            <xsl:message select="'Parse abstract in url ', $url"/>
        </xsl:param> 
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


    <xsl:template name="lineBreakup" match="
            pb:pbcoreDescription
            [@descriptionType = 'Abstract'] |
            column[@name = 'abstract'] |
            text()" mode="
            lineBreakup">
        <xsl:param name="text" select=".[text()]"/>
        <xsl:param name="lineBreakupMessage">
            <xsl:message select="'Break this text into lines: ', $text"/>
        </xsl:param>
        <xsl:for-each select="
                analyze-string(
                $text, $lineRegex, 'm'
                )/fn:match[matches(., '\w')]">
            <line>
                <xsl:value-of select="."/>
            </line>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="text()" mode="parseLine">
        <xsl:param name="line" select="
            tokenize(., '\*')[last()]"/>
        <xsl:param name="parseLineMessage">
            <xsl:message select="'Parse line of text ', $line"/>
        </xsl:param>        
        <xsl:param name="enclosedTitle" select="
            matches($line, $enclosedTitleRegex)"/>
        <xsl:param name="verbExists" select="
            matches($line, $verbRegex)"/>
        <xsl:param name="verbLocation" select="
            analyze-string($line, $enclosedTitleRegex)/
            fn:non-match[matches($line, $verbRegex)][1]"/>
        <xsl:param name="verbLocationAnalyzed" select="
            analyze-string($verbLocation, $verbRegex)"/>
        <xsl:param name="predicateSideOfVerbLocation">
            <xsl:value-of select="$verbLocationAnalyzed/fn:match[1], 
                $verbLocationAnalyzed/fn:match[1]/following-sibling::*" separator=""/>
        </xsl:param>
        <xsl:param name="subjectSideOfVerbLocation">
            <xsl:value-of select="
                $verbLocationAnalyzed/fn:match[1]/preceding-sibling::*" separator=""/>
        </xsl:param>
        <xsl:param name="subject">
            <xsl:value-of select="$line[not($verbExists)]"/>
            <xsl:value-of select="(
                $verbLocation/preceding-sibling::*,
                $subjectSideOfVerbLocation)[$verbExists]" separator=""/>
        </xsl:param>
        <xsl:param name="predicate">
            <xsl:value-of select="
                $predicateSideOfVerbLocation, 
                $verbLocation/following-sibling::*" separator=""/>
        </xsl:param>
        
        
        
        <xsl:param name="predicateRegex">
            <xsl:value-of select="'(.+)'"/>
            <xsl:value-of select="
                $enclosedTitleRegex[$enclosedTitle], 
                '()'[not($enclosedTitle)]"/>
            <xsl:value-of select="'(.*)'"/>
        </xsl:param>
        <xsl:param name="predicateAnalysis" select="
            analyze-string(
            $line[$verbExists], 
            $predicateRegex)"/>
        <xsl:param name="nonTitles" select="
            $predicateAnalysis/fn:match/
            fn:group[@nr='1' or @nr='3']"/>
        <xsl:param name="verbPhrase" select="
            $nonTitles[matches(., $verbRegex)][last()]"/>
        <xsl:param name="verbAnalysis" select="
            analyze-string(
            $verbPhrase, $verbRegex
            )"/>
        <xsl:param name="verb" select="
            $verbAnalysis/fn:match[last()]"/>        
        <xsl:param name="verbPosition" select="
            count(
            $verbAnalysis/
            fn:match
            [matches(., '[\w:]')])"/>        
        
        
        
        <line>
            <xsl:attribute name="text" select="$line"/>
            <xsl:attribute name="enclosedTitle" select="$enclosedTitle"/>
            <xsl:attribute name="verbExists" select="$verbExists"/>
            <subject>
                <xsl:value-of select="$subject"/>
            </subject>
            <predicate>              
                <xsl:value-of select="$predicate"/>
            </predicate>
        </line>
        
    </xsl:template>

    <!--<xsl:template match="." mode="separateGuests">
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
                        .[matches(replace(., $fullProfessionRegex, ''), '\w')]
                        [not(matches(preceding-sibling::fn:match[1], $enclosedTitleRegex))]"/>
                <xsl:variable name="knownWork">
                    <xsl:apply-templates select=".[matches(., '\w')]" mode="extractWorks"/>
                </xsl:variable>
                <!-\- If last name appears after work -\->
                <!-\- E.g. Duke ("Mood Indigo") Ellington -\->
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
                    
                    <xsl:copy-of select="$splitGuests"/>
                    
                    <xsl:value-of select="normalize-space($guest)"/>
                </guest>
            </xsl:for-each>
        </separateGuests>
    </xsl:template>-->
    
    <!--<xsl:template match="node()" mode="processGuest">
        <xsl:param name="guest" select="."/>        
        <xsl:param name="analyzeGuestProfessions" select="
            analyze-string($guest, $fullProfessionRegex, 'i')"/>
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
    </xsl:template>-->
    
    <xsl:template name="analyzeSubject" match="subject" mode="analyzeSubject">
        <!-- Analyze the subject of the statement -->
        <xsl:param name="subject" select="."/>
        <xsl:param name="analyzeSubjectMessage">
            <xsl:message select="'Analyze subject ', $subject"/>
        </xsl:param>
        <xsl:param name="subjectRegex">
            <xsl:value-of select="
                    $enclosedTitleRegex,
                    $fullProfessionRegex,
                    $roleRegex,
                    $workTypeRegex,
                    $nationalityRegex,
                    $associationRegex
                    " separator="|"/>
        </xsl:param>
        <xsl:param name="stringAnalysis" select="
                analyze-string($subject, $subjectRegex, 'i')"/>
        <xsl:param name="conjunctionLocation" select="
                $stringAnalysis/fn:non-match[matches(., ' and ')]"/>

        <!-- <xsl:copy-of select="$stringAnalysis"/>
    <xsl:copy-of select="$subjectRegex"/> -->
        <subjectText>
            <xsl:value-of select="$subject"/>
        </subjectText>

        <xsl:variable name="conjunctionLocationSplit" select="
                tokenize($conjunctionLocation[boolean($conjunctionLocation)][1], ' and ')"/>
        <xsl:variable name="singleGuestDomain">
            <guest>
                <xsl:copy-of select="
                        $stringAnalysis[not(boolean($conjunctionLocation))]/*"/>
            </guest>
        </xsl:variable>
        <xsl:variable name="guest1Domain">
            <guest>
                <xsl:copy-of select="$conjunctionLocation/preceding-sibling::*"/>
                <xsl:copy-of select="$conjunctionLocationSplit[1]"/>
            </guest>
        </xsl:variable>
        <xsl:variable name="guest2Domain">
            <guest>
                <xsl:copy-of select="$conjunctionLocationSplit[2]"/>
                <xsl:copy-of select="$conjunctionLocation/following-sibling::*"/>
            </guest>
        </xsl:variable>
        <xsl:for-each select="
                $singleGuestDomain[matches(., '\w')],
                $guest1Domain[matches(., '\w')],
                $guest2Domain[matches(., '\w')]">

            <xsl:variable name="guestName">
                <xsl:call-template name="extractName">
                    <xsl:with-param name="text">
                        <xsl:value-of select="guest"/>
                    </xsl:with-param>
                    <xsl:with-param name="subjectRegex" select="$subjectRegex"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="nationality" select="guest/fn:match/fn:group[@nr = '8']"/>
            <xsl:variable name="profession" select="
                    guest/fn:match/fn:group[@nr = '3']"/>
            <xsl:variable name="role" select="guest/fn:match/fn:group[@nr = '5']"/>
            <xsl:variable name="workType" select="
                    (
                    guest/fn:match/fn:group[@nr = '7'],
                    guest/fn:match//fn:group[@nr = '12']
                    )[matches(., '\w')][1]"/>
            <xsl:variable name="knownWork" select="
                    (
                    guest/fn:match[fn:group[@nr = '1']][1],
                    $role/../following-sibling::fn:non-match
                    )[matches(., '\w')][1]"/>
            <xsl:variable name="currentWork" select="
                    (guest/fn:match[fn:group[@nr = '1']][last()],
                    
                    $knownWork)
                    [matches(., '\w')][last()]"/>
            <xsl:variable name="associations" select="
                    guest/fn:match/fn:group[@nr = '9']/fn:group[@nr = '14']"/>

            <guest>
                <guestDomain>
                    <xsl:value-of select="." separator=""/>
                </guestDomain>
                <guestName>
                    <xsl:attribute name="guestName" select="normalize-space($guestName)"/>
                    <xsl:apply-templates select="$guestName[matches(., '\w')]" mode="analyzeName"/>
                </guestName>
                <knownWork>
                    <xsl:value-of select="normalize-space($knownWork)"/>
                </knownWork>
                <currentWork>
                    <xsl:value-of select="normalize-space($currentWork)"/>
                </currentWork>
                <workType>
                    <xsl:value-of select="normalize-space($workType)"/>
                </workType>
                <profession>
                    <xsl:value-of select="$profession/normalize-space(.)"/>
                </profession>
                <nationality>
                    <xsl:value-of select="normalize-space($nationality)"/>
                </nationality>
                <role>
                    <xsl:value-of select="normalize-space($role)"/>
                </role>
            </guest>
        </xsl:for-each>

    </xsl:template>
    
    <xsl:template name="extractName">
        <xsl:param name="text"/>
        <xsl:param name="extractNameMessage">
            <xsl:message select="'Extract person names out of ', $text"/>
        </xsl:param>
        <xsl:param name="textBeforeComma" select="tokenize($text, ',')[1]"/>
        <xsl:param name="subjectRegex"/>
        <xsl:param name="guestName">
            <xsl:choose>
                <xsl:when test="matches($textBeforeComma, $allCapsGuestRegex)">
                    <xsl:value-of
                        select="analyze-string($textBeforeComma, $allCapsGuestRegex)/fn:match"
                        separator=""/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="
                            analyze-string($text, $subjectRegex, 'i')/fn:non-match"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        <xsl:copy-of select="$guestName"/>        
    </xsl:template>
    
    
    
    <xsl:template name="analyzeName" match="." mode="analyzeName">
        <xsl:param name="guestName">
            <xsl:value-of select="."/>
        </xsl:param>
        <xsl:param name="message">
            <xsl:message select="'Analyze name', $guestName"/>
        </xsl:param>
        <!-- Take an inserted work out (e.g. Steven ("Jaws") Spielberg) -->
        <xsl:param name="guestNameNoWork">
            <xsl:value-of select="tokenize($guestName, $enclosedTitleRegex)"/>
        </xsl:param>
        <xsl:param name="guestIsInCAPS" select="
            matches($guestName, '[A-Z\.\-’]{3,}')" tunnel="yes"/>
        <!-- Take out honorary titles, suffixes and dates -->
        <xsl:param name="surnameSuffixRegex">(,? Jr\.|,? Sr\.|,? Esq\.|,? Ph\. ?D\.)</xsl:param>
        <xsl:param name="namePrefixRegex">(Dr\. |Rev\. |Sir )</xsl:param>
        <xsl:param name="dateRangeRegex">(, [0-9]{4}\-([0-9]{4})?)</xsl:param>
        <xsl:param name="nonNameRegex">
            <xsl:value-of select="
                $surnameSuffixRegex, 
                $namePrefixRegex, 
                $dateRangeRegex" separator="|"/>
        </xsl:param>
        <xsl:param name="birthDeathDate" select="analyze-string($guestNameNoWork, $dateRangeRegex)/fn:match"/>
        <xsl:param name="justNames">
            <xsl:value-of select="
                analyze-string($guestNameNoWork, $nonNameRegex, 'i')/fn:non-match"/>
        </xsl:param> 
        <xsl:param name="lastNameFirst" select="contains($justNames, ', ')"/>
        <xsl:param name="token" select="', '[$lastNameFirst], ' '[not($lastNameFirst)]"/>
        <xsl:param name="eachNameRegex" select='
            "^[A-Z].+" [$guestIsInCAPS], 
            "^[A-Z][A-Za-z&apos;].+" [not($guestIsInCAPS)]'/>
        
        <xsl:param name="tokenizeName" select='
            analyze-string($justNames, $token)/
            fn:non-match
            [matches(., $eachNameRegex)]'/>
        
        <xsl:variable name="firstName" select="if ($lastNameFirst) 
            then 
            $tokenizeName[position() gt 1][last()]
            else
            $tokenizeName[1]
            "/>
        <xsl:variable name="middleNames" select="
            $tokenizeName
            [position() gt 1]
            [position() lt last()]
            "/>
        <xsl:variable name="lastName" select="if ($lastNameFirst) then 
            $tokenizeName[1]
            else
            $tokenizeName
            [position() gt 1]
            [last()]
            "/>
        <person>
            <xsl:attribute name="inputName" select="$guestName"/>
            <xsl:attribute name="lastNameFirst" select="$lastNameFirst"/>
            <xsl:attribute name="guestIsInCAPS" select="$guestIsInCAPS"/>
            
            <firstName>
                <xsl:value-of select="($firstName)"/>
            </firstName>
            <xsl:for-each select="$middleNames">
                <middleName>
                    <xsl:value-of select="normalize-space(.)"/>
                </middleName>
            </xsl:for-each>
            <lastName>
                <xsl:value-of select="($lastName)"/>
            </lastName>
            <birthDeathDate>
                <xsl:value-of select="normalize-space(replace($birthDeathDate, '[^0-9]', ' '))"/>
            </birthDeathDate>
        </person>
    </xsl:template>
    
    
    <xsl:template name="analyzePredicate" match="predicate" mode="analyzePredicate">
        <xsl:param name="predicate" select=".[matches(., '\w')]"/>
        <xsl:param name="analyzePredicateMessage">
            <xsl:message select="'Analyze predicate ', $predicate"/>
        </xsl:param>
        <xsl:param name="worksExtracted">
            <xsl:apply-templates select="
                    $predicate" mode="extractWorks"/>
        </xsl:param>
        <xsl:param name="work" select="
                $worksExtracted[last()]"/>
        <xsl:param name="workTitleTokenized" select="
                tokenize($work, ':')"/>
        <xsl:param name="nonTitleCharacters">[^\w '-]</xsl:param>
        <xsl:param name="workMainTitle">
            <xsl:value-of select="
                    replace(
                    $workTitleTokenized[1],
                    $nonTitleCharacters, '')"/>
        </xsl:param>
        <xsl:param name="workSubtitle">
            <xsl:value-of select="
                    replace(
                    $workTitleTokenized[position() gt 1],
                    $nonTitleCharacters, '')"/>
        </xsl:param>
        <xsl:param name="workType" select="
                analyze-string(
                $predicate, $workTypeRegex
                )/fn:match"/>

        <work>
            <xsl:attribute name="workType" select="
                    $workType"/>

            <workTitle>
                <xsl:value-of select="
                        normalize-space(
                        $workMainTitle)"/>
            </workTitle>
            <workSubtitle>
                <xsl:value-of select="
                        replace(
                        normalize-space(
                        $workSubtitle),
                        '\(|\)', ''
                        )"/>
            </workSubtitle>
        </work>
        <xsl:apply-templates select="
            $predicate" mode="extractTopic"/>
    </xsl:template>
    
    <xsl:template match="text()" mode="extractTopic">
        <xsl:param name="text" select=".[matches(., '\w')]"/>
        <xsl:param name="nonTopicWords">
            <xsl:value-of select="$verbRegex, $possessivePlus, $workQualifiers, $workTypeRegex, $enclosedTitleRegex" separator="|"/>            
        </xsl:param>        
        <xsl:param name="workDomainAnalyzed" select="analyze-string($text, $nonTopicWords)"/>
        <topic>            
            <xsl:value-of select="
                $workDomainAnalyzed/fn:non-match"/>
        </topic>
    </xsl:template>
    
    <xsl:template match="column" mode="generateAttributes">
        <xsl:attribute name="{replace(@name, ' ', '')}">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="text()" mode="extractWorks">
        <xsl:param name="text" select=".[matches(., '\w')]"/>
        <xsl:choose>
            <xsl:when test="matches($text, $enclosedTitleRegex)">
                <xsl:copy-of select="analyze-string($text, $enclosedTitleRegex)/fn:match"/>
            </xsl:when>
            <xsl:when test="matches($text, $workTypeRegex)">
                <xsl:copy-of select="tokenize($text, $workTypeRegex)[last()]"/>
            </xsl:when>
            <xsl:when test="matches($text, $capTitleRegex)">
                <xsl:copy-of select="analyze-string($text, $capTitleRegex)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="tokenize($text, ',')[position() gt 1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>