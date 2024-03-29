<?xml version="1.0" encoding="UTF-8"?>

    
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xsi:schemaLocation="http://www.pbcore.org/PBCore/PBCoreNamespace.html 
    http://pbcore.org/xsd/pbcore-2.0.xsd"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:skos="http://www.w3.org/2009/08/skos-reference/skos.html"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:mads="http://www.loc.gov/mads/v2"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    xmlns:zs="http://docs.oasis-open.org/ns/search-ws/sruResponse" xmlns:WNYC="http://www.wnyc.org"
    xmlns:pma="http://www.phpmyadmin.net/some_doc_url/"
    xmlns:skosCore="http://www.w3.org/2004/02/skos/core#"
    xmlns:bf="http://id.loc.gov/ontologies/bibframe/"
    xmlns:ASCII="https://www.ecma-international.org/publications/standards/Ecma-094.htm"
    xmlns:ps="http://www.wikidata.org/prop/statement/"
    xmlns:psn="http://www.wikidata.org/prop/statement/value-normalized/"
    xmlns:wdt="http://www.wikidata.org/prop/direct/"
    xmlns:wdtn="http://www.wikidata.org/prop/direct-normalized/"
    xmlns:json="http://marklogic.com/xdmp/json/basic"
    xmlns:bflc="http://id.loc.gov/ontologies/bflc/"
    exclude-result-prefixes="#all">

    <!-- Various templates 
    dealing with the Library of Congress 
    subject and names APIs:
    
    1. Obtain data such as names, occupations and fields of activity
    2. Recursively find broader subjects
    3. Find only simple, narrowest subjects
    $. Search LoC authorities for names, subjects or both -->

    <xsl:import href="manageDuplicates.xsl"/>

    <xsl:mode on-no-match="deep-skip"/>
    <xsl:mode name="wikiToIPTC" on-no-match="deep-skip"/>

    <!--Gives line breaks etc -->
    <xsl:output method="xml" version="1.0" indent="yes"/>
    
   

    <xsl:variable name="separatingToken" select="';'"/>
    <xsl:variable name="separatingTokenLong" select="concat(' ', $separatingToken, ' ')"/>
    <xsl:variable name="validatingKeywordString" select="'id.loc.gov/authorities/subjects/'"/>
    <xsl:variable name="validatingNameString" select="'id.loc.gov/authorities/names/'"/>
    <xsl:variable name="validatingHubString" select="'id.loc.gov/resources/hubs/'"/>
    <xsl:variable name="combinedValidatingStrings"
        select="
            string-join(($validatingKeywordString, $validatingNameString, $validatingHubString), '|')"/>

    <xsl:variable name="wikidataValidatingString" select="'www.wikidata.org/'"/>
    <xsl:variable name="IPTCValidatingString" select="'mediatopic/'"/>
    <xsl:variable name="wikidataSeriesCode" select="'Q20937557'"/>
    
    <xsl:variable name="mediatopics"
        select="
        doc(
        'file:/T:/02%20CATALOGING/IPTCMediaTopics.rdf'
        )"
    />
    
    <xsl:template match="rdf:RDF[madsrdf:*]">
        <xsl:apply-templates/>
    </xsl:template>

    <!--<xsl:template match="rdf:Description">
        <xsl:apply-templates/>
    </xsl:template>-->

    <xsl:template match="RIFF:Keywords" name="getKeywordData">
        <xsl:param name="keywords" select="."/>
        <xsl:copy-of
            select="WNYC:splitParseValidate($keywords, $separatingToken, 'id.loc.gov')//valid/WNYC:getLOCData(.)"
        />
    </xsl:template>

    <xsl:template name="getArtistData" match="RIFF:Artist">
        <xsl:param name="artist" select="."/>
        <xsl:copy-of
            select="WNYC:splitParseValidate($artist, $separatingToken, 'id.loc.gov')//valid/WNYC:getLOCData(.)"
        />
    </xsl:template>

    <xsl:template name="generateLOCRDF" match="node()[matches(., 'id.loc.gov')]"
        mode="generateLOCRDF">
        <!-- Normalize LOCURLs with proper .rdf extension, etc. -->
        <xsl:param name="LOCURL" select="."/>
        <xsl:message
            select="
                concat(
                'Generate LoCRDF from ', $LOCURL
                )"/>
        <xsl:variable name="LOCRDF">
            <!-- Create a proper rdf 
                with all the proper elements -->
            <!-- Strip http protocol
            in case it is entered as https -->
            <xsl:variable name="nothttp">
                <xsl:value-of
                    select="
                        analyze-string($LOCURL, '^https*://')/fn:non-match"
                />
            </xsl:variable>
            <!-- Add plain ole http -->
            <xsl:value-of select="
                    'http://'"/>
            <!-- Strip extension -->
            <xsl:value-of
                select="
                    WNYC:substring-before-last-regex(
                    $nothttp, '\.\w{3,4}$'
                    )"/>
            <!-- Add .rdf extension -->
            <xsl:value-of select="'.rdf'"/>
        </xsl:variable>
        <xsl:message select="'LOCRDF:', $LOCRDF"/>
        <xsl:copy-of select="$LOCRDF"/>
    </xsl:template>

    <xsl:function name="WNYC:generateLOCRDF">
        <xsl:param name="LOCURL"/>
        <xsl:call-template name="generateLOCRDF">
            <xsl:with-param name="LOCURL" select="$LOCURL"/>
        </xsl:call-template>
    </xsl:function>

    <xsl:template name="getLOCData" match="
            node()[matches(., 'id.loc.gov')]"
        mode="getLOCData">
        <!-- Get data from an LoC URL -->
        <xsl:param name="LOCURL" select="."/>
        <xsl:message select="concat('Get LOC Data for ', $LOCURL)"/>
        <xsl:variable name="LOCRDF" select="WNYC:generateLOCRDF($LOCURL)"/>
        <xsl:variable name="LOCRDFAvailable" select="fn:doc-available($LOCRDF)"/>

        <xsl:if test="not($LOCRDFAvailable)">
            <rdf:RDF>
                <error type="LOCSH Not found">
                    <xsl:value-of select="$LOCURL, 'cannot be found online'"/>
                </error>
            </rdf:RDF>
        </xsl:if>
        <xsl:copy-of select="doc($LOCRDF)[$LOCRDFAvailable]"/>
    </xsl:template>

    <xsl:function name="WNYC:getLOCData">
        <xsl:param name="LOCURL"/>
        <xsl:call-template name="getLOCData">
            <xsl:with-param name="LOCURL" select="$LOCURL"/>
        </xsl:call-template>
    </xsl:function>

    <xsl:template name="LOCOccupationsAndFieldsOfActivity" match="
            RIFF:Artist"
        mode="LOCOccupationsAndFieldsOfActivity">
        <!-- Find LOC occupations
        and fields of activity
        for a URL -->
        <xsl:param name="artists" select="."/>
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
                <xsl:variable name="LOCData" select="WNYC:getLOCData(.)"/>
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
            .[contains(., 'id.loc.gov/')]" mode="locLabel">
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
            madsrdf:NameTitle"
        mode="nameInNameTitle">
        <!-- Find the name in name/title LoC Entries -->
        <xsl:param name="input" select="."/>
        <xsl:message select="
                concat('Extract name in nameTitle ', @rdf:about)"/>
        <xsl:variable name="nameInNameTitle"
            select="
                madsrdf:componentList
                /(madsrdf:PersonalName | madsrdf:CorporateName)
                /madsrdf:authoritativeLabel"/>
        <xsl:message
            select="
                concat(
                'Find LoC entry for ',
                $nameInNameTitle
                )"/>
        <xsl:variable name="nameLoCEntry">
            <xsl:call-template name="directLOCNameSearch">
                <xsl:with-param name="termToSearch"
                    select="
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

    <xsl:template name="placeInSubjectPlace"
        match="
            madsrdf:ComplexSubject
            [madsrdf:componentList/madsrdf:Geographic]"
        mode="placeInSubjectPlace">
        <!-- Find the place in subject-place complex LoC Entries -->
        <xsl:param name="input" select="."/>
        <xsl:message
            select="
                concat(
                'Extract place in subject-place complex subject ',
                $input/madsrdf:authoritativeLabel[@xml:lang = 'en'])"/>
        <xsl:for-each
            select="
                $input//
                madsrdf:componentList/
                madsrdf:Geographic">
            <xsl:variable name="placeInSubjectPlace"
                select="
                    madsrdf:authoritativeLabel"/>
            <xsl:message
                select="
                    concat
                    (
                    'Find LoC entry for place named ',
                    $placeInSubjectPlace
                    )"/>
            <xsl:variable name="placeLoCEntry">
                <xsl:call-template name="directLOCNameSearch">
                    <xsl:with-param name="termToSearch"
                        select="
                            $placeInSubjectPlace"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:copy-of
                select="
                    $placeLoCEntry/
                    rdf:RDF
                    "/>
            <xsl:message
                select="
                    concat(
                    'Found rdf ',
                    $placeLoCEntry/rdf:RDF/madsrdf:Geographic/@rdf:about,
                    ' for place ', $placeInSubjectPlace)"
            />
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="processSubjects" match="RIFF:Keywords" mode="
        processSubjects"
        expand-text="yes">
        <!-- Input: keywords separated by a token.        
        Output: original keyword + 
        simple keywords with an accepted URL
        and LOC occupations, etc.
        
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

        <xsl:param name="subjectsToProcessParsed"
            select="
                WNYC:splitParseValidate(
                $subjectsToProcess,
                $separatingToken,
                $combinedValidatingStrings)"/>

        <xsl:param name="subjectsToProcessValid"
            select="
                $subjectsToProcessParsed/valid"/>
        <xsl:param name="subjectsProcessedParsed"
            select="
                WNYC:splitParseValidate(
                $subjectsProcessed,
                $separatingToken,
                $combinedValidatingStrings)"/>

        <xsl:param name="subjectsProcessedValid"
            select="
                $subjectsProcessedParsed/valid"/>
        <xsl:message>
            <xsl:value-of select="$subjectsToProcessValid" separator="{$separatingTokenLong}"/>
        </xsl:message>
        <xsl:variable name="subjectsToProcessInvalid"
            select="
                $subjectsToProcessParsed/invalid"/>
        <xsl:variable name="
            allTopicsActivitiesOccupationsComponents">
            <allTopics>
                <xsl:apply-templates
                    select="
                        $subjectsToProcessValid[not(. = $subjectsProcessedValid)]"
                    mode="processSubject"/>
            </allTopics>
        </xsl:variable>
        <xsl:message>
            <xsl:value-of select="'All valid topics: '"/>
            <xsl:value-of
                select="
                    $allTopicsActivitiesOccupationsComponents/
                    allTopics/madsrdf:*"
                separator="{$separatingTokenLong}"/>
        </xsl:message>
        <xsl:variable name="distinctAllTopics">
            <xsl:for-each-group
                select="
                    $allTopicsActivitiesOccupationsComponents
                    /allTopics/madsrdf:*"
                group-by="@rdf:about[matches(., $combinedValidatingStrings)]">
                <xsl:copy-of select="."/>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:copy-of select="$distinctAllTopics"/>
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

        <xsl:variable name="
            allBroaderTopicsActivitiesOccupationsComponents">
            <allTopics>
                <xsl:apply-templates select="
                        $subjectsToProcessValid"
                    mode="broaderSubjects"/>
            </allTopics>
        </xsl:variable>
        <xsl:message>
            <xsl:value-of select="'All broader topics: '"/>
            <xsl:value-of
                select="
                    $allBroaderTopicsActivitiesOccupationsComponents/
                    allTopics/madsrdf:*"
                separator="{$separatingTokenLong}"/>
        </xsl:message>
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

    <xsl:template name="processSubject" match="
            ." mode="processSubject"
        xmlns:skos="http://www.w3.org/2004/02/skos/core#">
        <!-- 
            Take ONE keyword with an accepted URL 
        (e.g., it contains 'id.loc.gov')
        and break into component parts,
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
        <xsl:param name="LOCData" select="WNYC:getLOCData($LOCURL)"/>
        <xsl:param name="LOCURI"
            select="
                $LOCData/rdf:RDF
                /madsrdf:*/@rdf:about"/>
        <xsl:param name="LOCLabel"
            select="
                $LOCData/rdf:RDF/
                madsrdf:*/
                madsrdf:authoritativeLabel[@xml:lang = 'en' or not(@xml:lang)]"/>

        <xsl:message
            select="
                concat(
                'Validate topic ',
                $LOCLabel)"/>

        <!-- Copy the original -->
        <xsl:copy select="
                $LOCData/rdf:RDF/madsrdf:*">
            <xsl:copy-of select="$LOCURI"/>
            <xsl:copy-of select="$LOCLabel"/>
        </xsl:copy>

        <!-- Process component topics 
        with a valid URI -->
        <xsl:apply-templates
            select="
                $LOCData
                /rdf:RDF/madsrdf:ComplexSubject
                /madsrdf:componentList
                /madsrdf:*
                /@rdf:about
                [matches(., $combinedValidatingStrings)]"
            mode="processSubject"/>
        <!-- Process fields of activity -->
        <xsl:apply-templates
            select="
                $LOCData
                /rdf:RDF/madsrdf:*
                /madsrdf:identifiesRWO
                /madsrdf:RWO
                /madsrdf:fieldOfActivity
                /skos:Concept/@rdf:about
                "
            mode="processSubject"/>
        <!-- Process occupations -->
        <xsl:apply-templates
            select="
                $LOCData
                /rdf:RDF/madsrdf:*
                /madsrdf:identifiesRWO
                /madsrdf:RWO
                /madsrdf:occupation/madsrdf:Occupation/@rdf:about"
            mode="processSubject"/>
        <!-- Process name part of nameTitle -->
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
            mode="processSubject"/>
        <!-- Process geographic part 
            of subject-place complex subject -->
        <xsl:variable name="placeInSubjectPlace">
            <xsl:apply-templates
                select="
                    $LOCData/rdf:RDF/
                    madsrdf:ComplexSubject
                    [madsrdf:componentList/madsrdf:Geographic]"
                mode="placeInSubjectPlace"/>
        </xsl:variable>

        <xsl:copy-of select="
                $placeInSubjectPlace"/>


        <xsl:apply-templates
            select="
                $placeInSubjectPlace/
                rdf:RDF/madsrdf:Geographic/
                @rdf:about"
            mode="processSubject"/>
    </xsl:template>

    <xsl:template name="broaderSubjects" match="
            ." mode="broaderSubjects"
        xmlns:skos="http://www.w3.org/2004/02/skos/core#">
        <!-- 
            Take ONE keyword with an accepted URL 
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
        <xsl:param name="LOCData" select="WNYC:getLOCData($LOCURL)"/>
        <xsl:param name="LOCURI"
            select="
                $LOCData/rdf:RDF
                /madsrdf:*/@rdf:about"/>
        <xsl:param name="LOCLabel"
            select="
                $LOCData/rdf:RDF/
                madsrdf:*/
                madsrdf:authoritativeLabel[@xml:lang = 'en' or not(@xml:lang)]"/>
        <xsl:param name="broaderTopics"
            select="
                $LOCData
                /rdf:RDF/madsrdf:*
                /madsrdf:hasBroaderAuthority
                /madsrdf:Topic"/>
        <xsl:message
            select="
                concat(
                'Find broader topics for ',
                $LOCLabel)"/>
        <xsl:message
            select="
                concat(
                count($broaderTopics
                ),
                ' broader topic(s) found for ',
                $LOCLabel)"/>

        <!-- Copy the original -->
        <xsl:copy select="
                $LOCData/rdf:RDF/madsrdf:*">
            <xsl:copy-of select="$LOCURI"/>
            <xsl:copy-of select="$LOCLabel"/>
        </xsl:copy>

        <!-- Recursively process broader topics -->
        <xsl:apply-templates select="
                $broaderTopics
                /@rdf:about"
            mode="broaderSubjects"/>
        <!-- Recursively process component topics 
        with a valid URI -->
        <xsl:apply-templates
            select="
                $LOCData
                /rdf:RDF/madsrdf:ComplexSubject
                /madsrdf:componentList
                /madsrdf:*
                /@rdf:about
                [matches(., $combinedValidatingStrings)]"
            mode="broaderSubjects"/>
        <!-- Recursively process fields of activity -->
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
        <!-- Recursively process occupations -->
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
        <!-- Recursively process geographic part 
            of subject-place complex subject -->
        <xsl:variable name="placeInSubjectPlace">
            <xsl:apply-templates
                select="
                    $LOCData/rdf:RDF/
                    madsrdf:ComplexSubject
                    [madsrdf:componentList/madsrdf:Geographic]"
                mode="placeInSubjectPlace"/>
        </xsl:variable>
        <xsl:message
            select="
                count($LOCData/rdf:RDF/
                madsrdf:ComplexSubject/
                madsrdf:componentList/madsrdf:Geographic), ' geographic place(s) in ', $LOCLabel">
            <xsl:copy-of select="$placeInSubjectPlace"/>
        </xsl:message>

        <xsl:apply-templates
            select="
                $placeInSubjectPlace/rdf:RDF/madsrdf:Geographic/
                @rdf:about"
            mode="broaderSubjects"/>
    </xsl:template>

    <xsl:template name="narrowSubjects" match="
        ." mode="narrowSubjects"
        expand-text="yes">
        <!-- Accept a bunch of LoC URLs; 
            parse out only the narrowest
            or most specific.        
        This template is the opposite of "broaderSubjects" -->
        <xsl:param name="subjectsProcessed"/>
        <xsl:param name="subjectsToProcess" select="."/>
        <xsl:param name="separatingToken" select="
                $separatingToken"/>
        <xsl:param name="separatingTokenLong"
            select="
                concat(' ', $separatingToken, ' ')"/>
        <xsl:param name="validatingKeywordString" select="
                $validatingKeywordString"/>
        <xsl:param name="validatingNameString" select="
                $validatingNameString"/>
        <xsl:param name="combinedValidatingStrings"
            select="
                $combinedValidatingStrings"/>
        <xsl:message>
            <xsl:value-of select="'Find narrowest subjects for: '"/>
            <xsl:value-of select="$subjectsToProcess"
                separator="
                {$separatingTokenLong}"/>
            <xsl:value-of
                select="
                    ' with matching validating strings ',
                    $combinedValidatingStrings"
            />
        </xsl:message>

        <xsl:variable name="subjectsToProcessParsed"
            select="
                WNYC:splitParseValidate(
                replace($subjectsToProcess, 'https:', 'http:'),
                $separatingToken,
                $combinedValidatingStrings
                )"/>
        <xsl:message>
            <xsl:value-of select="'Subjects parsed: '"/>
            <xsl:value-of select="$subjectsToProcessParsed" separator="{$separatingTokenLong}"/>
        </xsl:message>
        <xsl:variable name="subjectsToProcessValid"
            select="
            $subjectsToProcessParsed/valid[not(contains($subjectsProcessed, .))]"/>
        <xsl:message
            select="
                'Valid subjects to process:',
                string-join($subjectsToProcessValid, $separatingTokenLong)"/>
        <xsl:variable name="subjectsToProcessInvalid"
            select="
                $subjectsToProcessParsed/invalid"/>
        <xsl:message
            select="
                'Invalid subjects to process:',
                $subjectsToProcessInvalid"/>
        <xsl:variable name="validComponents">
            <xsl:for-each select="$subjectsToProcessValid">
                <xsl:variable name="LOCURL" select="."/>
                <xsl:variable name="LOCData" select="WNYC:getLOCData($LOCURL)"/>
                <xsl:variable name="LOCLabel"
                    select="
                        $LOCData
                        /rdf:RDF
                        /madsrdf:*
                        /madsrdf:authoritativeLabel
                        [@xml:lang = 'en' or not(@xml:lang)]"/>
                <xsl:message
                    select="
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
                <xsl:variable name="nameInNameTitleURL"
                    select="
                        $nameInNameTitle
                        /rdf:RDF/@rdf:about"/>
                <xsl:variable name="
                    nameInNameTitleLabel"
                    select="
                        $nameInNameTitle
                        /rdf:RDF
                        /madsrdf:*
                        /madsrdf:authoritativeLabel"/>
                <xsl:message
                    select="
                        count($nameInNameTitle/rdf:RDF),
                        'name in name title ',
                        $LOCLabel, ': ',
                        $nameInNameTitleLabel"/>

                <!-- Extract place from subject/place complex entry -->
                <xsl:variable name="placeInSubjectPlace">
                    <xsl:apply-templates
                        select="
                            $LOCData/rdf:RDF
                            /madsrdf:ComplexSubject
                            [madsrdf:componentList/madsrdf:Geographic]"
                        mode="placeInSubjectPlace"/>
                </xsl:variable>

                <xsl:variable name="placeInSubjectPlaceURL"
                    select="
                        $placeInSubjectPlace[. != '']
                        /rdf:RDF/@rdf:about"/>
                <xsl:variable name="
                    placeInSubjectPlaceLabel"
                    select="
                        $placeInSubjectPlace
                        /rdf:RDF
                        /madsrdf:*
                        /madsrdf:authoritativeLabel"/>
                <xsl:message>
                    <xsl:value-of
                        select="
                            count(
                            $placeInSubjectPlace/rdf:RDF),
                            ' place(s) in subject place topic ',
                            $LOCLabel, ': '"/>
                    <xsl:value-of select="$placeInSubjectPlaceLabel"
                        separator="{$separatingTokenLong}"/>
                </xsl:message>
                <!-- Extract other component topics' rdfs -->
                <xsl:variable name="componentTopics"
                    select="
                        $LOCData/rdf:RDF
                        /madsrdf:*
                        /madsrdf:componentList
                        /madsrdf:*
                        [matches(@rdf:about, $combinedValidatingStrings)]"/>
                <xsl:message>
                    <xsl:value-of
                        select="
                            count($componentTopics),
                            'component topics in ',
                            $LOCLabel, ': '
                            "/>
                    <xsl:value-of
                        select="
                            $componentTopics/madsrdf:authoritativeLabel
                            [@xml:lang = 'en' or not(@xml:lang)]/normalize-space(.)"
                        separator="
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
            <xsl:value-of
                select="
                    'All valid URLs from ',
                    'names in nameTitles, ',
                    'places in complex subjects, ',
                    'and other components from '"/>
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
            <xsl:message
                select="
                    'Check to see if ', .,
                    ' is the narrowest topic in this bunch.'"/>
            <xsl:variable name="LOCURL" select="."/>
            <xsl:variable name="LOCRDF" select="WNYC:generateLOCRDF($LOCURL)"/>
            <xsl:variable name="LOCData" select="WNYC:getLOCData($LOCURL)"/>
            <xsl:variable name="subjectName"
                select="
                    string(
                    $LOCData
                    /rdf:RDF
                    /madsrdf:*
                    /madsrdf:authoritativeLabel
                    )"/>
            <xsl:variable name="narrowerTopics"
                select="
                    $LOCData/rdf:RDF/madsrdf:*
                    /madsrdf:hasNarrowerAuthority"/>
            <xsl:message
                select="
                    count($narrowerTopics),
                    'narrower topic(s) found for',
                    $subjectName"/>
            <xsl:message>
                <xsl:value-of select="'See if narrower topics '"/>
                <xsl:value-of select="$narrowerTopics/madsrdf:Authority/@rdf:about" separator=" ; "/>
                <xsl:value-of select="' are already in '"/>
                <xsl:value-of select="$subjectsToProcessValid" separator=" ; "/>
            </xsl:message>
            <xsl:message>
                <xsl:value-of
                    select="
                        'See if current URL ', $LOCURL,
                        ' is in one of components '"/>
                <xsl:value-of select="$validComponents" separator="{$separatingTokenLong}"/>
                <xsl:value-of select="$LOCURL = $validComponents/valid" separator="{$separatingTokenLong}"/>
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
                    [not($validComponents/valid = $LOCURL)]
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
        <xsl:param name="mustFind" select="false()"/>
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
                ' using search string ',
                $nameSearchString
                "/>
        <xsl:choose>
            <xsl:when test="$termToSearch = 'Russia (Federation)'">
                <!-- For some reason Russia trips up the script often -->
                <xsl:copy-of select="doc('russia_sh2008116754.rdf')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of
                    select="
                        doc(
                        $nameSearchString
                        [unparsed-text-available(.)]
                        )"
                />
            </xsl:otherwise>
        </xsl:choose>


    </xsl:template>

    <xsl:template name="directLOCSubjectSearch" match="
            ." mode="directLOCSubjectSearch">
        <!-- Search for an exact subject in LOC
        for a string -->
        <xsl:param name="termToSearch" select="."/>
        <xsl:param name="endsWithPeriod" select="ends-with($termToSearch, '.')"/>
        <xsl:param name="noFinalPeriod"
            select="
                if ($endsWithPeriod)
                then
                    WNYC:trimFinalPeriod($termToSearch)
                else
                    $termToSearch"/>
        <xsl:param name="termToSearchClean"
            select="
                WNYC:Capitalize(
                $noFinalPeriod,
                1)
                "/>
        <xsl:param name="searchTermURL" select="
                encode-for-uri($termToSearchClean)"/>
        <xsl:param name="subjectSearchString"
            select="
                concat(
                'http://id.loc.gov/authorities/subjects/label/',
                $searchTermURL,
                '.rdf')"/>
        <xsl:param name="passThrough" select="false()"/>
        <xsl:message
            select="
                'Search LoC subject headings directly for the term ',
                $termToSearchClean,
                ' using search string ',
                $subjectSearchString
                "/>
        <xsl:variable name="successfulSearch" select="
            unparsed-text-available($subjectSearchString)"/>
        <xsl:choose>
            <xsl:when test="$successfulSearch">
                <xsl:copy-of
                    select="
                        doc(
                        $subjectSearchString
                        [$successfulSearch]
                        )"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$passThrough">
                    <rdf:RDF>
                        <madsrdf:Topic>
                            <xsl:attribute name="rdf:about" select="$termToSearch"/>
                        </madsrdf:Topic>
                    </rdf:RDF>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
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
                <xsl:value-of select="$termsToSearch"
                    separator="
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
                        <xsl:with-param name="termToSearchClean"
                            select="
                                $termToSearchClean"/>
                    </xsl:call-template>
                </subject>
                <name>
                    <xsl:attribute name="searchTerm" select="."/>
                    <xsl:call-template name="directLOCNameSearch">
                        <xsl:with-param name="termToSearchClean"
                            select="
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
                    <xsl:value-of
                        select="
                            $searchResultTotals,
                            ' results ',
                            ' for search term ', $searchTerm"
                    />
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
                <xsl:variable name="exactResultCount"
                    select="
                        count($exactResult)"/>
                <xsl:message
                    select="
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
                <xsl:variable name="exactResultData"
                    select="
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
                        <xsl:attribute name="searchTerm"
                            select="
                                $searchTerm"/>
                        <xsl:attribute name="numberOfResults"
                            select="
                                $exactResultCount"/>
                        <exactResultURL>
                            <xsl:value-of
                                select="
                                    $exactResultURL"/>
                        </exactResultURL>
                        <exactResultData>
                            <xsl:copy-of select="
                                    $exactResult"
                            />
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
                    <xsl:attribute name="type"
                        select="
                            'no_search_results'"/>
                    <xsl:attribute name="searchTerm"
                        select="
                            $searchTerm"/>
                    <xsl:value-of
                        select="
                            concat(
                            $searchResultTotals,
                            ' results',
                            ' for search term ',
                            $searchTerm)"
                    />
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
                <xsl:variable name="exactResultCount"
                    select="
                        count($exactResult)"/>
                <xsl:message
                    select="
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
                <xsl:variable name="exactResultData"
                    select="
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
                        <xsl:attribute name="numberOfResults"
                            select="
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
                    .[$searchSubjects]"
                mode="wideLOCSubjectSearch"/>
        </xsl:variable>
        <xsl:copy-of select="$subjectSearchResults"/>
    </xsl:template>

    <xsl:template name="LOCNameSuggestSearch" match="pb:contributor | pb:creator"
        mode="LOCNameSuggestSearch">
        <!-- Find LoC URL from a name -->
        <!-- More info at https://id.loc.gov/techcenter/searching.html -->

        <xsl:param name="database" select="'https://id.loc.gov/'"/>
        <xsl:param name="scheme" select="'authorities/names/'"/>
        <xsl:param name="service" select="'suggest2'"/>
        <xsl:param name="searchTerm"/>
        <xsl:param name="searchType" select="'keyword'"/>
        <xsl:param name="rdfType" select="'PersonalName'"/>
        <xsl:param name="MIMEType" select="'xml'"/>

        <xsl:param name="APICall">
            <xsl:value-of
                select="
                    concat(
                    $database, $scheme, $service)"/>
            <xsl:value-of select="concat('?q=', $searchTerm)"/>
            <xsl:value-of select="concat('&amp;', 'searchtype=', $searchType)[$searchType !='']"/>
            <xsl:value-of select="concat('&amp;', 'rdftype=', $rdfType)[$rdfType !='']"/>
            <xsl:value-of select="concat('&amp;', 'mime=', $MIMEType)[$MIMEType !='']"/>
        </xsl:param>
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
            madsrdf:ConferenceName |
            madsrdf:ComplexSubject"
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

    <!-- Find subjects from xml tables 
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
                            [. ne '']"
                    />
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
                            [. ne '']"
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
                <xsl:element
                    name="
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
                <xsl:element
                    name="
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
                    <xsl:with-param name="maximumRetrievals"
                        select="
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
            <xsl:apply-templates select="pma:database[@name = 'pbcore']/table"/>
            <xsl:apply-templates select="database[@name = 'cavafy-prod']/table"/>
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
                            if (. != '') then .
                            else
                                'NULL'"
                    />
                </xsl:element>
            </xsl:for-each>
            <xsl:variable name="directLOCSubjectSearchResult">
                <xsl:call-template name="directLOCSubjectSearch">
                    <xsl:with-param name="termToSearch"
                        select="
                            column[@name = 'subject'][. ne '']"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="directLOCNameSearchResult">
                <xsl:call-template name="directLOCNameSearch">
                    <xsl:with-param name="termToSearch"
                        select="
                            column[@name = 'subject'][. ne '']"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="exactSubject" select="$directLOCSubjectSearchResult/rdf:RDF/
                madsrdf:Topic[madsrdf:authoritativeLabel]"/>
            <xsl:variable name="exactName" select="$directLOCNameSearchResult/rdf:RDF
                /madsrdf:*[madsrdf:authoritativeLabel]"/>
            <exactSubject>
                <xsl:value-of
                    select="($exactSubject/madsrdf:authoritativeLabel, 'NULL')
                    [matches(., '\w')][1]"
                />
            </exactSubject>
            <exactSubjectURL>
                <xsl:value-of
                    select="($exactSubject/@rdf:about, 'NULL')
                    [matches(., '\w')][1]"
                />                
            </exactSubjectURL>
            <exactName>
                <xsl:value-of select="
                    ($exactName/madsrdf:authoritativeLabel, 'NULL')
                    [matches(., '\w')][1]"/>
            </exactName>
            <exactNameURL>
                <xsl:value-of select="
                    ($exactName/@rdf:about, 'NULL')
                    [matches(., '\w')][1]"/>                
            </exactNameURL>
            <chosenURL>paste URL here</chosenURL>
            <xsl:variable name="wideLOCSubjectSearchResults">
                <xsl:call-template name="wideLOCSubjectSearch">
                    <xsl:with-param name="searchTerm"
                        select="
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
                    <xsl:with-param name="searchTerm"
                        select="
                            column[@name = 'subject']"/>
                    <xsl:with-param name="maximumRetrievals"
                        select="
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

    <xsl:template name="searchLoC" match="." mode="searchLoC">
        <!-- Search LoC, see https://id.loc.gov/techcenter/searching.html -->

        <xsl:param name="searchTerms"/>

        <xsl:param name="baseLoCURI" select="'https://id.loc.gov'"/>
        <xsl:param name="database" select="'/resources/works'"/>
        <xsl:param name="service" select="'/suggest2'"/>
        <xsl:param name="memberOf"/>
        <xsl:param name="rdftype"/>
        <xsl:param name="searchType" select="
                'keyword'"/>
        <xsl:param name="count" select="'50'"/>
        <!-- Max hits -->
        <xsl:param name="offset" select="'1'"/>
        <xsl:param name="mime" select="'xml'"/>
        <xsl:param name="searchTermsURIEncoded"
            select="
                encode-for-uri(
                replace($searchTerms, '\W', ' ')
                )"/>

        <xsl:param name="directory"/>

        <xsl:param name="fullAPICall">
            <xsl:value-of select="$baseLoCURI"/>
            <xsl:value-of select="$database"/>
            <xsl:value-of select="$service"/>
            <xsl:value-of select="concat('&amp;memberOf=', $memberOf)[$memberOf !='']"/>
            <xsl:value-of select="'?q='"/>
            <xsl:value-of select="$searchTermsURIEncoded"/>
            <xsl:value-of select="concat('&amp;searchtype=', $searchType)[$searchType !='']"/>
            <xsl:value-of select="concat('&amp;rdftype=', $rdftype)[$rdftype !='']"/>
            <xsl:value-of select="concat('&amp;count=', $count)"/>
            <xsl:value-of select="concat('&amp;offset=', $offset)[$offset !='']"/>
            <xsl:value-of select="concat('&amp;mime=', $mime)"/>
        </xsl:param>

        <xsl:param name="searchResults" select="doc($fullAPICall)"/>
        <xsl:message
            select="
                'Search LoC candidates for term ',
                $searchTerms,
                ' using search string ',
                $fullAPICall"/>
        <xsl:copy-of select="$searchResults"/>
    </xsl:template>

    <xsl:template name="searchPersonLoC" match="pb:contributor" mode="searchPersonLoC">
        <xsl:param name="personToSearch"/>
        <xsl:param name="corporationsArePeople" select="fn:false()"/>
        <xsl:call-template name="searchLoC">
            <xsl:with-param name="searchTerms" select="$personToSearch"/>
            <xsl:with-param name="database" select="'/authorities/names'"/>
            <xsl:with-param name="rdftype" select="
                    if ($corporationsArePeople)
                    then
                        'Name'
                    else
                        'PersonalName'"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="workNAF_LCSH" match="
            text()[contains(., 'id.loc.gov')]"
        mode="
        workNAF_LCSH">
        <!-- Process an LoC _work_ -->
        <!-- Extract author and subject headings -->
        <!-- Optional: Limit the authors extracted
        to a specific one -->
        <xsl:param name="workURI" select="."/>
        <xsl:param name="authorToMatch"/>
        <xsl:param name="authorToMatchClean"
            select="replace($authorToMatch[matches(., '\w')], '\W', ' ')"/>
        <xsl:param name="authorToMatchTokenized"
            select="
                tokenize($authorToMatchClean, ' ')"/>
        <xsl:message select="'Find work ', $workURI"/>
        <xsl:variable name="work" select="
                doc(concat($workURI, '.rdf'))"/>
        <xsl:variable name="authors"
            select="
                $work/rdf:RDF/bf:Work/
                bf:contribution/bf:Contribution/
                bf:agent/bf:Agent"/>
        <xsl:variable name="authorMatched"
            select="
                $authors
                [matches(rdfs:label, $authorToMatchTokenized[1], 'i')][matches($authorToMatch, '\w')]
                [matches(rdfs:label, $authorToMatchTokenized[last()], 'i')][matches($authorToMatch, '\w')]"/>
        <xsl:variable name="authorURI"
            select="
                $authorMatched/
                madsrdf:isIdentifiedByAuthority/
                @rdf:resource"/>
        <xsl:variable name="subjects" select="
                $work/rdf:RDF/bf:Work/bf:subject"/>
        <work>
            <xsl:attribute name="workURI" select="$workURI"/>
            <locAuthor>
                <authorURI>
                    <xsl:value-of select="$authorURI"/>
                </authorURI>
                <authorName>
                    <xsl:value-of select="$authorMatched/rdfs:label"/>
                </authorName>
            </locAuthor>
            <subjects>
                <xsl:for-each
                    select="
                        $subjects/
                        bf:*
                        [matches(@rdf:about, $combinedValidatingStrings)]
                        [not(@rdf:about = $authorURI)]">
                    <subject>
                        <subjectURL>
                            <xsl:value-of select="@rdf:about"/>
                        </subjectURL>
                        <subjectLabel>
                            <xsl:value-of select="madsrdf:authoritativeLabel"/>
                        </subjectLabel>
                    </subject>
                </xsl:for-each>
                <!-- People ("agents") as subjects -->
                <xsl:for-each
                    select="
                        $subjects/
                        bf:*
                        [matches(madsrdf:isIdentifiedByAuthority/@rdf:resource, $combinedValidatingStrings)]
                        [not(@rdf:about = $authorURI)]">
                    <subject>
                        <subjectURL>
                            <xsl:value-of select="madsrdf:isIdentifiedByAuthority/@rdf:resource"/>
                        </subjectURL>
                        <subjectLabel>
                            <xsl:value-of select="madsrdf:authoritativeLabel"/>
                        </subjectLabel>
                    </subject>
                </xsl:for-each>
            </subjects>
        </work>
    </xsl:template>

<!--    <xsl:template match="rdf:RDF">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="rdf:Description" mode="IPTC"/>
        </xsl:copy>
    </xsl:template>-->

    <xsl:template match="rdf:Description" mode="IPTC">
        <xsl:param name="keywordsToProcess" select="WNYC:splitParseValidate(
            RIFF:Keywords, $separatingToken,
            $validatingKeywordString
            )/valid"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="RIFF:Keywords" mode="IPTC"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="RIFF:Keywords" mode="IPTC">
        <xsl:param name="keywords" select="."/>
        <xsl:param name="keywordsChecked" select="
            WNYC:splitParseValidate(
            $keywords, $separatingToken,
            $validatingKeywordString
            )"/>
        <xsl:param name="IPTCURLs">
                <xsl:apply-templates
                    select="
                        $keywordsChecked/valid"
                    mode="LoCToIPTC"/>
        </xsl:param>
        <xsl:copy>
        <xsl:copy-of select="$IPTCURLs"/>
        </xsl:copy>
        <!--<xsl:param name="IPTCData">
            <xsl:apply-templates select="
                $wikidataData/wikidataData/IPTCURL" mode="IPTC"/>
        </xsl:param>
        <xsl:copy>            
            <xsl:value-of
                select="
                    $IPTCData/rdf:RDF/
                    rdf:Description/@rdf:about"
                separator="{$separatingTokenLong}"/>
        </xsl:copy>-->
    </xsl:template>

    <xsl:template name="LoCToIPTC" match="
            valid | madsrdf:Topic"
        mode="
        LoCToIPTC">
        <xsl:param name="keyword" select="."/>
        <xsl:param name="LOCURL">
            <xsl:value-of select=".[local-name($keyword) = 'valid']"/>
            <xsl:value-of select="@rdf:about[local-name($keyword) = 'Topic']"/>
        </xsl:param>
        <xsl:param name="LOCURLsAlreadyProcessed"/>
        <xsl:param name="LOCData" select="WNYC:getLOCData($LOCURL)"/>
        <xsl:param name="wikidataURL" select="$LOCData/rdf:RDF/madsrdf:Topic/
            madsrdf:hasCloseExternalAuthority
            [contains(@rdf:resource, $wikidataValidatingString)]"/>
        <xsl:param name="wikiURLsAlreadyProcessed" select="'wikis:'"/>

        <!-- Find wikidata data -->
        <xsl:param name="wikidataData">
            <xsl:apply-templates
                select="$wikidataURL"
                mode="getWikidataData"/>
        </xsl:param>
        <xsl:param name="wikidataDataFound"
            select="
                boolean($wikidataData
                [rdf:RDF/rdf:Description])"/>
        
        <!-- Option 1: Direct link from wikidata to IPTC -->
        <!-- (only works for two top tiers of IPTC) -->
        <xsl:param name="directIPTCLink"
            select="
                $wikidataData/
                rdf:RDF/rdf:Description/
                wdt:P5429/@rdf:resource
                [contains(., $IPTCValidatingString)][1]"/>
        <xsl:param name="directIPTCLinkFound" select="
                boolean($directIPTCLink)"/>
        
        <!-- Option 2: LoC English labels string match to IPTC doc -->
        <xsl:param name="LoCEnglishLabelsIPTCStringMatch">
            <xsl:apply-templates
                select="
                    $LOCData/rdf:RDF/
                    madsrdf:Topic/
                    (madsrdf:authoritativeLabel | 
                    madsrdf:hasVariant/
                    madsrdf:Topic/
                    madsrdf:variantLabel)
                    [@xml:lang = 'en' or not(@xml:lang)]
                    [not($wikidataDataFound)]"
                mode="IPTCStringMatch"/>
        </xsl:param>
        <xsl:param name="LoCEnglishLabelsIPTCStringMatchFound"
            select="
                boolean($LoCEnglishLabelsIPTCStringMatch/rdf:Description)"/>
                
       <!-- Option 3: recursive wikidata to IPTC --> 
        <xsl:param name="wikiToIPTC">
            <xsl:apply-templates select="
                $wikidataURL
                [$wikidataDataFound]
                [not($LoCEnglishLabelsIPTCStringMatchFound)]" mode="wikiToIPTC"/>
        </xsl:param>
        <xsl:param name="wikiToIPTCFound" select="
            boolean($wikiToIPTC[rdf:RDF/rdf:Description])"/>
        
        <!-- Option 4: Broader terms -->
        <xsl:param name="broaderAuthority"
            select="
                $LOCData/rdf:RDF/
                madsrdf:Topic/
                madsrdf:hasBroaderAuthority[madsrdf:Topic[@rdf:about]]"/>
        <xsl:param name="broaderTerms">            
                <xsl:apply-templates
                    select="
                        $broaderAuthority/
                        madsrdf:Topic
                        [not(matches($LOCURLsAlreadyProcessed, @rdf:about))]
                        [not($wikiToIPTCFound)]"
                    mode="LoCToIPTC">
                    <xsl:with-param name="LOCURLsAlreadyProcessed">
                        <xsl:value-of select="$LOCURLsAlreadyProcessed, $LOCURL"
                            separator="{$separatingToken}"/>
                    </xsl:with-param>
                </xsl:apply-templates>            
        </xsl:param>
        <xsl:param name="broaderTermsFound"
            select="
                boolean($broaderTerms//IPTC)"/>

        <IPTCURL>
            <xsl:attribute name="LOCName"
                select="$LOCData/rdf:RDF/
                madsrdf:Topic/madsrdf:authoritativeLabel
                [@xml:lang = 'en' or not(@xml:lang)]"/>
            <xsl:attribute name="LOCURL" select="$LOCURL"/>
            <xsl:attribute name="wikidata" select="$wikidataData/rdf:RDF/rdf:Description[1]/@rdf:about"/>
            <xsl:attribute name="directIPTCLink" select="$directIPTCLink"/>
            <xsl:attribute name="LoCEnglishLabelsIPTCStringMatch"
                select="$LoCEnglishLabelsIPTCStringMatch/rdf:Description/@rdf:about"/>            
            <xsl:attribute name="wikiToIPTC" select="$wikiToIPTC/rdf:Description/@rdf:about"/>
            
            <xsl:copy-of select="$directIPTCLink"/>
            <xsl:copy-of select="$LoCEnglishLabelsIPTCStringMatch"/>
            <xsl:copy-of
                select="$wikiToIPTC"/>
            <xsl:copy-of select="$broaderTerms"/>
        </IPTCURL>
    </xsl:template>
    
    <xsl:template match="test">
        <wikiTest>
        <xsl:message select="'Match!'"/>
        <xsl:apply-templates select="
            madsrdf:hasCloseExternalAuthority" mode="wikiToIPTC"/>        
        </wikiTest>
    </xsl:template>
    
    <xsl:template name="wikiToIPTC"
        match="
            madsrdf:hasCloseExternalAuthority |
            wdt:P460 | wdt:P2959 |
            wdt:P425 |
            wdt:P279 |
            wdt:P361 |
            wdt:P5429"
        mode="
        wikiToIPTC">
        <xsl:param name="wikiInput" select="."/>
        <xsl:param name="wikidataURL">
            <xsl:value-of
                select="
                    @rdf:resource
                    [contains(., $wikidataValidatingString)]"/>
            <xsl:value-of
                select="
                    $wikiInput[contains(., $wikidataValidatingString)]"/>
        </xsl:param>
        <xsl:param name="wikiURLsAlreadyProcessed" select="'wikis:'"/>
        <xsl:param name="wikidataURLMessage">
            <xsl:message select="'Wiki Input', $wikiInput"/>
        </xsl:param>
        <!-- Find wikidata data -->
        <xsl:param name="wikidataData">
            <xsl:call-template name="getWikidataData">
                <xsl:with-param name="wikidataURL" select="$wikidataURL"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="wikidataDataFound"
            select="
                boolean($wikidataData
                [rdf:RDF/rdf:Description])"/>

        <!-- Option 1: Direct link from wikidata to IPTC -->
        <!-- (only works for two top tiers of IPTC) -->
        <xsl:param name="directIPTCLink"
            select="
                $wikidataData/
                rdf:RDF/rdf:Description/
                wdtn:P5429
                [contains(@rdf:resource, $IPTCValidatingString)][1]"/>
        <xsl:param name="directIPTCLinkFound"
            select="
                boolean($directIPTCLink[@rdf:resource])"/>

        <!-- Option 2: wikidata English labels 
            (skos:prefLabel, skos:altLabel)
            string match to IPTC doc -->
        <xsl:param name="wikiLabelsIPTCStringMatch">
            <xsl:apply-templates
                select="
                    $wikidataData/rdf:RDF/
                    rdf:Description[@rdf:about = $wikidataURL]/
                    (skosCore:prefLabel | skosCore:altLabel)
                    [@xml:lang = 'en']
                    [$wikidataDataFound]
                    [not($directIPTCLinkFound)]"
                mode="IPTCStringMatch"/>
        </xsl:param>
        <xsl:param name="wikiLabelsIPTCStringMatchFound"
            select="
                boolean($wikiLabelsIPTCStringMatch[rdf:Description])"/>

        <!-- Option 3: wikidata 'said to be the same as'
        (wdt:P460 or wdt:P2959) -->
        <xsl:param name="wikiSaidToBeTheSame">
            <xsl:apply-templates
                select="
                    $wikidataData/rdf:RDF/
                    rdf:Description/
                    (wdt:P460 | wdt:P2959)
                    [$wikidataDataFound]
                    [not($directIPTCLinkFound)]
                    [not($wikiLabelsIPTCStringMatchFound)]
                    [not(contains($wikiURLsAlreadyProcessed, .))]
                    "
                mode="wikiToIPTC">
                <xsl:with-param name="wikiURLsAlreadyProcessed"
                    select="
                        concat($wikiURLsAlreadyProcessed, $wikidataURL)"
                />
            </xsl:apply-templates>
        </xsl:param>
        <xsl:param name="wikiSaidToBeTheSameFound"
            select="
                boolean($wikiSaidToBeTheSame
                [rdf:RDF/rdf:Description])"/>

        <!-- Option 4: wikidata 'Field of this occupation'
        (wdt:P425) -->
        <!-- (IPTC does not cover professions very well) -->
        <xsl:param name="wikiFieldOfThisOccupation">
            <xsl:apply-templates
                select="
                    $wikidataData/rdf:RDF/
                    rdf:Description/
                    wdt:P425
                    [$wikidataDataFound]
                    [not($directIPTCLinkFound)]
                    [not($wikiLabelsIPTCStringMatchFound)]
                    [not($wikiSaidToBeTheSameFound)]
                    [not(contains($wikiURLsAlreadyProcessed, @rdf:resource))]
                    "
                mode="wikiToIPTC">
                <xsl:with-param name="wikiURLsAlreadyProcessed"
                    select="
                        concat($wikiURLsAlreadyProcessed, $wikidataURL)"
                />
            </xsl:apply-templates>
        </xsl:param>
        <xsl:param name="wikiFieldOfThisOccupationFound"
            select="
                boolean($wikiFieldOfThisOccupation
                [rdf:RDF/rdf:Description])"/>

        <!-- Option 5: wiki 'Subclass of' 
            (wdt:P279)
        except 'series of' -->
        <xsl:param name="wikiSubclassOf">
            <xsl:apply-templates
                select="
                    $wikidataData/rdf:RDF/
                    rdf:Description/
                    wdt:P279
                    [$wikidataDataFound]
                    [not($directIPTCLinkFound)]
                    [not($wikiLabelsIPTCStringMatchFound)]
                    [not($wikiSaidToBeTheSameFound)]
                    [not($wikiFieldOfThisOccupationFound)]
                    [not(contains($wikiURLsAlreadyProcessed, @rdf:resource))]
                    [not(contains(@rdf:resource, $wikidataSeriesCode))]
                    "
                mode="wikiToIPTC">
                <xsl:with-param name="wikiURLsAlreadyProcessed"
                    select="
                        concat($wikiURLsAlreadyProcessed, $wikidataURL)"
                />
            </xsl:apply-templates>
        </xsl:param>
        <xsl:param name="wikiSubclassOfFound"
            select="
                boolean($wikiSubclassOf
                [rdf:RDF/rdf:Description])"/>

        <!-- Option 6: wiki 'part of' 
            (wdt:P361) -->
        <xsl:param name="wikiPartOf">
            <xsl:apply-templates
                select="
                    $wikidataData/rdf:RDF/
                    rdf:Description/
                    wdt:P361
                    [$wikidataDataFound]
                    [not($directIPTCLinkFound)]
                    [not($wikiLabelsIPTCStringMatchFound)]
                    [not($wikiSaidToBeTheSameFound)]
                    [not($wikiFieldOfThisOccupationFound)]
                    [not($wikiSubclassOfFound)]
                    [not(contains($wikiURLsAlreadyProcessed, .))]
                    "
                mode="wikiToIPTC">
                <xsl:with-param name="wikiURLsAlreadyProcessed"
                    select="
                        concat($wikiURLsAlreadyProcessed, $wikidataURL)"
                />
            </xsl:apply-templates>
        </xsl:param>
        <xsl:param name="wikiPartOfFound"
            select="
                boolean($wikiPartOf
                [rdf:RDF/rdf:Description])"/>
        <wikiData>
            <xsl:attribute name="wikiURL" select="$wikidataURL"/>
            <xsl:attribute name="wikiURLsAlreadyProcessed" select="$wikiURLsAlreadyProcessed"/>
            <xsl:attribute name="directIPTCLink" select="$directIPTCLink"/>
            <xsl:attribute name="wikiLabelsIPTCStringMatch" select="$wikiLabelsIPTCStringMatch"/>
            <xsl:attribute name="wikiSaidToBeTheSame" select="$wikiSaidToBeTheSame"/>
            <xsl:attribute name="wikiFieldOfThisOccupation" select="$wikiFieldOfThisOccupation"/>
            <xsl:attribute name="wikiSubclassOf" select="$wikiSubclassOf"/>
            <xsl:attribute name="wikiPartOf" select="$wikiPartOf"/>
            <prefLabel>
                <xsl:value-of
                    select="
                        $wikidataData/rdf:RDF/
                        rdf:Description[contains(@rdf:about, substring-after($wikidataURL, '/Q'))]/skosCore:prefLabel[@xml:lang = 'en']"
                > </xsl:value-of>
            </prefLabel>
            <IPTC>
                <xsl:value-of select="$directIPTCLink/@rdf:resource"/>
            </IPTC>
            <xsl:copy-of select="$wikiLabelsIPTCStringMatch"/>
            <xsl:copy-of select="$wikiSaidToBeTheSame"/>
            <xsl:copy-of select="$wikiFieldOfThisOccupation"/>
            <xsl:copy-of select="$wikiSubclassOf"/>
            <xsl:copy-of select="$wikiPartOf"/>
        </wikiData>
    </xsl:template>

    <xsl:template name="getWikidataData"
        match="
            madsrdf:hasCloseExternalAuthority |
            wdt:P460 | wdt:P2959 |
            wdt:P425 |
            wdt:P279 |
            wdt:P361 |
            wdt:P5429
            "
        mode="getWikidataData">
        <xsl:param name="wikidataInfo" select="."/>
        <xsl:param name="wikidataURL">
            <xsl:value-of
                select="
                    $wikidataInfo/
                    @rdf:resource
                    [matches(., $wikidataValidatingString)]"/>
            <xsl:value-of
                select="
                    $wikidataInfo[matches(., $wikidataValidatingString)]"/>
        </xsl:param>
        <xsl:param name="wikidataInfoMessage">
            <xsl:message select="'Find wikidata data for URL:', $wikidataURL"/>
        </xsl:param>
        <xsl:param name="wikidataLinkAPI">
            <xsl:value-of
                select="
                    replace(
                    replace(
                    $wikidataURL,
                    'www.wikidata.org/wiki/Q',
                    'www.wikidata.org/wiki/Special:EntityData/Q'
                    ),
                    'www.wikidata.org/entity/',
                    'www.wikidata.org/wiki/Special:EntityData/'
                    )"
            />
            <xsl:value-of select="'.rdf'"/>
        </xsl:param>
        <xsl:param name="wikidataData" select="doc($wikidataLinkAPI)"/>
        <xsl:copy-of select="$wikidataData"/>
    </xsl:template>

<!--    <xsl:template match="
        @rdf:resource
        [contains(., $IPTCValidatingString)]" mode="IPTC">
        <xsl:param name="IPTCURL" select="."/>
        <IPTCURL>
            <xsl:value-of select="$IPTCURL"/>
        </IPTCURL>
    </xsl:template>-->
    
    <xsl:template name="IPTCStringMatch" match="
        skosCore:prefLabel |
        madsrdf:authoritativeLabel | 
        madsrdf:variantLabel |
        skosCore:altLabel| wdt:P5973 " 
        mode="IPTCStringMatch" 
        default-collation="http://www.w3.org/2013/collation/UCA?ignore-symbols=yes;strength=primary">
        <xsl:param name="keywordString" select="."/>
        <xsl:copy-of select="
            $mediatopics/rdf:RDF/
            rdf:Description
            [skosCore:prefLabel[@xml:lang='en-US'] eq $keywordString]"/>
    </xsl:template>

    <xsl:template match="IPTCURL" mode="getIPTCData">
        <xsl:param name="IPTCURL" select="."/>
        <xsl:param name="IPTCRDF" select="concat($IPTCURL, '?lang=en-US&amp;format=rdfxml')"/>
        <xsl:param name="IPTCData" select="doc($IPTCRDF)"/>
        <xsl:copy-of select="$IPTCData"/>
    </xsl:template>

    <xsl:template name="IPTCtoPBCore"
        match="rdf:Description[contains(@rdf:about, $IPTCValidatingString)]"
        mode="IPTCtoPBCore">
        <!-- Convert an IPTC entry
        to a pbcoreSubject -->
        <xsl:param name="IPTCURL" select="@rdf:about"/>
        <xsl:param name="IPTCRDF" select="concat($IPTCURL, '?lang=en-US&amp;format=rdfxml')"/>
        <xsl:param name="IPTCData" select="."/>
        <pbcoreSubject>
            <xsl:attribute name="source">
                <xsl:value-of select="'IPTC NewsCode'"/>
            </xsl:attribute>
            <xsl:attribute name="ref">
                <xsl:value-of select="$IPTCURL"/>
            </xsl:attribute>
            <xsl:value-of
                select="skosCore:prefLabel[@xml:lang='en-US']"
            />
        </pbcoreSubject>
    </xsl:template>
    
    <xsl:template name="parseContributors" match="." mode="parseContributors">
        <xsl:param name="contributorsToProcess" select="."/>
        <xsl:param name="token" select="$separatingToken"/>
        <xsl:param name="longToken" select="$separatingTokenLong"/>
        <xsl:param name="contributorsAlreadyInCavafy"/>
        <xsl:param name="role" select="'contributor'"/>
        <xsl:param name="validatingString" select="'id.loc.gov'"/>
        <xsl:param name="validatedSource"
            select="'Library of Congress'[$validatingString = 'id.loc.gov']"/>
        <xsl:param name="capsRole" select="WNYC:Capitalize($role, 1)"/>
        <xsl:param name="message">
            <xsl:message select="
                    concat(
                    'Parse ', $capsRole, 's ',
                    $contributorsToProcess)"/>
            <xsl:message select="
                    $capsRole, 's', 'already in cavafy: ',
                    $contributorsAlreadyInCavafy"/>
            <xsl:if test="
                    $role != 'contributor'
                    and
                    $role != 'creator'">
                <xsl:message terminate="yes" select="
                        concat(
                        'Role must be ',
                        '_creator_ or _contributor_ (lowercase). ',
                        'You entered ', $role)"/>
            </xsl:if>
        </xsl:param>
        <xsl:param name="pbcoreRole" select="
            concat('pbcore', $capsRole)"/>        
        <xsl:param name="contributorsToProcessParsed"
            select="
            WNYC:splitParseValidate(
            $contributorsToProcess, $longToken, $validatingString)[matches($contributorsToProcess, '\w')]"/>
        <xsl:param name="contributorsAlreadyInCavafyParsed"
            select="
            WNYC:splitParseValidate(
            $contributorsAlreadyInCavafy, $longToken, $validatingString)"/>
        <xsl:for-each
            select="
            $contributorsToProcessParsed/valid
            [not(. = $contributorsAlreadyInCavafyParsed/valid)]">
            
            <xsl:variable name="currentContributorxml" select="concat(., '.rdf')"/>
            <xsl:variable name="currentContributorName"
                select="
                WNYC:getLOCData(.)
                //rdf:RDF
                /*
                /madsrdf:authoritativeLabel
                "/>
            <xsl:message
                select="
                concat(
                $currentContributorName, ' not already in cavafy.')"/>
            <xsl:element name="{$pbcoreRole}" namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                <xsl:element name="{$role}" namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                    <xsl:attribute name="ref" select="replace(., 'https://', 'http://')"/>
                    <xsl:attribute name="source" select="$validatedSource"/>
                    <xsl:value-of select="$currentContributorName"/>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="getPersonBasics" match="json:hit" mode="getPersonBasics">
        <xsl:param name="uri" select="json:uri"/>
        <xsl:param name="uriRdf" select="concat($uri, '.rdf')"/>
        <xsl:param name="hitCount" select="../../json:count" as="xs:integer"/>
        <xsl:param name="name" select="json:aLabel"/>
        <xsl:param name="locData" select="doc($uriRdf)"/>
        <xsl:param name="locNameData" select="$locData/rdf:RDF/(madsrdf:PersonalName|madsrdf:CorporateName)"/>
        <xsl:param name="professions" select="
            $locNameData/madsrdf:identifiesRWO/madsrdf:RWO/
            (madsrdf:fieldOfActivity | madsrdf:occupation)"/>
        <xsl:param name="sources" select="$locNameData/madsrdf:hasSource"/>
        <xsl:param name="works" select="
            $locNameData/madsrdf:identifiesRWO/madsrdf:RWO/bflc:contributorTo/bf:Work[position() lt 6]
            "/>
        <xsl:param name="dates" select="
            $locNameData/madsrdf:identifiesRWO/madsrdf:RWO/
            (madsrdf:birthDate, madsrdf:deathDate)"/>
        <xsl:param name="oneHitOnly" select="$hitCount = 1"/>
        <!-- If you think the only option will be the correct one -->
        <xsl:param name="trustMyChoice" select="fn:false()"/>
        <person>
            <xsl:attribute name="choose">
                <xsl:value-of select="'x'[$oneHitOnly][$trustMyChoice]"/>
            </xsl:attribute>
            <xsl:attribute name="uri" select="$uri"/>
            <name>
                <xsl:value-of select="$name"/>
            </name>
            <professions>
                <xsl:value-of select="$professions/normalize-space(.)" separator=" ; "/>
            </professions>
            <dates>
                <xsl:value-of select="$dates/fn:normalize-space(.)" separator=" -- "/>
            </dates>
            <sources>
                <xsl:value-of select="
                    $sources/madsrdf:Source/normalize-space(.)" separator=" ; "/>
            </sources>
            <works>
                <xsl:value-of select="$works/normalize-space(.)" separator=" ; "/>
            </works>
        </person>
    </xsl:template>
    
    
    <xsl:template name="getWorkBasics" match="json:hit" mode="getWorkBasics" xmlns="http://marklogic.com/xdmp/json/basic"  exclude-result-prefixes="#all">
        <xsl:param name="hit" select="."/>
        <xsl:param name="hitNumber" select="position()"/>
        <xsl:param name="uri" select="json:uri"/>
        <xsl:param name="uriRdf" select="concat($uri, '.rdf')"/>
        <xsl:param name="name" select="json:aLabel"/>
        <xsl:param name="locData" select="doc($uriRdf)"/>
        <xsl:param name="type" select="$locData/rdf:RDF/bf:Work/bf:content/bf:Content/rdfs:label"/>
        <xsl:param name="contributors" select="$locData/rdf:RDF/bf:Work/bf:contribution/bf:Contribution/bf:agent/bf:Agent"/>
        <xsl:param name="subjects" select="
            $locData/rdf:RDF/bf:Work/bf:subject/bf:Topic"/>
        
        <xsl:copy select="$locData/rdf:RDF">
            <xsl:copy-of select="$uri"/>
            <xsl:copy-of select="$name"/>
            <xsl:copy-of select="$type"/>
            <xsl:copy-of select="$contributors"/>            
            <xsl:copy-of select="$subjects"/>
        </xsl:copy>
    </xsl:template>
    
    
    
</xsl:stylesheet>
