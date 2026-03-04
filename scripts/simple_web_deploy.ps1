# simple_deploy.ps1 - Простой деплой Web версии
param(
    [string]$TargetDir = "C:\WorkshopApp",  # Куда копировать
    [int]$Port = 3030,                       # Порт для сервера
    [switch]$SkipBuild,                       # Пропустить сборку
    [switch]$SkipCopy,                         # Пропустить копирование
    [switch]$SkipServer                         # Не запускать сервер
)

Write-Host "🚀 Деплой Web версии" -ForegroundColor Green
Write-Host "========================================"

# 1. Сборка
if (-not $SkipBuild) {
    Write-Host "📦 Сборка проекта..." -ForegroundColor Yellow
    flutter clean
    flutter build web --release --no-tree-shake-icons
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Ошибка сборки" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Сборка завершена" -ForegroundColor Green
} else {
    Write-Host "⏩ Сборка пропущена" -ForegroundColor Gray
}

# 2. Копирование
if (-not $SkipCopy) {
    Write-Host "📋 Копирование файлов в $TargetDir..." -ForegroundColor Yellow
    
    # Создаем папку если нет
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
        Write-Host "  Создана папка $TargetDir" -ForegroundColor Gray
    }
    
    # Копируем
    Copy-Item -Path "build\web\*" -Destination $TargetDir -Recurse -Force
    Write-Host "✅ Файлы скопированы" -ForegroundColor Green
} else {
    Write-Host "⏩ Копирование пропущено" -ForegroundColor Gray
}

# 3. Запуск сервера
if (-not $SkipServer) {
    Write-Host "🚀 Запуск сервера на порту $Port..." -ForegroundColor Yellow
    
    # Получаем IP адреса
    $ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }
    
    Write-Host ""
    Write-Host "📱 Сервер доступен по адресам:" -ForegroundColor Cyan
    Write-Host "   http://localhost:$Port" -ForegroundColor White
    foreach ($ip in $ips) {
        Write-Host "   http://$($ip.IPAddress):$Port" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "❌ Нажми Ctrl+C для остановки" -ForegroundColor Red
    Write-Host ""
    
    # Переходим в папку с файлами и запускаем сервер
    Push-Location $TargetDir
    npx http-server -p $Port --host 0.0.0.0
    Pop-Location
} else {
    Write-Host ""
    Write-Host "✅ Готово! Файлы в: $TargetDir" -ForegroundColor Green
    Write-Host "   Запусти сервер: npx http-server -p $Port --host 0.0.0.0"
}