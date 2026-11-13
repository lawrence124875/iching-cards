"""Crop the 64 卦影 woodcuts (Harvard 斷易天機) by snapping rough boxes to frame lines.
Output: <out>/images/NN.webp (King Wen number), <out>/work/crops_sheet.jpg, debug_sheet.jpg, map.csv"""
import sys, os, json
import numpy as np
from PIL import Image, ImageDraw, ImageOps
pages, out = sys.argv[1], sys.argv[2]
NAMES = ["乾","坤","屯","蒙","需","訟","師","比","小畜","履","泰","否","同人","大有","謙","豫","隨","蠱","臨","觀","噬嗑","賁","剝","復","無妄","大畜","頤","大過","坎","離","咸","恆","遯","大壯","晉","明夷","家人","睽","蹇","解","損","益","夬","姤","萃","升","困","井","革","鼎","震","艮","漸","歸妹","豐","旅","巽","兌","渙","節","中孚","小過","既濟","未濟"]
# (page, half, y0, y1, 卦名) in book order (八宮)
SPEC = json.load(open(os.path.join(os.path.dirname(__file__), "spec.json"), encoding="utf-8"))
over = SPEC.get("override", {})
os.makedirs(os.path.join(out, "images"), exist_ok=True); os.makedirs(os.path.join(out, "work"), exist_ok=True)

def runs(b):  # longest run of True along last axis
    best = np.zeros(b.shape[:-1], int); cur = np.zeros_like(best)
    for i in range(b.shape[-1]):
        cur = np.where(b[..., i], cur + 1, 0); best = np.maximum(best, cur)
    return best

def close1d(b, k):  # fill gaps up to k along last axis
    c = b.copy()
    for s in range(1, k + 1):
        c[..., :-s] |= b[..., s:]
    return c

def hruns(b):
    return runs(close1d(b, 6))

rows, crops, dbg = [], [], []
CX = 0.35
for page, half, cy, name in SPEC["items"]:
    im = Image.open(os.path.join(pages, page + ".jpg")).convert("RGB")
    W, H = im.size
    hx0, hx1 = (0, W // 2) if half == "L" else (W // 2, W)
    g = np.asarray(ImageOps.grayscale(im.crop((hx0, 0, hx1, H))), float)
    hw = g.shape[1]
    dark = g < np.percentile(g, 50) * 0.72
    status = "ok"
    k = over.get(name)
    if k:
        bx0, by0, bx1, by1 = int(k[0]*hw), int(k[1]*H), int(k[2]*hw), int(k[3]*H); status = "manual"
    else:
        xa, xb = int((CX - 0.22) * hw), int((CX + 0.18) * hw)
        hs = hruns(dark[:, xa:xb]) >= 0.85 * (xb - xa)
        lines, r = [], 0
        while r < H:
            if hs[r]:
                e = r
                while e + 1 < H and hs[e + 1]: e += 1
                lines.append((r + e) // 2); r = e + 1
            else: r += 1
        c = int(cy * H)
        ups = sorted([l for l in lines if c - 0.32*H < l < c], reverse=True)
        dns = sorted([l for l in lines if c < l < c + 0.32*H])
        found = None
        for t in ups:
            for b in dns:
                if not (0.12*H <= b - t <= 0.45*H): continue
                band = dark[t + 4:b - 4, :]
                vs = hruns(band.T) >= 0.9 * band.shape[0]
                xs = np.nonzero(vs)[0]
                L = [x for x in xs if x < (CX - 0.12) * hw]; R = [x for x in xs if x > (CX + 0.12) * hw]
                if L and R and min(R) - max(L) >= 0.4 * hw:
                    found = (max(L), t, min(R), b); break
            if found: break
        if found: bx0, by0, bx1, by1 = found
        else:
            status = "FAIL"; bx0, by0, bx1, by1 = int(0.03*hw), int((cy-0.13)*H), int(0.7*hw), int((cy+0.13)*H)
    box = (hx0 + bx0, by0, hx0 + bx1, by1)
    c = im.crop(box)
    num = NAMES.index(name) + 1
    cw = c
    if cw.width > 900: cw = cw.resize((900, round(cw.height * 900 / cw.width)), Image.LANCZOS)
    cw.save(os.path.join(out, "images", f"{num:02d}.webp"), quality=80, method=6)
    sz = os.path.getsize(os.path.join(out, "images", f"{num:02d}.webp"))
    rows.append(f"{num:02d},{name},{page},{half},{bx0/hw:.3f},{by0/H:.3f},{bx1/hw:.3f},{by1/H:.3f},{c.width}x{c.height},{status},{sz}")
    crops.append((f"{len(crops)+1}:{num:02d}{'' if status=='ok' else ' '+status}", c))
    d = im.crop((hx0, 0, hx1, H)).copy(); dr = ImageDraw.Draw(d)
    dr.rectangle((bx0, by0, bx1, by1), outline=(255, 0, 0), width=8)
    dbg.append((f"{len(dbg)+1}:{num:02d} {page}{half}", d))

def sheet(items, tw, path, cols=8):
    th = []
    for lab, im in items:
        im = im.copy(); im.thumbnail((tw, tw * 2)); th.append((lab, im))
    Hh = max(i.height for _, i in th) + 16
    s = Image.new("RGB", (cols * tw, ((len(th) + cols - 1) // cols) * Hh), "white"); d = ImageDraw.Draw(s)
    for n, (lab, im) in enumerate(th):
        x, y = (n % cols) * tw, (n // cols) * Hh
        s.paste(im, (x, y + 14)); d.text((x + 3, y + 1), lab, fill="red")
    s.save(path, quality=72)
sheet(crops, 220, os.path.join(out, "work", "crops_sheet.jpg"))
sheet(dbg, 160, os.path.join(out, "work", "debug_sheet.jpg"), cols=11)
open(os.path.join(out, "work", "map.csv"), "w", encoding="utf-8").write("num,name,page,half,fx0,fy0,fx1,fy1,size,status,bytes\n" + "\n".join(rows) + "\n")
print("cropped", len(rows), "fail", sum("FAIL" in r for r in rows), "total KB", sum(int(r.split(",")[-1]) for r in rows) // 1024)
# export half pages for local tuning (work branch only)
hp = os.path.join(out, "work", "halves"); os.makedirs(hp, exist_ok=True)
for page, half, cy, name in SPEC["items"]:
    im = Image.open(os.path.join(pages, page + ".jpg")).convert("RGB"); W, H = im.size
    h = im.crop((0, 0, W // 2, H) if half == "L" else (W // 2, 0, W, H))
    h.save(os.path.join(hp, f"{NAMES.index(name)+1:02d}.jpg"), quality=85)
