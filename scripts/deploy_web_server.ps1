# deploy_web_server.ps1 - Сборка и деплой Web версии на сервер предприятия
param
(
    [string]$ServerPath = "\\server\www\workshop_app",  # Путь к папке на сервере
    [string]$ServerIP = "192.168.1.100",                 # IP сервера (для информации)
    [int]$Port = 8080,                                   # Порт для сервера
    [switch]$Build = $true,                               # Выполнять сборку
    [switch]$Deploy = $true,                              # Копировать на сервер
    [switch]$StartServer = $false,                        # Запустить сервер после деплоя
    [switch]$InstallAsService = $false,                   # Установить как службу Windows
    [switch]$DryRun = $false                               # Только показать что будет
)

# Цвета для вывода
$Host.UI.RawUI.ForegroundColor = "White"
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

function Write-Success($message) 
{
    Write-Host "✅ $message" -ForegroundColor $successColor
}

function Write-Error($message) 
{
    Write-Host "❌ $message" -ForegroundColor $errorColor
}

function Write-Info($message) 
{
    Write-Host "ℹ️  $message" -ForegroundColor $infoColor
}

function Write-Warning($message) 
{
    Write-Host "⚠️  $message" -ForegroundColor $warningColor
}

function Get-CurrentVersion 
{
    $pubspecContent = Get-Content -Path "pubspec.yaml" -Raw
    if ($pubspecContent -match 'version:\s*([\d\.]+\+\d+)') 
    {
        return $Matches[1]
    }
    return "unknown"
}

function Build-WebVersion 
{
    Write-Info "Сборка Web версии..."
    
    # Очистка
    flutter clean
    if ($LASTEXITCODE -ne 0) { throw "flutter clean failed" }
    
    # Сборка
    flutter build web --release --no-tree-shake-icons
    if ($LASTEXITCODE -ne 0) { throw "flutter build web failed" }
    
    $buildPath = "build/web"
    if (Test-Path $buildPath) 
    {
        $size = (Get-ChildItem $buildPath -Recurse | Measure-Object Length -Sum).Sum / 1MB
        Write-Success "Web версия собрана: $([math]::Round($size, 2)) MB"
        return $buildPath
    } 
    else 
    {
        throw "Папка сборки не найдена: $buildPath"
    }
}

function Copy-ToServer($source, $destination) 
{
    Write-Info "Копирование файлов на сервер..."
    Write-Info "   Источник: $source"
    Write-Info "   Назначение: $destination"
    
    # Проверяем доступность сервера
    if (-not (Test-Connection -ComputerName ($destination -split '\\')[2] -Count 1 -Quiet)) 
    {
        Write-Warning "Сервер недоступен по сети"
        return $false
    }
    
    # Создаем папку на сервере если нет
    if (-not (Test-Path $destination)) 
    {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        Write-Success "Создана папка на сервере"
    }
    
    # Копируем файлы
    Copy-Item -Path "$source\*" -Destination $destination -Recurse -Force
    
    Write-Success "Файлы скопированы на сервер"
    return $true
}

function Create-WebConfig($path) 
{
    Write-Info "Создание web.config для IIS..."
    $configPath = Join-Path $path "web.config"
    
    # Пишем XML построчно через массив, чтобы исключить ошибки парсинга here-strings
    $xmlLines = @(
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<configuration>',
        '  <system.webServer>',
        '    <staticContent>',
        '      <mimeMap fileExtension=".dart" mimeType="text/plain" />',
        '      <mimeMap fileExtension=".js" mimeType="application/javascript" />',
        '      <mimeMap fileExtension=".json" mimeType="application/json" />',
        '      <mimeMap fileExtension=".wasm" mimeType="application/wasm" />',
        '    </staticContent>',
        '    <rewrite>',
        '      <rules>',
        '        <rule name="Flutter Routes" stopProcessing="true">',
        '          <match url=".*" />',
        '          <conditions logicalGrouping="MatchAll">',
        '            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />',
        '            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />',
        '          </conditions>',
        '          <action type="Rewrite" url="/index.html" />',
        '        </rule>',
        '      </rules>',
        '    </rewrite>',
        '    <httpProtocol>',
        '      <customHeaders>',
        '        <add name="Access-Control-Allow-Origin" value="*" />',
        '      </customHeaders>',
        '    </httpProtocol>',
        '  </system.webServer>',
        '</configuration>'
    )
    
    $xmlLines | Set-Content -Path $configPath -Encoding UTF8
    Write-Success "web.config создан"
}

function Create-StartScript($path, $port) 
{
    Write-Info "Создание скрипта запуска сервера..."
    
    # Создаем BAT файл (простая строка, без переменных PS)
    $batContent = @"
@echo off
cd /d "%~dp0"
echo Starting server on port %1
python -m http.server %1
"@
    $batContent | Set-Content -Path "$path\start_server.bat" -Encoding ASCII
    
    # Создаем PS1 файл. 
    # ВАЖНО: Используем @'...'@ (одинарные кавычки), чтобы содержимое не выполнялось сейчас,
    # а записалось в файл буквально. Переменные `$port` экранируем как `$`port.
    $psContent = @"
param(`$port = $port)
Set-Location `$PSScriptRoot
Write-Host "🚀 Запуск сервера на порту `$port" -ForegroundColor Green
Write-Host "📁 Папка: `$PSScriptRoot" -ForegroundColor Cyan
Write-Host ""
Write-Host "Доступно по адресам:" -ForegroundColor Yellow
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { `$_.InterfaceAlias -notlike "*Loopback*" } | ForEach-Object {
    Write-Host "   http://`$(`$_.IPAddress):`$port" -ForegroundColor White
}
Write-Host ""
Write-Host "❌ Ctrl+C для остановки" -ForegroundColor Red
python -m http.server `$port
"@
    $psContent | Set-Content -Path "$path\start_server.ps1" -Encoding UTF8
    Write-Success "Скрипты запуска созданы"
}

function Start-LocalServer($port) 
{
    Write-Info "Запуск сервера на порту $port..."
    
    # Проверяем наличие Python
    try 
    {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python") 
        {
            Write-Success "Python найден: $pythonVersion"
        } 
        else 
        {
            throw "Python не найден"
        }
    } 
    catch 
    {
        Write-Warning "Python не установлен. Используем Node.js?"
        try 
        {
            $nodeVersion = node --version
            Write-Success "Node.js найден: $nodeVersion"
            Start-Process "npx" -ArgumentList "http-server -p $port -a 0.0.0.0" -WindowStyle Normal
            return
        } 
        catch 
        {
            Write-Error "Ни Python, ни Node.js не установлены"
            return $false
        }
    }
    
    # Запускаем Python сервер
    $serverProcess = Start-Process -FilePath "python" -ArgumentList "-m http.server $port" -PassThru -NoNewWindow
    Write-Success "Сервер запущен (PID: $($serverProcess.Id))"
    
    # Показываем IP адреса
    Write-Host ""
    Write-Host "📱 Доступно по адресам:" -ForegroundColor Yellow
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | ForEach-Object {
        Write-Host "   http://$($_.IPAddress):$port" -ForegroundColor White
    }
    Write-Host ""
    
    return $serverProcess
}

function Install-AsWindowsService($path, $port) 
{
    Write-Info "Установка как службы Windows..."
    
    # Проверяем наличие NSSM (Non-Sucking Service Manager)
    if (-not (Get-Command nssm -ErrorAction SilentlyContinue)) 
    {
        Write-Warning "NSSM не найден. Скачиваем..."
        $nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
        $nssmZip = "$env:TEMP\nssm.zip"
        $nssmDir = "$env:TEMP\nssm"
        
        Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmZip
        Expand-Archive -Path $nssmZip -DestinationPath $nssmDir -Force
        Copy-Item "$nssmDir\nssm-2.24\win64\nssm.exe" -Destination "$env:SystemRoot\System32\nssm.exe" -Force
        Remove-Item $nssmZip, $nssmDir -Recurse -Force
        Write-Success "NSSM установлен"
    }
    
    # Создаем службу
    $serviceName = "WorkshopAppWeb"
    $pythonPath = (Get-Command python).Source
    
    nssm install $serviceName $pythonPath "-m http.server $port"
    nssm set $serviceName AppDirectory $path
    nssm set $serviceName Start SERVICE_AUTO_START
    nssm set $serviceName DisplayName "Красная горка - Web версия"
    nssm set $serviceName Description "Web сервер для приложения Workshop App"
    
    Write-Success "Служба $serviceName создана"
    
    # Запускаем службу
    Start-Service $serviceName
    Write-Success "Служба запущена"
}

# ============ ОСНОВНАЯ ЛОГИКА ============
Write-Host "🚀 ДЕПЛОЙ WEB ВЕРСИИ НА СЕРВЕР" -ForegroundColor Magenta
Write-Host ("=" * 50)
Write-Host ""

$version = Get-CurrentVersion
Write-Info "Текущая версия: $version"

if ($DryRun) 
{
    Write-Warning "РЕЖИМ DRY RUN - ничего не будет выполнено"
    Write-Host ""
    Write-Host "Будут выполнены следующие действия:" -ForegroundColor Yellow
    if ($Build) { Write-Host "  • Сборка Web версии" }
    if ($Deploy) { Write-Host "  • Копирование на сервер: $ServerPath" }
    if ($StartServer) { Write-Host "  • Запуск сервера на порту $Port" }
    if ($InstallAsService) { Write-Host "  • Установка как службы Windows" }
    exit 0
}

# Шаг 1: Сборка
if ($Build) 
{
    try 
    {
        $buildPath = Build-WebVersion
        
        # Создаем web.config для IIS
        Create-WebConfig -path $buildPath
        
        # Создаем скрипты запуска
        Create-StartScript -path $buildPath -port $Port
    } 
    catch 
    {
        Write-Error "Ошибка сборки: $_"
        exit 1
    }
} 
else 
{
    $buildPath = "build/web"
    if (-not (Test-Path $buildPath)) 
    {
        Write-Error "Папка сборки не найдена. Запустите с параметром -Build"
        exit 1
    }
}

# Шаг 2: Копирование на сервер
if ($Deploy) 
{
    $copySuccess = Copy-ToServer -source $buildPath -destination $ServerPath
    if (-not $copySuccess) 
    {
        Write-Warning "Продолжаем локально"
    }
}

# Шаг 3: Запуск сервера
if ($StartServer) 
{
    $process = Start-LocalServer -port $Port
    
    # Сохраняем PID для возможной остановки
    if ($process) 
    {
        $process.Id | Out-File -FilePath "server.pid"
        Write-Success "PID сохранен в server.pid"
    }
}

# Шаг 4: Установка как службы
if ($InstallAsService) 
{
    Install-AsWindowsService -path $buildPath -port $Port
}

# Шаг 5: Итог
Write-Host ""
Write-Host "✅✅✅ ДЕПЛОЙ ЗАВЕРШЕН! ✅✅✅" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Версия:       $version" -ForegroundColor Cyan
Write-Host "📁 Локальная:    $buildPath"
Write-Host "🌐 Сервер:       $ServerPath"
Write-Host "🔌 Порт:         $Port"
Write-Host ""

if ($StartServer) 
{
    Write-Host "📱 Доступ локально:" -ForegroundColor Yellow
    Write-Host "   http://localhost:$Port"
    Write-Host ""
    Write-Host "🌍 Доступ в сети:" -ForegroundColor Yellow
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | ForEach-Object {
        Write-Host "   http://$($_.IPAddress):$Port"
    }
}

Write-Host ""
Write-Host "💡 Команды управления:" -ForegroundColor Cyan
Write-Host "   Остановить сервер:  taskkill /F /PID $(Get-Content server.pid 2>$null)"
Write-Host "   Запустить сервер:   .\start_server.ps1"
Write-Host "   Пересобрать:        .\deploy_web_server.ps1"
Write-Host "   Dry run:            .\deploy_web_server.ps1 -DryRun"