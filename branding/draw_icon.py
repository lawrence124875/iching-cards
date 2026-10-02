"""桌面圖示（0.1.0+14 起：無框滿版，2026-10-02 使用者選定 A 版）。
玄底上直接畫謙卦 ䷎ 六爻；九三陽爻用較亮的稻金。卦象高度約為可見範圍的 62%，
圓角方形與圓形桌面都不會切到。執行：python3 branding/draw_icon.py（在 repo 根目錄）。"""
import os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
INK = (0x1C, 0x1B, 0x22); EARTH = (0xC9, 0xA4, 0x5C); RICE = (0xE0, 0xC0, 0x78)
LINES = [False, False, True, False, False, False]  # 謙 由下而上：初六、六二、九三、六四、六五、上六
SCALE = 0.62  # 卦象高度 ÷ 可見範圍


def hexagram(d, cx, cy, h):
    bw = h; bh = h * 0.105; gap = (h - bh) / 5; top = cy - h / 2
    for i in range(6):
        yang = LINES[5 - i]  # 由上往下畫
        y = top + i * gap
        col = RICE if yang else EARTH
        if yang:
            d.rectangle((cx - bw / 2, y, cx + bw / 2, y + bh), fill=col)
        else:
            seg = bw * 0.42
            d.rectangle((cx - bw / 2, y, cx - bw / 2 + seg, y + bh), fill=col)
            d.rectangle((cx + bw / 2 - seg, y, cx + bw / 2, y + bh), fill=col)


def foreground(S):
    """自適應圖示前景（108dp 畫布，可見範圍約中央 72dp＝66.7%），透明底。"""
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    hexagram(ImageDraw.Draw(im), S / 2, S / 2, S * (72 / 108) * SCALE)
    return im


def legacy(S):
    """傳統圖示與上架大圖：圓角方形玄底＋卦象。"""
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, S - 1, S - 1), radius=S * 0.22, fill=INK)
    hexagram(d, S / 2, S / 2, S * SCALE)
    return im


def hi(fn, px):
    return fn(px * 4).resize((px, px), Image.LANCZOS)


res = os.path.join(HERE, 'android', 'res')
for dens, fg_px, lg_px in [('mdpi', 108, 48), ('hdpi', 162, 72), ('xhdpi', 216, 96),
                           ('xxhdpi', 324, 144), ('xxxhdpi', 432, 192)]:
    hi(foreground, fg_px).save(os.path.join(res, f'mipmap-{dens}', 'ic_launcher_foreground.png'))
    hi(legacy, lg_px).save(os.path.join(res, f'mipmap-{dens}', 'ic_launcher.png'))
hi(legacy, 1024).save(os.path.join(HERE, 'icon-1024.png'))
print('done')
