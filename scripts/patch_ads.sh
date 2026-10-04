#!/usr/bin/env bash
# 廣告與訂閱（HANDOFF §23）：AdMob App ID、url_launcher 查詢、ProGuard。
# ADMOB_APP_ID（GitHub Secret，ca-app-pub-…~…）沒設定時用 Google 官方測試 App ID：
# 少了這個 meta-data，google_mobile_ads 一啟動就閃退。
set -euo pipefail
MANIFEST="android/app/src/main/AndroidManifest.xml"
PROGUARD="android/app/proguard-rules.pro"
APP_ID="${ADMOB_APP_ID:-}"
if [ -z "$APP_ID" ]; then
  APP_ID="ca-app-pub-3940256099942544~3347511713"
  echo "::warning::未設定 ADMOB_APP_ID，使用 Google 測試 App ID（只會顯示測試廣告）"
  echo "ADS=測試廣告" >> "${GITHUB_ENV:-/dev/null}"
else
  echo "ADS=正式廣告單元" >> "${GITHUB_ENV:-/dev/null}"
fi
python3 - "$MANIFEST" "$APP_ID" << 'PYEOF'
import sys
path, app_id = sys.argv[1], sys.argv[2]
m = open(path, encoding="utf-8").read()
if "com.google.android.gms.ads.APPLICATION_ID" not in m:
    meta = ('        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
            f'            android:value="{app_id}"/>\n    </application>')
    m = m.replace("</application>", meta, 1)
# url_launcher（Android 11+ 套件可見性）：開瀏覽器看隱私權政策、到 Play 管理訂閱
if '<data android:scheme="https"' not in m:
    q = ('    <queries>\n        <intent>\n            <action android:name="android.intent.action.VIEW" />\n'
         '            <data android:scheme="https" />\n        </intent>\n    </queries>\n</manifest>')
    i = m.rfind("</manifest>")
    m = m[:i] + q + m[i + len("</manifest>"):]
open(path, "w", encoding="utf-8").write(m)
PYEOF
grep -q "gms.ads.APPLICATION_ID" "$MANIFEST" && echo "已加入 AdMob App ID"
touch "$PROGUARD"
if ! grep -q "revenuecat" "$PROGUARD"; then
  cat >> "$PROGUARD" << 'RULES'
# RevenueCat / Google Play Billing / AdMob（同智慧聽覺巡航）
-keep class com.android.billingclient.api.** { *; }
-dontwarn com.android.billingclient.api.**
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
RULES
fi
if [ -n "${REVENUECAT_API_KEY:-}" ]; then
  echo "SUBS=已設定" >> "${GITHUB_ENV:-/dev/null}"
else
  echo "::warning::未設定 REVENUECAT_ANDROID_API_KEY，訂閱頁會顯示「尚未開放」"
  echo "SUBS=未設定（尚未開放）" >> "${GITHUB_ENV:-/dev/null}"
fi
