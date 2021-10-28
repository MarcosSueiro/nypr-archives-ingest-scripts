<?xml version="1.1" encoding="UTF-8"?>
<!--    
    Generate a BWF MetaEdit-like output
    from a cavafy collection
-->

<xsl:stylesheet version="3.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" 
    xmlns:WNYC="http://www.wnyc.org"
    xmlns:op="https://www.w3.org/TR/2017/REC-xpath-functions-31-20170321/"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" 
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    exclude-result-prefixes="#all">
    
    <xsl:output method="xml" version="1.0" indent="yes" encoding="ASCII"/>

    <xsl:import href="processLoCURL.xsl"/>
    <xsl:import href="cavafySearch.xsl"/>

    <xsl:param name="cavafyValidatingString" 
        select="'https://cavafy.wnyc.org/assets/'"/>
    <xsl:param name="separatingToken" 
        select="';'"/>
    <xsl:param name="separatingTokenLong" 
        select="concat(' ', $separatingToken, ' ')"/>
    <xsl:param name="todaysDate" 
        select="xs:date(current-date())"/>
    
    <xsl:template match="pb:pbcoreCollection" mode="generateBWFME">
        <conformance_point_document>
            <xsl:apply-templates mode="generateBWFME"/>
        </conformance_point_document>
    </xsl:template>
    
    <xsl:template match="pb:pbcoreDescriptionDocument" mode="generateBWFME">
        <xsl:param name="cavafyxml" select="."/>
        <xsl:param name="filename" select="concat('Filename', position() div 2, '.wav')"/>
        <xsl:param name="parsedDAVIDTitle">
            <xsl:call-template name="parseDAVIDTitle">
                <xsl:with-param name="filenameToParse" select="$filename"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="generation" select="
            $parsedDAVIDTitle/parsedDAVIDTitle/parsedElements/parsedGeneration"/>        
        <xsl:param name="assetID" select="
            $parsedDAVIDTitle/parsedDAVIDTitle/parsedElements/assetID"/>
        <xsl:param name="collection" select="
            pb:pbcoreTitle[@titleType='Collection']"/>
        <xsl:param name="RIFF:ArchivalLocation">
            <xsl:variable name="multipleCollections" select="count(pb:pbcoreTitle
                [@titleType='Collection']) gt 1"/>
                <xsl:value-of select="
                    'MULTIPLE COLLECTIONS'[$multipleCollections]"/>
                <xsl:value-of select="WNYC:generateIARL($collection)"/>            
        </xsl:param>
        <xsl:param name="RIFF:Artist">
            <xsl:value-of
                select="
                    pb:pbcoreContributor
                    /pb:contributor
                    /@ref
                    [matches(., $validatingNameString)]"
                separator="{$separatingTokenLong}"/>
        </xsl:param>
        <xsl:param name="RIFF:CommissionedBy">
            <xsl:value-of select="
                    pb:pbcoreCreator
                    /pb:creator
                    /@ref
                    [matches(., $validatingNameString)]" 
                    separator="{$separatingTokenLong}"/>
        </xsl:param>
        <xsl:param name="RIFF:Comment">
            <xsl:value-of select="
                    pb:pbcoreAnnotation" 
                    separator="{$separatingTokenLong}"/>
        </xsl:param>
        <xsl:param name="RIFF:Copyright">
            <xsl:value-of select="
                    pb:pbcoreRightsSummary/pb:rightsSummary"/>
        </xsl:param>
        <xsl:param name="RIFF:CreateDate">
            <xsl:call-template name="earliestDate">
                <xsl:with-param name="cavafyXML" select="."/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="RIFF:Engineer">
            <xsl:value-of select="
                pb:pbcoreContributor
                [contains(pb:contributorRole, 'ngineer')]
                /pb:contributor" separator="{$separatingTokenLong}"/>
        </xsl:param>
        <xsl:param name="multipleGenres" select="
            count(pb:pbcoreGenre) gt 1"></xsl:param>
        <xsl:param name="RIFF:Genre">
            <xsl:value-of select="
                    'MULTIPLE GENRES'[$multipleGenres]"/>
            <xsl:value-of select="pb:pbcoreGenre"/>
        </xsl:param>
        <xsl:param name="RIFF:Keywords">
            <xsl:variable name="narrowSubjects">
                    <xsl:call-template name="narrowSubjects">
                        <xsl:with-param name="subjectsToProcess">
                            <xsl:value-of
                                select="
                                pb:pbcoreSubject
                                /@ref
                                [matches(., $combinedValidatingStrings)]"
                                separator="{$separatingTokenLong}"
                            />
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="
                    $narrowSubjects
                    /madsrdf:*
                    /@rdf:about" 
                    separator="{$separatingTokenLong}"/>
        </xsl:param>
        <xsl:param name="RIFF:Medium">            
            <xsl:variable name="possibleMediums">
                <xsl:value-of
                    select="
                        distinct-values(
                        pb:pbcoreInstantiation
                        /pb:instantiationPhysical)"
                    separator="
                    {$separatingTokenLong}"/>
            </xsl:variable>
            <xsl:value-of
                    select="
                        
                        if (contains($possibleMediums, $separatingToken))
                        then
                            'Audio material'
                        else
                            $possibleMediums"
                />
        </xsl:param>
        <xsl:param name="RIFF:Name">
            <xsl:variable name="multipleTitles" select="
                count(pb:pbcoreTitle[@titleType='Episode']) gt 1"/>
            <xsl:value-of select="'MULTIPLE TITLES'[$multipleTitles]"/>
                <xsl:value-of select="
                    pb:pbcoreTitle[@titleType='Episode']"/>
        </xsl:param>
        <xsl:param name="RIFF:Product">
            <xsl:variable name="multipleSeries" select="
                count(pb:pbcoreTitle[@titleType='Series']) gt 1"/>
            <xsl:value-of select="'MULTIPLE SERIES'[$multipleSeries]"/>
                    <xsl:value-of select="pb:pbcoreTitle[@titleType='Series']"/>
        </xsl:param>
        <xsl:param name="RIFF:Subject">
            <xsl:variable name="multipleAbstracts" select="
                count(pb:pbcoreDescription[@descriptionType='Abstract']) gt 1"/>
            <xsl:value-of select="'MULTIPLE ABSTRACTS'[$multipleAbstracts]"/>
            <xsl:value-of select="pb:pbcoreDescription[@descriptionType='Abstract']"/>
        </xsl:param>
        <xsl:param name="RIFF:Software" select="'Unknown software'"/>
        <xsl:param name="RIFF:Source">
            <xsl:value-of select="
                concat(
                'https://cavafy.wnyc.org/assets/', 
                pb:pbcoreIdentifier
                [@source='pbcore XML database UUID']
                )"/>
        </xsl:param>
        <xsl:param name="RIFF:SourceForm">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="field1" select="
                    pb:pbcoreAnnotation
                    [@annotationType = 'Provenance']"/>
                <xsl:with-param name="defaultValue" select="
                    concat(
                    $collection, ' ', 
                    $RIFF:Medium, ' ', 
                    $generation, ' from ', $assetID)"/>
                <xsl:with-param name="fieldName" select="'SourceForm'"/>
            </xsl:call-template>
            
        </xsl:param>
        
        <!-- Extra descriptors -->
        <xsl:param name="location"/>
        <xsl:param name="physicalLabel"/>                    
        <xsl:param name="mergeID"/>
        
        <xsl:element name="File">
            <xsl:attribute name="name" select="$filename"/>
                <Core>
                    <Description>
                        <xsl:value-of select="$filename"/>
                    </Description>
                    <IARL>
                        <xsl:value-of select="$RIFF:ArchivalLocation"/>
                    </IARL>
                    <IART>
                        <xsl:value-of select="$RIFF:Artist"/>
                    </IART>
                    <ICMS>
                        <xsl:value-of select="$RIFF:CommissionedBy"/>
                    </ICMS>
                    <ICMT>
                        <xsl:value-of select="$RIFF:Comment"/>
                    </ICMT>
                    <ICOP>
                        <xsl:value-of select="$RIFF:Copyright"/>
                    </ICOP>
                    <ICRD>
                        <xsl:value-of select="$RIFF:CreateDate"/>
                    </ICRD>
                    <IENG>
                        <xsl:value-of select="$RIFF:Engineer"/>
                    </IENG>
                    <IGNR>
                        <xsl:value-of select="$RIFF:Genre"/>
                    </IGNR>
                    <IKEY>
                        <xsl:value-of select="$RIFF:Keywords"/>
                    </IKEY>
                    <IMED>
                        <xsl:value-of select="$RIFF:Medium"/>
                    </IMED>
                    <INAM>
                        <xsl:value-of select="$RIFF:Name"/>
                    </INAM>
                    <IPRD>
                        <xsl:value-of select="$RIFF:Product"/>
                    </IPRD>
                    <ISBJ>
                        <xsl:value-of select="$RIFF:Subject"/>
                    </ISBJ>
                    <ISFT>
                        <xsl:value-of select="$RIFF:Software"/>
                    </ISFT>
                    <ISRC>
                        <xsl:value-of select="$RIFF:Source"/>
                    </ISRC>
                    <ISRF>
                        <xsl:value-of select="$RIFF:SourceForm"/>
                    </ISRF>
                    <ITCH>Unknown technician</ITCH>
                </Core>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
