<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html">

    
    <xsl:import href="masterRouter.xsl"/>
    
    <xsl:param name="searchString"
        select="
        'https://cavafy.wnyc.org/?facet_Series+Title%5B%5D=On+the+Media&amp;q=9278'"/>

    <xsl:template match="urls">
        <xsl:variable name="pbcoreCollection">
            <xsl:call-template name="generatePbCoreCollection">
                <xsl:with-param name="urls">
                    <xsl:value-of select="url" separator=" ; "/>
                </xsl:with-param> 
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="pbcoreCollectionNarrowSH">
            <xsl:copy select="$pbcoreCollection/pb:pbcoreCollection">
                <xsl:apply-templates
                    select="$pbcoreCollection/pb:pbcoreCollection/pb:pbcoreDescriptionDocument"
                    mode="narrowizeSubjects"/>
            </xsl:copy>
        </xsl:variable>
        <xsl:variable name="narrowSHImportReady">
            <xsl:apply-templates select="$pbcoreCollectionNarrowSH/pb:pbcoreCollection"
                mode="importReady"> </xsl:apply-templates>
        </xsl:variable>
        <xsl:apply-templates select="$narrowSHImportReady/pb:pbcoreCollection" mode="breakItUp">
            <xsl:with-param name="maxOccurrences" select="200"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="pb:pbcoreDescriptionDocument" mode="narrowizeSubjects">
        <xsl:copy>
            <xsl:copy-of
                select="
                    *[following-sibling::pb:pbcoreSubject]
                    [not(self::pb:pbcoreSubject)]"/>
            <xsl:variable name="narrowSubjects">
                <xsl:call-template name="narrowSubjects">
                    <xsl:with-param name="subjectsToProcess">
                        <xsl:value-of select="pb:pbcoreSubject/@ref" separator=" ; "/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:variable>
            <xsl:apply-templates select="$narrowSubjects" mode="LOCtoPBCore"/>
            <xsl:copy-of
                select="
                    *[preceding-sibling::pb:pbcoreSubject]
                    [not(self::pb:pbcoreSubject)]"
            />
        </xsl:copy>
    </xsl:template>


</xsl:stylesheet>