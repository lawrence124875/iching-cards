#!/usr/bin/env python3
"""CI 用：把思源黑體／宋體（Noto Sans TC／Noto Serif TC，OFL）切成 App 用的子集。

HANDOFF §6.2、§15。完整字型每個 12–17 MB，只保留需要的字：
  1. Big5 常用字（第一字面 5,401 字）——使用者輸入「想問的事」、回顧時用得到
  2. 實際用到的字：assets/content/**/*.json（解讀內容）＋ lib/**/*.dart、lib/l10n/*.arb（介面文字）
  3. 英數、標點、全形符號
不在子集中的字（罕用字）會由系統字體自動補上，不會變成方框。

⚠️ 公開 repo 的 Actions 紀錄任何人都看得到：只印字數與檔案大小，不印字元。

用法：python3 scripts/build_fonts.py <下載的可變字型資料夾> <輸出資料夾 assets/fonts>
"""
import pathlib
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

# (來源可變字型, 字族, 字重)；輸出檔名為「字族-字重.ttf」，須與 pubspec.yaml 一致
# 程式目前沒有指定粗體：Material 按鈕與小標用 500，其餘 400；
# 若日後要粗體，Flutter 會以 400 合成（或在這裡加 700 並同步改 pubspec.yaml）。
WEIGHTS = [
    ("NotoSansTC[wght].ttf", "NotoSansTC", 400),
    ("NotoSansTC[wght].ttf", "NotoSansTC", 500),
    ("NotoSerifTC[wght].ttf", "NotoSerifTC", 400),
]


def big5_common() -> set[str]:
    """Big5 第一字面常用字（0xA440–0xC67E）。"""
    out = set()
    for hi in range(0xA4, 0xC7):
        for lo in list(range(0x40, 0x7F)) + list(range(0xA1, 0xFF)):
            code = (hi << 8) | lo
            if code < 0xA440 or code > 0xC67E:
                continue
            try:
                out.add(bytes([hi, lo]).decode("big5"))
            except UnicodeDecodeError:
                pass
    return out


def used_chars(root: pathlib.Path) -> set[str]:
    chars = set()
    for pattern in ("assets/content/**/*.json", "lib/**/*.dart", "lib/**/*.arb"):
        for f in root.glob(pattern):
            chars.update(f.read_text(encoding="utf-8"))
    return chars


def main() -> None:
    src = pathlib.Path(sys.argv[1])
    out = pathlib.Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    root = pathlib.Path(__file__).resolve().parent.parent

    chars = big5_common() | used_chars(root)
    ranges = [(0x20, 0x7E), (0xA0, 0xFF), (0x2000, 0x206F), (0x3000, 0x303F), (0xFF00, 0xFFEF)]
    for a, b in ranges:
        chars.update(chr(c) for c in range(a, b + 1))
    codepoints = {ord(c) for c in chars if ord(c) >= 0x20}
    print(f"子集字數：{len(codepoints)}")

    cache: dict[str, TTFont] = {}
    for fname, family, wght in WEIGHTS:
        if fname not in cache:
            cache[fname] = TTFont(src / fname)
        font = instancer.instantiateVariableFont(cache[fname], {"wght": wght}, inplace=False)
        opts = subset.Options()
        opts.layout_features = ["*"]  # 保留直排、全形標點等 OpenType 功能
        opts.name_IDs = ["*"]
        opts.notdef_outline = True
        opts.hinting = False  # 手機高解析度不需要 hinting，可再省空間
        sub = subset.Subsetter(opts)
        sub.populate(unicodes=codepoints)
        sub.subset(font)
        path = out / f"{family}-{wght}.ttf"
        font.save(path)
        print(f"{path.name}：{path.stat().st_size / 1e6:.2f} MB")


if __name__ == "__main__":
    main()
