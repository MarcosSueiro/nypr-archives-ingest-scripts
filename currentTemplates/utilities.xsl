<?xml version="1.0" encoding="UTF-8"?>
<!-- Various utility templates and functions -->

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:WNYC="http://www.wnyc.org" xmlns:functx="http://www.functx.com"
    xmlns:ASCII="https://www.ecma-international.org/publications/standards/Ecma-094.htm"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" exclude-result-prefixes="#all">

    <xsl:mode on-no-match="deep-skip"/>

    <xsl:output method="html" version="4.0" indent="yes"/>

    <xsl:variable name="separatingToken" select="';'"/>
    <xsl:variable name="validatingKeywordString" select="'id.loc.gov/authorities/subjects/'"/>
    <xsl:variable name="validatingNameString" select="'id.loc.gov/authorities/names/'"/>

    <xsl:function name="WNYC:Capitalize">
        <!-- Capitalize 
            a certain number of letters
            from the beginning 
        -->
        <xsl:param name="textToCapitalize"/>
        <xsl:param name="numberOflettersToCapitalize"/>
        <xsl:value-of
            select="
                concat(
                upper-case(substring($textToCapitalize, 1, $numberOflettersToCapitalize)),
                substring($textToCapitalize, $numberOflettersToCapitalize + 1))"
        />
    </xsl:function>

    <xsl:function name="WNYC:splitParseValidate">
        <!-- Input: 
        a string, 
        a separating token,
        a validating string.
        Output:
        unique non-empty strings,        
        validated or not.  
        
        Output format: 
        <inputParsed>
              <valid>
              <invalid>        
        -->
        <xsl:param name="input" as="xs:string"/>
        <xsl:param name="separatingToken"/>
        <xsl:param name="validatingString"/>
        <xsl:call-template name="splitParseValidate">
            <xsl:with-param name="input" select="$input"/>
            <xsl:with-param name="separatingToken" select="$separatingToken"/>
            <xsl:with-param name="validatingString" select="$validatingString"/>
        </xsl:call-template>
    </xsl:function>

    <xsl:template match="node()" name="splitParseValidate" mode="splitParseValidate">
        <!-- Parse a token-separated string into unique, 
            non-empty components;
        validate (or not) each component 
         Output format: 
        <inputParsed>
              <valid>
              <invalid>   -->
        <xsl:param name="input" select="."/>
        <xsl:param name="separatingToken" select="$separatingToken"/>
        <xsl:param name="validatingString" select="'id.loc.gov'"/>
        <xsl:param name="normalize" select="true()"/>

        <xsl:param name="inputTokenized">
            <xsl:for-each select="fn:tokenize($input, $separatingToken)">
                <tokenized>
                    <xsl:value-of select="normalize-space(.)[$normalize]"/>
                    <xsl:value-of select=".[not($normalize)]"/>
                </tokenized>
            </xsl:for-each>
        </xsl:param>
        <xsl:message
            select="
                'Split parse and validate string ', $input,
                'separated by', $separatingToken,
                'with validating string', $validatingString"/>
        <inputParsed>
            <xsl:for-each
                select="
                    distinct-values($inputTokenized/tokenized)[. != ''][matches(., $validatingString)]">
                <valid>
                    <xsl:value-of select="."/>
                </valid>
            </xsl:for-each>
            <xsl:for-each
                select="
                    distinct-values($inputTokenized/tokenized)
                    [. != '']
                    [not(matches(., $validatingString))]">
                <invalid>
                    <xsl:value-of select="."/>
                </invalid>
            </xsl:for-each>
        </inputParsed>
    </xsl:template>

    <xsl:template name="strip-tags" match="text()" mode="strip-tags">
        <!-- Get rid of html tags using regexp -->
        <xsl:param name="text" select="."/>
        <xsl:message select="'Get rid of html tags'"/>
        <!-- Replace <p>, <br> and <div> with new lines  -->
        <xsl:variable name="newLines"
            select="
                replace(
                $text,
                '&lt;/*p&gt;|&lt;/*br&gt;|&lt;/*div&gt;',
                '&#x0A;')"/>
        <!-- Then, delete all other tags: 
            identified as text inside two carets < and > -->
        <xsl:variable name="noHtml"
            select="
                replace(
                $newLines,
                '&lt;[^&gt;]+&gt;', '')"/>
        <!-- Get rid of weird spaces -->
        <xsl:variable name="normalizeSpaces"
            select="
                replace($noHtml, '\p{Zs}', ' ')"/>
        <!-- Finally, change more than two new lines to just two -->
        <xsl:value-of
            select="
                replace($normalizeSpaces,
                '&#x0A;{3,}', '&#x0A;&#x0A;')"
        />
    </xsl:template>

    <xsl:function name="WNYC:strip-tags">
        <xsl:param name="text"/>
        <xsl:call-template name="strip-tags">
            <xsl:with-param name="text" select="$text"/>
        </xsl:call-template>
    </xsl:function>

    <xsl:function name="WNYC:stripNonASCII" expand-text="yes">
        <!-- Strip non-ASCII characters -->
        <xsl:param name="inputText"/>
        <xsl:value-of select="replace($inputText, '[^ -~]', '')"/>
    </xsl:function>

    <xsl:template name="ASCIIFy" match="node()" mode="ASCIIFy">
        <!-- Transliterate non-ASCII characters
        such as é
        to their ASCII "equivalent"
        such as e;        
        generate error if non-ASCII characters remain
        -->
        <xsl:param name="inputText" select="."/>
        <xsl:variable name="ASCIIFiedText" select="
                ASCII:ASCIIFier($inputText)"/>
        <!-- Potentially troublesome characters -->
        <xsl:variable name="nonASCIICodesFound"
            select="
                distinct-values(
                string-to-codepoints(
                $inputText
                )[. gt 125 or . lt 32]
                [. != 9]
                [. != 10]
                [. != 13])
                "/>
        <xsl:variable name="nonASCIICharactersFound">
            <xsl:value-of
                select="
                    codepoints-to-string($nonASCIICodesFound)
                    "
            />
        </xsl:variable>
        <ASCIIResult>
            <ASCIIFiedText>
                <xsl:value-of select="$ASCIIFiedText"/>
            </ASCIIFiedText>
            <xsl:if test="$nonASCIICharactersFound">
                <charactersRemoved>
                    <xsl:value-of select="'Non-ASCII characters found: '"/>
                    <xsl:value-of select="$nonASCIICharactersFound"/>
                </charactersRemoved>
                <codesRemoved>
                    <xsl:value-of select="'with codes: '"/>
                    <xsl:value-of select="$nonASCIICodesFound"/>
                </codesRemoved>
            </xsl:if>
            <xsl:if test="max(string-to-codepoints($ASCIIFiedText)) gt 126">
                <xsl:element name="error">
                    <xsl:attribute name="type"
                        select="
                            'nonASCII_characters_remain'"/>
                    <xsl:value-of
                        select="
                            distinct-values(
                            string-to-codepoints($ASCIIFiedText)
                            [. gt 126]
                            )"
                    />
                </xsl:element>
            </xsl:if>
        </ASCIIResult>
    </xsl:template>

    <xsl:function name="ASCII:ASCIIFier">
        <!-- 
        Translate non-ASCII characters
        such as é
        to their ASCII "equivalent"
        such as e
        -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                ASCII:apostrophes(
                ASCII:quotes(
                ASCII:emdash(
                ASCII:endash(
                ASCII:tilde(
                ASCII:ellipsis(
                ASCII:vowelsUC(
                ASCII:vowelsLC(
                ASCII:c(
                ASCII:d(
                ASCII:g(
                ASCII:n(
                ASCII:r(
                ASCII:s(
                ASCII:th(
                ASCII:y(
                ASCII:z(
                ASCII:middleDot(
                ASCII:control(
                ASCII:space(
                ASCII:Copyright(
                ASCII:registered(
                ASCII:trademark(
                $string1)))))))))))))))))))))))"
        />
    </xsl:function>
    <xsl:function name="ASCII:apostrophes">
        <!-- Replace apostrophes with '-->
        <xsl:param name="string1"/>
        <xsl:value-of select='
                replace($string1, "[’‘’]", "&apos;")'/>
    </xsl:function>
    <xsl:function name="ASCII:quotes">
        <!-- Replace quotes with "-->
        <xsl:param name="string1"/>
        <xsl:value-of select="replace($string1, '[”“]', '&quot;')"/>
    </xsl:function>
    <xsl:function name="ASCII:emdash">
        <!-- Replace emdash with two dashes -->
        <xsl:param name="string1"/>
        <xsl:value-of select="replace($string1, '—', '--')"/>
    </xsl:function>
    <xsl:function name="ASCII:endash">
        <!-- Replace endash with - -->
        <xsl:param name="string1"/>
        <xsl:value-of select="replace($string1, '&#8211;', '-')"/>
    </xsl:function>
    <xsl:function name="ASCII:tilde">
        <!-- Replace ˜ with ~ -->
        <xsl:param name="string1"/>
        <xsl:value-of select="replace($string1, '˜', '~')"/>
    </xsl:function>
    <xsl:function name="ASCII:ellipsis">
        <!-- Replace ellipsis with ... -->
        <xsl:param name="string1"/>
        <xsl:value-of select="replace($string1, '&#8230;', '...')"/>
    </xsl:function>
    <xsl:function name="ASCII:vowelsUC">
        <!-- Remove tildes, etc 
            from uppercase vowels -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                replace(
                replace(
                replace(
                replace(
                $string1,
                '[Ù-Ü]', 'U'),
                '[Ò-Ö]', 'O'),
                '[Ì-Ï]', 'I'),
                '[È-Ë]', 'E'),
                '[À-Å]', 'A')"
        />
    </xsl:function>
    <xsl:function name="ASCII:vowelsLC">
        <!-- Remove tildes, etc 
            from lowercase vowels -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                replace(
                replace(
                replace(
                replace(
                replace(
                $string1,
                '[ù-ü]', 'u'),
                '[ò-öøō]', 'o'),
                '[ì-ï]', 'i'),
                '[è-ë]', 'e'),
                '[à-åā]', 'a'),
                'æ', 'ae')"
        />
    </xsl:function>
    <xsl:function name="ASCII:c">
        <!-- Replace ç and ć and č with c
        and Ç with C -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                replace(
                $string1,
                '[çćč]', 'c'),
                'Ç', 'C')
                "
        />
    </xsl:function>
    <xsl:function name="ASCII:d">
        <!-- Replace ð with d -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                $string1,
                '[ð]', 'd')
                "
        />
    </xsl:function>
    <xsl:function name="ASCII:g">
        <!-- Replace ğ with g -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                $string1,
                '[ğ]', 'g')
                "
        />
    </xsl:function>
    <xsl:function name="ASCII:n">
        <!-- Replace ñ with n -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                replace(
                $string1,
                'ñ', 'n'),
                'Ñ', 'N')
                "
        />
    </xsl:function>
    <xsl:function name="ASCII:r">
        <!-- Replace ř with r -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                $string1,
                'ř', 'r')
                "
        />
    </xsl:function>
    <xsl:function name="ASCII:s">
        <!-- Replace š with s -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                $string1,
                'š', 's')
                "
        />
    </xsl:function>
    <xsl:function name="ASCII:th">
        <!-- Replace þ with th -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                $string1,
                '[þ]', 'th')"
        />
    </xsl:function>
    <xsl:function name="ASCII:y">
        <!-- Replace ÿ and ý with y -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                $string1,
                '[ÿý]', 'y')"
        />
    </xsl:function>
    <xsl:function name="ASCII:z">
        <!-- Replace ž with z -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace($string1,
                'ž', 'z')
                "/>
    </xsl:function>
    <xsl:function name="ASCII:middleDot">
        <!-- Replace · with - -->
        <xsl:param name="string1"/>
        <xsl:value-of select="replace($string1, '·', '-')"/>
    </xsl:function>
    <xsl:function name="ASCII:control">
        <!-- Delete control characters -->
        <xsl:param name="string1"/>
        <xsl:value-of select="replace($string1, '[&#157;&#8206;&#129;]', '')"/>
    </xsl:function>
    <xsl:function name="ASCII:space">
        <!-- Replace funky spaces with good old spacebar -->
        <xsl:param name="string1"/>
        <xsl:value-of select="replace($string1, '&#160;', ' ')"/>
    </xsl:function>
    <xsl:function name="ASCII:Copyright">
        <!-- Replace © with (c) -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                $string1,
                '©', '(c)')"
        />
    </xsl:function>
    <xsl:function name="ASCII:registered">
        <!-- Replace ® with (r) -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                $string1,
                '®', '(r)')"
        />
    </xsl:function>
    <xsl:function name="ASCII:trademark">
        <!-- Replace ™ with (TM) -->
        <xsl:param name="string1"/>
        <xsl:value-of
            select="
                replace(
                $string1,
                '™', '(TM)')"
        />
    </xsl:function>


    <xsl:function name="WNYC:trimFinalPeriod">
        <!-- Trim a final period -->
        <xsl:param name="text"/>
        <xsl:value-of
            select="
                if (ends-with($text, '.'))
                then
                    substring($text,
                    1,
                    string-length($text) - 1)
                else
                    $text"
        />
    </xsl:function>

    <xsl:template name="cavafyBasicsHtml" match="pb:pbcoreDescriptionDocument"
        mode="cavafyBasicsHtml">
        <xsl:param name="cavafyData" select="."/>
        <xsl:message select="'Basic asset fields as html'"/>
        <xsl:for-each select="*">
            <xsl:value-of select="concat(local-name(.), ': ')"/>
            <xsl:value-of select="." separator=", "/>
            <br/>
        </xsl:for-each>
    </xsl:template>

    <!-- Strip all attributes from nodes -->
    <xsl:template match="node()" mode="noAttributes">
        <xsl:copy>
            <xsl:apply-templates select="node()" mode="noAttributes"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="checkTextLength" match="
            text()" mode="checkTextLength">
        <xsl:param name="text" select="."/>
        <xsl:param name="maxCharacters" select="80"/>
        <xsl:param name="fieldName" select="local-name(.)"/>
        <xsl:param name="characterCount" select="
                string-length($text)"/>
        <xsl:param name="excessCharacterCount"
            select="
                $characterCount - $maxCharacters"/>
        <xsl:param name="fileTooLong" select="$excessCharacterCount gt 0"/>
        <xsl:param name="generateError" select="true()"/>

        <xsl:copy-of select="$fileTooLong"/>
        <xsl:variable name="excessCharacters" select="substring($text, $maxCharacters)"/>
        <xsl:variable name="errorMessage"
            select="
                $fieldName, $text,
                '_ is', $excessCharacterCount, ' characters too long!',
                'Remove string _', $excessCharacters, '_'"/>
        <xsl:apply-templates
            select="
                $text[$excessCharacterCount gt 0]
                [$generateError]"
            mode="
            generateError">
            <xsl:with-param name="errorType" select="'textTooLong'"/>
            <xsl:with-param name="errorMessage" select="$errorMessage"/>
            <xsl:with-param name="fieldName" select="'DAVIDTitle'"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template name="generateError" match="node()" mode="generateError">
        <xsl:param name="errorType" select="'Error'"/>
        <xsl:param name="fieldName" select="local-name(.)"/>
        <xsl:param name="errorMessage" select="$errorType, 'in field', $fieldName"/>
        <xsl:element name="error">
            <xsl:attribute name="type" select="$errorType"/>
            <xsl:value-of select="$errorMessage"/>
        </xsl:element>
        <xsl:message select="$errorMessage"/>
    </xsl:template>

</xsl:stylesheet>
