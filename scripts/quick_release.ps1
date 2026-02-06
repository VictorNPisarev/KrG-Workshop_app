# Быстрый релиз с автоматическим patch update
param(
    [string]$RepoOwner = "VictorNPisarev",
    [string]$RepoName = "KrG-Workshop_app"
)

Write-Host "🚀 Быстрый релиз (автоматический patch update)..." -ForegroundColor Green

# Запускаем основной скрипт с флагом AutoPatch
.\release.ps1 -AutoPatch -RepoOwner $RepoOwner -RepoName $RepoName