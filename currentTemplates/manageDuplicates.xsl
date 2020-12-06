<?xml version="1.0" encoding="UTF-8"?>
<!-- Merge or check for conflicts 
from different sources -->

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:XMP-x="http://ns.exiftool.ca/XMP/XMP-x/1.0/"
    xmlns:XMP-xmp="http://ns.exiftool.ca/XMP/XMP-xmp/1.0/"
    xmlns:XMP-xmpDM="http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/"
    xmlns:XMP-xmpMM="http://ns.exiftool.ca/XMP/XMP-xmpMM/1.0/"
    xmlns:XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/"
    xmlns:XMP-WNYCSchema="http://ns.exiftool.ca/XMP/XMP-WNYCSchema/1.0/"
    xmlns:XMP-exif="http://ns.exiftool.ca/XMP/XMP-exif/1.0/" xmlns:lc="http://www.loc.gov/"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:et="http://ns.exiftool.ca/1.0/" et:toolkit="Image::ExifTool 10.82"
    xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/"
    xmlns:XMP-plus="http://ns.exiftool.ca/XMP/XMP-plus/1.0/"
    xmlns:XML="http://ns.exiftool.ca/XML/XML/1.0/" xmlns:WNYC="http://www.wnyc.org"
    exclude-result-prefixes="#all">

    <xsl:import href="trimStrings.xsl"/>
    <xsl:import href="utilities.xsl"/>
    
    <xsl:variable name="separatingToken" select="';'"/>
    <xsl:variable name="separatingTokenLong" select="
        concat(' ', $separatingToken, ' ')"/>
    <!-- To avoid semicolons separating a single field -->
    <xsl:variable name="separatingTokenForFreeTextFields"
        select="
        '###===###'"/>
    
    <xsl:template name="checkConflicts" 
        match="inputs" 
        mode="checkConflicts">
        
        <!-- Check for data inconsistencies -->
        
        <xsl:param name="field1" select="dummyNode"/>
        <xsl:param name="field2" select="dummyNode"/>
        <xsl:param name="field3" select="dummyNode"/>
        <xsl:param name="field4" select="dummyNode"/>
        <xsl:param name="field5" select="dummyNode"/>
        <xsl:param name="fieldName" select="name($field1(.!='')[1])"/>
        <xsl:param name="filename" select=".//System:FileName"/>
        <xsl:param name="validatingString" select="''"/>
        <xsl:param name="separatingToken" select="$separatingToken"/>
        <xsl:param name="defaultValue">
            <xsl:element name="error">
                <xsl:attribute name="type" select="
                        'no_field_entry'"/>
                <xsl:value-of select="$fieldName[1]"/>
            </xsl:element>
        </xsl:param>
        <xsl:message select="'
            Check for conflicts among values for ', $fieldName[1], ': ', 
            string-join(
            ($field1, $field2, $field3, $field4, $field5), 
            $separatingToken)"/>

        <xsl:variable name="distinctFields">
            <xsl:call-template name="splitParseValidate">
                <xsl:with-param name="input">
                    <xsl:value-of select="string-join(
                        ($field1, $field2, $field3, $field4, $field5), 
                        $separatingToken)"/>
                </xsl:with-param>
                <xsl:with-param name="separatingToken" select="$separatingToken"/>
                <xsl:with-param name="validatingString" select="
                    $validatingString"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:message>
            SPLIT PARSE VALIDATE
                <xsl:value-of select="
                    $field1 | 
                    $field2 | 
                    $field3 | 
                    $field4 | 
                    $field5" 
                    separator="{$separatingToken}"/>
            VALIDATING STRING
            <xsl:value-of 
            select="
                $validatingString"/>
        </xsl:message>        
        <xsl:variable name="distinctFoundCount" select="
            count($distinctFields/inputParsed/valid)"/>
        <xsl:message>
            <xsl:value-of select="
                $distinctFoundCount, ' distinct values for ',
                $fieldName, ' found: '"/>
            <xsl:value-of select="
                $distinctFields/inputParsed/valid" separator="
                {$separatingToken}"/>
        </xsl:message>
        <xsl:variable name="checkConflictResult">
        <xsl:choose>
            <xsl:when test="$distinctFoundCount eq 1">                
                <xsl:value-of select="$distinctFields/inputParsed/valid"/>
            </xsl:when>
            <xsl:when test="$distinctFoundCount lt 1">                
                <xsl:copy-of select="$defaultValue"/>
            </xsl:when>            
            <xsl:when test="$distinctFoundCount gt 1">
                <xsl:element name="error">
                    <xsl:attribute name="type"
                        select="'conflicting_values'"/>
                    <xsl:value-of select="'conflicting values for', 
                        $fieldName, 
                        ' in ', $filename, ': '"/>
                    <xsl:value-of select="
                        $distinctFields/inputParsed/valid" separator="
                        {$separatingToken}"/>
                </xsl:element>
            </xsl:when>
        </xsl:choose>
        </xsl:variable>
        <xsl:copy-of select="$checkConflictResult"/>
        <xsl:message select="$checkConflictResult"/>
    </xsl:template>

    <xsl:template name="mergeData" 
        match="inputs" 
        mode="mergeData">
        
        <!-- Check for data inconsistencies -->
        
        <xsl:param name="field1" select="dummyNode"/>
        <xsl:param name="field2" select="dummyNode"/>
        <xsl:param name="field3" select="dummyNode"/>
        <xsl:param name="field4" select="dummyNode"/>
        <xsl:param name="field5" select="dummyNode"/>
        <xsl:param name="fieldName" select="name($field1(.!='')[1])"/>
        <xsl:param name="validatingString" select="''"/>
        <xsl:param name="separatingToken" select="$separatingToken"/>
        <xsl:param name="defaultValue">
            <xsl:element name="error">
                <xsl:attribute name="type" select="
                    'no_field_entry'"/>
                <xsl:value-of select="$fieldName[1]"/>
            </xsl:element>
        </xsl:param>
        
        <xsl:variable name="distinctFields">
            <xsl:call-template name="splitParseValidate">
                <xsl:with-param name="input">
                    <xsl:value-of select="
                        $field1 | 
                        $field2 | 
                        $field3 | 
                        $field4 | 
                        $field5" 
                        separator="{$separatingToken}"/>
                </xsl:with-param>
                <xsl:with-param name="separatingToken" select="$separatingToken"/>
                <xsl:with-param name="validatingString" select="
                    $validatingString"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="distinctValid" select="
            $distinctFields/inputParsed/valid[. ne '']"/>       
        <xsl:variable name="distinctValidCount" select="
            count($distinctValid)"/>
        <xsl:message select="
            'Merge ',
            $distinctValidCount, ' distinct valid values for ',
            $fieldName, ': ', 
            $distinctValid"/>
        <xsl:choose>
            <xsl:when test="$distinctValidCount gt 0">                
                <xsl:value-of 
                    select="$distinctValid" 
                    separator="{$separatingTokenLong}"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$defaultValue"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="checkFields" mode="exactMatch"
        match="." >
        <!-- Terminate if two normalised fields 
            are not identical -->
        <xsl:param name="field1"/>
        <xsl:param name="field2"/>

        <xsl:if 
            test="not(
            normalize-space($field1) 
            eq normalize-space($field2)
            )">
            <xsl:variable name="errorMessage" 
                select="
                concat(
                'ERROR: ', 
                $field1, ' and ', $field2, 
                ' are not equal.'
                )"/>
            <xsl:value-of 
                select="$errorMessage"/>
            <xsl:message terminate="yes" select="$errorMessage"/>                
        </xsl:if>
    </xsl:template>

    <xsl:template name="field1MustContainField2" 
        match="/" mode="field1MustContainField2">
        <!-- Terminate if field1
        does not contain field2 -->
        <xsl:param name="field1"/>
        <xsl:param name="field2"/>        

        <xsl:if test="not(contains($field1, $field2))">
            <xsl:variable name="errorMessage" select="
                concat(
                'ERROR: ', 
                $field1, ' does not contain ', $field2
                )"/>
            <xsl:value-of select="$errorMessage"/>
            <xsl:message terminate="yes" select="$errorMessage"/>                
        </xsl:if>
    </xsl:template>

    <xsl:template name="field1MustNotContainField2" 
        match="/" mode="field1MustNotContainField2">
        <!-- Terminate if field 1
        contains field 2-->
        <xsl:param name="field1"/>
        <xsl:param name="field2"/>

        <xsl:if test="contains($field1, $field2)">
            <xsl:variable name="errorMessage" select="
                concat(
                'ERROR: ', 
                $field1, ' contains ', $field2
                )"/>
            <xsl:value-of select="$errorMessage"/>
            <xsl:message terminate="yes" select="$errorMessage"/>
        </xsl:if>
    </xsl:template>

    <!--<xsl:template name="stopDuplicates">
        <!-\- Merge two fields
        into single non-repeating field-\->
        <xsl:param name="field1"/>
        <xsl:param name="field2"/>
        <xsl:param name="token" select="';'"/>
        <xsl:param name="longToken" select="concat(' ', $token, ' ')"/>

        <xsl:param name="normalizedField1">
            <xsl:call-template name="recursive-out-trim">
                <xsl:with-param name="input" select="$field1"/>
                <xsl:with-param name="endStr" select="$token"/>
            </xsl:call-template>
        </xsl:param>

        <xsl:param name="normalizedField2">
            <xsl:call-template name="recursive-in-trim">
                <xsl:with-param name="input" select="$field2"/>
                <xsl:with-param name="startStr" select="$token"/>
            </xsl:call-template>
        </xsl:param>

        <xsl:param name="mergedFields">
            <xsl:choose>
                <xsl:when test="not(normalize-space($normalizedField1))">
                    <xsl:value-of select="$normalizedField2"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="string-join((normalize-space($normalizedField1), normalize-space($normalizedField2)), $longToken)"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>

        <xsl:param name="newMergedFields"/>

        <xsl:message select="concat('Field 1: ', $field1)"/>
        <xsl:message select="concat('Field 2: ', $field2)"/>
        <xsl:message select="concat('Merged fields: ', $mergedFields)"/>


        <xsl:variable name="firstField">
            <xsl:call-template name="recursive-out-trim">
                <xsl:with-param name="input"
                    select="normalize-space(substring-before(normalize-space($mergedFields), $token))"/>
                <xsl:with-param name="endStr" select="$token"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="restOfFields">
            <xsl:call-template name="recursive-in-trim">
                <xsl:with-param name="input"
                    select="normalize-space(substring-after(normalize-space($mergedFields), $token))"/>
                <xsl:with-param name="startStr" select="$token"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when
                test="normalize-space($firstField) = '' or (normalize-space($firstField) = $token)">
                <xsl:message>**merging is done**</xsl:message>
                <xsl:variable name="trimmedNewMergedFields">
                    <xsl:call-template name="recursive-out-trim">
                        <xsl:with-param name="input" select="$newMergedFields"/>
                        <xsl:with-param name="endStr" select="$token"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="mergedOutput">
                    <xsl:value-of
                        select="string-join((normalize-space($trimmedNewMergedFields), normalize-space($mergedFields)), $longToken)"
                    />
                </xsl:variable>

                <xsl:variable name="trimmedInMergedOutput">
                    <xsl:call-template name="recursive-in-trim">
                        <xsl:with-param name="input" select="$mergedOutput"/>
                        <xsl:with-param name="startStr" select="$token"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="trimmedMergedOutput">
                    <xsl:call-template name="recursive-out-trim">
                        <xsl:with-param name="input" select="$trimmedInMergedOutput"/>
                        <xsl:with-param name="endStr" select="';'"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:message select="concat('Output: ', $trimmedMergedOutput)"/>

            </xsl:when>

            <xsl:when test="contains($restOfFields, $firstField)">
                <xsl:message terminate="yes"
                    select="concat('DUPLICATE FIELDS!!&#10;   ', $firstField, ' is included in ', $restOfFields, '. This is not allowed.')"
                />
            </xsl:when>
            <xsl:when test="not(contains($restOfFields, $firstField))">
                <xsl:call-template name="stopDuplicates">
                    <xsl:with-param name="mergedFields" select="normalize-space($restOfFields)"/>
                    <xsl:with-param name="newMergedFields"
                        select="string-join((normalize-space($newMergedFields), normalize-space($firstField)), $longToken)"
                    />
                </xsl:call-template>
            </xsl:when>
        </xsl:choose>

        <!-\-<xsl:value-of select="normalize-space($newMergedFields)"/>-\->
    </xsl:template>-->

</xsl:stylesheet>
