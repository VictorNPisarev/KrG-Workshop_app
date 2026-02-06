#!/bin/bash
# Быстрый релиз с авто-патчем

set -e

# Проверка необходимых команд
command -v flutter >/dev/null 2>&1 || { echo "❌ Flutter не установлен"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "❌ Git не установлен"; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "❌ GitHub CLI не установлен"; exit 1; }

# Проверка, что мы в директории проекта
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Запустите скрипт из корневой директории Flutter проекта"
    exit 1
fi

# Автоматически увеличиваем patch версию
CURRENT_VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //')
IFS='+' read -ra PARTS <<< "$CURRENT_VERSION"
VERSION="${PARTS[0]}"
BUILD="${PARTS[1]}"

IFS='.' read -ra VER <<< "$VERSION"
MAJOR="${VER[0]}"
MINOR="${VER[1]}"
PATCH="${VER[2]}"

NEW_PATCH=$((PATCH + 1))
NEW_BUILD=$((BUILD + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
NEW_VERSION_FULL="$NEW_VERSION+$NEW_BUILD"

echo "🔄 Автоматическое обновление: $CURRENT_VERSION → $NEW_VERSION_FULL"

# Обновляем pubspec.yaml
sed -i "s/version: $CURRENT_VERSION/version: $NEW_VERSION_FULL/" pubspec.yaml

# Запускаем основной скрипт в автоматическом режиме
./release.sh auto-patch