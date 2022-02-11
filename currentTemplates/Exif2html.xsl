<?xml version="1.0" encoding="UTF-8"?>
<!-- Transform an exiftool xml document
    to a promotional html document
    that includes links to cavafy
    and links to entries
    25 and 50 years ago -->

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" 
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"    
    xmlns:xi="http://www.w3.org/2001/XInclude"    
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#" 
    xmlns:ASCII="https://www.ecma-international.org/publications/standards/Ecma-094.htm"
    default-collation="http://www.w3.org/2013/collation/UCA?ignore-symbols=yes;strength=primary"
    exclude-result-prefixes="#all">

    <xsl:import href="cavafySearch.xsl"/>
    
    <!--Output definitions -->
    <xsl:output encoding="UTF-8" method="html" version="4.0" indent="yes"/>    

    <xsl:param name="todaysDate" select="current-date()"/>
    <xsl:param name="todaysDateFormatted"
        select="format-date($todaysDate, '[Y0001]-[M01]-[D01]')"/>
    <xsl:param name="validatingSubjectString" select="'id.loc.gov'"/>
    <xsl:param name="defaultPersons"
        select="
            'id.loc.gov/authorities/names/n81047053|id.loc.gov/authorities/names/no98091861|id.loc.gov/authorities/names/n85268774'"
    />
    <xsl:template match="rdf:RDF" mode="html">
        <!-- Create the overall html template,
        including the 25 and 50 yrs ago buttons -->
        <xsl:param name="todaysDate" select="$todaysDate"/>
        <xsl:variable name="twentyFiveYearResult">
            <xsl:call-template name="anniversaries">
                <xsl:with-param name="xYears" select="25"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="fiftyYearResult">
            <xsl:call-template name="anniversaries">
                <xsl:with-param name="xYears" select="50"/>
            </xsl:call-template>
        </xsl:variable>

        <html>
            <head>
                <link href="
                    https://fonts.googleapis.com/css?family=Open+Sans&amp;display=swap" rel="
                    stylesheet"/>
                <title>
                    <xsl:value-of select="
                        'Newly added Archives items for', 
                        $todaysDateFormatted"/>
                </title>
                <style>
                    h2 {
                        font-family: Open Sans;
                        font-weight: bold
                    }
                    h3 {
                        color: #d3008c;
                        font-family: Open Sans;
                        font-weight: medium
                    }
                    p1 {
                        text-indent: 50px;
                        font-family: Open Sans;
                        font-weight: book;
                        color: #000000
                    }
                    *:link {
                        text-decoration: none;
                        color: #128cf4
                    }
                    a:hover {
                        color: #128cf4;
                        text-decoration: underline
                    }
                    *:visited {
                        color: #de1e3d
                    }</style>
            </head>
            <body>
                <h2 align="center">New Items in the NYPR Archives</h2>
                <div align="center" font-size="book"
                    >Below are some newly added archives items. 
                    Click on the links to explore by date, people or subjects.
                    Have fun, and
                        <a
                        href="
                        mailto:msueiro@wnyc.org&amp;subject=Suggestions for Archives newly-added list&amp;body=Here's a suggestion for your newly-added list: "
                        >send suggestions</a>!</div>
                
                <xsl:if
                    test="
                    $twentyFiveYearResult[not(*[//local-name() = 'error'])]
                    ">
                    <xsl:variable name="
                        twentyFiveYrCavafySearchString" select="
                        $twentyFiveYearResult//@searchString"/>
                    <div align="center">
                        <button type="button">
                            <a
                                href="{$twentyFiveYrCavafySearchString}"
                                >Twenty-five years ago today</a>
                        </button>
                    </div>
                </xsl:if>
                <xsl:if
                    test="
                    $fiftyYearResult[not(*[//local-name() = 'error'])]
                    ">
                    <xsl:variable name="
                        fiftyYrCavafySearchString" select="
                        $fiftyYearResult//@searchString"/>
                    <div align="center">
                        <button type="button">
                            <a href="
                                {$fiftyYrCavafySearchString}"
                                >Fifty years ago today</a>
                        </button>
                    </div>
                </xsl:if> 
                
                <xsl:for-each-group select="rdf:Description" group-by="RIFF:Source">
                    <xsl:variable name="assetTitle" select="
                        current-group()/RIFF:Title/
                        tokenize(., ', part ', 'i')[1]"/>
                    <xsl:variable name="assetDescription" select="
                        current-group()/RIFF:Subject/
                        tokenize(., 'Part.{1,4}of: \n', 'i')[last()]"/>
                    <xsl:variable name="distinctAssetDescriptions">
                        <xsl:value-of select="distinct-values($assetDescription)" separator="{&#xD; }"/>
                    </xsl:variable>
                    <h3 style="color:red; ">
                        <a href="{RIFF:Source}">
                            <xsl:value-of select="distinct-values($assetTitle)" separator=" ; "/>
                        </a>
                    </h3>
                    <div style="font-family:Open Sans; font-weight:book; color:#000000; font-size:small; margin-top:-15px">
                        <div style="padding-left:20px; line-height:110%">
                            <xsl:value-of select="
                                replace(ASCII:ASCIIFier($distinctAssetDescriptions), '[\n&#xD;]+', '&lt;br/&gt;')" disable-output-escaping="yes"/>
                        </div>
                        <xsl:if
                            test="
                            not(
                            contains(
                            RIFF:Comment, 'Date is approximate'
                            ))">
                            <div style="margin-top:15px">
                                
                                <i>
                                    <xsl:value-of select="'Date: '"/>
                                </i>
                                <a
                                    href="{concat(
                                    'https://cavafy.wnyc.org/assets?q=', 
                                    RIFF:DateCreated, 
                                    '&amp;search_fields%5B%5D=date'
                                    )}">
                                    <xsl:value-of select="RIFF:DateCreated"/>
                                </a>
                            </div>
                        </xsl:if>
                        
                        <xsl:variable name="parsedArtists" select="
                            current-group()/RIFF:Artist/analyze-string(., ';'
                            )
                            /fn:non-match"/>
                        <xsl:variable name="parsedCommissioned" select="
                            current-group()/RIFF:Commissioned/analyze-string(., ';'
                            )
                            /fn:non-match"/>
                        <xsl:variable name="parsedPersons" select="
                            $parsedArtists, $parsedCommissioned"/>
                        <xsl:variable name="distinctPersons" select="
                            distinct-values(
                            $parsedPersons
                            /normalize-space(.)
                            )"/>
                        <xsl:variable name="distinctNonDefaultPersons" select="
                            $distinctPersons
                            [not (matches(., $defaultPersons))]
                            "/> <!-- WNYC, WQXR, MUNI are default and need not be listed -->
                        
                        <xsl:if
                            test="normalize-space($distinctNonDefaultPersons[1]) ne ''">
                            <div> 
                                <i>With: </i>
                                <xsl:for-each select="$distinctNonDefaultPersons[position() eq 1]">
                                    <xsl:variable name="personURL"
                                        select="
                                        normalize-space(
                                        concat(normalize-space(.), '.rdf')
                                        )"/>
                                    <xsl:variable name="personData" select="
                                        document($personURL)"/>
                                    <xsl:variable name="personName"
                                        select="$personData
                                        /rdf:RDF
                                        /madsrdf:*
                                        /madsrdf:authoritativeLabel"/>
                                    <xsl:variable name="personURLName" select="
                                        encode-for-uri($personName)"/>
                                    <xsl:variable name="cavafyPersonSearchString"
                                        select="concat(
                                        'https://cavafy.wnyc.org/assets?q=%22',
                                        $personURLName,
                                        '%22&amp;search_fields%5B%5D=creator', 
                                        '&amp;search_fields%5B%5D=contributor', 
                                        '&amp;search_fields%5B%5D=publisher'
                                        )"
                                    /> 
                                    <a href="{$cavafyPersonSearchString}">
                                        <xsl:value-of select="$personName"/>
                                    </a>
                                </xsl:for-each>
                                <xsl:for-each select="$distinctNonDefaultPersons
                                    [position() gt 1]">
                                    <xsl:variable name="personURL"
                                        select="
                                        normalize-space(
                                        concat(
                                        normalize-space(.), '.rdf')
                                        )"/>
                                    <xsl:variable name="personData" select="
                                        document($personURL)"/>
                                    <xsl:variable name="personName"
                                        select="$personData
                                        /rdf:RDF
                                        /madsrdf:*
                                        /madsrdf:authoritativeLabel"/>
                                    <xsl:variable name="personURLName" select="
                                        encode-for-uri($personName)"/>
                                    <xsl:variable name="cavafyPersonSearchString"
                                        select="
                                        concat(
                                        'https://cavafy.wnyc.org/assets?q=%22',
                                        $personURLName,
                                        '%22&amp;search_fields%5B%5D=creator', 
                                        '&amp;search_fields%5B%5D=contributor', 
                                        '&amp;search_fields%5B%5D=publisher'
                                        )"
                                    /> 
                                    ; <a href="{$cavafyPersonSearchString}">
                                        <xsl:value-of select="$personName"/>
                                    </a>
                                </xsl:for-each>
                            </div>
                        </xsl:if>
                        
                        <xsl:variable name="validKeywords"
                            select="
                            current-group()/
                            RIFF:Keywords
                            [contains(., $validatingSubjectString)]/fn:analyze-string(., 
                            ';'
                            )"/>
                        <xsl:variable name="parsedKeywords" select="
                            distinct-values(
                            $validKeywords
                            /fn:non-match
                            /normalize-space(.)
                            [not (matches(.,  
                            'id.loc.gov/authorities/subjects/sh85061212'))]
                            )"/><!-- 'History' is a deprecated default term -->
                        <xsl:if
                            test="normalize-space($parsedKeywords[1]) ne ''">
                            <div> <i>Subject headings: </i>
                                <xsl:for-each
                                    select="$parsedKeywords[position() eq 1]">
                                    <xsl:variable name="keywordURL"
                                        select="
                                        normalize-space(
                                        concat(normalize-space(.), '.rdf')
                                        )"/>                            
                                    <xsl:variable name="keywordData" select="
                                        document($keywordURL)"/>
                                    <xsl:variable name="keywordName"
                                        select="$keywordData
                                        /rdf:RDF
                                        /madsrdf:*
                                        /madsrdf:authoritativeLabel"/>
                                    <xsl:variable name="keywordURLName"
                                        select="encode-for-uri($keywordName)"/>
                                    <xsl:variable name="cavafyKeywordSearchString"
                                        select="
                                        concat(
                                        'https://cavafy.wnyc.org/assets?q=%22',
                                        $keywordURLName,
                                        '%22&amp;search_fields%5B%5D=subject')"
                                    /> 
                                    
                                    <a href="{$cavafyKeywordSearchString}">
                                        <xsl:value-of select="$keywordName"/>
                                    </a>
                                </xsl:for-each> 
                                <xsl:for-each
                                    select="$parsedKeywords[position() gt 1]">
                                    <xsl:variable name="keywordURL"
                                        select="normalize-space(
                                        concat(normalize-space(.), '.rdf')
                                        )"/>                            
                                    <xsl:variable name="keywordData" select="
                                        document($keywordURL)"/>
                                    <xsl:variable name="keywordName"
                                        select="$keywordData
                                        /rdf:RDF
                                        /madsrdf:*
                                        /madsrdf:authoritativeLabel"/>
                                    <xsl:variable name="keywordURLName"
                                        select="encode-for-uri($keywordName)"/>
                                    <xsl:variable name="cavafyKeywordSearchString"
                                        select="
                                        concat(
                                        'https://cavafy.wnyc.org/assets?q=%22',
                                        $keywordURLName,
                                        '%22&amp;search_fields%5B%5D=subject'
                                        )"
                                    /> 
                                    
                                    ; <a href="{$cavafyKeywordSearchString}">
                                        <xsl:value-of select="$keywordName"/>
                                    </a>
                                </xsl:for-each> 
                            </div>
                        </xsl:if>
                        <aside>
                            <small> Formats added: <xsl:value-of select="File:FileType"/>.
                                <xsl:value-of select="distinct-values(
                                    current-group()/RIFF:SourceForm
                                    [not(contains(.,'audio material'))])" separator="; "/>
                            </small>
                            
                            
                            <xsl:variable name="emailSubject">
                                <xsl:value-of
                                    select="
                                    concat(
                                    '[ARCHIVE-REQUEST]', 
                                    ' Please%20send%20item%20',
                                    RIFF:Source
                                    )"
                                />
                            </xsl:variable>
                            
                            <p>
                                <button>
                                    <small>
                                        <a
                                            href="{concat(
                                            'mailto:msueiro@wnyc.org?', 
                                            'cc=alanset@wnyc.org&amp;subject=',
                                            $emailSubject,
                                            '&amp;body=This material is needed for:'
                                            )}"
                                            >Request!</a>
                                    </small>
                                </button>
                            </p>
                        </aside>
                    </div>
                </xsl:for-each-group>
                
                
            </body>
        </html>

    </xsl:template>

    <xsl:template match="rdf:Description" mode="html">
        <!-- Process each file at the asset level -->
        

        <!--assets -->
        
            <h3 style="color:red; ">
                <a href="{RIFF:Source}">
                    <xsl:value-of select="RIFF:Title" separator=" ; "/>
                </a>
            </h3>
            
            <div style="font-family:Open Sans; font-weight:book; color:#000000; font-size:small; margin-top:-15px">
                <div style="padding-left:20px; line-height:110%">
                <xsl:value-of select="
                    replace(ASCII:ASCIIFier(RIFF:Subject), '[\n&#xD;]+', '&lt;br/&gt;')" disable-output-escaping="yes"/>
                </div>
                <xsl:if
                    test="
                        not(
                        contains(
                        RIFF:Comment, 'Date is approximate'
                        ))">
                    <div style="margin-top:15px">

                        <i>
                            <xsl:value-of select="'Date: '"/>
                        </i>
                        <a
                            href="{concat(
                                'https://cavafy.wnyc.org/assets?q=', 
                                RIFF:DateCreated, 
                                '&amp;search_fields%5B%5D=date'
                                )}">
                            <xsl:value-of select="RIFF:DateCreated"/>
                        </a>
                    </div>
                </xsl:if>
               
                <xsl:variable name="parsedArtists" select="
                    analyze-string(
                    RIFF:Artist, ';'
                    )
                    /fn:non-match"/>
                <xsl:variable name="parsedCommissioned" select="
                    analyze-string(
                    RIFF:Commissioned, ';'
                    )
                    /fn:non-match"/>
                <xsl:variable name="parsedPersons" select="
                    $parsedArtists, $parsedCommissioned"/>
                <xsl:variable name="distinctPersons" select="
                    distinct-values(
                    $parsedPersons
                    /normalize-space(.)
                    )"/>
                <xsl:variable name="distinctNonDefaultPersons" select="
                    $distinctPersons
                    [not (matches(., $defaultPersons))]
                    "/> <!-- WNYC, WQXR, MUNI are default and need not be listed -->
                                
                <xsl:if
                    test="normalize-space($distinctNonDefaultPersons[1]) ne ''">
                    <div> 
                        <i>With: </i>
                        <xsl:for-each select="$distinctNonDefaultPersons[position() eq 1]">
                            <xsl:variable name="personURL"
                                select="
                                normalize-space(
                                concat(normalize-space(.), '.rdf')
                                )"/>
                            <xsl:variable name="personData" select="
                                document($personURL)"/>
                            <xsl:variable name="personName"
                                select="$personData
                                /rdf:RDF
                                /madsrdf:*
                                /madsrdf:authoritativeLabel"/>
                            <xsl:variable name="personURLName" select="
                                encode-for-uri($personName)"/>
                            <xsl:variable name="cavafyPersonSearchString"
                                select="concat(
                                'https://cavafy.wnyc.org/assets?q=%22',
                                $personURLName,
                                '%22&amp;search_fields%5B%5D=creator', 
                                '&amp;search_fields%5B%5D=contributor', 
                                '&amp;search_fields%5B%5D=publisher'
                                )"
                            /> 
                            <a href="{$cavafyPersonSearchString}">
                                <xsl:value-of select="$personName"/>
                            </a>
                        </xsl:for-each>
                        <xsl:for-each select="$distinctNonDefaultPersons
                            [position() gt 1]">
                            <xsl:variable name="personURL"
                                select="
                                normalize-space(
                                concat(
                                normalize-space(.), '.rdf')
                                )"/>
                            <xsl:variable name="personData" select="
                                document($personURL)"/>
                            <xsl:variable name="personName"
                                select="$personData
                                /rdf:RDF
                                /madsrdf:*
                                /madsrdf:authoritativeLabel"/>
                            <xsl:variable name="personURLName" select="
                                encode-for-uri($personName)"/>
                            <xsl:variable name="cavafyPersonSearchString"
                                select="
                                concat(
                                'https://cavafy.wnyc.org/assets?q=%22',
                                $personURLName,
                                '%22&amp;search_fields%5B%5D=creator', 
                                '&amp;search_fields%5B%5D=contributor', 
                                '&amp;search_fields%5B%5D=publisher'
                                )"
                            /> 
                            ; <a href="{$cavafyPersonSearchString}">
                                <xsl:value-of select="$personName"/>
                            </a>
                        </xsl:for-each>
                    </div>
                </xsl:if>

                <xsl:variable name="validKeywords"
                    select="
                    analyze-string(
                    RIFF:Keywords
                    [contains(., $validatingSubjectString)], 
                    ';'
                    )"/>
                <xsl:variable name="parsedKeywords" select="
                    distinct-values(
                    $validKeywords
                    /fn:non-match
                    /normalize-space(.)
                    [not (matches(.,  
                    'id.loc.gov/authorities/subjects/sh85061212'))]
                    )"/><!-- 'History' is a deprecated default term -->
                <xsl:if
                    test="normalize-space($parsedKeywords[1]) ne ''">
                    <div> <i>Subject headings: </i>
                        <xsl:for-each
                            select="$parsedKeywords[position() eq 1]">
                            <xsl:variable name="keywordURL"
                                select="
                                normalize-space(
                                concat(normalize-space(.), '.rdf')
                                )"/>                            
                            <xsl:variable name="keywordData" select="
                                document($keywordURL)"/>
                            <xsl:variable name="keywordName"
                                select="$keywordData
                                /rdf:RDF
                                /madsrdf:*
                                /madsrdf:authoritativeLabel"/>
                            <xsl:variable name="keywordURLName"
                                select="encode-for-uri($keywordName)"/>
                            <xsl:variable name="cavafyKeywordSearchString"
                                select="
                                concat(
                                'https://cavafy.wnyc.org/assets?q=%22',
                                $keywordURLName,
                                '%22&amp;search_fields%5B%5D=subject')"
                            /> 
                            
                            <a href="{$cavafyKeywordSearchString}">
                                <xsl:value-of select="$keywordName"/>
                            </a>
                        </xsl:for-each> 
                        <xsl:for-each
                            select="$parsedKeywords[position() gt 1]">
                            <xsl:variable name="keywordURL"
                                select="normalize-space(
                                concat(normalize-space(.), '.rdf')
                                )"/>                            
                            <xsl:variable name="keywordData" select="
                                document($keywordURL)"/>
                            <xsl:variable name="keywordName"
                                select="$keywordData
                                /rdf:RDF
                                /madsrdf:*
                                /madsrdf:authoritativeLabel"/>
                            <xsl:variable name="keywordURLName"
                                select="encode-for-uri($keywordName)"/>
                            <xsl:variable name="cavafyKeywordSearchString"
                                select="
                                concat(
                                'https://cavafy.wnyc.org/assets?q=%22',
                                $keywordURLName,
                                '%22&amp;search_fields%5B%5D=subject'
                                )"
                            /> 
                            
                            ; <a href="{$cavafyKeywordSearchString}">
                               <xsl:value-of select="$keywordName"/>
                            </a>
                        </xsl:for-each> 
                    </div>
                </xsl:if>
                <aside>
                    <small> Formats added: <xsl:value-of select="File:FileType"/>.
                                <xsl:value-of select="
                                    RIFF:SourceForm
                                    [not(contains(.,'audio material'))]"/>
                    </small>
                    
                
                <xsl:variable name="emailSubject">
                    <xsl:value-of
                        select="
                        concat(
                        '[ARCHIVE-REQUEST]', 
                        ' Please%20send%20item%20',
                        RIFF:Source
                        )"
                    />
                </xsl:variable>
                
                    <p>
                        <button>
                            <small>
                            <a
                                href="{concat(
                                'mailto:msueiro@wnyc.org?', 
                                'cc=alanset@wnyc.org&amp;subject=',
                                $emailSubject,
                                '&amp;body=This material is needed for:'
                                )}"
                                >Request!</a>
                            </small>
                        </button>
                    </p>
                </aside>
            </div>
        
    </xsl:template>
</xsl:stylesheet>
