<?xml version="1.0" encoding="UTF-8"?>
<!-- Input: 
    Collection acronym(s) 
    such as 'WNYC' or 'MUNI'.
    
    Output: 
    Collection name,
    country
    and Library of Congress info
    
    via a document called 
    'CollectionConcordance.xml' -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:WNYC="http://www.wnyc.org"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#" exclude-result-prefixes="#all" version="3.0">

    <xsl:import href="processLoCURL.xsl"/>    

    <xsl:param name="collectionConcordance" select="document('CollectionConcordance.xml')"/>
    <xsl:param name="separatingToken" select="';'"/>
    <xsl:param name="validatingString" select="'id.loc.gov/'"/>

    <xsl:template name="collections">
        <!-- Accept one or more collection acronyms -->
        <xsl:param name="collectionAcronyms" select="'WNYC'"/>
        <xsl:param name="collectionsParsed">
            <xsl:call-template name="splitParseValidate">
                <xsl:with-param name="input" select="$collectionAcronyms"/>
                <xsl:with-param name="separatingToken" select="$separatingToken"/>
                <xsl:with-param name="validatingString" select="''"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:message select="'Process collections', $collectionAcronyms"/>
        <xsl:for-each select="$collectionsParsed/inputParsed/valid">
            <xsl:call-template name="processCollection">
                <xsl:with-param name="collectionAcronym" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="processCollection" match="collectionAcronym" mode="processCollection">
        <!-- Process a single collection 
        and output 
        collectionInfo/collectionLOCName -->
        <xsl:param name="collectionAcronym" select="."/>
        <xsl:message select="
            'Process collection ', $collectionAcronym"/>
        <!-- Collection found -->
        <xsl:variable name="collectionConcordanceInfo"
            select="
                $collectionConcordance/collections
                /collection[collAcro = $collectionAcronym]/*"/>
        <xsl:variable name="collectionLocInfo">
            <xsl:apply-templates
                select="
                    $collectionConcordance/collections
                    /collection[collAcro = $collectionAcronym]
                    /collURL[contains(., 'id.loc.gov')]"
                mode="getLOCData"/>
        </xsl:variable>
        <collectionInfo>
            <xsl:attribute name="collectionAcronym" select="$collectionAcronym"/>
            <!-- Collection not Found -->
            <xsl:apply-templates
                select="
                    $collectionConcordance/collections
                    [not(collection/collAcro = $collectionAcronym)]"
                mode="collectionNotFound">
                <xsl:with-param name="
                    collectionAcronym"
                    select="$collectionAcronym"/>
            </xsl:apply-templates>
            <xsl:copy-of select="$collectionConcordanceInfo"/>
            <collLOCName>
                <xsl:value-of
                    select="
                        $collectionLocInfo/rdf:RDF
                        /madsrdf:*/madsrdf:authoritativeLabel"
                />
            </collLOCName>
            <xsl:copy-of select="$collectionLocInfo"/>
        </collectionInfo>
    </xsl:template>

    <xsl:template match="collections" mode="collectionNotFound">
        <!-- Output error for collections not found -->
        <xsl:param name="collectionAcronym"/>
        <xsl:element name="error">
            <xsl:attribute name="type" select="'collection_not_found'"/>
            <xsl:value-of
                select="
                    'Collection', $collectionAcronym,
                    'not found in CollectionConcordance.xml'"
            />
        </xsl:element>
    </xsl:template>

    <xsl:template name="getCollectionLoCName" 
        match=".[contains(., 'id.loc.gov')]"
        mode="getCollectionLoCName">
        <xsl:call-template name="locLabel">
            <xsl:with-param name="url" select="."/>
        </xsl:call-template>
    </xsl:template>

</xsl:stylesheet>
