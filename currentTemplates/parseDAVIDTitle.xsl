<?xml version="1.0" encoding="UTF-8"?>
<!-- Check and parse a DAVID title or filename 
using the pattern COLL-SERI-YYYY-MM-DD-12345.6 [generation] [MUNIID] [free text]-->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:XMP="http://ns.exiftool.ca/XMP/XMP/1.0/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html" exclude-result-prefixes="#all">

    <xsl:import href="processCollection.xsl"/>    

    <!-- Parse an NYPR Archives-conforming DAVID title -->
    <xsl:param name="maxCharacters" select="79"/>

    <!-- NYPR naming convention -->
    <!-- COLL-SERI-YYYY-MM-DD-12345.2[a][_TK1-8] [Free text] -->
    <!-- Mandatory elements -->
    <xsl:variable name="collectionAcronymRegex" select="'[A-Z0-9]{3,5}'"/>
    <xsl:variable name="seriesAcronymRegex" select="'[A-Z0-9]{2,5}'"/>
    <xsl:variable name="yearRegex" select="'[12u][0123456789u]{3}'"/>
    <xsl:variable name="monthRegex" select="'[01u][0123456789u]'"/>
    <xsl:variable name="dayRegex" select="'[0123u][0123456789u]'"/>
    <xsl:variable name="assetNoRegex" select="'[0-9]{4,}'"/>
    <xsl:variable name="instLevelSuffixRegex" select="'[0-9]+'"/>
    
    <!-- Optional elements -->
    <xsl:variable name="instSegmentRegex" select="'[a-z]{0,2}'"/>
    <xsl:variable name="multitrackRegex" select="'((_TK)?[0-9]{1,2}(-[0-9]{1,2})*)*'"/>
    <xsl:variable name="freeTextRegex" select="'( [\w ])*'"/>
    
    <!-- Combined elements -->
    <xsl:variable name="instIDRegex">
        <xsl:value-of select="$assetNoRegex"/>
        <xsl:value-of select="'\.'"/>
        <xsl:value-of select="$instLevelSuffixRegex"/>
        <xsl:value-of select="$instSegmentRegex"/>
        <xsl:value-of select="$multitrackRegex"/>
    </xsl:variable>

    <xsl:variable name="nyprNamingConvention">
        <!-- Complete NYPR Archives DAVID Title Regexp -->
        <!-- Test at https://xsltfiddle.liberty-development.net/pNvtBH6/7 -->

        <xsl:value-of select="'^'"/>
        <xsl:value-of
            select="
                string-join(
                ($collectionAcronymRegex,
                $seriesAcronymRegex,
                $yearRegex,
                $monthRegex,
                $dayRegex,
                $assetNoRegex
                ), '-'
                )"/>
        <xsl:value-of select="'\.'"/>
        <xsl:value-of select="$instLevelSuffixRegex"/>
        <xsl:value-of select="$instSegmentRegex"/>
        <xsl:value-of select="$multitrackRegex"/>
        <xsl:value-of select="$freeTextRegex"/>
    </xsl:variable>
    
    <!-- Flags that indicate
    the audio file is not an original -->
    <xsl:param name="copyFlags"
        select="
            'WEB EDIT|MONO EQ|MONO EDIT|RESTORED|ACLIP|EXCERPT'"/>

    <!-- Flags that indicate
    the audio file is not a complete asset -->
    <xsl:param name="segmentFlags" select="
        'ACLIP|SEGMENT|EXCERPT|INCOMPLETE'"/>

    <!-- Flags that indicate
    the audio file is an access copy -->
    <xsl:param name="accessFlags" select="
            'WEB EDIT|MONO EQ|MONO EDIT|RESTORED'"/>
    
    <!-- Flag that indicates
    the audio file is from a multitrack -->
    <xsl:param name="multitrackFlag" select="
        '[0-9a-z]_TK[0-9]'"/>
    
    <xsl:template name="splitDAVIDTitle" 
        match="DAVIDTitle" mode="splitDAVIDTitle">
        <!-- Split a valid DAVID Title into its components -->
        <xsl:param name="titleToSplit" select="."/>
        <xsl:message select="
            concat('Split title ', $titleToSplit)"/>
        <xsl:variable name="checkedDAVIDTitle">
            <xsl:call-template name="checkDAVIDTitle">
                <xsl:with-param name="DAVIDTitleToCheck" select="$titleToSplit"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="$checkedDAVIDTitle"/>
        <xsl:variable name="DAVIDTitleBeforeSpace" select="
            $checkedDAVIDTitle//DAVIDTitleBeforeSpace"/>
        <xsl:variable name="DAVIDTitleTokenized"
            select="
            fn:tokenize(
            $DAVIDTitleBeforeSpace, '-'
            )
            [$checkedDAVIDTitle//@DAVIDTitleComplies = 'true']"
        />
        <xsl:message select="
            'DAVID Title tokenized:', $DAVIDTitleTokenized"/>
        <xsl:variable name="parsedYear" select="
            $DAVIDTitleTokenized[3]"/>
        <xsl:variable name="parsedMonth" select="
            $DAVIDTitleTokenized[4]"/>
        <xsl:variable name="parsedDay" select="
            $DAVIDTitleTokenized[5]"/>
        <xsl:variable name="instantiationID" select="
            $DAVIDTitleTokenized[6]"/>
        <xsl:variable name="instantiationIDParsed">
            <xsl:call-template name="parseInstantiationID">
                <xsl:with-param name="instantiationID" select="
                    normalize-space($instantiationID)"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="DAVIDTitleSplit">
            <DAVIDTitleBeforeSpace>
                <xsl:value-of select="$DAVIDTitleBeforeSpace"/>
            </DAVIDTitleBeforeSpace>
            <collectionAcronym>
                <xsl:value-of select="$DAVIDTitleTokenized[1]"/>
            </collectionAcronym>
            <seriesAcronym>
                <xsl:value-of select="$DAVIDTitleTokenized[2]"/>
            </seriesAcronym>
            <parsedYear>
                <xsl:value-of select="$parsedYear"/>
            </parsedYear>
            <parsedMonth>
                <xsl:value-of select="$parsedMonth"/>
            </parsedMonth>
            <parsedDay>
                <xsl:value-of select="$parsedDay"/>
            </parsedDay>
            <DAVIDTitleDate>
                <xsl:value-of
                    select="
                    string-join(
                    ($parsedYear, $parsedMonth, $parsedDay)
                    , '-')"
                />
            </DAVIDTitleDate>
            <instantiationID>
                <xsl:value-of select="$instantiationID"/>
            </instantiationID>
            <xsl:copy-of select="$instantiationIDParsed"/>
            <assetID>
                <xsl:value-of
                    select="
                    $instantiationIDParsed/instantiationIDParsed/
                    assetID"
                />
            </assetID>
            <instantiationSuffixComplete>
                <xsl:value-of
                    select="
                    $instantiationIDParsed/instantiationIDParsed/
                    instantiationSuffixComplete"/>
            </instantiationSuffixComplete>
            <instantiationSuffix>
                <xsl:value-of
                    select="
                    $instantiationIDParsed/instantiationIDParsed/
                    instantiationSuffix"/>
            </instantiationSuffix>
            <instantiationSegmentSuffix>
                <xsl:value-of
                    select="$instantiationIDParsed/instantiationIDParsed/
                    instantiationSegmentSuffix"/>
            </instantiationSegmentSuffix>
            <freeText>
                <xsl:value-of
                    select="
                    substring-after(
                    $titleToSplit, $DAVIDTitleBeforeSpace
                    )"
                />
            </freeText>
        </xsl:variable>
        <xsl:message select="'DAVID Title split: ', $DAVIDTitleBeforeSpace"/>
        <xsl:copy-of select="$DAVIDTitleSplit"/>
    </xsl:template>
    
    <xsl:template name="checkDAVIDTitle" 
        match="System:FileName" mode="checkDAVIDTitle">
        <!--    
        Check whether filename or DAVID Title 
        conforms to the NYPR naming convention 
            
            'COLL-SERI-YYYY-MM-DD-xxxx.a[ Free text]'
        
        with a string length of less than 78 characters 
        and where 
        
        COLL: Collection acronym (3-4 characters)
        SERI: Series acronym (2-4 characters)
        YYYY-MM-DD: earliest known relevant date, 
                    with 'u' for unknowns
        xxxx: asset number
        xxxx.x: unique instantiation number
        -->

        <xsl:param name="filenameToCheck" select="."/>
        <xsl:param name="filenameNormalized" select="
            tokenize(
            translate(
            $filenameToCheck, '\', '/'
            ), 
            '/')
            [last()]
            "/>
        <xsl:param name="filenameExtension"
            select="
                tokenize($filenameNormalized, '[.]')[last()]"/>
        <xsl:param name="filenameNoExtensionRaw"
            select="
                substring-before(
                $filenameNormalized,
                concat('.', $filenameExtension)
                )"/>
        <xsl:param name="DAVIDTitleToCheck"
            select="
                normalize-space($filenameNoExtensionRaw)"/>
        <xsl:param name="DAVIDTitleBeforeSpace" select="
            tokenize($DAVIDTitleToCheck, ' ')[1]"/>
        <xsl:param name="maxCharacters" select="$maxCharacters"/>
        <xsl:param name="checkTitleLength">          
            <xsl:call-template name="checkTextLength">
                <xsl:with-param name="text" select="$DAVIDTitleToCheck"/>
                <xsl:with-param name="fieldName" select="'DAVIDTitle'"/>
            </xsl:call-template>
        </xsl:param>        
        <xsl:param name="titleTooLong" select="
            boolean($checkTitleLength//error)"/>
        <xsl:param name="funnyDates" select="
            contains($DAVIDTitleBeforeSpace, '-00-')"/>
        <xsl:param name="namingConventionViolation" select="
            not(matches($DAVIDTitleToCheck, $nyprNamingConvention))"/>
        <xsl:param name="illegalName" select="
            $titleTooLong or $funnyDates or $namingConventionViolation"/>
        <xsl:param name="titleTooLongMessage" select="
            ($DAVIDTitleToCheck, 'is too long')
            [$titleTooLong]"/>
        <xsl:param name="funnyDateMessage" select="
            ('Funny dates in', $DAVIDTitleBeforeSpace)
            [$funnyDates]"/>
        <xsl:param name="namingConventionViolationMessage" select="
            ($DAVIDTitleToCheck,
            '_ does not conform to the NYPR Archives naming convention.')
            [$namingConventionViolation]"/>
        <xsl:message select="'DAVID title compliance errors: ',
            $titleTooLongMessage, 
            $funnyDateMessage, 
            $namingConventionViolationMessage"/>
        <xsl:variable name="testedDAVIDTitle">
            <xsl:element name="filenameToCheck">
                <xsl:value-of select="$filenameNormalized"/>
            </xsl:element>
            <xsl:element name="DAVIDTitle">
                <xsl:value-of select="$DAVIDTitleToCheck"/>
            </xsl:element>
            <xsl:element name="filenameExtension">
                <xsl:value-of select="$filenameExtension"/>
            </xsl:element>
            <xsl:element name="DAVIDTitleBeforeSpace">
                <xsl:value-of select="$DAVIDTitleBeforeSpace"/>
            </xsl:element>
            <xsl:copy-of select="$checkTitleLength//error"/>
            <xsl:if test="$funnyDates">
                <xsl:call-template name="generateError">
                    <xsl:with-param name="errorType" select="'funnyDate'"/>
                    <xsl:with-param name="fieldName" select="'DAVIDTitle'"/>
                    <xsl:with-param name="errorMessage" select="$funnyDateMessage"/>
                </xsl:call-template>
            </xsl:if>            
            <xsl:if test="$namingConventionViolation">
                <xsl:call-template name="
                    generateError">
                    <xsl:with-param name="errorType" select="
                        'namingConventionViolation'"/>
                    <xsl:with-param name="fieldName" select="
                        'DAVIDTitle'"/>
                    <xsl:with-param name="errorMessage" select="
                        $namingConventionViolationMessage"/>
                </xsl:call-template>  
            </xsl:if>
        </xsl:variable>
        <xsl:message select="
            'Tested DAVID Title:', $testedDAVIDTitle/filenameToCheck"/>

        <!-- Output -->
        <xsl:variable name="checkedDAVIDTitle">
            <checkedDAVIDTitle>
                <xsl:attribute name="filenameNoExtension"
                    select="
                        $DAVIDTitleToCheck"/>
                <xsl:attribute name="DAVIDTitleComplies" select="not($illegalName)"/>
                <xsl:copy-of select="$testedDAVIDTitle"/>
            </checkedDAVIDTitle>
        </xsl:variable>
        <xsl:message select="'Checked DAVID Title:', 
            $checkedDAVIDTitle/checkedDAVIDTitle/
            DAVIDTitle"/>
        <xsl:copy-of select="$checkedDAVIDTitle"/>
    </xsl:template>

    <xsl:template name="determineGeneration">
        <!-- Determine generation based on text flags such as WEB EDIT, etc 
        or from the instantiation suffix (e.g. 3b means it is a segment) -->
        <!-- We consider the following Generations with two parts A:B
            A. An original master (Master:) or Derivative (Copy:)
            B. Complete (preservation or access, respectively) 
               or partial (segment) -->
        <!-- This means there are four possible generations:
           Master: preservation
           Copy: access
           Master: segment
           Copy: segment -->
           
        <!--   If the audio file comes from a multitrack, 
           the word "stream" 
           and the track number follow, e.g.
           "Master: segment stream 3" -->
        
        <xsl:param name="instantiationSuffix"/>
        <xsl:param name="freeText"/>
        <xsl:param name="copyFlags" select="$copyFlags"/>
        <xsl:param name="segmentFlags" select="$segmentFlags"/>
        <xsl:param name="accessFlags" select="$accessFlags"/>
        <xsl:param name="multitrackFlag" select="$multitrackFlag"/>
        <xsl:param name="instantiationSuffixMT" select="''"/>
        <xsl:param name="instantiationFirstTrack" select="0"/>
        <xsl:param name="instantiationLastTrack" select="0"/>
        <xsl:variable name="parsedGeneration">
        <parsedGeneration>
            <xsl:choose>
                <xsl:when
                    test="
                        matches($freeText,
                        $copyFlags)
                        ">
                    <xsl:value-of select="'Copy: '"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'Master: '"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when
                    test="
                        matches($freeText, $segmentFlags) or
                        matches(upper-case($instantiationSuffix), '[A-Z]')
                        ">
                    <xsl:value-of select="'segment'"/>
                </xsl:when>
                <xsl:when test="matches($freeText, $accessFlags)">
                    <xsl:value-of select="'access'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'preservation'"/>
                </xsl:otherwise>                
            </xsl:choose>
            <xsl:if test="$instantiationFirstTrack gt 0">
                <xsl:value-of select="concat(' stream ', $instantiationSuffixMT)"/>
            </xsl:if>
        </parsedGeneration>
        </xsl:variable>
        <xsl:copy-of select="$parsedGeneration"/>
        <xsl:message select="'Parsed generation: ', $parsedGeneration"/>
    </xsl:template>

    <xsl:template name="extractMUNINumber" match="DAVIDTitle[starts-with(., 'MUNI-')]"
        mode="extractMUNINumber">
        <!--determine MUNI number -->
        <xsl:param name="DAVIDTitle" select="."/>
        <xsl:param name="freeText" select="
                substring-after($DAVIDTitle, ' ')"/>
        <xsl:message select="'Find MUNI number in', $freeText"/>
        <xsl:variable name="muniNumbers">
            <muniNumber>
                <xsl:variable name="muniPattern">
                    <xsl:analyze-string select="$freeText" regex="\s+(L*T\d+)\s*">
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:message select="
                        'MUNI pattern found: ', $muniPattern"/>
                <xsl:choose>
                    <xsl:when test="normalize-space($muniPattern) = ''">
                        <xsl:variable name="errorMessage"
                            select="
                                'MUNI filename ', $DAVIDTitle,
                                ' is missing its MUNI T/LT number.'"/>
                        <xsl:message>
                            <xsl:value-of select="$errorMessage"/>
                        </xsl:message>
                        <xsl:element name="error">
                            <xsl:attribute name="type" select="'missing_MUNI_number'"/>
                            <xsl:value-of select="$errorMessage"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$muniPattern"/>
                    </xsl:otherwise>
                </xsl:choose>
            </muniNumber>
            <rTapeNumber>
                <xsl:variable name="rTapeNumber">
                    <xsl:analyze-string select="$freeText" regex="\s+(R*\d+)\s*">
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:value-of select="$rTapeNumber"/>
            </rTapeNumber>
        </xsl:variable>
        <xsl:copy-of select="$muniNumbers"/>
        <xsl:message select="'MUNI numbers:', $muniNumbers"/>
    </xsl:template>

    <xsl:template name="parseDAVIDTitle" 
        match="System:FileName" mode="parseDAVIDTitle">
        <!--    
        Parse a filename or DAVID Title 
        that conforms to the NYPR naming convention 
            
            'COLL-SERI-YYYY-MM-DD-xxxx.a Free text'
        
        where 
        
        COLL: Collection acronym (3-4 characters)
        SERI: Series acronym (2-4 characters)
        YYYY-MM-DD: earliest known relevant date, 
                    with 'u' for unknowns
        xxxx: asset number
        xxxx.x: unique instantiation number
        -->

        <!--        First: Is the DAVID title OK?-->
        <xsl:param name="filenameToParse" select="."/>
        <xsl:param name="filenameToParseMessage">
            <xsl:message select="
                concat('Filename to parse: ', $filenameToParse)"/>
        </xsl:param>
        <xsl:param name="checkedDAVIDTitle">
            <xsl:call-template name="checkDAVIDTitle">
                <xsl:with-param name="filenameToCheck" select="
                    $filenameToParse"/>
            </xsl:call-template>
        </xsl:param>
                
        <!-- If file is OK, parse -->
        <xsl:param name="titleToParse"
            select="
                $checkedDAVIDTitle
                [not(//error)]
                /checkedDAVIDTitle/DAVIDTitle"/>
        <xsl:param name="titleToParseMessage">
            <xsl:message select="
                concat('Title to parse: ', $titleToParse)"/>
        </xsl:param>
        <xsl:param name="DAVIDTitleBeforeSpace"
            select="
                $checkedDAVIDTitle
                [not(//error)]
                /checkedDAVIDTitle/DAVIDTitleBeforeSpace"/>
        
        <!--        Parse the DAVID Title -->
        <xsl:param name="splitDAVIDTitle">
            <xsl:apply-templates
                select="
                    $checkedDAVIDTitle
                    [not(//error)]
                    /checkedDAVIDTitle/DAVIDTitle"
                mode="splitDAVIDTitle"/>
        </xsl:param>
        <!--        First, the tokenized title -->
        <xsl:param name="collectionAcronym" select="$splitDAVIDTitle/collectionAcronym"/>
        <xsl:param name="seriesAcronym" select="$splitDAVIDTitle/seriesAcronym"/>
        <xsl:param name="parsedYear" select="$splitDAVIDTitle/parsedYear"/>
        <xsl:param name="parsedMonth" select="$splitDAVIDTitle/parsedMonth"/>
        <xsl:param name="parsedDay" select="$splitDAVIDTitle/parsedDay"/>
        <xsl:param name="DAVIDTitleDate" select="$splitDAVIDTitle/DAVIDTitleDate"/>
        <xsl:param name="instantiationID" select="$splitDAVIDTitle/instantiationID"/>
        <xsl:param name="assetID" select="$splitDAVIDTitle/assetID"/>
        <xsl:param name="instantiationSuffixComplete" select="
            $splitDAVIDTitle/instantiationIDParsed/
            instantiationSuffixComplete"/>
        <xsl:param name="instantiationSuffix" select="$splitDAVIDTitle/instantiationSuffix"/>
        <xsl:param name="instantiationSegmentSuffix" select="$splitDAVIDTitle/instantiationSegmentSuffix"/>
        <xsl:param name="instantiationSuffixMT" select="
            $splitDAVIDTitle/instantiationIDParsed/
            instantiationSuffixMT"/>
        <xsl:param name="instantiationFirstTrack" select="
            $splitDAVIDTitle/instantiationIDParsed/
            instantiationFirstTrack[matches(., '^\d+$')]" as="xs:integer?"/>
        <xsl:param name="instantiationLastTrack" select="
            $splitDAVIDTitle/instantiationIDParsed/
            instantiationLastTrack[matches(., '^\d+$')]" as="xs:integer?"/>        
        <xsl:param name="freeText" select="$splitDAVIDTitle/freeText"/>

        <!--        Now for the more involved parameters -->

        <!--        Collection info -->
        <xsl:param name="collectionInfo">
            <xsl:call-template name="processCollection">
                <xsl:with-param name="collectionAcronym" select="
                    $collectionAcronym[. !='']"/>
            </xsl:call-template>
        </xsl:param>        

        <xsl:param name="finalSeriesEntry">
            <xsl:call-template name="findSeriesXML">
                <xsl:with-param name="seriesAcronym" select="
                    $seriesAcronym"/>
            </xsl:call-template>
        </xsl:param>

        <xsl:param name="seriesName"
            select="
            $finalSeriesEntry[not(//error)]
            //pb:pbcoreTitle[@titleType = 'Series']"/>

        <!--        Date info -->

        <!-- Translate 'uu' (unknowns)
        to earliest date in possible range -->
        <xsl:param name="DAVIDTitleDateTranslated"
            select="
                concat(
                translate(
                substring($DAVIDTitleDate, 1, 1),
                'u', '1'),
                translate(
                substring($DAVIDTitleDate, 2, 5),
                'u', '0'),
                translate(
                substring($DAVIDTitleDate, 7, 2),
                'u', '1'),
                translate(
                substring($DAVIDTitleDate, 9, 1),
                'u', '0'),
                translate(
                substring($DAVIDTitleDate, 10, 1),
                'u', '1')
                )"/>

        <!--        Find the corresponding cavafy asset entry -->
        <xsl:param name="finalCavafyEntry">
            <xsl:choose>
                <xsl:when test="$checkedDAVIDTitle/checkedDAVIDTitle/filenameExtension = 'NEWASSET'">
                    <!-- This means that we are dealing with an asset,
                            so we do NOT want to wipe or merge with an old one -->
                    <xsl:call-template name="findSpecificCavafyAssetXML">
                        <xsl:with-param name="assetID" select="$assetID"/>
                        <xsl:with-param name="series" select="encode-for-uri($seriesName)"/>                        
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="findSpecificCavafyAssetXML">
                        <xsl:with-param name="assetID" select="$assetID"/>
                        <xsl:with-param name="series" select="encode-for-uri($seriesName)"/>                        
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>        
        
        <xsl:param name="filenameExtension" select="
            $checkedDAVIDTitle
            /checkedDAVIDTitle
            /filenameExtension"/>
        
        <xsl:param name="format" select="
            if 
            (upper-case($filenameExtension) = 'WAV')
            then 'BWF'
            else
            $filenameExtension"/>

        <!-- Find a matching instantiation -->
        <xsl:param name="instantiationData">
            <xsl:call-template name="findInstantiation">
                <xsl:with-param name="instantiationID"
                    select="
                        $instantiationID"/>
                <xsl:with-param name="cavafyEntry"
                    select="
                        $finalCavafyEntry"/>
                <xsl:with-param name="format" select="
                        $format"/>
            </xsl:call-template>
        </xsl:param>

        <!-- Info from free text -->
        <xsl:param name="freeTextNormalized">
            <xsl:value-of select="normalize-space($splitDAVIDTitle/freeText)"/>
        </xsl:param>

        <xsl:param name="parsedGeneration">
            <xsl:call-template name="determineGeneration">
                <xsl:with-param name="instantiationSuffix" select="$instantiationSuffix"/>
                <xsl:with-param name="freeText" select="$freeText"/>
                <xsl:with-param name="instantiationSuffixMT" select="$instantiationSuffixMT"/>
                <xsl:with-param name="instantiationFirstTrack" select="$instantiationFirstTrack[. gt 0]"/>
                <xsl:with-param name="instantiationLastTrack" select="$instantiationLastTrack[. gt 0]"/>
            </xsl:call-template>
        </xsl:param>        
        <xsl:param name="segmentFlag">
            <xsl:value-of select="
                analyze-string($freeText, $segmentFlags)/fn:match"/>
        </xsl:param>

        <xsl:param name="muniNumber">
            <xsl:apply-templates
                select="
                    $checkedDAVIDTitle
                    /checkedDAVIDTitle/DAVIDTitle[starts-with(., 'MUNI-')]"
                mode="extractMUNINumber">
                <xsl:with-param name="freeText" select="$freeText"/>
            </xsl:apply-templates>
        </xsl:param>
        
        <!--determine MUNI original format 
            based on T or LT 
            (R: tape (dub), T: tape, LT: disc)-->
        <xsl:param name="MUNIMedium"
            select="
                if (starts-with($muniNumber/rTapeNumber, 'R'))
                then
                    concat(' 1/4 inch audio tape ', $muniNumber/rTapeNumber)
                else
                    if (starts-with($muniNumber/muniNumber, 'T'))
                    then
                        concat(' 1/4 inch audio tape ', $muniNumber/muniNumber)
                    else
                        if (starts-with($muniNumber/muniNumber, 'LT'))
                        then
                            concat(' Sound disc ', $muniNumber/muniNumber)
                        else
                            ''"
        />
        <xsl:param name="MUNIMediumMessage">
            <xsl:message select="'MUNI Medium: ', $MUNIMedium"/>
        </xsl:param>
        
        
        <!--        The 'theme' field 
            is derived from the asset number 
            and is used by DAVID to publish audio -->
        <xsl:param name="theme" select="concat('archive_import', $assetID)"/>
        <xsl:param name="mp3URL"
            select="
                concat(
                'http://audio.wnyc.org/archive_import/',
                $theme, '.mp3')"/>
        <xsl:message select="concat(
            'DAVID Title ',
            '_', $titleToParse, '_', 
            ' parsed.')"/>        

        <!--    Output as 'parsedDAVIDTitle' -->
        <parsedDAVIDTitle>            
            <xsl:attribute name="DAVIDTitle" select="$titleToParse"/>
            <xsl:attribute name="isSegment" select="matches($titleToParse, $segmentFlags)"/>
            <xsl:attribute name="isMultiTrack" select="matches($titleToParse, $multitrackFlag)"/>            
            <parsedElements>
                <xsl:copy-of select="$checkedDAVIDTitle"/>
                <xsl:element name="filenameExtension">
                    <xsl:value-of select="$filenameExtension"/>
                </xsl:element>
                <xsl:element name="DAVIDTitle">
                    <xsl:value-of select="$titleToParse"/>
                </xsl:element>
                <xsl:element name="DAVIDTitleBeforeSpace">
                    <xsl:value-of select="$DAVIDTitleBeforeSpace"/>
                </xsl:element>
                <xsl:element name="collectionAcronym">
                    <xsl:value-of select="$collectionAcronym"/>
                </xsl:element>
                <xsl:element name="seriesAcronym">
                    <xsl:value-of select="$seriesAcronym"/>
                </xsl:element>
                <xsl:element name="DAVIDTitleDate">
                    <xsl:value-of select="$DAVIDTitleDate"/>
                </xsl:element>
                <xsl:element name="assetID">
                    <xsl:value-of select="$assetID"/>
                </xsl:element>
                <xsl:element name="instantiationID">
                    <xsl:value-of select="$instantiationID"/>
                </xsl:element>
                <xsl:element name="instantiationSuffixComplete">
                    <xsl:value-of select="$instantiationSuffixComplete"/>
                </xsl:element>
                <xsl:element name="instantiationSuffix">
                    <xsl:value-of select="$instantiationSuffix"/>
                </xsl:element>
                <xsl:element name="instantiationSegmentSuffix">
                    <xsl:value-of select="$instantiationSegmentSuffix"/>
                </xsl:element>                
                <xsl:element name="instantiationSuffixMT">
                    <xsl:value-of select="$instantiationSuffixMT"/>
                </xsl:element>
                <xsl:element name="instantiationFirstTrack">
                    <xsl:value-of select="$instantiationFirstTrack"/>
                </xsl:element>
                <xsl:element name="instantiationLastTrack">
                    <xsl:value-of select="$instantiationLastTrack"/>
                </xsl:element>
                <xsl:element name="freeText">
                    <xsl:value-of select="$freeText"/>
                </xsl:element>
                <xsl:element name="segmentFlag">
                    <xsl:value-of select="$segmentFlag"/>
                </xsl:element>
                <xsl:element name="parsedGeneration">
                    <xsl:value-of select="$parsedGeneration"/>
                </xsl:element>
                <xsl:element name="collectionData">
                    <xsl:copy-of select="$collectionInfo"/>
                </xsl:element>
                <xsl:element name="collectionName">
                    <xsl:value-of select="$collectionInfo/collectionInfo/collName"/>
                </xsl:element>
                <xsl:element name="seriesData">
                    <xsl:copy-of select="$finalSeriesEntry"/>
                </xsl:element>
                <xsl:element name="seriesName">
                    <xsl:value-of select="$seriesName"/>
                </xsl:element>
                <xsl:element name="DAVIDTitleDateTranslated">
                    <xsl:value-of select="$DAVIDTitleDateTranslated"/>
                </xsl:element>
                <xsl:element name="finalCavafyEntry">
                    <xsl:copy-of select="$finalCavafyEntry"/>
                </xsl:element>
                <xsl:element name="finalCavafyURL">
                    <xsl:value-of 
                        select="concat(
                        'https://cavafy.wnyc.org/assets/', 
                        $finalCavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreIdentifier[@source='pbcore XML database UUID'])"/>
                </xsl:element>
                <xsl:copy-of select="$instantiationData"/>
                <xsl:element name="normalizedFreeText">
                    <xsl:value-of select="normalize-space($freeText)"/>
                </xsl:element>
                <xsl:copy-of select="$muniNumber"/>
                <xsl:element name="MUNIMedium">
                    <xsl:value-of select="$MUNIMedium"/>
                </xsl:element>                
                <xsl:element name="theme">
                    <xsl:value-of select="$theme"/>
                </xsl:element>
                <xsl:element name="mp3URL">
                    <xsl:value-of select="$mp3URL"/>
                </xsl:element>
            </parsedElements>
        </parsedDAVIDTitle>
    </xsl:template>

    <xsl:template name="parseInstantiationID"
        match="
            instantiationID |
            newInstantiationID |
            pb:instantiationIdentifier
            [@source = 'WNYC Media Archive Label']"
        mode="parseInstantiationID">
        <!-- Parse cavafy instantiation ID -->
        <xsl:param name="instantiationID" select="
            normalize-space(.)"/>
        <xsl:param name="message">
            <xsl:message select="'Parse instantiation ID', $instantiationID"/>
        </xsl:param>
        <xsl:param name="validated"
            select="
                matches(normalize-space($instantiationID),
                concat('^', $instIDRegex, '$'))"/>
        <xsl:param name="assetID"
            select="
                substring-before($instantiationID[$validated], '.')"/>
        <xsl:param name="instantiationSuffixComplete">
            <xsl:copy-of
                select="
                    substring-after($instantiationID[$validated], '.')"/>
        </xsl:param>
        <xsl:param name="instantiationSuffix"
            select="
                tokenize($instantiationSuffixComplete[$validated], '_TK')[1]"/>
        <!-- Capture just the multitrack part of the instantiation suffix -->
        <xsl:param name="instantiationSuffixMT"
            select="
                tokenize($instantiationSuffixComplete[$validated], '_TK')[2]"/>
        <!-- Capture just the digit part of the instantiation suffix -->
        <xsl:param name="instantiationSuffixDigit">
            <xsl:value-of
                select="
                    xs:integer(analyze-string($instantiationSuffix, '\d+')//*:match[1])"
            />
        </xsl:param>
        <!-- Capture just the letter part 
      ( (aka segment suffix) 
        of the instantiation suffix 
        and make it lowercase -->
        <xsl:param name="instantiationSegmentSuffix">
            <xsl:value-of
                select="
                    analyze-string(
                    lower-case(
                    $instantiationSuffix
                    ), '[a-z]+'
                    )/*:match"
            />
        </xsl:param>
        
        <!-- instantiationID 'level', 
            i.e. sans segment suffix 
            or multitrack flag -->
        <xsl:param name="instantiationIDwOutSuffixSegment">
            <xsl:value-of select="
                concat(
                $assetID, '.', $instantiationSuffixDigit
                )"/>
        </xsl:param>
        <xsl:variable name="instantiationIDParsed">
            <instantiationIDParsed>
                <xsl:apply-templates
                    select="
                        $instantiationID[not($validated)]"
                    mode="
                    generateError">
                    <xsl:with-param name="errorMessage">
                        <error>
                            <xsl:value-of
                                select="
                                    concat(
                                    'Instantiation ID ', $instantiationID,
                                    ' is not valid.')"
                            />
                        </error>
                    </xsl:with-param>
                </xsl:apply-templates>
                <instantiationID>
                    <xsl:copy-of select="@*"/>
                    <xsl:value-of
                        select="
                            normalize-space($instantiationID[$validated])"
                    />
                </instantiationID>
                <assetID>
                    <xsl:value-of select="$assetID"/>
                </assetID>
                <instantiationSuffixComplete>
                    <xsl:value-of select="$instantiationSuffixComplete"/>
                </instantiationSuffixComplete>
                <instantiationSuffix>
                    <xsl:value-of select="$instantiationSuffix"/>
                </instantiationSuffix>
                <instantiationSuffixDigit>
                    <xsl:value-of select="number($instantiationSuffixDigit)"/>
                </instantiationSuffixDigit>
                <instantiationSegmentSuffix>
                    <xsl:value-of select="$instantiationSegmentSuffix"/>
                </instantiationSegmentSuffix>
                <instantiationIDwOutSuffixSegment>
                    <xsl:value-of select="$instantiationIDwOutSuffixSegment"/>
                </instantiationIDwOutSuffixSegment>
                <instantiationSuffixMT>
                    <xsl:value-of select="$instantiationSuffixMT"/>
                </instantiationSuffixMT>
                <instantiationFirstTrack>
                    <xsl:value-of
                        select="
                            xs:integer(
                            tokenize(
                            $instantiationSuffixMT, '-'
                            )[1]
                            [matches(., '^\d+$')])"
                    />
                </instantiationFirstTrack>
                <instantiationLastTrack>
                    <xsl:value-of
                        select="
                            xs:integer(
                            tokenize(
                            $instantiationSuffixMT, '-'
                            )
                            [last()]
                            [matches(., '^\d+$')]
                            )"
                    />
                </instantiationLastTrack>
            </instantiationIDParsed>
        </xsl:variable>
        <xsl:message>
            <xsl:value-of select="'Instantiation ID', $instantiationID, ' parsed. '"/>
<!--            <xsl:copy-of select="$instantiationIDParsed"/>-->
        </xsl:message>
        <xsl:copy-of select="$instantiationIDParsed"/>
    </xsl:template>

</xsl:stylesheet>
