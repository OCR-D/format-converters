<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
xmlns="http://www.tei-c.org/ns/1.0" xmlns:t="http://www.tei-c.org/ns/1.0"
xmlns:h="http://www.w3.org/1999/xhtml">
<xsl:output method="xml" encoding="UTF-8"/>

<!-- the first version and the origin stylesheet from https://sourceforge.net/p/epidoc/code/HEAD/tree/trunk/hocr2tei/xslt/
see alternative https://wiki.tei-c.org/index.php/HOCR2TEI
13.03.2018 Matthias Boenig correct and expand the origin XSL-Stylesheet
-->

<xsl:variable name="document-uri" select="document-uri(.)"/>

<xsl:variable name="filename1" select="(tokenize($document-uri,'/'))[last()]"/>

<xsl:variable name="without_extension" select="tokenize($filename1, '\.')[1]"/>



<xsl:variable name="filename">
<xsl:value-of select="substring-before(base-uri(), '.')"/>
</xsl:variable>


<xsl:template match="h:html">
<xsl:processing-instruction name="xml-model">
            href="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng" type="application/xml" 
            schematypens="http://relaxng.org/ns/structure/1.0"
        </xsl:processing-instruction>
<xsl:element name="TEI">
<xsl:apply-templates/>
</xsl:element>
</xsl:template>

<xsl:template match="h:head">
<xsl:element name="teiHeader">
<xsl:element name="fileDesc">
<xsl:element name="titleStmt">
<xsl:element name="title">
<xsl:value-of select="h:title"/>
</xsl:element>
</xsl:element>
<xsl:element name="publicationStmt">
<xsl:element name="p"/>
</xsl:element>
<xsl:element name="sourceDesc">
<xsl:element name="p">
<xsl:value-of select="h:meta[@name = 'description']/@content"/>
</xsl:element>
</xsl:element>
</xsl:element>
</xsl:element>

<xsl:element name="facsimile">
<xsl:for-each select="//h:div[@class = 'ocr_page']">
<xsl:element name="surface">
<xsl:element name="graphic">
<xsl:attribute name="url" select="substring-after(./@title, 'image ')"/>
</xsl:element>
<xsl:for-each select="//h:div[starts-with(@title, 'bbox')]">
<xsl:element name="zone">
<xsl:attribute name="xml:id">
<xsl:value-of select="$without_extension"/>_<xsl:value-of select="concat(@class, '_', count(preceding::h:*[@class = current()/@class]))"/>
</xsl:attribute>
<xsl:attribute name="ulx" select="tokenize(@title, ' ')[2]"/>
<xsl:attribute name="uly" select="tokenize(@title, ' ')[3]"/>
<xsl:attribute name="lrx" select="tokenize(@title, ' ')[4]"/>
<xsl:attribute name="lry" select="tokenize(@title, ' ')[5]"/>
</xsl:element>
</xsl:for-each>
<xsl:for-each select="//h:p[starts-with(@title, 'bbox')]">
<xsl:element name="zone">
<xsl:attribute name="xml:id">
<xsl:value-of select="$without_extension"/>_<xsl:value-of select="concat(@class, '_', count(preceding::h:*[@class = current()/@class]))"/>
</xsl:attribute>
<xsl:attribute name="ulx" select="tokenize(@title, ' ')[2]"/>
<xsl:attribute name="uly" select="tokenize(@title, ' ')[3]"/>
<xsl:attribute name="lrx" select="tokenize(@title, ' ')[4]"/>
<xsl:attribute name="lry" select="tokenize(@title, ' ')[5]"/>
</xsl:element>
</xsl:for-each>
<xsl:for-each select="//h:span[starts-with(@title, 'bbox')]">
<xsl:element name="zone">
<xsl:attribute name="xml:id">
<xsl:value-of select="$without_extension"/>_<xsl:value-of select="concat(@class, '_', count(preceding::h:*[@class = current()/@class]))"/>
</xsl:attribute>
<xsl:attribute name="ulx" select="tokenize(@title, ' ')[2]"/>
<xsl:attribute name="uly" select="tokenize(@title, ' ')[3]"/>
<xsl:attribute name="lrx" select="tokenize(@title, ' ')[4]"/>
<xsl:attribute name="lry" select="tokenize(@title, ' ')[5]"/>
</xsl:element>
</xsl:for-each>
</xsl:element>
</xsl:for-each>
</xsl:element>
</xsl:template>


<xsl:template match="h:body">
<xsl:element name="text">
<xsl:element name="body">
<xsl:choose>
<xsl:when test="descendant::h:p[@class = 'ocr_par']">
<xsl:apply-templates/>
</xsl:when>
<xsl:otherwise>
<xsl:element name="div">
<xsl:apply-templates/>
</xsl:element>
</xsl:otherwise>
</xsl:choose>
</xsl:element>
</xsl:element>
</xsl:template>

<xsl:template match="//h:div[@class = 'meta']"/>


<xsl:template match="h:p">
<xsl:choose>
<xsl:when test="@class='ocr_par'">
<xsl:element name="p">
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
<xsl:when test="@style='text-align: justify;'">
<xsl:element name="p">
<xsl:attribute name="rendition">#block</xsl:attribute>
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
<xsl:when test="@style='text-align: left;'">
<xsl:element name="p">
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
<xsl:when test="@style='text-align: right;'">
<xsl:element name="p">
<xsl:attribute name="rendition">#right</xsl:attribute>
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
<xsl:when test="@style='text-align: center;'">
<xsl:element name="p">
<xsl:attribute name="rendition">#c</xsl:attribute>
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
<xsl:otherwise>
<xsl:element name="p">
<xsl:apply-templates/>
</xsl:element>
</xsl:otherwise>
</xsl:choose>
</xsl:template>


<xsl:template match="h:div">
<xsl:choose>
<xsl:when test="@class = 'ocr_page'">
<xsl:element name="div">
<xsl:element name="pb">
<xsl:call-template name="at-facs"/>
<xsl:if test="descendant::h:span[@class = 'tei_pb']">
<xsl:attribute name="n">
<xsl:value-of select="descendant::h:span[@class = 'tei_pb'][1]"/>
</xsl:attribute>
</xsl:if>
</xsl:element>
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
<xsl:when test="@class = 'ocr_table'">
<xsl:element name="div">
<xsl:call-template name="at-facs"/>
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
<xsl:when test="@class = 'ocr_carea'">
<xsl:element name="div">
<xsl:call-template name="at-facs"/>
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
<xsl:when test="@class = 'ocr_image'">
<xsl:element name="div">
<xsl:call-template name="at-facs"/>
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
</xsl:choose>
</xsl:template>


<xsl:template match="h:span[@class = 'ocr_line']">
<xsl:element name="lb">
<xsl:call-template name="at-facs"/>
<xsl:if test="descendant::h:span[@class = 'tei_lb']">
<xsl:attribute name="n">
<xsl:value-of select="descendant::h:span[@class = 'tei_lb'][1]"/>
</xsl:attribute>
</xsl:if>
</xsl:element>
<xsl:apply-templates/>
</xsl:template>


<xsl:template match="h:span[@class = 'ocr_word']">
<xsl:choose>
<xsl:when test=". = ('-', '.', ',', ':', ';', '?,', '!', '·', '—')">
<xsl:element name="pc">
<xsl:call-template name="at-facs"/>
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
<xsl:otherwise>
<xsl:element name="w">
<xsl:call-template name="at-facs"/>
<xsl:apply-templates/>
</xsl:element>
</xsl:otherwise>
</xsl:choose>
</xsl:template>


<xsl:template match="h:span[starts-with(@class, 'tei_')]">
<xsl:choose>
<xsl:when test="substring-after(@class, 'tei_') = ('pb', 'lb')"/>
<xsl:otherwise>
<xsl:element name="{substring-after(@class,'tei_')}">
<xsl:call-template name="at-facs"/>
<xsl:apply-templates/>
</xsl:element>
</xsl:otherwise>
</xsl:choose>
</xsl:template>


<xsl:template name="at-facs">
<xsl:if test="starts-with(@title, 'bbox')">
<xsl:attribute name="facs">
<xsl:value-of select="concat('#', @class, '_', count(preceding::*[@class = current()/@class]))"/>
</xsl:attribute>
</xsl:if>
</xsl:template>


<!-- Formating -->

<xsl:template match="h:b">
<xsl:element name="hi">
<xsl:attribute name="rendition">#b</xsl:attribute>
<xsl:apply-templates/>
</xsl:element>
</xsl:template>


<xsl:template match="h:em">
<xsl:element name="hi">
<xsl:attribute name="rendition">#i</xsl:attribute>
<xsl:apply-templates/>
</xsl:element>
</xsl:template>


<xsl:template match="h:span">
<xsl:choose>
<xsl:when test="@style = 'letter-spacing: 0.25em;'">
<xsl:element name="hi">
<xsl:attribute name="rendition">#g</xsl:attribute>
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
<xsl:when test="@style = 'font-variant:small-caps;'">
<xsl:element name="hi">
<xsl:attribute name="rendition">#k</xsl:attribute>
<xsl:apply-templates/>
</xsl:element>
</xsl:when>
<xsl:otherwise>
<xsl:apply-templates/>
</xsl:otherwise>
</xsl:choose>
</xsl:template>

<!--Tables-->

<xsl:template match="h:table">
<xsl:element name="table">
<xsl:apply-templates/>
</xsl:element>
</xsl:template>

<xsl:template match="h:tr">
<xsl:element name="row">
<xsl:apply-templates/>
</xsl:element>
</xsl:template>


<xsl:template match="h:td">
<xsl:element name="cell">
<xsl:apply-templates/>
</xsl:element>
</xsl:template>




<xsl:template match="*/text()[normalize-space()]">
<xsl:value-of select="normalize-space()"/>
</xsl:template>

<xsl:template match="*/text()[not(normalize-space())]"/>




</xsl:stylesheet>
