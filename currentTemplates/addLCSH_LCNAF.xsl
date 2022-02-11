<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    xmlns:WNYC="http://www.wnyc.org"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    exclude-result-prefixes="#all">
       
    <xsl:import href="masterRouter.xsl"/>
    
    <xsl:param name="searchString"
        select="
        'https://cavafy.wnyc.org/?facet_Series+Title%5B%5D=On+the+Media&amp;q=9278'"/>

    <xsl:variable name="baseURI" select="base-uri()"/>
    <xsl:variable name="parsedBaseURI" select="analyze-string($baseURI, '/')"/>
    <xsl:variable name="masterDocFilename">
        <xsl:value-of select="$parsedBaseURI/fn:non-match[last()]"/>
    </xsl:variable> 
    <xsl:variable name="masterDocFilenameNoExtension">
        <xsl:value-of select="WNYC:substring-before-last($masterDocFilename,'.')"/>
    </xsl:variable> 
    <xsl:variable name="baseFolder" select="substring-before($baseURI, $masterDocFilename)"/>
    <xsl:variable name="logFolder" select="concat($baseFolder, 'instantiationUploadLOGS/')"/>
    <xsl:variable name="currentTime"
        select="substring(translate(string(current-time()), ':', ''), 1, 4)"/>
    

    <xsl:template match="rdf:RDF">
        <xsl:variable name="pbcoreCollection">
            <xsl:element name="pbcoreCollection" namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                <xsl:namespace name="xsi" select="'http://www.w3.org/2001/XMLSchema-instance'"/>                
                <xsl:attribute name="xsi:schemaLocation"
                    select="'http://pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd'"/>
                <xsl:apply-templates select="rdf:Description" mode="addLCSH_LCNAF"/>
            </xsl:element>
        </xsl:variable>
        
        
        
        <xsl:apply-templates select="
            $pbcoreCollection/pb:pbcoreCollection" mode="breakItUp">
            <xsl:with-param name="maxOccurrences" select="200"/>
            <xsl:with-param name="filename" select="$masterDocFilenameNoExtension"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="rdf:Description" mode="addLCSH_LCNAF">
        <xsl:variable name="cavafyEntry">
            <xsl:call-template name="generatePbCoreDescriptionDocument">
                <xsl:with-param name="url" select="RIFF:Source"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="exifKeywords" select="RIFF:Keywords"/>
        <xsl:variable name="cavafyKeywords">
            <xsl:value-of select="
                $cavafyEntry/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreSubject/@ref" separator=" ; "/>
        </xsl:variable>        
        <xsl:variable name="exifArtists" select="RIFF:Artist"/>
        <xsl:variable name="cavafyContributors">
            <xsl:value-of select="
            $cavafyEntry/
            pb:pbcoreDescriptionDocument/pb:pbcoreContributor/@ref" separator=" ; "/>            
        </xsl:variable>        
        <xsl:variable name="allLCNAF">
            <xsl:value-of select="$cavafyContributors, $exifArtists" separator=" ; "/>
        </xsl:variable>
        <xsl:variable name="occupationsEtc">
            <xsl:call-template name="LOCOccupationsAndFieldsOfActivity">
                <xsl:with-param name="artists">
                    <xsl:value-of select="$allLCNAF, $exifKeywords, $cavafyKeywords" separator=" ; "/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="allKeywords">
            <xsl:value-of select="$exifKeywords, $cavafyKeywords, $occupationsEtc" separator=" ; "/>
        </xsl:variable>
        
        <xsl:variable name="narrowSubjects">
            <xsl:call-template name="narrowSubjects">
                <xsl:with-param name="subjectsToProcess">
                    <xsl:value-of select="$allKeywords"/>
                </xsl:with-param>
                <xsl:with-param name="subjectsProcessed" select="$cavafyKeywords"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:element name="pbcoreDescriptionDocument" namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
        
            <xsl:copy-of
                select="$cavafyEntry/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreIdentifier[@source='WNYC Archive Catalog']"/>
            <xsl:copy-of
                select="$cavafyEntry/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreTitle[@titleType='Collection']"/>
            
            <xsl:apply-templates select="
                $narrowSubjects/
                (madsrdf:Topic |
                madsrdf:NameTitle |
                madsrdf:Geographic |
                madsrdf:Name |
                madsrdf:FamilyName |
                madsrdf:CorporateName |
                madsrdf:Title |
                madsrdf:PersonalName |
                madsrdf:ConferenceName |
                madsrdf:ComplexSubject)" mode="LOCtoPBCore"/>
            <xsl:call-template name="parseContributors">
                <xsl:with-param name="contributorsToProcess" select="$exifArtists"/>
                <xsl:with-param name="contributorsAlreadyInCavafy" select="$cavafyContributors"/>
            </xsl:call-template>
        </xsl:element>
        
    </xsl:template>

    
    

</xsl:stylesheet>