@echo off
setlocal EnableExtensions
rem Entrada Windows de _scan.sh. Nao reimplementa a varredura: acha o
rem bash do Git for Windows e delega. Nao usa o bash.exe de System32
rem (WSL), que nao enxerga caminho do Windows. Sem Git Bash, sai 0
rem com um aviso: a sessao e o /init-project degradam, nao falham sempre.

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
  echo ausente: Git Bash nao encontrado. A varredura foi pulada. 1>&2
  exit /b 0
)
if not exist "%~dp0_scan.sh" (
  echo ausente: _scan.sh nao encontrado ao lado de scan.cmd. 1>&2
  exit /b 0
)
"%BASH%" "%~dp0_scan.sh" %*
exit /b %ERRORLEVEL%
