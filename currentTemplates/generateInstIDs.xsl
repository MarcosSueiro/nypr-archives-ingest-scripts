<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" exclude-result-prefixes="#all"
    version="2.0">

    <!-- Extract proper instantiation IDs -->

    <xsl:import href="cavafySearch.xsl"/>
    <xsl:import href="parseDAVIDTitle.xsl"/>


    <xsl:variable name="baseURI" select="base-uri()"/>
    <xsl:variable name="currentDate"
        select="
            format-date(current-date(),
            '[Y0001][M01][D01]')"/>
    <xsl:output name="cavafy" encoding="UTF-8" method="xml" version="1.0" indent="yes"/>

    <xsl:output name="log" method="xml" encoding="UTF-8" version="1.0" indent="yes"/>

    <xsl:template match="pma_xml_export">

        <xsl:variable name="urls">
            <xsl:value-of
                select="
                    distinct-values(database/table/column[@name = 'URL'])"
                separator=" ; "/>
        </xsl:variable>
        <xsl:message
            select="
                'Generate missing instantiation IDs in URLs', substring($urls, 1, 200), '...etc.'"/>
        <xsl:variable name="pbcoreCollection">
            <xsl:call-template name="generatePbCoreCollection">
                <xsl:with-param name="urls" select="$urls"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:apply-templates select="$pbcoreCollection" mode="generateInstIDs"/>

        <xsl:apply-templates select="$pbcoreCollection" mode="breakItUp">
            <xsl:with-param name="filenamePrefix" select="'ORIGINALBACKUP_'"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="pb:pbcoreCollection" mode="generateInstIDs">
        <xsl:message select="'Generate instantiation IDs in collection'"/>
        <xsl:variable name="completeOutput">
            <xsl:apply-templates select="pb:pbcoreDescriptionDocument" mode="generateInstIDs"/>
        </xsl:variable>
        <xsl:variable name="cavafyOutput">
            <xsl:copy>
                <xsl:copy-of select="$completeOutput/pb:pbcoreDescriptionDocument[not(.//pb:error)]"
                />
            </xsl:copy>
        </xsl:variable>
        <xsl:variable name="errorOutput"
            select="$completeOutput/pb:pbcoreDescriptionDocument[.//pb:error]"/>

        <xsl:message select="'COMPLETE OUTPUT: ', $completeOutput"/>
        <xsl:message select="'CAVAFY OUTPUT: ', $cavafyOutput"/>
        <xsl:message select="'ERROR OUTPUT: ', $errorOutput"/>

        <xsl:call-template name="dupInstErrorLog">
            <xsl:with-param name="input" select="$errorOutput"/>
        </xsl:call-template>



        <!-- Final result needs to be split 
            into bite-size chunks of about 200 assets -->
        <xsl:variable name="cavafyAssetsCount"
            select="count($cavafyOutput/pb:pbcoreCollection/pb:pbcoreDescriptionDocument)"/>
        <xsl:variable name="maxCavafyAssets" select="200" as="xs:integer"/>
        <xsl:message select="'total instances', $cavafyAssetsCount"/>
        <xsl:apply-templates select="
                $cavafyOutput" mode="breakItUp">
            <xsl:with-param name="maxOccurrences" select="
                    $maxCavafyAssets"/>
            <xsl:with-param name="filenamePrefix" select="'NEW_INST_IDS_'"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="pb:pbcoreDescriptionDocument" mode="generateInstIDs">
        <xsl:message
            select="
                'Create instantiation IDs for asset ',
                pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog']"/>
        <xsl:copy>
            <!-- Copy asset level fields
            except relation and instantiations-->
            <xsl:copy-of
                select="
                    *
                    [not(self::pb:pbcoreRelation)]
                    [not(self::pb:pbcoreInstantiation)]
                    "/>
            <!-- Copy relation sans @ref,
                    which somehow throws an error upon import -->
            <xsl:apply-templates select="
                    pb:pbcoreRelation" mode="noAttributes"/>
            <!-- Generate new instantiation section -->
            <xsl:variable name="newInstantiations">
                <!-- (Barely) process instantiations 
                    with instantiation IDs -->
                <xsl:apply-templates
                    select="
                        pb:pbcoreInstantiation
                        [pb:instantiationIdentifier
                        [@source = 'WNYC Media Archive Label']]"/>
                <!-- Process instantiations 
                    with missing instantiation IDs -->
                <xsl:apply-templates
                    select="
                        pb:pbcoreInstantiation
                        [not(pb:instantiationIdentifier
                        [@source = 'WNYC Media Archive Label'])]"
                    mode="generateInstIDs">
                    <xsl:with-param name="cavafyID"
                        select="
                            pb:pbcoreIdentifier
                            [@source = 'WNYC Archive Catalog']"
                    />
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:message select="
                    'New instantiations', $newInstantiations"/>
            <!-- Output if there are
        no repeated instantiation ID values -->
            <xsl:message
                select="
                    'Duplicate IDs in',
                    $newInstantiations
                    /pb:pbcoreInstantiation
                    [pb:instantiationIdentifier
                    [@source = 'WNYC Media Archive Label']
                    =
                    following-sibling::pb:pbcoreInstantiation
                    /pb:instantiationIdentifier
                    [@source = 'WNYC Media Archive Label']
                    ]"/>
            <xsl:variable name="instantiationIDCount"
                select="
                    count(
                    $newInstantiations
                    /pb:pbcoreInstantiation
                    /pb:instantiationIdentifier
                    [@source = 'WNYC Media Archive Label']
                    )"/>
            <xsl:variable name="instantiationIDDistinctCount"
                select="
                    count(
                    distinct-values(
                    $newInstantiations
                    /pb:pbcoreInstantiation
                    /pb:instantiationIdentifier
                    [@source = 'WNYC Media Archive Label']
                    ))"/>
            <xsl:message
                select="
                    $instantiationIDCount,
                    'vs.',
                    $instantiationIDDistinctCount"/>
            <xsl:copy-of
                select="
                    $newInstantiations
                    [$instantiationIDCount = $instantiationIDDistinctCount]"/>
            <!-- Generate an error if there are 
            repeated instantiation ID values -->
            <xsl:apply-templates
                select="
                    $newInstantiations/pb:pbcoreInstantiation
                    [
                    pb:instantiationIdentifier
                    [@source = 'WNYC Media Archive Label']
                    =
                    following-sibling::pb:pbcoreInstantiation/pb:instantiationIdentifier
                    [@source = 'WNYC Media Archive Label']
                    ]"
                mode="
                dupInstantiationIDs"/>
        </xsl:copy>
    </xsl:template>

    <!-- Process instantiations 
        with proper instantiation IDs -->
    <xsl:template
        match="
            pb:pbcoreInstantiation
            [pb:instantiationIdentifier[@source = 'WNYC Media Archive Label']]">
        <xsl:copy inherit-namespaces="yes">
            <!-- Copy instantiation IDs except UUID -->
            <xsl:copy-of
                select="
                    pb:instantiationIdentifier
                    [not(@source = 'pbcore XML database UUID')]"/>

            <!-- Copy all other values -->
            <xsl:copy-of
                select="
                    *
                    [not(self::pb:instantiationIdentifier)]
                    "
            />
        </xsl:copy>
    </xsl:template>

    <!-- Process instantiations with no proper ID -->
    <xsl:template
        match="
            pb:pbcoreInstantiation
            [not(pb:instantiationIdentifier[@source = 'WNYC Media Archive Label'])]"
        mode="generateInstIDs">
        <xsl:param name="cavafyID"
            select="
                parent::pb:pbcoreDescriptionDocument/
                pb:pbcoreIdentifier[@source = 'WNYC Archive Catalog']"/>
        <xsl:param name="instIDPattern">
            <xsl:value-of select="$cavafyID"/>
            <xsl:value-of select="'\.'"/>
            <xsl:value-of select="'[0-9]+'"/>
            <xsl:value-of select="'[a-z]?'"/>
        </xsl:param>
        <xsl:param name="matchingInstID"
            select="
                pb:instantiationIdentifier
                [matches(., $instIDPattern, 'i')][1]"/>
        <xsl:param name="matchingEssenceTrackID"
            select="
                pb:instantiationEssenceTrack/pb:essenceTrackIdentifier
                [matches(., $instIDPattern, 'i')][1]"/>
        
        <xsl:param name="newInstantiationID"
            select="
                if ($matchingInstID)
                then
                    analyze-string($matchingInstID, $instIDPattern, 'i')/fn:match
                else
                    analyze-string($matchingEssenceTrackID, $instIDPattern, 'i')/fn:match"/>

        <xsl:message select="'New instantiation ID: ', $newInstantiationID"/>

        <xsl:variable name="alternateEssenceTrackIDPattern">
            <!-- This catches an alternate pattern
            used often in CDs and BWFs -->
            <xsl:value-of select="'[A-Z0-9]{2,5}'"/>
            <xsl:value-of select="'-'"/>
            <xsl:value-of select="'[0-9]{4}-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])'"/>
            <xsl:value-of select="'-'"/>
            <xsl:value-of select="'[A-Z]$'"/>
        </xsl:variable>
        <xsl:if test="$newInstantiationID = ''">
            <error type="noExtractableID">
                Could not find an instantiation ID embedded in
                <xsl:copy-of select="pb:instantiationIdentifier"/>
                <xsl:copy-of select="pb:instantiationEssenceTrack/pb:essenceTrackIdentifier"/>
            </error>
        </xsl:if>

       <xsl:copy>
           <instantiationIdentifier xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html" source="WNYC Media Archive Label">
               <xsl:value-of select="lower-case($newInstantiationID)"/>
           </instantiationIdentifier>
           <xsl:copy-of select="*[not(local-name()='instantiationIdentifier' and @source='pbcore XML database UUID')]"/>
       </xsl:copy>        
    </xsl:template>

    <xsl:template match="pb:pbcoreInstantiation" mode="
        dupInstantiationIDs">
        <xsl:variable name="instantiationID"
            select="
                pb:instantiationIdentifier
                [@source = 'WNYC Media Archive Label']"/>
        <xsl:variable name="errorMessage">
            <xsl:value-of select="'Attention!! Instantiations with duplicate IDs: '"/>
            <xsl:value-of select="$instantiationID" separator=", "/>
        </xsl:variable>
        <xsl:message select="$errorMessage"/>

        <xsl:element name="error" namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
            <xsl:attribute name="type" select="
                    'dupInstIDs'"/>
            <xsl:value-of select="$errorMessage"/>
            <xsl:copy-of select="."/>
            <!-- The first instantiation w dupe ID -->
            <xsl:copy-of
                select="
                    following-sibling::pb:pbcoreInstantiation
                    [pb:instantiationIdentifier = $instantiationID]"
            />
        </xsl:element>
    </xsl:template>

    <xsl:template name="dupInstErrorLog" match="node()" mode="dupInstErrorLog">
        <xsl:param name="input"/>
        <xsl:variable name="dupInstantiationErrorFilename"
            select="
                concat(
                substring-before(base-uri(), '.'),
                'dupInstantiationERROR_',
                format-date(current-date(),
                '[Y0001][M01][D01]'),
                '.xml')"/>
        <xsl:message select="$dupInstantiationErrorFilename"/>

        <xsl:result-document format="log" href="{$dupInstantiationErrorFilename}">
            <instantiationErrors>
                <xsl:copy-of select="$input"/>
            </instantiationErrors>
        </xsl:result-document>
    </xsl:template>

    <!--<xsl:template match="node()" name="breakItUp" mode="breakItUp">
        <xsl:param name="firstOccurrence" select="1"/>
        <xsl:param name="maxOccurrences" select="200"/>
        <xsl:param name="total" select="count(child::*)"/>
        <xsl:param name="baseURI" select="$baseURI"/>
        <xsl:param name="filenamePrefix"/>
        <xsl:param name="filename" select="document-uri()"/>
        <xsl:param name="filenameSuffix" select="'_ForCAVAFY'"/>
        <xsl:param name="currentDate" select="$currentDate"/>
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
                $filenamePrefix,
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
                <xsl:with-param name="filenamePrefix" select="$filenamePrefix"/>
                <xsl:with-param name="filename" select="$filename"/>
                <xsl:with-param name="filenameSuffix" select="$filenameSuffix"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>-->


</xsl:stylesheet>