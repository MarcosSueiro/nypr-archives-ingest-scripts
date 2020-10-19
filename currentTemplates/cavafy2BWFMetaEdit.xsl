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
    exclude-result-prefixes="#all">
    
    <xsl:output method="xml" version="1.0" indent="yes" encoding="ASCII"/>

    <xsl:import href="processLoCURL.xsl"/>

    <xsl:param name="cavafyValidatingString" 
        select="'https://cavafy.wnyc.org/assets/'"/>
    <xsl:param name="separatingToken" 
        select="';'"/>
    <xsl:param name="separatingTokenLong" 
        select="concat(' ', $separatingToken, ' ')"/>
    <xsl:param name="todaysDate" 
        select="xs:date(current-date())"/>
    
    <xsl:template match="pb:pbcoreCollection">
        <conformance_point_document>
            <xsl:apply-templates/>
        </conformance_point_document>
    </xsl:template>
    
    <xsl:template match="pb:pbcoreDescriptionDocument">
        <xsl:variable name="filename" select="concat('Filename', position() div 2, '.wav')"/>
        <xsl:element name="File">
            <xsl:attribute name="name" select="$filename"/>
                <Core>
                    <Description>
                        <xsl:value-of select="$filename"/>
                    </Description>
                    <IARL>
                        <xsl:value-of select="
                            concat(
                            'US, ', 
                            pb:pbcoreTitle
                            [@titleType='Collection']
                            )"/>
                    </IARL>
                    <IART>
                        <xsl:value-of select="
                            pb:pbcoreContributor
                            /pb:contributor
                            /@ref
                            [matches(., $validatingNameString)]" separator="
                            {$separatingTokenLong}"/>
                    </IART>
                    <ICMS>
                        <xsl:value-of select="
                            pb:pbcoreCreator
                            /pb:Creator
                            /@ref
                            [matches(., $validatingNameString)]" separator="
                            {$separatingTokenLong}"/>
                    </ICMS>
                    <ICMT>
                        <xsl:value-of select="
                            pb:pbcoreAnnotation" 
                            separator="{$separatingTokenLong}"/>
                    </ICMT>
                    <ICOP>
                        <xsl:value-of select="
                            pb:pbcoreRightsSummary/pb:rightsSummary"/>
                    </ICOP>                    
                    <ICRD>
                        <xsl:variable name="chosenAssetDate">
                            <xsl:variable name="earliestAssetDate" select="
                                min(
                                pb:pbcoreAssetDate
                                [not(contains(., 'u'))]/xs:date(.)
                                )"/>
                            <xsl:variable name="approxAssetDates" select="
                                pb:pbcoreAssetDate[contains(., 'u')]"/>
                            <xsl:value-of select="
                                if(
                                $earliestAssetDate gt xs:date('1000-01-01')
                                )
                                then $earliestAssetDate
                                else if (min($approxAssetDates/pb:pbcoreAssetDate) !='')
                                then min($approxAssetDates/pb:pbcoreAssetDate)
                                else 'uuuu-uu-uu'"/>
                        </xsl:variable>
                        <xsl:value-of select="$chosenAssetDate"/>
                    </ICRD>
                    <IENG>Unknown engineer&#xD;</IENG>
                    <IGNR>
                        <xsl:value-of select="pb:pbcoreGenre"/>
                    </IGNR>
                <IKEY>
                    <xsl:variable name="narrowSubjects">
                        <xsl:call-template name="narrowSubjects">
                            <xsl:with-param name="subjectsToProcess">
                                <xsl:value-of
                                    select="
                                        pb:pbcoreSubject
                                        /@ref
                                        [matches(., $combinedValidatingStrings)]"
                                    separator="
                                    {$separatingTokenLong}"
                                />
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:value-of select="
                        $narrowSubjects
                        /madsrdf:*
                        /@rdf:about" separator="
                        {$separatingTokenLong}"/>
                </IKEY>
                    <IMED>Audio material</IMED>
                    <INAM>
                        <xsl:value-of select="pb:pbcoreTitle[@titleType='Episode']"/>
                    </INAM>
                    <IPRD>
                        <xsl:value-of select="pb:pbcoreTitle[@titleType='Series']"/>
                    </IPRD>
                    <ISBJ>
                        <xsl:value-of select="pb:pbcoreDescription[@descriptionType='Abstract']"/>
                    </ISBJ>
                    <ISFT>Unknown software</ISFT>
                    <ISRC>
                        <xsl:value-of select="
                            concat(
                            'https://cavafy.wnyc.org/assets/', 
                            pb:pbcoreIdentifier
                            [@source='pbcore XML database UUID']
                            )"/>
                    </ISRC>
                    <ISRF>
                        <xsl:value-of select="concat('Audio material from ', pb:pbcoreIdentifier[@source='WNYC Archive Catalog'])"/>
                    </ISRF>
                    <ITCH>Unknown technician</ITCH>
                </Core>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
