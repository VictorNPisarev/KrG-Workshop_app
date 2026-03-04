# simple_deploy.ps1 - Только сборка и копирование
param(
    [string]$ServerPath = "C:\inetpub\wwwroot\workshop_web", #"\\server\WorkshopApp$",
    [switch]$SkipBuild,
    [switch]$Test  # Проверить доступность без копирования
)

if ($Test) {
    Write-Host "🔍 Проверка доступности:" -ForegroundColor Cyan
    
    # Проверка сервера
    if (Test-Connection -ComputerName ($ServerPath -split '\\')[2] -Count 1 -Quiet) {
        Write-Host "  ✅ Сервер доступен" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Сервер недоступен" -ForegroundColor Red
    }
    
    # Проверка папки
    if (Test-Path $ServerPath) {
        Write-Host "  ✅ Папка доступна" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Папка не найдена" -ForegroundColor Red
    }
    
    exit
}

if (-not $SkipBuild) {
    Write-Host "📦 Сборка проекта..." -ForegroundColor Yellow
    flutter clean
    flutter build web --release --no-tree-shake-icons
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

Write-Host "📋 Копирование на $ServerPath..." -ForegroundColor Yellow
Copy-Item -Path "build\web\*" -Destination $ServerPath -Recurse -Force

Write-Host "✅ Готово!" -ForegroundColor Green
Write-Host "📱 Приложение обновлено на сервере"