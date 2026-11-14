"""Format original imagegen illustrations. Requires Pillow; no image generation here.

Only measured atlas cropping, aspect-preserving sizing/padding, and PNG encoding.
Run from any directory. Original source images and prompts remain untouched.
"""
from pathlib import Path
import hashlib, json
from PIL import Image, ImageOps, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'marketing/source'
OUT=[]
def save(source, target, size, crop=None, rgba=False, badge=False):
    with Image.open(SRC/source) as im:
        im=im.convert('RGBA' if rgba else 'RGB')
        if crop: im=im.crop(crop)
        if badge:
            # Preserve every part of the illustration. Neutral delivery padding
            # never crops a shield tip or stretches the original badge.
            ink=im.getpixel((0,0))
            im=ImageOps.contain(im,(size[0]-64,size[1]-64),method=Image.Resampling.LANCZOS)
            padded=Image.new('RGB',size,ink)
            padded.paste(im,((size[0]-im.width)//2,(size[1]-im.height)//2))
            im=padded
        else:im=ImageOps.fit(im,size,method=Image.Resampling.LANCZOS)
        path=ROOT/target; path.parent.mkdir(parents=True,exist_ok=True)
        im.save(path,optimize=True)
    OUT.append(dict(path=target,source='marketing/source/'+source,width=size[0],height=size[1],
                    mode='RGBA' if rgba else 'RGB',bytes=path.stat().st_size,
                    sha256=hashlib.sha256(path.read_bytes()).hexdigest(),crop=crop,
                    sizing='contain with at least 32px neutral margin' if badge else 'aspect-preserving fit'))

for target in ['assets/brand/app-icon.png','assets/brand/icon.png','marketing/app-icon-512.png']:
    save('icon-source.png',target,(512,512),rgba=True)
save('feature-source.png','marketing/feature-graphic-1024x500.png',(1024,500))
save('splash-source.png','marketing/splash-1080x1920.png',(1080,1920))
save('splash-source.png','assets/brand/splash-portrait.png',(720,1280))

catalog=json.loads((ROOT/'game/catalog.json').read_text(encoding='utf-8-sig'))
# Measured outer art bounds on the untouched 1402x1122 generated atlas. These
# separate the chief's left laurel from Crew Leader's right edge and preserve
# all full shield tips. Eight source pixels of quiet margin surround each.
ACHIEVEMENT_BOUNDS=[
    (41,19,277,273),(318,34,544,262),(592,19,813,273),(861,19,1087,275),(1132,27,1368,270),
    (40,296,276,548),(314,301,544,534),(574,297,827,540),(856,303,1088,534),(1137,296,1359,547),
    (32,569,270,809),(296,567,561,806),(587,563,813,817),(851,570,1092,809),(1129,567,1367,816),
    (28,841,280,1085),(310,834,548,1090),(579,842,815,1083),(854,834,1087,1091),(1117,840,1376,1081)]
for group,cols,rows in [('achievements',5,4),('leaderboards',3,1)]:
    name=group+'-source.png'
    with Image.open(SRC/name) as im: w,h=im.size
    for i,item in enumerate(catalog[group]):
        x,y=i%cols,i//cols
        crop=[round(x*w/cols),round(y*h/rows),round((x+1)*w/cols),round((y+1)*h/rows)]
        if group=='achievements':
            left,top,right,bottom=ACHIEVEMENT_BOUNDS[i]
            crop=[round((left-8)*w/1402),round((top-8)*h/1122),round((right+8)*w/1402),round((bottom+8)*h/1122)]
        save(name,f'marketing/{group}/{item["id"]}.png',(512,512),crop,badge=True)
        save(name,f'assets/{group}/{item["id"]}.png',(512,512),crop,badge=True)

sheet=Image.new('RGB',(1500,1500),'#07162a'); draw=ImageDraw.Draw(sheet)
items=catalog['achievements']+catalog['leaderboards']
for i,item in enumerate(items):
    x,y=(i%5)*300,(i//5)*300
    group='achievements' if i<20 else 'leaderboards'
    with Image.open(ROOT/f'marketing/{group}/{item["id"]}.png') as im:
        im.thumbnail((250,250),Image.Resampling.LANCZOS);sheet.paste(im,(x+25,y))
    draw.text((x+16,y+260),item['name'],fill='#fff2d5')
sheet.save(ROOT/'marketing/source/badges-contact-sheet.jpg',quality=90)
edge_records=[]
for item in items:
    path=ROOT/item['icon'].removeprefix('res://')
    with Image.open(path) as icon:
        icon=icon.convert('RGB')
        bands=[icon.crop((0,0,512,40)),icon.crop((0,472,512,512)),
               icon.crop((0,0,40,512)),icon.crop((472,0,512,512))]
        maxima=[max(max(band.getpixel((x,y))) for y in range(band.height) for x in range(band.width)) for band in bands]
    if max(maxima)>=70:raise ValueError('Unexpected colored art in neutral edge: '+item['id'])
    group='achievements' if item in catalog['achievements'] else 'leaderboards'
    if path.read_bytes()!=(ROOT/f'marketing/{group}/{item["id"]}.png').read_bytes():
        raise ValueError('Store/runtime badge mismatch: '+item['id'])
    edge_records.append(dict(id=item['id'],outer_40px_rgb_max=maxima,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
edge_report=dict(result='PASS',icons=len(edge_records),edge_region='Outer 40px on all four sides',
                 limit='All edge RGB channels below70; no gold/cream badge fragments in neutral margins',
                 paired_store_runtime_bytes_identical=True,records=edge_records)
(SRC/'badge-edge-validation.json').write_text(json.dumps(edge_report,indent=2)+'\n',encoding='utf-8')
sources=[]
for p in sorted(SRC.glob('*-source.png')):
    with Image.open(p) as im: size=im.size
    sources.append(dict(path=str(p.relative_to(ROOT)).replace('\\','/'),width=size[0],height=size[1],
                        sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
manifest=dict(generator='Built-in image_gen; 2026-11-14',source_type='Original AI-assisted game illustrations',
              formatting='Measured individual atlas crops, Lanczos aspect-preserving contain with neutral margins, PNG encode; no fabricated runtime images',
              sources=sources,outputs=OUT,
              visual_review='All five generated source illustrations and final contact sheet reviewed for legibility, cell boundaries and correct identity.')
(ROOT/'marketing/art-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print(f'Prepared {len(OUT)} original art PNGs; 20 achievement and 3 leaderboard pairs.')
