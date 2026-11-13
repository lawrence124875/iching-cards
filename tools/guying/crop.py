"""Crop the 64 卦影 woodcuts (Harvard 斷易天機, PD) with the tuned boxes in spec.json.
Output: <out>/images/NN.webp (King Wen number), <out>/work/crops_sheet.jpg, map.csv"""
import sys, os, json
from PIL import Image, ImageDraw
pages, out = sys.argv[1], sys.argv[2]
NAMES = ["乾","坤","屯","蒙","需","訟","師","比","小畜","履","泰","否","同人","大有","謙","豫","隨","蠱","臨","觀","噬嗑","賁","剝","復","無妄","大畜","頤","大過","坎","離","咸","恆","遯","大壯","晉","明夷","家人","睽","蹇","解","損","益","夬","姤","萃","升","困","井","革","鼎","震","艮","漸","歸妹","豐","旅","巽","兌","渙","節","中孚","小過","既濟","未濟"]
SPEC = json.load(open(os.path.join(os.path.dirname(__file__), "spec.json"), encoding="utf-8"))
os.makedirs(os.path.join(out, "images"), exist_ok=True); os.makedirs(os.path.join(out, "work"), exist_ok=True)
rows, crops = [], []
for page, half, name, (fx0, fy0, fx1, fy1) in SPEC["items"]:
    im = Image.open(os.path.join(pages, page + ".jpg")).convert("RGB")
    W, H = im.size; hw = W // 2; ox = 0 if half == "L" else hw
    c = im.crop((ox + int(fx0 * hw), int(fy0 * H), ox + int(fx1 * hw), int(fy1 * H)))
    num = NAMES.index(name) + 1
    w = c if c.width <= 720 else c.resize((720, round(c.height * 720 / c.width)), Image.LANCZOS)
    p = os.path.join(out, "images", f"{num:02d}.webp"); w.save(p, quality=72, method=6)
    rows.append(f"{num:02d},{name},{page},{half},{w.width}x{w.height},{os.path.getsize(p)}")
    crops.append((num, c))
crops.sort()
tw, cols = 220, 8; th = []
for n, c in crops:
    c = c.copy(); c.thumbnail((tw, tw)); th.append((n, c))
hh = max(c.height for _, c in th) + 16
s = Image.new("RGB", (cols * tw, ((len(th) + cols - 1) // cols) * hh), "white"); d = ImageDraw.Draw(s)
for i, (n, c) in enumerate(th):
    x, y = (i % cols) * tw, (i // cols) * hh
    s.paste(c, (x, y + 14)); d.text((x + 3, y + 1), f"{n:02d}", fill="red")
s.save(os.path.join(out, "work", "crops_sheet.jpg"), quality=72)
open(os.path.join(out, "work", "map.csv"), "w", encoding="utf-8").write("num,name,page,half,size,bytes\n" + "\n".join(sorted(rows)) + "\n")
print("cropped", len(rows), "KB", sum(int(r.split(",")[-1]) for r in rows) // 1024)
