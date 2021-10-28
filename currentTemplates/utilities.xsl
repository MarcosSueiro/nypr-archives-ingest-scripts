<?xml version="1.0" encoding="UTF-8"?>
<!-- Various utility templates and functions -->

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:WNYC="http://www.wnyc.org" xmlns:functx="http://www.functx.com"
    xmlns:ASCII="https://www.ecma-international.org/publications/standards/Ecma-094.htm"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    default-collation="http://www.w3.org/2013/collation/UCA?ignore-symbols=yes;strength=primary"
    exclude-result-prefixes="#all">

    <xsl:mode on-no-match="deep-skip"/>

    <xsl:output method="html" version="4.0" indent="yes"/>

    <xsl:variable name="ISODatePattern"
        select="
            '^([0-9]{4})-?(1[0-2]|0[1-9])-?(3[01]|0[1-9]|[12][0-9])$'"/>
    <xsl:variable name="CMSShowList" select="doc('Shows.xml')"/>

    <xsl:variable name="separatingToken" select="';'"/>
    <xsl:variable name="separatingTokenLong"
        select="
            concat(' ', $separatingToken, ' ')"/>
    <!-- To avoid semicolons separating a single field -->
    <xsl:variable name="separatingTokenForFreeTextFields" select="
            '###===###'"/>
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

    <xsl:template match="node()" name="splitParseValidate" mode="
        splitParseValidate">
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
        <xsl:param name="inputLength" select="string-length($input)"/>
        <xsl:param name="inputIsLong" select="$inputLength gt 100"/>
        <xsl:message>
            <xsl:value-of select="'Split parse and validate string '"/>
            <xsl:value-of select="substring($input, 1, 100)"/>
            <xsl:value-of select="'. . . '[$inputIsLong]"/>
            <xsl:value-of select="' separated by ', $separatingToken"/>
            <xsl:value-of select="'with validating string', $validatingString"/>
        </xsl:message>
        <inputParsed>
            <xsl:for-each
                select="
                    distinct-values(
                    $inputTokenized/tokenized)
                    [. != '']
                    [matches(., $validatingString)]">
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
        <!-- Delete javascript tags and content -->
        <xsl:variable name="noJava"
            select="
                replace(
                $newLines,
                '&lt;script.*?&gt;.*?&lt;/script&gt;',
                '&#x0A;')"/>
        <!-- Then, delete all other tags: 
            identified as text inside two carets < and > -->
        <xsl:variable name="noHtml"
            select="
                replace(
                $noJava,
                '&lt;[^&gt;]+&gt;', '')"/>
        <!-- Get rid of weird spaces -->
        <xsl:variable name="normalizeSpaces"
            select="
                replace($noHtml, '\p{Zs}', ' ')"/>
        <!-- Finally, change more than two new lines to just two -->
        <xsl:value-of
            select="
                replace($normalizeSpaces,
                '[\r|\n]{2,}', '&#x0A;&#x0A;')"
        />
    </xsl:template>


    <xsl:template name="strip-links" match="text()" mode="strip-links">
        <!-- Strip all hyperlinks -->
        <!-- Both the text and the link -->
        <!-- Do not use on descriptions that have 
        embedded hyperlinks in the text flow -->
        <xsl:param name="text" select="."/>
        <xsl:message select="'Get rid of html links'"/>
        <xsl:value-of
            select="
                analyze-string(
                ., '&lt;a.*?a&gt;')/
                fn:non-match
                "
        />
    </xsl:template>


    <xsl:template name="strip-final-link" match="text()" mode="strip-final-link">
        <!-- Strip only final link -->
        <!-- This is helpful when a description has a final, 
        'hanging' link without context -->
        <xsl:param name="text" select="."/>
        <xsl:message
            select="
                'Get rid of final, hanging html links without context'"/>
        <xsl:value-of
            select="
                analyze-string(
                ., '&lt;a.*&gt;')/
                *[not(
                self::fn:match
                [not(
                following-sibling::fn:non-match[matches(., '\w')]
                )])]"
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

    <xsl:function name="WNYC:justASCIILetters" expand-text="yes">
        <!-- Strip characters that are not ASCII letters -->
        <!-- a-z or A-Z -->
        <xsl:param name="inputText"/>
        <xsl:value-of select="replace($inputText, '[^(a-z|A-Z)]', '')"/>
    </xsl:function>

    <xsl:function name="WNYC:justLetters" expand-text="yes">
        <!-- Strip characters that are not letters -->
        <xsl:param name="inputText"/>
        <xsl:value-of select="replace($inputText, '\P{L}', '')"/>
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
        <xsl:param name="fileTooLong" select="
                $excessCharacterCount gt 0"/>
        <xsl:param name="generateError" select="true()"/>
        <xsl:variable name="excessCharacters"
            select="
                substring($text, $maxCharacters)"/>
        <xsl:variable name="errorMessage"
            select="
                $fieldName, $text,
                '_ is', $excessCharacterCount, ' characters too long!',
                'Remove string _', $excessCharacters, '_'"/>
        <xsl:if test="$excessCharacterCount gt 0 and $generateError">
            <xsl:message select="$errorMessage"/>
            <xsl:call-template name="
                generateError">
                <xsl:with-param name="errorType" select="'textTooLong'"/>
                <xsl:with-param name="errorMessage" select="
                        $errorMessage"/>
                <xsl:with-param name="fieldName" select="'DAVIDTitle'"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="generateError" match="node()" mode="generateError">
        <xsl:param name="fieldName" select="local-name(.)"/>
        <xsl:param name="errorType" select="concat($fieldName, '_Error')"/>
        <xsl:param name="errorMessage" select="$errorType, 'in field', $fieldName"/>
        <xsl:element name="error">
            <xsl:attribute name="type" select="$errorType"/>
            <xsl:value-of select="$errorMessage"/>
        </xsl:element>
        <xsl:message select="$errorMessage"/>
    </xsl:template>

    <xsl:function name="WNYC:reverseArticle">
        <xsl:param name="text" as="xs:string"/>
        <xsl:variable name="analyzedText"
            select="
                analyze-string(
                normalize-space(
                $text
                ),
                ', (The|A|a|the)$'
                )"/>
        <xsl:variable name="reversedText">
            <xsl:value-of
                select="
                    $analyzedText/
                    fn:match/
                    fn:group[@nr = 1]"/>
            <xsl:value-of select="' '[$analyzedText/fn:match != '']"/>
            <xsl:value-of select="$analyzedText/fn:non-match"/>
        </xsl:variable>
        <xsl:value-of
            select="
                WNYC:Capitalize(
                normalize-space(
                $reversedText
                ), 1
                )"
        />
    </xsl:function>

    <xsl:template name="mp3builder" match="
            pb:pbcoreDescriptionDocument"
        mode="mp3builder">
        <xsl:param name="showName" select="
                pb:pbcoreTitle[@titleType = 'Series']"/>
        <xsl:param name="bcastDateAsText"
            select="
                pb:pbcoreAssetDate
                [@dateType = 'broadcast']
                /normalize-space(.)
                [matches(., $ISODatePattern)]"/>
        <xsl:param name="date"
            select="
                xs:date(min($bcastDateAsText)
                )"/>
        <xsl:param name="exactMatch" select="false()"/>
        <xsl:param name="articledShowName" select="
                WNYC:reverseArticle($showName)"/>
        <xsl:param name="cmsDate" select="
                fn:format-date($date, '[M01][D01][Y01]')"/>
        <xsl:param name="cmsShowInfo">
            <xsl:copy-of
                select="
                    $CMSShowList/JSON/
                    data[type = 'show']/
                    attributes[title = $showName]"
            />
        </xsl:param>
        <xsl:param name="slug" select="
                $cmsShowInfo/attributes/slug"/>
        <xsl:message select="'Generate MP3 for show', $showName, 'on date', $date"/>
        <xsl:if test="matches($slug, '\w')">
            <xsl:value-of select="$slug"/>
            <xsl:value-of select="$cmsDate"/>
            <xsl:value-of select="'.mp3'[$exactMatch]"/>
        </xsl:if>
    </xsl:template>

    <xsl:template name="titleCase">
        <!-- Generate title case -->
        <!-- Lifted from 
            https://stackoverflow.com/questions/62193225/how-can-i-convert-all-heading-text-to-title-case-with-xslt -->
        <xsl:param name="inputTitle"/>

        <xsl:param name="alwaysLC"
            select="'*a*,*an*,*the*,*and*,*but*,*for*,*nor*,*or*,*so*,*yet*,*as*,*at*,*by*,*if*,*in*,*of*,*on*,*to*,*with*,*when*,*where*'"/>
        <xsl:param name="alwaysUC"
            select="'\\.[A-Z]|^A\\/H$|^ABC$|^AIDS$|^AM$|^AP$|^ASCAP$|^BBC$|^CBGB$|^CBS$|^CD$|^CMNY$|^CNN$|^CPB$|^DAT$|^DNC$|^DIY$|^EPA$|^FDNY$|^FM$|^GOP$|^HSA$|^HUAC$|^II$|^III$|^IV$|^IX$|^JFK$|^LMDC$|^M\\/H$|^NATO$|^NBC$|^NPR$|^NS$|^NW$|^NWU$|^NY$|^NY1$|^NYC$|^NYPD$|^NYS$|^P\.M\.$|^PAL$|^PBS$|^PCB$|^PM$|^PS$|^RNC$|^SFX$|^TAL$|^TB$|^UN$|^US$|^USA$|^USAF$|^TV$|^V\-E$|^VD$|^VE$|^VI$^VII$||^VP$|^WNBA$|^WQXR$|^WNYC$|^WW1$|^WW2$|^XI$|^XII$'"/>

        <xsl:param name="cleanInput" select="normalize-space($inputTitle)"/>
        <xsl:param name="elements" select="tokenize($cleanInput, ' ')"/>
        <xsl:for-each select="$elements">
            <xsl:variable name="lcElement" select="lower-case(.)"/>
            <xsl:choose>
                <!-- Leave some words uppercase -->
                <xsl:when test="matches(., $alwaysUC)">
                    <xsl:value-of select="."/>
                    <xsl:if test="position() != last()">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:when>
                <!-- The first letter of the first word of a title is always Uppercase -->
                <xsl:when test="position() = 1">
                    <xsl:value-of select="upper-case(substring($lcElement, 1, 1))"/>
                    <xsl:value-of select="substring($lcElement, 2)"/>
                    <xsl:if test="position() != last()">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <!-- Leave some words uppercase -->
                        <xsl:when test="matches(., $alwaysUC)">
                            <xsl:value-of select="."/>
                        </xsl:when>
                        <!-- If the word is contained in $words, leave it Lowercase -->
                        <xsl:when test="contains($alwaysLC, concat('*', $lcElement, '*'))">
                            <xsl:value-of select="$lcElement"/>
                            <xsl:if test="position() != last()">
                                <xsl:text> </xsl:text>
                            </xsl:if>
                        </xsl:when>

                        <!-- If not, first letter is Uppercase -->
                        <xsl:otherwise>
                            <xsl:value-of select="upper-case(substring($lcElement, 1, 1))"/>
                            <xsl:value-of select="substring($lcElement, 2)"/>
                            <xsl:if test="position() != last()">
                                <xsl:text> </xsl:text>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

    </xsl:template>

    <xsl:function name="WNYC:titleCase">
        <xsl:param name="inputTitle"/>
        <xsl:call-template name="titleCase">
            <xsl:with-param name="inputTitle"/>
        </xsl:call-template>
    </xsl:function>

    <xsl:template name="RIFFDate">
        <xsl:param name="inputDate"/>
        <xsl:param name="inputDateISO" select="translate($inputDate, ':', '-')"/>
        <xsl:param name="inputDateParsed" select="tokenize($inputDateISO, '-')"/>
        <xsl:param name="year">
            <xsl:value-of select="$inputDateParsed[1][not(contains(., 'u'))]"/>
            <xsl:value-of select="'0000'[(contains($inputDateParsed[1], 'u'))]"/>
        </xsl:param>
        <xsl:param name="month" select="
                $inputDateParsed[2][not(contains(., 'u'))]"/>
        <xsl:param name="day"
            select="
                $inputDateParsed[3][not(contains(., 'u'))][$month != '']"/>

        <xsl:value-of select="$year, $month, $day" separator="-"/>
    </xsl:template>

</xsl:stylesheet>
