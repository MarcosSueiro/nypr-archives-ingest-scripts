masterRouter.xsl
template name="exiftool" match="rdf:RDF"

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterRouter.xsl
Description: Basic info: type of document, number of instantiations
XPath location: /xsl:stylesheet[1]/xsl:template[3]/comment()[1]
Start location: 27:9
End location: 27:72

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterRouter.xsl
Description: Make sure there are no duplicate instantiations.
XPath location: /xsl:stylesheet[1]/xsl:template[3]/comment()[2]
Start location: 33:9
End location: 33:64

Call template rdfExtractor
XPath location: /xsl:stylesheet[1]/xsl:template[3]/xsl:element[1]/xsl:call-template[1]/@name
Start location: 64:32
End location: 64:51

masterCrossChecker.xsl
template name="rdfExtractor"
xsl:apply-templates select="rdf:Description" mode="generateDAVIDTitle"

masterCrossChecker.xsl
template match="rdf:Description" mode="generateDAVIDTitle"
System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: 'DAVID Title' changes depending on system, since DAVID generates its own filenames
XPath location: /xsl:stylesheet[1]/xsl:template[2]/comment()[1]
Start location: 65:9
End location: 65:107

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: concat('File ', @rdf:about, ' is in DAVID')
XPath location: /xsl:stylesheet[1]/xsl:template[2]/xsl:choose[1]/xsl:when[1]/xsl:message[1]/xsl:value-of[1]/@select

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: concat('File ', @rdf:about, ' has a DAVID Title ', $dbxTitle, ' in its DBX.')
XPath location: /xsl:stylesheet[1]/xsl:template[2]/xsl:choose[1]/xsl:when[1]/xsl:message[2]/xsl:value-of[1]/@select

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: concat('The embedded DAVID Title ', RIFF:Description, ' will be overwritten.')
XPath location: /xsl:stylesheet[1]/xsl:template[2]/xsl:choose[1]/xsl:when[1]/xsl:if[1]/xsl:message[1]/xsl:value-of[1]/@select

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: concat('This file is not in DAVID. We will use _', $filename, '_ as its DAVID title.')
XPath location: /xsl:stylesheet[1]/xsl:template[2]/xsl:choose[1]/xsl:otherwise[1]/xsl:message[1]/xsl:value-of[1]/@select

parseDAVIDTitle.xsl
template name="checkDAVIDTitle"
System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: Check whether filename or DAVID Title conforms to the NYPR naming convention 'COLL-SERI-YYYY-MM-DD-xxxx.a Free text'         where filename length is less than 78 characters, and         where          COLL: Collection acronym (3-4 characters)         SERI: Series acronym (3-4 characters)         YYYY-MM-DD: earliest known relevant date, with 'u' for unknowns         xxxx: Asset number         xxxx.a: instantiation number
XPath location: /xsl:stylesheet[1]/xsl:template[1]/comment()[1]
Start location: 12:9
End location: 20:12

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: Determine generation based on suffix
XPath location: /xsl:stylesheet[1]/xsl:template[2]/comment()[1]
Start location: 137:9
End location: 137:54

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: determine MUNI number
XPath location: /xsl:stylesheet[1]/xsl:template[2]/comment()[2]
Start location: 151:9
End location: 151:37

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: determine MUNI format based on T or LT
XPath location: /xsl:stylesheet[1]/xsl:template[2]/comment()[3]
Start location: 162:9
End location: 162:54

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: Output as 'parsedTitle'
XPath location: /xsl:stylesheet[1]/xsl:template[2]/comment()[4]
Start location: 180:9
End location: 180:41

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: concat(' Now checking whether DAVID Title _', $DAVIDTitle, '_ conforms to NYPR Archives naming convention.')
XPath location: /xsl:stylesheet[1]/xsl:template[1]/xsl:message[1]/xsl:value-of[1]/@select
Start location: 26:27
End location: 26:144

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: concat('FILENAME TOO LONG! Maximum DAVID title is 78 characters, and yours has ', string-length($DAVIDTitle), '.')
XPath location: /xsl:stylesheet[1]/xsl:template[1]/xsl:choose[1]/xsl:when[1]/xsl:message[1]/@select
Start location: 31:25
End location: 31:148

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: concat($DAVIDTitle, ' does not conform to the NYPR Archives naming convention.')
XPath location: /xsl:stylesheet[1]/xsl:template[1]/xsl:choose[1]/xsl:when[2]/xsl:message[1]/@select
Start location: 37:25
End location: 37:114

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: concat($DAVIDTitle, ' conforms to the NYPR Archives naming convention.')
XPath location: /xsl:stylesheet[1]/xsl:template[1]/xsl:choose[1]/xsl:otherwise[1]/xsl:message[1]/@select
Start location: 52:29
End location: 52:110

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: Determine generation based on suffix
XPath location: /xsl:stylesheet[1]/xsl:template[2]/comment()[1]
Start location: 137:9
End location: 137:54

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: determine MUNI number
XPath location: /xsl:stylesheet[1]/xsl:template[2]/comment()[2]
Start location: 151:9
End location: 151:37

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: determine MUNI format based on T or LT
XPath location: /xsl:stylesheet[1]/xsl:template[2]/comment()[3]
Start location: 162:9
End location: 162:54

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\parseDAVIDTitle.xsl
Description: Output as 'parsedTitle'
XPath location: /xsl:stylesheet[1]/xsl:template[2]/comment()[4]
Start location: 180:9
End location: 180:41



template match="rdf:Description" mode="cross-checker" name="cross-checker"

From parsed DAVID title: collectionAcronym, seriesAcronym, filenameDate, assetID, instantiationID, freeText, parsedCollectionxml (via a concordance), parsedSeriesURL (from a cavafy search), collectionName (via a concordance), seriesName (via cavafy search using SRSLST), seriesURL (via cavafy search using SRSLST), parsedMedium (from T/LT in MUNI titles), filenameDateTranslated (changing 'uu' to '01', etc), generation (from 'WEB EDIT', etc), theme (archive_importassetID), mp3URL (http://audio.wnyc.org/archive_import'), seriesxml (via cavafy search using SRSLST), seriesData (via cavafy search using SRSLST), translatedFileName (for internal purposes: changes '/' to '\')

XMP fields: cmsImageID
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[20]
Start location: 317:9
End location: 328:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="originalMedium" select="RIFF:Medium"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[22]
Start location: 334:9
End location: 334:67

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="provenance"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[23]
Start location: 336:9
End location: 347:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="shelfLocation"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[24]
Start location: 351:9
End location: 351:45

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="locationOfOriginalRecording"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[25]
Start location: 352:9
End location: 352:59

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="transcript"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[26]
Start location: 353:9
End location: 353:42

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="shortDescription"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[27]
Start location: 354:9
End location: 354:48

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="imageID"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[28]
Start location: 355:9
End location: 355:39

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="imageURL"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[29]
Start location: 356:9
End location: 356:40

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="provenance"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[30]
Start location: 357:9
End location: 368:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="markers"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[31]
Start location: 370:9
End location: 370:39

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="turnover"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[32]
Start location: 372:9
End location: 372:40

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="rolloff"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[33]
Start location: 373:9
End location: 373:39

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="stylusSize"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[34]
Start location: 374:9
End location: 374:42

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="catalogURL"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[35]
Start location: 378:9
End location: 422:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="catalogURLFromAXML"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[35]/xsl:variable[1]
Start location: 380:13
End location: 406:28

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="searchedCavafyURL"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[35]/xsl:variable[2]
Start location: 407:13
End location: 414:28

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="catalogxml" select="concat(normalize-space($catalogURL), '.xml')"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[36]
Start location: 424:9
End location: 424:96

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: as="element()" name="catalogEntry"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[37]
Start location: 426:9
End location: 430:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="cavafyCollection" select="$catalogEntry//*[local-name() = 'pbcoreTitle'][@titleType = 'Collection']"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[38]
Start location: 440:9
End location: 441:97

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="cavafySeries" select="$catalogEntry//*[local-name() = 'pbcoreTitle'][@titleType = 'Series']"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[39]
Start location: 449:9
End location: 450:93

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="cavafyTitle" select="$catalogEntry//*[local-name() = 'pbcoreTitle'][@titleType = 'Episode']"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[40]
Start location: 452:9
End location: 453:94

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="genresAlreadyInCavafy"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[41]
Start location: 461:9
End location: 465:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="genre"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[42]
Start location: 482:9
End location: 494:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="contributorsAlreadyInCavafy"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[43]
Start location: 496:9
End location: 502:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="subjectsAlreadyInCavafy"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[44]
Start location: 504:9
End location: 508:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="abstractAlreadyInCavafy"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[45]
Start location: 517:9
End location: 522:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="producersAlreadyInCavafy"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[46]
Start location: 534:9
End location: 540:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="publishersAlreadyInCavafy"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[47]
Start location: 542:9
End location: 548:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="engineersAlreadyInCavafy"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[48]
Start location: 550:9
End location: 556:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="instantiationIDsAlreadyInCavafy"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[49]
Start location: 558:9
End location: 563:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: as="element()*" name="matchingInstantiation"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[50]
Start location: 571:9
End location: 603:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="instantiationIDSource" select="$catalogEntry//*[local-name() = 'pbcoreDescriptionDocument']/*[local-name() = 'pbcoreInstantiation']/*[local-name() = 'instantiationIdentifier'][. = $instantiationID]/[@source]"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[50]/xsl:if[1]/xsl:copy[1]/xsl:for-each[1]/xsl:variable[1]
Start location: 578:25
End location: 579:216

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="physInstantiationType"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[50]/xsl:if[1]/xsl:copy[1]/xsl:for-each[1]/xsl:variable[2]
Start location: 587:25
End location: 589:40

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="dbxURI" select="concat(substring-before(@rdf:about, '.'), '.DBX')"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:if[8]/xsl:variable[1]
Start location: 621:13
End location: 621:101

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="dbxData" select="document($dbxURI)"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:if[8]/xsl:variable[2]
Start location: 623:13
End location: 623:70

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="dbxSoftDeleted" select="$dbxData/ENTRIES/ENTRY/SOFTDELETED"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:if[8]/xsl:variable[3]
Start location: 624:13
End location: 624:94

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="dbxTitle" select="$dbxData/ENTRIES/ENTRY/TITLE"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:if[8]/xsl:variable[4]
Start location: 625:13
End location: 625:82

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="dbxCreator" select="$dbxData/ENTRIES/ENTRY/CREATOR"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:if[8]/xsl:variable[5]
Start location: 626:13
End location: 626:86

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="dbxAuthor" select="$dbxData/ENTRIES/ENTRY/AUTHOR"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:if[8]/xsl:variable[6]
Start location: 627:13
End location: 627:84

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="dbxEditor" select="$dbxData/ENTRIES/ENTRY/EDITOR"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:if[8]/xsl:variable[7]
Start location: 628:13
End location: 628:84

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="dbxBroadcastDate" select="$dbxData/ENTRIES/ENTRY/BROADCASTDATE"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:if[8]/xsl:variable[8]
Start location: 629:13
End location: 629:98

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="dbxRemark" select="$dbxData/ENTRIES/ENTRY/REMARK"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:if[8]/xsl:variable[9]
Start location: 630:13
End location: 630:84

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="dbxTheme" select="$dbxData/ENTRIES/ENTRY/MOTIVE"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:if[8]/xsl:variable[10]
Start location: 631:13
End location: 631:83

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: as="element()*" name="mergedFields"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]
Start location: 637:9
End location: 1009:24

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="mergedContributors"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[7]/xsl:variable[1]
Start location: 694:17
End location: 700:32

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="mergedCreatorsProducersCollection"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[8]/xsl:variable[1]
Start location: 723:17
End location: 729:32

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="mergedCavafyPublishersProducers"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[8]/xsl:variable[2]
Start location: 730:17
End location: 737:32

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="mergedCreatorsProducersCollectionPublishersProducers"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[8]/xsl:variable[3]
Start location: 739:17
End location: 746:32

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="mergedEngineers"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[12]/xsl:variable[1]
Start location: 809:17
End location: 814:32

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="subjectsAndKeywords"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:variable[1]
Start location: 829:13
End location: 844:28

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="untrimmedNarrowedSubjectsAndKeywords"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:variable[2]
Start location: 848:13
End location: 852:28

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="narrowedSubjectsAndKeywords"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:variable[3]
Start location: 854:13
End location: 859:28

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="filename"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[1]
Start location: 639:13
End location: 641:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="DAVIDTitle"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[2]
Start location: 642:13
End location: 644:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="codingHistory"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[3]
Start location: 645:13
End location: 678:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="assetID"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[4]
Start location: 680:13
End location: 682:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="collectionAcronym"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[5]
Start location: 684:13
End location: 686:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="seriesData"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[6]
Start location: 688:13
End location: 690:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="contributors"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[7]
Start location: 692:13
End location: 717:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="creators"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[8]
Start location: 721:13
End location: 758:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="comments"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[9]
Start location: 760:13
End location: 777:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="copyrightNotice"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[10]
Start location: 779:13
End location: 802:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="relevantDate"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[11]
Start location: 804:13
End location: 806:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="originalRecordingEngineers"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[12]
Start location: 808:13
End location: 823:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="genre"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[13]
Start location: 825:13
End location: 827:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="subjectsAndKeywords"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[14]
Start location: 864:13
End location: 866:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="narrowedSubjectsAndKeywords"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[15]
Start location: 868:13
End location: 870:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="subjects"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[16]
Start location: 872:13
End location: 874:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="keywords"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[17]
Start location: 878:13
End location: 880:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="title"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[18]
Start location: 883:13
End location: 900:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="originalMedium"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[19]
Start location: 902:13
End location: 915:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="series"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[20]
Start location: 917:13
End location: 949:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="description"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[21]
Start location: 951:13
End location: 965:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="software"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[22]
Start location: 967:13
End location: 977:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="catalogURL"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[23]
Start location: 979:13
End location: 981:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="generation"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[24]
Start location: 983:13
End location: 985:27

System ID: H:\02 CATALOGING\Instantiation uploads\InstantiationUploadTEMPLATES\masterCrossChecker.xsl
Description: name="transferTechnician"
XPath location: /xsl:stylesheet[1]/xsl:template[4]/xsl:variable[51]/xsl:element[25]
Start location: 987:13
End location: 1008:27


