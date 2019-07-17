# -*- coding: utf-8 -*-
from __future__ import absolute_import

import os
import sys
import click
import validators

from urllib.request import urlopen
from lxml import etree
from PIL import Image

ns = {
     'pc': 'http://schema.primaresearch.org/PAGE/gts/pagecontent/2018-07-15',
     'xlink' : "http://www.w3.org/1999/xlink",
}
PC = "{%s}" % ns['pc']
XLINK = "{%s}" % ns['xlink']

@click.command()
@click.argument('page', type=click.File('rb'))
@click.option('-o', '--out-dir', type=click.Path(exists=True), default=".", help="Existing directory for storing the extracted image files (default: PWD)")
@click.option('-l', '--level', type=click.Choice(['line','region']), default='line', help="Structural level to perform the image extraction on (default: 'line')")
def cli(page,out_dir,level):
    """ PAGE: Input PAGE XML """

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
    if validators.url(src_img):
        f = urlopen(src_img)
    elif os.path.exists(src_img):
        f = open(src_img, "rb")
    else:
        click.echo("File %s could not be retrieved! Aborting." % src_img, err=True)
        sys.exit(1)
    pil_image = Image.open(f)

    #
    # iterate over all structs
    #
    for struct in page_elem.xpath(".//pc:Text%s|.//pc:Image%s" % (level.capitalize(), level.capitalize()), namespaces=ns):

        #
        # generate PIL crop schema from struct points
        xys = [[int(p) for p in pair.split(',')] for pair in struct.find("./" + PC + "Coords").get("points").split(' ')]
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
        pil_image_struct.save("%s/%s_%s.png" % (out_dir,os.path.basename(src_img),struct.get("id")), dpi=(300,300))

if __name__ == '__main__':
    cli()
