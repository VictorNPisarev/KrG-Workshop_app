#!/bin/bash
# Скрипт для создания релиза на GitHub

set -e  # Выход при ошибке

# Настройки
VERSION="1.0.2"
VERSION_CODE=3
REPO_OWNER="VictorNPisarev"
REPO_NAME="KrG-Workshop_app"
RELEASE_TITLE="Версия $VERSION"

echo "🚀 Создание релиза v$VERSION..."

# 1. Собираем APK
echo "📦 Сборка APK..."
flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
APK_SIZE=$(stat -f%z "$APK_PATH")
APK_NAME="workshop-app-v$VERSION.apk"

# 2. Генерируем MD5 хеш
echo "🔐 Генерация MD5..."
MD5_HASH=$(md5 -q "$APK_PATH")

# 3. Создаем update.json
echo "📝 Создание update.json..."
cat > update.json << EOF
{
  "version": "$VERSION",
  "version_code": $VERSION_CODE,
  "minimum_version_code": 1,
  "download_url": "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/v$VERSION/app-release.apk",
  "file_name": "$APK_NAME",
  "force_update": false,
  "release_notes": [
    "Исправлены ошибки",
    "Добавлены автоматические обновления"
  ],
  "file_size": $APK_SIZE,
  "checksum": "$MD5_HASH"
}
EOF

# 4. Создаем тег и пуш
echo "🏷️ Создание тега v$VERSION..."
git tag -a "v$VERSION" -m "Release version $VERSION"
git push origin "v$VERSION"

# 5. Создаем релиз (требуется установленный gh)
echo "📤 Создание релиза на GitHub..."
gh release create "v$VERSION" \
  --title "$RELEASE_TITLE" \
  --notes "Что нового:
  - Исправлены ошибки
  - Добавлены автоматические обновления" \
  "$APK_PATH" \
  update.json

# 6. Очистка
rm update.json

echo "✅ Релиз создан!"
echo "📱 APK: https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/v$VERSION/app-release.apk"
echo "📄 update.json: https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest/download/update.json"