#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import click
import validators
import re

from urllib.request import urlopen
from lxml import etree
from PIL import Image, ImageDraw, ImageFont

@click.command()
@click.argument('page', type=click.File('rb'))
@click.option('-o', '--out-dir', type=click.Path(exists=True), default=".", help="Existing directory for storing the extracted image files (default: PWD)")
@click.option('-l', '--level', type=click.Choice(['line','region','page']), default='line', help="Structural level to perform the image extraction on (default: 'line')")
@click.option('-i', '--image-format', type=click.Choice(['png','tif']), default='png', help="Output image format (default: 'png')")
@click.option('-p', '--page-version', type=click.Choice(['2013-07-15','2019-07-15']), default='2019-07-15', help="PAGE version (default: '2019-07-15')")
@click.option('-t', '--text', is_flag=True, default=False, help="Also extract full text (if available) and put it into a text file in the output directory.")
@click.option('-f', '--font', type=click.Path(dir_okay=False), help="Truetype font file for label output")

def cli(page, out_dir, level, image_format, page_version, text, font):
    """ PAGE: Input PAGE XML """

    ns = {
         'pc': 'http://schema.primaresearch.org/PAGE/gts/pagecontent/' + page_version,
         'xlink' : "http://www.w3.org/1999/xlink",
         're' : "http://exslt.org/regular-expressions",
         }
    PC = "{%s}" % ns['pc']
    XLINK = "{%s}" % ns['xlink']

    colormap = {
            PC + 'NoiseRegion' : [128, 0, 0],
            PC + 'TextRegion' : [0, 128, 0],
            PC + 'ImageRegion' : [0, 0, 128],
            PC + 'GraphicRegion' : [128, 128, 0],
            PC + 'SeparatorRegion' : [0, 128, 128],
            PC + 'MathRegion' : [128, 0, 128],
            PC + 'TableRegion' : [128, 128, 128],
            }

    #
    # read font file
    #
    try:
        font = ImageFont.truetype(font, size=24)
    except:
        font = ImageFont.load_default()

    #
    # read input xml
    #
    page_elem = etree.parse(page).getroot().find("./" + PC + "Page")

    #
    # get main image
    #
    src_img = page_elem.get("imageFilename")

    #
    # URL or file?
    dir = os.path.dirname(page.name)
    if validators.url(src_img):
        f = urlopen(src_img)
    elif os.path.exists(src_img):
        f = open(src_img, "rb")
    elif os.path.exists(f'{dir}/{src_img}'):
        f = open(f'{dir}/{src_img}', "rb")
    else:
        click.echo("File %s could not be retrieved! Aborting." % src_img, err=True)
        sys.exit(1)
    pil_image = Image.open(f)

    #
    # iterate over all structs
    #
    if level == "line":
        xpath = ".//pc:TextLine"
    else:
        xpath = ".//*[re:test(local-name(), '[A-Z][a-z]*Region')]"
        #
        # create drawing area for page
        if level == 'page':
            draw = ImageDraw.Draw(pil_image, 'RGBA')
    for struct in page_elem.xpath(xpath, namespaces=ns):

        points = struct.find("./" + PC + "Coords").get("points")
        if not points:
            continue

        xys = [tuple([int(p) for p in pair.split(',')]) for pair in points.split(' ')]

        #
        # draw regions into page
        if level == 'page':
            draw.polygon(xys, (colormap[struct.tag][0], colormap[struct.tag][1], colormap[struct.tag][2], 50), outline='black')
            draw.text(xys[0], "%s-%s-%s" % (re.sub("{[^}]*}", "", struct.tag), struct.get("type", default="None"), struct.get("custom", default="None")), (colormap[struct.tag][0], colormap[struct.tag][1], colormap[struct.tag][2], 255), font=font)
        #
        # generate PIL crop schema from struct points
        else:
            min_x = pil_image.width
            min_y = pil_image.height
            max_x = 0
            max_y = 0
            for xy in xys:
                if xy[0] < min_x:
                    min_x = xy[0]
                if xy[0] > max_x:
                    max_x = xy[0]
                if xy[1] < min_y:
                    min_y = xy[1]
                if xy[1] > max_y:
                    max_y = xy[1]

            #
            # generate and save struct image
            pil_image_struct = pil_image.crop((min_x, min_y, max_x, max_y))
            pil_image_struct.save("%s/%s_%s.%s" % (out_dir,os.path.basename(src_img),struct.get("id"),image_format), dpi=(300,300))

        #
        # extract text if requested by user
        if text:
            unic = struct.find("./" + PC + "TextEquiv").find("./" + PC + "Unicode")
            if unic is not None and unic.text is not None:
                if level == 'page':
                    text_dest = open("%s/%s.txt" % (out_dir,os.path.basename(src_img)), "wa")
                else:
                    text_dest = open("%s/%s_%s.txt" % (out_dir,os.path.basename(src_img),struct.get("id")), "w")
                text_dest.write(unic.text)
                text_dest.close()
    #
    # delete draw area and save page
    if level == 'page':
        del draw
        pil_image.save("%s/%s_hl.%s" % (out_dir,os.path.basename(src_img),image_format), dpi=(300,300))

if __name__ == '__main__':
    cli()
