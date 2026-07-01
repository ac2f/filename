$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = Join-Path $env:LOCALAPPDATA "CdrAutoRenamer"

Write-Host "CDR Auto Renamer kuruluyor -> $InstallDir"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Copy-Item -Path (Join-Path $ScriptDir "src\*.py") -Destination $InstallDir -Force
Copy-Item -Path (Join-Path $ScriptDir "requirements.txt") -Destination $InstallDir -Force

$ConfigPath = Join-Path $InstallDir "config.json"
if (-not (Test-Path $ConfigPath)) {
    Copy-Item -Path (Join-Path $ScriptDir "config.example.json") -Destination $ConfigPath -Force
    Write-Host "Varsayilan ayar dosyasi olusturuldu: $ConfigPath"
} else {
    Write-Host "Mevcut ayar dosyasi korundu: $ConfigPath"
}

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Error "Python bulunamadi. Lutfen once https://www.python.org/downloads/ adresinden Python 3 kurun (kurulumda 'Add python.exe to PATH' kutusunu isaretleyin), ardindan bu kurulumu tekrar calistirin."
    exit 1
}

$VenvDir = Join-Path $InstallDir "venv"
if (-not (Test-Path $VenvDir)) {
    Write-Host "Sanal ortam olusturuluyor..."
    & python -m venv $VenvDir
}

$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
$VenvPythonw = Join-Path $VenvDir "Scripts\pythonw.exe"

Write-Host "Gerekli paketler kuruluyor..."
& $VenvPython -m pip install --upgrade pip | Out-Null
& $VenvPython -m pip install -r (Join-Path $InstallDir "requirements.txt")

$StartupDir = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupDir "CdrAutoRenamer.lnk"
$AppPath = Join-Path $InstallDir "app.py"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $VenvPythonw
$Shortcut.Arguments = '"' + $AppPath + '"'
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.Description = "CDR Auto Renamer - Windows baslangicinda otomatik calisir"
$Shortcut.Save()

Write-Host "Baslangicta otomatik calisma kisayolu olusturuldu: $ShortcutPath"

Write-Host "Uygulama simdi baslatiliyor..."
Start-Process -FilePath $VenvPythonw -ArgumentList ('"' + $AppPath + '"') -WorkingDirectory $InstallDir

Write-Host ""
Write-Host "Kurulum tamamlandi."
Write-Host "Ayarlari degistirmek icin: $ConfigPath"
Write-Host "Sistem tepsisindeki simgeye sag tiklayarak aktif/deaktif yapabilir, otomatik acma ozelliklerini yonetebilirsiniz."
