<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
    xmlns:XMP='http://ns.exiftool.ca/XMP/XMP/1.0/'>
    
    <xsl:variable name="instantiationIDRegex" select="'^[0-9]{4,}\.[0-9]'"/>
    <xsl:variable name="archives44k24WTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/Archives44k24WTheme.xml')"/>
    <xsl:variable name="archives44kWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/Archives44kWTheme.xml')"/>
    <xsl:variable name="archives48kWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/Archives48kWTheme.xml')"/>
    <xsl:variable name="archives96kWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/Archives96kWTheme.xml')"/>
    <xsl:variable name="archivesBrianLehrerWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/ArchivesBrianLehrerWTheme.xml')"/>
    <xsl:variable name="archivesGreenespaceWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/ArchivesGreenespaceWTheme.xml')"/>
    <xsl:variable name="archivesLeonardLopateWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/ArchivesLeonardLopateWTheme.xml')"/>
    <xsl:variable name="archivesNEHWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/ArchivesNEHWTheme.xml')"/>
    <xsl:variable name="archivesOTMWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/ArchivesOTMWTheme.xml')"/>
    <xsl:variable name="archivesRadiolabWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/ArchivesRadiolabWTheme.xml')"/>
    <xsl:variable name="archivesSoundcheckWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/ArchivesSoundcheckWTheme.xml')"/>
    <xsl:variable name="archivesTakeawayWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/ArchivesTakeawayWTheme.xml')"/>
    <xsl:variable name="archivesWQXRWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/ArchivesWQXRWTheme.xml')"/>
    <xsl:variable name="NewSoundsUndeadWTheme" select="
        doc('file:/T:/02%20CATALOGING/DAVIDLists/NewSoundsUndeadWTheme.xml')"/>
    <xsl:output indent="yes"/>
    
    <xsl:template match="/">
        <xsl:param name="instIDsInDAVID">
        <xsl:apply-templates select="(
            $archives44k24WTheme, 
            $archives44kWTheme, 
            $archives48kWTheme, 
            $archives96kWTheme, 
            $archivesBrianLehrerWTheme, 
            $archivesGreenespaceWTheme, 
            $archivesLeonardLopateWTheme, 
            $archivesNEHWTheme, 
            $archivesOTMWTheme, 
            $archivesRadiolabWTheme, 
            $archivesSoundcheckWTheme, 
            $archivesTakeawayWTheme, 
            $archivesWQXRWTheme, 
            $NewSoundsUndeadWTheme)/rdf:RDF"/>
        </xsl:param>
        <xsl:result-document href="file:///T:/02 CATALOGING/DAVIDLists/instantiationIDsInDAVID.xml">
        <instantiationIDs>
            <xsl:comment>
                <xsl:value-of select="count($instIDsInDAVID/instantiationID)"/>
                Instantiation IDs in DAVID
            <xsl:value-of select="' as of '"/>
                <xsl:value-of select="current-dateTime()"/>
            </xsl:comment>
            <xsl:copy-of select="$instIDsInDAVID"/>
        </instantiationIDs>
        </xsl:result-document>
    </xsl:template>
    
    <!-- Extract instantiation ID -->
    <xsl:template match="rdf:RDF[rdf:Description/XMP:EntriesEntryMediumFileTitle]">
               
            <xsl:apply-templates select="rdf:Description"/>
        
        
    </xsl:template>
    <xsl:template match="rdf:Description">
        <xsl:param name="dbxFilename" select="@rdf:about" tunnel="yes"/>
            <xsl:apply-templates select="
                XMP:EntriesEntryMediumFileTitle
                [ends-with(., '.wav')]" mode="extractInstID"
            >
                <xsl:with-param name="dbxFilename" select="$dbxFilename" tunnel="yes"/>
            </xsl:apply-templates>
    </xsl:template>
    <xsl:template match=".[ends-with(., '.wav')]" mode="extractInstID">
        <xsl:param name="filename" select="."/>
        <xsl:param name="DAVIDTitle" select="tokenize($filename, '\.wav')[1]"/>
        <xsl:param name="instID" select="tokenize(tokenize($DAVIDTitle, '-')[6], ' ')[1][matches(., $instantiationIDRegex)]"
        />
        <xsl:apply-templates select="$instID" mode="validInstID">
            <xsl:with-param name="DAVIDTitle" select="$DAVIDTitle"/>
        </xsl:apply-templates>        
    </xsl:template>
    <xsl:template name="validInstID" match="
        .[matches(., $instantiationIDRegex)]" mode="validInstID">
        <xsl:param name="DAVIDTitle"/>
        <xsl:param name="dbxFilename" tunnel="yes"/>
        <instantiationID>
            <xsl:attribute name="DAVIDTitle" select="$DAVIDTitle"/>
            <xsl:attribute name="dbxFilename" select="$dbxFilename"/>
            <xsl:value-of select="."/>
        </instantiationID>
    </xsl:template>
</xsl:stylesheet>