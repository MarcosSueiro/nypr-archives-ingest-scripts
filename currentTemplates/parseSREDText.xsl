<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    exclude-result-prefixes="#all"
    version="3.0">
    
    <xsl:mode on-no-match="shallow-copy"/>
    
    <xsl:output method="xml" indent="yes" html-version="5"/>
    
    <xsl:template match="/">
        
        <xsl:param name="text" select="text"/>
        <xsl:param name="analyzedText">
            <xsl:copy-of select="analyze-string($text, 'MONDAY|TUESDAY|WEDNESDAY|THURSDAY|FRIDAY')"
            />
        </xsl:param>
        <xsl:param name="weekday" select="$analyzedText/fn:analyze-string-result/fn:match"/>
        <xsl:param name="date"
            select="$analyzedText/fn:analyze-string-result/fn:non-match/tokenize(substring-after(., ','), '\n')[1]"/>
        <xsl:param name="description"
            select="$analyzedText/fn:analyze-string-result/fn:non-match/tokenize(substring-after(., ','), '\n')[3]"/>
        
        <entries>
            
            <xsl:for-each
                select="$analyzedText/fn:analyze-string-result/fn:non-match[matches(., '\w')]">
                <xsl:variable name="date"
                    select="normalize-space(tokenize(substring-after(., ','), '\n')[1])"/>
                <xsl:variable name="IETFMonth" select="substring($date, 1, 3)"/>
                <xsl:variable name="day" select="substring-after(substring-before($date, ','), ' ')"/>
                <xsl:variable name="year" select="normalize-space(substring-after($date, ','))"/>
                <xsl:variable name="fakeHour" select="'00:00:00'"/>
                <xsl:variable name="IETFDate">
                    <xsl:value-of select="$day, $IETFMonth, $year, $fakeHour"/>
                </xsl:variable>
                <xsl:variable name="ISODateTime">
                    <xsl:value-of select="fn:parse-ietf-date($IETFDate)"/>
                </xsl:variable>
                <xsl:variable name="ISODate" select="substring($ISODateTime, 1, 10)"/>
                <xsl:variable name="cavafySearchString"
                    select="concat('https://cavafy.wnyc.org/?facet_Series+Title[]=Senior+Edition&amp;q=', $ISODate)"/>
                
                <entry>
                    <cavafySearchString>
                        <xsl:value-of select="$cavafySearchString"/>
                    </cavafySearchString>
                    <cavafy>
                        <xsl:value-of select="doc($cavafySearchString)//*:meta[@name='totalResults']/@content"/>
                    </cavafy>
                    <IETFDate>
                        <xsl:value-of select="$IETFDate"/>
                    </IETFDate>
                    <xsl:variable name="description"
                        select="tokenize(substring-after(., ','), '\n')[position() gt 1]"/>
                    <dateTime>
                        <xsl:value-of select="$ISODateTime"/>
                    </dateTime>
                    <date>
                        <xsl:value-of select="$ISODate"/>
                    </date>
                    <description>
                        <xsl:value-of select="$description"/>
                    </description>
                </entry>
            </xsl:for-each>
        </entries>
    </xsl:template>
    
</xsl:stylesheet>