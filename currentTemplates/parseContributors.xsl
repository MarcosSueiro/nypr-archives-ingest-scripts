<?xml version="1.0" encoding="UTF-8"?>
<!-- Process contributors and creators,
their occupations and their fields of activity
and output pbcoreCreator / pbcoreContributor-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    exclude-result-prefixes="#all">

    <xsl:template name="parseContributors">
        <xsl:param name="contributorsToProcess"/>
        <xsl:param name="token" select="';'"/>
        <xsl:param name="longToken" select="concat(' ',$token,' ')"/>
        <xsl:param name="contributorsAlreadyInCavafy"/>
        <xsl:param name="role" select="contributor"/>
        <xsl:param name="validatingString" select="'id.loc.gov'"/>
        <xsl:param name="validatedSource" select="'Library of Congress'"/>

        <xsl:if 
            test="
            $role != 'contributor' 
            and 
            $role != 'creator'">
            <xsl:message terminate="yes"
                select="concat(
                'Role must be ', 
                '_creator_ or _contributor_ (lowercase). ',
                'You entered ', $role)"
            />
        </xsl:if>

        <xsl:variable name="capsRole" 
            select="concat('C', substring($role, 2))"/>

        <xsl:variable name="pbcoreRole" select="concat('pbcore', $capsRole)"/>

        <xsl:choose>
            <!-- More than one contributor -->
            <xsl:when test="contains($contributorsToProcess, $token)">
                <xsl:variable name="currentContributor"
                    select="
                    normalize-space(
                    substring-before(
                    $contributorsToProcess, $token
                    ))"/>

                <!-- Accepted LOC contributor -->
                <xsl:if 
                    test="
                    contains($currentContributor, $validatingString)">
                    <xsl:if 
                        test="not(
                        contains(
                        $contributorsAlreadyInCavafy, $currentContributor
                        ))">
                        <xsl:variable name="currentContributorxml"
                            select="concat($currentContributor, '.rdf')"/>
                        <xsl:variable name="currentContributorName"
                            select="
                            doc($currentContributorxml)
                            //rdf:RDF
                            /*
                            /madsrdf:authoritativeLabel
                                "/>
                        <xsl:element name="{$pbcoreRole}">
                            <xsl:element name="{$role}">
                                <xsl:attribute name="ref" select="$currentContributor"/>
                                <xsl:attribute name="source" select="$validatedSource"/>
                                <xsl:value-of select="$currentContributorName"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:if>
                </xsl:if>
                <xsl:call-template name="parseContributors">
                    <xsl:with-param name="contributorsToProcess"
                        select="
                        normalize-space(
                        substring-after(
                        substring-after(
                        $contributorsToProcess, 
                        $currentContributor), 
                        $token
                        ))"/>
                    <xsl:with-param name="token" select="$token"/>
                    <xsl:with-param name="contributorsAlreadyInCavafy"
                        select="
                        string-join(
                        ($contributorsAlreadyInCavafy, $currentContributor),
                        $longToken
                        )"/>
                    <xsl:with-param name="role" select="$role"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="currentContributor"
                    select="normalize-space($contributorsToProcess)"/>
                <xsl:if test="contains($currentContributor, $validatingString)">
                    <xsl:variable name="currentContributorxml"
                        select="concat($currentContributor, '.rdf')"/>
                    <xsl:variable name="currentContributorName"
                        select="doc($currentContributorxml)
                        //rdf:RDF/*
                        /madsrdf:authoritativeLabel
                        "/>
                    <xsl:if 
                        test="
                        not(
                        contains($contributorsAlreadyInCavafy, $currentContributor))">
                        <xsl:element name="{$pbcoreRole}">
                            <xsl:element name="{$role}">
                                <xsl:attribute name="ref" select="$currentContributor"/>
                                <xsl:attribute name="source" select="$validatedSource"/>
                                <xsl:value-of select="$currentContributorName"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:if>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

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
                                /@rdf:about[contains(.,$validatingString)]" 
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
                    <!--Not a valid LOC contributor; skip over-->
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
                                /@rdf:about[contains(.,$validatingString)]" 
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
                                /@rdf:about[contains(.,$validatingString)]" 
                                separator="{$longToken}"
                                />
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
                                ($fieldsOfActivity,$currentContributorFieldsOfActivity), 
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
                            select="doc($currentContributorxml)
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
                            select="string-join(
                            ($fieldsOfActivity, $currentContributorFieldsOfActivity), 
                            $longToken
                            )"/>
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
