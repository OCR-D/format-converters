<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:ns0="http://www.abbyy.com/FineReader_xml/FineReader6-schema-v1.xml"
  xmlns:ns1="http://www.abbyy.com/FineReader_xml/FineReader8-schema-v2.xml"
  xmlns:ns2="http://www.abbyy.com/FineReader_xml/FineReader9-schema-v1.xml"
  xmlns:ns3="http://www.abbyy.com/FineReader_xml/FineReader10-schema-v1.xml">

<!--
First Author: Rod Page Source: http://iphylo.blogspot.com/2011/07/correcting-ocr-using-hocr-firefox.html
see alternative https://gist.github.com/tfmorris/5977784

13.03.2018 (5 years ago) Matthias Boenig correct and expand the XSL-Stylesheet
-->

<xsl:namespace-alias stylesheet-prefix="ns0" result-prefix=""/>
<xsl:namespace-alias stylesheet-prefix="ns1" result-prefix=""/>
<xsl:namespace-alias stylesheet-prefix="ns2" result-prefix=""/>
<xsl:namespace-alias stylesheet-prefix="ns3" result-prefix=""/>
<xsl:output method="html" encoding="UTF-8"/>
<xsl:strip-space elements="*"/>


<xsl:param name="ImageFile_Path_and_ImageFile"></xsl:param>
<xsl:param name="ImageFile_format"></xsl:param>
<xsl:param name="CSS_Stylesheet"></xsl:param>
    
<xsl:variable name="document-uri" select="document-uri(.)"/>
<xsl:variable name="filename" select="(tokenize($document-uri,'/'))[last()]"/>
<xsl:variable name="without_extension" select="tokenize($filename, '\.')[1]"/>

<xsl:template match="ns0:document|ns1:document|ns2:document|ns3:document">
  <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE HTML&gt;
</xsl:text>
  <html>
    <head>
      <xsl:if test="normalize-space($ImageFile_Path_and_ImageFile) != ''">
        <link rel="stylesheet"><xsl:attribute name="href"><xsl:value-of select="$CSS_Stylesheet"/></xsl:attribute></link>
      </xsl:if>
      <title>OCR Output</title>
      <meta name="description"><xsl:attribute name="content">OCR Output produced by <xsl:value-of select="./@producer"/></xsl:attribute></meta>
    </head>
    <body>
      <xsl:apply-templates select="//ns0:page|//ns1:page|//ns2:page|//ns3:page" />
    </body>
  </html>
</xsl:template>

<xsl:template match="ns0:page|ns1:page|ns2:page|ns3:page">
  <div class="ocr_page">
    <xsl:attribute name="title">
      <xsl:text>bbox 0 0 </xsl:text>
      <xsl:value-of select="@width" />
      <xsl:text> </xsl:text>
      <xsl:value-of select="@height" />
      <xsl:if test="normalize-space($ImageFile_Path_and_ImageFile) != ''">
        <xsl:text> image </xsl:text><xsl:text> </xsl:text><xsl:value-of select="$ImageFile_Path_and_ImageFile"/>.<xsl:value-of select="$ImageFile_format"/><xsl:text></xsl:text>
      </xsl:if>
    </xsl:attribute>
    <xsl:apply-templates select="ns0:block|ns1:block|ns2:block|ns3:block" />
  </div>
</xsl:template>

<xsl:template match="ns0:block|ns1:block|ns2:block|ns3:block">
  <xsl:choose>
    <xsl:when test="@blockType='Picture'">
      <xsl:element name="div">
        <xsl:attribute name="class">ocr_image</xsl:attribute>
        <xsl:attribute name="title">
          <xsl:text>bbox </xsl:text>
          <xsl:value-of select="@l"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@t"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@r"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@b"/>
        </xsl:attribute>
      </xsl:element>
    </xsl:when>
    <xsl:when test="@blockType='Table'">
      <xsl:element name="div">
        <xsl:attribute name="class">ocr_table</xsl:attribute>
        <xsl:attribute name="title">
          <xsl:text>bbox </xsl:text>
          <xsl:value-of select="@l"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@t"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@r"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@b"/>
        </xsl:attribute>
        <xsl:element name="table">
          <xsl:apply-templates select="ns0:row|ns1:row|ns2:row|ns3:row"/>
        </xsl:element>
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="div">
        <xsl:attribute name="class">ocr_carea</xsl:attribute>
        <xsl:attribute name="title">
          <xsl:text>bbox </xsl:text>
          <xsl:value-of select="@l"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@t"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@r"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@b"/>
        </xsl:attribute>
        <xsl:apply-templates select="ns0:text/ns0:par|ns1:text/ns1:par|ns2:text/ns2:par|ns3:text/ns3:par"/>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="ns0:par|ns1:par|ns2:par|ns3:par">
  <xsl:variable name="bbox" as="item()">
    <xsl:attribute name="title">
      <xsl:text>bbox </xsl:text>
      <xsl:value-of select="ns0:line[1]/@l|ns1:line[1]/@l|ns2:line[1]/@l|ns3:line[1]/@l"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="ns0:line[1]/@t|ns1:line[1]/@t|ns2:line[1]/@t|ns3:line[1]/@t"/>
      <xsl:text> </xsl:text>
      <xsl:choose>
        <xsl:when test="../../../../@blockType='Table'">
          <xsl:value-of select="../../../../@r"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="../../@r"/></xsl:otherwise>
      </xsl:choose>
      <xsl:text> </xsl:text>
      <xsl:value-of select="ns0:line[last()]/@b|ns1:line[last()]/@b|ns2:line[last()]/@b|ns3:line[last()]/@b"/>
    </xsl:attribute>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="@align = 'Justify'">
      <p class="ocr_par" style="text-align: justify;">
        <xsl:apply-templates select="ns0:line|ns1:line|ns2:line|ns3:line"/>
      </p>
    </xsl:when>
    <xsl:when test="@align = 'Justified'">
      <p class="ocr_par" style="text-align: justify;">
        <xsl:apply-templates select="ns0:line|ns1:line|ns2:line|ns3:line"/>
      </p>
    </xsl:when>
    <xsl:when test="@align = 'Left'">
      <p class="ocr_par" style="text-align: left;">
        <xsl:apply-templates select="ns0:line|ns1:line|ns2:line|ns3:line"/>
      </p>
    </xsl:when>
    <xsl:when test="@align = 'Center'">
      <p class="ocr_par" style="text-align: center;">
        <xsl:apply-templates select="ns0:line|ns1:line|ns2:line|ns3:line"/>
      </p>
    </xsl:when>
    <xsl:when test="@align = 'Right'">
      <p class="ocr_par" style="text-align: right;">
        <xsl:apply-templates select="ns0:line|ns1:line|ns2:line|ns3:line"/>
      </p>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="ns0:line|ns1:line|ns2:line|ns3:line">
          <p class="ocr_par">
            <xsl:attribute name="title"><xsl:value-of select="$bbox"/></xsl:attribute>
            <xsl:apply-templates select="ns0:line|ns1:line|ns2:line|ns3:line"/>
          </p>
        </xsl:when>
        <xsl:otherwise><p class="ocr_par"/></xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="ns0:line|ns1:line|ns2:line|ns3:line">
  <span class="ocr_line">
    <xsl:attribute name="title">
      <xsl:text>bbox </xsl:text>
      <xsl:value-of select="@l"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="@t"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="@r"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="@b"/>
    </xsl:attribute>
    <xsl:if test="./*:formatting/@lang">
      <xsl:attribute name="lang">
        <xsl:value-of select="./*:formatting/@lang"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:apply-templates select="ns0:formatting|ns1:formatting|ns2:formatting|ns3:formatting"/>
  </span>
  <xsl:text> </xsl:text>
</xsl:template>

<!-- Formatting -->

<xsl:template match="ns0:formatting|ns1:formatting|ns2:formatting|ns3:formatting">
  <xsl:choose>
    <xsl:when test="@bold = '1'">
      <b>
        <xsl:apply-templates select="ns0:charParams|ns1:charParams|ns2:charParams|ns3:charParams"/>
      </b>
    </xsl:when>
    <xsl:when test="@italic = '1'">
      <em>
        <xsl:apply-templates select="ns0:charParams|ns1:charParams|ns2:charParams|ns3:charParams"/>
      </em>
    </xsl:when>
    <xsl:when test="@smallcaps = '1'">
      <span style="font-variant:small-caps;">
        <xsl:apply-templates select="ns0:charParams|ns1:charParams|ns2:charParams|ns3:charParams"/>
      </span>
    </xsl:when>
    <xsl:when test="@bold = 'true'">
      <b>
        <xsl:apply-templates select="ns0:charParams|ns1:charParams|ns2:charParams|ns3:charParams"/>
      </b>
    </xsl:when>
    <xsl:when test="@italic = 'true'">
      <em>
        <xsl:apply-templates select="ns0:charParams|ns1:charParams|ns2:charParams|ns3:charParams"/>
      </em>
    </xsl:when>
    <xsl:when test="@smallcaps = 'true'">
      <span style="font-variant:small-caps;">
        <xsl:apply-templates select="ns0:charParams|ns1:charParams|ns2:charParams|ns3:charParams"/>
      </span>
    </xsl:when>
    <xsl:when test="@spacing = '30'">
      <span style="letter-spacing: 0.25em;">
        <xsl:apply-templates select="ns0:charParams|ns1:charParams|ns2:charParams|ns3:charParams"/>
      </span>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="ns0:charParams|ns1:charParams|ns2:charParams|ns3:charParams"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="ns0:charParams|ns1:charParams|ns2:charParams|ns3:charParams">
  <xsl:choose>
    <xsl:when test=". = ' '">
      <xsl:value-of select="."/><xsl:text> </xsl:text>
    </xsl:when>
    <xsl:when test="@wordFirst = '1'">
      <xsl:text> </xsl:text>
      <xsl:value-of select="."/>
      <xsl:apply-templates select="ns0:charParams|ns1:charParams|ns2:charParams|ns3:charParams"/>
    </xsl:when>
    <xsl:when test="@wordStart = 'true'">
      <xsl:text> </xsl:text>
      <xsl:value-of select="."/>
      <xsl:apply-templates select="ns0:charParams|ns1:charParams|ns2:charParams|ns3:charParams"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="."/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Table-->

<xsl:template match="ns0:row|ns1:row|ns2:row|ns3:row">
  <xsl:element name="tr">
    <xsl:apply-templates/>
  </xsl:element>
</xsl:template>

<xsl:template match="ns0:cell|ns1:cell|ns2:cell|ns3:cell">
  <xsl:element name="td">
    <xsl:apply-templates/>
  </xsl:element>
</xsl:template>

</xsl:stylesheet>
