# Opsiyonel: Python kurulu olmayan bilgisayarlarda calisabilen tek dosyalik
# CdrAutoRenamer.exe uretmek icin bu betigi Windows uzerinde calistirin.
# Uretilen exe dist\CdrAutoRenamer.exe altinda olusur; onu istediginiz
# baslangic kisayoluna baglayabilirsiniz.
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. (Join-Path $ScriptDir "find_python.ps1")

$python = Find-Python
if (-not $python) {
    Write-Error "Uygun Python bulunamadi (Python $script:MinPythonVersion veya daha yenisi gerekli). Lutfen once https://www.python.org/downloads/ adresinden Python 3 (64 bit) kurun."
    exit 1
}
Write-Host ("Kullanilacak Python: {0} ({1} bit) -> {2}" -f $python.Version, $python.Bits, $python.Path)

& $python.Path -m pip install --upgrade pyinstaller
& $python.Path -m pip install -r (Join-Path $ScriptDir "requirements.txt")
& $python.Path -m PyInstaller --noconfirm --onefile --windowed --name CdrAutoRenamer (Join-Path $ScriptDir "src\app.py")

Write-Host "Derlenen exe: $(Join-Path $ScriptDir 'dist\CdrAutoRenamer.exe')"
