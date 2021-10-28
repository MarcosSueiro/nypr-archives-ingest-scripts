<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" exclude-result-prefixes="#all"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/" version="2.0">

<!-- Add technical information from vendor to CodingHistory -->
    <xsl:output indent="yes"/>
    <xsl:param name="MemnonTechMD">
        <xsl:copy-of select="doc('file:/T:/01%20INGEST/Levy/AdditionalMemnonMetadata.xml')"/>
    </xsl:param>

    <xsl:template match="rdf:RDF">
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="rdf:Description">
        <xsl:copy>
            <xsl:apply-templates select="RIFF:CodingHistory" mode="addMemnonTechMD">
                <xsl:with-param name="fileName" select="System:FileName"/>
            </xsl:apply-templates>
            <!--            <xsl:copy-of select="*[not(self::RIFF:CodingHistory)]"/>-->
        </xsl:copy>
    </xsl:template>
    <xsl:template match="RIFF:CodingHistory" mode="addMemnonTechMD">
        <xsl:param name="fileName" select="parent::rdf:Description/System:FileName"/>
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
        <xsl:copy>
            <xsl:if test="matches($allMemnonTech, '\w')">
                <xsl:value-of select="'T='"/>
                <xsl:value-of select="$allMemnonTechCleaned"/>
                <xsl:value-of select="'&#xD;'"/>
            </xsl:if>
            <xsl:value-of select="replace(., 'ANALOG', 'ANALOGUE')"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>