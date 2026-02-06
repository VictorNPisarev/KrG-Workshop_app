# Скрипт для создания релиза на GitHub с автоматическим управлением версиями
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
    $newContent = $content -replace "version: $oldVersion", "version: $newVersion"
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

# ============ ОСНОВНОЙ КОД ============
Write-Host "🚀 Подготовка к созданию релиза..." -ForegroundColor Green
Write-Host ""

# Получаем текущую версию
$current = Get-CurrentVersion

# Определяем новую версию
if ($AutoPatch) {
    # Автоматический patch update
    $newPatch = $current.Patch + 1
    $newVersion = "$($current.Major).$($current.Minor).$newPatch"
    $newBuild = $current.Build + 1
    $choice = 1
}
elseif ($Version) {
    # Версия указана в параметре
    $newVersion = $Version
    $newBuild = if ($VersionCode) { $VersionCode } else { $current.Build + 1 }
}
else {
    # Интерактивный режим
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
            exit 1
        }
    }
}

$newVersionFull = "$newVersion+$newBuild"

Write-Host ""
Write-Host "📊 Планируется:" -ForegroundColor Cyan
Write-Host "   Старая версия: $($current.Full)"
Write-Host "   Новая версия:  $newVersionFull"
Write-Host ""

if ($DryRun) {
    Write-Host "⚠️  Dry Run - никакие действия не будут выполнены" -ForegroundColor Yellow
    exit 0
}

$confirm = Read-Host "Продолжить? (y/N)"
if ($confirm -notmatch '^[yY]$') {
    Write-Host "❌ Отменено пользователем" -ForegroundColor Red
    exit 0
}

# ============ ВЫПОЛНЕНИЕ ============
try {
    # 1. Обновляем pubspec.yaml
    Update-PubspecVersion -oldVersion $current.Full -newVersion $newVersionFull
    
    # 2. Собираем APK
    Write-Host "📦 Сборка APK..." -ForegroundColor Green
    flutter clean
    flutter build apk --release
    
    $APK_PATH = "build\app\outputs\flutter-apk\app-release.apk"
    $APK_NAME = "workshop-app-v$newVersion.apk"
    
    # 3. Создаем update.json
    Write-Host "📝 Создание update.json..." -ForegroundColor Green
    Create-UpdateJson -version $newVersion -versionCode $newBuild -apkPath $APK_PATH `
        -apkName $APK_NAME -repoOwner $RepoOwner -repoName $RepoName
    
    # 4. Запрашиваем описание релиза
    Write-Host ""
    Write-Host "📄 Введите описание релиза (оставьте пустым для стандартного):" -ForegroundColor Cyan
    $releaseNotes = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($releaseNotes)) {
        $releaseNotes = "Релиз версии $newVersion

Что нового:
- Автоматическая сборка версии
- Улучшения производительности
- Исправление ошибок"
    }
    
    # 5. Создаем коммит и тег
    Write-Host "🏷️  Создание тега v$newVersion..." -ForegroundColor Green
    git add pubspec.yaml
    git commit -m "Bump version to $newVersionFull"
    git tag -a "v$newVersion" -m "Release version $newVersion"
    git push origin main
    git push origin "v$newVersion"
    
    # 6. Создаем релиз
    Write-Host "📤 Создание релиза на GitHub..." -ForegroundColor Green
    gh release create "v$newVersion" `
        --title "Версия $newVersion" `
        --notes "$releaseNotes" `
        "$APK_PATH" `
        "update.json"
    
    # 7. Очистка
    Remove-Item "update.json" -ErrorAction SilentlyContinue
    
    # 8. Результат
    Write-Host ""
    Write-Host "✅ Релиз успешно создан!" -ForegroundColor Green
    Write-Host "📊 Информация:" -ForegroundColor Cyan
    Write-Host "   Версия:          $newVersion"
    Write-Host "   Build number:    $newBuild"
    Write-Host "   Размер APK:      $([math]::Round((Get-Item $APK_PATH).Length / 1MB, 2)) MB"
    Write-Host ""
    Write-Host "🔗 Ссылки:" -ForegroundColor Cyan
    Write-Host "   APK:        https://github.com/$RepoOwner/$RepoName/releases/download/v$newVersion/app-release.apk"
    Write-Host "   update.json: https://github.com/$RepoOwner/$RepoName/releases/latest/download/update.json"
    Write-Host "   Релиз:      https://github.com/$RepoOwner/$RepoName/releases/tag/v$newVersion"
    
}
catch {
    Write-Host "❌ Ошибка: $_" -ForegroundColor Red
    # Откатываем изменения в pubspec.yaml в случае ошибки
    if ($current.Full) {
        Update-PubspecVersion -oldVersion $newVersionFull -newVersion $current.Full
    }
    throw
}