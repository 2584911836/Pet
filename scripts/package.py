#!/usr/bin/env python3
"""Package tested exports; never include credentials, user data, Git or caches."""
from pathlib import Path
import hashlib
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = sys.argv[1] if len(sys.argv) > 1 else '0.4.0'
OUT = ROOT / 'build' / 'releases'
OUT.mkdir(parents=True, exist_ok=True)

def zip_files(path, files):
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for source, name in files:
            archive.write(source, name)
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
    print(path.name, path.stat().st_size, 'bytes')

files=[]
for folder in ['scripts', 'tests', 'docs', 'assets']:
    for source in sorted((ROOT/folder).rglob('*')):
        if source.is_file() and '__pycache__' not in source.parts:
            files.append((source,'Tidebound/'+str(source.relative_to(ROOT))))
for name in ['project.godot','main.tscn','export_presets.cfg','README.md','.gitignore']:
    files.append((ROOT/name,'Tidebound/'+name))
zip_files(OUT/f'Tidebound-v{VERSION}-Godot-Source.zip',files)
with (OUT/f'SHA256-v{VERSION}.txt').open('w') as output:
    for path in sorted(OUT.glob(f'Tidebound-v{VERSION}-*.zip')):
        output.write(hashlib.sha256(path.read_bytes()).hexdigest()+'  '+path.name+'\n')
