<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" exclude-result-prefixes="#all"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/" version="2.0">

    <!-- Add technical data from vendor to CodingHistory -->
    <!-- Accepts output from BWF MetaEdit -->
    
    <xsl:output indent="yes" method="xml" encoding="UTF-8"/>
    <xsl:param name="MemnonTechMD">
        <xsl:copy-of select="doc('file:/T:/01%20INGEST/Levy/AdditionalMemnonMetadata2.xml')"/>
    </xsl:param>

    <xsl:template match="conformance_point_document">
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="File">
        <xsl:copy>
            <xsl:copy-of select="@*"></xsl:copy-of>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="Core">
        <xsl:copy>
            
            <xsl:apply-templates select="CodingHistory" mode="addMemnonTechMD">
                <xsl:with-param name="fileName" select="concat(Description, '.wav')"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="ICRD[contains(., 'uuuu-')]" mode="formatDate"/>
            <!--            <xsl:copy-of select="*[not(self::CodingHistory)]"/>-->
        </xsl:copy>
    </xsl:template>
    <xsl:template match="CodingHistory" mode="addMemnonTechMD">
        <xsl:param name="fileName" select="parent::Core/@name"/>
        <xsl:param name="matchedTechData"
            select="
                $MemnonTechMD/
                audioFiles/
                audioFile[Digitization_FileName = $fileName]"/>
        <xsl:param name="digitizationComment">
            <xsl:value-of select="replace(normalize-space($matchedTechData/Digitization_Comment), '&#x2013;', '-')"/>
        </xsl:param>
        <xsl:param name="bakingStamp">
            <xsl:value-of
                select="$matchedTechData[Baking_Counter != '0']/Baking_Stamp/concat('Baked ', .)"/>
        </xsl:param>
        <xsl:param name="leaderAdded"
            select="$matchedTechData/LeaderAdded[. != '0']/concat('Leader added: ', .)"/>
        <xsl:param name="allMemnonTech"
            select="string-join(($digitizationComment, $bakingStamp, $leaderAdded), '. ')"/>
        <xsl:param name="allMemnonTechCleaned" select="replace($allMemnonTech, ',', ';')"/>
        <xsl:if test="matches($allMemnonTech, '\w')">
        <xsl:copy>            
                <xsl:value-of select="'T='"/>
                <xsl:value-of select="$allMemnonTechCleaned"/>
                <xsl:value-of select="'&#xD;'"/>            
            <xsl:value-of select="replace(., 'ANALOG', 'ANALOGUE')"/>
        </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="ICRD" mode="formatDate">
        <xsl:copy>
            <xsl:value-of select="'0000'"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>