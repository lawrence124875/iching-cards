#!/usr/bin/env bash
# 把私人 repo iching-content 的內容複製進 App 資產（只在 CI 執行）。
# ⚠️ 本 repo 公開、Actions 紀錄任何人都看得到：這裡只印數量，不印檔名或內容。
set -euo pipefail
src="${1:?用法：import_content.sh <iching-content 路徑>}"

mkdir -p assets/content/zh-Hant assets/cards
n_json=0
for f in "$src"/zh-Hant/[0-9][0-9]-*.json; do
  [ -e "$f" ] || continue
  cp "$f" "assets/content/zh-Hant/$(basename "$f" | cut -c1-2).json"
  n_json=$((n_json + 1))
done

# 牌面圖：先複製一般檔，再讓重產版（-v2、-v3…）覆蓋。
n_img=0
for pass in normal redo; do
  for f in "$src"/images/webp/[0-9][0-9]-*.webp; do
    [ -e "$f" ] || continue
    case "$(basename "$f")" in
      *-v[0-9]*) [ "$pass" = redo ] || continue ;;
      *) [ "$pass" = normal ] || continue ;;
    esac
    cp "$f" "assets/cards/$(basename "$f" | cut -c1-2).webp"
    [ "$pass" = normal ] && n_img=$((n_img + 1))
  done
done

echo "已匯入解讀 ${n_json} 卦、牌面圖 ${n_img} 張"
