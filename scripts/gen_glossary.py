#!/usr/bin/env python3
"""術語表 → Dart 常數（HANDOFF §17）。只在 CI 執行。

輸入：私人 repo iching-content 的 glossary/glossary.json（唯一來源）。
輸出：lib/l10n/glossary_data.g.dart（不進 repo，.gitignore 擋住）。

只取 App 介面需要的欄位：64 卦的 name／title／meaning（日文另有讀音）、八經卦的 name／image、
12 個傳統爻名與用九／用六。⚠️ 公開 repo 的 Actions 紀錄任何人都看得到：只印數量。
"""
import json
import pathlib
import sys

TRIGRAMS = ["qian", "dui", "li", "zhen", "xun", "kan", "gen", "kun"]


def dart(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$") + "'"


def fail(msg: str) -> None:
    print(f"::error::術語表檢查失敗：{msg}")
    sys.exit(1)


def main() -> None:
    src = pathlib.Path(sys.argv[1])
    out = pathlib.Path(sys.argv[2])
    g = json.loads(src.read_text(encoding="utf-8"))
    langs = [l["code"] for l in g["languages"]]
    hexes = sorted(g["hexagrams"], key=lambda h: h["number"])
    if [h["number"] for h in hexes] != list(range(1, 65)):
        fail("卦序不是 1–64")

    lines = ["// 由 scripts/gen_glossary.py 從 iching-content/glossary/glossary.json 產生，請勿手改。",
             "// ignore_for_file: lines_longer_than_80_chars",
             "part of 'glossary.dart';", "",
             "const _languages = [" + ", ".join(dart(c) for c in langs) + "];", ""]

    lines.append("const _hexagrams = <String, List<GlossaryHexagram>>{")
    for code in langs:
        lines.append(f"  {dart(code)}: [")
        for h in hexes:
            n = h["names"].get(code)
            if not n or not n.get("name") or not n.get("title"):
                fail(f"{code} 缺第 {h['number']} 卦名稱")
            meaning = n.get("meaning", "")
            lines.append(
                f"    GlossaryHexagram({dart(n['name'])}, {dart(n['title'])}, {dart(meaning)}, "
                f"{dart(n.get('reading', ''))}, {dart(n.get('titleReading', ''))}),")
        lines.append("  ],")
    lines.append("};")
    lines.append("")

    lines.append("const _trigrams = <String, Map<String, GlossaryTrigram>>{")
    for code in langs:
        lines.append(f"  {dart(code)}: {{")
        for k in TRIGRAMS:
            t = g["trigrams"][k].get(code)
            if not t:
                fail(f"{code} 缺經卦 {k}")
            lines.append(f"    {dart(k)}: GlossaryTrigram({dart(t['name'])}, {dart(t['image'])}),")
        lines.append("  },")
    lines.append("};")
    lines.append("")

    lines.append("const _lines = <String, GlossaryLines>{")
    for code in langs:
        l = g["lines"].get(code)
        if not l:
            fail(f"{code} 缺爻名")
        yang, yin = l["labels"]["yang"], l["labels"]["yin"]
        if len(yang) != 6 or len(yin) != 6:
            fail(f"{code} 爻名不是 6 個")
        lines.append(
            f"  {dart(code)}: GlossaryLines([{', '.join(dart(s) for s in yang)}], "
            f"[{', '.join(dart(s) for s in yin)}], {dart(l['allYang'])}, {dart(l['allYin'])}),")
    lines.append("};")
    lines.append("")

    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"已產生術語表：{len(langs)} 語、{len(hexes)} 卦、{len(TRIGRAMS)} 經卦")


if __name__ == "__main__":
    main()
