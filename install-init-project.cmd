@echo off
rem install-init-project.cmd - lancador do install-init-project.ps1 no Windows.
rem
rem Existe so para contornar a ExecutionPolicy: aplica "Bypass" apenas a este
rem processo, sem alterar a politica da maquina. Toda a logica de instalacao
rem fica no install-init-project.ps1 (mesma pasta).
rem
rem Uso:
rem   install-init-project.cmd [caminho\para\pasta-do-pacote]
rem
rem Prefere o PowerShell 7 (pwsh) quando instalado; senao usa o Windows
rem PowerShell 5.1, presente em qualquer Windows 10/11.

setlocal
set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%install-init-project.ps1"

if not exist "%PS1%" (
  echo ERRO: %PS1% nao encontrado. O .cmd precisa ficar na mesma pasta do .ps1.
  exit /b 1
)

where pwsh >nul 2>nul
if %ERRORLEVEL%==0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
)
exit /b %ERRORLEVEL%
