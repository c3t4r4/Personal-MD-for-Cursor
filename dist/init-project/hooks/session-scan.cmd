@echo off
setlocal EnableExtensions
rem Entrada Windows do hook sessionStart. O hooks.json aponta para este
rem cmd, nunca para session-scan.sh. Stdin passa direto ao bash. Sai 0
rem mesmo sem Git Bash, para nao bloquear a abertura da sessao.

set "BASH="
if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" set "BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not defined BASH if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" set "BASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not defined BASH (
  for /f "delims=" %%B in ('where bash 2^>nul') do (
    echo %%B | findstr /I /C:"\System32\" >nul
    if errorlevel 1 if not defined BASH set "BASH=%%B"
  )
)
if not defined BASH (
  echo {}
  exit /b 0
)
if not exist "%~dp0session-scan.sh" (
  echo {}
  exit /b 0
)
"%BASH%" "%~dp0session-scan.sh"
exit /b 0
