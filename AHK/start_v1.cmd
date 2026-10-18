@echo off
rem Chay Maple Auto v1 (AutoHotkey 64-bit) roi mo launcher Ranmelle.exe. File nay nam trong thu muc AHK, game nam o thu muc cha.
set G=%~dp0..
start "" "%~dp0AutoHotkey64.exe" "%~dp0maple_auto_v1.ahk"
start "" /D "%G%" "%G%\Ranmelle.exe"
