# HANDOFF — 易經卦卡 App（名稱未定）

> 新對話接續時請先讀本檔。本檔記錄已確定的決策、內容規格與待討論事項。
> 最後更新：2026-10-03（**Firebase 0.1.0+20**：改加進智慧聽覺巡航的 Firebase 專案（帳號專案數已滿），Analytics、Crashlytics、Remote Config，`qg_` 前綴＋App 條件，見第 18 節；**11 語術語表使用者審閱無意見、定稿**，App 端套用待做，見第 17 節；run #36 使用者實機回饋良好；0.1.0+19（run #36）：**介面翻譯架構（ARB）**，繁中＋英文介面，英文暫不開放，見第 16 節；「寫下想問的事」連結字體縮小，見 15.2；0.1.0+18：置中提示語去標點、逗號處換行，見 15.1；run #33 字體使用者實機確認沒問題；0.1.0+17：打包思源黑體／宋體子集，見第 15 節；run #32（0.1.0+16）使用者實機確認可用；0.1.0+16：首頁一屏顯示完、免責聲明縮小貼底，見 14.7；0.1.0+15：鎖屏媒體按鈕圖示被資源壓縮移除的修正、測試提醒鈕，見 14.6；0.1.0+14：桌面圖示改無框滿版，見 14.4；0.1.0+13：鎖定畫面暫停／停止鍵、桌面圖示比例，見 14.4；0.1.0+12：版面修正，見 14.3；0.1.0+11：卦記提醒準時模式，見 13 節末；0.1.0+10：音景柔和版、432Hz 調音、雙耳節拍，見 14.2；0.1.0+9：實機回饋修正與音景背景播放，見 14.1；**呼吸音景** 0.1.0+8，見第 14 節；卦記功能 0.1.0+7，見第 13 節；**64 卦中文初稿全部完成**，01–36 東西相映名人優先檢查也已完成（見 4.5），下一步由使用者審閱定稿；多語言規劃見第 12 節）

---

## 1. 專案概述

- 以《易經》六十四卦為題材的身心靈療癒卦卡 App（Android，Flutter）。
- 目標：給使用者「希望」（卦象解讀）＋「實質有感」（小行動、反思、東西相映、呼吸音景）。
- 原則：零額外花費；解讀全部預先寫好，不用 AI API、不需後端。
- 定位：自我探索與反思工具，不做預測保證。App 內與商店描述標示「內容僅供自我探索與娛樂參考」。

## 2. 基礎建設

| 項目 | 做法 |
|---|---|
| GitHub | 本 repo 專用（公開，GitHub Pages 放隱私權政策）。現有 fine-grained 權杖加入本 repo 即可 |
| Firebase | ~~新開專案~~ → 2026-10-03 改為**加進智慧聽覺巡航的 Firebase 專案**（帳號專案數已滿），同專案第二個 Android App `com.lclab.qiangua`；Spark 免費方案，Analytics＋Crashlytics＋Remote Config。共用規則見第 18 節 |
| Google Play Console | 沿用現有開發者帳號。新 App 須重跑封閉測試（12 位以上、連續 14 天） |
| AdMob / RevenueCat | 沿用現有帳號，新增 App |
| 簽署金鑰 | 另建新的上傳金鑰，與智慧聽覺巡航分開；存 GitHub Secrets，本機備份 |
| CI | `.github/workflows/build_android.yml`：push 到 main 即建置，**只改 .md 不觸發**（2026-10-01 改，避免每次更新 HANDOFF 都多一個 Release）；保留 `workflow_dispatch` 手動建置。詳見 11.3 |

⚠️ applicationId（套件名稱）第一次上傳 Play 後無法更改，需在 App 名稱確定後再定。repo 名稱可日後更改。

## 3. 已確定的決策

- 題材：易經六十四卦卦卡。
- 起卦方式：兩種都提供，由使用者選擇。
  - 簡單抽卡（首頁主按鈕「抽一卦」）
  - 擲錢起卦（三枚銅錢擲六次，含變爻與之卦；首頁次要連結）
- 卦解讀：每卦 3 組，隨機顯示一組，著重「象」。
- 爻解讀：每爻 1 組，著重「象」。
- 不做問事分類（事業／感情等），使用者自行解象套用。
- 每組解讀結尾同時保留「今日小行動」與「反思提問」。
- 語言：先做繁體中文＋英文；日後比照智慧聽覺巡航擴充至 11 語。
- 牌面圖：Gemini 生成擬真風景，9:16，全 64 卦共用風格提示詞。
- 牌面版本：有框版。
- 每卦加入「東西相映」區塊：一句哲學名句＋一個心理學概念（見 4.5）。
- 視覺主題：以謙卦為主題的配色（見第 6 節）。

## 4. 內容規格

### 4.1 卦（每卦）

**共用原文**（每次都顯示）：卦辭、《彖傳》、《大象傳》。

**三組解讀**（隨機一組），每組結構：
1. 象的畫面（具體景象）
2. 象從哪裡來（上下卦、卦主、爻位、內外卦等，教使用者看象）
3. 給現在的你（生活提醒，開放式，不分類）
4. 今日小行動（一句）
5. 反思提問（一句）

三組需各取不同看象角度（例如：上下卦關係／大象傳／卦主與內外卦）。每組約 250–300 字。

### 4.2 爻（每爻）

1. 原文：爻辭＋《小象傳》
2. 象的畫面
3. 象從哪裡來（爻位、陰陽、當位與否、應與比、所在經卦）
4. 給現在的你

另需：乾卦「用九」、坤卦「用六」。

### 4.3 變爻取用規則（朱熹《易學啟蒙》）

| 變爻數 | 看哪裡 |
|---|---|
| 0 | 本卦卦辭 |
| 1 | 該變爻爻辭 |
| 2 | 兩變爻爻辭，以上爻為主 |
| 3 | 本卦與之卦卦辭 |
| 4 | 之卦兩個不變爻，以下爻為主 |
| 5 | 之卦唯一不變爻 |
| 6 | 乾坤看用九／用六，其餘看之卦卦辭 |

App 自動標出「本次重點」。

### 4.5 東西相映（2026-09-30 決定）

- 位置：解讀的「給現在的你」之後，獨立小區塊。
- 每卦固定一組，不隨三組解讀變動：
  1. 哲學名句（附原著出處，例如「《邏輯哲學論》5.6」）＋一兩句說明與本卦的呼應
  2. 心理學概念（附提出者與年份）＋一兩句說明與本卦的呼應
- 候選：特斯拉在腦中完整模擬發明的敘述（出自其 1919 年自傳《My Inventions》，公有領域），可配「象」的思維；使用前須核對英文原文並自行翻譯。
- 配對範例（尚未定稿）：謙＝聚光燈效應（Gilovich, 2000）；升＝竹子比喻（呼應「地中生木，積小以高大」）；蒙＝畢馬龍效應（Rosenthal & Jacobson, 1968）；艮＝維根斯坦《邏輯哲學論》第 7 條。
- 原則：
  - 名句必須可查證，對到原著篇章／段落編號；網路流傳但查無出處者不收。
  - 心理學誠實標示證據強弱：有爭議者寫「研究發現可能……」（如畢馬龍效應重複驗證效果較小）；非研究者標示為「比喻」或「寓言」（如竹子理論，且避免誇大數字）。
  - 證據薄弱的流行說法不收（如一萬小時定律、左右腦性格、權力姿勢）。
  - 版權：原文已進公有領域者（如維根斯坦德文原著）由我們自行翻譯中英文；不引用仍有版權的譯本。理論概念用自己的話寫。
- **名人優先（2026-10-02 使用者決定）**：東西相映優先選用下列名人，不另開欄位。37–64 卦直接照此寫（不先給配對草稿）；**64 卦全部寫完後，回頭檢查 01–36**，能換成名單人物且同樣貼切的就換，沒有更好更適合的才保留原本。
  - 心理學：佛洛伊德、威廉・詹姆斯、馮特、皮亞傑、斯金納、羅傑斯、馬斯洛、班杜拉、榮格、巴夫洛夫。
  - 哲學：蘇格拉底、柏拉圖、亞里斯多德、笛卡兒、康德、尼采、馬克思、洛克、羅素、維根斯坦（孔子、老子屬「東」，不放此區）。
  - 01–36 已用：班杜拉（01）、羅傑斯（31）、蘇格拉底／柏拉圖（04、14、20）、亞里斯多德（09）、尼采（16）、康德（35）。
  - 37–41 已用：亞里斯多德＋馬斯洛（37）、洛克＋佛洛伊德〈投射〉（38）、笛卡兒＋皮亞傑（39）、維根斯坦 6.521＋巴夫洛夫〈消弱〉（40）、蘇格拉底（拉爾修記載）＋W. 詹姆斯〈自尊公式〉（41）。名單中尚未用過：心理學——馮特、斯金納、榮格；哲學——馬克思、羅素（羅素只能介紹理論，不引原句）。
  - 42–46 已用：馬克思〈費爾巴哈提綱〉第十一條＋斯金納〈逐步塑造〉（42）、尼采《偶像的黃昏》格言 44＋佛洛伊德〈談話治療〉（43）、康德《實踐理性批判》〈結論〉星空與道德法則＋榮格〈陰影〉（44）、亞里斯多德《政治學》1253a＋馮特〈民族心理學〉（45）、柏拉圖《會飲篇》211c＋羅傑斯〈實現傾向〉（46，取代原構想的竹子比喻）。名單中只剩羅素尚未用過；之後名單人物可重複，但同一部著作的同一段不重複（亞里斯多德《倫理學》II.1、康德〈何謂啟蒙〉、笛卡兒《談談方法》第三部分已用）。
  - 47–51 已用：蘇格拉底《克力同篇》48b＋塞利格曼與梅爾〈習得無助〉（非名單，最貼切，含 2016 修正）（47）、笛卡兒《談談方法》第一部分＋榮格〈集體潛意識〉（48）、洛克《政府論》下篇 §225＋勒溫〈解凍—改變—再凍結〉（非名單）（49）、柏拉圖《理想國》433a＋佛洛伊德〈昇華〉（50）、尼采《偶像的黃昏》〈格言與箭〉第 8 則＋巴夫洛夫〈探究反射〉（51）。另外已用：《談談方法》第一部分、《偶像的黃昏》格言 8／33／44、《申辯篇》21d／38a。
  - 52–56 已用：維根斯坦《邏輯哲學論》第 7 條＋W. 詹姆斯〈選擇性注意〉（52）、亞里斯多德《尼各馬可倫理學》I.7 1098a18「一隻燕子不成春」＋班杜拉〈觀察學習〉（53）、馬克思《1844 年經濟學哲學手稿》〈貨幣〉「以愛換愛」＋馬斯洛〈匱乏之愛與存在之愛〉（54）、尼采《查拉圖斯特拉如是說》〈序言〉§1 對太陽說話＋榮格〈對反轉化〉（55）、康德《論永久和平》第三條確定條款（好客）＋奧伯格〈文化衝擊〉（非名單，最貼切）（56）。心理學概念不重複（享樂適應已用於 14、延遲滿足已用於 05）。
  - 57–61 已用：尼采《查拉圖斯特拉》第二部〈最寂靜的時刻〉＋艾賓豪斯〈間隔效應〉（非名單，最貼切）（57）、柏拉圖《第七封信》341c–d（真偽有爭議，已註明）＋佛洛伊德〈快樂原則與現實原則〉（58）、笛卡兒《第一哲學沉思集》第二沉思（蠟塊）＋謝里夫〈超級目標〉（非名單，最貼切）（59）、亞里斯多德《倫理學》II.6 1106b36（中道）＋斯金納〈自我控制技術〉（60）、尼采《善惡的彼岸》§183＋羅傑斯〈真誠一致〉（61）。尼采已用 6 次、亞里斯多德 6 次。
  - 62–64 已用：洛克《人類理解論》I.i.6「本分不是知道一切」＋W. 詹姆斯〈習慣〉（62）、柏拉圖《理想國》546a「凡生成者皆有衰敗」＋克萊恩〈事前驗屍〉（非名單，最貼切）（63）、康德〈普遍歷史理念〉第六命題「彎曲的木頭」＋蔡格尼克效應（非名單，最貼切，註明重複驗證不一）（64）。名單中只有羅素從未使用（只能介紹理論、不引原句），回頭檢查 01–36 時可考慮。
  - **01–36 回頭檢查完成（2026-10-02）**：換 8 項——02 心理學 安全基地→羅傑斯〈無條件正向關懷〉；15 名句 蒙田高蹺→維根斯坦《邏輯哲學論》〈序〉最後一段（「問題解決了，所成就的事是多麼少」，對九三勞謙「有功而不德」）；16 心理學 品味→馮特曲線（倒 U，對鳴豫、冥豫）；18 名句 奧維德→馬克思《霧月十八日》第一章開頭（死去世代的傳統，對幹父之蠱）、心理學 現狀偏誤→佛洛伊德〈強迫性重複與修通〉（1914）；26 名句 牛頓→洛克《論理解力的運用》§20（閱讀只是材料，要反芻）；27 心理學 自我疼惜→巴夫洛夫〈古典制約與線索引發的食慾〉（對初九觀我朵頤）；36 名句 巴斯卡→笛卡兒《私人思考》larvatus prodeo（AT X 213，對用晦而明）。
  - 保留不換（名單中沒有同樣貼切者，或會與 37–64 重複概念）：01 奧理略、03 奧理略＋合意的困難（皮亞傑的平衡化與 39 同化調適重複）、05 里爾克＋延遲滿足、06 斯賓諾莎＋天真實在論、07 塞內卡＋心理安全感、08 西塞羅＋歸屬需求（馬斯洛歸屬已用於 37）、09–14、17、19–25、28–35 原配對皆保留。04、09、14、20、31、35 本來就是名單人物。
  - 羅素仍未使用：名句欄必須引原文，而羅素原文仍有版權，不適合放入；若日後要用，只能放在說明文字中以自己的話介紹。
  - 版權：名句只引公有領域原文並自行翻譯。羅素（1970 卒）、榮格（1961 卒）原文仍有版權，只能用自己的話介紹其理論，不引原句（如羅素自傳「三種激情」不可用）。維根斯坦只引《邏輯哲學論》；「我的語言之界限，意味著我的世界之界限」是 5.6（早期），不是《哲學研究》；第 7 條已用於 52 艮。
  - 證據：佛洛伊德的潛意識、榮格的原型標示為理論或比喻；馬斯洛需求層次須註明「嚴格階梯」缺乏實證支持；皮亞傑階段論註明後續研究的修正。

### 4.6 內容檔案（2026-10-01 決定）

- 存放：私人 repo `lawrence124875/iching-content`（2026-10-01 已建立，權杖已授權）。建置時由 GitHub Actions 以 Secrets 權杖抓取。**解讀內容一律不 commit 到本公開 repo**（git 歷史無法收回）。
- 格式：直接寫 JSON，一卦一檔，各語言分資料夾：`zh-Hant/01-qian.json`、`en/01-qian.json`。
- 順序：依卦序從乾卦開始；中文一批定稿後再寫英文。
- 經文逐卦對照維基文庫《周易》原文（zh.wikisource.org）。
- 結構：
  - `id, name, fullName, symbol, pinyin, upper, lower`
  - `text`：`judgment`（卦辭）、`tuan`（彖傳）、`daxiang`（大象傳）
  - `readings[3]`：`title, image, source, forYou, action, question`
  - `lines[6]`（乾坤為 7，含用九／用六，position 7）：`position, name, stage, text, xiaoxiang, image, source, forYou`
  - `eastWest.quote`：`text, author, source, translationNote, note`
  - `eastWest.psychology`：`name, origin, evidenceNote, note`
- 進度：乾、坤卦中文初稿完成（2026-10-01，待使用者審閱），兩卦 `art.prompt` 皆已填入 Gemini 提示詞。03 屯～64 未濟中文初稿完成（2026-10-02，待審閱；**64 卦全部完成**）。最新進度以 iching-content README 為準。

### 4.4 內容份量

- 卦解讀：64 × 3 = 192 段
- 爻解讀：384 段＋用九、用六 2 段
- 東西相映：64 句名句＋64 個心理學概念
- 每種語言各一份

### 4.5 寫作原則

- 不做醫療預測或健康判斷；身心相關只談情緒、壓力、作息，身體不適提醒就醫。
- 不用性別刻板印象，解讀對任何性別都適用。
- 不用保證式、絕對性用語（如「必定」「立於不敗之地」）。
- 不給具體投資方向。
- 經文用公有領域原文；英文版不可引用 Wilhelm/Baynes 英譯本（可能仍有版權），Legge 1882 譯本為公有領域，最好自行撰寫。

- 「象的畫面」寫法（2026-09-30 決定，借鏡民間卦圖的精神）：不只描述單一景色，而是讓畫面中的多個元素各自對應卦的結構（上下卦、主爻、爻位等），引導使用者自己看出象來。對應依據一律來自經文與卦體，不用諧音、拆字、姓氏、生肖等射覆式解法。
- 謙卦加入「真謙與假謙」的角度（例如反思提問：「你的低調，是真的不需要被看見，還是希望別人主動發現你？」），於量產謙卦內容時納入其中一組；文字自行撰寫。

- 爻解讀的統一框架（2026-09-30 決定）：六爻即一件事發展的六個階段（初＝剛起步、二＝初露、三＝轉換關口、四＝接近核心、五＝盛位、上＝走到盡頭），「給現在的你」先讓使用者知道自己「現在在哪一步」。比喻須通用，不限職場或特定問事類別。
- 定位語可用：以占筮為形式、以反思為目的——「易經不是用來算命，而是練習看象與做決定」。可用於商店說明與關於頁。
- 「保持童蒙」（先假設別人是對的，再去驗證）的學習態度，可作為首次開啟或關於頁的一句話；用自己的話寫。
- 經文一律以原文核對（例：乾九四為「或躍在淵」，網路常誤作「活躍在淵」）。

## 5. 版權注意

- 易學網（易經卦卡）的卡圖有版權，不可照畫或改畫；整體外觀（土黃底、同樣欄位位置、宇宙太極牌背）也要避開。
- 版面元素（卦象、卦序、英文卦義、拼音、經卦顏色、經文）可自由使用。
- 倪海廈「六十四卦圖解」（使用者提供的 PDF）僅供參考：圖文有著作權、檔案疑似未授權轉傳，且內容為預測式（姓氏、生肖、死喪、官司）並含性別刻板框架，不可引用、照畫或改寫。
- Gemini 生成圖：正式採用前確認 Gemini 當下條款允許用於上架 App。

## 6. 視覺設計

設計畫布（試作）：https://claude.ai/artifact/TEy7KCWxspe4Qx1RuiRHZj
含：有框牌面、滿版牌面、牌背（先天八卦環）、配色與字體、首頁、解卦頁。

### 6.1 配色（謙卦主題：天玄地黃，玄底黃點綴）

| 名稱 | 色碼 | 用途 |
|---|---|---|
| 玄墨 | #1C1B22 | 主背景 |
| 玄灰 | #26242E | 卡片底 |
| 地黃 | #C9A45C | 主色（坤・土） |
| 稻金 | #D8B56A | 點綴 |
| 山褐 | #7E6A52 | 輔色（艮・山） |
| 淡金 | #E8D9B0 | 深底主文字 |
| 灰穗 | #A89F8C | 深底次文字 |
| 紙白 | #EDE4D0 | 淺色模式底 |

經卦顏色採五行：乾兌＝金（白、金）、震巽＝木（綠）、坎＝水（黑、藍）、離＝火（紅）、坤艮＝土（黃）。

### 6.2 字體

- 思源宋體 Noto Serif TC：卦名、經文、標題
- 思源黑體 Noto Sans TC：白話解讀、介面

### 6.3 牌面

- 牌面：卦序、卦象符號、卦名、拼音、英文卦義、上下經卦標示；經文放詳細頁。
- 牌背：先天八卦環（不用太極圖）。
- 採用**有框版**（2026-09-30 決定）：風景照置於框內，周圍留邊放卦序、卦象、卦名、拼音、英文卦義與上下經卦。

### 6.4 Gemini 提示詞範本（9:16）

每卦只改 Foreground／Background／Sky；Composition、Light、Mood 視卦調整；Style 與最後一行固定。

```
A photorealistic vertical landscape, 9:16 aspect ratio.
Composition: the top fifth is calm, empty dark sky; the horizon sits slightly above the middle of the frame; the bottom fifth is dense, darker rice stalks in shadow.
Foreground: a vast field of ripe golden rice, heavy rice stalks bowing low under the weight of their grain, sharp detail on the nearest stalks.
Background: only a faint, low, distant mountain ridge barely rising above the horizon, much lower than the rice stalks in the frame, softened by evening haze, as if the mountains rest beneath the earth.
Sky: dark indigo night-falling sky, almost blue-black, with a faint pale crescent moon, calm and quiet.
Light: soft, low evening light, gentle warm glow on the rice.
Mood: humble, serene, grounded.
Style: muted earthy palette of ochre gold, umber brown and deep indigo, wabi-sabi atmosphere, 35mm film photography look with subtle grain, natural colors, not oversaturated.
Pure untouched nature: no people, no buildings, no houses, no lights, no roads, no text, no watermark, no frame.
```

謙卦已產出 1536×2752 版本（仍有山稜偏雄偉、地平線有細小建築的小瑕疵，量產時可重產）。

## 7. 待討論事項

1. App 名稱（→ 決定後再定 applicationId）
   - 方向：像「鼎泰豐」以吉卦卦名組成；使用者喜歡的意象：象、謙、光明、無限、豐盛。
   - 候選：謙泰恆、謙益恆、謙益、觀謙益、晉豐、謙光萬象。
   - 避開：含「泰豐」「恆泰」的組合（與鼎泰豐及其大陸經營公司「恆泰豐」近似）；既濟（初吉終亂）、噬嗑（刑獄之象）不適合作療癒品牌。
   - 「謙益恆」的可靠出處：《繫辭下》第七章「三陳九卦」，謙、恆、益同列九卦——「謙，德之柄也；恆，德之固也；益，德之裕也」「謙尊而光……恆雜而不厭……益長裕而不設」「謙以制禮……恆以一德……益以興利」。另：恆（雷風）與益（風雷）上下卦互換。注意：網路流傳「益卦由謙卦錯卦／變卦而來」有誤（謙之錯卦為履、綜卦為豫）；「謙益恆三卦」也非傳統固定稱法，品牌故事以《繫辭》九卦為準。
   - 選定後查 Play 商店與商標撞名，再定 applicationId。
2. ~~呼吸與音景~~ → 2026-10-02 已實作（0.1.0+8，見第 14 節）。原構想：2026-09-30 決定**納入**（曾一度暫緩，後改回）。構想：八經卦對應八種自然音景（水＝流水、雷＝遠雷雨、風＝林風、火＝營火、山＝山林寂靜、澤＝湖畔、天、地待定），抽到的卦以上下經卦組合音景，搭配 2–3 分鐘引導呼吸。音源待定，只考慮不花錢且可商用的來源：程式合成（雨、風、流水等噪音類效果佳），或 CC0 授權自然錄音；每個音檔需記錄來源與授權。呼吸節奏待定。
3. 商業模式（免費與付費內容劃分、廣告、訂閱）
4. ~~牌面採有框版或滿版版~~ → 已決定有框版（見 6.3）
5. ~~解讀內容的保護~~ → 2026-10-01 決定：解讀內容另放**私人 repo**（見 4.6），本 repo 不放任何解讀內容。

### 安全原則

repo 裡永遠不寫任何金鑰、密碼或權杖（含文件、commit 訊息、Issue）。簽署金鑰與 Firebase 設定檔一律存 GitHub Secrets。
任何 APK／AAB／IPA 都不可上傳到公開 repo 的 Artifacts，一律發佈到私人 repo iching-content 的 Release（見 10.4）。

## 9. 程式架構原則（2026-10-01 決定，開發時必須遵守）

目標：功能可隨時增加或減少，改一處不牽動全體（低耦合、高內聚；SOLID 的單一職責、開放封閉、依賴反轉）。

1. **功能模組化**：每個功能一個獨立資料夾（抽卡、擲錢、解讀、呼吸音景、東西相映、紀錄…），彼此不直接引用。首頁入口由「功能註冊表」產生；增減功能＝增減一個資料夾＋一行註冊。
2. **策略模式**：起卦方式共用介面（簡單抽卡、擲錢為兩個實作，日後可加蓍草法）；變爻取用規則（目前朱熹）、音景來源（程式合成／錄音檔）各自抽成策略。
3. **依賴反轉**：畫面只向「內容來源」介面要資料；目前實作為讀 App 內 JSON，日後換來源不改畫面。
4. **遠端開關**：Firebase Remote Config（免費方案）控制功能顯示，不發新版即可開關、測試付費內容。
5. **資料驅動**：卦、爻、語言全放 JSON；新增語言＝新增資料夾；JSON 帶 `schemaVersion`，新增欄位不讓舊程式壞掉。
6. **事件只給旁觀者**：例如「完成一次解卦」發出事件，由紀錄、統計、評分提醒各自接收；起卦→解讀主流程直接呼叫，便於追蹤。
7. **不過度抽象**：只在確定會變的地方加介面。
8. 限制：Flutter 為預先編譯，Google Play 也禁止下載執行新程式碼，**不做動態載入外掛**；拔除功能＝移出註冊表後重新建置，或以遠端開關隱藏。

### 9.1 平台：先 Android，保留直接做 iOS 的能力

- 先做 Android；程式從第一天就以「日後直接出 iOS」為前提。
- 套件只選同時支援 Android 與 iOS 者（pub.dev 確認平台標示）。
- 平台專屬程式（通知、音訊背景播放、檔案路徑等）一律包在介面後面，iOS 只需補實作。
- applicationId 與 iOS Bundle ID 用同一名稱，App 名稱定案後一起決定。
- Firebase、AdMob、RevenueCat 都支援 iOS；iOS 的付費內容必須走 Apple 內購，由 RevenueCat 統一處理。
- 做 iOS 時的注意事項（屆時再議）：
  - Apple Developer Program 年費 US$99，與「零額外花費」原則衝突，需另行決定。
  - iOS 建置需要 macOS：可用 GitHub Actions macOS runner（公開 repo 免費）。
  - App Store 審核指南 4.3 將算命類列為飽和類別，上架需凸顯差異（反思工具定位、原創內容）。

### 9.2 測試與上架流程

1. **階段一：個人手機測試**：GitHub Actions 建置 APK，發佈到私人 repo iching-content 的 Release（不用 Artifacts，見 10.4），使用者以手機登入 GitHub 下載安裝。
2. **階段二：大致確定後**上傳 Google Play **封閉測試**（AAB），並使用**付費外部測試服務**湊足 12 位測試者、連續 14 天。
3. 通過後申請正式版。

## 10. 開發路線圖（2026-10-01 決定）

原則：「內容」與「程式」並行；App 名稱不必先定（applicationId 只在第一次上傳 Play 時鎖死，個人測試階段先用暫定 ID，封閉測試前定名再改；Firebase 屆時在同一專案新增 App 即可）。每個對話只做內容或程式其中一項，節省 token。

### 10.1 第一階段：手機可裝的最小版本（MVP，只做繁中）

> 2026-10-01：1–5 項初版皆已完成並建置成功（run #1），待使用者實機試用回饋；上傳金鑰 Secrets 待使用者設定（11.4）。
1. Flutter 專案骨架，依第 9 節架構原則搭好功能註冊表、內容來源介面、起卦策略介面。
2. CI 自動建置 APK：建立新的上傳金鑰（存 Secrets）；建置時以 `BUILDS_REPO_TOKEN` 從私人 repo 抓內容；**APK 發佈到私人 repo 的 Release**（見 10.4）。
3. 核心流程：抽一卦 → 翻牌 → 解讀頁（三組隨機一組）→ 詳細頁（經文、六爻）。
4. 擲錢起卦：變爻、之卦，套用朱熹規則（4.3）。
5. 牌面與牌背：有框版；尚無圖的卦用佔位圖；尚未寫內容的卦顯示「內容撰寫中」。

### 10.2 第二階段：完整體驗
呼吸音景、紀錄與收藏、Firebase（Analytics、Crashlytics、Remote Config）、英文版。

### 10.3 第三階段：上架準備
App 名稱與 applicationId、商業模式（廣告與付費內容）、隱私權政策（本 repo GitHub Pages）、商店資訊、封閉測試（9.2）。

### 10.4 ⚠️ 建置產物一律發佈到私人 repo 的 Release（永久原則，英文 App 與易經 App 共同適用）

**原則**：公開 repo 的 Actions Artifacts，任何登入 GitHub 的人都能下載。因此**任何 APK、AAB、IPA 都不可用 `actions/upload-artifact` 上傳到公開 repo**，一律用 `gh release create` 發佈到私人 repo 的 Release。

- 易經 App 的發佈目標：私人 repo **`lawrence124875/iching-content` 的 Releases**。使用者以手機登入 GitHub，從那裡下載安裝。
- 參考實作：english-learning-app 的 `.github/workflows/build_android.yml` 最後一步（2026-10-01 以 #211 驗證成功）。寫法：

```yaml
      - name: 發佈到私人 repo 的 Release
        env:
          GH_TOKEN: ${{ secrets.BUILDS_REPO_TOKEN }}
        run: |
          gh release create "android-release-run${{ github.run_number }}" \
            build/app/outputs/flutter-apk/<含版本與run編號的檔名>.apk \
            build/app/outputs/bundle/release/<含版本與run編號的檔名>.aab \
            --repo lawrence124875/iching-content \
            --title "<版本> (run ${{ github.run_number }})" --notes "自動建置"
```

- 檔名帶版本與 run 編號；舊 Release 定期刪除，只保留最近數個。
- 內容抓取也用同一個 Secret：`actions/checkout` 以 `repository: lawrence124875/iching-content`、`token: ${{ secrets.BUILDS_REPO_TOKEN }}` 取得解讀內容（取代原先規劃的 `CONTENT_TOKEN`，不另建）。
- 公開 repo 的 Actions 紀錄任何人都看得到：建置步驟不可 `cat`／`echo` 內容檔或列出內容，不可印出權杖。
- 2026-10-01 檢查：iching-cards 尚無任何 workflow，兩個 repo 的 Artifacts 與 Actions 執行紀錄皆為 0；iching-content 已有 commit（Release 需要）。

**權杖分工（共三個，2026-10-01 決定）**

| 權杖 | 授權範圍 | 用途與存放 |
|---|---|---|
| 英文對話用 | english-learning-app | 每次貼在英文對話 |
| 易經對話用 | iching-cards＋iching-content | 每次貼在易經對話；Contents、Workflows、Actions 讀寫（2026-10-02 Actions 改讀寫：Claude 可用 workflow_dispatch 觸發建置，例如內容 repo 更新後） |
| CI 專用 `ci-private-releases` | english-app-builds＋iching-content，只有 Contents 讀寫 | **只存在 GitHub Secret，從不貼到對話**；兩個 App 的 CI 共用。英文 App 與 iching-cards 的 Secret 名稱都是 `BUILDS_REPO_TOKEN` |

⚠️ `ci-private-releases` 到期時，english-learning-app 與 iching-cards **兩個 repo 的 Secret 都要更新**。

**到期日（2026-10-01 記錄）**：易經對話用 `iching-cards` 2026-10-30（週五）；英文對話用 `english-app-claude` 2026-10-26（週一）；`ci-private-releases` 未設有效期。新對話若接近或已過到期日，主動提醒使用者到 https://github.com/settings/personal-access-tokens 重新生成。

**✅ 已驗證（2026-10-01）**：iching-cards 的 Secret `BUILDS_REPO_TOKEN` 已設好。以臨時 workflow（run 36804745907，驗證後已移除）確認：可 checkout iching-content、可在其上建立並刪除 Release。注意：workflow 的 `run:` 單行指令若含「: 」會造成 YAML 解析失敗（整個 run 沒有 job），一律改用 `run: |` 區塊寫法。

### 10.5 Gemini 牌面圖流程
- **時機**：每寫完一卦內容，同時提供該卦的 Gemini 提示詞（依 6.4 範本），存入該卦 JSON 的 `art` 欄位（`art.prompt`、`art.status`），方便日後重產。
- **64 張牌面原圖全部定案（2026-10-01）**：iching-content `images/raw/NN-slug.jpg`，皆 1536×2752、無可見浮水印；13、26、27、46、50 經重寫提示詞重產。
- **WebP 已完成（2026-10-01）**：iching-content `images/webp/NN-slug.webp`，1080×1920（等比縮放後上下各裁約 7px）、quality 80，64 張共 12.4 MB。日後重產某卦：原圖放 raw/，再請 Claude 重轉該張。
- **64 卦提示詞（2026-10-01 完成）**：iching-content `prompts/art-prompts.md`，含卦序、上下卦、大象與檔名對照。產圖改以 Google AI Studio 為優先（長寬比 9:16、2K），待使用者試產確認無可見浮水印與畫質。
- **下載**：一律用電腦從 gemini.google.com 下載原圖（謙卦電腦下載為 1536×2752；手機下載只有 768×1376，不可用）。手機產的圖，可在電腦開同一對話下載。
- **檔名**：`兩位數卦序-拼音`，副檔名照下載原樣（.jpg／.png），重產加 `-v2`；程式只認前兩碼卦序（乾／謙等拼音相同）。
- **上傳**：使用者直接以 GitHub 網頁上傳到 iching-content 的 `images/raw/`（不經對話，圖片在對話中很耗 token）。
- **轉檔**：Claude 以腳本統一轉成 1080×1920 WebP（每張約 300KB，64 張約 20MB），存 `images/webp/`。
- **原檔**：1536×2752 原檔由使用者自行備份在 Google 雲端硬碟，repo 只存轉檔後版本（避免 clone 變慢）。
- **授權（2026-10-01 查證）**：商業使用大致可行——Google 服務條款不主張生成內容的所有權，Gemini 生成內容一般可用於商業用途；但條款沒有明文的商業授權，Google 也不提供侵權擔保（可接受）。純 AI 生成圖可能不受著作權保護，他人可能照用（可接受）。Gemini 對話本身回答「可以用」不算依據，以條款為準。
- **可見浮水印（2026-10-01 已確認）**：Gemini App（Pro 方案）電腦下載的乾卦原圖（1536×2752 JPG）右下角無星芒 → 繼續用 Gemini App 產圖，不必改用 AI Studio。乾卦圖已定案，存於 iching-content `images/raw/01-qian.jpg`。以下為原先查證：
- **可見浮水印（背景）**：依 Nano Banana Pro 發表時的說明，免費與 Google AI Pro 方案的圖會保留右下角 Gemini 星芒浮水印，Ultra 與 Google AI Studio 則不加。使用者為 Pro 方案，需檢查已產出的圖是否帶星芒。如有，不自行裁切、修除或用牌框遮住，改評估以 Google AI Studio 產圖。所有圖另含不可見的 SynthID 浮水印，不影響使用。

### 10.6 下一步
1. ~~設定上傳金鑰~~、~~首頁置中與桌面圖示~~（0.1.0+3，run #4 完成）。使用者實機試用中（APK：https://github.com/lawrence124875/iching-content/releases ）。
2. 乾、坤卦：使用者看過實機後同意開始量產內容，格式沿用；之後有回饋再回頭修。
3. **內容量產**（2026-10-02 起）：**01～64 中文初稿全部完成**（2026-10-02，run 由 workflow_dispatch 觸發）。01–36 東西相映名人優先檢查已完成（2026-10-02，換 8 項，見 4.5）。經文版本差異（iching-content README）2026-10-02 使用者決定全部照王弼本採用，不再核對。**下一步**：使用者以手機逐卦審閱（另提供審閱用 Excel：64 卦東西相映、今日更動、經文差異，含「我的意見／狀態」欄，存於私人 repo iching-content `review/謙卦_64卦審閱表.xlsx`，不進本公開 repo），使用者回傳意見後修改；未提意見者視為定稿，再依第 12 節開始英文版。以下流程仍適用於修改既有卦：一個對話寫 4～5 卦（單一對話的長度上限，寫不完 62 卦），格式同 `01-qian.json`、`02-kun.json`。`art.prompt` 從 iching-content `prompts/art-prompts.md` 搬入（圖已定案，`art.status` 填「已定案」）。每批完成後更新 iching-content README 進度。流程：clone iching-content（sparse：zh-Hant、prompts、tools）→ 寫 `zh-Hant/NN-slug.json`（不含 `art`）→ `python3 tools/finalize_hexagram.py NN` 自動填入提示詞並檢查結構 → 每完成一卦就 commit＋push。參考經文（簡體，僅比對用、不進 repo）：`curl -sL https://raw.githubusercontent.com/NanBox/PiPiName/master/data/%E5%91%A8%E6%98%93.txt`（容器網路無法連維基文庫）。比對時以 opencc（`pip install opencc-python-reimplemented`）簡轉繁、切出 `NN.md` 給 `REF_DIR`；轉換造成的假差異（于／於、干／幹、斗／鬥、征凶／徵兇、為／爲）可忽略。卦辭不以「卦名：」開頭者（履、同人、艮）腳本會報錯，需人工比對。整批完成後以 workflow_dispatch 觸發建置（只改 .md 不會自動建置）。經文與參考本不同處記在 iching-content README「待人工核對」。
4. **審閱期間並行的工作（2026-10-02 使用者同意，依序各開一個新對話）**：
   1. ✅ 2026-10-02 完成（0.1.0+8，見第 14 節）【程式】呼吸音景（§7 第 2 項）：音源採程式合成（不用錄音檔，免授權追蹤）；**已決定（2026-10-02）**：呼吸節奏固定「吸 4 秒、吐 6 秒」（每分鐘 6 次）；時長由使用者選 1／2／3／5 分鐘。音景依抽到的卦以上下經卦組合（§7 第 2 項；天、地兩種音景仍待定，開工時提案）。
   2. 【程式】✅ 字體打包 2026-10-03 完成（0.1.0+17，見第 15 節）。✅ Firebase（Analytics、Crashlytics、Remote Config）2026-10-03 完成（0.1.0+20，見第 18 節）：因帳號專案數已滿，**改加進智慧聽覺巡航的 Firebase 專案**（第二個 Android App `com.lclab.qiangua`），Secret `GOOGLE_SERVICES_JSON_BASE64` 由使用者建立，CI 每次檢查。✅ run #38（workflow_dispatch）驗證通過：Secret 可解碼、含 `com.lclab.qiangua`，Release 說明「Firebase：已啟用」。
   3. ✅ 2026-10-03 定稿（見第 17 節）【內容】11 語術語表：64 卦名、八經卦、爻位、易學術語的固定譯法，存 iching-content `glossary/`。使用者審閱無意見。⏳ **下一個程式工作**：App 端套用（改 `lib/l10n/terms.dart` 與 ARB，§16、§17）。
   4. ✅ 2026-10-03 完成（0.1.0+19，run #36，見第 16 節）【程式】介面翻譯：Flutter 多語系架構（ARB），全部介面文字移到 ARB，已有繁中＋英文介面；依 §12，英文內容完成前不開放。
5. 程式待辦（有空檔或回饋時）：術語表套用到 App（§17，排第一）；牌面細節；上架前：隱私權政策與 Play「資料安全性」表單要寫明 Firebase 收集項目（§18）。

## 11. 程式現況（2026-10-01 骨架完成）

### 11.1 目錄結構（依第 9 節架構原則）

| 路徑 | 內容 |
|---|---|
| `lib/main.dart`、`lib/app/` | 進入點、`IchingApp`、謙卦主題（`theme.dart`）、首頁、`services.dart`（以 InheritedWidget 提供共用服務，換實作只改 `Services.standard()`） |
| `lib/app/app_feature.dart`、`feature_registry.dart` | 首頁入口定義與**功能註冊表**；增減功能＝增減 `registeredFeatures` 一行 |
| `lib/core/iching/` | `trigram.dart`（八經卦）、`hexagram_table.dart`（文王卦序表、64 卦卦名／拼音／暫定英文卦義）、`cast_result.dart`（6/7/8/9、本卦、之卦、變爻）、`divination_method.dart`（**起卦策略**：`SimpleDraw`、`ThreeCoins`）、`focus_rule.dart`（**變爻規則策略**：`ZhuXiFocusRule`） |
| `lib/core/content/` | `ContentSource` 介面＋`AssetContentSource`（讀 `assets/content/zh-Hant/NN.json`、`assets/cards/NN.webp`）；`hexagram_content.dart` 寬鬆解析 JSON（缺欄位給空字串） |
| `lib/core/events/event_bus.dart` | 事件匯流排；目前只有 `ReadingShown`，尚無訂閱者（留給紀錄、統計） |
| `lib/features/draw/`、`lib/features/coin_cast/` | 兩個首頁功能，各自只對外公開一個 `AppFeature`；彼此不引用 |
| `lib/reading/` | 主流程共用頁：解讀頁（牌面→本次重點→隨機一組解讀→東西相映→小行動與提問）、詳細頁（經文與各爻，重點爻自動展開） |
| `lib/shared/widgets/` | 卦象（`HexagramGlyph`）、先天八卦環牌背、有框牌面（無圖時以卦象符號當佔位）、翻牌動畫（尊重系統「減少動態效果」） |
| `test/iching_test.dart` | 卦序表、起卦、朱熹規則的單元測試，CI 每次都跑 |
| `scripts/import_content.sh`、`patch_android.sh` | CI 用：匯入私人內容（只印數量）；設定桌面名稱、桌面圖示與簽署 |
| `branding/` | 桌面圖示：`draw_icon.py`（Pillow 繪製，改設計就改這支再重產）、`icon-1024.png`（上架用大圖）、`android/res/`（各密度 mipmap＋Android 8+ 自適應圖示，CI 複製進 `android/`）。設計（0.1.0+14 起）：**無框滿版**——玄底上直接畫謙卦 ䷎ 六爻，卦象高度約為可見範圍 62%（圓角方形、圓形桌面都不切到），九三陽爻用較亮的稻金。原本的金框卦卡版已停用 |

### 11.2 暫定設定
- **定名（2026-10-01）**：開發者 **LC Lab**；App 名 **謙卦**（英文 Qiangua）。桌面名稱「謙卦」；首頁大標「謙卦」、副標「易經六十四卦卡」；Google Play 標題預定「謙卦｜易經六十四卦卡」。2026-10-01 使用者已在 Google Play／App Store 搜尋，確認沒有名為「謙卦」的 App（商標可在上架前另查）。
- **套件名稱 `com.lclab.qiangua`**（0.1.0+5 起；上傳 Play 後永遠不能改）。由 `patch_android.sh` 改 applicationId；`flutter create --org com.lclab`，namespace 維持產生值。舊版 `tw.bcc.iching_cards` 是不同 App，測試機需手動移除。
- 版本 `0.1.0+20`（+20：Firebase，見第 18 節；+19：介面翻譯架構（ARB）、想問的事連結字體縮小，見第 16 節、15.2；+18：置中提示語去標點；+17：思源字體子集，見第 15 節；+16：首頁一屏顯示完；+15：鎖屏按鈕圖示保留、測試提醒鈕；+14：桌面圖示無框滿版；+13：鎖定畫面控制改用 audio_service、桌面圖示留白；+12：卦記縮圖、底部被導覽列擋住、音景設定面板；+11：卦記提醒準時模式；+10：音景柔和版、432Hz、雙耳節拍，見 14.2；+9：實機回饋修正、音景背景播放與通知控制，見 14.1；+8：呼吸音景，見第 14 節；+7：卦記與回顧提醒，見第 13 節；+3：首頁水平置中修正、桌面圖示；+4：固定直向；+5：定名謙卦、套件名稱 com.lclab.qiangua；+6：擲錢頁收斂在一個畫面、點牌面圖滿版看象）。
- **滿版看圖**（0.1.0+6，`shared/widgets/card_art_viewer.dart`）：`CardFace(zoomable: true)` 時點風景圖開啟；預設 cover 填滿螢幕、隱藏系統列，點兩下切換完整畫面（contain），兩指縮放，點一下返回。目前用於抽卡翻牌後與解讀頁。
- **擲錢頁版面**（0.1.0+6）：不再捲動；六爻列固定保留（未擲顯示「—」），中段以 FittedBox 等比縮小以適應小螢幕或大字體，按鈕固定在底部。
- **固定直向**：卦卡為 9:16 直式，`main.dart` 以 `SystemChrome` 鎖直向，Android 另由 `patch_android.sh` 在 AndroidManifest 加 `screenOrientation="portrait"`。iOS 上架時需在 Info.plist 只留 Portrait。平板若要支援橫向，再另做雙欄版面。
- 外部套件（0.1.0+7 起）：`path_provider`、`flutter_local_notifications` ^18、`timezone` ^0.9（版本同智慧聽覺巡航）；0.1.0+8 加 `just_audio` ^0.10.4（播放音景）、`wakelock_plus` ^1.2.8（練習時螢幕不關）；0.1.0+9 曾加 `just_audio_background`，0.1.0+13 改為直接用 `audio_service` ^0.18.15（見 14.4）。字體 0.1.0+17 起打包思源黑體／宋體子集（第 15 節）。
- 英文卦義為自撰暫定詞，英文版上線前再審。
- `android/`、`ios/` 不進 repo，CI 以 `flutter create` 產生（同英文 App 做法）；`flutter create` 會產生的 `test/widget_test.dart` 在 CI 中刪除。
- `assets/content/`、`assets/cards/` 在本 repo 只有 `.gitkeep`，`.gitignore` 擋住 json／webp，**內容永遠不進公開 repo**。

### 11.3 CI 流程（build_android.yml）
checkout 本 repo → 以 `BUILDS_REPO_TOKEN` sparse-checkout iching-content 的 `zh-Hant/` 與 `images/webp/`（不抓 raw 原圖）→ 匯入內容 → `flutter create` → 套用名稱與簽署 → `flutter analyze`（只有 error 會失敗）→ `flutter test` → `flutter build apk --release` → `gh release create iching-android-run<N>` 到 iching-content → 自動刪除舊建置 Release，**只保留最近 5 個**（依 run 編號排序；createdAt 會相同，不可用來排序）。
- 失敗時錯誤行會轉成 annotation，Claude 以 `GET /repos/lawrence124875/iching-cards/check-runs/<id>/annotations` 讀取（容器無法下載完整日誌）。
- APK 為通用版（含三種 CPU 架構），約 58 MB；上架時改建 AAB，由 Play 自動拆分。
- run #1（2026-10-01）全部步驟成功，以除錯金鑰簽署。

### 11.4 上傳金鑰（2026-10-01 已產生並設定完成）
- 新建、與智慧聽覺巡航分開：PKCS12、別名 `upload`、RSA 2048、有效至 2054 年。憑證 SHA-256 指紋開頭 `80:9A:C2:C1`。
- 檔案與密碼已交給使用者下載，由使用者備份到 Google 雲端硬碟；**Claude 與 repo 都不保留**。遺失＝上架後無法更新。
- 使用者需在 iching-cards 的 Settings → Secrets → Actions 建立：`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_PASSWORD`、`ANDROID_KEY_ALIAS`。
- ✅ 2026-10-01 使用者已建好 4 個 Secrets；run #3（0.1.0+2）起以上傳金鑰簽署，之後的 APK 可直接覆蓋安裝。
- 若 Secrets 遺失，CI 會自動改用除錯金鑰並在 annotation 警告；除錯金鑰每次建置不同，裝新版前須先移除舊版。設定後的 Release 說明會顯示「簽署：上傳金鑰」。

## 12. 多語言規劃（2026-10-02 討論）

- **方向：先求語言數量**（使用者決定），預定與智慧聽覺巡航同一組語言，共 11 語：繁中、英、簡中、日、韓、越、印尼、西、葡（巴西）、泰、阿拉伯。阿拉伯文與印尼文市場對占卜類內容較敏感，上架前再評估。
- **順序**：繁中 64 卦寫完並經使用者審閱定稿 → 英文（重新寫給英文讀者，非逐句翻譯）→ 其餘語言分批。中文未定稿前不開始翻譯。
- **術語表先行**：64 卦名、八經卦、爻位與易學術語（象、當位、應、比、內外卦等）在各語言的固定譯法，翻譯時強制套用，並以回譯抽查。
- **經文**：各語言一律保留漢字原文，附自行翻譯的譯文；可參考公有領域譯本（英：Legge 1882；德：Wilhelm 1924 德文原譯），不引用仍有版權的譯本（如 Wilhelm/Baynes 英譯）。
- **東西相映名句**：每種語言都從原著語言（拉丁、希臘、英、德等）直接翻譯，不經中文轉手；`translationNote` 註明。
- **簡中**：卦名與經文鎖定不做自動繁簡轉換（例：「乾」會被誤轉為「干」）。
- **上線原則**：內容沒有完整翻譯的語言不開放；介面翻譯可先做。

## 13. 卦記（2026-10-02 加入，0.1.0+7，run #15 建置成功）

使用者需求：抽完的卦可以存起來，註明當時問的事，日後回來對照實際發展，練習解象（事後回溯與學習）。

**已決定**
- 「想問的事」抽卦前、抽完都可以填：抽卦頁與擲錢頁有「寫下想問的事（可不填）」連結，帶進解讀頁；存檔時仍可修改。自由文字，不做問事分類（維持 §3 原則）。
- 解讀頁最下方「記下這一卦」→ 底部面板：想問的事＋回顧提醒（不提醒／3／7／14／30 天／自訂 1–365 天，預設 7 天），提醒時間固定為該日晚上 8 點。
- 每筆紀錄保存：時間、起卦方式、六爻數值（6–9，可還原本卦／之卦／變爻）、想問的事、**當時隨機顯示的解讀組別 `readingIndex`**（回看時顯示同一組）、提醒時間、多筆回顧（各自標日期）。
- 首頁次要入口「卦記」：由新到舊列表；單筆頁可修改問題、「看當時的解讀」（ReadingPage review 模式：不發事件、不顯示儲存）、新增／修改回顧（清空文字＝刪除該則）、改期或取消提醒、刪除紀錄。
- 點通知直接開啟該筆卦記（payload `journal:<id>`；App 關閉時由 launch details 處理）。
- 隱私：只存在手機（App 私有資料夾 `journal.json`，Android 自動備份可能涵蓋但不保證）；通知內文**不放想問的事**（鎖定畫面可見）；日後接 Firebase 時不得記錄問題或回顧文字。移除 App 會一併刪除，之後可加匯出／匯入備份。

**程式位置（依 §9 架構）**
- `lib/core/journal/`：`JournalEntry`（含 JSON、`schemaVersion` 1）、`JournalStore` 介面（`MemoryJournalStore` 測試用）、`FileJournalStore`（暫存檔再改名，避免毀損）、`JournalReminders`（回顧時間、通知文字、payload）。
- `lib/core/reminders/`：`ReminderService` 介面＋`LocalNotificationReminders`（UTC 時間點排程、`inexactAllowWhileIdle` 不需精確鬧鐘權限、所有呼叫不拋例外；排程時才請求通知權限）＋`NoopReminderService`。
- `lib/features/journal/`：功能入口（註冊表一行）、列表頁、單筆頁。拔除＝移出註冊表並把 `Services.journal` 設為 null（解讀頁自動不顯示「記下這一卦」）。
- `AppFeature.openPayload`：功能可處理通知帶來的 payload；`IchingApp` 以 navigatorKey 分派。
- `lib/reading/save_reading_sheet.dart`、`lib/shared/widgets/question_dialog.dart`、`reminder_picker.dart`、`lib/shared/format.dart`。
- `scripts/patch_android.sh`：加入 POST_NOTIFICATIONS／RECEIVE_BOOT_COMPLETED 權限、兩個通知 receiver（少了會排程成功卻永遠不跳）、core library desugaring；設定失敗會讓 CI 失敗。
- `test/journal_test.dart`：JSON 來回、跨月回顧時間、payload、儲存。
- iOS 上架時：需在 AppDelegate 設定通知代理（flutter_local_notifications 的 iOS 說明），其餘程式共用。

**準時模式（2026-10-02 使用者決定比照智慧聽覺巡航，0.1.0+11）**
- 使用者允許「鬧鐘與提醒」（精確鬧鐘）時用 `exactAllowWhileIdle` 準時跳出；不允許則退回 `inexactAllowWhileIdle`（省電時可能延後）。
- **第一次**設定提醒時開一次系統設定頁請使用者允許（`requestExactAlarmsPermission`，返回後才排程）；之後不再主動開，旗標檔 `exact_alarm_asked` 存在 App 私有資料夾。拒絕後可自行到手機設定 → 應用程式 → 謙卦 → 鬧鐘與提醒 開啟。
- Manifest 加 `SCHEDULE_EXACT_ALARM`（使用者可自行授予的權限；不用受 Play 嚴格審查的 `USE_EXACT_ALARM`）。Android 14 起新安裝預設不允許，所以需要上述引導。
- 已排好的提醒不會自動改成準時，之後新設定或改期的才會。

**待使用者實機回饋**：通知實際跳出時間（各廠牌省電機制可能延遲）、版面與文字。

## 14. 呼吸音景（2026-10-02 加入，0.1.0+8）

**已決定**（§7 第 2 項、§10.6 第 4 項）
- 音源全部**程式合成**，不用錄音檔（免授權追蹤）。呼吸節奏固定**吸 4 秒、吐 6 秒**（每分鐘 6 次）；時長由使用者選 1／2／3／5 分鐘。
- 入口：解讀頁「以此卦靜心呼吸」（卦記回看時也有）→ 設定面板（時長、換氣鈴聲開關）→ 練習頁。不放首頁（音景依抽到的卦決定）。
- 音景＝本卦上卦＋下卦兩種經卦音景疊加（八純卦只用一種）。之卦不參與。

**八經卦音景**（天、地為本次提案，**暫定**，使用者試聽後可改）

| 經卦 | 音景 | 合成方式 |
|---|---|---|
| 乾・天 | 高空清風（暫定） | 高頻、緩慢游移的輕風＋G2 自然泛音（1、1.5、2、3、4 倍）緩慢起伏的長鳴，取「天行健」的清朗開闊 |
| 坤・地 | 夜野蟲鳴（暫定） | 大地低沉嗡鳴（低通布朗雜訊）＋三隻遠近不同的蟋蟀，取「厚德載物」的沉靜與夜之陰 |
| 震・雷 | 遠雷春雨 | 粉紅雜訊雨聲＋雨滴＋每 9–16 秒一次低沉遠雷 |
| 巽・風 | 林間風聲 | 中心頻率游移的帶通雜訊陣風＋隨陣風起落的樹葉沙沙聲 |
| 坎・水 | 山澗流水 | 快速變化的帶通雜訊＋細小上升的氣泡音 |
| 離・火 | 營火 | 低沉火焰聲＋成串劈啪聲與偶爾木柴爆裂 |
| 艮・山 | 山林寂靜 | 極輕的山間空氣聲＋偶爾遠處鳥鳴（刻意最安靜） |
| 兌・澤 | 湖畔水波 | 5–7 秒一波的低頻水聲起伏，波峰時輕拍岸邊 |

**聲音設計**
- 每種經卦音景先合成一段可無縫循環的片段（上卦 31 秒、下卦 37 秒，互質不易聽出重複；尾端 3 秒等功率交叉淡化接回開頭），再鋪滿整段練習。亂數有固定種子，同一卦每次聽到相同的聲音。
- 整段時間軸：準備 3 秒（淡入）→ 呼吸 N 分鐘 → 收尾 5 秒（淡出、結束鈴）。音景音量隨呼吸起伏（吐到底約 −4.4 dB），吸氣開始輕敲高音鈴（C5）、吐氣開始低音鈴（G4），可開關（0.1.0+9 起預設關閉）。
- 輸出 22,050 Hz、16-bit 單聲道 WAV，在背景 isolate 合成（不卡畫面），存手機暫存資料夾；同一組設定直接沿用，換設定時刪掉舊檔只留一個（5 分鐘約 13 MB）。合成方式改版時把 `SessionSpec.key` 的 `v1` 往上加，舊快取自動失效。
- 練習頁的呼吸圓、吸／吐字樣、倒數，**一律取自音檔播放位置**，畫面與聲音不會漂移；音檔無法播放時可改用「無聲引導」（以碼錶計時）。練習中保持螢幕亮著，可暫停／繼續／結束。
- 調整某種音景＝改 `synth_bed_source.dart` 裡該經卦的一個函式；各音層以均方根（連續聲）或峰值（雷、鳥、劈啪等稀疏聲）校準到絕對音量。

**程式位置（依 §9 架構）**
- `lib/core/soundscape/`：`dsp.dart`（亂數、粉紅／布朗雜訊、雙二階濾波器、平滑隨機 LFO）、`bed_source.dart`（**音景來源策略**介面）、`synth_bed_source.dart`（八經卦合成實作）、`breath_timeline.dart`（呼吸節奏、時間軸、音量曲線、鈴聲時間）、`session_renderer.dart`（組成整段 WAV）、`soundscape_files.dart`（背景合成與快取）。日後要改用錄音檔，只需新增一個 `BedSource` 實作。
- `lib/core/audio/`：`AudioPlayback` 介面＋`JustAudioPlayback`；`ScreenAwake` 介面＋`WakelockScreenAwake`（iOS 只需確認套件設定）。
- `lib/features/breath/`：功能入口（`placement: none`＋`readingAction`）、設定面板、練習頁、音景名稱。拔除＝移出註冊表一行。
- `AppFeature` 新增 `readingAction`（解讀頁底部的功能入口）與 `FeaturePlacement.none`；`builder` 改為可省略。
- `Services.breath`（`BreathServices`：檔案、播放器、螢幕常亮）。
- `test/soundscape_test.dart`：節奏與時間軸、音量曲線連續、鈴聲數量、八種音景數值與音量範圍、可重現、循環接縫、WAV 格式。

**待使用者實機回饋**：各音景好不好聽（特別是天、地兩個提案）、音量平衡、鈴聲大小、第一次合成等待時間（5 分鐘的音檔最久）。

### 14.1 0.1.0+9 實機回饋修正（2026-10-02）

- **起卦頁標題**：抽一卦、三枚銅錢起卦兩頁上方不再顯示標題（首頁按鈕已寫），只留返回鍵。
- **想問的事**：翻牌後（擲錢則是擲完六次後）不能再寫；已填的問題仍顯示。存進卦記時照舊可改。
- **滿版看圖**：下方提示只留「點一下返回」（點兩下切換完整畫面仍可用，不另提示）。
- **記下這一卦**：面板改為可捲動，鍵盤升起時「儲存」不會被擋住；點空白處收起鍵盤，鍵盤右下角為「完成」。App 內所有輸入框點外面都會收起鍵盤（`onTapOutside`）。
- **卦記提醒設定失敗**：原因判斷為 release 版 R8 壓縮砍掉 Gson 泛型資訊，`zonedSchedule` 拋例外（智慧聽覺巡航早已加同樣規則）。`patch_android.sh` 加入 flutter_local_notifications／Gson 的 ProGuard 規則。另外：已允許通知就不再跳權限對話框；啟動時初始化失敗會在排程時重試；失敗時提示會帶上原因（未允許通知，或錯誤訊息），方便回報。⚠️ 待使用者實機確認是否修好；若仍失敗，請把提示裡的原因文字傳回來。
- **通知小圖示**：新增單色謙卦卦象 `ic_stat_qian`（`branding/android/res/drawable-*`，`raw/keep.xml` 防止被資源壓縮移除），卦記提醒與音景播放通知共用。
- **呼吸音景**：
  - 換氣鈴聲預設**關閉**。
  - 練習頁下方改為三個細金線圓形按鈕：看圖／暫停・繼續（較大）／結束，各附小字。
  - 「看圖」開啟此卦滿版牌面圖，音景持續播放，畫面下方疊一個小呼吸圓（吸／吐），點一下返回練習頁。完成後也可「再看一次卦圖」。
  - **背景播放**：離開 App 或關閉螢幕仍繼續播放；通知列與鎖定畫面顯示「卦名・呼吸音景」、音景名稱與時長、牌面圖，可暫停／播放，畫面同步。播完或離開練習頁即停止並移除通知。
  - 實作：`AudioPlayback` 改為全 App 單一播放器（`Services.breath.playback`，套件只支援單一播放器），新增 `stop()`、`playingChanges`、`completed`；`main.dart` 先 `JustAudioPlayback.initBackground()`（失敗只是沒有通知控制）。`ContentSource.cardArtBytes()` 提供鎖定畫面用的圖（寫到暫存 `art_NN.webp`）。
  - Android 設定（`patch_android.sh`）：前景服務權限、`AudioService` 與 `MediaButtonReceiver`、MainActivity 改繼承 `AudioServiceActivity`、`launchMode=singleTask`（AudioServiceActivity 共用引擎，點通知若另建第二個 Activity 畫面會卡住，智慧聽覺巡航 2026-09-29 的教訓）。
  - iOS 上架時：Info.plist 加 `UIBackgroundModes` → `audio`。

### 14.2 0.1.0+10 柔和版、432Hz 調音、雙耳節拍（2026-10-02）

使用者回饋：以卦生成的音景不錯，希望更柔和放鬆；詢問 528Hz／432Hz／7.83Hz。討論後**選定 432Hz**（兩套調音並存會互相衝突，只取一個基準）。

- **研究現況（與使用者確認過的說法）**：528Hz「修復 DNA」、432Hz「與宇宙共振」之類說法沒有可靠研究支持，只當美感上的調音選擇；7.83Hz（舒曼共振）低於人耳可聽範圍，只能以雙耳節拍呈現，需戴耳機，相關研究結果不一；證據最紮實的是每分鐘 6 次的慢呼吸本身（HRV）。
- **⚠️ 文案原則（Google Play 健康宣稱政策）**：App 與商店頁只可描述做法（「以 432Hz 調音」「雙耳節拍 7.83Hz（需耳機）」），**不可寫任何療效**（修復、療癒 DNA、降低焦慮、提升腦波等）。
- **柔和化**：各音景削弱高頻（雨改為帶通 400–2500Hz、樹葉與劈啪改為帶通、風的中心頻率降低）；突發聲壓低並放緩（雷聲峰值 0.4→0.25、起音 1–2 秒、間隔 12–20 秒；劈啪峰值 0.45→0.2、頻率減半；拍岸 0.22→0.12 並緩起；鳥鳴更少更輕）；陣風、水流變化放慢；最後整體再過 5kHz 低通；呼吸起伏深度 0.4→0.35。
- **432Hz 調音**：天的泛音長鳴基頻 98Hz→108Hz（432÷4，泛音含 216、324、432Hz）；鈴聲吸氣 432Hz、吐氣與結束 324Hz（純四度），起音放緩、餘音拉長、音量降低。
- **雙耳節拍**：設定面板新增開關「雙耳節拍 7.83Hz」（預設關閉）。開啟時輸出立體聲：左耳 216Hz、右耳 223.83Hz 的輕柔正弦，只隨準備淡入、結束淡出，不跟呼吸起伏。立體聲檔案大一倍（5 分鐘約 27 MB）。
- 快取鍵改為 `v2`，舊版音檔自動重新生成。

### 14.3 0.1.0+12 版面修正（2026-10-02 實機截圖回饋，Redmi 三鍵導覽列）

- **卦記單筆頁**：110 寬的牌面縮圖原本直接排版，字擠成一團（英文換行、上下經卦壓到「想問的事」）。改為以 240 寬原尺寸排版後 `FittedBox` 等比縮小。「當時的解讀」改成小標＋下一行標題，不再斷成「宜日／中」。
- **底部被系統導覽列擋住**：App 是 edge-to-edge（看圖頁離開時設 `SystemUiMode.edgeToEdge`），清單底部要自己讓出導覽列。解讀頁、經文詳細頁、卦記列表、卦記單筆頁的 ListView 底部 padding 加上 `MediaQuery.viewPaddingOf(context).bottom`；「記下這一卦」面板同樣處理。⚠️ 之後新增可捲動頁面或底部面板都要照做。
- **呼吸音景設定面板**：內容超過螢幕高度時「開始」被截掉。改為可捲動並讓出導覽列；兩個開關改 dense、雙耳節拍說明縮短。

### 14.4 0.1.0+13 鎖定畫面控制、桌面圖示（2026-10-02 實機截圖回饋）

- **鎖定畫面與通知列沒有暫停、停止鍵**（Redmi／MIUI）：just_audio_background 只送出預設按鈕，MIUI 媒體卡片只顯示進度條。改為直接用 audio_service：`lib/core/audio/breath_audio_handler.dart`（`BreathAudioHandler`）包住 just_audio 播放器，明確指定按鈕「暫停／播放、停止」並設為精簡按鈕（`androidCompactActionIndices [0, 1]`），播放狀態隨播放器事件同步；`mediaItem` 帶 duration 顯示進度。
  - 通知或鎖定畫面按「停止」→ `AudioPlayback.stoppedExternally` → 練習頁顯示「已結束・已從通知列停止」。App 自己停止（播完、離開頁面）走 `stopFromApp()`，不觸發此事件。
  - 從最近使用列表滑掉 App → `onTaskRemoved` 停止並收掉卡片（智慧聽覺巡航的教訓）。
  - `main.dart` 的 `JustAudioPlayback.initBackground()` 改為 `AudioService.init`（5 秒逾時；失敗退回一般播放器，只是沒有通知控制）。Android 設定沿用 14.1（AudioService、AudioServiceActivity、singleTask），不必改。
- **桌面圖示比 icon-1024.png 擁擠**：自適應圖示的可見範圍約為前景畫布 66.7%，原本卦卡高度為畫布 60%，在桌面上佔滿可見高度約 89%。`draw_icon.py` 改為 52%（約 78%，與 icon-1024.png 比例相同），重新產生各密度 `ic_launcher_foreground.png`；傳統圖示外觀不變。MIUI 可能快取舊圖示，若沒變可重新開機或移除重裝。
- **0.1.0+14 再改：無框滿版**（使用者看預覽圖後選 A 版：卦象約佔可見範圍 62%；B 版 72% 在圓形桌面會切到四角，未採用）。之後又預覽「A＋細金邊」（圓角方形邊在圓形桌面會被切斷；圓形邊在方形桌面四角留白），使用者確認**維持 A 原樣、不加金邊**。`draw_icon.py` 改寫為一次產生各密度前景、傳統圖示與 `icon-1024.png`。

### 14.6 0.1.0+15 鎖屏與通知中心沒有暫停／停止鍵的真正原因（2026-10-02）

- 使用者確認：智慧聽覺巡航在同一支小米手機上**也一樣沒有按鈕**，所以不是按鈕組合（+13 的推測不成立）。
- 下載 run #30 的 APK 檢查資源表：裡面**完全沒有** audio_service 的 `audio_service_pause／play_arrow／stop` 等按鈕圖示。audio_service 是用名稱字串查這些圖示，release 版資源壓縮（shrinkResources）判斷沒人用就刪掉，按鈕圖示變成 0，小米卡片就整排不顯示。
- 修法：`branding/android/res/raw/keep.xml` 的 `tools:keep` 加上 `@drawable/audio_service_*`。
- ⚠️ **智慧聽覺巡航要做同樣修正**（它的 raw/keep.xml 或 res/raw 加 `tools:keep="@drawable/audio_service_*"`），需在英文 App 對話處理（本對話的權杖只能寫 iching-cards）。
- ✅ 2026-10-02 使用者實機確認（小米）：鎖屏與通知中心已出現暫停、停止鍵；測試提醒準時跳出，桌面圖示右上角也出現數字角標。卦記提醒問題（ProGuard＋準時模式）結案。
- 卦記單筆頁「回顧提醒」下方新增暫時按鈕「測試：1 分鐘後提醒」，用來實機驗證提醒與桌面圖示角標。⚠️ **上架前移除**（程式中標 `TODO(上架前移除)`）。

### 14.7 0.1.0+16 首頁一屏顯示完（2026-10-02）

- 使用者回報：小米上首頁要往下滑才看得到「內容僅供自我探索與娛樂參考」（非刻意設計，是內容高度超過螢幕）。
- 修法：首頁不再捲動。主內容（牌背、標題、按鈕）放進 `FittedBox(scaleDown)`，螢幕矮或系統字體放大時等比縮小；免責聲明移出主內容，固定貼在畫面底部，字級 13→11、顏色略淡。

## 15. 字體打包（2026-10-03，0.1.0+17）

- 字型：Google Fonts 的 Noto Sans TC（思源黑體）、Noto Serif TC（思源宋體）可變字型，SIL OFL 1.1，可商用、可隨 App 散布。CI 從 google/fonts 固定 commit `9710da1e` 下載（`actions/cache` 快取），更新字型＝改 workflow 的 `NOTO_COMMIT` 與 cache key。
- **子集**：`scripts/build_fonts.py` 在 CI 匯入內容之後執行，只留 Big5 常用字（5,401 字，給使用者輸入的「想問的事」與回顧）＋內容 JSON 與 `lib/` 實際用到的字＋英數標點，約 6,200 字。完整字型 12–17 MB，子集後黑體每個字重約 2.0 MB、宋體約 2.8 MB。子集外的罕用字由系統字體自動補上（不會變方框）。Actions 紀錄只印字數與檔案大小，不印字元。
- 字重：黑體 400、500（Material 按鈕與小標用 500）；宋體 400。程式目前沒有指定粗體；日後要用，在 `build_fonts.py` 的 `WEIGHTS` 加 700 並同步改 `pubspec.yaml`。
- 字型檔不進 repo（`.gitignore` 擋 `assets/fonts/*.ttf`），只有授權全文 `assets/licenses/*-OFL.txt` 進 repo，並在 `main.dart` 以 `LicenseRegistry` 登記（OFL 要求附授權）。
- `theme.dart`：`kSans = 'NotoSansTC'` 為全 App 預設字族；`kSerif = 'NotoSerifTC'` 用於卦名、經文、標題。
- ⚠️ **多語言時**：日、韓、泰、阿拉伯文等不在這兩個字型內，需要時再加對應的 Noto 字型（同樣子集化），或交給系統字體。簡中可另加 Noto Sans SC／Serif SC。
- ✅ 2026-10-03 使用者實機確認 run #33 字體沒問題，首頁仍一屏顯示完。

### 15.1 置中提示語的寫法（2026-10-03 使用者決定，0.1.0+18）

- 畫面中央的短提示語（首頁標語、抽卦頁「心裡想著眼前的一件事／準備好了就點牌」「這是此刻的象」、卦記空白頁）**不加逗號、句號**，原本逗號的地方直接換行。
- ⚠️ 之後新增的置中提示語照此寫；解讀內文、說明段落、對話框與提示訊息維持一般標點。

### 15.2 「寫下想問的事」連結字體（2026-10-03 run #34 實機回饋，0.1.0+19）

- 回饋：抽卦頁、擲錢頁的「寫下想問的事（可不填）」字體與該頁不一致、太大。原因：它是按鈕字（labelLarge：16、字重 500、字距 2），比上方提示語（15.5、字重 400）還大。
- 修法（`shared/widgets/question_dialog.dart` 的 `QuestionPrompt`）：改用與提示語同一套黑體一般字重，13.5、字距 0.5、灰穗色，圖示 20→17；填了問題後顯示的「問：……」同樣 13.5（淡金色）。⏳ 待使用者實機確認。

## 16. 介面翻譯（ARB，2026-10-03，0.1.0+19）

做法與智慧聽覺巡航相同（同一套 CI 驗證過）：`flutter_localizations`＋`intl`，`pubspec.yaml` 的 `generate: true`，設定在 `l10n.yaml`。

**檔案**
- `lib/l10n/app_zh.arb`：**範本**（繁中，含每個鍵的說明與參數型別）；`app_en.arb`：英文。共 146 個鍵。
  - `app_zh.arb` 的語言代碼是 `zh`（基底），App 實際以 `zh_Hant` 使用（Material 內建文字才會是繁體）。日後簡中＝新增 `app_zh_Hans.arb`。
- 產生的 `lib/l10n/app_localizations*.dart` **不進 repo**（.gitignore），CI 的 `flutter pub get` 自動產生。
- `lib/l10n/app_languages.dart`：**語言登記表** `AppLanguages.all`（目前 `zhHant`、`en`），每個語言有 `contentFolder`（iching-content 的資料夾）與 `contentReady`。
- `lib/l10n/l10n.dart`：畫面裡用 `context.l10n.xxx`；沒有 context 的地方（通知類別名稱、回顧通知、鎖定畫面卡片）用 `L10n.current.xxx`，兩者同一語言（MaterialApp 決定語言時同步更新 `L10n.language`）。
- `lib/l10n/terms.dart`（`IchingTerms` 擴充）：core 層只回傳代碼，這裡轉成文字——卦名（`hexName`／`hexFullName`）、經卦名與象、音景名稱、爻位、6/7/8/9 名稱、變爻規則說明（`FocusCase`）、呼吸階段、提醒失敗原因（`ReminderFailure`）、回顧通知（`reviewMessage`）、牌面卦序（`cardNumber`：第十五卦／No. 15）、`hour12`。

**原則**
- **上線原則（§12）**：只有 `contentReady: true` 的語言會開放（`AppLanguages.enabled`）。英文介面已完成，但英文內容未寫，所以目前 `en.contentReady = false`，使用者看不到英文。英文內容完成、CI 匯入 `en/` 後改成 true。
- 語言判斷（`AppLanguages.resolve`）：依手機語言偏好順序；中文標示簡體或地區為中國／新加坡／馬來西亞時優先簡中，簡中未開放就用繁中（比英文好）；其他對不上的語言用英文（若已開放），否則繁中。
- core 不放介面文字：`FocusResult.reason`（enum）、`ReminderService.lastFailure`、`JournalReminders.apply(..., message)`、`LocalNotificationReminders(channelName:, channelDescription:)`、`JustAudioPlayback.initBackground(channelName:, album:)`。`Trigram.label/nature`、`HexagramInfo.name/fullName` 仍是漢字原始資料，介面一律經過 `IchingTerms`。
- **牌面中央大字卦名各語言都保留漢字**（牌面設計）；卦序、上下經卦依介面語言。非中文介面的卦名暫用拼音＋暫定英文卦義，⚠️ **11 語術語表完成後只需改 `terms.dart`**（並同步改 ARB 裡經卦名、爻位、6/7/8/9 的 select）。
- 置中提示語在各語言同樣不加句點（§15.1）。
- 字體子集：`build_fonts.py` 已加入 `lib/**/*.arb`。日、韓、泰、阿拉伯文仍需另加字型（§15）。
- 順帶修正：卦記提醒原本顯示「晚上 20 點」，改為「晚上 8 點」（`hour12`）。

**新增介面文字的做法**
1. `app_zh.arb` 加鍵（有參數要寫 `@鍵` 的 placeholders 型別），**所有其他 ARB 也要加同一個鍵**——`test/l10n_test.dart` 會檢查每個 ARB 的鍵、參數一致，缺一個 CI 就失敗。
2. 畫面裡 `context.l10n.新鍵`；不要再寫中文字串常數（core 的易學原始資料除外）。
3. select 用到的新情況，`l10n_test` 會檢查每個語言都有翻譯（不會落到 `other`）。

**新增語言**：新增 `app_xx.arb`（複製 app_en.arb 翻譯）→ `AppLanguages.all` 加一行（`contentReady: false`）→ 內容寫完、`build_android.yml` 的 sparse-checkout 與 `pubspec.yaml` assets 加該語言資料夾 → 改 `contentReady: true`。

**測試版：看英文介面**
- `workflow_dispatch` 新增輸入 `force_lang`：手動建置時填 `en`，該 APK 不論手機語言一律英文介面（內容仍為繁中），Release 標題註明「測試：介面 en」、檔名帶 `_ui-en`。留空＝正式版。程式中對應 `--dart-define=FORCE_LANG=en`。
- 注意：測試版與正式版是同一個套件名稱，會互相覆蓋安裝（卦記資料保留）。

## 17. 11 語術語表（2026-10-03 初稿）

- 位置：私人 repo iching-content `glossary/glossary.json`（唯一來源）、說明 `glossary/README.md`、審閱表 `review/謙卦_術語表審閱.xlsx`；工具 `tools/glossary.py check|xlsx`（檢查 11 語齊全、卦序、簡中不得出現「干」、意譯卦名不重複）。
- 內容：64 卦（`name` 內文稱呼、`title` 標題、`meaning` 卦義）、八經卦（名、象、卦德）、爻位（12 個爻名＋用九用六）、58 個術語（含 App 區塊名，英文與 ARB 一致）。
- 卦名原則：中、日、韓、越用各自漢字讀法（日新字體附讀音；韓附漢字、純卦用「重」；越用漢越音、純卦用 Thuần）；英、印尼、西、葡、泰、阿用意譯＋帶聲調拼音（例 `Modesty (Qiān)`）。牌面大字一律漢字。
- 英文卦義相對 `hexagram_table.dart` 暫定詞改 5 個：1 Creative Force、2 Receptivity、47 Confinement、51 Shock、57 Gentle Penetration（避免與經卦象同名）。
- ✅ **2026-10-03 使用者審閱完畢，無修改意見 → 定稿**（iching-content 兩份 README 已標註）。泰、阿仍需母語者校閱，在開放該語言前處理。
- ⏳ App 端（下一個程式對話）：`terms.dart` 的 `hexName`／`hexFullName` 改依術語表（可在 CI 匯入 `glossary.json` 或產生 Dart 常數）、ARB 經卦名與 `lineName` select 對照修改；目前 ARB 的 `lineName` 用「Line 1…」（介面爻位），與術語表的傳統爻名（Nine at the beginning）是兩回事，詳細頁標題要用哪個待定。

## 18. Firebase（2026-10-03，0.1.0+20）

### 18.1 決定：與智慧聽覺巡航共用同一個 Firebase 專案
- 原計畫新開專案，但使用者的 Google 帳號 Firebase 專案數已滿 → **改加進智慧聽覺巡航的 Firebase 專案**，成為同專案第二個 Android App，套件 `com.lclab.qiangua`（英文 App 是 `tw.bcc.englishapp`）。
- 共用造成的規則（**永久**，兩個 App 都要遵守）：
  1. **Remote Config 參數一律 `qg_` 開頭**（Qiangua）。Remote Config 範本是整個專案共用的，兩個 App 抓到的是同一份參數清單；前綴避免撞名。英文 App 日後新增參數**不可用 `qg_` 開頭**。
  2. **Remote Config 的值只設在「App 條件」下**：在主控台 Remote Config → 條件，建立條件「謙卦 Android」＝ 應用程式 (App) ＝ `com.lclab.qiangua`。`qg_` 參數的「預設值」選「使用應用程式內的預設值」，只在「謙卦 Android」條件下填值。這樣英文 App 永遠拿不到有意義的值，也不會被誤關功能。
  3. **Analytics 事件也一律 `qg_` 開頭**（本對話自行決定的延伸）。兩個 App 共用同一個 GA4 資源，主控台可依「應用程式」篩選，前綴讓報表與自訂維度不會混在一起。
  4. **Crashlytics** 依 App 分開顯示，不需特別處理。
  5. `google-services.json` 內含**兩個 App** 的設定；Gradle 外掛依 applicationId 自動挑 `com.lclab.qiangua` 那一筆。英文 App 的 Secret 是另一份（`FIREBASE_GOOGLE_SERVICES_JSON`，純文字），兩者互不影響；新下載的 json 也含英文 App，英文 App 不必更新。
  6. 免費方案的配額（Analytics、Crashlytics、Remote Config 都無上限或很寬）兩個 App 共用，目前不構成問題。
  7. **Firestore 安全規則整個專案只有一份**（2026-10-03 英文 App 對話通知）：英文 App 用 `feedback` 集合，規則為 create-only（只能新增，不能讀、改、刪）。謙卦目前**沒有用 Firestore**；日後若要用：
     - 集合名稱一律 `qg_` 開頭（例如 `qg_feedback`），不可用 `feedback`。
     - 發布規則時必須**合併**，保留英文 App 的 `feedback` create 規則，**不可整份覆蓋**，否則英文 App 的意見回饋會失敗。
     - 發布前先把**完整規則內容**給使用者確認。
  8. **不可刪除專案中的英文 App，也不改動它的任何 Firebase 設定**（App 設定、SHA 指紋、Remote Config 參數、Firestore 的 `feedback` 規則）。
  9. 查看 Crashlytics、Analytics 時先在主控台上方**篩選 App**（謙卦＝`com.lclab.qiangua`），以免看到英文 App 的資料。
  10. 換 Secret 時，新下載的 google-services.json 會含兩個 client（`tw.bcc.englishapp`、`com.lclab.qiangua`）：`patch_firebase.sh` 會檢查含 `com.lclab.qiangua`，google-services 外掛再依 applicationId（`patch_android.sh` 設為 `com.lclab.qiangua`）自動選用謙卦那一筆，不會誤用英文 App 的設定（2026-10-03 已確認）。
- Secret：iching-cards 的 `GOOGLE_SERVICES_JSON_BASE64`（google-services.json 整檔 base64，不進 repo；`.gitignore` 也擋 `google-services.json`）。更新方式：Firebase 主控台 → 專案設定 → 謙卦 App → 下載 google-services.json → PowerShell `[Convert]::ToBase64String([IO.File]::ReadAllBytes("google-services.json")) | Set-Clipboard` → 貼到 Secret。

### 18.2 CI（`scripts/patch_firebase.sh`，在 patch_android.sh 之後）
- 解 base64（先去除空白換行）→ 驗證是 JSON → **只印出 json 內的套件名稱** → 沒有 `com.lclab.qiangua` 就讓 CI 失敗（`::error::` 說明怎麼修）。
- 加 Gradle 外掛：`com.google.gms.google-services` 4.4.2、`com.google.firebase.crashlytics` 3.0.2（版本同英文 App）；ProGuard 加 Firebase keep 規則（缺了 release 版 `Firebase.initializeApp` 會失敗，英文 App 的教訓）。
- Secret 沒設：只發 warning，照樣建置（App 內 Firebase 初始化失敗→自動停用）。Release 說明會顯示「Firebase：已啟用／未啟用」。

### 18.3 程式（依 §9：Firebase 只出現在一個檔案）
- `lib/core/telemetry/`：介面 `Analytics`（`NoopAnalytics`）、`RemoteFlags`（`DefaultRemoteFlags`＝全開；`featureFlagKey(id)` → `qg_feature_<id>`）、`AnalyticsListener`（事件匯流排的旁觀者，事件→統計事件；`describe()` 可單獨測試）。
- `lib/core/firebase/firebase_telemetry.dart`：**唯一 import Firebase 的檔案**。`FirebaseTelemetry.init(featureIds:)`：`Firebase.initializeApp`（8 秒逾時）→ Crashlytics（release 才收集；接 `FlutterError.onError` 與 `PlatformDispatcher.onError`）→ Remote Config。任何失敗都退回 Noop／預設值，不影響啟動。拔除 Firebase＝`main.dart` 不呼叫它並移除套件。
- `main.dart`：最先初始化 Firebase（才接得到啟動中的當機）→ `Services.standard(analytics:, flags:)` → `AnalyticsListener`。
- 套件：`firebase_core` ^3.6.0、`firebase_analytics` ^11.3.3、`firebase_crashlytics` ^4.1.3（同英文 App）、`firebase_remote_config` ^5.1.3。皆支援 iOS；做 iOS 時需 `GoogleService-Info.plist`（同專案再加 iOS App）。
- 測試：`test/telemetry_test.dart`（事件名稱合規且 `qg_` 開頭、參數只有字串／數字、事件轉送、開關名稱與過濾）。

**統計事件**（只有代碼與數字；⚠️ **絕不送「想問的事」、回顧或任何使用者輸入的文字**，§13）

| 事件 | 參數 | 觸發處 |
|---|---|---|
| `qg_reading_shown` | method（`simple`／`coins` 等起卦方式 id）、hexagram（本卦 1–64）、has_changed（0/1） | 解讀頁（卦記回看不算） |
| `qg_journal_saved` | has_reminder（0/1） | 解讀頁存卦記 |
| `qg_breath_started` | hexagram、minutes、silent（無聲引導 0/1）、binaural（0/1） | 呼吸練習開始 |
| `qg_breath_completed` | hexagram、minutes | 呼吸練習完整做完（從通知停止不算） |

新增統計：在 `event_bus.dart` 加事件類別、功能裡 `emit`、`AnalyticsListener.describe` 加一行、測試會自動檢查名稱。

**Remote Config 參數**（App 內預設全部 `true`；主控台不設就照預設）

| 參數 | 型別 | 作用 |
|---|---|---|
| `qg_feature_draw` | 布林 | 首頁「抽一卦」 |
| `qg_feature_coin_cast` | 布林 | 首頁「三枚銅錢起卦」 |
| `qg_feature_journal` | 布林 | 首頁「卦記」與解讀頁「記下這一卦」（已存的卦記提醒通知仍可開啟） |
| `qg_feature_breath` | 布林 | 解讀頁「以此卦靜心呼吸」 |

- 讀法：**下次啟動生效**——啟動時套用上次抓到的值，背景再抓新值（12 小時一次）。改了主控台的值，使用者通常要重開 App 一到兩次才看到。
- 參數名稱由功能 id 自動產生（`registeredFeatures` 的 `id`），新功能自動有開關。日後付費內容、A/B 測試的參數同樣 `qg_` 開頭並設在 App 條件下。

### 18.4 待辦
- ✅ **2026-10-03 run #38 解決**：使用者重設 Secret 後手動重建，CI 檢查通過，APK 已含 Firebase（Release 說明「Firebase：已啟用」）。以下為 run #37 當時的紀錄：run #37 Secret 讀不到。程式與 CI 都已通過（analyze、test、release 建置成功，沒有 Firebase 也能正常執行），但 workflow 收到的 `GOOGLE_SERVICES_JSON_BASE64` 是空的，所以這個 APK 不含 Firebase。請使用者到 iching-cards → Settings → Secrets and variables → **Actions** → 「Repository secrets」確認：名稱完全是 `GOOGLE_SERVICES_JSON_BASE64`、建在 iching-cards（不是 english-learning-app）、不是放在 Environment／Dependabot／Codespaces 分頁。改好後到 Actions → Build Android APK → Run workflow 手動重建；Release 說明應顯示「Firebase：已啟用」，若內容不對，CI 會以 annotation 說明（例如沒有 `com.lclab.qiangua`）。容器權杖無法列出 Secret 名稱（403），只能由建置結果判斷。
- ⏳ 使用者實機確認：Firebase 主控台 → Analytics → **DebugView** 或「即時」報表（選謙卦 App）看得到 `qg_reading_shown` 等事件（一般報表要等 24 小時）；Crashlytics 頁面在第一次啟動回報後會從「等待中」變成正常。
- 上架前：隱私權政策（GitHub Pages）與 Play「資料安全性」表單要寫明 Analytics（應用程式互動、裝置 ID）、Crashlytics（當機紀錄、診斷資料）；Firebase Analytics 會自動加入廣告 ID 權限（`AD_ID`），Play 的「廣告 ID」聲明要勾選（日後接 AdMob 也需要）。
- 是否加「不分享使用統計」的開關：上架前與商業模式一起討論。

## 8. 範例內容：謙卦（第十五卦，地山謙 ䷎，Qiān · Modesty）

### 共用原文

> 謙：亨，君子有終。
> 《彖》曰：謙，亨，天道下濟而光明，地道卑而上行。天道虧盈而益謙，地道變盈而流謙，鬼神害盈而福謙，人道惡盈而好謙。謙尊而光，卑而不可踰，君子之終也。
> 《象》曰：地中有山，謙。君子以裒多益寡，稱物平施。

### 第一組：山藏地中

- **象的畫面**：高山沒有聳立在地面上，而是整座藏進了大地裡。地面看起來平坦尋常，底下卻蘊藏著一座山的厚重。
- **象從哪裡來**：上卦坤為地，下卦艮為山。山本來應該高過大地，這一卦卻讓山處在地的下方。高的甘願居於低處，這就是謙最根本的象。
- **給現在的你**：真正有份量的東西，不需要時時展示出來。你的能力和累積，就算別人暫時看不見，也不會因此減少半分。今天不必急著證明什麼，讓事情本身替你說話。
- **今日小行動**：當你想急著說明自己有多努力時，先停三秒，讓結果自己說話。
- **反思提問**：你最近有沒有一件事，急著想讓別人看見？

### 第二組：裒多益寡

- **象的畫面**：有人把高處多出來的土挖下來，一鏟一鏟填進低窪的地方，大地慢慢變得平整。
- **象從哪裡來**：《大象傳》說「裒多益寡，稱物平施」，裒是取、益是補。山高地低，而山伏在地下，高與低在這一卦裡相互調和。《彖傳》也說「地道變盈而流謙」，就像水總是從滿的地方流向低處。謙的作用，就是讓失衡的地方回到平衡。
- **給現在的你**：看看你的生活裡，哪裡太多、哪裡太少？也許是工作占據了太多時間，陪伴家人的時間太少；也許是對別人的要求太多，對自己的體諒太少。今天試著把多的那邊移一點過去。
- **今日小行動**：把今天多出來的一點時間、注意力或物品，分給一個正好缺少的人。
- **反思提問**：你的生活裡，哪一處太滿，哪一處太空？

### 第三組：一陽藏於五陰

- **象的畫面**：五層柔軟的土壤之中，藏著一道堅實的岩脈。從地面看不出來，但整片大地都靠它撐著。
- **象從哪裡來**：全卦只有九三一個陽爻，位在下卦的頂端，是這一卦的主爻。它剛健有力，卻被五個陰爻包覆著，有實力而不外露。再看上下卦：內卦艮為止，外卦坤為順，也就是內心安定、對外柔和。九三爻辭「勞謙君子，有終吉」，正好呼應卦辭的「君子有終」。
- **給現在的你**：你可以同時是堅定的，又是柔軟的。內心清楚自己要什麼，對外卻不必處處爭鋒。這樣的人，往往走得最遠，也最有好的結局。
- **今日小行動**：今天遇到意見不同時，先說一句「你這樣想也有道理」，再說出自己的看法。
- **反思提問**：在哪件事上，你可以內心堅定，但態度更柔軟一些？

### 爻範例：初六

- **原文**：初六：謙謙君子，用涉大川，吉。《象》曰：謙謙君子，卑以自牧也。
- **象的畫面**：一座藏在大地之下的山，而你站在山腳最低的地方。低到不能再低，卻正是出發渡河的起點。
- **象從哪裡來**：初爻是全卦最底層，又位在下卦「艮山」的最下方。謙卦本身已是山伏於地下，初六再處其最低處，所以是「謙而又謙」。陰爻居陽位並不當位，上方的六四也同是陰爻，沒有呼應支援，處境看似弱小。但也正因為沒有依靠、不爭不搶，反而能穩穩地一步步前行，這就是「用涉大川」的由來。
- **給現在的你**：事情剛開始、自己還沒有什麼份量的時候，不必急著被看見。把姿態放低，專心照顧好自己的本分，這種安靜的踏實，會帶你渡過眼前那條看似很寬的河。
