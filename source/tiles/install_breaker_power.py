"""Install only the two added power-light cells; preserve every existing tile pixel.

Render breaker_on with build_livewire_tiles.py and generate depth.json using the
breaker_power.py recipe first. Run with <render-dir> --forge <forge-dir>
--depth-tool <skill>/scripts/build_depthmap.py. Raw backups/reports stay in render-dir.
"""
import argparse
import importlib.util
import json
import math
import os
import sys
from io import BytesIO
from pathlib import Path

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('render_dir',type=Path)
    parser.add_argument('--forge',type=Path,required=True)
    parser.add_argument('--depth-tool',type=Path,required=True)
    args=parser.parse_args()
    os.environ['PZ_FORGE']=str(args.forge)
    sys.path.insert(0,str(args.forge))
    import build_livewire_tiles as recipe
    from PIL import Image
    from pzforge.packfile import TexturePack
    from pzforge.sheet import Cell,Sheet,pack_sheet
    root=Path(__file__).resolve().parents[2]
    media=root/'Contents/mods/batman_LiveWire/common/media'
    pack_path=media/'texturepacks/batman_livewire_01.pack'
    depth_path=media/'depthmaps/DEPTH_batman_livewire_01.png'
    work=args.render_dir.resolve()
    work.mkdir(parents=True,exist_ok=True)
    def cells(pack):
        result={}
        for page in pack.pages:
            atlas=Image.open(BytesIO(page.png)).convert('RGBA')
            for e in page.entries:
                img=Image.new('RGBA',(128,256))
                img.paste(atlas.crop((e.x,e.y,e.x+e.w,e.y+e.h)),(e.ox,e.oy))
                result[int(e.name.rsplit('_',1)[1])]=img
        return result
    original=pack_path.read_bytes()
    before=cells(TexturePack.loads(original))
    old_names=set(before)
    assert old_names<=set(range(recipe.TOTAL))
    for i in range(recipe.TOTAL):before.setdefault(i,Image.new('RGBA',(128,256)))
    after={i:img.copy() for i,img in before.items()}
    added=recipe.styled_cells(work/'breaker_on',work/'_styled',True)
    for i,img in zip((84,85),added):
        assert img.getbbox(),f'empty added light {i}'
        after[i]=img
    packed=pack_sheet(Sheet(recipe.SHEET,128,256,8,[Cell(after[i],index=i) for i in range(recipe.TOTAL)]))
    verified=cells(TexturePack.loads(packed.dumps()))
    assert set(verified)==old_names|{84,85}
    for i in range(recipe.TOTAL):
        if i not in verified:
            assert after[i].getbbox() is None
            continue
        assert verified[i].tobytes()==after[i].tobytes()
        if i not in (84,85):assert verified[i].tobytes()==before[i].tobytes()
    spec=importlib.util.spec_from_file_location('lw_depth_tool',args.depth_tool)
    depth=importlib.util.module_from_spec(spec);spec.loader.exec_module(depth)
    data=json.loads((work/'depth.json').read_text())
    old_depth=Image.open(depth_path).convert('RGBA')
    new_depth=old_depth.copy()
    reports={}
    for i in (84,85):
        values,drawn,stats=depth.tile_depth(data['tiles'][str(i)],after[i].getchannel('A'),128,256)
        assert stats['unfilled']==0 and stats['stray']==0,stats
        tile=Image.new('RGBA',(128,256))
        for y in range(256):
            for x in range(128):
                d=values[y][x]
                if d is not None and drawn(x,y):
                    value=math.floor(min(1,max(0,d))*255)
                    tile.putpixel((x,y),(value,value,value,255))
        new_depth.paste(tile,((i%8)*128,(i//8)*256))
        reports[i]=stats
    for i in range(recipe.TOTAL):
        if i in (84,85):continue
        box=((i%8)*128,(i//8)*256,(i%8+1)*128,(i//8+1)*256)
        assert old_depth.crop(box).tobytes()==new_depth.crop(box).tobytes()
    # Preserve the first backup even when replaying this installation.
    if not (work/'original.pack').exists():(work/'original.pack').write_bytes(original)
    if not (work/'original-depth.png').exists():old_depth.save(work/'original-depth.png')
    packed.write(pack_path);new_depth.save(depth_path)
    preview=Image.new('RGBA',(128*4,256))
    for facing in range(2):
        base=before[20+facing].copy()
        lit=base.copy();lit.alpha_composite(after[84+facing])
        preview.alpha_composite(base,(facing*256,0))
        preview.alpha_composite(lit,(facing*256+128,0))
    preview.save(work/'breaker-off-on.png')
    (work/'asset-report.json').write_text(json.dumps(reports,indent=2),encoding='ascii')
    print('OK: 88 stable cells; only 84/85 changed; existing depth cells preserved; no tile definitions rewritten')
    print(json.dumps(reports))

if __name__=='__main__':main()
