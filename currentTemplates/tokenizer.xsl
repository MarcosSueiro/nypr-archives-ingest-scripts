<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" version="1.0">
    <!--Tokenize a string -->
    <xsl:template match="File" mode="tokenize" name="tokenize">
        <xsl:param name="string"/>
        <xsl:param name="break"/>
        
        <xsl:variable name="multitoken" select="contains($string,$break)"/>
        
        <xsl:variable name="token">
            <xsl:choose>
                <xsl:when test="not($multitoken)">
                    <xsl:value-of select="$string"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="string($token)">
                <xsl:value-of select="substring-before($token,$break)"/>
            </xsl:when>
        </xsl:choose>
        
        <xsl:if test="$multitoken">
            <xsl:call-template name="tokenize">
                <xsl:with-param name="string" select="substring-after($string,$break)"/>
                <xsl:with-param name="break" select="$break"/>
            </xsl:call-template>
        </xsl:if>
        
    </xsl:template>

</xsl:stylesheet>
