<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:json="http://marklogic.com/xdmp/json/basic"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fn = "http://www.w3.org/2005/xpath-functions"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    exclude-result-prefixes="#all">
    
    <xsl:mode on-no-match="deep-skip"/>
    <xsl:mode name="update" on-no-match="shallow-copy"/>
    <xsl:param name="chooseContributorMessage">
        1. Extract Capitalised Names from a text 
        2. Note pbcore names 
        (pbcoreContributor, pbcoreCreator, pbcorePublisher) 
        without an authority @ref 
        3. Note pbcoreSubjects without an authority @ref 
        4. Combine 1-3 above and
    generate a document that allows a human to choose the right one
    from a LoC list
        5. Generate a new pbcore document with the corrections,
    as well as a backup pbcore document
    </xsl:param>
    <xsl:param name="chooseCodes">
        <xsl:value-of select="'c=Contributor, s=Subject, r=cReator, p=Publisher'"/>
    </xsl:param>
    
    
    <xsl:import href="masterRouter.xsl"/>
    
    
    
    
    <xsl:template match="pma_xml_export" name="chooseContributors">
        
        <xsl:param name="findLoCContributors">
            <findLoCContributors>
                <xsl:apply-templates select="database/table" mode="findLoCContributor"/>
            </findLoCContributors>
        </xsl:param>
        <xsl:variable name="filename">
            <xsl:value-of
                select="'file:/T:/02%20CATALOGING/Instantiation%20uploads/chooseFiles/'"/>
            <xsl:value-of select="substring-before(tokenize(base-uri(), '/')[last()], '.xml')"/>            
            <xsl:value-of select="'_chooseContributor'"/>
            <xsl:value-of select="format-dateTime(current-dateTime(), '[Y][M01][D01][H01][m01][s01]')"/>
            <xsl:value-of select="'.xml'"/>
        </xsl:variable>
        <xsl:result-document href="{$filename}">
            <xsl:comment select="$chooseContributorMessage"/>
            <xsl:copy-of select="$findLoCContributors"/>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="table" mode="findLoCContributor">
        <xsl:param name="cavafyURL" select="column[@name = 'URL' or @name = 'url']"/>
        <xsl:param name="cavafyEntry" select="doc(concat($cavafyURL, '.xml'))"/>
        <xsl:param name="cavafyID" select="
                $cavafyEntry/pb:pbcoreDescriptionDocument/
                pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog']"/>
        <xsl:param name="assetDates" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreAssetDate"/>
        <xsl:param name="goodCavafyContributors" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreContributor
            [contains(pb:contributor/@ref, $validatingNameString)]"/>
        
        <xsl:param name="invalidPersons" select="
                $cavafyEntry/pb:pbcoreDescriptionDocument/
                (pb:pbcoreContributor|pb:pbcoreCreator|pb:pbcorePublisher)
                [not(contains(pb:*/@ref, $validatingNameString))]"/>
        <xsl:param name="invalidSubjects" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreSubject
            [not(contains(@ref, $validatingKeywordString))]"/>
        <xsl:param name="message">
            <xsl:message select="
                'Find possible LoC matches for contributors', 
                $invalidPersons/pb:contributor"/>
        </xsl:param>
        <xsl:param name="abstract" select="
                $cavafyEntry/pb:pbcoreDescriptionDocument/
                pb:pbcoreDescription[@descriptionType = 'Abstract']"/>

        <asset>
            <xsl:attribute name="cavafyID" select="$cavafyID"/>
            <xsl:attribute name="dates">
                <xsl:value-of select="$assetDates" separator="{$separatingTokenLong}"/>
            </xsl:attribute>
            <abstract>
                <xsl:value-of select="$abstract"/>
            </abstract>
            <url>
                <xsl:value-of select="$cavafyURL"/>
            </url>
            <xsl:apply-templates select="$invalidPersons" mode="findLoCContributor">
                <xsl:with-param name="cavafyEntry" select="$cavafyEntry"/>
                <xsl:with-param name="abstract" select="$abstract"/>
                <xsl:with-param name="cavafyURL" select="$cavafyURL"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="$invalidSubjects" mode="findLoCSubject">
                <xsl:with-param name="cavafyEntry" select="$cavafyEntry"/>
                <xsl:with-param name="abstract" select="$abstract"/>
                <xsl:with-param name="cavafyURL" select="$cavafyURL"/>
            </xsl:apply-templates>
        </asset>
    </xsl:template>
    
    
    <xsl:template name="findLoCContributor" match="
        pb:pbcoreContributor" mode="findLoCContributor">
        <xsl:param name="cavafyEntry" select=".."/>
        <xsl:param name="contributorToSearch" select="pb:contributor"/>
        <xsl:param name="contributorRole" select="pb:contributorRole"/>
        
        <xsl:param name="abstract" select="
                $cavafyEntry/
                pb:pbcoreDescription[@descriptionType = 'Abstract']"/>

        <xsl:param name="message">
            <xsl:message select="
                    'Find LoC candidates for ',
                    $contributorToSearch"/>
        </xsl:param>
        <xsl:param name="contributorNameAnalyzed">
            <xsl:apply-templates select="$contributorToSearch" mode="analyzeName"/>
        </xsl:param>
        <xsl:param name="contributorLastName" select="
            $contributorNameAnalyzed/person/lastName"/>
        <xsl:param name="contributorFirstName" select="
            $contributorNameAnalyzed/person/firstName"/>
        <xsl:param name="contributorBirthDeathDate"
            select="$contributorNameAnalyzed/person/birthDeathDate"/>
        <xsl:param name="textToSearch">
            <xsl:value-of select="
                    $contributorFirstName, 
                    $contributorLastName, 
                    $contributorBirthDeathDate"
            />
        </xsl:param>
        <xsl:param name="searchResult">
            <xsl:call-template name="searchPersonLoC">
                <xsl:with-param name="personToSearch" select="
                    normalize-space($textToSearch)"/>
                <xsl:with-param name="corporationsArePeople" select="true()"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="hitCount" select="
                $searchResult/json:json/json:count" as="xs:integer"/>
        <xsl:param name="locContributorBasics">
            <xsl:apply-templates select="$searchResult/json:json/json:hits/json:hit"
                mode="getPersonBasics">
                <xsl:with-param name="hitCount" select="$hitCount"/>
                <xsl:with-param name="oneHitOnly" select="$hitCount eq 1"/>
            </xsl:apply-templates>
        </xsl:param>
        <xsl:param name="context">
            <xsl:call-template name="getContext">
                <xsl:with-param name="domain" select="$abstract"/>
                <xsl:with-param name="text" select="
                        ($contributorLastName, $contributorFirstName)
                        [matches(., '\w')][1]"/>
                <xsl:with-param name="ignoreCase" select="false()"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="matchingCavafyContributor" select="
                $cavafyEntry/pb:pbcoreDescriptionDocument/
                pb:pbcoreContributor/pb:contributor
                [@ref = $locContributorBasics/person/@uri]"/>
        <xsl:param name="matchingCavafyCreator" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreCreator/pb:creator
            [@ref = $locContributorBasics/person/@uri]"/>
        <xsl:param name="matchingCavafyPublisher" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcorePublisher/pb:publisher
            [@ref = $locContributorBasics/person/@uri]"/>
        <xsl:param name="matchingCavafySubject" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreSubject[@ref = $locContributorBasics/person/@uri]"/>
        <chooseContributor>
            <xsl:attribute name="personSearched" select="$contributorToSearch"/>
            <xsl:attribute name="role" select="$contributorRole"/>
            <xsl:attribute name="noOfHits" select="$hitCount"/>
            <xsl:attribute name="textSearched" select="normalize-space($textToSearch)"/>

            <matchingCavafyContributor>
                <xsl:copy-of select="$matchingCavafyContributor"/>
            </matchingCavafyContributor>
            <matchingCavafySubject>
                <xsl:copy-of select="$matchingCavafySubject"/>
            </matchingCavafySubject>
            <matchingCavafyCreator>
                <xsl:copy-of select="$matchingCavafyCreator"/>
            </matchingCavafyCreator>
            <matchingCavafyPublisher>
                <xsl:copy-of select="$matchingCavafyPublisher"/>
            </matchingCavafyPublisher>

            <xsl:copy-of select="$context"/>
            <xsl:if test="$hitCount = 0">
                <person choose="" uri=""/>
                <xsl:comment select="$chooseCodes"/>
            </xsl:if>
            <xsl:copy select="$locContributorBasics">
                <xsl:comment select="$chooseCodes"/>
                <xsl:copy-of select="@*|node()"/>
            </xsl:copy>
        </chooseContributor>
    </xsl:template>
    
    <xsl:template name="findLoCSubject" match="
        pb:pbcoreSubject" mode="findLoCSubject">
        <xsl:param name="cavafyEntry" select=".."/>
        <xsl:param name="subjectToSearch" select="."/>
        <xsl:param name="subjectSource" select="$subjectToSearch/@source"/>
        <xsl:param name="subjectRef" select="$subjectToSearch/@ref"/>        
        <xsl:param name="abstract" select="
            $cavafyEntry/
            pb:pbcoreDescription[@descriptionType = 'Abstract']"/>        
        <xsl:param name="message">
            <xsl:message select="
                'Find LoC candidates for subject ',
                $subjectToSearch"/>
        </xsl:param>
        <xsl:param name="directLOCSubjectSearchResult">
            <xsl:call-template name="directLOCSubjectSearch">
                <xsl:with-param name="termToSearch"
                    select="$subjectToSearch[. ne '']"/>
            </xsl:call-template>
        </xsl:param>        
        <xsl:param name="exactSubject" select="$directLOCSubjectSearchResult/rdf:RDF/
            madsrdf:Topic[madsrdf:authoritativeLabel]"/>        
        <xsl:param name="exactSubjectHitCount" select="count(
            $directLOCSubjectSearchResult/rdf:RDF)" as="xs:integer"/>
        
        <xsl:param name="locContributorBasics">
            <xsl:apply-templates select="$directLOCSubjectSearchResult/json:json/json:hits/json:hit"
                mode="getPersonBasics">
                <xsl:with-param name="hitCount" select="$exactSubjectHitCount"/>
                <xsl:with-param name="oneHitOnly" select="$exactSubjectHitCount eq 1"/>
            </xsl:apply-templates>
        </xsl:param>
        <xsl:param name="context">
            <xsl:call-template name="getContext">
                <xsl:with-param name="domain" select="$abstract"/>
                <xsl:with-param name="text" select="
                    $subjectToSearch
                    [matches(., '\w')][1]"/>
                <xsl:with-param name="ignoreCase" select="false()"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="matchingCavafyContributor" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreContributor/pb:contributor
            [@ref = $locContributorBasics/person/@uri]"/>
        <xsl:param name="matchingCavafyCreator" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreCreator/pb:creator
            [@ref = $locContributorBasics/person/@uri]"/>
        <xsl:param name="matchingCavafyPublisher" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcorePublisher/pb:publisher
            [@ref = $locContributorBasics/person/@uri]"/>
        <xsl:param name="matchingCavafySubject" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreSubject[@ref = $locContributorBasics/person/@uri]"/>
        <chooseContributor>
            <xsl:attribute name="personSearched" select="$subjectToSearch"/>
            <xsl:attribute name="role" select="$subjectSource"/>
            <xsl:attribute name="noOfHits" select="$exactSubjectHitCount"/>
            <xsl:attribute name="textSearched" select="normalize-space($subjectToSearch)"/>
            
            <matchingCavafyContributor>
                <xsl:copy-of select="$matchingCavafyContributor"/>
            </matchingCavafyContributor>
            <matchingCavafySubject>
                <xsl:copy-of select="$matchingCavafySubject"/>
            </matchingCavafySubject>
            <matchingCavafyCreator>
                <xsl:copy-of select="$matchingCavafyCreator"/>
            </matchingCavafyCreator>
            <matchingCavafyPublisher>
                <xsl:copy-of select="$matchingCavafyPublisher"/>
            </matchingCavafyPublisher>
            
            <xsl:copy-of select="$context"/>
            <xsl:if test="$exactSubjectHitCount = 0">
                <person choose="" uri=""/>
                <xsl:comment select="$chooseCodes"/>
            </xsl:if>
            <xsl:copy select="$locContributorBasics">
                <xsl:comment select="$chooseCodes"/>
                <xsl:copy-of select="@*|node()"/>
            </xsl:copy>
        </chooseContributor>
    </xsl:template>
    
    <xsl:template name="getContext" match="." mode="getContext">
        <xsl:param name="domain" select="."/>
        <xsl:param name="text"/>        
        <xsl:param name="matchNumber" select="1"/>
        <xsl:param name="ignoreCase" select="true()"/>
        <xsl:param name="longDomain" select="string-length($domain) gt 1000"></xsl:param>
        <xsl:param name="message">
            <xsl:message select="'Get context: find text ', $text, ' in domain ', substring($domain, 1, 1000), ' ... '[$longDomain], ', ignoring case'[$ignoreCase]"/>
        </xsl:param>
        <xsl:param name="match" select="
                if ($ignoreCase)
                then
                    analyze-string($domain, $text, 'i')/fn:match
                    [position() = $matchNumber]
                else
                    analyze-string($domain, $text)/fn:match
                    [position() = $matchNumber]"/>
        <xsl:param name="preContextCharacters" select="200"/>
        <xsl:param name="postContextCharacters" select="400"/>
        <xsl:param name="precontext">
            <xsl:value-of select="$match/preceding-sibling::*[position() lt 10]"/>
        </xsl:param>
        <xsl:param name="postcontext">
            <xsl:value-of select="$match/following-sibling::*[position() lt 10]"/>
        </xsl:param>
        <context>
            <xsl:value-of select="
                substring(
                $precontext, 
                string-length($precontext)-$preContextCharacters), 
                '_', $match ,'_', 
                substring($postcontext, 1, $postContextCharacters)
                "/>
        </context>
    </xsl:template>
    
    <!-- Process result document with this template -->
    <xsl:template match="findLoCContributors">
        <!-- First, generate a backup -->
        <xsl:param name="cavafyBackup">
            <xsl:call-template name="generatePbCoreCollection">
                <xsl:with-param name="urls">
                    <xsl:value-of select="asset/url" separator=" ; "/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="importReadyCavafyBackup">
            <xsl:apply-templates select="$cavafyBackup" mode="importReady"/>
        </xsl:param>


        <!-- Process document -->
        <xsl:param name="updatedCavafyEntries">
            <pbcoreCollection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                <xsl:apply-templates select="
                    asset
                    [chooseContributor/person[matches(@choose, '\w')]]"/>
            </pbcoreCollection>
        </xsl:param>
        <xsl:param name="importReadyUpdatedCavafyEntries">
            <xsl:apply-templates select="$updatedCavafyEntries" mode="importReady"/>
        </xsl:param>
<xsl:copy-of select="$updatedCavafyEntries"/>
        <!-- Create backup log document -->
        <xsl:apply-templates select="$importReadyCavafyBackup" mode="breakItUp">
            <xsl:with-param name="breakupDocBaseURI" select="
                    'file:\\T:\02 CATALOGING\Instantiation uploads\instantiationUploadLOGS\'"/>
            <xsl:with-param name="filename" select="'chooseContributorsBACKUP'"/>
            <xsl:with-param name="currentTime"
                select="fn:format-time(fn:current-time(), '[h][m][s]')"/>
        </xsl:apply-templates>
        <!-- Create update document to load into cavafy -->
        <xsl:apply-templates select="$importReadyUpdatedCavafyEntries" mode="breakItUp">
            <xsl:with-param name="breakupDocBaseURI" select="
                    'file:\\T:\02 CATALOGING\Instantiation uploads\'"/>
            <xsl:with-param name="filename" select="'chooseContributors'"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="asset">   
        <xsl:param name="addNonLoCNewContributors" select="
            true()"/>
        <xsl:param name="addNonLoCCavafyContributors" select="
            false()"/>
        <xsl:param name="cavafyEntry" select="
            doc(concat(url, '.xml'))"/>
        <xsl:param name="cavafyContributors" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreContributor"/>
        <xsl:param name="cavafySubjects" select="
            $cavafyEntry/pb:pbcoreDescriptionDocument/
            pb:pbcoreSubject"/>
        <xsl:param name="cavafyContributorLoCURLs" select="
                $cavafyContributors/
                pb:contributor/
                @ref[matches(., $validatingNameString)]"/>       
        <xsl:param name="newContributors" select="
            chooseContributor
            [person/@choose = 'c']"/>
        <xsl:param name="newPBCoreContributors">
            <!-- Build a new set of pbCore Contributors -->
            <xsl:comment select="' 1. Contributors in cavafy already with an LoC URI '"/>
            <xsl:copy-of select="
                    $cavafyContributors
                    [matches(pb:contributor/@ref, $validatingNameString)]"/>
            <xsl:comment select="' 2. New chosen LoC contributors '"/>
            <xsl:call-template name="parseContributors">
                <xsl:with-param name="contributorsToProcess">
                    <xsl:value-of select="
                            $newContributors/person
                            [@choose = 'c']
                            [matches(@uri, $validatingNameString)]/@uri"
                        separator="{$separatingTokenLong}"/>
                </xsl:with-param>
                <xsl:with-param name="contributorsAlreadyInCavafy">
                    <xsl:value-of select="
                        $cavafyContributorLoCURLs" separator="{$separatingTokenLong}"/>
                </xsl:with-param>
            </xsl:call-template>
            <xsl:comment select="' 3. Non-LoC cavafy contributors (optional) '"/>
            <xsl:if test="$addNonLoCCavafyContributors">
                <xsl:copy-of select="$cavafyContributors
                    [not(matches(pb:contributor/@ref, $validatingNameString))]
                    [not(pb:contributor = $newContributors/@personSearched)]"/>
            </xsl:if>
            <xsl:comment select="' 4. New chosen non-LoC contributors (optional) '"/>
            <xsl:if test="$addNonLoCNewContributors">
                <xsl:for-each select="$newContributors/person
                    [@choose = 'c']
                    [not(matches(@uri, $validatingNameString))]">
                    <pbcoreContributor>
                        <contributor>
                            <xsl:value-of select="../@personSearched"/>
                        </contributor>
                    </pbcoreContributor>
                </xsl:for-each>
            </xsl:if>
        </xsl:param>
        
        <xsl:param name="contributorsToSubjects" select="
            chooseContributor
            [person/@choose = 's']"/>
        <xsl:param name="contributorsToSubjectsLoC">
            <xsl:call-template name="processSubjects">
                <xsl:with-param name="subjectsToProcess">
                    <xsl:value-of select="
                        $contributorsToSubjects/person
                        [@choose = 's']
                        [matches(@uri, $validatingNameString)]/@uri"
                        separator="{$separatingTokenLong}"/>
                </xsl:with-param>
                <xsl:with-param name="subjectsProcessed">
                    <xsl:value-of select="
                        $cavafySubjects
                        [matches(@ref, $validatingKeywordString)]/
                        @ref" separator="{$separatingTokenLong}"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="newPBCoreSubjects">
            <!-- Build a new set of pbCore Subjects -->
            <xsl:comment select="' 1. Subjects in cavafy already with an LoC URI '"/>
            <xsl:copy-of select="
                $cavafySubjects
                [matches(@ref, $validatingKeywordString)]"/>            
            <xsl:comment select="' 2. New subjects chosen from LoC contributors '"/>
            <xsl:apply-templates select="$contributorsToSubjectsLoC" mode="LOCtoPBCore"/>
        </xsl:param>
        
        <xsl:copy select="$cavafyEntry/pb:pbcoreDescriptionDocument">
            
            <xsl:copy-of select="$newPBCoreContributors"/>
            <xsl:copy-of select="$newPBCoreSubjects"/>
            <xsl:apply-templates mode="update"/>
        </xsl:copy>
        
            
        
        
        
    </xsl:template>
 
    
    
    
    
    <xsl:template match="pb:pbcoreContributor" mode="update"/>
    <xsl:template match="pb:pbcoreSubject" mode="update"/>
    
</xsl:stylesheet>