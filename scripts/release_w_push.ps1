# Скрипт для создания релиза на GitHub с управлением версиями через релизные ветки
param(
    [string]$Version,
    [int]$VersionCode,
    [string]$RepoOwner = "VictorNPisarev",
    [string]$RepoName = "KrG-Workshop_app",
    [switch]$AutoPatch,  # Автоматический patch update без вопросов
    [switch]$DryRun      # Только показать что будет, не выполнять
)

function Get-CurrentVersion {
    # Читаем текущую версию из pubspec.yaml
    $pubspecContent = Get-Content -Path "pubspec.yaml" -Raw
    if ($pubspecContent -match 'version:\s*([\d\.]+\+\d+)') {
        $fullVersion = $Matches[1]
        # Разбираем на части: MAJOR.MINOR.PATCH+BUILD
        $parts = $fullVersion -split '\+'
        $versionParts = $parts[0] -split '\.'
        $build = $parts[1]
        
        return @{
            Full = $fullVersion
            Major = [int]$versionParts[0]
            Minor = [int]$versionParts[1]
            Patch = [int]$versionParts[2]
            Build = [int]$build
            VersionWithoutBuild = $parts[0]
        }
    }
    throw "Не удалось найти версию в pubspec.yaml"
}

function Show-VersionMenu($current) {
    Write-Host "Текущая версия: $($current.Major).$($current.Minor).$($current.Patch)+$($current.Build)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Выберите тип обновления:" -ForegroundColor Cyan
    Write-Host "1) Patch (исправления) - $($current.Major).$($current.Minor).$($current.Patch + 1)+$($current.Build + 1)"
    Write-Host "2) Minor (новый функционал) - $($current.Major).$($current.Minor + 1).0+$($current.Build + 1)"
    Write-Host "3) Major (крупные изменения) - $($current.Major + 1).0.0+$($current.Build + 1)"
    Write-Host "4) Ввести свою версию"
    Write-Host ""
    
    $choice = Read-Host "Ваш выбор [1-4]"
    return $choice
}

function Update-PubspecVersion($oldVersion, $newVersion) {
    # Обновляем версию в pubspec.yaml
    $content = Get-Content -Path "pubspec.yaml" -Raw
    $newContent = $content -replace '(?m)^(\s*version:\s*).+', "`$1$newVersion"
    Set-Content -Path "pubspec.yaml" -Value $newContent -Encoding UTF8
    Write-Host "✅ Обновлен pubspec.yaml: $oldVersion → $newVersion" -ForegroundColor Green
}

function Get-MD5Hash($filePath) {
    $hash = (Get-FileHash -Path $filePath -Algorithm MD5).Hash.ToLower()
    return $hash
}

function Create-UpdateJson($version, $versionCode, $apkPath, $apkName, $repoOwner, $repoName) {
    $apkSize = (Get-Item $apkPath).Length
    $md5Hash = Get-MD5Hash -filePath $apkPath
    
    $updateJson = @{
        version = $version
        version_code = $versionCode
        minimum_version_code = 1
        download_url = "https://github.com/$repoOwner/$repoName/releases/download/v$version/app-release.apk"
        file_name = $apkName
        force_update = $false
        release_notes = @(
            "Автоматическая сборка версии $version",
            "Улучшения производительности",
            "Исправление ошибок"
        )
        file_size = $apkSize
        checksum = $md5Hash
    }
    
    $updateJson | ConvertTo-Json | Set-Content -Path "update.json" -Encoding UTF8
    Write-Host "✅ Создан update.json" -ForegroundColor Green
}

# ============ НАЧАЛО СКРИПТА ============
Write-Host "🚀 Подготовка к созданию релиза..." -ForegroundColor Green
Write-Host ""

# Сохраняем текущую ветку для возврата в конце
$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Host "📌 Текущая ветка: $currentBranch" -ForegroundColor Gray

# ============ ШАГ 1: Проверка состояния ============
Write-Host "🔍 Проверка состояния репозитория..." -ForegroundColor Cyan

# Проверяем наличие незакоммиченных изменений
$uncommitted = git status --porcelain
if ($uncommitted) {
    Write-Host "❌ Есть незакоммиченные изменения. Сохраните их через git stash или закоммитьте." -ForegroundColor Red
    git status --short
    exit 1
}

# Переключаемся на main и обновляем
Write-Host "🔀 Переключение на ветку main..." -ForegroundColor Cyan
git checkout main 2>&1 | Out-Null
git pull origin main

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Не удалось обновить ветку main" -ForegroundColor Red
    # Возвращаемся на исходную ветку
    git checkout $currentBranch 2>&1 | Out-Null
    exit 1
}

# ============ ШАГ 2: Определение новой версии ============
$current = Get-CurrentVersion

if ($AutoPatch) {
    $newPatch = $current.Patch + 1
    $newVersion = "$($current.Major).$($current.Minor).$newPatch"
    $newBuild = $current.Build + 1
    $choice = 1
}
elseif ($Version) {
    $newVersion = $Version
    $newBuild = if ($VersionCode) { $VersionCode } else { $current.Build + 1 }
}
else {
    $choice = Show-VersionMenu -current $current
    
    switch ($choice) {
        "1" {
            $newPatch = $current.Patch + 1
            $newVersion = "$($current.Major).$($current.Minor).$newPatch"
            $newBuild = $current.Build + 1
        }
        "2" {
            $newMinor = $current.Minor + 1
            $newVersion = "$($current.Major).$newMinor.0"
            $newBuild = $current.Build + 1
        }
        "3" {
            $newMajor = $current.Major + 1
            $newVersion = "$newMajor.0.0"
            $newBuild = $current.Build + 1
        }
        "4" {
            $newVersion = Read-Host "Введите новую версию (например: 1.2.3)"
            $newBuild = $current.Build + 1
        }
        default {
            Write-Host "❌ Неверный выбор" -ForegroundColor Red
            git checkout $currentBranch 2>&1 | Out-Null
            exit 1
        }
    }
}

$newVersionFull = "$newVersion+$newBuild"
$releaseBranch = "release/v$newVersion"

Write-Host ""
Write-Host "📊 Планируется:" -ForegroundColor Cyan
Write-Host "   Старая версия: $($current.Full)"
Write-Host "   Новая версия:  $newVersionFull"
Write-Host "   Релизная ветка: $releaseBranch"
Write-Host ""

if ($DryRun) {
    Write-Host "⚠️  Dry Run - никакие действия не будут выполнены" -ForegroundColor Yellow
    Write-Host "Будут выполнены:"
    Write-Host "  1. Создание ветки $releaseBranch из main"
    Write-Host "  2. Обновление pubspec.yaml → $newVersionFull"
    Write-Host "  3. Коммит изменений версии"
    Write-Host "  4. Сборка APK"
    Write-Host "  5. Мерж $releaseBranch в main (--no-ff)"
    Write-Host "  6. Создание тега v$newVersion"
    Write-Host "  7. Пуш main + тег в origin"
    Write-Host "  8. Создание update.json (артефакт сборки)"
    Write-Host "  9. Публикация релиза на GitHub с APK и update.json"
    Write-Host " 10. Удаление локальной ветки $releaseBranch"
    Write-Host " 11. Возврат на ветку $currentBranch"
    exit 0
}

$confirm = Read-Host "Продолжить? (y/N)"
if ($confirm -notmatch '^[yY]$') {
    Write-Host "❌ Отменено пользователем" -ForegroundColor Red
    git checkout $currentBranch 2>&1 | Out-Null
    exit 0
}

# ============ ШАГ 3: Создание релизной ветки ============
Write-Host "SetBranch $releaseBranch..." -ForegroundColor Green
git checkout -b $releaseBranch

# ============ ШАГ 4: Обновление версии ============
Write-Host "✏️  Обновление версии в pubspec.yaml..." -ForegroundColor Green
Update-PubspecVersion -oldVersion $current.Full -newVersion $newVersionFull

git add pubspec.yaml
git commit -m "Bump version to $newVersionFull"
Write-Host "✅ Закоммичено изменение версии" -ForegroundColor Green

# ============ ШАГ 5: Сборка APK ============
Write-Host "📦 Сборка APK..." -ForegroundColor Green
flutter clean
if ($LASTEXITCODE -ne 0) { throw "flutter clean failed" }

flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw "flutter build failed" }

$APK_PATH = "build\app\outputs\flutter-apk\app-release.apk"
$APK_NAME = "workshop-app-v$newVersion.apk"

if (-not (Test-Path $APK_PATH)) {
    throw "APK не найден: $APK_PATH"
}

Write-Host "✅ APK собран: $([math]::Round((Get-Item $APK_PATH).Length / 1MB, 2)) MB" -ForegroundColor Green

# ============ ШАГ 6: Мерж в main ============
Write-Host "🔀 Слияние $releaseBranch в main..." -ForegroundColor Green
git checkout main
git merge $releaseBranch --no-ff -m "Release v$newVersion"

# ============ ШАГ 7: Создание тега ============
Write-Host "🏷️  Создание тега v$newVersion..." -ForegroundColor Green
git tag -a "v$newVersion" -m "Release version $newVersion"

# ============ ШАГ 8: Публикация кода ============
Write-Host "📤 Публикация в удалённый репозиторий..." -ForegroundColor Green
git push origin main
if ($LASTEXITCODE -ne 0) { throw "Не удалось запушить main" }

git push origin "v$newVersion"
if ($LASTEXITCODE -ne 0) { throw "Не удалось запушить тег" }

# ============ ШАГ 9: Создание артефактов релиза (ПОСЛЕ мержа!) ============
Write-Host "📝 Создание артефактов релиза..." -ForegroundColor Green

# Создаём update.json ТОЛЬКО ДЛЯ ПУБЛИКАЦИИ (не для коммита!)
Create-UpdateJson -version $newVersion -versionCode $newBuild -apkPath $APK_PATH `
    -apkName $APK_NAME -repoOwner $RepoOwner -repoName $RepoName

# ============ ШАГ 10: Публикация релиза на GitHub ============
Write-Host "☁️  Создание релиза на GitHub..." -ForegroundColor Green

Write-Host "📄 Введите описание релиза (оставьте пустым для стандартного):" -ForegroundColor Cyan
$releaseNotes = Read-Host

if ([string]::IsNullOrWhiteSpace($releaseNotes)) {
    $releaseNotes = "Релиз версии $newVersion

Что нового:
- Автоматическая сборка версии
- Улучшения производительности
- Исправление ошибок"
}

gh release create "v$newVersion" `
    --title "Версия $newVersion" `
    --notes "$releaseNotes" `
    "$APK_PATH" `
    "update.json"

if ($LASTEXITCODE -ne 0) { throw "Не удалось создать релиз на GitHub" }

# ============ ШАГ 11: Очистка ============
Write-Host "🧹 Очистка..." -ForegroundColor Green
Remove-Item "update.json" -ErrorAction SilentlyContinue
git branch -d $releaseBranch  # Удаляем локальную релизную ветку

# Возвращаемся на исходную ветку
if ($currentBranch -ne "main") {
    Write-Host "🔙 Возврат на ветку $currentBranch..." -ForegroundColor Gray
    git checkout $currentBranch
}

# ============ ШАГ 12: Итог ============
Write-Host ""
Write-Host "✅✅✅ РЕЛИЗ УСПЕШНО ЗАВЕРШЕН! ✅✅✅" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Версия:          $newVersion" -ForegroundColor Cyan
Write-Host "📦 Build number:    $newBuild"
Write-Host "🏷️  Тег:             v$newVersion (указывает на коммит с версией $newVersionFull)"
Write-Host ""
Write-Host "🔗 Ссылки:" -ForegroundColor Cyan
Write-Host "   APK:        https://github.com/$RepoOwner/$RepoName/releases/download/v$newVersion/app-release.apk"
Write-Host "   update.json: https://github.com/$RepoOwner/$RepoName/releases/latest/download/update.json"
Write-Host "   Релиз:      https://github.com/$RepoOwner/$RepoName/releases/tag/v$newVersion"
Write-Host ""
Write-Host "💡 Теперь любой может воспроизвести сборку:"
Write-Host "   git checkout v$newVersion"
Write-Host "   flutter build apk --release"
Write-Host ""