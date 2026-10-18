#!/usr/bin/env python3
"""Compile the 108 individually authored species records. No template generation.
Not required to run Godot. Stable IDs and encounter locations preserve old saves.
"""
from pathlib import Path
import csv,json
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'assets/pets/species_designs.json'
records=json.loads(source.read_text())
assert len(records)==108 and [r['id'] for r in records]==list(range(108))
for field in ['name','skill','lore','visual']:
    assert len({r[field] for r in records})==108, field
fields=['name','type','color','max_hp','power','skill','lore','family','form','trait','island','area','tide','skill_kind','skill_value','skill_scale','role']
path=ROOT/'scripts/game_data.gd'
old=path.read_text()
islands=old[old.index('const ISLANDS = '):]
lines=['extends RefCounted','','# 108 individually directed species. IDs and encounter locations remain save-compatible.','# family/form are legacy atlas coordinates, not species taxonomy.','const SPECIES = [']
for r in records:
    parts=[]
    for key in fields:
        value=json.dumps(r[key],ensure_ascii=False)
        if key=='color': value='Color('+value+')'
        parts.append(json.dumps(key)+':'+value)
    lines.append('\t{'+', '.join(parts)+'},')
path.write_text('\n'.join(lines)+'\n]\n\n'+islands)
with (ROOT/'docs/PET_CATALOG.csv').open('w',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=['id']+fields+['visual'],lineterminator='\n')
    writer.writeheader()
    writer.writerows(records)
print('Compiled 108 individually authored species and review catalogue')
