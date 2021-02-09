<?xml version="1.0" encoding="UTF-8"?>
<!-- Trim strings -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:WNYC="http://www.wnyc.org" version="3.0"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">


    <xsl:template name="substring-before-last-regex">
        <!-- substring-before-last regex, or entire string otherwise -->
        <xsl:param name="input"/>
        <xsl:param name="substr"/>
        <xsl:value-of select="$input[not(matches(., $substr))]"/>
        <xsl:value-of
            select="
                analyze-string($input, $substr)
                /fn:match[last()]
                /preceding-sibling::*"
            separator=""/>
    </xsl:template>

    <xsl:template name="substring-before-last">
        <!-- substring-before-last, or entire string otherwise -->
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
        <!-- substring-before-last, or entire string otherwise -->
        <xsl:param name="input"/>
        <xsl:param name="substr"/>
        <xsl:value-of select="$input[not(contains(., $substr))]"/>

        <xsl:value-of
            select="
                analyze-string($input, $substr)
                /fn:match[last()]
                /following-sibling::*"
            separator=""/>
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
                <xsl:variable name="firstTrim" select="substring($input, 1, $charLimit)"/>
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

    <xsl:template match="text()" name="abbreviateText" mode="
        abbreviateText">
        <!-- Get rid of words shorter than a certain minimum -->
        <!-- Also, get rid of non-letter and non-number characters -->
        <xsl:param name="text" select="."/>
        <xsl:param name="maxTitleLength" select="30"/>
        <xsl:param name="minWordLength" select="4"/>
        <xsl:param name="regexMatch"
            select="
                concat(
                ' \w{1,', $minWordLength - 1, '} ')"/>
        <xsl:param name="deleteShortWords"
            select="
                replace($text, $regexMatch, ' ')"/>
        <xsl:param name="replaceDashes"
            select="
                replace($deleteShortWords, '-', ' ')"/>
        <xsl:variable name="cleanEntry">
            <xsl:value-of
                select="
                    analyze-string(
                    $replaceDashes, '[ A-Za-z0-9]')/*:match"
                separator=""/>
        </xsl:variable>
        <xsl:value-of select="matches('hello ', '\w{5,} ')"/>
        <originalText>
            <xsl:value-of select="$text"/>
        </originalText>
        <abbreviatedText>
            <xsl:call-template name="substring-before-last">
                <xsl:with-param name="input"
                    select="
                        replace($cleanEntry, ' {2,}', ' ')"/>
                <xsl:with-param name="substr" select="' '"/>
            </xsl:call-template>
        </abbreviatedText>
    </xsl:template>
    
    <xsl:function name="WNYC:substring-before-last">
        <xsl:param name="input"/>
        <xsl:param name="substr"/>
        <xsl:call-template name="substring-before-last">
            <xsl:with-param name="input" select="$input"/>
            <xsl:with-param name="substr" select="$substr"/>
        </xsl:call-template>
    </xsl:function>
    
    <xsl:function name="WNYC:substring-before-last-regex">
        <xsl:param name="input"/>
        <xsl:param name="regex"/>
        <xsl:call-template name="substring-before-last-regex">
            <xsl:with-param name="input" select="$input"/>
            <xsl:with-param name="substr" select="$regex"/>
        </xsl:call-template>
    </xsl:function>

</xsl:stylesheet>
