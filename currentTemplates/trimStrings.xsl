<?xml version="1.0" encoding="UTF-8"?>
<!-- Trim strings -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" version="3.0">
    
    
    <xsl:template name="substring-before-last">
        <!-- substring-before-last -->
        <xsl:param name="input"/>
        <xsl:param name="substr"/>
        <xsl:choose>
        <xsl:when test="$substr and contains($input, $substr)">
            <xsl:variable name="temp" select="substring-after($input, $substr)"/>
            <xsl:value-of select="substring-before($input, $substr)"/>
            <xsl:if test="contains($temp, $substr)">
                <xsl:value-of select="$substr"/>
                <xsl:call-template name="substring-before-last">
                    <xsl:with-param name="input" select="$temp"/>
                    <xsl:with-param name="substr" select="$substr"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="substring-after-last">
        <!-- substring-after-last -->
        <xsl:param name="input"/>
        <xsl:param name="substr"/>
        <xsl:variable name="temp" select="substring-after($input, $substr)"/>
        
        <xsl:choose>
            <xsl:when test="$substr and contains($temp,$substr)">
                <xsl:call-template name="substring-after-last">
                    <xsl:with-param name="input" select="$temp"/>
                    <xsl:with-param name="substr" select="$substr"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$temp"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="recursive-in-trim">
        <!-- Recursively trim a specific substring
            from the beginning of string  -->
        <xsl:param name="input"/>
        <xsl:param name="startStr" select="';'"/>
        <xsl:choose>
            <xsl:when test="starts-with(normalize-space($input), $startStr)">
                <xsl:call-template name="recursive-in-trim">
                    <xsl:with-param name="input" select="substring-after($input, $startStr)"/>
                    <xsl:with-param name="startStr" select="$startStr"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="recursive-out-trim">
        <!-- Recursively trim a specific substring
            from the end of string -->
        <xsl:param name="input"/>
        <xsl:param name="endStr" select="';'"/>
        <xsl:choose>
            <xsl:when test="ends-with(normalize-space($input), $endStr)">
                <xsl:call-template name="recursive-out-trim">
                    <xsl:with-param name="input">
                        <xsl:call-template name="substring-before-last">
                            <xsl:with-param name="input" select="$input"/>
                            <xsl:with-param name="substr" select="$endStr"/>
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="endStr" select="$endStr"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="trimStrings">
        <!-- Trim a string 
        to the last occurrence
        of a 'break character'
        (which can be more than one)
        up to a specific length.
        This is useful e.g.
        if you want to trim a long paragraph
        up to a period. 
        -->
        <xsl:param name="input"/>
        <xsl:param name="breakCharacter" select="';'"/>
        <xsl:param name="charLimit" select="100"/>
        <xsl:choose>
            <!-- string is within limit anyway -->
            <xsl:when test="string-length($input) &lt; $charLimit + 1">
                <xsl:value-of select="$input"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="firstTrim" select="substring($input,1,$charLimit)"/>
                <xsl:variable name="finalTrim">
                    <xsl:call-template name="substring-before-last">
                        <xsl:with-param name="input" select="$firstTrim"/>
                        <xsl:with-param name="substr" select="$breakCharacter"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="normalize-space($finalTrim)"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
</xsl:stylesheet>
