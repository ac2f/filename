# Opsiyonel: Python kurulu olmayan bilgisayarlarda calisabilen tek dosyalik
# CdrAutoRenamer.exe uretmek icin bu betigi Windows uzerinde calistirin.
# Uretilen exe dist\CdrAutoRenamer.exe altinda olusur; onu istediginiz
# baslangic kisayoluna baglayabilirsiniz.
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

python -m pip install --upgrade pyinstaller
python -m pip install -r (Join-Path $ScriptDir "requirements.txt")
python -m PyInstaller --noconfirm --onefile --windowed --name CdrAutoRenamer (Join-Path $ScriptDir "src\app.py")

Write-Host "Derlenen exe: $(Join-Path $ScriptDir 'dist\CdrAutoRenamer.exe')"
