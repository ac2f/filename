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

. (Join-Path $ScriptDir "find_python.ps1")

# Kurulu Python'lar arasindan en uygununu (64 bit, en guncel surum) sec.
$python = Find-Python
if (-not $python) {
    Write-Error "Uygun Python bulunamadi (Python $script:MinPythonVersion veya daha yenisi gerekli). Lutfen once https://www.python.org/downloads/ adresinden Python 3 (64 bit) kurun, ardindan bu kurulumu tekrar calistirin."
    exit 1
}
Write-Host ("Kullanilacak Python: {0} ({1} bit) -> {2}" -f $python.Version, $python.Bits, $python.Path)

$VenvDir = Join-Path $InstallDir "venv"
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
$VenvPythonw = Join-Path $VenvDir "Scripts\pythonw.exe"

# Daha once olusturulmus sanal ortam silinmis/degismis bir Python'a bagliysa
# (ornegin kaldirilan eski surum) veya secilen Python'dan farkliysa yeniden olustur.
if (Test-Path $VenvDir) {
    $venvInfo = Get-PythonInfo $VenvPython
    $venvStale = (-not $venvInfo) `
        -or ($venvInfo.Version.Major -ne $python.Version.Major) `
        -or ($venvInfo.Version.Minor -ne $python.Version.Minor) `
        -or ($venvInfo.Bits -ne $python.Bits)
    if ($venvStale) {
        Write-Host "Mevcut sanal ortam eski/bozuk bir Python'a bagli, yeniden olusturuluyor..."
        Get-Process pythonw -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$InstallDir*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Remove-Item $VenvDir -Recurse -Force
    }
}

if (-not (Test-Path $VenvDir)) {
    Write-Host "Sanal ortam olusturuluyor..."
    & $python.Path -m venv $VenvDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Sanal ortam olusturulamadi."
        exit 1
    }
}

Write-Host "Gerekli paketler kuruluyor..."
& $VenvPython -m pip install --upgrade pip | Out-Null
& $VenvPython -m pip install -r (Join-Path $InstallDir "requirements.txt")
if ($LASTEXITCODE -ne 0) {
    Write-Error "Gerekli paketler kurulamadi."
    exit 1
}

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
