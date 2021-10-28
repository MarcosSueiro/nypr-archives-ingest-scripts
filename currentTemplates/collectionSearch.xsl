<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
    exclude-result-prefixes="#all"
    version="3.0">
    
    <!-- Find collection info
        from the Collection list concordance -->
    <xsl:template name="collectionSearch" match="/">
        <xsl:param name="collectionAcronym" select="'WNYC'"/>
        <xsl:param name="collectionURL"
            select="document('CollectionConcordance.xml')//*[collAcro = $collectionAcronym]/collURL"
        />   
        
        <collectionxml>
            <xsl:choose>               
                <!-- Collections without a specific Library of Congress entry -->
                <xsl:when test="normalize-space($collectionAcronym) = 'COMM'"/>
                <xsl:when test="normalize-space($collectionAcronym) = 'LANS'"/>
                <!-- The rest of the collections -->
                <xsl:when test="normalize-space($collectionURL) != ''">
                    <xsl:variable name="collectionxml" select="concat($collectionURL, '.rdf')"/>
                    <xsl:message
                        select="concat('Collection ', $collectionAcronym, ' xml/rdf is ', $collectionxml)"/>
                    <xsl:copy-of select="$collectionxml"/>
                </xsl:when>                                    
                <xsl:otherwise>
                    <xsl:element name="error">
                        <xsl:attribute name="type" select="
                            'collection_acronym_not found'"/>
                        <xsl:value-of select="
                            'Collection ', $collectionAcronym, 
                            ' not found.'"/>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </collectionxml>
    </xsl:template>
</xsl:stylesheet>
