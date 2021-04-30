<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" version="2.0">
    
    <xsl:import href="cavafy2BWFMetaEdit.xsl"/>
    <xsl:import href="BWF2Exif.xsl"/>
    <xsl:import href="cavafySearch.xsl"/>
    <xsl:import href="errorLog.xsl"/>
    <xsl:import href="processCollection.xsl"/>
        
    <xsl:template match="/|pb:pbcoreCollection">
        <xsl:param name="instantiationID" select="'68916.2'"/>
        <xsl:param name="cavafyEntry">
            <xsl:copy-of select="pb:pbcoreDescriptionDocument"/>
        </xsl:param>
        <xsl:param name="foundInstantiation"
            select="
                $cavafyEntry//pb:pbcoreInstantiation
                [pb:instantiationIdentifier = $instantiationID]"/>        
        <xsl:param name="fullFilename">
            <xsl:variable name="generatedFilename">
                <xsl:apply-templates
                    select="
                        $foundInstantiation/pb:instantiationIdentifier
                        [@source = 'WNYC Media Archive Label']"
                    mode="generateNextFilename">
                    <xsl:with-param name="foundAsset" select="$cavafyEntry"/>
                    <xsl:with-param name="foundInstantiation" select="$foundInstantiation"/>
                    <xsl:with-param name="instantiationIDOffset" select="0"/>
                    <xsl:with-param name="freeTextComplete" select="''"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:value-of select="normalize-space($generatedFilename/pb:inputs/pb:parsedDAVIDTitle/@DAVIDTitle)"/>
            <xsl:value-of select="'.'"/>
            <xsl:value-of select="tokenize($foundInstantiation/pb:instantiationPhysical, '\W')" separator=""/>
        </xsl:param>
        <xsl:param name="BWFCoreOutput">
            <conformance_point_document>
                <xsl:apply-imports>
                    <xsl:with-param name="filename">
                        <xsl:value-of select="$fullFilename"/>                        
                    </xsl:with-param> 
                </xsl:apply-imports>
            </conformance_point_document>
        </xsl:param>
        <xsl:message select="'Found cavafy entry', $cavafyEntry/pb:pbcoreDescriptionDocument"/>
        <xsl:message select="'Found instantiation', $foundInstantiation"/>
        
        <xsl:copy-of select="$BWFCoreOutput"/>
        <xsl:apply-templates select="$BWFCoreOutput" mode="BWFMetaEdit">
            
        </xsl:apply-templates>
    </xsl:template>
    
</xsl:stylesheet>