<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet 
	xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:p1="http://schema.primaresearch.org/PAGE/gts/pagecontent/2009-03-16"
	xmlns:p2="http://schema.primaresearch.org/PAGE/gts/pagecontent/2010-01-12"
	xmlns:p3="http://schema.primaresearch.org/PAGE/gts/pagecontent/2010-03-19"
	xmlns:p4="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
	xmlns:p5="http://schema.primaresearch.org/PAGE/gts/pagecontent/2016-07-15"
	xmlns:p6="http://schema.primaresearch.org/PAGE/gts/pagecontent/2017-07-15"
	xmlns:p7="http://schema.primaresearch.org/PAGE/gts/pagecontent/2018-07-15"
	xmlns="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
	exclude-result-prefixes="#all"
	version="2.0">


	<xsl:output method="html" encoding="UTF-8" standalone="yes" indent="yes"/>


	<xsl:template match="*:PcGts" xmlns="http://www.w3.org/1999/xhtml">
		<html>
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<link rel="stylesheet" href=""/>
				<title>OCR Output</title>
				<meta name="description" content="OCR Output via XSLT of pageXML."/>
			</head>
			<body>
				<xsl:element name="div">
					<xsl:attribute name="class">ocr_page</xsl:attribute>
					<xsl:attribute name="title">bbox 0 0 <xsl:value-of select="*:Page/@imageWidth"/>
						<xsl:text> </xsl:text> <xsl:value-of select="*:Page/@imageHeight"/>
						<xsl:text>; image 'image/</xsl:text> <xsl:value-of
						select="*:Page/@imageFilename"/> <xsl:text>';</xsl:text> </xsl:attribute>
					<xsl:for-each select="*:Page/*:TextRegion">
						<xsl:call-template name="textregion"/>
					</xsl:for-each>
					<xsl:for-each select="*:Page/*:ImageRegion">
						<xsl:call-template name="imageregion"/>
					</xsl:for-each>
					<xsl:for-each select="*:Page/*:GraphicRegion">
						<xsl:call-template name="graphicregion"/>
						<xsl:if test="child::*:TextRegion">
							<xsl:for-each select="*:TextRegion">
								<xsl:call-template name="textregion"/>
							</xsl:for-each>
						</xsl:if>
					</xsl:for-each>
				</xsl:element>
			</body>
		</html>
	</xsl:template>

	
	<xsl:template name="imageregion" xmlns="http://www.w3.org/1999/xhtml">
		<xsl:param name="bbox_poly">
			<xsl:call-template name="bbox_or_poly"/>
		</xsl:param>
		<div class="cr_carea" title="{$bbox_poly}">
			<p class="ocr_par" title="{$bbox_poly}"></p>
		</div>
	</xsl:template>

	<xsl:template name="graphicregion">
		<xsl:param name="bbox_poly">
			<xsl:call-template name="bbox_or_poly"/>
		</xsl:param>
		<div class="cr_carea" title="{$bbox_poly}">
			<p class="ocr_par" title="{$bbox_poly}"></p>
		</div>
	</xsl:template>
	
	<xsl:template name="textregion" xmlns="http://www.w3.org/1999/xhtml">
		<xsl:element name="div">
			<xsl:attribute name="class">ocr_carea</xsl:attribute>
			<xsl:attribute name="title">
				<xsl:call-template name="bbox_or_poly"/>
			</xsl:attribute>
			<xsl:element name="p">
				<xsl:attribute name="class">ocr_par</xsl:attribute>
				<xsl:attribute name="title">
					<xsl:call-template name="bbox_or_poly"/>
				</xsl:attribute>
				<xsl:choose>
					<xsl:when test="*:TextLine">
						<xsl:for-each select="*:TextLine">
							<xsl:element name="span">
								<xsl:attribute name="class">ocr_line</xsl:attribute>
								<xsl:attribute name="title">
									<xsl:call-template name="bbox_or_poly"/>
								</xsl:attribute>
								<xsl:for-each select="*:Word">
									<xsl:element name="span">
										<xsl:attribute name="class">ocrx_word</xsl:attribute>
										<xsl:attribute name="title">
											<xsl:call-template name="bbox_or_poly"/>
										</xsl:attribute>
										<xsl:value-of select="*:TextEquiv/*:Unicode"/>
									</xsl:element>
								</xsl:for-each>
								<xsl:value-of select="*:TextEquiv/*:Unicode"/>
							</xsl:element>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="*:TextEquiv/*:Unicode"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:element>
		</xsl:element>
	</xsl:template>

	<xsl:template name="bbox_or_poly">
		<xsl:variable name="Coords" select="*:Coords/@points"/>
		<xsl:variable name="points" select="tokenize($Coords, ' ')"/>

		<xsl:variable name="xmin">
			<xsl:for-each select="$points">
				<xsl:sort select="substring-before(., ',')" data-type="number"/>
				<xsl:if test="substring-before(., ',') and position() = 1">
					<xsl:value-of select="substring-before(., ',')"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<xsl:variable name="xmax">
			<xsl:for-each select="$points">
				<xsl:sort select="substring-before(., ',')" order="descending" data-type="number"/>
				<xsl:if test="substring-before(., ',') and position() = 1">
					<xsl:value-of select="substring-before(., ',')"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<xsl:variable name="ymin">
			<xsl:for-each select="$points">
				<xsl:sort select="substring-after(., ',')" data-type="number"/>
				<xsl:if test="substring-after(., ',') and position() = 1">
					<xsl:value-of select="substring-after(., ',')"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<xsl:variable name="ymax">
			<xsl:for-each select="$points">
				<xsl:sort select="substring-after(., ',')" order="descending" data-type="number"/>
				<xsl:if test="substring-after(., ',') and position() = 1">
					<xsl:value-of select="substring-after(., ',')"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:choose>
			<!--<xsl:when test="count($points) > 4">bbox <xsl:value-of select="$xmin"/><xsl:text> </xsl:text><xsl:value-of select="$ymin"/><xsl:text> </xsl:text><xsl:value-of select="$xmax"/><xsl:text> </xsl:text><xsl:value-of select="$ymax"/>; poly <xsl:value-of select="replace($Coords, ',', ' ')"/></xsl:when>-->
			<xsl:when test="count($points) > 4">bbox <xsl:value-of select="$xmin"
				/><xsl:text> </xsl:text><xsl:value-of select="$ymin"
				/><xsl:text> </xsl:text><xsl:value-of select="$xmax"
				/><xsl:text> </xsl:text><xsl:value-of select="$ymax"/></xsl:when>
			<xsl:otherwise>bbox <xsl:value-of select="$xmin"/><xsl:text> </xsl:text><xsl:value-of
				select="$ymin"/><xsl:text> </xsl:text><xsl:value-of select="$xmax"
				/><xsl:text> </xsl:text><xsl:value-of select="$ymax"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>
