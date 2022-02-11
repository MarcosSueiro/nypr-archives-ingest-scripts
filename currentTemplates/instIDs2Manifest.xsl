<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:WNYC="http://www.wnyc.org"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">

    <xsl:import href="generateManifest.xsl"/>
    
    <xsl:output indent="yes" encoding="UTF-8"/>

    

    <xsl:param name="CMSShowList" select="doc('Shows.xml')"/>

    <xsl:variable name="baseURI" select="
        base-uri()"/>
    
    <xsl:template match="instantiationIDs">
        <!-- Generate a manifest
        from a list of instantiation IDs 
        after dividing into bins -->
        <xsl:param name="instIDsByBin">
            <instIDsByBin>
            <xsl:for-each-group select="instantiationID" group-by="@location">
                <xsl:copy select="..">
                    <xsl:attribute name="location" select="fn:current-grouping-key()"/>
                    <xsl:copy-of select="current-group()"/>
                </xsl:copy>
            </xsl:for-each-group>
            </instIDsByBin>
        </xsl:param>
        
            <xsl:apply-templates select="$instIDsByBin/instIDsByBin/instantiationIDs" mode="generateExif"/>
                
            
            
        
            
    </xsl:template>

    

    



</xsl:stylesheet>