#!/bin/bash
# Скрипт для создания релиза на GitHub с автоматическим увеличением версии

set -e  # Выход при ошибке

# Проверка необходимых команд
command -v flutter >/dev/null 2>&1 || { echo "❌ Flutter не установлен"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "❌ Git не установлен"; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "❌ GitHub CLI не установлен"; exit 1; }

# Проверка, что мы в директории проекта
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Запустите скрипт из корневой директории Flutter проекта"
    exit 1
fi

# Настройки
REPO_OWNER="VictorNPisarev"
REPO_NAME="KrG-Workshop_app"

echo "🚀 Подготовка к созданию релиза..."

# 1. Получаем текущую версию из pubspec.yaml
CURRENT_VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //')
echo "📄 Текущая версия в pubspec.yaml: $CURRENT_VERSION"

# 2. Парсим версию (формат: MAJOR.MINOR.PATCH+BUILD)
IFS='+' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
VERSION_WITHOUT_BUILD="${VERSION_PARTS[0]}"
CURRENT_BUILD="${VERSION_PARTS[1]}"

IFS='.' read -ra VERSION_NUMS <<< "$VERSION_WITHOUT_BUILD"
MAJOR="${VERSION_NUMS[0]}"
MINOR="${VERSION_NUMS[1]}"
PATCH="${VERSION_NUMS[2]}"

# 3. Спрашиваем тип обновления
echo ""
echo "Текущая версия: $MAJOR.$MINOR.$PATCH+$CURRENT_BUILD"
echo "Выберите тип обновления:"
echo "1) Patch (исправления) - $MAJOR.$MINOR.$((PATCH + 1))+$((CURRENT_BUILD + 1))"
echo "2) Minor (новый функционал) - $MAJOR.$((MINOR + 1)).0+$((CURRENT_BUILD + 1))"
echo "3) Major (крупные изменения) - $((MAJOR + 1)).0.0+$((CURRENT_BUILD + 1))"
echo "4) Ввести свою версию"
echo -n "Ваш выбор [1-4]: "
read -r CHOICE

case $CHOICE in
    1)
        # Patch update
        NEW_PATCH=$((PATCH + 1))
        NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
        ;;
    2)
        # Minor update
        NEW_MINOR=$((MINOR + 1))
        NEW_VERSION="$MAJOR.$NEW_MINOR.0"
        ;;
    3)
        # Major update
        NEW_MAJOR=$((MAJOR + 1))
        NEW_VERSION="$NEW_MAJOR.0.0"
        ;;
    4)
        echo -n "Введите новую версию (без build number, например: 1.2.3): "
        read -r NEW_VERSION
        ;;
    *)
        echo "❌ Неверный выбор"
        exit 1
        ;;
esac

# 4. Генерируем новый build number
NEW_BUILD=$((CURRENT_BUILD + 1))

# 5. Обновляем pubspec.yaml
NEW_VERSION_FULL="$NEW_VERSION+$NEW_BUILD"
echo "🔄 Обновляю pubspec.yaml до версии: $NEW_VERSION_FULL"
sed -i "s/version: $CURRENT_VERSION/version: $NEW_VERSION_FULL/" pubspec.yaml

# 6. Собираем APK
echo "📦 Сборка APK..."
flutter clean
flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
APK_SIZE=$(stat -f%z "$APK_PATH" 2>/dev/null || stat -c%s "$APK_PATH")  # Поддержка macOS и Linux
APK_NAME="workshop-app-v$NEW_VERSION.apk"

# 7. Генерируем MD5 хеш
echo "🔐 Генерация MD5..."
if command -v md5sum &> /dev/null; then
    MD5_HASH=$(md5sum "$APK_PATH" | cut -d ' ' -f1)
else
    MD5_HASH=$(md5 -q "$APK_PATH")
fi

# 8. Создаем update.json
echo "📝 Создание update.json..."
cat > update.json << EOF
{
  "version": "$NEW_VERSION",
  "version_code": $NEW_BUILD,
  "minimum_version_code": 1,
  "download_url": "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/v$NEW_VERSION/app-release.apk",
  "file_name": "$APK_NAME",
  "force_update": false,
  "release_notes": [
    "Автоматическая сборка версии $NEW_VERSION",
    "Исправлены ошибки",
    "Добавлены автоматические обновления"
  ],
  "file_size": $APK_SIZE,
  "checksum": "$MD5_HASH"
}
EOF

# 9. Спрашиваем описание релиза
echo -n "Введите описание релиза (оставьте пустым для стандартного): "
read -r RELEASE_NOTES

if [ -z "$RELEASE_NOTES" ]; then
    RELEASE_NOTES="Релиз версии $NEW_VERSION

Что нового:
- Автоматическая сборка версии
- Улучшения производительности
- Исправление ошибок"
fi

# 10. Создаем тег и пуш
echo "🏷️ Создание тега v$NEW_VERSION..."
git add pubspec.yaml
git commit -m "Bump version to $NEW_VERSION_FULL"
git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"
git push origin main
git push origin "v$NEW_VERSION"

# 11. Создаем релиз (требуется установленный gh)
echo "📤 Создание релиза на GitHub..."
gh release create "v$NEW_VERSION" \
  --title "Версия $NEW_VERSION" \
  --notes "$RELEASE_NOTES" \
  "$APK_PATH" \
  update.json

# 12. Очистка
rm update.json

echo ""
echo "✅ Релиз успешно создан!"
echo "📊 Информация о релизе:"
echo "   Версия:          $NEW_VERSION"
echo "   Build number:    $NEW_BUILD"
echo "   Размер APK:      $(echo "scale=2; $APK_SIZE/1048576" | bc) MB"
echo "   MD5:             $MD5_HASH"
echo ""
echo "🔗 Ссылки:"
echo "   APK:        https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/v$NEW_VERSION/app-release.apk"
echo "   update.json: https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest/download/update.json"
echo "   Релиз:      https://github.com/$REPO_OWNER/$REPO_NAME/releases/tag/v$NEW_VERSION"