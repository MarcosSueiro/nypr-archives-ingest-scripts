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
    xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html" exclude-result-prefixes="#all">

    <xsl:import href="selectionOrExcerpt.xsl"/>    
    <xsl:import href="parseDAVIDTitle.xsl"/>
    <xsl:import href="parseContributors.xsl"/>

    <xsl:param name="exifInput"/>
    
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
        <xsl:param name="parsedDAVIDTitle">
            <!-- Parse DAVID title or filename -->
            <xsl:choose>
                <xsl:when test="File:FileType = 'NEWASSET'">
                    <xsl:apply-templates select="System:FileName" mode="parseDAVIDTitle">
                        <xsl:with-param name="filenameToParse" select="System:FileName"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="contains(System:Directory, 'ARCHIVESNAS1/INGEST')">
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
                    So we look after the comma-->
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

        <!-- Generation -->
        <xsl:variable name="generation">
            <xsl:copy-of 
                select="
                $parsedDAVIDTitle/parsedDAVIDTitle
                /parsedElements/parsedGeneration"
            />
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
                    are necessary to import assets into cavafy-->
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
                    <!-- To ensure things get published to the web, 
                        which needs a broadcast date -->
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
                    are necessary to import assets into cavafy-->
                <pbcoreTitle titleType="Collection">
                    <xsl:value-of select="$collectionAcronym"/>
                </pbcoreTitle>

                <pbcoreTitle titleType="Series">
                    <xsl:value-of select="RIFF:Product"/>
                </pbcoreTitle>
                
                <!-- Apply asset-level fields 
                    to instantiations that are not an excerpt-->
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
                            <xsl:value-of select="normalize-space(RIFF:Subject)"/>
                        </pbcoreDescription>
                    </xsl:if>

                    <!-- Markers as excerpts-->
                    <xsl:if
                        test="
                        XMP-xmpDM:Tracks
                        /rdf:Bag
                        /rdf:li[@rdf:parseType = 'Resource']
                        /XMP-xmpDM:Markers
                        /rdf:Bag
                        /rdf:li[@rdf:parseType = 'Resource']">
                        <xsl:variable name="excerptsAlreadyInCavafy">
                            <xsl:for-each
                                select="
                                $cavafyEntry
                                //*[@descriptionType = 'Selection or Excerpt']">
                                <xsl:value-of select="." separator=" ; "/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:variable name="currentExcerpt">
                            <xsl:apply-templates
                                select="
                                XMP-xmpDM:Tracks
                                /rdf:Bag
                                /rdf:li[@rdf:parseType = 'Resource']
                                /XMP-xmpDM:Markers
                                /rdf:Bag
                                /rdf:li[@rdf:parseType = 'Resource']"
                            />
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
                            separator="+++++++++++++++++++++++++++++++"/>
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
                <!-- The template 'Broader Subjects' 
                    travels up the LOC hierarchy -->

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


                <xsl:variable name="broaderSubjects">
                    <xsl:apply-templates 
                        select="RIFF:Keywords" 
                        mode="broaderSubjects"/>
                </xsl:variable>

                <xsl:apply-templates 
                    select="$broaderSubjects" 
                    mode="LOCtoPBCore"/>
                
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

                <!--Adding creators-->
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
                    <xsl:otherwise>

                        <!-- instantiations-->

                        <pbcoreInstantiation>
                            <instantiationIdentifier source="WNYC Media Archive Label">
                                <xsl:value-of select="$instantiationID"/>
                            </instantiationIdentifier>
                            <instantiationIdentifier source="DAVID Title">
                                <xsl:value-of select="normalize-space(RIFF:Description)"/>
                            </instantiationIdentifier>
                            <instantiationDate dateType="Created">
                                <xsl:value-of
                                    select="
                                    normalize-space(
                                    translate(
                                    substring-before(
                                    System:FileCreateDate, 
                                    ' '), 
                                    ':', 
                                    '-'
                                    ))"
                                />
                            </instantiationDate>
                            <instantiationDigital>
                                <xsl:choose>
                                    <xsl:when test="File:FileType eq 'WAV'">
                                        <xsl:value-of select="'BWF'"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:element name="error">
                                            <xsl:attribute name="type" select="'unknown_format'"/>
                                            <xsl:value-of select="File:FileType"/>
                                        </xsl:element>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </instantiationDigital>
                            <instantiationLocation>DAVID</instantiationLocation>
                            <instantiationMediaType>Sound</instantiationMediaType>
                            <instantiationGenerations>
                                <xsl:value-of select="$generation"/>
                            </instantiationGenerations>
                            <instantiationFileSize>
                                <xsl:value-of select="System:FileSize"/>
                            </instantiationFileSize>
                            <instantiationDuration>
                                <xsl:value-of select="Composite:Duration"/>
                            </instantiationDuration>
                            <instantiationDataRate>
                                <xsl:value-of select="RIFF:AvgBytesPerSec"/>
                            </instantiationDataRate>
                            <instantiationChannelConfiguration>
                                <xsl:choose>
                                    <xsl:when 
                                        test="RIFF:NumChannels = 1">Mono</xsl:when>
                                    <xsl:when 
                                        test="RIFF:NumChannels = 2">Stereo</xsl:when>
                                </xsl:choose>
                            </instantiationChannelConfiguration>

                            <xsl:if test="contains($generation, 'segment')">
                                <instantiationAnnotation annotationType="Embedded Title">
                                    <xsl:value-of 
                                        select="normalize-space(RIFF:Title)"/>
                                </instantiationAnnotation>
                                <instantiationAnnotation 
                                    annotationType="Embedded Description">
                                    <xsl:value-of 
                                        select="normalize-space(RIFF:Subject)"/>
                                </instantiationAnnotation>
                            </xsl:if>

                            <xsl:if
                                test="RIFF:CodingHistory ne '' 
                                and 
                                not(
                                contains(RIFF:CodingHistory, 'D.A.V.I.D.'
                                ))">
                                <instantiationAnnotation annotationType="Encoding_Notes">
                                    <xsl:value-of 
                                        select="normalize-space(RIFF:CodingHistory)"/>
                                </instantiationAnnotation>
                            </xsl:if>

                            <xsl:if test="contains(RIFF:CodingHistory, '[TO]')">
                                <instantiationAnnotation annotationType="LF_turnover">
                                    <xsl:value-of
                                        select="
                                        substring-before(
                                        substring-after(
                                        RIFF:CodingHistory, 
                                        '[TO]'
                                        ), 
                                        '[RO]'
                                        )"
                                    />
                                </instantiationAnnotation>
                            </xsl:if>

                            <xsl:if test="contains(RIFF:CodingHistory, '[RO]')">
                                <instantiationAnnotation annotationType="10kHz_att">
                                    <xsl:value-of
                                        select="
                                        substring-after(
                                        RIFF:CodingHistory, '[RO]'
                                        )"/>
                                </instantiationAnnotation>
                            </xsl:if>

                            <instantiationAnnotation annotationType="Provenance">
                                <xsl:value-of 
                                    select="normalize-space(RIFF:SourceForm)"/>
                            </instantiationAnnotation>
                            <instantiationAnnotation annotationType="Embedded_Comments">
                                <xsl:value-of select="normalize-space(RIFF:Comment)"/>
                            </instantiationAnnotation>

                            <!--essence tracks-->
                            <instantiationEssenceTrack>
                                <essenceTrackType>audio</essenceTrackType>
                                <essenceTrackIdentifier source="DAVID Title">
                                    <xsl:value-of 
                                        select="normalize-space(RIFF:Description)"/>
                                </essenceTrackIdentifier>
                                <essenceTrackStandard>
                                    <xsl:value-of select="File:FileType"/>
                                </essenceTrackStandard>
                                <essenceTrackEncoding>
                                    <xsl:value-of select="RIFF:Encoding"/>
                                </essenceTrackEncoding>
                                <essenceTrackDataRate>
                                    <xsl:value-of select="RIFF:AvgBytesPerSec"/>
                                </essenceTrackDataRate>
                                <essenceTrackSamplingRate>
                                    <xsl:value-of select="RIFF:SampleRate"/>
                                </essenceTrackSamplingRate>
                                <essenceTrackBitDepth>
                                    <xsl:value-of select="concat(RIFF:BitsPerSample, ' bit')"/>
                                </essenceTrackBitDepth>
                            </instantiationEssenceTrack>
                        </pbcoreInstantiation>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
        </xsl:variable>

        <xsl:copy-of select="$cavafyOutput"/>

    </xsl:template>
</xsl:stylesheet>
