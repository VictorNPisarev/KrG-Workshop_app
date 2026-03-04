# workshop_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## RUN
**Chrome:** flutter run -d chrome --web-browser-flag "--disable-web-security"

## BUILD release
**Web:** flutter build web --release --no-tree-shake-icons
**Apk (push main с новой версией + публикация на Github):** .\scripts\release_w_push.ps1

## ЗАПУСК СЕРВЕРА
**Установить Node.js (если нет)** choco install nodejs -y
**Открыть порт в брандмауэре (один раз)** New-NetFirewallRule -DisplayName "Workshop App" -Direction Inbound -LocalPort 3030 -Protocol TCP -Action Allow
**Запустить сервер node.js**  npx http-server -p 3030 --host 0.0.0.0   //***запустить из папки со сборкой*** cd build/web

## ЗАПУСК СЕРВЕРА IIS
### Шаг 1: Включить IIS в Windows
#### Вариант А: Через PowerShell (админ)
```powershell
    ##### Запустить PowerShell от имени администратора

    # Включить IIS и все нужные компоненты
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebDAV
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-LoggingLibraries
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestMonitor
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpTracing
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementService
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementScriptingTools
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementService
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-IIS6ManagementCompatibility
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-Metabase
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HostableWebCore
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CertProvider
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-DigestAuthentication
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ClientCertificateMappingAuthentication
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-IISCertificateMappingAuthentication
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ODBCLogging
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-BasicAuthentication
```
#### Вариант Б: Через интерфейс Windows
    Открой Панель управления → Программы → Включение или отключение компонентов Windows
    Найди Internet Information Services и отметь галочкой
 
**Минимально необходимые компоненты:**
    Общие функции HTTP
    ☑ Документ по умолчанию
    ☑ Статическое содержимое
    ☐ Просмотр каталога (можно не включать, если не нужно)
    ☐ Ошибки HTTP (можно оставить)
    
    Проверка работоспособности и диагностика
    ☑ Ведение журнала HTTP (полезно для отладки)
    
    Средства управления веб-сайтом
    ☑ Консоль управления IIS (чтобы администрировать)
    Для Flutter особо ничего не нужно - просто раздача статики
    
### Шаг2: Проверить, что IIS работает
```powershell
    # Открыть браузер и перейти
    http://localhost
    # Должна открыться стартовая страница IIS
```
### Шаг 3: Создать папку для приложения
```powershell
    # Создать папку в стандартной директории IIS
    New-Item -ItemType Directory -Path "C:\inetpub\wwwroot\workshop_web" -Force
```
### Шаг 4: Собрать Web версию
```powershell
    # В папке твоего проекта
    cd C:\develop\workshop_app
    # Собрать
    flutter build web --release --no-tree-shake-icons
```
### Шаг 5: Скопировать файлы в папку IIS
```powershell
    # Скопировать собранные файлы
    Copy-Item -Path "build\web\*" -Destination "C:\inetpub\wwwroot\workshop_web" -Recurse -Force
```
### Шаг 6: Создать web.config в проекте
    см. файл проекта web/web.config (пока web.config.broken - отключен, т.к. в web.config IIS падает с ошибкой 500 и сайт не открывается, а без файла - все ОК)

### Шаг 7: Создать сайт в IIS (через PowerShell)
```powershell
    # Импортировать модуль IIS
    Import-Module IISAdministration

    # Удалить сайт по умолчанию (если мешает)
    # Remove-IISSite -Name "Default Web Site" -Confirm:$false

    # Создать новый сайт
    New-IISSite -Name "WorkshopWeb" -PhysicalPath "C:\inetpub\wwwroot\workshop_web" -BindingInformation "*:3030:"

    # Перезапустить IIS
    iisreset

    # Проверка списка сайтов IIS
    Get-IISSite
```
### Шаг 8: Открыть порт в брандмауэре
```powershell
    # PowerShell (админ)
    New-NetFirewallRule -DisplayName "Workshop App Local" -Direction Inbound -LocalPort 3030 -Protocol TCP -Action Allow
```
### Шаг 9: Проверить работу
**Открыть в браузере**
    http://localhost:3030/index.html
    http://192.168.1.xxx:3030/index.html - твой локальный IP
