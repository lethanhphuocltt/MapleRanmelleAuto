@echo off
rem Chay Maple Auto v1 (AutoHotkey 64-bit) roi mo launcher Ranmelle.exe.
rem File nay nam trong thu muc AHK. Ranmelle.exe duoc tim o thu muc cha, roi len toi da 3 cap nua.
set "G="
for %%D in ("%~dp0.." "%~dp0..\.." "%~dp0..\..\.." "%~dp0..\..\..\..") do if not defined G if exist "%%~fD\Ranmelle.exe" set "G=%%~fD"
if not defined G (
  echo Khong tim thay Ranmelle.exe o cac thu muc cha cua %~dp0
  pause
  exit /b 1
)
start "" "%~dp0AutoHotkey64.exe" "%~dp0maple_auto_v1.ahk"
start "" /D "%G%" "%G%\Ranmelle.exe"
