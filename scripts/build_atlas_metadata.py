#!/usr/bin/env python3
"""Analyze alpha components and emit Godot AtlasTexture regions; never edit PNG pixels.
Optional development tool requiring Pillow, NumPy, SciPy. Not required to run Godot.
"""
from pathlib import Path
from PIL import Image
from scipy import ndimage
import numpy as np
import json

ROOT=Path(__file__).resolve().parents[1]
PET=ROOT/'assets/pets'
sources=json.loads((PET/'sources.json').read_text())
all_frames=[]
for sheet in sources:
    image=Image.open(PET/sheet['image']).convert('RGBA')
    alpha=np.asarray(image)[:,:,3]
    labels,count=ndimage.label(alpha>180)
    areas=np.bincount(labels.ravel())
    slices=ndimage.find_objects(labels)
    width,height=image.size
    components=[]
    for index,region in enumerate(slices,1):
        if region is None or areas[index]<64:continue
        y,x=region
        box=[x.start,y.start,x.stop,y.stop]
        center=[(box[0]+box[2])/2,(box[1]+box[3])/2]
        cell=min(2,int(center[1]*3/height))*3+min(2,int(center[0]*3/width))
        components.append({'label':index,'area':int(areas[index]),'box':box,'center':center,'cell':cell})
    bodies=[]
    for cell in range(9):
        choices=[x for x in components if x['cell']==cell]
        body=max(choices,key=lambda x:x['area'])
        assert body['area']>5000, (sheet['image'],cell,'no main body')
        bodies.append(body)
    boxes=[list(body['box']) for body in bodies]
    for part in components:
        # Main bodies keep their own cell; nearby detached pearls/halos follow the nearest body.
        cell=min(range(9),key=lambda i:sum(((part['center'][axis]-bodies[i]['center'][axis])/(width if axis==0 else height))**2 for axis in (0,1)))
        if part['label'] in [x['label'] for x in bodies]:cell=[x['label'] for x in bodies].index(part['label'])
        b=boxes[cell];p=part['box']
        boxes[cell]=[min(b[0],p[0]),min(b[1],p[1]),max(b[2],p[2]),max(b[3],p[3])]
    frames=[None]*9
    for position,family in enumerate(sheet['family_order']):
        x0,y0,x1,y1=boxes[position]
        x0=max(0,x0-3);y0=max(0,y0-3);x1=min(width,x1+3);y1=min(height,y1+3)
        assert x1-x0>150 and y1-y0>150
        frames[family]=[x0,y0,x1-x0,y1-y0]
    all_frames.append(frames)
    print(sheet['image'],'main bodies',[x['area'] for x in bodies])
lines=['extends RefCounted','# Generated atlas-region metadata. Source PNGs are unmodified.','const SHEETS = [']
lines.extend('\t"res://assets/pets/'+x['image']+'",' for x in sources)
lines+= [']','const FRAMES = [']
for frames in all_frames:
    lines.append('\t['+', '.join('Rect2(%d,%d,%d,%d)'%tuple(frame) for frame in frames)+'],')
lines+= [']','']
(ROOT/'scripts/pet_atlases.gd').write_text('\n'.join(lines))
(PET/'regions.json').write_text(json.dumps(all_frames,indent=2)+'\n')
