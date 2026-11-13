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

rows, crops, dbg = [], [], []
for page, half, y0, y1, name in SPEC["items"]:
    im = Image.open(os.path.join(pages, page + ".jpg")).convert("RGB")
    W, H = im.size
    hx0, hx1 = (0, W // 2) if half == "L" else (W // 2, W)
    g = np.asarray(ImageOps.grayscale(im.crop((hx0, 0, hx1, H))), float)
    hw = g.shape[1]
    thr = np.percentile(g, 50) * 0.72
    dark = g < thr
    k = over.get(name)
    if k:  # manual box in half fractions x0,y0,x1,y1
        bx0, by0, bx1, by1 = int(k[0]*hw), int(k[1]*H), int(k[2]*hw), int(k[3]*H)
    else:
        def hline(lo, hi, xa, xb):
            lo, hi = max(0, int(lo*H)), min(H, int(hi*H))
            sc = runs(close1d(dark[lo:hi, xa:xb], 4))
            return lo + int(np.argmax(sc)), sc.max() / max(1, xb - xa)
        def vline(lo, hi, ya, yb):
            lo, hi = max(0, int(lo*hw)), min(hw, int(hi*hw))
            sc = runs(close1d(dark[ya:yb, lo:hi].T, 4))
            return lo + int(np.argmax(sc)), sc.max() / max(1, yb - ya)
        xa, xb = int(0.15*hw), int(0.55*hw)
        by0, s0 = hline(y0 - 0.09, y0 + 0.09, xa, xb)
        by1, s1 = hline(y1 - 0.09, y1 + 0.09, xa, xb)
        bx0, s2 = vline(0.0, 0.3, by0 + 5, by1 - 5)
        bx1, s3 = vline(0.5, 0.92, by0 + 5, by1 - 5)
        by0, s0 = hline(by0/H - 0.02, by0/H + 0.02, bx0 + 10, bx1 - 10)
        by1, s1 = hline(by1/H - 0.02, by1/H + 0.02, bx0 + 10, bx1 - 10)
    box = (hx0 + bx0, by0, hx0 + bx1, by1)
    c = im.crop(box)
    num = NAMES.index(name) + 1
    cw = c
    if cw.width > 900: cw = cw.resize((900, round(cw.height * 900 / cw.width)), Image.LANCZOS)
    cw.save(os.path.join(out, "images", f"{num:02d}.webp"), quality=80, method=6)
    sz = os.path.getsize(os.path.join(out, "images", f"{num:02d}.webp"))
    rows.append(f"{num:02d},{name},{page},{half},{box[0]},{box[1]},{box[2]},{box[3]},{c.width}x{c.height},{sz}")
    crops.append((f"{len(crops)+1}:{num:02d}", c))
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
open(os.path.join(out, "work", "map.csv"), "w", encoding="utf-8").write("num,name,page,half,x0,y0,x1,y1,size,bytes\n" + "\n".join(rows) + "\n")
print("cropped", len(rows), "total KB", sum(int(r.split(",")[-1]) for r in rows) // 1024)
