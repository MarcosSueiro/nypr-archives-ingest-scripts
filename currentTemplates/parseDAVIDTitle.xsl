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

    <xsl:import href="cavafyQC.xsl"/>    

    <!-- Parse an NYPR Archives-conforming DAVID title -->
    <xsl:param name="maxCharacters" select="79"/>


    <!-- NYPR naming convention -->
    <xsl:param name="nyprNamingConvention" select="
        '^[\S]{3,5}-[\S]{2,5}-[12u][0123456789u]{3}-[01u][0123456789u]-[0123u][0123456789u]-[0-9]{4,}\.[0-9][\S]{0,3}'"/>
    
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

        <xsl:param name="filenameNoExtensionNormalized"
            select="
                normalize-space($filenameNoExtensionRaw)"/>

        <xsl:param name="DAVIDTitleToCheck"
            select="
                normalize-space($filenameNoExtensionRaw)"/>

        <xsl:param name="DAVIDTitleBeforeSpace" select="tokenize($DAVIDTitleToCheck, ' ')[1]"/>

        <xsl:param name="maxCharacters" select="$maxCharacters"/>
        <xsl:variable name="titleTooLong">          
            <xsl:call-template name="checkTextLength">
                <xsl:with-param name="text" select="$DAVIDTitleToCheck"/>
                <xsl:with-param name="fieldName" select="'DAVIDTitle'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="funnyDates" select="
            contains($DAVIDTitleBeforeSpace, '-00-')"/>

        <xsl:variable name="namingConventionViolation" select="
            not(matches($DAVIDTitleToCheck, $nyprNamingConvention))"/>
        <xsl:variable name="illegalName" select="
            $titleTooLong or $funnyDates or $namingConventionViolation"/>
        <xsl:variable name="titleTooLongMessage" select="
            ($DAVIDTitleToCheck, 'is too long')
            [$titleTooLong]"/>
        <xsl:variable name="funnyDateMessage" select="
            ('Funny dates in', $DAVIDTitleBeforeSpace)
            [$funnyDates]"/>
        <xsl:variable name="namingConventionViolationMessage" select="
            ($DAVIDTitleToCheck,
            '_ does not conform to the NYPR Archives naming convention.')
            [$namingConventionViolation]"/>
        

        <xsl:variable name="checkedDAVIDTitle">
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
            <xsl:copy-of select="$titleTooLong"/>
            <xsl:apply-templates select="$DAVIDTitleToCheck[$funnyDates]" mode="generateError">
                <xsl:with-param name="errorType" select="'funnyDate'"/>
                <xsl:with-param name="fieldName" select="'DAVIDTitle'"/>
                <xsl:with-param name="errorMessage" select="$funnyDateMessage"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="$DAVIDTitleToCheck[$namingConventionViolation]" mode="generateError">
                <xsl:with-param name="errorType" select="'namingConventionViolation'"/>
                <xsl:with-param name="fieldName" select="'DAVIDTitle'"/>
                <xsl:with-param name="errorMessage" select="$namingConventionViolationMessage"/>
            </xsl:apply-templates>
            
        </xsl:variable>

        <!-- Output -->
        <checkedDAVIDTitle>
            <xsl:attribute name="filenameNoExtension" select="$DAVIDTitleToCheck"/>
            <xsl:attribute name="DAVIDTitleComplies"
                select="not($illegalName)"/>
            <xsl:copy-of select="$checkedDAVIDTitle"/>
        </checkedDAVIDTitle>
    </xsl:template>

    <xsl:template name="splitDAVIDTitle" 
        match="DAVIDTitle" mode="splitDAVIDTitle">
        <!-- Split a DAVID Title into its components -->

        <xsl:param name="titleToSplit" select="."/>

        <xsl:message select="
            concat('Split title ', $titleToSplit)"/>

        <!--        Parse the DAVID Title -->
        <xsl:variable name="DAVIDTitleBeforeSpace" select="
            tokenize($titleToSplit, ' ')[1]"/>

        <xsl:message select="
            'Title before space: ', 
            $DAVIDTitleBeforeSpace"/>

        <DAVIDTitleBeforeSpace>
            <xsl:value-of select="$DAVIDTitleBeforeSpace"/>
        </DAVIDTitleBeforeSpace>

        <xsl:variable name="DAVIDTitleTokenized" select="
            fn:tokenize($DAVIDTitleBeforeSpace, '-')"/>

        <collectionAcronym>
            <xsl:value-of select="$DAVIDTitleTokenized[1]"/>
        </collectionAcronym>
        <seriesAcronym>
            <xsl:value-of select="$DAVIDTitleTokenized[2]"/>
        </seriesAcronym>
        <xsl:variable name="parsedYear" select="$DAVIDTitleTokenized[3]"/>
        <xsl:variable name="parsedMonth" select="$DAVIDTitleTokenized[4]"/>
        <xsl:variable name="parsedDay" select="$DAVIDTitleTokenized[5]"/>
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
            <xsl:value-of select="
                string-join(
                ($parsedYear, $parsedMonth, $parsedDay)
                , '-')"/>
        </DAVIDTitleDate>
        <xsl:variable name="instantiationID" select="
            $DAVIDTitleTokenized[6]"/>
        <xsl:variable name="instantiationIDParsed">
            <xsl:apply-templates select="$instantiationID" mode="parseInstantiationID"/>
        </xsl:variable>
        <instantiationID>
            <xsl:value-of select="$instantiationID"/>
        </instantiationID>
        <xsl:copy-of select="$instantiationIDParsed"/>        
        <assetID>
            <xsl:value-of select="
                substring-before($instantiationID, '.')"/>
        </assetID>
        <xsl:variable name="instantiationSuffix">
            <xsl:value-of select="
                substring-after($instantiationID, '.')"/>
        </xsl:variable>
        <instantiationSuffix>
            <xsl:value-of select="$instantiationSuffix"/>
        </instantiationSuffix>
        <instantiationSegmentSuffix>
            <xsl:value-of select="
                analyze-string($instantiationSuffix, '\p{L}')
                /fn:match"/>
        </instantiationSegmentSuffix>
        <freeText>
            <xsl:value-of select="
                substring-after(
                $titleToSplit, $DAVIDTitleBeforeSpace
                )"/>
        </freeText>
    </xsl:template>

    <xsl:template name="determineGeneration">
        <!-- Determine generation based on text flags such as WEB EDIT, etc 
        or from the instantiation suffix (e.g. 3b means part 2) -->
        <!-- We conisder the following Generations with two parts A:B
            A. An original master (Master:) or Derivative (Copy:)
            B. Complete (preservation or access, respectively) 
               or partial (segment)
        This means there are four possible generations:
           Master: preservation
           Copy: access
           Master: segment
           Copy: segment
        -->
        <xsl:param name="instantiationSuffix"/>
        <xsl:param name="freeText"/>
        <xsl:param name="copyFlags" select="$copyFlags"/>
        <xsl:param name="segmentFlags" select="$segmentFlags"/>
        <xsl:param name="accessFlags" select="$accessFlags"/>
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
        </parsedGeneration>
    </xsl:template>

    <xsl:template name="extractMUNINumber" 
        match="DAVIDTitle[starts-with(., 'MUNI-')]"
        mode="extractMUNINumber">
        <!--determine MUNI number -->
        <xsl:param name="DAVIDTitle" select="."/>
        <xsl:param name="freeText" select="
            substring-after($DAVIDTitle, ' ')"/>
        <xsl:message select="'Find MUNI number in', $freeText"/>
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

        <xsl:param name="checkedDAVIDTitle">
            <xsl:call-template name="checkDAVIDTitle">
                <xsl:with-param 
                    name="filenameToCheck" 
                    select="$filenameToParse"/>
            </xsl:call-template>
        </xsl:param>
        <!-- If file is OK, parse -->

        <xsl:param name="titleToParse"
            select="
                $checkedDAVIDTitle
                [not(//error)]
                /checkedDAVIDTitle/DAVIDTitle"/>

        <xsl:param name="DAVIDTitleBeforeSpace"
            select="
                $checkedDAVIDTitle
                [not(//error)]
                /checkedDAVIDTitle/DAVIDTitleBeforeSpace"/>

        <xsl:message select="
            concat('Filename to parse: ', $filenameToParse)"/>
        <xsl:message select="
            concat('Title to parse: ', $titleToParse)"/>

        <!--        Parse the DAVID Title -->

        <xsl:variable name="splitDAVIDTitle">
            <xsl:apply-templates
                select="
                    $checkedDAVIDTitle
                    [not(//error)]
                    /checkedDAVIDTitle/DAVIDTitle"
                mode="splitDAVIDTitle"/>
        </xsl:variable>

        <!--        First, the tokenized title -->
        <xsl:variable name="DAVIDTitleTokenized" select="fn:tokenize($DAVIDTitleBeforeSpace, '-')"/>
        <xsl:variable name="collectionAcronym" select="$splitDAVIDTitle/collectionAcronym"/>
        <xsl:variable name="seriesAcronym" select="$splitDAVIDTitle/seriesAcronym"/>
        <xsl:variable name="parsedYear" select="$splitDAVIDTitle/parsedYear"/>
        <xsl:variable name="parsedMonth" select="$splitDAVIDTitle/parsedMonth"/>
        <xsl:variable name="parsedDay" select="$splitDAVIDTitle/parsedDay"/>
        <xsl:variable name="DAVIDTitleDate" select="$splitDAVIDTitle/DAVIDTitleDate"/>
        <xsl:variable name="instantiationID" select="$splitDAVIDTitle/instantiationID"/>
        <xsl:variable name="assetID" select="$splitDAVIDTitle/assetID"/>
        <xsl:variable name="instantiationSuffix" select="$splitDAVIDTitle/instantiationSuffix"/>
        <xsl:variable name="instantiationSegmentSuffix" select="$splitDAVIDTitle/instantiationSegmentSuffix"/>
        <xsl:variable name="freeText" select="$splitDAVIDTitle/freeText"/>



        <!--        Now for the more involved parameters -->

        <!--        Collection info -->
        <xsl:variable name="collectionInfo">
            <xsl:call-template name="processCollection">
                <xsl:with-param name="collectionAcronym" select="
                    $collectionAcronym[. !='']"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:message select="$collectionInfo"/>

        <xsl:variable name="finalSeriesEntry">
            <xsl:call-template name="findSeriesXML">
                <xsl:with-param name="seriesAcronym" select="
                    $seriesAcronym"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="seriesName"
            select="
            $finalSeriesEntry[not(//error)]
            //pb:pbcoreTitle[@titleType = 'Series']"/>

        <!--        Date info -->

        <!-- Translate 'uu' (unknowns)
        to earliest date in possible range -->
        <xsl:variable name="DAVIDTitleDateTranslated"
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
        <xsl:variable name="finalCavafyEntry">
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
        </xsl:variable>

        <xsl:message select="
            'Final cavafy entry', 
            $finalCavafyEntry"/>
        
        <xsl:variable name="filenameExtension" select="
            $checkedDAVIDTitle
            /checkedDAVIDTitle
            /filenameExtension"/>
        
        <xsl:variable name="format" select="
            if 
            (upper-case($filenameExtension) = 'WAV')
            then 'BWF'
            else
            $filenameExtension"/>

        <!--            Find a matching instantiation -->
        <xsl:variable name="instantiationData">
            <xsl:call-template name="findInstantiation">
                <xsl:with-param name="instantiationID" select="
                    $instantiationID"/>
                <xsl:with-param name="cavafyEntry" select="
                    $finalCavafyEntry"/>
                <xsl:with-param name="format" select="
                    $format"/>
            </xsl:call-template>
        </xsl:variable>

        <!--        Info from free text -->
        <xsl:variable name="freeTextNormalized">
            <xsl:value-of select="normalize-space($splitDAVIDTitle/freeText)"/>
        </xsl:variable>

        <xsl:variable name="parsedGeneration">
            <xsl:call-template name="determineGeneration">
                <xsl:with-param name="instantiationSuffix" select="$instantiationSuffix"/>
                <xsl:with-param name="freeText" select="$freeText"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:message select="'Parsed generation:', $parsedGeneration"/>
        
        <xsl:variable name="segmentFlag">
            <xsl:value-of select="
                analyze-string($freeText, $segmentFlags)/fn:match"/>
        </xsl:variable>

        <xsl:variable name="muniNumber">
            <xsl:apply-templates
                select="
                    $checkedDAVIDTitle
                    /checkedDAVIDTitle/DAVIDTitle[starts-with(., 'MUNI-')]"
                mode="extractMUNINumber">
                <xsl:with-param name="freeText" select="$freeText"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:message select="
            'MUNI Number:', $muniNumber"/>

        <!--determine MUNI original format 
            based on T or LT 
            (R: tape (dub), T: tape, LT: disc)-->
        <xsl:variable name="MUNIMedium"
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
        <xsl:message select="'MUNI Medium: ', $MUNIMedium"/>
        
        <!--        The 'theme' field 
            is derived from the asset number 
            and is used by DAVID to publish audio -->
        <xsl:variable name="theme" select="concat('archive_import', $assetID)"/>
        <xsl:variable name="mp3URL"
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
            <parsedElements>
                <xsl:copy-of select="$checkedDAVIDTitle[//error]"/>
                <xsl:element name="filenameExtension">
                    <xsl:value-of select="$checkedDAVIDTitle/checkedDAVIDTitle/filenameExtension"/>
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
                <xsl:element name="instantiationSuffix">
                    <xsl:value-of select="$instantiationSuffix"/>
                </xsl:element>
                <xsl:element name="instantiationSegmentSuffix">
                    <xsl:value-of select="$instantiationSegmentSuffix"/>
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

<xsl:template match="
        instantiationID | 
        pb:instantiationIdentifier
        [@source = 'WNYC Media Archive Label']" mode="parseInstantiationID">
        <!-- Parse cavafy instantiaion ID -->
        <xsl:param name="instantiationID" select="."/>
        <xsl:param name="validated" select="
            matches(normalize-space($instantiationID), '^\d+\.\d+\p{L}*$')"/>
        <xsl:param name="assetID" select="
            substring-before($instantiationID[$validated], '.')"/>
        <xsl:param name="instantiationSuffix">
            <xsl:copy-of select="substring-after($instantiationID[$validated], '.')"/>
        </xsl:param>
        <!-- Capture just the digit part of the instantiation suffix -->
        <xsl:param name="instantiationSuffixDigit">
            <xsl:value-of select="
                xs:integer(analyze-string($instantiationSuffix, '\d+')//*:match)"/>
        </xsl:param>
        <!-- Capture just the letter part 
      (aka segment suffix) 
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
        <!-- instantiationID sans suffix segment -->
        <xsl:param name="instantiationIDwOutSuffixSegment">
            <xsl:value-of
                select="concat($assetID, '.', $instantiationSuffixDigit)"
            />
        </xsl:param>
        <xsl:variable name="instantiationIDParsed">
            <instantiationIDParsed>
                <xsl:apply-templates select="$instantiationID[not($validated)]" mode="generateError">
                    <xsl:with-param name="errorMessage">
                        <error>
                            <xsl:value-of select="'Instantiation ID', $instantiationID, 'is not valid.'"/>
                        </error>
                    </xsl:with-param>
                </xsl:apply-templates>
                <instantiationID>
                    <xsl:value-of select="
                        normalize-space($instantiationID[$validated])"/>
                </instantiationID>
                
                <assetID>
                    <xsl:value-of select="$assetID"/>
                </assetID>
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
            </instantiationIDParsed>
        </xsl:variable>
        <xsl:copy-of select="$instantiationIDParsed"/>
        
    </xsl:template>

</xsl:stylesheet>
