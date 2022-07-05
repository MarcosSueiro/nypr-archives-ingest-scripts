<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="3.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xsi:schemaLocation="http://www.pbcore.org/PBCore/PBCoreNamespace.html 
    http://pbcore.org/xsd/pbcore-2.0.xsd"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:et="http://ns.exiftool.ca/1.0/"
    et:toolkit="Image::ExifTool 9.46" 
    xmlns:ExifTool="http://ns.exiftool.ca/ExifTool/1.0/"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/" 
    xmlns:RIFF="http://ns.exiftool.ca/RIFF/RIFF/1.0/"
    xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    xmlns:XMP-x="http://ns.exiftool.ca/XMP/XMP-x/1.0/"
    xmlns:XMP-xmp="http://ns.exiftool.ca/XMP/XMP-xmp/1.0/"
    xmlns:XMP-xmpDM="http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/"
    xmlns:XMP-xmpMM="http://ns.exiftool.ca/XMP/XMP-xmpMM/1.0/"
    xmlns:XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/"
    xmlns:XMP-WNYCSchema="http://ns.exiftool.ca/XMP/XMP-WNYCSchema/1.0/"
    xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:Composite="http://ns.exiftool.ca/Composite/1.0/" exclude-result-prefixes="#all">

    <!--Gives line breaks etc-->
    <xsl:output method="xml" version="1.0" indent="yes"/>

    <xsl:include
        href="file:/T:/02%20CATALOGING/Instantiation%20uploads/nypr-archives-ingest-scripts/currentTemplates/cavafySearch.xsl"/>
    
    <!--Output definitions -->

    <!--<xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>-->

    <xsl:template match="entries">
        <pbcoreCollection xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd">
            <xsl:apply-templates select="entry"/>
        </pbcoreCollection>
    </xsl:template>

    <xsl:template match="entry">
        <xsl:param name="assetID">
            <xsl:value-of select="normalize-space(catalogNo)"/>
        </xsl:param>

        <xsl:message>
            <xsl:value-of select="concat('Asset ID is ', $assetID)"/>
        </xsl:message>
        <xsl:if test="$assetID = ''">
            <xsl:message select="'No catalog number'" terminate="yes"/>
        </xsl:if>
        <xsl:if test="collectionTitle = ''">
            <xsl:message select="'No collection'" terminate="yes"/>
        </xsl:if>
        
        <xsl:variable name="seriesTitle" select="
            normalize-space(seriesTitle)"/>
        
        <xsl:variable name="cavafyXML">
            <xsl:call-template name="findCavafyXMLs">
                <xsl:with-param name="textToSearch" select="$assetID"/>
                <xsl:with-param name="field1ToSearch" select="'identifier'"/>
                <xsl:with-param name="series" select="$seriesTitle"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="datesInCavafy" select="
                $cavafyXML/pb:pbcoreDescriptionDocument/
                pb:pbcoreAssetDate"/>
        <xsl:variable name="abstractInCavafy" select="
            $cavafyXML/pb:pbcoreDescriptionDocument/
            pb:pbcoreDescription[@descriptionType='Abstract']"/>
        <xsl:variable name="subjectsInCavafy" select="
            $cavafyXML/pb:pbcoreDescriptionDocument/
            pb:pbcoreSubject"/>
        <xsl:variable name="contributorsInCavafy" select="
            $cavafyXML/pb:pbcoreDescriptionDocument/
            pb:pbcoreContributor/pb:contributor"/>
        <xsl:variable name="creatorsInCavafy" select="
            $cavafyXML/pb:pbcoreDescriptionDocument/
            pb:pbcoreCreator/pb:creator"/>
        <xsl:variable name="genresInCavafy" select="
            $cavafyXML/pb:pbcoreDescriptionDocument/
            pb:pbcoreGenre"/>
        
        <!--assets-->
        <pbcoreDescriptionDocument>
            <xsl:apply-templates select="
                createDate[. != $datesInCavafy[@dateType='created']]"/>
            
            <xsl:apply-templates select="
                bcastDate[. != $datesInCavafy[@dateType='broadcast']]"/>
                
            
            <pbcoreIdentifier source="WNYC Archive Catalog">
                <xsl:value-of select="$assetID"/>
            </pbcoreIdentifier>
            

            <pbcoreTitle titleType="Episode">
                <xsl:choose>
                    <xsl:when test="showTitle">
                        <xsl:value-of select="showTitle"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($seriesTitle, ', ', bcastDate)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </pbcoreTitle>
            
            <xsl:if test="seriesTitle">
                <pbcoreTitle titleType="Series">
                    <xsl:value-of select="seriesTitle"/>
                </pbcoreTitle>
            </xsl:if>
            <pbcoreTitle titleType="Collection">
                <xsl:value-of select="collectionTitle"/>
            </pbcoreTitle>
            <xsl:if test="cmsTease">
                <pbcoreDescription descriptionType="CMS Tease">
                    <xsl:value-of select="cmsTease"/>
                </pbcoreDescription>
            </xsl:if>
            <xsl:apply-templates select="
                abstract[not(. = $abstractInCavafy)]"/>
            <xsl:apply-templates select="
                genre[not(. = $genresInCavafy)]"/>
            <xsl:if test="cmsImage">
                <pbcoreAnnotation annotationType="CMS Image">
                    <xsl:value-of select="cmsImage"/>
                </pbcoreAnnotation>
            </xsl:if>
            
            <xsl:variable name="occupations">
                <xsl:call-template name="LOCOccupationsAndFieldsOfActivity">
                    <xsl:with-param name="artists" select="artist1"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:variable name="narrowSubjects">
                <xsl:apply-templates select="subject" mode="
                    narrowSubjects">
                    <xsl:with-param name="subjectsToProcess">
                        <xsl:value-of select="subject, $occupations" separator=" ; "/>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:variable>
            
            <xsl:apply-templates select="
                $narrowSubjects/
                madsrdf:*
                [not(@rdf:about = $subjectsInCavafy/@*:ref)]" mode="
                LOCtoPBCore"/>
            <xsl:apply-templates select="artist1">
                <xsl:with-param name="
                    contributorsAlreadyInCavafy">
                    <xsl:value-of select="concat($contributorsInCavafy, ' ')"/>
                </xsl:with-param>
            </xsl:apply-templates>
            
            
            
            <xsl:if test="normalize-space(host)">
                <xsl:call-template name="parseContributors">
                    <xsl:with-param name="contributorsToProcess" select="host"/>
                    <xsl:with-param name="token" select="';'"/>                    
                    <xsl:with-param name="role" select="'creator'"/>
                </xsl:call-template>
            </xsl:if>

            <!-- instantiations-->
            <xsl:if test="normalize-space(instantiationExtension)">

                <pbcoreInstantiation>
                    <instantiationIdentifier source="WNYC Media Archive Label">
                        <xsl:value-of select="concat(catalogNo, '.', instantiationExtension)"/>
                    </instantiationIdentifier>
                    <xsl:if test="normalize-space(createDate)">
                        <instantiationDate dateType="Created">
                            <xsl:value-of select="createDate"/>
                        </instantiationDate>
                    </xsl:if>
                    <instantiationPhysical>
                        <xsl:value-of select="format"/>
                    </instantiationPhysical>
                    <instantiationLocation>
                        <xsl:value-of select="'Archives storage'"
                        />
                    </instantiationLocation>
                    <instantiationMediaType>Sound</instantiationMediaType>
                    <xsl:if test="normalize-space(note1)">
                        <instantiationAnnotation>
                            <xsl:value-of select="note1"/>
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
                    </instantiationEssenceTrack>
                </pbcoreInstantiation>
            </xsl:if>
        </pbcoreDescriptionDocument>
    </xsl:template>

    <xsl:template match="File" name="splitDates">
        <xsl:param name="string"/>
        <xsl:param name="break"/>
        <xsl:variable name="multitoken" select="contains($string, $break)"/>

        <xsl:variable name="token">
            <xsl:choose>
                <xsl:when test="$multitoken">
                    <xsl:value-of select="normalize-space(substring-before($string, $break))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space($string)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:if test="string($token)">
            <pbcoreAssetDate dateType="broadcast">
                <xsl:value-of select="$token"/>
            </pbcoreAssetDate>
        </xsl:if>


        <xsl:if test="$multitoken">
            <xsl:call-template name="splitDates">
                <xsl:with-param name="string" select="substring-after($string, $break)"/>
                <xsl:with-param name="break" select="$break"/>
            </xsl:call-template>
        </xsl:if>

    </xsl:template>
    <!-- getting more subjects from names-->
        <xsl:template match="//*[contains(name(),'occupation')]">
        <pbcoreSubject source="Library of Congress"
            ref="{./*[contains(name(),'Occupation')]/attribute::rdf:about}">
            <xsl:value-of
                select="./*[contains(name(),'Occupation')]/*[contains(name(),'authoritativeLabel')]"
            />
        </pbcoreSubject>
    </xsl:template>
    
    <xsl:template match="createDate">
        <pbcoreAssetDate dateType="created">
            <xsl:value-of select="normalize-space(.)"/>
        </pbcoreAssetDate>
    </xsl:template>
    <xsl:template match="bcastDate">
        <pbcoreAssetDate dateType="broadcast">
            <xsl:value-of select="normalize-space(.)"/>
        </pbcoreAssetDate>
    </xsl:template>
    <xsl:template match="abstract">
        <pbcoreDescription descriptionType="Abstract">
            <xsl:value-of select="."/>
        </pbcoreDescription>
    </xsl:template>
    <xsl:template match="genre">
        <pbcoreGenre source="PBCore Genre Picklist">
            <xsl:value-of select="genre"/>
        </pbcoreGenre>
    </xsl:template>
    <xsl:template match="artist1">
        <xsl:param name="contributorsAlreadyInCavafy"/>
            <xsl:call-template name="parseContributors">
                <xsl:with-param name="contributorsToProcess" select="."/>
                <xsl:with-param name="token" select="';'"/>                    
                <xsl:with-param name="role" select="'contributor'"/>
                <xsl:with-param name="contributorsAlreadyInCavafy" select="$contributorsAlreadyInCavafy"/>
            </xsl:call-template>
    </xsl:template>

</xsl:stylesheet>
