<?xml version="1.0" encoding="UTF-8"?>

<!-- Convert output from exiftool
to a pbcore cavafy entry -->

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xsi:schemaLocation="http://www.pbcore.org/PBCore/PBCoreNamespace.html 
    http://pbcore.org/xsd/pbcore-2.0.xsd"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:et="http://ns.exiftool.ca/1.0/"
    et:toolkit="Image::ExifTool 9.46" xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:XMP-x="http://ns.exiftool.ca/XMP/XMP-x/1.0/"
    xmlns:XMP-xmp="http://ns.exiftool.ca/XMP/XMP-xmp/1.0/"
    xmlns:XMP-xmpDM="http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/"
    xmlns:XMP-xmpMM="http://ns.exiftool.ca/XMP/XMP-xmpMM/1.0/"
    xmlns:XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/"
    xmlns:XMP-WNYCSchema="http://ns.exiftool.ca/XMP/XMP-WNYCSchema/1.0/"
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/"
    xmlns:ns2="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:ns8="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:ns9="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:XMP-plus="http://ns.exiftool.ca/XMP/XMP-plus/1.0/"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    xmlns:WNYC="http://www.wnyc.org"
    xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html" exclude-result-prefixes="#all">

    <xsl:import href="selectionOrExcerpt.xsl"/>    
    <xsl:import href="parseDAVIDTitle.xsl"/>
    <xsl:import href="processLoCURL.xsl"/>

    <xsl:param name="exifInput"/>
    
    <xsl:variable name="cavafyFormats" select="
        doc('cavafyFormats.xml')"/>
    <xsl:variable name="EBUCodingAlgorithm" select="
        'ANALOG|ANALOGUE|PCM|MPEG1L1|MPEG1L2|MPEG1L3|MPEG2L1|MPEG2L2|MPEG2L3'"/>
    <xsl:variable name="EBUSamplingFrequency" select="
        '11000|22050|24000|32000|44100|48000|96000|176400|192000|384000|768000'"/>
    <xsl:variable name="EBUWordLength" select="
        '8|12|14|16|18|20|22|24|32'"/>
    <xsl:variable name="EBUMode" select="
        'mono|stereo|dual-mono|joint-stereo|multitrack|multichannel|surround'"/>
    <xsl:variable name="EBUText" select="'^[^,]+$'"/>
    
    <xsl:template match="rdf:RDF" mode="cavafy">
        <!-- Wrap all entries as a 'pbcoreCollection' -->
        <xsl:element name="pbcoreCollection">
            <xsl:namespace name="" select="'http://www.pbcore.org/PBCore/PBCoreNamespace.html'"/>
            <xsl:namespace name="xsi" select="'http://www.w3.org/2001/XMLSchema-instance'"/>
            <xsl:attribute name="xsi:schemaLocation"
                select="'http://pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd'"/>
            <xsl:apply-templates select="rdf:Description" mode="cavafy"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="rdf:Description" mode="cavafy">
        <!-- Process each exiftool entry -->
        <xsl:param name="catalogURL">
            <xsl:value-of select="normalize-space(RIFF:Source)"/>
        </xsl:param>
        <xsl:param name="catalogxml">
            <xsl:value-of select="string(concat($catalogURL, '.xml'))"/>
        </xsl:param>
        <xsl:param name="cavafyEntry">
            <xsl:copy-of select="document($catalogxml)"/>
        </xsl:param>
        <xsl:param name="isWAV" select="
            upper-case(File:FileType) eq 'WAV'"/>       
        <xsl:param name="isDub" select="not(RIFF:Medium
             = 'Original')"/>
        <xsl:param name="parsedDAVIDTitle">
            <!-- Parse DAVID title or filename -->
            <xsl:choose>
                <xsl:when test="File:FileType = 'NEWASSET'">
                    <xsl:apply-templates select="System:FileName" mode="parseDAVIDTitle">
                        <xsl:with-param name="filenameToParse" select="System:FileName"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="matches(System:Directory, 'ARCHIVESNAS1/INGEST|Archives|Iron Mountain')">
                    <xsl:apply-templates select="System:FileName" mode="parseDAVIDTitle"/>
                </xsl:when>
                <xsl:when test="contains(System:Directory, 'wnycdavidmedia')">
                    <xsl:message select="'DAVID File'"/>
                    <xsl:apply-templates select="System:FileName" mode="parseDAVIDTitle">
                        <xsl:with-param name="filenameToParse"
                            select="concat(RIFF:Description, '.', File:FileType)"/>
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>
        </xsl:param>
        <xsl:message
            select="'Parsed new asset agaiiiiiiin*************************************', $parsedDAVIDTitle"/>

        <!--Collection -->
        <!--Embedded collection is of the type 'US, WNYC' 
                    So we look after the comma -->
        <xsl:variable name="collectionAcronym">
            <xsl:value-of
                select="
                    RIFF:ArchivalLocation/
                    normalize-space(substring-after(., ','))"
            />
        </xsl:variable>

        <!-- Asset ID -->
        <xsl:variable name="assetID">
            <xsl:value-of 
                select="
                $parsedDAVIDTitle/parsedDAVIDTitle
                /parsedElements/assetID"/>
        </xsl:variable>

        <!-- Instantiation ID -->
        <xsl:variable name="instantiationID">
            <xsl:value-of 
                select="
                $parsedDAVIDTitle/parsedDAVIDTitle
                /parsedElements/instantiationID"
            />
        </xsl:variable>
        
        <xsl:variable name="instantiationData">
            <xsl:copy-of 
                select="
                $cavafyEntry/pb:pbcoreDescriptionDocument
                /pb:pbcoreInstantiation[instantiationIdentifier[@source='WNYC Media Archive Label'] = $instantiationID]"/>
        </xsl:variable>
        
        <!-- Generation -->
        <xsl:variable name="parsedGeneration">
            <xsl:value-of 
                select="
                $parsedDAVIDTitle/parsedDAVIDTitle
                /parsedElements/parsedGeneration"
            />
        </xsl:variable>
        <xsl:variable name="cavafyGeneration">
            <xsl:value-of select="$instantiationData/
                pb:instantiationGenerations"/>
        </xsl:variable>
        <xsl:variable name="generation">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="'Generation'"/>
                <xsl:with-param name="field1" select="$parsedGeneration"/>
                <xsl:with-param name="field2" select="$cavafyGeneration"/>
                <xsl:with-param name="defaultValue" select="$parsedGeneration"/>                
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="CMSTeaseAlreadyInCavafy">
            <xsl:value-of
                select="
                $cavafyEntry/pb:pbcoreDescriptionDocument
                /pb:pbcoreDescription[@descriptionType = 'CMS Tease']"
                separator="+++++++++++++++++++++++++++++++++++++++++++"/>
        </xsl:variable>

        <xsl:variable name="DAVIDTitleDate">
            <xsl:value-of 
                select="
                $parsedDAVIDTitle/parsedDAVIDTitle
                /parsedElements/DAVIDTitleDate"
            />
        </xsl:variable>

        <!-- American Archive of Public Media variables -->
        <xsl:variable name="aapbURL">
            <xsl:choose>
                <xsl:when 
                    test="
                    starts-with(
                    RIFF:Source, 
                    'http://americanarchive.org/catalog/'
                    )">
                    <xsl:value-of select="normalize-space(rdf:Source)"/>
                </xsl:when>
                <xsl:when 
                    test="
                    contains(
                    RIFF:Comment, 
                    'http://americanarchive.org/catalog/'
                    )">
                    <xsl:value-of
                        select="
                        concat(
                        'http://americanarchive.org/catalog/', 
                        substring-before(
                        substring-after(
                        RIFF:Comment, 
                        'http://americanarchive.org/catalog/'
                        ), 
                        '.pbcore'), 
                        '.pbcore'
                        )"
                    />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="aapbData">
            <xsl:copy-of select="doc($aapbURL)"/>
        </xsl:variable>


        <!-- cavafy output -->
        <xsl:variable name="cavafyOutput">
            <xsl:element name="pbcoreDescriptionDocument"
                namespace="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
                <!-- Identifiers -->
                <!-- The identifier of type 'WNYC Archive Catalog', 
                    along with the collection name,
                    are required to import assets into cavafy -->
                <pbcoreIdentifier source="WNYC Archive Catalog">
                    <xsl:value-of select="$assetID"/>
                </pbcoreIdentifier>

                <!-- Additional MUNI ID -->
                <xsl:if test="starts-with(RIFF:Description, 'MUNI')">
                    <xsl:variable name="MuniIDsAlreadyInCavafy">
                        <xsl:value-of
                            select="
                            $cavafyEntry/pb:pbcoreDescriptionDocument
                            /pb:pbcoreIdentifier[@source = 'Municipal Archives']"
                            separator=" ; "/>
                    </xsl:variable>
                    <xsl:variable name="parsedMuniID">
                        <xsl:value-of
                            select="
                            analyze-string(
                            System:FileName, '\s+L*T+[0-9]{2,5}'
                            )
                            //fn:match[1]"
                        /></xsl:variable>

                    <xsl:if test="
                        matches(
                        RIFF:Description, 
                        '\s+L*T+[0-9]{2,5}'
                        )">
                        <xsl:if 
                            test="
                            not(
                            contains(
                            $MuniIDsAlreadyInCavafy, 
                            $parsedMuniID
                            )
                            )">
                            <pbcoreIdentifier source="Municipal Archives">
                                <xsl:value-of 
                                    select="$parsedMuniID"/>
                            </pbcoreIdentifier>
                        </xsl:if>
                    </xsl:if>
                </xsl:if>

                <!-- Dates -->
                <xsl:choose>
                    <!-- Assets published to the web 
                        need a broadcast date -->
                    <xsl:when
                        test="
                        contains(RIFF:Description, 'WEB EDIT') 
                        and 
                        not(
                        $DAVIDTitleDate eq 
                        $cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreDate[@dateType = 'broadcast']
                        )">
                        <pbcoreAssetDate dateType="broadcast">
                            <xsl:value-of select="$DAVIDTitleDate"/>
                        </pbcoreAssetDate>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if
                            test="
                            not(
                            $cavafyEntry
                            /pb:pbcoreDescriptionDocument
                            /pb:pbcoreAssetDate
                            [. eq $DAVIDTitleDate]
                            )">
                            <pbcoreAssetDate>
                                <xsl:value-of 
                                    select="$DAVIDTitleDate"/>
                            </pbcoreAssetDate>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>

                <!-- Episode and Collection Titles -->
                <xsl:if test="normalize-space(RIFF:Title) ne ''">
                    <xsl:if
                        test="
                        normalize-space(
                        $cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreTitle
                        [@titleType eq 'Episode']
                        ) eq ''
                        ">
                        <pbcoreTitle titleType="Episode">
                            <xsl:value-of 
                                select="normalize-space(RIFF:Title)"/>
                        </pbcoreTitle>
                    </xsl:if>
                </xsl:if>

                <!-- The collection name, 
                    along with the identifier 
                    of type 'WNYC Archive Catalog',
                    are necessary to import assets into cavafy -->
                <pbcoreTitle titleType="Collection">
                    <xsl:value-of select="$collectionAcronym"/>
                </pbcoreTitle>

                <pbcoreTitle titleType="Series">
                    <xsl:value-of select="normalize-space(RIFF:Product)"/>
                </pbcoreTitle>
                
                <!-- Apply asset-level fields 
                    to instantiations that are not an excerpt -->
                <xsl:if test="
                        not(contains($generation, 'segment'))">

                    <!-- CMS Tease (a short description) -->
                    <xsl:if 
                        test="
                        contains(RIFF:Description, 'WEB EDIT')
                        ">
                        <xsl:if 
                            test="
                            normalize-space($CMSTeaseAlreadyInCavafy) 
                            eq ''">
                            <pbcoreDescription descriptionType="CMS Tease">
                                <xsl:choose>
                                    <xsl:when 
                                        test="
                                        string-length(RIFF:Subject) &lt; 180">
                                        <xsl:value-of select="RIFF:Subject"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of
                                            select="
                                            concat(
                                            substring(
                                            normalize-space(
                                            RIFF:Subject
                                            ), 1, 177
                                            ), 
                                            '...')"
                                        />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </pbcoreDescription>
                        </xsl:if>
                    </xsl:if>

                    <!-- Abstract, a main description -->
                    <xsl:if
                        test="
                        normalize-space(
                        $cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreDescription
                        [@descriptionType = 'Abstract']
                        )
                        eq ''">
                        <pbcoreDescription descriptionType="Abstract">
                            <xsl:value-of select="RIFF:Subject"/>
                        </pbcoreDescription>
                    </xsl:if>

                    <!-- Markers as excerpts -->
                    <xsl:variable name="excerptsAlreadyInCavafy">
                        <xsl:for-each select="
                            $cavafyEntry/pb:pbcoreDescriptionDocument/
                            pb:pbcoreDescription
                            [@descriptionType = 'Selection or Excerpt']">
                            <xsl:value-of select="." separator="
                                {$separatingTokenForFreeTextFields}"
                            />
                        </xsl:for-each>
                        </xsl:variable>

                    <xsl:variable name="currentExcerpt">
                            <xsl:apply-templates select="XMP-xmpDM:Tracks"/>
                        </xsl:variable>
                        <xsl:message
                            select="                            
                            'Excerpts already in cavafy: ', 
                            $excerptsAlreadyInCavafy
                            "/>
                        <xsl:message select="                            
                            'Excerpt - current:', 
                            $currentExcerpt
                            "/>
                        <xsl:if
                            test="
                            not(
                            contains(
                            normalize-space($excerptsAlreadyInCavafy), 
                            normalize-space($currentExcerpt)
                            ))">
                            <pbcoreDescription descriptionType="Selection or Excerpt">
                                <xsl:choose>
                                    <xsl:when
                                        test="
                                        matches(
                                        RIFF:Description, 
                                        'WEB EDIT|MONO EQ|MONO EDIT|RESTORED')
                                        ">
                                        <xsl:value-of
                                            select="
                                            concat(
                                            'Edited file timings:&#013;', 
                                            $currentExcerpt
                                            )"
                                        />
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of
                                            select="
                                            concat(
                                            'Raw file timings:&#013;', 
                                            $currentExcerpt
                                            )"
                                        />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </pbcoreDescription>
                        </xsl:if>
                    

                    <!-- Transcripts -->
                    <xsl:variable name="transcriptAlreadyInCavafy">
                        <xsl:value-of
                            select="
                            $cavafyEntry
                            /pb:pbcoreDescriptionDocument
                            /pb:pbcoreDescription
                            [@descriptionType = 'Transcript']
                            /normalize-space(.)
                            "
                            separator="{$separatingTokenForFreeTextFields}"/>
                    </xsl:variable>

                    <xsl:if test="normalize-space(XMP-xmpDM:Lyrics)">
                        <xsl:if test="
                            not(
                            contains(
                            $transcriptAlreadyInCavafy, 
                            XMP-xmpDM:Lyrics
                            ))">
                            <pbcoreDescription descriptionType="Transcript">
                                <xsl:value-of select="XMP-xmpDM:Lyrics"/>
                            </pbcoreDescription>
                        </xsl:if>
                    </xsl:if>
                </xsl:if>

                <!-- Publish to the web -->
                <xsl:if test="contains(RIFF:Description, 'WEB EDIT')">
                    <xsl:choose>
                        <xsl:when test="$collectionAcronym eq 'WQXR'">
                            <xsl:if
                                test="
                                not(
                                $cavafyEntry
                                /pb:pbcoreDescriptionDocument
                                /pb:pbcoreRelation
                                [pb:pbcoreRelationType eq 'Is Part Of']
                                /pb:pbcoreRelationIdentifier[. eq 'CMSWQXR']
                                )">
                                <pbcoreRelation>
                                    <pbcoreRelationType>Is Part Of</pbcoreRelationType>
                                    <pbcoreRelationIdentifier>CMSWQXR</pbcoreRelationIdentifier>
                                </pbcoreRelation>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if
                                test="
                                not(
                                $cavafyEntry
                                /pb:pbcoreDescriptionDocument
                                /pb:pbcoreRelation
                                [pb:pbcoreRelationType eq 'Is Part Of']
                                /pb:pbcoreRelationIdentifier[. eq 'CMS'])">
                                <pbcoreRelation>
                                    <pbcoreRelationType>Is Part Of</pbcoreRelationType>
                                    <pbcoreRelationIdentifier>CMS</pbcoreRelationIdentifier>
                                </pbcoreRelation>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                    <pbcoreRelation>
                        <pbcoreRelationType>Website Series</pbcoreRelationType>
                        <pbcoreRelationIdentifier>
                            <xsl:choose>
                                <xsl:when
                                    test="
                                    normalize-space(RIFF:Product) = 'On the Media' 
                                    and 
                                    substring-before(RIFF:DateCreated, ':') &lt; '2001'">
                                    <xsl:value-of select="'On the Media, 1993-2000'"/>
                                </xsl:when>
                                <xsl:when test="
                                    ends-with(
                                    normalize-space(RIFF:Product),
                                    ', The'
                                    )">
                                    <xsl:value-of
                                        select="
                                        concat(
                                        'The ', 
                                        normalize-space(
                                        substring-before(
                                        RIFF:Product, ', The'
                                        )))"
                                    />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of 
                                        select="normalize-space(RIFF:Product)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </pbcoreRelationIdentifier>
                    </pbcoreRelation>
                </xsl:if>

                <!-- Relations -->
                <xsl:variable name="relationsAlreadyInCavafy">
                    <xsl:value-of
                        select="
                        $cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreRelation
                        /pb:pbcoreRelationIdentifier"
                    />
                </xsl:variable>
                
                <xsl:if
                    test="
                    normalize-space($aapbURL) 
                    and 
                    not(contains($relationsAlreadyInCavafy, $aapbURL))">
                    <pbcoreRelation>
                        <pbcoreRelationType>References</pbcoreRelationType>
                        <pbcoreRelationIdentifier>
                            <xsl:value-of select="$aapbURL"/>
                        </pbcoreRelationIdentifier>
                    </pbcoreRelation>
                </xsl:if>
                
                
                
                <!-- Location of recording -->
                <xsl:variable name="coverageAlreadyInCavafy">
                    <xsl:value-of
                        select="
                        normalize-space(
                        $cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreCoverage
                        [pb:coverageType = 'Spatial']
                        /coverage
                        )"
                    />
                </xsl:variable>

                <xsl:if test="normalize-space(XMP-dc:Coverage) ne ''">
                    <xsl:if test="
                        not(
                        contains(
                        XMP-dc:Coverage, 
                        $coverageAlreadyInCavafy
                        ))">
                        <pbcoreCoverage>
                            <coverage>
                                <xsl:choose>
                                    <xsl:when
                                        test="
                                        contains(
                                        normalize-space(
                                        XMP-dc:Coverage
                                        ),
                                        'google'
                                        )">
                                        <xsl:value-of
                                            select="
                                            concat(
                                            substring-before(
                                            substring-after(
                                            XMP-dc:Coverage,
                                            '@'), 
                                            ','), 
                                            ', ', 
                                            substring-before(
                                            substring-after(
                                            substring-after(
                                            XMP-dc:Coverage, 
                                            '@'), 
                                            ','), 
                                            ','
                                            ))"
                                        />
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of 
                                            select="XMP-dc:Coverage"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </coverage>
                            <coverageType>Spatial</coverageType>
                        </pbcoreCoverage>
                    </xsl:if>
                </xsl:if>

                <!-- Subject headings -->

                <xsl:variable name="subjectsAlreadyInCavafy">
                    <xsl:copy-of
                        select="
                        $cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreSubject
                        [contains(@ref, 'id.loc.gov')]"
                    />
                </xsl:variable>

                <xsl:message
                    select="
                        'subjects already in cavafy',
                        $subjectsAlreadyInCavafy"/>


                <xsl:variable name="locSubjects">
                    <xsl:apply-templates 
                        select="RIFF:Keywords"/>
                </xsl:variable>

                <xsl:message select="'Subjects:', $locSubjects"/>
                
                <xsl:apply-templates 
                    select="$locSubjects/rdf:RDF/
                    (
                    madsrdf:Topic |
                    madsrdf:NameTitle |
                    madsrdf:Geographic |
                    madsrdf:Name |
                    madsrdf:FamilyName |
                    madsrdf:CorporateName |
                    madsrdf:Title |
                    madsrdf:PersonalName |
                    madsrdf:ConferenceName | 
                    madsrdf:ComplexSubject
                    )" mode="LOCtoPBCore"/>
                
                <xsl:variable name="genreAlreadyInCavafy">
                    <xsl:value-of select="
                        $cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreGenre"
                    />
                </xsl:variable>
                <xsl:if test="$genreAlreadyInCavafy eq ''">
                    <pbcoreGenre source="PBCore Genre Picklist">
                        <xsl:value-of select="RIFF:Genre"/>
                    </pbcoreGenre>
                </xsl:if>
                
                <!-- CMS Image ID -->
                <xsl:variable name="cmsImageAlreadyInCavafy">
                    <xsl:value-of
                        select="$cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreAnnotation
                        [@annotationType = 'CMS Image']"
                        separator=" ; "/>
                </xsl:variable>
                <xsl:if test="XMP-plus:ImageSupplierImageID ne ''">
                    <xsl:if test="$cmsImageAlreadyInCavafy eq ''">
                        <pbcoreAnnotation annotationType="CMS Image">
                            <xsl:value-of 
                                select="XMP-plus:ImageSupplierImageID"/>
                        </pbcoreAnnotation>
                    </xsl:if>
                </xsl:if>

                <!--Adding creators -->
                <xsl:call-template name="parseContributors">
                    <xsl:with-param name="contributorsToProcess" 
                        select="RIFF:Commissioned"/>
                    <xsl:with-param name="token" select="';'"/>
                    <xsl:with-param name="contributorsAlreadyInCavafy">
                        <xsl:value-of
                            select="
                            $cavafyEntry
                            /pb:pbcoreDescriptionDocument
                            /pb:pbcoreCreator
                            /pb:creator
                            /@ref[contains(., 'id.loc.gov')]"
                            separator=" ; "/>
                    </xsl:with-param>
                    <xsl:with-param name="role" select="'creator'"/>
                </xsl:call-template>

                <!-- Adding contributors -->
                <xsl:call-template name="parseContributors">
                    <xsl:with-param name="contributorsToProcess" 
                        select="RIFF:Artist"/>
                    <xsl:with-param name="token" select="';'"/>
                    <xsl:with-param name="contributorsAlreadyInCavafy">
                        <xsl:value-of
                            select="
                            $cavafyEntry
                            /pb:pbcoreDescriptionDocument
                            /pb:pbcoreContributor
                            /pb:contributor
                            /@ref[contains(., 'id.loc.gov')]"
                            separator=" ; "/>
                    </xsl:with-param>
                    <xsl:with-param name="role" select="'contributor'"/>
                </xsl:call-template>
                
                <!-- Add Engineers -->
                <xsl:apply-templates select="RIFF:Engineer
                    [not(matches(., 'Unknown', 'i'))]" mode="pbcore"/>
                

                <!-- Copyright info -->
                <xsl:variable name="copyrightAlreadyInCavafy">
                    <xsl:value-of
                        select="
                        normalize-space(
                        $cavafyEntry
                        /pb:pbcoreDescriptionDocument
                        /pb:pbcoreRightsSummary
                        /pb:rightsSummary
                        )"
                    />
                </xsl:variable>
                <xsl:message 
                    select="'Copyright in cavafy: ', 
                    $copyrightAlreadyInCavafy"/>
                <xsl:if test="$copyrightAlreadyInCavafy = ''">
                    <pbcoreRightsSummary>
                        <rightsSummary>
                            <xsl:value-of 
                                select="
                                normalize-space(RIFF:Copyright)
                                "/>
                        </rightsSummary>
                    </pbcoreRightsSummary>
                </xsl:if>

                <xsl:choose>
                    <xsl:when test="File:FileType = 'NEWASSET'">
                        <pbcoreAnnotation annotationType="Provenance">
                            <xsl:value-of 
                                select="
                                normalize-space(RIFF:Comment)
                                "/>
                        </pbcoreAnnotation>
                    </xsl:when>
                    
                    <!-- Indicates fake Exif instantiation -->
                    
                    <xsl:when test="
                        RIFF:NumChannels = '0' or 
                        RIFF:SampleRate = '1000' or 
                        RIFF:BitsPerSample = '8'">
                        <!-- Do nothing -->                        
                    </xsl:when>
                    <xsl:otherwise>

                        <!-- instantiations -->

                        <pbcoreInstantiation>
                            <instantiationIdentifier source="WNYC Media Archive Label">
                                <xsl:value-of select="$instantiationID"/>
                            </instantiationIdentifier>
                            <!-- DAVID Title -->
                            <xsl:apply-templates
                                select="
                                    RIFF:Description
                                    [$isWAV]"
                                mode="pbcore"/>
                            <xsl:apply-templates select="
                                System:FileCreateDate[$isWAV]" mode="pbcore"/>                            
                            <xsl:apply-templates select="
                                WNYC:instantiation_physical_label" mode="pbcore"/>
                            <xsl:apply-templates select="
                                WNYC:instantiation_issued_date" mode="pbcore"/>
                            <xsl:apply-templates select="
                                WNYC:instantiation_date" mode="pbcore"/>
                            <xsl:apply-templates select="
                                WNYC:instantiation_created_date" mode="pbcore"/>
                            <xsl:choose>
                                <xsl:when test="$isWAV">
                                    <instantiationDigital>
                                        <xsl:value-of select="'BWF'"/>
                                    </instantiationDigital>
                                </xsl:when>
                                <xsl:otherwise>
                                    <instantiationPhysical>
                                        <xsl:value-of select="File:FileType"/>
                                    </instantiationPhysical>
                                </xsl:otherwise>
                            </xsl:choose>
                            
                            <instantiationLocation>
                                <xsl:call-template name="checkConflicts">
                                    <xsl:with-param name="fieldName"
                                        select="
                                            'instantiationLocation'"/>
                                    <xsl:with-param name="field1"
                                        select="
                                            normalize-space(
                                            System:Directory
                                            [contains(., 'Levy')]
                                            )"/>
                                    <xsl:with-param name="defaultValue">
                                        <xsl:value-of select="'DAVID'[$isWAV]"/>
                                        <xsl:value-of select="'Archives storage'[not($isWAV)]"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </instantiationLocation>
                            <instantiationMediaType>Sound</instantiationMediaType>
                            <xsl:if test="$isDub">
                                <instantiationGenerations>
                                    <xsl:value-of select="$generation"/>
                                </instantiationGenerations>
                            </xsl:if>
                            <xsl:apply-templates select="
                                System:FileSize[$isWAV]" mode="pbcore"/>
                            <xsl:apply-templates select="
                                Composite:Duration" mode="pbcore"/>
                            <xsl:apply-templates select="
                                RIFF:AvgBytesPerSec" mode="pbcore"/>
                            
                            <instantiationChannelConfiguration>
                                <xsl:choose>
                                    <xsl:when 
                                        test="RIFF:NumChannels = '1'">Mono</xsl:when>
                                    <xsl:when 
                                        test="RIFF:NumChannels = '2'">Stereo</xsl:when>
                                <xsl:otherwise>
                                        <xsl:value-of select="RIFF:NumChannels"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </instantiationChannelConfiguration>

                            <xsl:if test="contains($generation, 'segment')">
                                <instantiationAnnotation annotationType="instantiation_title">
                                    <xsl:value-of 
                                        select="normalize-space(RIFF:Title)"/>
                                </instantiationAnnotation>
                                <instantiationAnnotation 
                                    annotationType="instantiation_description">
                                    <xsl:value-of 
                                        select="(RIFF:Subject)"/>
                                </instantiationAnnotation>
                            </xsl:if>
                            <xsl:apply-templates
                                select="RIFF:CodingHistory
                                [not(contains(., 'D.A.V.I.D.'))][$isWAV]"/>
                            <xsl:apply-templates select="RIFF:SourceForm" mode="pbcore"/>
                            
                            <instantiationAnnotation annotationType="embedded_comments">
                                <xsl:value-of select="normalize-space(RIFF:Comment)"/>
                            </instantiationAnnotation>

                            <xsl:apply-templates select="RIFF:Technician" mode="pbcore"/>
                            

                            <!--essence tracks -->
                            <xsl:apply-templates select=".[matches($File:FileType, 'WAV|BWF', 'i')]" mode="essenceTrack"/>
                            
                            <!-- Is dub of -->
                            
                            <xsl:variable name="instIsDubOf" select="$instantiationData/
                                pb:instantiationRelation
                                [pb:instantiationRelationType = 'Is Dub Of']/
                                pb:instantiationRelationIdentifier"/>
                            <xsl:apply-templates select="
                                RIFF:Medium
                                [$isDub]" mode="isDubOf">
                                <xsl:with-param name="instIsDubOf" select="$instIsDubOf"/>
                            </xsl:apply-templates> 
                            
                        </pbcoreInstantiation>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
        </xsl:variable>

        <xsl:copy-of select="$cavafyOutput"/>

    </xsl:template>
    
    <xsl:template match="
            WNYC:instantiation_physical_label" mode="pbcore">
        <xsl:for-each select="tokenize(., $separatingToken)">
            <pbcoreinstantiationIdentifier source="Physical label">
                <xsl:value-of select="normalize-space(.)"/>
            </pbcoreinstantiationIdentifier>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="
        WNYC:instantiation_issued_date" mode="pbcore">
        <xsl:for-each select="tokenize(., $separatingToken)">
            <instantiationDate dateType="Issued">
                <xsl:value-of select="normalize-space(.)"/>
            </instantiationDate>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="
        WNYC:instantiation_date" mode="pbcore">
        <xsl:for-each select="tokenize(., $separatingToken)">
            <instantiationDate>
                <xsl:value-of select="normalize-space(.)"/>
            </instantiationDate>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="
        WNYC:instantiation_created_date" mode="pbcore">
        <xsl:for-each select="tokenize(., $separatingToken)">
            <instantiationDate dateType="Created">
                <xsl:value-of select="normalize-space(.)"/>
            </instantiationDate>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="RIFF:Description" mode="pbcore">
        <instantiationIdentifier source="DAVID Title">
            <xsl:value-of select="
                    normalize-space(.)"/>
        </instantiationIdentifier>
    </xsl:template>
    
    <xsl:template match="System:FileCreateDate" mode="pbcore">
        <instantiationDate dateType="Created">
            <xsl:value-of select="WNYC:dateTimeToISODate(.)"/>
        </instantiationDate>
    </xsl:template>
    
    <xsl:template match="RIFF:Technician" mode="pbcore">
        <instantiationAnnotation annotationType="Transfer_Technician">
            <xsl:value-of select="normalize-space(.)"/>
        </instantiationAnnotation>
    </xsl:template>
    
    <xsl:template match="RIFF:Engineer" mode="pbcore">
        <xsl:for-each select="tokenize(., $separatingToken)">
            <pbcoreContributor>
                <contributor>
                    <xsl:value-of select="normalize-space(.)"/>
                </contributor>
                <contributorRole>Engineer</contributorRole>
            </pbcoreContributor>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="System:FileSize" mode="pbcore">
        <instantiationFileSize>
            <xsl:value-of select="."/>
        </instantiationFileSize>
    </xsl:template>    
    <xsl:template match="Composite:Duration" mode="pbcore">
        <instantiationDuration>
            <xsl:value-of select="."/>
        </instantiationDuration>
    </xsl:template>
    <xsl:template match="RIFF:AvgBytesPerSec" mode="pbcore">
        <instantiationDataRate>
            <xsl:value-of select="."/>
        </instantiationDataRate>
    </xsl:template>
    <xsl:template match="RIFF:SourceForm" mode="pbcore">
        <instantiationAnnotation annotationType="Provenance">
            <xsl:value-of select="
                    normalize-space(
                    .)"/>
        </instantiationAnnotation>
    </xsl:template>
    
    <xsl:template match="rdf:Description" mode="essenceTrack">
        <xsl:param name="isWAV" select="
            upper-case(File:FileType) eq 'WAV'"/>
        <instantiationEssenceTrack>
            <essenceTrackType>audio</essenceTrackType>
            <xsl:if test="$isWAV">
                <essenceTrackIdentifier source="DAVID Title">
                    <xsl:value-of select="normalize-space(RIFF:Description)"/>
                </essenceTrackIdentifier>
            </xsl:if>
            <essenceTrackStandard>
                <xsl:value-of select="File:FileType"/>
            </essenceTrackStandard>
            <essenceTrackEncoding>
                <xsl:value-of select="RIFF:Encoding"/>
            </essenceTrackEncoding>
            <xsl:apply-templates select="
                RIFF:AvgBytesPerSec|
                RIFF:SampleRate|
                RIFF:BitsPerSample" mode="essenceTrack"/>
        </instantiationEssenceTrack>
    </xsl:template>
    
    <xsl:template match="RIFF:Medium" mode="isDubOf">
        <xsl:param name="RIFF:Medium" select="."/>
        <xsl:param name="instIsDubOf"/>
        <xsl:param name="isDubOf">
            <xsl:call-template name="checkConflicts">
                <xsl:with-param name="fieldName" select="isDubOf"/>
                <xsl:with-param name="field1" select="$RIFF:Medium"/>
                <xsl:with-param name="field2" select="$instIsDubOf"/>
            </xsl:call-template>
        </xsl:param>
        <instantiationRelation>
            <instantiationRelationType>Is Dub Of</instantiationRelationType>
            <instantiationRelationIdentifier>
                <xsl:value-of select="$isDubOf"/>
            </instantiationRelationIdentifier>
        </instantiationRelation>
    </xsl:template>
    
    <xsl:template match="RIFF:CodingHistory">
        <xsl:call-template name="generateInstantiationAnnotation">
            <xsl:with-param name="annotationType" select="'codingHistory'"/>
            <xsl:with-param name="value" select="."/>
        </xsl:call-template>
        <xsl:variable name="processSteps" select="
            tokenize(., '\n')[matches(., '\w')]"/>
        <xsl:variable name="numberOfProcessSteps" select="count($processSteps)"/>
        
        <xsl:for-each select="$processSteps">
            <xsl:variable name="codingProcessStepNo" select="position()"/>
            <xsl:apply-templates select="." mode="parseCodingHistoryStep">
                <xsl:with-param name="codingProcessStepNo" select="
                    $codingProcessStepNo"/>
            </xsl:apply-templates>
        </xsl:for-each>
        
    </xsl:template>
    
    <xsl:template match="RIFF:AvgBytesPerSec" mode="essenceTrack">
        <essenceTrackDataRate>
            <xsl:value-of select="."/>
        </essenceTrackDataRate>
    </xsl:template>
    <xsl:template match="RIFF:SampleRate" mode="essenceTrack">
        <essenceTrackSamplingRate>
            <xsl:value-of select="."/>
        </essenceTrackSamplingRate>
    </xsl:template>
    <xsl:template match="RIFF:BitsPerSample" mode="essenceTrack">
        <essenceTrackBitDepth>
            <xsl:value-of select="concat(., ' bit')"/>
        </essenceTrackBitDepth>
    </xsl:template>
    
    <xsl:template match="." mode="parseCodingHistoryStep">
        <xsl:param name="codingProcessStepNo"/>
        
        <xsl:param name="codingProcessStep" select="concat('codingProcessStep', $codingProcessStepNo)"/>
        <xsl:call-template name="generateInstantiationAnnotation">
            <xsl:with-param name="annotationType" select="$codingProcessStep"/>
            <xsl:with-param name="value" select="normalize-space(.)"/>
        </xsl:call-template>
        
        <xsl:for-each select="analyze-string(., 
            '[AFWBMT]=')/fn:non-match">
            
            <xsl:variable name="subelementCode">
                <xsl:value-of select="./preceding-sibling::fn:match[1]/substring-before(., '=')"/>
            </xsl:variable> 
            <xsl:variable name="subelementValue">
                <xsl:value-of select="tokenize(., ',')[1]"/>
            </xsl:variable> 
            <xsl:apply-templates select="." mode="parseCodingHistorySubelement">
                <xsl:with-param name="subelementCode" select="$subelementCode"/>
                <xsl:with-param name="subelementValue" select="$subelementValue"/>
                <xsl:with-param name="codingProcessStepNo" select="$codingProcessStepNo"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="." mode="parseCodingHistorySubelement">
        <xsl:param name="codingHistorySubelement" select="."/>
        <xsl:param name="codingProcessStepNo"/>
        <xsl:param name="codingHistorySubelementParsed" select="tokenize($codingHistorySubelement, '=')"/>
        <xsl:param name="subelementCode" select="$codingHistorySubelementParsed[1]"/>
        <xsl:param name="subelementValue" select="$codingHistorySubelementParsed[2]"/>
        <xsl:variable name="annotationType">
            <xsl:value-of select="
                'codingAlgorithm'[$subelementCode = 'A'],
                'samplingFrequency'[$subelementCode = 'F'],
                'bitRate'[$subelementCode = 'B'],
                'wordLength_bitDepth'[$subelementCode = 'W'],
                'mode_soundField'[$subelementCode = 'M'],
                'freeASCIITextString'[$subelementCode = 'T']"/>
            <xsl:value-of select="$codingProcessStepNo"/>
        </xsl:variable>
        <xsl:variable name="isValidEBU" select="
            $subelementCode = 'A' and matches($subelementValue, $EBUCodingAlgorithm)
            or 
            $subelementCode = 'F' and matches($subelementValue, $EBUSamplingFrequency)
            or
            $subelementCode = 'B'
            or
            $subelementCode = 'W' and matches($subelementValue, $EBUWordLength)
            or
            $subelementCode = 'M' and matches($subelementValue, $EBUMode)
            or
            $subelementCode = 'T' and not(contains($subelementValue, ','))
            "/>
        <xsl:for-each select=".[$isValidEBU]">
            <xsl:call-template name="generateInstantiationAnnotation">
                <xsl:with-param name="annotationType" select="$annotationType"/>
                <xsl:with-param name="value">
                    <xsl:choose>
                        <xsl:when test="$subelementCode = 'A' and matches($subelementValue, $EBUCodingAlgorithm)">
                            <xsl:value-of select="normalize-space($subelementValue)"/>
                        </xsl:when>
                        <xsl:when test="$subelementCode = 'F' and matches($subelementValue, $EBUSamplingFrequency)">
                            <xsl:value-of select="normalize-space($subelementValue)"/>
                        </xsl:when>
                        <xsl:when test="$subelementCode = 'B'">
                            <xsl:value-of select="normalize-space($subelementValue)"/>
                        </xsl:when>
                        <xsl:when test="$subelementCode = 'W' and matches($subelementValue, $EBUWordLength)">
                            <xsl:value-of select="normalize-space($subelementValue)"/>
                        </xsl:when>
                        <xsl:when test="$subelementCode = 'M' and matches($subelementValue, $EBUMode)">
                            <xsl:value-of select="normalize-space($subelementValue)"/>
                        </xsl:when>
                        <xsl:when test="$subelementCode = 'T' and not(contains($subelementValue, ','))">
                            <xsl:value-of select="normalize-space($subelementValue)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message select="'Invalid value for:', $annotationType, $subelementValue"/>
                        </xsl:otherwise> 
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:apply-templates select="$subelementValue[$subelementCode = 'T'][matches(., '\[(St|RF|TO|RO|Ca|EQ|NR|Sp)\]')]" mode="parseCodingHistoryFreeText"/>
    </xsl:template>
    
    
    
    <xsl:template name="parseCodingHistoryFreeText" match="." mode="
        parseCodingHistoryFreeText">
        <xsl:param name="codingHistoryFreeText" select="."/>
        <xsl:param name="codingHistoryTech" select="
            tokenize($codingHistoryFreeText, ';')
            [matches(., '\[(St|RF|TO|RO|Ca|EQ|NR|Sp)\]')]"/>
        <xsl:param name="codingHistoryNotes" select="
            tokenize($codingHistoryFreeText, ';')
            [not(matches(., '\[(St|RF|TO|RO|Ca|EQ|NR|Sp)\]'))]"/>
        <xsl:param name="format"/>
        
        <xsl:for-each select="$codingHistoryTech">
            <xsl:call-template name="parseCodingHistoryTech">
                <xsl:with-param name="codingHistoryTech" select="."/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="$codingHistoryNotes">
            <xsl:call-template name="generateInstantiationAnnotation">
                <xsl:with-param name="annotationType" select="'Engineer_notes'"/>
                <xsl:with-param name="value" select="normalize-space(.)"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="parseCodingHistoryTech" match="
        text()[matches(., '\[(St|RF|TO|RO|Ca|EQ|NR|Sp)\]')]" mode="
        parseCodingHistoryTech">
        <xsl:param name="codingHistoryTech" select="."/>
        <xsl:param name="codingHistoryTechParsed" select="
            analyze-string(
            $codingHistoryTech, '\[(St|RF|TO|RO|Ca|EQ|NR|Sp)\]'
            )"/>
        <xsl:apply-templates select="
            $codingHistoryTechParsed/*:match" mode="codingHistoryTechAnnotation"/>
    </xsl:template>
    
    <xsl:template name="codingHistoryTechAnnotation" match="
        *:match" mode="codingHistoryTechAnnotation">
        <xsl:param name="typeCode" select="."/>
        <xsl:element name="instantiationAnnotation">
            <xsl:attribute name="annotationType">
                <xsl:value-of select="'Stylus_size'[$typeCode = '[St]']"/>
                <xsl:value-of select="'Rumble_filter'[$typeCode = '[RF]']"/>
                <xsl:value-of select="'LF_turnover'[$typeCode = '[TO]']"/>
                <xsl:value-of select="'10kHz_att'[$typeCode = '[RO]']"/>
                <xsl:value-of select="'Calibration'[$typeCode = '[Ca]']"/>
                <xsl:value-of select="'playback_EQ'[$typeCode = '[EQ]']"/>
                <xsl:value-of select="'Noise_reduction'[$typeCode = '[NR]']"/>
                <xsl:value-of select="'Playback_speed'[$typeCode = '[Sp]']"/>
            </xsl:attribute>
            <xsl:value-of select="normalize-space(following-sibling::*:non-match[1])"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="generateInstantiationAnnotation">
        <xsl:param name="value" select="normalize-space(.)"/>
        <xsl:param name="annotationType"/>
        <xsl:param name="annotation"/>
        <xsl:element name="instantiationAnnotation">
            <xsl:if test="matches($annotationType, '\w')">
                <xsl:attribute name="annotationType" select="$annotationType"/>
            </xsl:if>
            <xsl:if test="matches($annotation, '\w')">
                <xsl:attribute name="annotation" select="$annotation"/>
            </xsl:if>
            <xsl:value-of select="$value"/>
        </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>
