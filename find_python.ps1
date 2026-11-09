# install.ps1 ve build_exe.ps1 tarafindan kullanilan ortak yardimci betik.
#
# Bilgisayarda kurulu butun Python surumlerini bulur (Windows kayit defteri,
# "py" baslaticisi ve PATH uzerinden), her birini gercekten calistirip surum ve
# bit bilgisini dogrular, sonra en uygununu secer:
#   1) 64 bit olanlar once, 2) en guncel surum.
# Silinmis bir Python'dan kalan eski kayit defteri girdileri veya bozuk
# kisayollar calistirilamadigi icin otomatik olarak elenir.

$script:MinPythonVersion = [version]"3.9"

function Get-PythonInfo {
    param([string]$Path)

    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }

    # Python stderr'e uyari yazsa bile yutulsun, betigin "Stop" modu patlatmasin.
    $ErrorActionPreference = "Continue"
    try {
        $out = & $Path -c "import sys, struct; print(sys.version_info[0], sys.version_info[1], sys.version_info[2], struct.calcsize('P') * 8)" 2>$null
    } catch {
        return $null
    }
    if ($LASTEXITCODE -ne 0 -or -not $out) { return $null }

    $parts = ("$out").Trim() -split '\s+'
    if ($parts.Count -ne 4) { return $null }

    [pscustomobject]@{
        Path    = (Resolve-Path -LiteralPath $Path).Path
        Version = [version]("{0}.{1}.{2}" -f $parts[0], $parts[1], $parts[2])
        Bits    = [int]$parts[3]
    }
}

function Get-PythonCandidatePaths {
    $paths = @()

    # 1) Kayit defteri (python.org kurulumlari). Silinmis surumlerden kalan
    #    girdiler olabilir; Get-PythonInfo bunlari eler.
    $roots = @(
        "HKCU:\SOFTWARE\Python\PythonCore",
        "HKLM:\SOFTWARE\Python\PythonCore",
        "HKLM:\SOFTWARE\WOW6432Node\Python\PythonCore"
    )
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        foreach ($key in Get-ChildItem $root -ErrorAction SilentlyContinue) {
            $ip = Get-ItemProperty -Path "$($key.PSPath)\InstallPath" -ErrorAction SilentlyContinue
            if (-not $ip) { continue }
            if ($ip.ExecutablePath) {
                $paths += $ip.ExecutablePath
            } elseif ($ip.'(default)') {
                $paths += (Join-Path $ip.'(default)' "python.exe")
            }
        }
    }

    # 2) "py" baslaticisi: py -0p kurulu butun Python'larin yolunu listeler.
    if (Get-Command py -ErrorAction SilentlyContinue) {
        $ErrorActionPreference = "Continue"
        $lines = & py -0p 2>$null
        foreach ($line in $lines) {
            if ("$line" -match '([A-Za-z]:\\.*?\.exe)\s*$') { $paths += $Matches[1] }
        }
    }

    # 3) PATH
    foreach ($cmd in @(Get-Command python -All -CommandType Application -ErrorAction SilentlyContinue)) {
        $paths += $cmd.Source
    }

    return $paths
}

function Find-Python {
    $candidates = @(Get-PythonCandidatePaths | Where-Object { $_ } | Sort-Object -Unique)

    # Microsoft Store "python.exe" kisayolu Python kurulu degilse Store'u acabilir;
    # bu yuzden sadece baska hicbir Python bulunamazsa denenir.
    $storeAlias = @($candidates | Where-Object { $_ -like "*\Microsoft\WindowsApps\*" })
    $normal     = @($candidates | Where-Object { $_ -notlike "*\Microsoft\WindowsApps\*" })

    foreach ($group in @($normal, $storeAlias)) {
        $found = @($group |
            ForEach-Object { Get-PythonInfo $_ } |
            Where-Object { $_ -and $_.Version -ge $script:MinPythonVersion })
        if ($found.Count -gt 0) {
            return ($found |
                Sort-Object -Property `
                    @{ Expression = { $_.Bits -eq 64 }; Descending = $true }, `
                    @{ Expression = { $_.Version };     Descending = $true } |
                Select-Object -First 1)
        }
    }

    return $null
}
