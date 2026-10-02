#!/usr/bin/env bash
# CI 產生 android/ 後套用 App 設定：桌面名稱、套件名稱、固定直向、桌面圖示、上傳金鑰簽署。
# 上傳金鑰的四個 Secrets 尚未設定時，改用除錯金鑰簽署（只能自己側載測試）。
set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"
sed -i 's/android:label="[^"]*"/android:label="謙卦"/' "$MANIFEST"

# 套件名稱（Google Play 身分，上傳後永遠不能改）：com.lclab.qiangua
# 只改 applicationId；namespace 維持 flutter create 產生的值，MainActivity 不必搬移
GRADLE="android/app/build.gradle.kts"
sed -i 's/applicationId = "[^"]*"/applicationId = "com.lclab.qiangua"/' "$GRADLE"
grep -q 'applicationId = "com.lclab.qiangua"' "$GRADLE" && echo "套件名稱：com.lclab.qiangua"
# 固定直向：卦卡為 9:16 直式設計
grep -q 'android:screenOrientation' "$MANIFEST" || \
  sed -i '0,/<activity/s//<activity android:screenOrientation="portrait"/' "$MANIFEST"
grep -q 'android:screenOrientation="portrait"' "$MANIFEST" && echo "已固定直向"

# 卦記回顧提醒（flutter_local_notifications）：
# 1) 通知與開機權限；2) 兩個 receiver——少了它們排程會「成功」但時間到永遠不會跳出，
#    BootReceiver 讓重開機或更新後自動重新排程（智慧聽覺巡航 2026-09-27 的教訓）；
# 3) core library desugaring。
python3 - "$MANIFEST" "$GRADLE" << 'PYEOF'
import re, sys
manifest, gradle = sys.argv[1], sys.argv[2]
m = open(manifest, encoding="utf-8").read()
if "ScheduledNotificationReceiver" not in m:
    perms = ('    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n'
             '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n')
    m = m.replace("<application", perms + "    <application", 1)
    receivers = '''        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>'''
    m = m.replace("</application>", receivers, 1)
    open(manifest, "w", encoding="utf-8").write(m)
g = open(gradle, encoding="utf-8").read()
if "isCoreLibraryDesugaringEnabled" not in g:
    g = re.sub(r'(compileOptions\s*\{)', r'\1\n        isCoreLibraryDesugaringEnabled = true', g, count=1)
if "coreLibraryDesugaring(" not in g:
    g = g.rstrip() + '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
open(gradle, "w", encoding="utf-8").write(g)
PYEOF
if grep -q ScheduledNotificationBootReceiver "$MANIFEST" && grep -q isCoreLibraryDesugaringEnabled "$GRADLE"; then
  echo "已設定通知 receiver 與 desugaring"
else
  echo "::error::通知 receiver 或 desugaring 設定失敗（flutter create 範本可能改了）"; exit 1
fi

# 卦記提醒在 release 版失敗的修正（0.1.0+9）：flutter_local_notifications 用 Gson 的 TypeToken
# 把已排程通知序列化保存；R8 壓縮若砍掉泛型資訊，zonedSchedule 會拋例外，
# 結果是「已記在卦記，但提醒沒有設定成功」。智慧聽覺巡航也加了同樣的規則。
PROGUARD="android/app/proguard-rules.pro"
touch "$PROGUARD"
if ! grep -q "flutterlocalnotifications" "$PROGUARD"; then
  cat >> "$PROGUARD" << 'RULES'
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-dontwarn com.google.gson.**
RULES
fi
python3 - "$GRADLE" << 'PYEOF'
import re, sys
path = sys.argv[1]
g = open(path, encoding="utf-8").read()
if "proguard-rules.pro" not in g:
    ins = '\n            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")'
    g = re.sub(r'(release\s*\{)', lambda mt: mt.group(1) + ins, g, count=1)
    open(path, "w", encoding="utf-8").write(g)
PYEOF
grep -q "proguard-rules.pro" "$GRADLE" && echo "已套用 ProGuard 規則（通知排程）" || { echo "::error::ProGuard 規則未套用"; exit 1; }

# 呼吸音景背景播放與通知／鎖定畫面控制（just_audio_background → audio_service）：
# 1) 前景服務權限；2) AudioService 與 MediaButtonReceiver；3) MainActivity 改繼承 AudioServiceActivity；
# 4) launchMode=singleTask——AudioServiceActivity 共用同一個 FlutterEngine，點通知若另建第二個
#    MainActivity，舊的被銷毀時會把引擎拆走，畫面卡住（智慧聽覺巡航 2026-09-29 的教訓）。
python3 - "$MANIFEST" << 'PYEOF'
import re, sys
path = sys.argv[1]
m = open(path, encoding="utf-8").read()
if "com.ryanheise.audioservice.AudioService" not in m:
    perms = ('    <uses-permission android:name="android.permission.WAKE_LOCK"/>\n'
             '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>\n'
             '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>\n')
    m = m.replace("    <application", perms + "    <application", 1)
    block = '''        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>
    </application>'''
    m = m.replace("    </application>", block, 1)
tag = re.search(r'<activity\b[^>]*android:name="\.MainActivity"[^>]*>', m, re.S)
if not tag:
    raise SystemExit("找不到 MainActivity 的 <activity> 標籤")
t = tag.group(0)
if 'android:launchMode=' in t:
    nt = re.sub(r'android:launchMode="[^"]*"', 'android:launchMode="singleTask"', t)
else:
    nt = t.replace('android:name=".MainActivity"', 'android:name=".MainActivity"\n            android:launchMode="singleTask"', 1)
m = m.replace(t, nt, 1)
open(path, "w", encoding="utf-8").write(m)
PYEOF
MAIN_ACTIVITY=$(find android/app/src/main -name "MainActivity.kt" | head -n 1)
sed -i 's/import io.flutter.embedding.android.FlutterActivity/import com.ryanheise.audioservice.AudioServiceActivity/; s/class MainActivity *: *FlutterActivity()/class MainActivity : AudioServiceActivity()/' "$MAIN_ACTIVITY"
if grep -q AudioServiceActivity "$MAIN_ACTIVITY" && grep -q 'com.ryanheise.audioservice.AudioService"' "$MANIFEST" && grep -q 'launchMode="singleTask"' "$MANIFEST"; then
  echo "已設定背景播放（AudioService、AudioServiceActivity、singleTask）"
else
  echo "::error::背景播放設定失敗（flutter create 範本可能改了）"; exit 1
fi

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
