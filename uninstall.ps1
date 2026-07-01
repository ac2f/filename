$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $env:LOCALAPPDATA "CdrAutoRenamer"
$StartupDir = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupDir "CdrAutoRenamer.lnk"

Write-Host "CDR Auto Renamer kaldiriliyor..."

Get-Process pythonw -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$InstallDir*" } | Stop-Process -Force -ErrorAction SilentlyContinue

if (Test-Path $ShortcutPath) {
    Remove-Item $ShortcutPath -Force
    Write-Host "Baslangic kisayolu kaldirildi."
} else {
    Write-Host "Baslangic kisayolu zaten yoktu."
}

$response = Read-Host "Ayar ve program dosyalari da silinsin mi? (E/H)"
if ($response -match '^[EeYy]') {
    if (Test-Path $InstallDir) {
        Remove-Item $InstallDir -Recurse -Force
        Write-Host "Kurulum klasoru silindi: $InstallDir"
    }
} else {
    Write-Host "Kurulum klasoru korundu: $InstallDir"
}

Write-Host "Kaldirma tamamlandi."
