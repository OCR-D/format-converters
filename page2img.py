#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import math
import os
import re
import sys
from urllib.request import urlopen

import click
import validators
from lxml import etree
from PIL import Image, ImageDraw, ImageFont


@click.command()
@click.argument('page', type=click.File('rb'))
@click.option('-o', '--out-dir', type=click.Path(exists=True), default=".",
              help="Existing directory for storing the extracted image files (default: PWD)")
@click.option('-l', '--level', type=click.Choice(['line', 'region', 'page']), default='line',
              help="Structural level to perform the image extraction on (default: 'line')")
@click.option('-i', '--image-format', type=click.Choice(
    ['png', 'tif']), default='png', help="Output image format (default: 'png')")
@click.option('-p', '--page-version',
              type=click.Choice(['2013-07-15', '2019-07-15']),
              default='2019-07-15',
              help="PAGE version (default: '2019-07-15')")
@click.option('-t', '--text', is_flag=True, default=False,
              help=("Also extract full text (if available) and "
                    "put it into a text file in the output directory."))
@click.option('-f', '--font', type=click.Path(dir_okay=False),
              help="Truetype font file for label output")
@click.option('-v', '--verbose', is_flag=True, help='Enable verbose mode')
def cli(page, out_dir, level, image_format, page_version, text, font, verbose):
    """ PAGE: Input PAGE XML """

    xml = etree.parse(page)
    xml_root = xml.getroot()
    xmlns = xml_root.attrib.get(
        '{http://www.w3.org/2001/XMLSchema-instance}schemaLocation')
    if xmlns is not None:
        xmlns = xmlns.split()
        if xmlns[0] == 'http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15':
            page_version = '2013-07-15'

    ns = {
        'pc': 'http://schema.primaresearch.org/PAGE/gts/pagecontent/' + page_version,
        'xlink': "http://www.w3.org/1999/xlink",
        're': "http://exslt.org/regular-expressions",
    }
    PC = "{%s}" % ns['pc']

    colormap = {
        PC + 'NoiseRegion': [128, 0, 0],
        PC + 'TextRegion': [0, 128, 0],
        PC + 'ImageRegion': [0, 0, 128],
        PC + 'GraphicRegion': [128, 128, 0],
        PC + 'SeparatorRegion': [0, 128, 128],
        PC + 'MathRegion': [128, 0, 128],
        PC + 'TableRegion': [128, 128, 128],
    }

    #
    # read font file
    #
    try:
        font = ImageFont.truetype(font, size=24)
    except BaseException:
        font = ImageFont.load_default()

    #
    # read input xml
    #
    page_elem = xml_root.find("./" + PC + "Page")

    #
    # get main image
    #
    src_img = page_elem.get("imageFilename")
    imageWidth = int(page_elem.get("imageWidth"))
    imageHeight = int(page_elem.get("imageHeight"))

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
        click.echo("File %s could not be retrieved! Aborting." %
                   src_img, err=True)
        sys.exit(1)
    pil_image = Image.open(f)

    if pil_image.width != imageWidth or pil_image.height != imageHeight:
        print(
            f('WARNING: mismatch of image dimensions, '
              '{pil_image.width}x{pil_image.height} '
              '(from {src_img}) != {imageWidth}x{imageHeight} '
              '(from {page.name})'))

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

        textregion = struct.getparent()
        orientation = textregion.get('orientation')
        if orientation is None:
            orientation = 0.0
        else:
            orientation = float(orientation)

        points = struct.find("./" + PC + "Coords").get("points")
        if not points:
            continue

        outname = f'{out_dir}/{os.path.basename(src_img)}_{struct.get("id")}.{image_format}'

        xys = [tuple([int(p) for p in pair.split(',')])
               for pair in points.split(' ')]

        #
        # draw regions into page
        if level == 'page':
            draw.polygon(xys, (colormap[struct.tag][0], colormap[struct.tag]
                         [1], colormap[struct.tag][2], 50), outline='black')
            draw.text(xys[0],
                      "%s-%s-%s" % (re.sub("{[^}]*}", "", struct.tag),
                                    struct.get("type", default="None"),
                                    struct.get("custom", default="None")),
                      (colormap[struct.tag][0],
                       colormap[struct.tag][1],
                       colormap[struct.tag][2], 255), font=font)
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

            # Look for a baseline with coordinates outside of box (problem in ONB GT).
            # If found, increase box to include the baseline.
            baseline = struct.find("./" + PC + "Baseline")
            if baseline is None:
                baseline_points = False
            else:
                baseline_points = struct.find(
                    "./" + PC + "Baseline").get("points")
                if baseline_points:
                    baseline_xys = [tuple([int(p) for p in pair.split(',')])
                                    for pair in baseline_points.split(' ')]
                    for xy in baseline_xys:
                        if xy[0] < min_x:
                            if verbose:
                                print(
                                    f'INFO: baseline changes min_x from {min_x} to {xy[0]} for {outname}')
                            min_x = xy[0]
                        if xy[0] > max_x:
                            if verbose:
                                print(
                                    f'INFO: baseline changes max_x from {max_x} to {xy[0]} for {outname}')
                            max_x = xy[0]
                        if xy[1] < min_y:
                            if verbose:
                                print(
                                    f'INFO: baseline changes min_y from {min_y} to {xy[1]} for {outname}')
                            min_y = xy[1]
                        if xy[1] > max_y:
                            if verbose:
                                print(
                                    f'INFO: baseline changes max_y from {max_y} to {xy[1]} for {outname}')
                            max_y = xy[1]

            #
            # generate struct image
            pil_image_struct = pil_image.crop((min_x, min_y, max_x, max_y))

            # rotate line image by multiples of 90° if needed
            if not baseline_points:
                # missing baseline points, use orientation of text region
                angle = -orientation
            else:
                xys = [tuple([int(p) for p in pair.split(',')])
                       for pair in baseline_points.split(' ')]
                dx = xys[-1][0] - xys[0][0]
                dy = xys[-1][1] - xys[0][1]
                angle = math.atan2(dy, dx) * 180 / math.pi
            delta = 10
            if (0 - delta < angle) and (angle < 0 + delta):
                pass
            elif 90 - delta < angle and angle < 90 + delta:
                pil_image_struct = pil_image_struct.rotate(90, expand=True)
                if verbose:
                    print(f'INFO: line rotated by 90° in image {outname}')
            elif -90 - delta < angle and angle < -90 + delta:
                pil_image_struct = pil_image_struct.rotate(-90, expand=True)
                if verbose:
                    print(f'INFO: line rotated by -90° in image {outname}')
            elif 180 - delta < angle and angle < 180 + delta:
                pil_image_struct = pil_image_struct.rotate(180, expand=True)
                if verbose:
                    print(f'INFO: line rotated by 180° in image {outname}')
            elif -180 - delta < angle and angle < -180 + delta:
                pil_image_struct = pil_image_struct.rotate(180, expand=True)
                if verbose:
                    print(f'INFO: line rotated by -180° in image {outname}')
            else:
                print(
                    f'WARNING: line not rotated by {angle}° in image {outname}')

            # save struct image
            try:
                pil_image_struct.save(outname, dpi=(300, 300))
            except BaseException:
                print(f'ERROR: failed to write {outname}, {pil_image_struct=}')
                # Don't extract text if image could not be written.
                continue
            finally:
                pil_image_struct.close()

        #
        # extract text if requested by user
        if text:
            text_equiv = struct.find("./" + PC + "TextEquiv")
            if text_equiv is not None:
                unic = text_equiv.find("./" + PC + "Unicode")
                if unic is not None and unic.text is not None:
                    if level == 'page':
                        text_dest = open(
                            "%s/%s.txt" % (out_dir, os.path.basename(src_img)), "wa")
                    else:
                        text_dest = open(
                            "%s/%s_%s.txt" % (out_dir, os.path.basename(src_img), struct.get("id")), "w")
                    text_dest.write(unic.text)
                    text_dest.close()
    #
    # delete draw area and save page
    if level == 'page':
        del draw
        pil_image.save("%s/%s_hl.%s" % (out_dir,
                       os.path.basename(src_img), image_format), dpi=(300, 300))
    pil_image.close()


if __name__ == '__main__':
    cli()
