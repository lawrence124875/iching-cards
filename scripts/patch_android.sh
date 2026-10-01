#!/usr/bin/env bash
# CI 產生 android/ 後套用 App 設定：桌面名稱、固定直向、桌面圖示、上傳金鑰簽署。
# 上傳金鑰的四個 Secrets 尚未設定時，改用除錯金鑰簽署（只能自己側載測試）。
set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"
sed -i 's/android:label="[^"]*"/android:label="易經卦卡"/' "$MANIFEST"
# 固定直向：卦卡為 9:16 直式設計
grep -q 'android:screenOrientation' "$MANIFEST" || \
  sed -i '0,/<activity/s//<activity android:screenOrientation="portrait"/' "$MANIFEST"
grep -q 'android:screenOrientation="portrait"' "$MANIFEST" && echo "已固定直向"

# 桌面圖示（謙卦卦卡）：覆蓋 flutter create 的預設圖示，含 Android 8+ 自適應圖示
cp -r branding/android/res/. android/app/src/main/res/
echo "已套用桌面圖示"

GRADLE_KTS="android/app/build.gradle.kts"

if [ -z "${ANDROID_KEYSTORE_BASE64:-}" ]; then
  echo "::warning::尚未設定上傳金鑰 Secrets，本次以除錯金鑰簽署（每次建置簽章不同，安裝新版前須先移除舊版）"
  echo "SIGNING=除錯金鑰" >> "$GITHUB_ENV"
  exit 0
fi

echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > android/app/upload-key.jks
cat > android/key.properties << PROPS
storePassword=$ANDROID_KEYSTORE_PASSWORD
keyPassword=$ANDROID_KEY_PASSWORD
keyAlias=$ANDROID_KEY_ALIAS
storeFile=upload-key.jks
PROPS

python3 - "$GRADLE_KTS" << 'PYEOF'
import re, sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
if "iching_release_signing" not in s:
    s = "import java.util.Properties\nimport java.io.FileInputStream\n\n" + s
    s = s.replace("android {", '''// iching_release_signing
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {''', 1)
    s = s.replace("    buildTypes {", '''    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {''', 1)
    new = re.sub(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
                 'signingConfig = signingConfigs.getByName("release")', s)
    if new == s:
        new = re.sub(r'(release\s*\{)', r'\1\n            signingConfig = signingConfigs.getByName("release")', s, count=1)
    s = new
open(path, "w", encoding="utf-8").write(s)
PYEOF

echo "SIGNING=上傳金鑰" >> "$GITHUB_ENV"
echo "已設定上傳金鑰簽署"
