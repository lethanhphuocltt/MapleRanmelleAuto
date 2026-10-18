[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

# Visual C++ Redistributable (x86 + x64)
foreach ($arch in 'x86','x64') {
    $file = Join-Path $env:TEMP "vc_redist.$arch.exe"
    Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.$arch.exe" -OutFile $file
    Start-Process -FilePath $file -ArgumentList '/install','/quiet','/norestart' -Wait
}

# AutoHotkey v2
$ahk = Join-Path $env:TEMP 'ahk-v2.exe'
Invoke-WebRequest -Uri 'https://www.autohotkey.com/download/ahk-v2.exe' -OutFile $ahk
Start-Process -FilePath $ahk -ArgumentList '/silent' -Wait
