# Скрипт для создания релиза на GitHub
param(
    [string]$Version = "1.0.1",
    [int]$VersionCode = 2,
    [string]$RepoOwner = "VictorNPisarev",
    [string]$RepoName = "KrG-Workshop_app"
)

Write-Host "Создание релиза v$Version..."

# 1. Сборка APK
Write-Host "Сборка APK..."
flutter build apk --release

$APK_PATH = "build\app\outputs\flutter-apk\app-release.apk"
$APK_NAME = "workshop-app-v$Version.apk"

# 2. MD5 хеш
Write-Host "Генерация MD5..."
$MD5_HASH = (Get-FileHash -Path $APK_PATH -Algorithm MD5).Hash.ToLower()

# 3. Размер файла
$APK_SIZE = (Get-Item $APK_PATH).Length

# 4. Создание update.json
Write-Host "Создание update.json..."
$UPDATE_JSON_CONTENT = @"
{
  "version": "$Version",
  "version_code": $VersionCode,
  "minimum_version_code": 1,
  "download_url": "https://github.com/$RepoOwner/$RepoName/releases/download/v$Version/app-release.apk",
  "file_name": "$APK_NAME",
  "force_update": false,
  "release_notes": [
    "Bug fixes",
    "Added automatic updates"
  ],
  "file_size": $APK_SIZE,
  "checksum": "$MD5_HASH"
}
"@

Set-Content -Path "update.json" -Value $UPDATE_JSON_CONTENT -Encoding UTF8

# 5. Создание тега
Write-Host "Создание тега v$Version..."
git tag -a "v$Version" -m "Release version $Version"
git push origin "v$Version"

# 6. Создание релиза через gh CLI
Write-Host "Создание релиза на GitHub..."
gh release create "v$Version" `
  --title "Version $Version" `
  --notes "What's new:
- Bug fixes
- Added automatic updates" `
  "$APK_PATH" `
  update.json

# 7. Очистка
Remove-Item "update.json"

Write-Host "Релиз создан!"
Write-Host "APK: https://github.com/$RepoOwner/$RepoName/releases/download/v$Version/app-release.apk"
Write-Host "update.json: https://github.com/$RepoOwner/$RepoName/releases/latest/download/update.json"