<?xml version="1.0" encoding="UTF-8"?>


<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xsi:schemaLocation="http://www.pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:et="http://ns.exiftool.ca/1.0/"
    et:toolkit="Image::ExifTool 9.46" xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:WNYC="http://www.wnyc.org"
    xmlns:XMP="http://ns.exiftool.ca/XMP/XMP/1.0/"
    xmlns:XMP-x="http://ns.exiftool.ca/XMP/XMP-x/1.0/"
    xmlns:XMP-xmp="http://ns.exiftool.ca/XMP/XMP-xmp/1.0/"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:XMP-xmpDM="http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/"
    xmlns:XMP-xmpMM="http://ns.exiftool.ca/XMP/XMP-xmpMM/1.0/"
    xmlns:XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/"
    xmlns:XMP-WNYCSchema="http://ns.exiftool.ca/XMP/XMP-WNYCSchema/1.0/"
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/"
    exclude-result-prefixes="XMP rdf et ExifTool System File RIFF XMP-x XMP-xmp XMP-xmpDM XMP-xmpMM XMP-dc XMP-WNYCSchema Composite XMP-dc">

    <!--Gives line breaks etc-->
    <xsl:output encoding="UTF-8" method="xml" version="1.0" indent="yes"/>

    <xsl:import href="masterRouter.xsl"/>
    
    <xsl:variable name="baseURI" select="
        base-uri()"/>
    <xsl:variable name="parsedBaseURI" select="
        analyze-string($baseURI, '/')"/>
    <xsl:variable name="masterDocFilename">
        <xsl:value-of select="
            $parsedBaseURI/
            fn:non-match[last()]"
        />
    </xsl:variable>
    <xsl:variable name="masterDocFilenameNoExtension">
        <xsl:value-of
            select="
            WNYC:substring-before-last(
            $masterDocFilename, '.'
            )"
        />
    </xsl:variable>
    <xsl:variable name="baseFolder"
        select="
        substring-before(
        $baseURI,
        $masterDocFilename
        )"/>
    
    <xsl:template match="entries">
        <xsl:variable name="resultDocument">
        <pbcoreCollection xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html" 
            xsi:schemaLocation="http://www.pbcore.org/PBCore/PBCoreNamespace.html
            http://pbcore.org/xsd/pbcore-2.0.xsd">
            <xsl:apply-templates select="entry"/>
        </pbcoreCollection>
        </xsl:variable>
        <xsl:value-of select="$baseURI, $baseFolder"/>
        <xsl:apply-templates select="$resultDocument" mode="breakItUp">
            <xsl:with-param name="filename"
                select="
                concat('file:/T:/02%20CATALOGING/MultiTrackCataloging/',
                $masterDocFilenameNoExtension)"/>          
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="entry">

        <!-- parameters to be used when searching for subjects -->
        <xsl:param name="subjectsProcessed"/>
        <xsl:param name="subjectsToProcess" select="string-join((subject,subject2,subject3), ' ; ')"/>
        <xsl:param name="cavafyurl" select="concat(url, '.xml')"/>
        <xsl:param name="cavafyxml" select="doc($cavafyurl)"/>
        
        <xsl:param name="subjectsAlreadyInCavafy">
            <xsl:value-of select="
                $cavafyxml/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreSubject/
                @ref[contains(., 'id.loc.gov')]
                " separator=" ; "/>
        </xsl:param>
        <xsl:param name="contributorsAlreadyInCavafy">
            <xsl:value-of select="
                $cavafyxml/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreContributor/
                pb:contributor/
                @ref[contains(., 'id.loc.gov')]" separator = " ; "/>
        </xsl:param>
        <xsl:param name="creatorsAlreadyInCavafy">
            <xsl:value-of select="
                $cavafyxml/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreCreator/
                pb:creator/
                @ref[contains(., 'id.loc.gov')]" separator = " ; "/>
        </xsl:param>
        <xsl:param name="publishersAlreadyInCavafy">
            <xsl:value-of select="
                $cavafyxml/
                pb:pbcoreDescriptionDocument/
                pb:pbcorePublisher/
                pb:publisher/
                @ref[contains(., 'id.loc.gov')]" separator = " ; "/>
        </xsl:param>
        <xsl:param name="peopleAlreadyInCavafy">
            <xsl:value-of select="
                $creatorsAlreadyInCavafy, 
                $publishersAlreadyInCavafy, 
                $contributorsAlreadyInCavafy" 
                separator=" ; "/>
        </xsl:param>
        <xsl:param name="genresAlreadyInCavafy">
            <xsl:value-of select="
                $cavafyxml/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreGenre" separator = " ; "/>
        </xsl:param>        
        <xsl:param name="coverageAlreadyInCavafy">
            <xsl:value-of select="
                $cavafyxml/
                pb:pbcoreDescriptionDocument/
                pb:pbcoreCoverage/
                pb:coverage" separator = " ; "/>
        </xsl:param>
        
        <!--<subjectsAlreadyInCavafy>
            <xsl:value-of select="$subjectsAlreadyInCavafy"/>
        </subjectsAlreadyInCavafy>-->
        
        <!--<contributorsAlreadyInCavafy>
            <xsl:value-of select="$contributorsAlreadyInCavafy"/>
        </contributorsAlreadyInCavafy>-->

        <xsl:variable name="assetID">
            <xsl:value-of select="catalogNo"/>
        </xsl:variable>
        
        <xsl:variable name="machine">
            <xsl:value-of select="machine"/>
        </xsl:variable>
        <xsl:variable name="tape">
            <xsl:value-of select="tape"/>
        </xsl:variable>
        <xsl:variable name="tracks">
            <xsl:value-of select="tracks"/>
        </xsl:variable>
        <xsl:variable name="tracksCompact" select="
            replace($tracks, '[^0-9]+', '-')"/>
        <xsl:variable name="instantiationLevel">
            <xsl:value-of select="note1"/>
        </xsl:variable>
        <xsl:variable name="allArtists">
            <xsl:value-of select="artist1, artist2, artist3" separator=" ; "/>
        </xsl:variable>
        <xsl:variable name="validArtists" select="
            WNYC:splitParseValidate($allArtists, ';', 'id.loc.gov')/valid"/>

        <xsl:variable name="instantiationID" select="
                concat(
                catalogNo,
                '.',
                $instantiationLevel,
                '_TK',
                $tracksCompact)"/>

        <xsl:variable name="physicalLabel">
            <xsl:value-of select="replace(replace(
                replace(
                instantiationIDType, 'XX', $machine), 
                'YY', $tape), 'ZZ', $tracks)"/>            
        </xsl:variable>
        <xsl:variable name="freeText">
            <xsl:value-of select="substring-after(XMP:EntriesEntryTitle,' ')"/>
        </xsl:variable>

        <xsl:variable name="collection"
            select="$cavafyxml/
            pb:pbcoreDescriptionDocument/
            pb:pbcoreTitle[@titleType='Collection']"/>
        
        <xsl:variable name="cavafyAssetID"
            select="$cavafyxml/
            pb:pbcoreDescriptionDocument/
            pb:pbcoreIdentifier[@source='WNYC Archive Catalog']"/>
        
        <xsl:if test="not($assetID = $cavafyAssetID)">
            <xsl:message terminate="yes">
                ERROR: Given asset ID is 
                <xsl:value-of select="$assetID"/>
                but the cavafy ID from the URL is 
                <xsl:value-of select="$cavafyAssetID"/>
            </xsl:message>
        </xsl:if>

        <xsl:variable name="coverage" select="
                concat(
                substring-before(
                substring-after(
                coveragePlace, '@'
                ), ','),
                ',',
                substring-before(
                substring-after(
                substring-after(
                coveragePlace, '@'
                ), ','), ',')
                )"/>
        
        <!--assets-->
        <pbcoreDescriptionDocument xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html">
            <xsl:if test="normalize-space(createDate)">
                <pbcoreAssetDate dateType="created">
                    <xsl:value-of select="createDate"/>
                </pbcoreAssetDate>
            </xsl:if>
            <pbcoreIdentifier source="WNYC Archive Catalog">
                <xsl:value-of select="$assetID"/>
            </pbcoreIdentifier>
            <pbcoreTitle titleType="Collection">
                <xsl:value-of select="$collection"/>
            </pbcoreTitle>

            <xsl:if
                test="normalize-space(genre) and not (matches($genresAlreadyInCavafy, '\w'))">
                <pbcoreGenre source="PBCore Genre Picklist">
                    <xsl:value-of select="genre"/>
                </pbcoreGenre>
            </xsl:if>
            
            <!-- artist occupations and fields of activity-->
            <xsl:variable name="combinedArtistJobs">
                <xsl:for-each select="$validArtists">
                    <xsl:variable name="artistxml" select="concat(.,'.rdf')"/>
                    <xsl:variable name="artistJob" select="document($artistxml)//*[local-name()='occupation']/*[local-name()='Occupation']/@*[local-name()='about']"/>
                    <xsl:value-of select="string-join($artistJob,' ; ')"/>
                </xsl:for-each>
            </xsl:variable> 
<!--            <combinedArtistJobs>
                <xsl:value-of select="$combinedArtistJobs"/>
            </combinedArtistJobs>-->
            
            <xsl:variable name="combinedArtistFields">
                <xsl:for-each select="$validArtists">
                    <xsl:variable name="artistxml" select="concat(.,'.rdf')"/>
                    <xsl:variable name="artistField" select="document($artistxml)//*[local-name()='fieldOfActivity']/*[local-name()='Concept']/@*[local-name()='about']"/>
                    <xsl:value-of select="string-join($artistField,' ; ')"/>
                    <xsl:value-of select="' ; '"/>
                </xsl:for-each>
            </xsl:variable> 
<!--            <combinedArtistFields>
                <xsl:value-of select="$combinedArtistFields"/>
                </combinedArtistFields>-->
            <xsl:variable name="subjects">
                <xsl:apply-templates select="
                        string-join((
                        $subjectsToProcess,
                        $combinedArtistJobs,
                        $combinedArtistFields), ' ; ')[matches(., 'id.loc.gov')]"
                    mode="narrowSubjects">
                    <xsl:with-param name="subjectsProcessed"
                        select="string-join(($subjectsProcessed, $subjectsAlreadyInCavafy), ' ; ')"/>
                </xsl:apply-templates>
            </xsl:variable>
            
            <xsl:apply-templates select="$subjects" mode="LOCtoPBCore"/>

            <xsl:if test="normalize-space(
                coveragePlace) and not(contains($coverageAlreadyInCavafy,$coverage))">
                <pbcoreCoverage>
                    <coverage>
                        <xsl:value-of select="$coverage"/>
                    </coverage>
                    <coverageType>Spatial</coverageType>
                </pbcoreCoverage>
            </xsl:if>
            <xsl:apply-templates select="host[matches(., 'id.loc.gov')]" mode="
                parseContributors">
                <xsl:with-param name="role" select="'creator'"/>
                <xsl:with-param name="contributorsAlreadyInCavafy" select="
                    $peopleAlreadyInCavafy"/>
            </xsl:apply-templates>
                        
            <xsl:apply-templates select="$allArtists[matches(., 'id.loc.gov')]" mode="
                parseContributors">
                <xsl:with-param name="role" select="'contributor'"/>
                <xsl:with-param name="contributorsAlreadyInCavafy" select="
                    $peopleAlreadyInCavafy"/>
            </xsl:apply-templates>

            <!-- instantiations-->

            <pbcoreInstantiation>
                <instantiationIdentifier source="WNYC Media Archive Label">
                    <xsl:value-of select="$instantiationID"/>
                </instantiationIdentifier>
                <instantiationIdentifier source="Physical label">
                    <xsl:value-of select="$physicalLabel"/>
                </instantiationIdentifier>
                <xsl:if test="normalize-space(createDate)">
                    <instantiationDate dateType="Created">
                        <xsl:value-of select="createDate"/>
                    </instantiationDate>
                </xsl:if>
                <instantiationPhysical>
                    <xsl:value-of select="physicalFormat"/>
                </instantiationPhysical>
                <instantiationLocation>
                    <xsl:value-of select="concat(locationShelf,', Box &quot;',locationBox,'&quot;')"
                    />
                </instantiationLocation>
                <instantiationMediaType>Sound</instantiationMediaType>
                <instantiationChannelConfiguration>
                    <xsl:variable name="numberOfTracks" select="
                            string(
                            number(
                            substring-after($tracksCompact, '-'))
                            -
                            number(substring-before(tracks, '-')
                            ) + 1)"/>
                    <xsl:value-of
                        select="concat($numberOfTracks,' tracks',' (',totalTracks,' total)')"/>
                </instantiationChannelConfiguration>
                <xsl:if test="normalize-space(engineers)">
                    <instantiationAnnotation>
                        <xsl:value-of select="concat('Engineers: ',engineers)"/>
                    </instantiationAnnotation>
                </xsl:if>

                <xsl:if test="normalize-space(note2)">
                    <instantiationAnnotation>
                        <xsl:value-of select="note2"/>
                    </instantiationAnnotation>
                </xsl:if>

                <!--essence tracks-->
                <instantiationEssenceTrack>
                    <essenceTrackType>audio</essenceTrackType>
                    <essenceTrackStandard>
                        <xsl:value-of select="essenceTrackFormat"/>
                    </essenceTrackStandard>
                    <essenceTrackSamplingRate>
                        <xsl:value-of select="sampleRate"/>
                    </essenceTrackSamplingRate>
                    <essenceTrackBitDepth>
                        <xsl:value-of select="concat(bitDepth,' bit')"/>
                    </essenceTrackBitDepth>
                </instantiationEssenceTrack>
            </pbcoreInstantiation>
        </pbcoreDescriptionDocument>
    </xsl:template>
</xsl:stylesheet>
