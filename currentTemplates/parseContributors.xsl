<?xml version="1.0" encoding="UTF-8"?>
<!-- Process contributors and creators,
their occupations and their fields of activity
and output pbcoreCreator / pbcoreContributor -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#" xmlns:WNYC="http://www.wnyc.org"
    exclude-result-prefixes="#all">

    <!--<xsl:template name="parseContributors" match="." mode="parseContributors">
        <xsl:param name="contributorsToProcess" select="."/>
        <xsl:param name="token" select="$separatingToken"/>
        <xsl:param name="longToken" select="$separatingTokenLong"/>
        <xsl:param name="contributorsAlreadyInCavafy"/>
        <xsl:param name="role" select="'contributor'"/>
        <xsl:param name="validatingString" select="'id.loc.gov'"/>
        <xsl:param name="validatedSource"
            select="'Library of Congress'[$validatingString = 'id.loc.gov']"/>
        <xsl:variable name="capsRole" select="WNYC:Capitalize($role, 1)"/>
        <xsl:message
            select="
                concat(
                'Parse ', $capsRole, 's ',
                $contributorsToProcess)"/>
        <xsl:message
            select="
                $capsRole, 's', 'already in cavafy: ',
                $contributorsAlreadyInCavafy"/>

        <xsl:if
            test="
                $role != 'contributor'
                and
                $role != 'creator'">
            <xsl:message terminate="yes"
                select="
                    concat(
                    'Role must be ',
                    '_creator_ or _contributor_ (lowercase). ',
                    'You entered ', $role)"
            />
        </xsl:if>
        <xsl:variable name="pbcoreRole" select="concat('pbcore', $capsRole)"/>

        <xsl:variable name="contributorsToProcessParsed"
            select="
                WNYC:splitParseValidate(
                $contributorsToProcess, $longToken, $validatingString)[matches($contributorsToProcess, '\w')]"/>
        <xsl:variable name="contributorsAlreadyInCavafyParsed"
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
            <xsl:element name="{$pbcoreRole}">
                <xsl:element name="{$role}">
                    <xsl:attribute name="ref" select="replace(., 'https://', 'http://')"/>
                    <xsl:attribute name="source" select="$validatedSource"/>
                    <xsl:value-of select="$currentContributorName"/>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>-->

    <xsl:template name="parseContributorOccupations">
        <xsl:param name="contributorsToProcess"/>
        <xsl:param name="occupations" select="''"/>
        <xsl:param name="token" select="';'"/>
        <xsl:param name="validatingString" select="'id.loc.gov'"/>

        <xsl:variable name="longToken" select="concat(' ', $token, ' ')"/>
        <xsl:choose>
            <!-- Multiple contributors -->
            <xsl:when test="contains($contributorsToProcess, $token)">
                <xsl:variable name="currentContributor"
                    select="
                        normalize-space(
                        substring-before(
                        $contributorsToProcess, $token
                        ))"/>
                <xsl:choose>
                    <!-- Valid LOC contributor: add occupations -->
                    <xsl:when test="contains($currentContributor, $validatingString)">
                        <xsl:variable name="currentContributorxml"
                            select="concat($currentContributor, '.rdf')"/>
                        <xsl:variable name="currentContributorName"
                            select="
                                doc($currentContributorxml)
                                //rdf:RDF
                                /*
                                /madsrdf:authoritativeLabel"/>
                        <xsl:variable name="currentContributorOccupations">
                            <xsl:value-of
                                select="
                                    doc($currentContributorxml)
                                    //madsrdf:occupation
                                    /madsrdf:Occupation
                                    /@rdf:about[contains(., $validatingString)]"
                                separator="{$longToken}"/>
                        </xsl:variable>
                        <xsl:call-template name="parseContributorOccupations">
                            <xsl:with-param name="contributorsToProcess"
                                select="
                                    normalize-space(
                                    substring-after($contributorsToProcess, $token
                                    ))"/>
                            <xsl:with-param name="occupations"
                                select="
                                    string-join(
                                    ($occupations, $currentContributorOccupations),
                                    $longToken
                                    )"
                            />
                        </xsl:call-template>
                    </xsl:when>
                    <!--Not a valid LOC contributor; skip over -->
                    <xsl:otherwise>
                        <xsl:call-template name="parseContributorOccupations">
                            <xsl:with-param name="contributorsToProcess"
                                select="
                                    normalize-space(
                                    substring-after($contributorsToProcess, $token
                                    ))"/>
                            <xsl:with-param name="occupations" select="$occupations"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- One (last) contributor -->
            <xsl:otherwise>
                <xsl:variable name="currentContributor"
                    select="normalize-space($contributorsToProcess)"/>

                <xsl:choose>
                    <!-- Valid LOC contributor; add Occupations -->
                    <xsl:when test="contains($currentContributor, $validatingString)">
                        <xsl:variable name="currentContributorxml"
                            select="concat($currentContributor, '.rdf')"/>
                        <xsl:variable name="currentContributorName"
                            select="
                                doc($currentContributorxml)
                                //rdf:RDF
                                /*
                                /madsrdf:authoritativeLabel
                                "/>
                        <xsl:variable name="currentContributorOccupations">
                            <xsl:value-of
                                select="
                                    doc($currentContributorxml)
                                    //madsrdf:occupation
                                    /madsrdf:Occupation
                                    /@rdf:about[contains(., $validatingString)]"
                                separator="{$longToken}"/>
                        </xsl:variable>
                        <xsl:value-of
                            select="
                                string-join(
                                ($occupations, $currentContributorOccupations),
                                $longToken
                                )"
                        />
                    </xsl:when>
                    <!-- Not a valid LOC contributor -->
                    <xsl:otherwise>
                        <xsl:value-of select="$occupations"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="parseContributorFieldsOfActivity">
        <xsl:param name="contributorsToProcess" select="''"/>
        <xsl:param name="fieldsOfActivity" select="''"/>
        <xsl:param name="token" select="';'"/>
        <xsl:param name="validatingString" select="'id.loc.gov'"/>

        <xsl:variable name="longToken" select="concat(' ', $token, ' ')"/>

        <xsl:choose>
            <!-- Multiple contributors -->
            <xsl:when test="contains($contributorsToProcess, $token)">
                <xsl:variable name="currentContributor"
                    select="normalize-space(substring-before($contributorsToProcess, $token))"/>
                <xsl:choose>
                    <!-- Valid LOC contributor -->
                    <xsl:when test="contains($currentContributor, $validatingString)">
                        <xsl:variable name="currentContributorxml"
                            select="concat($currentContributor, '.rdf')"/>
                        <xsl:variable name="currentContributorName"
                            select="
                                doc($currentContributorxml)
                                //rdf:RDF
                                /*
                                /madsrdf:authoritativeLabel
                                "/>
                        <xsl:variable name="currentContributorFieldsOfActivity">
                            <xsl:value-of
                                select="
                                    doc($currentContributorxml)
                                    //madsrdf:fieldOfActivity
                                    /madsrdf:Concept
                                    /@rdf:about[contains(., $validatingString)]"
                                separator="{$longToken}"/>
                        </xsl:variable>
                        <xsl:call-template name="parseContributorFieldsOfActivity">
                            <xsl:with-param name="contributorsToProcess"
                                select="
                                    normalize-space(
                                    substring-after(
                                    $contributorsToProcess, $token
                                    ))"/>
                            <xsl:with-param name="fieldsOfActivity"
                                select="
                                    string-join(
                                    ($fieldsOfActivity, $currentContributorFieldsOfActivity),
                                    $longToken
                                    )"
                            />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="parseContributorFieldsOfActivity">
                            <xsl:with-param name="contributorsToProcess"
                                select="
                                    normalize-space(
                                    substring-after(
                                    $contributorsToProcess,
                                    $token
                                    ))"/>
                            <xsl:with-param name="fieldsOfActivity" select="$fieldsOfActivity"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- One (last) contributor -->
                <xsl:variable name="currentContributor"
                    select="normalize-space($contributorsToProcess)"/>
                <xsl:choose>
                    <!-- Valid LOC contributor; Add fields of activity -->
                    <xsl:when test="contains($currentContributor, $validatingString)">
                        <xsl:variable name="currentContributorxml"
                            select="concat($currentContributor, '.rdf')"/>
                        <xsl:variable name="currentContributorName"
                            select="
                                doc($currentContributorxml)
                                //rdf:RDF
                                /*
                                /madsrdf:authoritativeLabel"/>
                        <xsl:variable name="currentContributorFieldsOfActivity">
                            <xsl:value-of
                                select="
                                    doc($currentContributorxml)
                                    //madsrdf:occupation
                                    /madsrdf:Occupation
                                    /@rdf:about"
                                separator="{$longToken}"/>
                        </xsl:variable>
                        <xsl:value-of
                            select="
                                string-join(
                                ($fieldsOfActivity, $currentContributorFieldsOfActivity),
                                $longToken
                                )"
                        />
                    </xsl:when>
                    <!--Not valid LOC contributor -->
                    <xsl:otherwise>
                        <xsl:value-of select="$fieldsOfActivity"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
