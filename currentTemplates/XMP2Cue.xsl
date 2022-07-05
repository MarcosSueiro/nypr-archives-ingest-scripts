<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:System="http://ns.exiftool.ca/File/System/1.0/"
    xmlns:File="http://ns.exiftool.ca/File/1.0/"
    xmlns:XMP-xmpDM="http://ns.exiftool.ca/XMP/XMP-xmpDM/1.0/" xmlns:x="adobe:ns:meta/"
    exclude-result-prefixes="#all" version="3.0">

    <xsl:mode on-no-match="deep-skip"/>
    <xsl:mode name="XMP" on-no-match="shallow-copy"/>

    <xsl:output method="xml" indent="yes" encoding="ASCII"/>

    <xsl:import href="utilities.xsl"/>

    <xsl:param name="generateNewCueXMLs" select="true()"/>
    <xsl:param name="generateNewXMPs" select="true()"/>

    <!-- Fix marker data -->
    <!-- Input:XMP docs from exiftool -->
    <!-- Output: XMP and cue docs that *only* keep: -->
    <!-- 'Side_01' markers with an accompanying 'Side_XX' -->
    <!-- Any markers with comments -->
    <!-- All other markers -->
    <!-- Test site: https://xsltfiddle.liberty-development.net/93F8dV8/5 -->
    <!-- Detailed instructions at the bottom of this document -->

    <xsl:template match="x:xmpmeta">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="rdf:RDF">
        <xsl:apply-templates/>
        <xsl:apply-templates select=".[$generateNewXMPs]" mode="XMP"/>
    </xsl:template>

    <xsl:template match="rdf:Description">
        <xsl:param name="sourceFilePath">
            <xsl:value-of select="@rdf:about"/>
        </xsl:param>
        <xsl:param name="isXMP" select="
                ends-with($sourceFilePath, 'XMP.xml')"/>
        <xsl:param name="sourceFilePathParsed">
            <xsl:apply-templates select=".[$isXMP]" mode="parseFilePath"/>
        </xsl:param>
        <xsl:apply-templates>
            <xsl:with-param name="sourceFilePath" tunnel="yes" select="
                    $sourceFilePath"/>
            <xsl:with-param name="sourceFilePathParsed" tunnel="yes" select="
                    $sourceFilePathParsed"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="rdf:Description" mode="XMP">
        <xsl:param name="sourceFilePath">
            <xsl:value-of select="@rdf:about"/>
        </xsl:param>
        <xsl:param name="isXMP" select="
                ends-with($sourceFilePath, 'XMP.xml')"/>
        <xsl:param name="sourceFilePathParsed">
            <xsl:apply-templates select=".[$isXMP]" mode="parseFilePath"/>
        </xsl:param>
        <xsl:param name="newXMP">
            <x:xmpmeta xmlns:x="adobe:ns:meta/"
                x:xmptk="Adobe XMP Core 5.6-c148 79.163765, 2019/01/24-18:11:46        ">
                <xsl:copy>
                    <xsl:apply-templates mode="XMP"/>
                </xsl:copy>
            </x:xmpmeta>
        </xsl:param>
        <xsl:copy-of select="$newXMP"/>
        <xsl:apply-templates select="$newXMP/x:xmpmeta" mode="generateNewXMPs">
            <xsl:with-param name="sourceFilePathParsed" select="$sourceFilePathParsed"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="XMP-xmpDM:Tracks">
        <xsl:apply-templates/>
    </xsl:template>


    <xsl:template match="
            rdf:Bag
            [rdf:li[@rdf:parseType = 'Resource']/
            XMP-xmpDM:Markers]">
        <xsl:apply-templates/>
    </xsl:template>


    <xsl:template match="
            rdf:li
            [@rdf:parseType = 'Resource']
            [XMP-xmpDM:Markers]">
        <xsl:apply-templates/>
    </xsl:template>



    <xsl:template match="XMP-xmpDM:Markers">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="XMP-xmpDM:Markers" mode="XMP">
        <xsl:copy select="
                .[(rdf:Bag/rdf:li/
                XMP-xmpDM:Name != 'Side_01')
                or
                (rdf:Bag/rdf:li/
                XMP-xmpDM:Comment)
                ]">
            <xsl:copy select="rdf:Bag">
                <xsl:for-each select="
                        (rdf:li
                        [@rdf:parseType = 'Resource']
                        [XMP-xmpDM:CuePointParams]
                        [XMP-xmpDM:Name = 'Side_01']
                        [following-sibling::rdf:li
                        [XMP-xmpDM:Name [matches(., 'Side_')]]])
                        |
                        (rdf:li
                        [@rdf:parseType = 'Resource']
                        [XMP-xmpDM:CuePointParams]
                        [XMP-xmpDM:Comment])                        
                        |
                        (rdf:li
                        [@rdf:parseType = 'Resource']
                        [XMP-xmpDM:CuePointParams]
                        [XMP-xmpDM:Name != 'Side_01'])">
                    <xsl:sort select="XMP-xmpDM:StartTime"/>
                    <xsl:copy-of select="."/>
                </xsl:for-each>
            </xsl:copy>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="
            rdf:Bag
            [(rdf:li/
            XMP-xmpDM:Name != 'Side_01')
            or
            (rdf:li/
            XMP-xmpDM:Comment)
            ]">
        <!-- Process files with other markers besides 'Side_01' or with comments -->
        <!-- Or, if it has 'Side_01' and no comments, make sure it also has 'Side_XX' -->
        <xsl:param name="sourceFilePath" tunnel="yes"/>
        <xsl:param name="Cues">
            <Cues>
                <xsl:apply-templates select="
                        (rdf:li
                        [@rdf:parseType = 'Resource']
                        [XMP-xmpDM:CuePointParams]
                        [XMP-xmpDM:Name = 'Side_01']
                        [following-sibling::rdf:li
                        [XMP-xmpDM:Name [matches(., 'Side_')]]])
                        |
                        (rdf:li
                        [@rdf:parseType = 'Resource']
                        [XMP-xmpDM:CuePointParams]
                        [XMP-xmpDM:Comment])
                        |
                        (rdf:li
                        [@rdf:parseType = 'Resource']
                        [XMP-xmpDM:CuePointParams]
                        [XMP-xmpDM:Name != 'Side_01'])">
                    <xsl:sort select="XMP-xmpDM:StartTime"/>
                </xsl:apply-templates>
            </Cues>

        </xsl:param>

        <!--<xsl:copy-of select="$Cues"/>-->
        <xsl:apply-templates select="
                $Cues/Cues[Cue][$generateNewCueXMLs]" mode="generateNewCueXMLs"/>

    </xsl:template>




    <xsl:template match="
            rdf:li
            [@rdf:parseType = 'Resource']
            [XMP-xmpDM:CuePointParams]
            ">
        <xsl:param name="duration" select="XMP-xmpDM:Duration"/>
        <Cue>
            <ID>
                <xsl:value-of select="position()"/>
            </ID>
            <Position>
                <xsl:value-of select="XMP-xmpDM:StartTime"/>
            </Position>
            <DataChunkID>0x64617461</DataChunkID>
            <ChunkStart>0</ChunkStart>
            <BlockStart>0</BlockStart>
            <SampleOffset>
                <xsl:value-of select="XMP-xmpDM:StartTime"/>
            </SampleOffset>
            <Label>
                <xsl:value-of select="XMP-xmpDM:Name"/>
            </Label>
            <xsl:apply-templates select="XMP-xmpDM:Comment"/>
            <LabeledText>
                <SampleLength>
                    <xsl:apply-templates select="$duration[matches(., '\d')]"/>
                    <xsl:value-of select="'0'[not(matches($duration, '\d'))]"/>
                </SampleLength>
                <PurposeID>0x72676E20</PurposeID>
                <Country>0</Country>
                <Language>0</Language>
                <Dialect>0</Dialect>
                <CodePage>0</CodePage>
                <Text/>
            </LabeledText>
        </Cue>
    </xsl:template>

    <xsl:template match="
            (rdf:li
            [@rdf:parseType = 'Resource']
            [XMP-xmpDM:CuePointParams]
            [XMP-xmpDM:Name = 'Side_01']
            [not(following-sibling::rdf:li
            [XMP-xmpDM:Name [matches(., 'Side_')]])])
            |
            (rdf:li
            [@rdf:parseType = 'Resource']
            [XMP-xmpDM:CuePointParams]
            [not(XMP-xmpDM:Comment)])
            |
            (rdf:li
            [@rdf:parseType = 'Resource']
            [XMP-xmpDM:CuePointParams]
            [not(XMP-xmpDM:Name != 'Side_01')])" mode="XMP">
        <xsl:param name="duration" select="XMP-xmpDM:Duration"/>
        <Cue>
            <ID>
                <xsl:value-of select="position()"/>
            </ID>
            <Position>
                <xsl:value-of select="XMP-xmpDM:StartTime"/>
            </Position>
            <DataChunkID>0x64617461</DataChunkID>
            <ChunkStart>0</ChunkStart>
            <BlockStart>0</BlockStart>
            <SampleOffset>
                <xsl:value-of select="XMP-xmpDM:StartTime"/>
            </SampleOffset>
            <Label>
                <xsl:value-of select="XMP-xmpDM:Name"/>
            </Label>
            <LabeledText>
                <SampleLength>
                    <xsl:apply-templates select="$duration[matches(., '\d')]"/>
                    <xsl:value-of select="'0'[not(matches($duration, '\d'))]"/>
                </SampleLength>
                <PurposeID>0x72676E20</PurposeID>
                <Country>0</Country>
                <Language>0</Language>
                <Dialect>0</Dialect>
                <CodePage>0</CodePage>
                <Text/>
            </LabeledText>
        </Cue>
    </xsl:template>



    <xsl:template match="XMP-xmpDM:Duration">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:template match="XMP-xmpDM:Comment">
        <Note>
        <xsl:value-of select="."/>
        </Note>
    </xsl:template>

    <xsl:template match="Cues" mode="generateNewCueXMLs">
        <xsl:param name="sourceFilePath" tunnel="yes"/>
        <xsl:param name="sourceFilePathParsed" tunnel="yes"/>
        <xsl:param name="destinationFilePath">
            <xsl:value-of select="'file:///'"/>
            <xsl:value-of select="$sourceFilePathParsed/rdf:Description/System:Directory"/>
            <xsl:value-of select="'/'"/>
            <xsl:value-of
                select="replace($sourceFilePathParsed/rdf:Description/System:FileName, '\.wav\.XMP\.xml', '.wav.cue.xml')"
            />
        </xsl:param>
        <xsl:result-document href="{$destinationFilePath}">
            <xsl:copy-of select="."/>
        </xsl:result-document>
    </xsl:template>

    <xsl:template match="x:xmpmeta" mode="generateNewXMPs">
        <xsl:param name="sourceFilePath"/>
        <xsl:param name="sourceFilePathParsed"/>
        <xsl:param name="destinationFilePath">
            <xsl:value-of select="'file:///'"/>
            <xsl:value-of select="$sourceFilePathParsed/rdf:Description/System:Directory"/>
            <xsl:value-of select="'/newXMPs/'"/>
            <xsl:value-of select="$sourceFilePathParsed/rdf:Description/System:FileName"/>
        </xsl:param>
        <xsl:result-document href="{$destinationFilePath}">
            <xsl:copy-of select="."/>
        </xsl:result-document>
    </xsl:template>

    <!-- FULL PROCEDURE -->
    <!-- Assuming XMP data is the source, and you need to create new cue data -->
    <!-- ALL bwfmetaedit commands need two dashes, but cannot reproduce here -->
    <!-- 1. If present, delete (or move) all cue xmls, and then... -->
    <!-- 2. Export XMPs via "bwfmetaedit [two dashes: ] -\-out-XMP-xml [directory]/*.wav" -->
    <!-- 3. Gather all XMPs into one document via exiftool -X -a -struct [directory]*.XMP.xml -->
    <!-- 4. Move the XMPs to a separate directory, just in case -->
    <!-- 5. Transform resulting document with XMP2Cue.xsl -->
    <!-- 6. Inspect results, then move the new XMPs into the source directory -->
    <!-- 7. Import new cue docs via bwfmetaedit -\-in-cue-xml -\-continue-errors [directory]*.wav -->
    <!-- 8. Import new XMP docs via bwfmetaedit -\-in-XMP-xml -\-continue-errors [directory]*.wav -->

</xsl:stylesheet>