<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:p="http://schema.primaresearch.org/PAGE/gts/pagecontent/2016-07-15">
	<!--xmlns:p="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"-->
	<xsl:output method="html" encoding="utf-8" standalone="yes" indent="yes"/>


	<xsl:template match="p:PcGts">
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<link rel="stylesheet" href=""/>
				<title>OCR Output</title>
				<meta name="description" content="OCR Output via XSLT of pageXML."/>
			</head>
			<body>
				<xsl:element name="div">
					<xsl:attribute name="class">ocr_page</xsl:attribute>
					<xsl:attribute name="title">bbox 0 0 <xsl:value-of select="p:Page/@imageWidth"/>
						<xsl:text> </xsl:text>
						<xsl:value-of select="p:Page/@imageHeight"/>
						<xsl:text>; image 'image/</xsl:text>
						<xsl:value-of select="p:Page/@imageFilename"/>
						<xsl:text>';</xsl:text>
					</xsl:attribute>
					<xsl:for-each select="p:Page/p:TextRegion">
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
								<xsl:for-each select="p:TextLine">
									<xsl:element name="span">
										<xsl:attribute name="class">ocr_line</xsl:attribute>
										<xsl:attribute name="title">
											<xsl:call-template name="bbox_or_poly"/>
										</xsl:attribute>
										<xsl:value-of select="p:TextEquiv/p:Unicode"/>
									</xsl:element>
								</xsl:for-each>
							</xsl:element>
						</xsl:element>
					</xsl:for-each>
				</xsl:element>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="bbox_or_poly">
		<xsl:variable name="Coords" select="p:Coords/@points"/>
		<xsl:variable name="points" select="count(tokenize($Coords,' '))"/>
		<xsl:choose>
			<xsl:when test="$points > 4">poly <xsl:value-of select="replace($Coords, ',', ' ')"/></xsl:when>
			<xsl:otherwise>bbox <xsl:value-of select="replace($Coords, '([0-9]+),([0-9]+)\s([0-9]+),([0-9]+)\s([0-9]+),([0-9]+)\s([0-9]+),([0-9]+)', '$1 $2 $5 $6')"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
		
</xsl:stylesheet>