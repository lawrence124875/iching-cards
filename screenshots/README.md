# 商店截圖（App 真實畫面渲染）

2026-10-05 起，商店截圖不再用手機截：以 Flutter widget test 在雲端／本機渲染 App 真實畫面
（`store_screenshots_test.dart`），英文介面、會員狀態（無廣告），1080×2400、密度 2.625（Redmi 實機比例），
字型為 App 打包的思源子集，牌面與解讀為 iching-content 正式內容。HANDOFF §21.2。

⚠️ 截圖含私人內容：輸出資料夾放在本 repo 之外，成品只進私人 repo iching-content。

## 步驟（目錄結構：/home/user/iching-cards 與 /home/user/iching-content 並列）

```bash
# 1. 像 CI 一樣準備內容、術語表、字型子集（不進 repo，.gitignore 已擋）
bash scripts/import_content.sh ../iching-content
python3 scripts/gen_glossary.py ../iching-content/glossary/glossary.json lib/l10n/glossary_data.g.dart
#    字型原檔：build_android.yml「產生字型子集」步驟的 NOTO_COMMIT 與四個網址，下載到 ../_fonts_src
pip install pillow fonttools==4.62.1
python3 scripts/build_fonts.py ../_fonts_src assets/fonts
flutter pub get

# 2. 渲染 8 張原始畫面（raw-01.png…raw-08.png，約 10 分鐘）
SCREENSHOT_OUT=/tmp/shots flutter test --no-pub screenshots/store_screenshots_test.dart

# 3. 排版（輸出到 iching-content/store/screenshots-en/screenshot-01.png…）
python3 ../iching-content/store/screenshots-en/make.py /tmp/shots/raw-*.png
```

改了畫面、內容或順序：改 `store_screenshots_test.dart`（順序與 make.py 的 ITEMS 一致），重跑 2、3。
其他語言：測試裡的 `Locale`、`L10n.language` 換成該語言即可，標題文字在對應的 make.py。
