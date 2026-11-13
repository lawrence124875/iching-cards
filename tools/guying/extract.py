"""Extract scan pages from Harvard 斷易天機 PDFs and build contact sheets (REFERENCE: hexagram-art PLAN stage 1)."""
import sys, os, fitz
from PIL import Image, ImageDraw
src, pages_dir, sheet_dir = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(pages_dir, exist_ok=True); os.makedirs(sheet_dir, exist_ok=True)
names = []
for vol in ("v1", "v2"):
    doc = fitz.open(os.path.join(src, f"{vol}.pdf"))
    for i, page in enumerate(doc, 1):
        out = os.path.join(pages_dir, f"{vol}_p{i:03d}.jpg")
        if not os.path.exists(out):
            imgs = page.get_images(full=True)
            if imgs:
                xref = max(imgs, key=lambda x: x[2] * x[3])[0]
                pix = fitz.Pixmap(doc, xref)
                if pix.n - pix.alpha >= 4: pix = fitz.Pixmap(fitz.csRGB, pix)
                im = Image.frombytes("RGB" if pix.n >= 3 else "L", (pix.width, pix.height), pix.samples)
            else:
                pix = page.get_pixmap(dpi=200)
                im = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
            im = im.convert("RGB")
            if im.width > 2600: im = im.resize((2600, round(im.height * 2600 / im.width)))
            im.save(out, quality=88)
        names.append(out)
print("pages", len(names))
TW, PER = 300, 30
for s in range(0, len(names), PER):
    chunk = names[s:s + PER]
    thumbs = []
    for n in chunk:
        im = Image.open(n); im.thumbnail((TW, TW))
        thumbs.append((os.path.basename(n)[:-4], im))
    cols = 6; rows = (len(thumbs) + cols - 1) // cols
    H = max(t[1].height for t in thumbs) + 18
    sheet = Image.new("RGB", (cols * TW, rows * H), "white"); d = ImageDraw.Draw(sheet)
    for k, (lab, im) in enumerate(thumbs):
        x, y = (k % cols) * TW, (k // cols) * H
        sheet.paste(im, (x, y + 16)); d.text((x + 4, y + 2), lab, fill="red")
    sheet.save(os.path.join(sheet_dir, f"sheet_{s // PER + 1:02d}.jpg"), quality=70)
