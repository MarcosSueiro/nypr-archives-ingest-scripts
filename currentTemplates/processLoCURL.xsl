<?xml version="1.0" encoding="UTF-8"?>
<!-- Various templates 
    dealing with the Library of Congress 
    subject and names APIs:
    
    1. Obtain data such as names, occupations and fields of activity
    2. Recursively find broader subjects
    3. Find only simple, narrowest subjects
    $. Search LoC authorities for names, subjects or both -->
    
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xsi:schemaLocation="http://www.pbcore.org/PBCore/PBCoreNamespace.html 
    http://pbcore.org/xsd/pbcore-2.0.xsd"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:et="http://ns.exiftool.ca/1.0/"
    et:toolkit="Image::ExifTool 9.46" xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:XMP-x="http://ns.exiftool.ca/XMP/XMP-x/1.0/"
    xmlns:XMP-xmp="http://ns.exiftool.ca/XMP/XMP-xmp/1.0/"
    xmlns:XMP-xmpDM="http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/"
    xmlns:XMP-xmpMM="http://ns.exiftool.ca/XMP/XMP-xmpMM/1.0/"
    xmlns:XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/"
    xmlns:XMP-WNYCSchema="http://ns.exiftool.ca/XMP/XMP-WNYCSchema/1.0/"
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/"
    xmlns:skos="http://www.w3.org/2009/08/skos-reference/skos.html"
    xmlns:mads="http://www.loc.gov/mads/v2" xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    xmlns:zs="http://docs.oasis-open.org/ns/search-ws/sruResponse" xmlns:WNYC="http://www.wnyc.org"
    xmlns:pma="http://www.phpmyadmin.net/some_doc_url/" xmlns:functx="http://www.functx.com"
    xmlns:skosCore="http://www.w3.org/2004/02/skos/core#"
    xmlns:ASCII="https://www.ecma-international.org/publications/standards/Ecma-094.htm"
    exclude-result-prefixes="#all">

    <xsl:import href="manageDuplicates.xsl"/>    

    <xsl:mode on-no-match="deep-skip"/>

    <!--Gives line breaks etc -->
    <xsl:output method="xml" version="1.0" indent="yes"/>

    <xsl:variable name="separatingToken" select="';'"/>
    <xsl:variable name="separatingTokenLong" select="concat(' ', $separatingToken, ' ')"/>
    <xsl:variable name="validatingKeywordString" select="'id.loc.gov/authorities/subjects/'"/>
    <xsl:variable name="validatingNameString" select="'id.loc.gov/authorities/names/'"/>
    <xsl:variable name="combinedValidatingStrings"
        select="
            string-join(($validatingKeywordString, $validatingNameString), '|')"/>

    <xsl:template name="getLOCData" match="
            .[contains(., 'id.loc.gov')]"
        mode="getLOCData">
        <!-- Get data from an LoC URL -->
        <xsl:param name="LOCURL" select="."/>
        <xsl:param name="LOCRDF"
            select="
                if (ends-with($LOCURL, '.rdf'))
                then
                    $LOCURL
                else
                    if (ends-with($LOCURL, '.html'))
                    then
                        concat(substring-before($LOCURL, '.html'), '.rdf')
                    else
                        concat($LOCURL, '.rdf')"/>
        <xsl:message select="concat('Get LOC Data for ', $LOCURL)"/>
        <xsl:copy-of select="doc($LOCRDF)"/>
    </xsl:template>

    <xsl:template name="LOCOccupationsAndFieldsOfActivity" match="
            RIFF:Artist"
        mode="LOCOccupationsAndFieldsOfActivity">
        <!-- Find LOC occupations
        and fields of activity
        for a URL -->
        <xsl:param name="artists"/>
        <xsl:param name="LOCURLs"
            select="
                WNYC:splitParseValidate(
                $artists,
                $separatingToken,
                $validatingNameString
                )"/>
        <xsl:param name="validatingNameString" select="$validatingNameString"/>
        <xsl:variable name="occupationsAndFieldsOfActivity">
            <xsl:for-each select="$LOCURLs/valid">
                <xsl:variable name="LOCRDF" select="concat(., '.rdf')"/>
                <xsl:variable name="LOCData" select="doc($LOCRDF)"/>
                <xsl:copy-of select="$artists"/>
                <!--Find occupations -->
                <occupations>
                    <xsl:value-of
                        select="
                            $LOCData
                            /rdf:RDF/madsrdf:*
                            /madsrdf:identifiesRWO
                            /madsrdf:RWO
                            /madsrdf:occupation/madsrdf:Occupation
                            /@rdf:about
                            [contains(., $validatingKeywordString)]"
                        separator="{$separatingTokenLong}"/>
                </occupations>
                <fieldsOfActivity>
                    <xsl:value-of
                        select="
                            $LOCData
                            /rdf:RDF/madsrdf:*
                            /madsrdf:identifiesRWO
                            /madsrdf:RWO
                            /madsrdf:fieldOfActivity
                            /skosCore:Concept
                            /@rdf:about
                            [contains(., $validatingKeywordString)]"
                        separator="{$separatingTokenLong}"/>
                </fieldsOfActivity>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="$occupationsAndFieldsOfActivity/(occupations | fieldsOfActivity)"
            separator="{$separatingTokenLong}"/>
    </xsl:template>

    <xsl:template name="locLabel" match="
            .[contains(., 'id.loc.gov/')]"
        mode="locLabel">
        <!-- Get LoC name from URL -->
        <xsl:param name="url" select="."/>
        <xsl:param name="locData">
            <xsl:apply-templates select="." mode="getLOCData"/>
        </xsl:param>
        <locName>
            <xsl:value-of
                select="
                    $locData/rdf:RDF
                    /madsrdf:*/madsrdf:authoritativeLabel"
            />
        </locName>
    </xsl:template>

    <xsl:template name="nameInNameTitle" match="
            madsrdf:NameTitle" mode="nameInNameTitle">
        <!-- Find the name in name/title LoC Entries -->
        <xsl:param name="input" select="."/>
        <xsl:message select="concat('Extract name in nameTitle ', @rdf:about)"/>
        <xsl:variable name="nameInNameTitle"
            select="
                madsrdf:componentList
                /(madsrdf:PersonalName | madsrdf:CorporateName)
                /madsrdf:authoritativeLabel"/>
        <xsl:message select="
            concat(
            'Find LoC entry for ', 
            $nameInNameTitle
            )"/>
        <xsl:variable name="nameLoCEntry">
            <xsl:call-template name="directLOCSearch">
                <xsl:with-param name="input" select="
                    $nameInNameTitle"/>
                <xsl:with-param name="mustFind" select="true()"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of
            select="
                $nameLoCEntry
                /results
                /name
                /rdf:RDF
                "
        />
    </xsl:template>

    <xsl:template match="RIFF:Keywords" mode="
        broaderSubjects" expand-text="yes">
        <!--Input: keywords separated by a token
        
        Send each keyword with an accepted URL
        to recursively climb up
        its LOC 'broader Subject', occupations, etc.
        
        (In progress) For each keyword *without* an accepted URL,
        search LOC's SRU API 
        (https://www.loc.gov/standards/sru/companionSpecs/srw.html)
        and proceed as above
    -->
        <xsl:param name="subjectsProcessed"/>
        <xsl:param name="subjectsToProcess" select="."/>
        <xsl:param name="separatingToken" select="$separatingToken"/>
        <xsl:param name="separatingTokenLong" select="concat(' ', $separatingToken, ' ')"/>
        <xsl:param name="validatingKeywordString" select="$validatingKeywordString"/>
        <xsl:param name="validatingNameString" select="$validatingNameString"/>
        <xsl:param name="combinedValidatingStrings" select="$combinedValidatingStrings"/>

        <xsl:variable name="subjectsToProcessParsed"
            select="
                WNYC:splitParseValidate(
                $subjectsToProcess,
                $separatingToken,
                $combinedValidatingStrings)"/>

        <xsl:variable name="subjectsToProcessValid"
            select="
                $subjectsToProcessParsed/valid"/>
        <xsl:message
            select="
                'Valid RIFF:Keywords to process: ',
                $subjectsToProcessValid
                "/>
        <xsl:variable name="subjectsToProcessInvalid"
            select="
                $subjectsToProcessParsed/invalid"/>

        <!-- Search LOC for non-LOC keywords -->
        <!--        <xsl:variable name="locSearchResults">
            <xsl:apply-templates select="
                    $subjectInProcessInvalid"
                mode="LOCSearch"/>
        </xsl:variable>-->

        <!--        <xsl:variable name="exactResultURL"
            select="
                $locSearchResults/pb:locSearchResults
                /pb:exactResult/pb:exactResultURL"/>

        <xsl:copy-of select="$exactResultURL"/>-->

        <xsl:variable name="allBroaderTopicsActivitiesOccupationsComponents">
            <allTopics>
                <xsl:apply-templates select="$subjectsToProcessValid" mode="broaderSubjects"/>
            </allTopics>
        </xsl:variable>
        <xsl:variable name="distinctAllTopics">
            <xsl:for-each-group
                select="
                    $allBroaderTopicsActivitiesOccupationsComponents
                    /allTopics/madsrdf:*"
                group-by="@rdf:about[matches(., $combinedValidatingStrings)]">
                <xsl:copy-of select="."/>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:copy-of select="$distinctAllTopics"/>
    </xsl:template>

    <xsl:template name="broaderSubjects" match="
        ." mode="broaderSubjects"
        xmlns:skos="http://www.w3.org/2004/02/skos/core#">
        <!-- 
            Take a keyword with an accepted URL 
        (e.g., it contains 'id.loc.gov')
        and recursively climb up its broader topics, component parts,
        'fields of activity' and occupations.
        This creates a virtual taxonomy in each record.
        
        Output unique results for each list in the format below 
        
        <madsrdf:* xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            rdf:about="http://id.loc.gov/authorities/childrensSubjects/sj96005799">
            <madsrdf:authoritativeLabel xml:lang="en">Journalism</madsrdf:authoritativeLabel>
            </madsrdf:Topic>
            -->
        <xsl:param name="LOCURL" select="."/>
        <xsl:param name="LOCRDF" select="concat($LOCURL, '.rdf')"/>
        <xsl:param name="LOCData" select="doc($LOCRDF)"/>
        <xsl:message select="
            'Find broader topics for', 
            string(
            $LOCData/rdf:RDF/
            madsrdf:*/
            madsrdf:authoritativeLabel)"/>
        <xsl:message
            select="
                count(
                $LOCData/rdf:RDF/madsrdf:*
                /madsrdf:hasBroaderAuthority
                /madsrdf:Topic
                ),
                'broader topic(s) found for',
                string($LOCData/rdf:RDF/madsrdf:*/madsrdf:authoritativeLabel)"/>

        <!-- We only accept simple names and subjects -->

        <xsl:copy select="
                $LOCData/rdf:RDF/madsrdf:*">
            <xsl:copy-of select="
                $LOCData/rdf:RDF
                /madsrdf:*/@rdf:about"/>
            <xsl:copy-of select="
                $LOCData/rdf:RDF
                /madsrdf:*/madsrdf:authoritativeLabel"/>
        </xsl:copy>

        <!--Recursively process broader topics -->
        <xsl:apply-templates
            select="
                $LOCData
                /rdf:RDF/madsrdf:*
                /madsrdf:hasBroaderAuthority
                /madsrdf:Topic
                /@rdf:about"
            mode="broaderSubjects"/>
        <!--Recursively process component topics -->
        <xsl:apply-templates
            select="
                $LOCData
                /rdf:RDF/madsrdf:ComplexSubject
                /madsrdf:componentList
                /madsrdf:*
                /@rdf:about
                [matches(., $combinedValidatingStrings)]"
            mode="broaderSubjects"/>
        <!--Recursively process fields of activity -->
        <xsl:apply-templates
            select="
                $LOCData
                /rdf:RDF/madsrdf:*
                /madsrdf:identifiesRWO
                /madsrdf:RWO
                /madsrdf:fieldOfActivity
                /skos:Concept/@rdf:about
                "
            mode="broaderSubjects"/>
        <!--Recursively process occupations -->
        <xsl:apply-templates
            select="
                $LOCData
                /rdf:RDF/madsrdf:*
                /madsrdf:identifiesRWO
                /madsrdf:RWO
                /madsrdf:occupation/madsrdf:Occupation/@rdf:about"
            mode="broaderSubjects"/>
        <!-- Recursively process name part of nameTitle -->
        <xsl:variable name="nameInNameTitle">
            <xsl:apply-templates
                select="
                    $LOCData/rdf:RDF
                    /madsrdf:NameTitle"
                mode="nameInNameTitle"/>
        </xsl:variable>
        <xsl:apply-templates
            select="
                $nameInNameTitle[. != '']
                /rdf:RDF/madsrdf:*
                /@rdf:about"
            mode="broaderSubjects"/>
    </xsl:template>

    <xsl:template name="narrowSubjects" match="
        ." mode="narrowSubjects" expand-text="yes">
        <!-- Accept a bunch of keywords; 
            parse out only the narrowest
            or most specific.
        
        This template is the opposite of "broaderSubjects"-->
        <xsl:param name="subjectsProcessed"/>
        <xsl:param name="subjectsToProcess" select="."/>
        <xsl:param name="separatingToken" select="
            $separatingToken"/>
        <xsl:param name="separatingTokenLong" select="
            concat(' ', $separatingToken, ' ')"/>
        <xsl:param name="validatingKeywordString" select="
            $validatingKeywordString"/>
        <xsl:param name="validatingNameString" select="
            $validatingNameString"/>
        <xsl:param name="combinedValidatingStrings" select="
            $combinedValidatingStrings"/>
        <xsl:message select="
            'Find narrowest subjects for: ', $subjectsToProcess, 
            ' matching validating strings ', $combinedValidatingStrings"/>
        <xsl:variable name="subjectsToProcessParsed"
            select="
            WNYC:splitParseValidate(
            $subjectsToProcess, 
            $separatingToken, 
            $combinedValidatingStrings
            )"/>
        <xsl:message select="
            'Subjects parsed:', 
            $subjectsToProcessParsed"/>
        <xsl:variable name="subjectsToProcessValid"
            select="
                $subjectsToProcessParsed/valid"/>
        <xsl:message select="
            'Valid subjects to process:', 
            string-join($subjectsToProcessValid, $separatingTokenLong)"/>
        <xsl:variable name="subjectsToProcessInvalid"
            select="
                $subjectsToProcessParsed/invalid"/>
        <xsl:message select="
            'Invalid subjects to process:', 
            $subjectsToProcessInvalid"/>
        <xsl:variable name="validComponents">
            <xsl:for-each select="$subjectsToProcessValid">                
                <xsl:variable name="LOCURL" select="."/>
                <xsl:variable name="LOCRDF" select="
                    concat($LOCURL, '.rdf')"/>
                <xsl:variable name="LOCData" select="
                    document($LOCRDF)"/>
                <xsl:variable name="LOCLabel" select="
                    $LOCData
                    /rdf:RDF
                    /madsrdf:*
                    /madsrdf:authoritativeLabel
                    [@xml:lang='en' or not(@xml:lang)]"/>
                <xsl:message select="
                    concat('Extract components or names from ', 
                    $LOCLabel)"/>
                <!-- Extract name from name/title entry -->
                
                <xsl:variable name="nameInNameTitle">
                    <xsl:apply-templates
                        select="
                            $LOCData/rdf:RDF
                            /madsrdf:NameTitle"
                        mode="nameInNameTitle"/>
                </xsl:variable>
                
                <xsl:variable name="nameInNameTitleURL" select="
                    $nameInNameTitle
                    /rdf:RDF/@rdf:about"/>
                <xsl:variable name="
                    nameInNameTitleLabel" select="
                    $nameInNameTitle
                    /rdf:RDF
                    /madsrdf:*
                    /madsrdf:authoritativeLabel"/>
                <xsl:message select="
                    count($nameInNameTitle/rdf:RDF),
                    'name in name title ', 
                    $LOCLabel, ': ',
                    $nameInNameTitleLabel"/>
                <!-- Extract component topics -->
                <xsl:variable name="componentTopics" 
                        select="
                            $LOCData/rdf:RDF
                            /madsrdf:*
                            /madsrdf:componentList
                            /madsrdf:*                            
                            [matches(@rdf:about, $combinedValidatingStrings)]"
                        />
                <xsl:message>
                    <xsl:value-of select="
                        count($componentTopics), 
                        'component topics in ', 
                        $LOCLabel, ': ' 
                        "/>
                    <xsl:value-of select="
                        $componentTopics/madsrdf:authoritativeLabel
                        [@xml:lang='en' or not(@xml:lang)]/normalize-space(.)" separator="
                        {$separatingTokenLong}"/>
                </xsl:message> 
                <xsl:variable name="allNamesComponentsURLs">
                    <xsl:value-of
                        select="                            
                            $nameInNameTitle[. != '']/rdf:RDF/madsrdf:*/@rdf:about | 
                            $componentTopics[. != '']/@rdf:about"
                        separator="{$separatingTokenLong}"/>
                </xsl:variable>
                <xsl:message
                    select="
                    'URLs from names in nameTitles and components in', 
                    $LOCLabel, ': ', 
                    $allNamesComponentsURLs"/>
                <xsl:copy-of
                    select="
                        WNYC:splitParseValidate(
                        $allNamesComponentsURLs, 
                        $separatingToken, 
                        $combinedValidatingStrings
                        )/valid"
                />
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:message>
            <xsl:value-of select="'All valid URLs from names in nameTitles and components from '"/>
            <xsl:value-of select="$subjectsToProcessValid" separator="{$separatingTokenLong}"/>
            <xsl:value-of select="': '"/>
            <xsl:copy-of select="$validComponents"/>
        </xsl:message>

        <!-- Output only topics 
                without a narrower 
                or more specific topic 
                already included -->
        <xsl:for-each select="
            $subjectsToProcessValid">
            <xsl:message select="
                'Check to see if ', ., 
                ' is the narrowest topic in this bunch.'"/>
            <xsl:variable name="LOCURL" select="."/>
            <xsl:variable name="LOCRDF" select="
                concat($LOCURL, '.rdf')"/>
            <xsl:variable name="LOCData" select="
                doc($LOCRDF)"/>
            <xsl:variable name="subjectName" select="string(
                $LOCData
                /rdf:RDF
                /madsrdf:*
                /madsrdf:authoritativeLabel
                )"/>
            <xsl:variable name="narrowerTopics" select="
                $LOCData/rdf:RDF/madsrdf:*
                /madsrdf:hasNarrowerAuthority"/>
            <xsl:message
                select="
                    count($narrowerTopics),
                    'narrower topic(s) found for',
                    $subjectName"/>
            <xsl:message select="
                'See if narrower topics ', 
                $narrowerTopics/madsrdf:Authority/@rdf:about, 
                ' are already in ', $subjectsToProcessValid
                "/>
            <xsl:message>
                <xsl:value-of select="
                    'See if current URL ', $LOCURL, 
                ' is in one of components ', $validComponents"/>
                <xsl:value-of select="$LOCURL = $validComponents/valid"/>
            </xsl:message>
            <xsl:copy
                select="
                    $LOCData/rdf:RDF
                    /madsrdf:*                    
                    [not(
                    madsrdf:hasNarrowerAuthority
                    /madsrdf:Authority
                    /@rdf:about
                    =
                    $subjectsToProcessValid
                    )]                    
                    [not($validComponents/valid =  $LOCURL)]
                    ">
                <xsl:copy-of select="@rdf:about"/>
                <xsl:copy-of select="madsrdf:authoritativeLabel"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="directLOCNameSearch" match="
        ." mode="directLOCNameSearch">
        <!-- Search for an exact name match in LOC
        for a string -->
        <xsl:param name="termToSearch" select="."/>
        <xsl:param name="termToSearchClean"
            select="
                WNYC:Capitalize($termToSearch,
                1)
                "/>
        <xsl:variable name="searchTermURL"
            select="
                encode-for-uri($termToSearchClean)"/>
        <xsl:variable name="nameSearchString"
            select="
                concat(
                'http://id.loc.gov/authorities/names/label/',
                $searchTermURL,
                '.rdf')"/>
        <xsl:message
            select="
                'Search LoC name authorities directly for the term ',
                $termToSearchClean, 
                'using search string', 
                $nameSearchString
                "/>
        <xsl:copy-of
            select="
                doc(
                $nameSearchString
                [unparsed-text-available(.)]
                )"
        />
    </xsl:template>

    <xsl:template name="directLOCSubjectSearch" match="
        ." mode="directLOCSubjectSearch">
        <!-- Search for an exact subject in LOC
        for a string -->
        <xsl:param name="termToSearch" select="."/>
        <xsl:param name="termToSearchClean"
            select="
                WNYC:Capitalize(
                WNYC:trimFinalPeriod($termToSearch),
                1)
                "/>
        <xsl:variable name="searchTermURL"
            select="
                encode-for-uri($termToSearchClean)"/>
        <xsl:variable name="subjectSearchString"
            select="
                concat(
                'http://id.loc.gov/authorities/subjects/label/',
                $searchTermURL,
                '.rdf')"/>
        <xsl:message
            select="
                'Search LoC subject headings directly for the term ',
                $termToSearchClean, 
                'using search string', 
                $subjectSearchString
                "/>
        <xsl:copy-of
            select="
                doc(
                $subjectSearchString
                [unparsed-text-available(.)]
                )"
        />
    </xsl:template>

    <xsl:template name="directLOCSearch" match="
        ." mode="directLOCSearch">
        <!-- Search for an exact match in LOC
            for a string
        -->
        <xsl:param name="input" select="."/>
        <xsl:param name="mustFind" as="
            xs:boolean" select="false()"/>
        <xsl:param name="termsToSearch"
            select="
                WNYC:splitParseValidate(
                $input,
                $separatingToken,
                $combinedValidatingStrings
                )
                /invalid"/>

        <xsl:message select="
            concat('Search LoC directly for the terms ', $input)"/>
        <results>
            <xsl:attribute name="termsToSearch">
                <xsl:value-of select="$termsToSearch" separator="
                    {$separatingTokenLong}"/>
            </xsl:attribute>
            <xsl:for-each select="$termsToSearch">
                <xsl:variable name="termToSearchClean"
                    select="
                        WNYC:Capitalize(
                        WNYC:trimFinalPeriod(.),
                        1)
                        "/>

                <subject>
                    <xsl:attribute name="searchTerm" select="."/>
                    <xsl:call-template name="directLOCSubjectSearch">
                        <xsl:with-param name="termToSearchClean" select="
                            $termToSearchClean"/>
                    </xsl:call-template>
                </subject>
                <name>
                    <xsl:attribute name="searchTerm" select="."/>
                    <xsl:call-template name="directLOCNameSearch">
                        <xsl:with-param name="termToSearchClean" select="
                            $termToSearchClean"/>
                    </xsl:call-template>
                </name>
            </xsl:for-each>
        </results>
    </xsl:template>

    <xsl:template name="wideLOCSubjectSearch"
        match="
            text()
            [not(matches(., $validatingKeywordString))]
            "
        mode="wideLOCSubjectSearch">
        <!-- Search for a term
            in LOC subject database
            using its sru API -->
        <xsl:param name="searchTerm" select="."/>
        <xsl:param name="searchTermURL"
            select="
                encode-for-uri(
                replace(
                replace(
                ASCII:ASCIIFier($searchTerm),
                '[(),]', ''),
                '[\.-]', ' ')
                )"/>
        <xsl:param name="mustFind" as="xs:boolean" select="false()"/>
        <xsl:param name="maximumRetrievals" select="5"/>
        <xsl:param name="basicURL" select="
            'http://lx2.loc.gov:210/'"/>
        <xsl:param name="database" select="
            'SAF?version=2.0'"/>
        <xsl:param name="operation" select="
            '&amp;operation=searchRetrieve'"/>
        <xsl:param name="fieldToSearch" select="
            '&amp;query=local.subjectTopical='"/>
        <xsl:param name="recordSchema" select="
            'mads'"/>

        <!-- Build search string -->
        <xsl:variable name="searchString"
            select="
            concat(
            $basicURL,
            $database,
            $operation,
            $fieldToSearch, 
            $searchTermURL, 
            '&amp;maximumRecords=', $maximumRetrievals,
            '&amp;recordSchema=', $recordSchema
            )"/>
        <xsl:message>
            <xsl:value-of
                select="
                    concat(
                    'Search for topic ', $searchTerm,
                    ' using search string ', $searchString
                    )"
                disable-output-escaping="true"/>
        </xsl:message>
        <xsl:message
            select="
                'Retrieve at most ', $maximumRetrievals,
                $recordSchema, ' subject records',
                ' from search string ', $searchString"/>
        <xsl:variable name="searchResult" select="document($searchString)"/>
        <xsl:variable name="searchResultTotals"
            select="
            $searchResult
            /zs:searchRetrieveResponse
            /zs:numberOfRecords"/>
        <xsl:message
            select="
                concat(
                $searchResultTotals, ' subject results found',
                ' using search string ', $searchString
                )"/>
        <xsl:choose>
            <xsl:when test="$searchResultTotals &lt; 1[$mustFind = true()]">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="'no_search_results'"/>
                    <xsl:attribute name="searchTerm" select="$searchTerm"/>
                    <xsl:value-of select="$searchResultTotals, 
                        ' results ',
                        ' for search term ', $searchTerm"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="exactResult"
                    select="
                        $searchResult/
                        zs:searchRetrieveResponse/
                        zs:records/zs:record/zs:recordData/
                        mads:mads
                        [count(mads:authority/mads:*) = 1]
                        [mads:authority/mads:topic[@authority = 'lcsh'] = $searchTermURL]
                        "/>
                <xsl:variable name="exactResultCount" select="
                    count($exactResult)"/>
                <xsl:message select="
                    $exactResultCount, 'exact subject results found'"/>
                <xsl:variable name="exactResultID"
                    select="
                        $exactResult
                        /mads:identifier[not(@invalid = 'yes')]
                        /translate(., ' ', '')"/>
                <xsl:variable name="exactResultURL"
                    select="
                        if ($exactResultID ne '')
                        then
                            concat(
                            'http://id.loc.gov/authorities/subjects/', 
                            $exactResultID
                            )
                        else
                            ''"/>
                <xsl:variable name="exactResultData" select="
                    document($exactResultURL[. ne ''])"/>

                <xsl:variable name="alternativeResults"
                    select="
                        $searchResult/
                        zs:searchRetrieveResponse/
                        zs:records/zs:record/zs:recordData/
                        mads:mads[mads:related[@type = 'other']/
                        mads:topic = $searchTermURL]"/>
                <locSearchResults>
                    <exactResult>
                        <xsl:attribute name="searchTerm" select="
                            $searchTerm"/>
                        <xsl:attribute name="numberOfResults" select="
                            $exactResultCount"/>
                        <exactResultURL>
                            <xsl:value-of select="
                                $exactResultURL"/>
                        </exactResultURL>
                        <exactResultData>
                            <xsl:copy-of select="
                                $exactResult"/>
                        </exactResultData>
                    </exactResult>
                    <alternativeResults>
                        <xsl:copy-of select="
                            $alternativeResults"/>
                    </alternativeResults>
                    <searchResultExpanded>
                        <xsl:copy-of select="
                            $searchResult"/>
                    </searchResultExpanded>
                </locSearchResults>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="wideLOCNameSearch"
        match="
            text()
            [not(matches(., $validatingNameString))]
            "
        mode="wideLOCNameSearch">
        <!-- Search for a term
            in LOC name database
            using its sru API -->
        <xsl:param name="searchTerm" select="."/>
        <xsl:param name="searchTermURL"
            select="
                encode-for-uri(
                replace(
                replace(
                ASCII:ASCIIFier($searchTerm),
                '[(),]', ''),
                '[\.-]', ' ')
                )"/>
        <xsl:param name="mustFind" as="xs:boolean" select="false()"/>
        <xsl:param name="maximumRetrievals" select="5"/>
        <xsl:param name="basicURL" select="
            'http://lx2.loc.gov:210/'"/>
        <xsl:param name="database" select="
            'NAF?version=2.0'"/>
        <xsl:param name="operation" select="
            '&amp;operation=searchRetrieve'"/>
        <xsl:param name="fieldToSearch" select="
            '&amp;query=bath.Name='"/>
        <xsl:param name="recordSchema" select="
            'mads'"/>

        <!-- Build search string -->
        <xsl:variable name="searchString"
            select="
            concat(
            $basicURL,
            $database,
            $operation,
            $fieldToSearch, 
            $searchTermURL, 
            '&amp;maximumRecords=', $maximumRetrievals,
            '&amp;recordSchema=', $recordSchema
            )"/>
        <xsl:message
            select="
                concat(
                'Search for name ', $searchTerm,
                ' using search string ', $searchString
                )"/>
        <xsl:message
            select="
                'Retrieve at most ', $maximumRetrievals,
                $recordSchema, ' subject records',
                ' from search string ', $searchString"/>
        <xsl:variable name="searchResult" select="
            document($searchString)"/>
        <xsl:variable name="searchResultTotals"
            select="
            $searchResult
            /zs:searchRetrieveResponse
            /zs:numberOfRecords"/>
        <xsl:message
            select="
                concat(
                $searchResultTotals, ' name results found',
                ' using search string ', $searchString
                )"/>
        <xsl:choose>
            <xsl:when test="
                $searchResultTotals &lt; 1[$mustFind = true()]">
                <xsl:element name="error">
                    <xsl:attribute name="type" select="
                        'no_search_results'"/>
                    <xsl:attribute name="searchTerm" select="
                        $searchTerm"/>
                    <xsl:value-of select="concat(
                        $searchResultTotals, 
                        ' results',
                        ' for search term ',
                        $searchTerm)"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="exactResult"
                    select="
                        $searchResult
                        /zs:searchRetrieveResponse
                        /zs:records/zs:record/zs:recordData
                        /mads:mads
                        [count(mads:authority/mads:*) = 1]
                        [mads:authority/mads:name[@authority = 'naf']
                        /fn:string-join(mads:namePart, ', ') = $searchTermURL]
                        "/>
                <xsl:variable name="exactResultCount" select="
                    count($exactResult)"/>
                <xsl:message select="
                    $exactResultCount, 'exact name results found'"/>
                <xsl:variable name="exactResultID"
                    select="
                        $exactResult
                        /mads:identifier[not(@invalid = 'yes')]
                        /translate(., ' ', '')"/>
                <xsl:variable name="exactResultURL"
                    select="
                        if ($exactResultID)
                        then
                            concat(
                            'http://id.loc.gov/authorities/names/', 
                            translate(
                            $exactResultID, ' ', ''
                            ), 
                            '.rdf'
                            )
                        else
                            ''"/>
                <xsl:variable name="exactResultName"
                    select="
                        $exactResult
                        /mads:authority
                        /mads:name[@authority = 'naf']
                        /fn:string-join(mads:namePart, ', ')"/>
                <xsl:variable name="exactResultData" select="
                    document($exactResultURL[. ne ''])"/>

                <xsl:variable name="allResults">
                    <xsl:copy-of
                        select="
                            $searchResult
                            /zs:searchRetrieveResponse/zs:records
                            /zs:record[zs:recordSchema = $recordSchema]
                            "
                        copy-namespaces="no"/>
                </xsl:variable>
                <locSearchResults>
                    <exactResult>
                        <xsl:attribute name="searchTerm" select="$searchTerm"/>
                        <xsl:attribute name="numberOfResults" select="
                            $exactResultCount"/>
                        <exactResultName>
                            <xsl:value-of select="$exactResultName"/>
                        </exactResultName>
                        <exactResultURL>
                            <xsl:value-of select="$exactResultURL"/>
                        </exactResultURL>
                        <exactResultData>
                            <xsl:copy-of select="$exactResult"/>
                        </exactResultData>
                    </exactResult>
                    <allResults>
                        <xsl:copy-of select="$allResults"/>
                    </allResults>
                    <searchResultExpanded>
                        <xsl:copy-of select="$searchResult"/>
                    </searchResultExpanded>
                </locSearchResults>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="LOCSearch"
        match="
            text()
            [not(matches(., $combinedValidatingStrings))]
            "
        mode="LOCSearch">
        <!-- Search LOC for strings
        using its sru API -->
        <xsl:param name="searchTerm" select="."/>
        <xsl:param name="searchTermCap" select="
            WNYC:Capitalize($searchTerm, 1)"/>
        <xsl:param name="searchSubjects" select="true()"/>
        <xsl:param name="mustFind" as="xs:boolean" select="false()"/>
        <xsl:param name="maximumRetrievals" select="200"/>
        <xsl:param name="basicURL" select="
            'http://lx2.loc.gov:210/'"/>
        <xsl:param name="database" select="
            'SAF?version=1.1'"/>
        <xsl:param name="operation" select="
            '&amp;operation=searchRetrieve'"/>
        <xsl:param name="fieldToSearch" select="
            '&amp;query=local.subjectTopical='"/>

        <xsl:param name="searchString"
            select="
                concat($basicURL,
                $database,
                $operation,
                $fieldToSearch,
                $searchTerm)"/>

        <xsl:variable name="subjectSearchResults">
            <xsl:apply-templates select="
                .[$searchSubjects]" mode="wideLOCSubjectSearch"/>
        </xsl:variable>
        <xsl:copy-of select="$subjectSearchResults"/>
    </xsl:template>

    <xsl:template name="LOCtoPBCore"
        match="
            madsrdf:Topic |
            madsrdf:NameTitle |
            madsrdf:Geographic |
            madsrdf:Name |
            madsrdf:FamilyName |
            madsrdf:CorporateName |
            madsrdf:Title |
            madsrdf:PersonalName |
            madsrdf:ConferenceName"
        mode="LOCtoPBCore" xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
        <!-- Convert an LOC entry
        to a pbcoreSubject -->
        <xsl:param name="LOCURL" select="@rdf:about"/>
        <xsl:param name="LOCRDF" select="concat($LOCURL, '.rdf')"/>

        <pbcoreSubject>
            <xsl:attribute name="source">
                <xsl:value-of select="'Library of Congress'"/>
            </xsl:attribute>
            <xsl:attribute name="ref">
                <xsl:value-of select="$LOCURL"/>
            </xsl:attribute>
            <xsl:value-of
                select="
                    madsrdf:authoritativeLabel
                    [@xml:lang = 'en' or not(@xml:lang)]"
            />
        </pbcoreSubject>
    </xsl:template>

    <!-- Fiind subjects from xml tables 
        exported via phpMyAdmin -->

    <xsl:template match="assetsSubjects">
        <!-- Accept xml from phpMyAdmin 
        and select subjects 
        without LOC URL entry -->
        <xsl:copy>
            <xsl:apply-templates
                select="
                    assetSubject
                    [chosenURL = 'paste URL here']"
            > </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="assetSubject[chosenURL = 'paste URL here']">
        <!-- Accept row 
        from xml output by phpMyAdmin
        and search LOC for possible matches to subject -->
        <xsl:copy>
            <subject>
                <xsl:value-of select="@subject"/>
            </subject>
            <xsl:copy-of
                select="
                    subject_id
                    | subject_authority
                    | subjectURL
                    | ref
                    | assetURL
                    | title
                    | description
                    "/>
            <xsl:variable name="directLOCSubjectSearchResult">
                <xsl:call-template name="directLOCSubjectSearch">
                    <xsl:with-param name="termToSearch"
                        select="
                        translate(
                        translate(
                        @subject, '/', ''), 
                        ':', ''
                        )
                        [. ne '']"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="directLOCNameSearchResult">
                <xsl:call-template name="directLOCNameSearch">
                    <xsl:with-param name="termToSearch"
                        select="
                        translate(
                        translate(
                        @subject, '/', ''
                        ), ':', ''
                        )
                        [. ne '']"/>
                </xsl:call-template>
            </xsl:variable>
            <exactSubject>
                <xsl:value-of
                    select="
                        if (
                        $directLOCSubjectSearchResult/rdf:RDF
                        /madsrdf:Topic/madsrdf:authoritativeLabel
                        )
                        then
                            $directLOCSubjectSearchResult/rdf:RDF
                            /madsrdf:Topic/madsrdf:authoritativeLabel
                        else
                            'NULL'"
                />
            </exactSubject>
            <exactSubjectURL>
                <xsl:value-of
                    select="
                        if (
                        $directLOCSubjectSearchResult/rdf:RDF
                        /madsrdf:Topic/@rdf:about
                        )
                        then
                            $directLOCSubjectSearchResult/rdf:RDF
                            /madsrdf:Topic/@rdf:about
                        else
                            'NULL'"
                />
            </exactSubjectURL>
            <exactName>
                <xsl:value-of
                    select="
                        if (
                        $directLOCNameSearchResult/rdf:RDF
                        /madsrdf:*/madsrdf:authoritativeLabel
                        )
                        then
                            $directLOCNameSearchResult/rdf:RDF
                            /madsrdf:*/madsrdf:authoritativeLabel
                        else
                            'NULL'"
                />
            </exactName>
            <exactNameURL>
                <xsl:value-of
                    select="
                        if (
                        $directLOCNameSearchResult/rdf:RDF
                        /madsrdf:*/@rdf:about
                        )
                        then
                            $directLOCNameSearchResult/rdf:RDF
                            /madsrdf:*/@rdf:about
                        else
                            'NULL'"
                />
            </exactNameURL>
            <chosenURL>paste URL here</chosenURL>
            <xsl:variable name="wideLOCSubjectSearchResults">
                <xsl:call-template name="wideLOCSubjectSearch">
                    <xsl:with-param name="searchTerm"
                        select="
                        translate(
                        translate(
                        @subject, '/', ''), 
                        ':', ''
                        )
                        [. ne '']"/>
                    <xsl:with-param name="maximumRetrievals" select="5"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each
                select="
                    $wideLOCSubjectSearchResults
                    /locSearchResults
                    /searchResultExpanded
                    /zs:searchRetrieveResponse
                    /zs:records/zs:record
                    [position() gt 0 and position() lt 6]">
                <xsl:variable name="validName"
                    select="
                        .[zs:recordSchema = 'mads']
                        /zs:recordData
                        /mads:mads
                        /mads:authority
                        /mads:topic[@authority = 'lcsh']"/>
                <xsl:variable name="validID"
                    select="
                        .[zs:recordSchema = 'mads']
                        /zs:recordData
                        /mads:mads
                        /mads:recordInfo
                        /mads:recordIdentifier[@source = 'DLC']"/>
                <xsl:element name="
                    {concat('wideLOCSubjectSearchResult_', position())}">
                    <xsl:value-of
                        select="
                            if ($validName) then
                                $validName
                            else
                                'NULL'
                            "
                    />
                </xsl:element>
                <xsl:element name="
                    {concat('wideLOCSubjectSearchURL_', position())}">
                    <xsl:value-of
                        select="
                            if ($validID) 
                            then
                                concat(
                                'http://id.loc.gov/authorities/subjects/', 
                                translate($validID, ' ', '')
                                )
                            else
                                'NULL'"
                    />
                </xsl:element>
            </xsl:for-each>
            <xsl:variable name="maximumNameRetrievals" select="5"/>
            <xsl:variable name="wideLOCNameSearchResults">
                <xsl:call-template name="wideLOCNameSearch">
                    <xsl:with-param name="searchTerm"
                        select="
                        translate(
                        translate(
                        @subject, '/', ''), 
                        ':', ''
                        )
                        [. ne '']"/>
                    <xsl:with-param name="maximumRetrievals" select="
                        $maximumNameRetrievals"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each
                select="
                    $wideLOCNameSearchResults
                    /locSearchResults/searchResultExpanded
                    /zs:searchRetrieveResponse
                    /zs:records
                    /zs:record[position() gt 0 and position() le $maximumNameRetrievals]
                    ">
                <xsl:variable name="validName"
                    select="
                        .[zs:recordSchema = 'mads']
                        /zs:recordData
                        /mads:mads
                        /mads:authority
                        /mads:name
                        /mads:namePart"/>
                <xsl:variable name="validID"
                    select="
                        .[zs:recordSchema = 'mads']
                        /zs:recordData
                        /mads:mads
                        /mads:recordInfo
                        /mads:recordIdentifier[@source = 'DLC']"/>
                <xsl:element name="{concat('wideLOCNameSearchResult_', position())}">
                    <xsl:value-of
                        select="
                            if ($validName)
                            then
                                $validName
                            else
                                'NULL'
                            "
                        separator="--"/>
                </xsl:element>
                <xsl:element name="{concat('wideLOCNameSearchURL_', position())}">
                    <xsl:value-of
                        select="
                            if ($validID
                            )
                            then
                                concat('http://id.loc.gov/authorities/names/',
                                translate($validID, ' ', '')
                                )
                            else
                                'NULL'"
                    />
                </xsl:element>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="pma_xml_export">
        <!-- Accept xml table from phpMyAdmin 
        and select subjects 
        without LOC URL entry -->
        <assetsSubjects>
            <xsl:apply-templates select="*:database[@name = 'pbcore']/table"/>
        </assetsSubjects>
    </xsl:template>

    <xsl:template match="table">
        <!-- Output each row 
            with additional columns 
            for possible LOC subject heading matches -->
        <xsl:element name="assetSubject">
            <xsl:attribute name="subject" select="column[@name = 'subject']"/>
            <xsl:for-each select="column">
                <xsl:element name="{@name}">
                    <xsl:value-of
                        select="
                            if (. != '') then
                                .
                            else
                                'NULL'"
                    />
                </xsl:element>
            </xsl:for-each>
            <xsl:variable name="directLOCSubjectSearchResult">
                <xsl:call-template name="directLOCSubjectSearch">
                    <xsl:with-param name="termToSearch" select="
                        column[@name = 'subject'][. ne '']"
                    />
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="directLOCNameSearchResult">
                <xsl:call-template name="directLOCNameSearch">
                    <xsl:with-param name="termToSearch" select="
                        column[@name = 'subject'][. ne '']"
                    />
                </xsl:call-template>
            </xsl:variable>
            <exactSubject>
                <xsl:value-of
                    select="
                        if (
                        $directLOCSubjectSearchResult/rdf:RDF
                        /madsrdf:Topic/madsrdf:authoritativeLabel
                        )
                        then
                            $directLOCSubjectSearchResult/rdf:RDF
                            /madsrdf:Topic/madsrdf:authoritativeLabel
                        else
                            'NULL'"
                />
            </exactSubject>
            <exactSubjectURL>
                <xsl:value-of
                    select="
                        if (
                        $directLOCSubjectSearchResult/rdf:RDF
                        /madsrdf:Topic/@rdf:about
                        )
                        then
                            $directLOCSubjectSearchResult/rdf:RDF
                            /madsrdf:Topic/@rdf:about
                        else
                            'NULL'"
                />
            </exactSubjectURL>
            <exactName>
                <xsl:value-of
                    select="
                        if (
                        $directLOCNameSearchResult/rdf:RDF
                        /madsrdf:*/madsrdf:authoritativeLabel
                        )
                        then
                            $directLOCNameSearchResult/rdf:RDF
                            /madsrdf:*/madsrdf:authoritativeLabel
                        else
                            'NULL'"
                />
            </exactName>
            <exactNameURL>
                <xsl:value-of
                    select="
                        if (
                        $directLOCNameSearchResult/rdf:RDF
                        /madsrdf:*/@rdf:about
                        )
                        then
                            $directLOCNameSearchResult/rdf:RDF
                            /madsrdf:*/@rdf:about
                        else
                            'NULL'"
                />
            </exactNameURL>
            <chosenURL>paste URL here</chosenURL>
            <xsl:variable name="wideLOCSubjectSearchResults">
                <xsl:call-template name="wideLOCSubjectSearch">
                    <xsl:with-param name="searchTerm" select="
                        column[@name = 'subject']"/>
                    <xsl:with-param name="maximumRetrievals" select="5"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each
                select="
                    $wideLOCSubjectSearchResults
                    /locSearchResults
                    /searchResultExpanded
                    /zs:searchRetrieveResponse
                    /zs:records/zs:record[position() gt 0 and position() lt 6]">
                <xsl:variable name="validName"
                    select="
                        .[zs:recordSchema = 'mads']
                        /zs:recordData
                        /mads:mads
                        /mads:authority
                        /mads:topic[@authority = 'lcsh']"/>
                <xsl:variable name="validID"
                    select="
                        .[zs:recordSchema = 'mads']
                        /zs:recordData
                        /mads:mads
                        /mads:recordInfo
                        /mads:recordIdentifier[@source = 'DLC']"/>
                <xsl:element name="{concat('wideLOCSubjectSearchResult_', position())}">
                    <xsl:value-of
                        select="
                            if ($validName) then
                                $validName
                            else
                                'NULL'
                            "
                    />
                </xsl:element>
                <xsl:element name="{concat('wideLOCSubjectSearchURL_', position())}">
                    <xsl:value-of
                        select="
                            if ($validID) 
                            then
                                concat(
                                'http://id.loc.gov/authorities/subjects/', 
                                translate($validID, ' ', '')
                                )
                            else
                                'NULL'"
                    />
                </xsl:element>
            </xsl:for-each>
            <xsl:variable name="maximumNameRetrievals" select="5"/>
            <xsl:variable name="wideLOCNameSearchResults">
                <xsl:call-template name="wideLOCNameSearch">
                    <xsl:with-param name="searchTerm" select="
                        column[@name = 'subject']"/>
                    <xsl:with-param name="maximumRetrievals" select="
                        $maximumNameRetrievals"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each
                select="
                    $wideLOCNameSearchResults
                    /locSearchResults/searchResultExpanded
                    /zs:searchRetrieveResponse
                    /zs:records
                    /zs:record
                    [position() gt 0 and position() le $maximumNameRetrievals]
                    ">
                <xsl:variable name="validName"
                    select="
                        .[zs:recordSchema = 'mads']
                        /zs:recordData
                        /mads:mads
                        /mads:authority
                        /mads:name
                        /mads:namePart"/>
                <xsl:variable name="validID"
                    select="
                        .[zs:recordSchema = 'mads']
                        /zs:recordData
                        /mads:mads
                        /mads:recordInfo
                        /mads:recordIdentifier[@source = 'DLC']"/>
                <xsl:element name="{concat('wideLOCNameSearchResult_', position())}">
                    <xsl:value-of
                        select="
                            if ($validName)
                            then
                                $validName
                            else
                                'NULL'
                            "
                        separator="--"/>
                </xsl:element>
                <xsl:element name="{concat('wideLOCNameSearchURL_', position())}">
                    <xsl:value-of
                        select="
                            if ($validID
                            )
                            then
                                concat('http://id.loc.gov/authorities/names/',
                                translate($validID, ' ', '')
                                )
                            else
                                'NULL'"
                    />
                </xsl:element>
            </xsl:for-each>
            <!--            <xsl:copy-of select="$wideLOCNameSearchResults"/>-->
        </xsl:element>
    </xsl:template>

    <!--<xsl:template name="wideLOCNameSearchOld"
        match="
        text()
        [not(matches(., $combinedValidatingStrings))]
        "
        mode="wideLOCNameSearch">
        <xsl:param name="searchTerm" select="."/>
        <xsl:param name="searchTermCap" select="WNYC:Capitalize($searchTerm, 1)"/>        
        <xsl:param name="mustFind" as="xs:boolean" select="false()"/>        
        <xsl:param name="maximumRetrievals" select="5"/>
        <xsl:param name="basicURL" select="'http://lx2.loc.gov:210/'"/>
        <xsl:param name="database" select="'NAF?version=1.1'"/>
        <xsl:param name="operation" select="'&amp;operation=searchRetrieve'"/>
        <xsl:param name="fieldToSearch" select="'&amp;query=bath.Name='"/>
        
        <xsl:param name="searchString"
            select="
            concat($basicURL,
            $database,
            $operation,
            $fieldToSearch, 
            $searchTerm)"/>
        <xsl:message>
            <xsl:value-of select="concat('Search for Name ', $searchTerm, 
            ' using search string ', $searchString)" disable-output-escaping="yes"/>
        </xsl:message>
        <xsl:variable name="searchResult" select="document($searchString)"/>
        <xsl:variable name="searchResultTotals"
            select="$searchResult/zs:searchRetrieveResponse/zs:numberOfRecords"/>
        <xsl:message select="concat(
            $searchResultTotals, ' results found', 
            ' using search string ', $searchString
            )"/>
        <xsl:choose>
            <xsl:when test="$searchResultTotals &lt; 1[$mustFind]">
                <xsl:element name="error">
                    <xsl:attribute 
                        name="searchTerm" 
                        select="$searchTerm"/>
                    <xsl:attribute name="type" select="$searchResultTotals, 'results found'"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$searchResultTotals &gt; 0">
                <xsl:variable name="searchStringExpanded"
                    select="
                    concat(
                    $searchString, 
                    '&amp;maximumRecords=5',
                    '&amp;recordSchema=mads'
                    )"/>
                <xsl:message select="'Retrieve mads record from search string', $searchStringExpanded"/>
                <xsl:variable name="searchResultExpanded" select="document($searchStringExpanded)"/>
                <xsl:variable name="exactResult"
                    select="
                    $searchResultExpanded/
                    zs:searchRetrieveResponse/
                    zs:records/zs:record/zs:recordData/
                    mads:mads
                    [count(mads:authority/mads:*) = 1]
                    [mads:authority/mads:name[@authority = 'naf']/fn:string-join(mads:NamePart, ', ') = $searchTermCap]
                    
                    "/>
                <xsl:variable name="exactResultCount" select="count($exactResult)"/>
                <xsl:message select="$exactResultCount, 'exact results found'"/>
                <xsl:choose>
                    <xsl:when test="$exactResultCount = 1">
                        <xsl:variable name="exactResultID"
                            select="                                
                            $exactResult/mads:identifier[not (@invalid='yes')]/translate(., ' ', '')"/>
                        <xsl:variable name="exactResultURL"
                            select="concat('http://id.loc.gov/authorities/names/', $exactResultID)"/>
                        <xsl:variable name="exactResultData" select="document($exactResultURL)"/>
                        <xsl:variable name="alternativeResults"
                            select="
                            $searchResultExpanded/
                            zs:searchRetrieveResponse/
                            zs:records/zs:record/zs:recordData/
                            mads:mads[mads:related[@type = 'other']/
                            mads:topic = $searchTermCap]"/>
                        <locSearchResults>
                            <exactResult>
                                <xsl:attribute 
                                    name="searchTerm" 
                                    select="$searchTerm"/>
                                <xsl:attribute 
                                    name="numberOfResults" 
                                    select="$exactResultCount"/>
                                <exactResultURL>
                                    <xsl:value-of select="$exactResultURL"/>
                                </exactResultURL>
                                <exactResultData>
                                    <xsl:copy-of select="$exactResult"/>
                                </exactResultData>
                            </exactResult>
                            <alternativeResults>
                                <xsl:copy-of select="$alternativeResults"/>
                            </alternativeResults>
                            <searchResultExpanded>
                                <xsl:copy-of select="$searchResultExpanded"/>
                            </searchResultExpanded>
                        </locSearchResults>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message select="$exactResultCount, ' exact matches!!'"/>
                        <xsl:copy-of select="$searchResultExpanded"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="error">
                    <xsl:attribute 
                        name="searchTerm" 
                        select="$searchTerm"/>
                    <xsl:attribute name="type" select="'tooManyResults'"/>
                    <xsl:value-of select="$searchResultTotals"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->
</xsl:stylesheet>
