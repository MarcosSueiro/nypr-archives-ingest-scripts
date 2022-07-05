<?xml version="1.0" encoding="UTF-8"?>
<!-- Merge or check for conflicts 
from different sources -->

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"    
    xmlns:XMP-WNYCSchema="http://ns.exiftool.ca/XMP/XMP-WNYCSchema/1.0/"
    xmlns:XML="http://ns.exiftool.ca/XML/XML/1.0/" xmlns:WNYC="http://www.wnyc.org" default-collation="http://www.w3.org/2013/collation/UCA?ignore-symbols=yes;strength=primary"
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
        <!-- Check for letters-only inconsistencies -->        
        <xsl:param name="field1"/>
        <xsl:param name="field2"/>
        <xsl:param name="field3"/>
        <xsl:param name="field4"/>
        <xsl:param name="field5"/>
        <xsl:param name="allFields" select="$field1, $field2, $field3,$field4, $field5"/>
        <xsl:param name="fieldName" select="
            $allFields[. instance of node()]/name(), 
            'noFieldName'[not($allFields[. instance of node()])]"/>        
        <xsl:param name="filename"/>
        <xsl:param name="validatingString" select="'\w'"/><!-- Needs a 'word' string -->
        <xsl:param name="separatingToken" select="$separatingToken"/>
        <xsl:param name="defaultValue">
            <xsl:element name="error">
                <xsl:attribute name="type" select="
                    'no_field_entry'"/>
                <xsl:value-of select="$fieldName[1]"/>
            </xsl:element>
        </xsl:param>
        <xsl:param name="normalize" select="true()"/>
        <xsl:message
            select="
                'Check for conflicts among values for ', $fieldName[1], ': ',
                string-join(
                (
                substring($field1[1], 1, 100),
                substring($field2[1], 1, 100),
                substring($field3[1], 1, 100),
                substring($field4[1], 1, 100),
                substring($field5[1], 1, 100)
                ),
                $separatingToken)"
        />
        
        <xsl:variable name="distinctFields">
            <xsl:call-template name="splitParseValidate">
                <xsl:with-param name="input">
                    <xsl:value-of select="string-join(
                        ($field1, $field2, $field3, $field4, $field5), 
                        $separatingToken)"/>
                </xsl:with-param>
                <xsl:with-param name="separatingToken" select="
                    $separatingToken"/>
                <xsl:with-param name="validatingString" select="
                    $validatingString"/>
                <xsl:with-param name="normalize" select="$normalize"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="distinctFound" select="
            $distinctFields/inputParsed/valid"/>
        <xsl:variable name="distinctFoundCount" select="
            count($distinctFound)"/>
        <xsl:message>
            <xsl:value-of select="
                $distinctFoundCount, ' distinct values for ',
                $fieldName, ' found: '"/>
            <xsl:value-of select="
                $distinctFound/substring(., 1, 100)" separator="
                {$separatingToken}"/>
        </xsl:message>
        <xsl:variable name="distinctFoundSorted">
            <xsl:for-each select="distinct-values($distinctFound)">
                <xsl:sort select="."/>
                <valid>
                    <xsl:copy-of select="."/>
                </valid>
            </xsl:for-each>
        </xsl:variable>
        <!-- Check for basic matching of just letters -->
        <!-- Disregard upper and lowercase -->
        <!-- Disregard accents, umlauts and other modifiers -->
        <!-- See collation info at 
        https://saxonica.com/html/documentation/extensibility/config-extend/collation/ -->
        <xsl:variable name="basicCheck">
            <xsl:for-each select="$distinctFound[position() != last()]">
                <xsl:variable name="nextField" select="following-sibling::*[1]"/>
                <xsl:element name="compare">
                    <xsl:attribute name="field" select="."/>
                    <xsl:attribute name="nextField" select="$nextField"/>
                    <!-- We compare just letters -->
                    <xsl:value-of select="
                        compare(WNYC:justLetters(.), WNYC:justLetters($nextField)
                        , 
                        'http://www.w3.org/2013/collation/UCA?ignore-symbols=yes;strength=primary'
                        )"/>
                </xsl:element>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="checkConflictResult">
            <!-- Generate error for 
            fields that do not match 
            at their most basic -->
            <xsl:for-each select="$basicCheck/compare[. != 0]">
                <xsl:element name="error">
                    <xsl:attribute name="type"
                        select="'conflicting_values'"/>
                    <xsl:value-of select="'conflicting values for', 
                        $fieldName, 
                        ' in ', $filename, ': '"/>
                    <xsl:value-of select="
                        @field, @nextField" separator="
                        {$separatingToken}"/>
                </xsl:element>
            </xsl:for-each>
            
            <xsl:choose>
                <!-- Only one distinct value; pass-through -->
                <xsl:when test="$distinctFoundCount lt 1">                    
                    <xsl:copy-of select="$defaultValue"/>
                </xsl:when>
                <!-- Output the data-richest field -->
                <!-- E.g. prefer Le Carré to Le Carre -->
                <xsl:otherwise>
                    <xsl:value-of select="$distinctFoundSorted/valid[last()]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:copy-of select="$checkConflictResult"/>
        <xsl:variable name="checkConflictResultLength" select="string-length($checkConflictResult)"/>
        <xsl:variable name="checkConflictResultIsLong" select="$checkConflictResultLength gt 100"/>
        <xsl:message>
            <xsl:value-of select="'Chosen value for ', $fieldName, ': ', substring($checkConflictResult, 1, 100)"/>
            <xsl:value-of select="' . . .'[$checkConflictResultIsLong]"/>
        </xsl:message>
    </xsl:template>

    <xsl:template name="mergeData" 
        match="inputs" 
        mode="mergeData">
        
        <!-- Check for data inconsistencies -->
        
        <xsl:param name="field1"/>
        <xsl:param name="field2"/>
        <xsl:param name="field3"/>
        <xsl:param name="field4"/>
        <xsl:param name="field5"/>
        <xsl:param name="allFields" select="$field1, $field2, $field3,$field4, $field5"/>
        <xsl:param name="fieldName" select="
            $allFields[. instance of node()]/name(), 
            'noFieldName'[not($allFields[. instance of node()])]"/>    
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
                        $field1, $field2, $field3, $field4, $field5" 
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

    <xsl:template name="field1MustContainField2">
        <!-- Generate error if field1
        does not contain field2 -->
        <xsl:param name="field1"/>
        <xsl:param name="field2"/>
        <xsl:param name="field1Name" select="local-name($field1)"/>
        <xsl:param name="field2Name" select="local-name($field2)"/>
        <xsl:param name="normalizedField1" select="
            normalize-space(
            WNYC:stripNonASCII(
            $field1
            ))"/>
        <xsl:param name="normalizedField2" select="
            normalize-space(
            WNYC:stripNonASCII(
            ($field2)
            ))"/>
        <xsl:if test="
            not(
            contains(
            $normalizedField1, $normalizedField2
            ))">
            <xsl:variable name="errorMessage">
                <xsl:value-of select="concat(
                    '&#10;&#13;',
                    'ERROR: ',
                    '&#10;&#13;')"/>
                <xsl:copy-of select="$field1"/>
                <xsl:value-of select="$separatingTokenForFreeTextFields"/>
                <xsl:value-of select="'&#10;&#13;**** DOES NOT CONTAIN ****&#10;&#13;'"/>
                <xsl:copy-of select="$field2"/>
            </xsl:variable>
                
            <xsl:element name="error">
                <xsl:attribute name="type">
                    <xsl:value-of select="concat($field1Name, 'NotContains', $field2Name)"/>
                </xsl:attribute>
                <xsl:copy-of select="$errorMessage"/>
            </xsl:element>
            <xsl:message terminate="no" select="$errorMessage"/>
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
