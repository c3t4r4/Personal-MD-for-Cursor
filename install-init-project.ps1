<#
.SYNOPSIS
  install-init-project.ps1 — Windows

.DESCRIPTION
  Instala (ou atualiza) o comando /init-project do Cursor a partir de uma pasta
  gerada por package-init-project.sh (ou do dist\ deste repositório).
  Equivalente ao install-init-project.sh de macOS/Linux: nunca sobrescreve um
  arquivo existente sem perguntar, arquivo por arquivo, com opção de ver o diff.

  Destino: %USERPROFILE%\.cursor (ou $env:CURSOR_CONFIG_DIR, se definido).

.PARAMETER PackageDir
  Pasta do pacote. Sem argumento, usa (nesta ordem):
    1. .\dist\init-project relativo a este script, se existir
    2. %USERPROFILE%\.cursor\initProjectsInstall\dist\init-project

.EXAMPLE
  .\install-init-project.ps1
  .\install-init-project.ps1 .\dist\init-project
  powershell -ExecutionPolicy Bypass -File .\install-init-project.ps1

.NOTES
  Compatível com Windows PowerShell 5.1 e PowerShell 7+. Evita recursos
  exclusivos do 7 (sem ??, sem ternário, sem -Parallel).
  _scan.sh e hooks\session-scan.sh são bash: no Windows rodam via Git Bash
  (bash.exe do Git for Windows) ou WSL. O instalador só copia e avisa.
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$PackageDir
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- caminhos

if ($env:CURSOR_CONFIG_DIR) {
  $CursorHome = $env:CURSOR_CONFIG_DIR
} else {
  $CursorHome = Join-Path $env:USERPROFILE '.cursor'
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoPackageDir = Join-Path $ScriptDir 'dist\init-project'
$DefaultPackageDir = Join-Path $CursorHome 'initProjectsInstall\dist\init-project'

# Mesma lista do install-init-project.sh. Manter os dois em sincronia.
$Files = @(
  'rules/personal-md-global.mdc',
  'commands/init-project.md',
  'templates/init-project/_scan.sh',
  'templates/init-project/_capacidades.md',
  'templates/init-project/_checklist-entrevista.md',
  'templates/init-project/_varredura-regras.md',
  'templates/init-project/API.md.tpl.md',
  'templates/init-project/Arquitetura.md.tpl.md',
  'templates/init-project/Auth.md.tpl.md',
  'templates/init-project/AGENTS.md.tpl.md',
  'templates/init-project/Frontend.md.tpl.md',
  'templates/init-project/Harness.md.tpl.md',
  'templates/init-project/Infraestrutura.md.tpl.md',
  'templates/init-project/Memoria.md.tpl.md',
  'templates/init-project/Organograma.md.tpl.md',
  'templates/init-project/Progresso.md.tpl.md',
  'templates/init-project/RAG.md.tpl.md',
  'templates/init-project/RegrasNegocio.md.tpl.md'
)

$OptionalFiles = @(
  'hooks/session-scan.sh',
  'hooks.json.snippet'
)

if ($PackageDir) {
  $ResolvedPackageDir = $PackageDir
} elseif (Test-Path -LiteralPath $RepoPackageDir -PathType Container) {
  $ResolvedPackageDir = $RepoPackageDir
} else {
  $ResolvedPackageDir = $DefaultPackageDir
}

if (-not (Test-Path -LiteralPath $ResolvedPackageDir -PathType Container)) {
  Write-Host "ERRO: pasta de pacote não encontrada: $ResolvedPackageDir" -ForegroundColor Red
  Write-Host ("Uso: {0} [caminho\para\pasta-do-pacote]" -f $MyInvocation.MyCommand.Name)
  Write-Host "Sem argumento, espera encontrar: $RepoPackageDir ou $DefaultPackageDir"
  exit 1
}
$ResolvedPackageDir = (Resolve-Path -LiteralPath $ResolvedPackageDir).Path

if (-not $PackageDir) {
  Write-Host "==> Nenhuma pasta informada. Usando: $ResolvedPackageDir"
}

# ----------------------------------------------------------- integridade

function Join-Rel {
  param([string]$Base, [string]$Rel)
  return Join-Path $Base ($Rel -replace '/', [IO.Path]::DirectorySeparatorChar)
}

$missing = @()
foreach ($rel in $Files) {
  if (-not (Test-Path -LiteralPath (Join-Rel $ResolvedPackageDir $rel) -PathType Leaf)) {
    $missing += $rel
  }
}

if ($missing.Count -gt 0) {
  Write-Host ("ERRO: a pasta não contém todos os {0} arquivos esperados:" -f $Files.Count) -ForegroundColor Red
  foreach ($m in $missing) { Write-Host "  - $m" -ForegroundColor Red }
  Write-Host "Abortando. Nada foi copiado para $CursorHome." -ForegroundColor Red
  exit 1
}

Write-Host ("==> OK: os {0} arquivos esperados estão presentes em {1}." -f $Files.Count, $ResolvedPackageDir)

foreach ($d in @('', 'commands', 'rules', 'templates\init-project', 'hooks')) {
  $p = Join-Path $CursorHome $d
  if (-not (Test-Path -LiteralPath $p -PathType Container)) {
    New-Item -ItemType Directory -Path $p -Force | Out-Null
  }
}

# ------------------------------------------------------------ interativo

# Sem terminal interativo (serviço, -NonInteractive, stdin redirecionado):
# arquivos existentes são pulados, nunca sobrescritos.
$HasTty = $true
try {
  if (-not [Environment]::UserInteractive) { $HasTty = $false }
  if ([Console]::IsInputRedirected) { $HasTty = $false }
  $cmdLine = [Environment]::CommandLine
  if ($cmdLine -and $cmdLine -match '(?i)-NonInteractive') { $HasTty = $false }
} catch {
  $HasTty = $false
}

if (-not $HasTty) {
  Write-Host 'AVISO: nenhuma sessão interativa disponível. Arquivos existentes serão pulados por padrão (sem sobrescrever).' -ForegroundColor Yellow
}

$script:installedNew = 0
$script:overwritten = 0
$script:skipped = 0

function Test-SameContent {
  param([string]$A, [string]$B)
  $ha = (Get-FileHash -LiteralPath $A -Algorithm SHA256).Hash
  $hb = (Get-FileHash -LiteralPath $B -Algorithm SHA256).Hash
  return ($ha -eq $hb)
}

function Show-Diff {
  param([string]$Existing, [string]$New)
  Write-Host '----- diff: existente (esquerda) vs. novo (direita) -----'
  $git = Get-Command git -ErrorAction SilentlyContinue
  if ($git) {
    & $git.Source --no-pager diff --no-index -- $Existing $New
  } else {
    $left = Get-Content -LiteralPath $Existing
    $right = Get-Content -LiteralPath $New
    $cmp = Compare-Object -ReferenceObject $left -DifferenceObject $right
    if ($cmp) {
      foreach ($c in $cmp) {
        if ($c.SideIndicator -eq '<=') { Write-Host ("- {0}" -f $c.InputObject) }
        else { Write-Host ("+ {0}" -f $c.InputObject) }
      }
    } else {
      Write-Host '(sem diferenças de conteúdo)'
    }
  }
  Write-Host '-----------------------------------------------------------'
}

function Install-One {
  param([string]$Rel, [bool]$Optional = $false)

  $src = Join-Rel $ResolvedPackageDir $Rel
  $dest = Join-Rel $CursorHome $Rel
  $destDir = Split-Path -Parent $dest
  if (-not (Test-Path -LiteralPath $destDir -PathType Container)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
  }

  if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
    if ($Optional) { return }
    throw "ERRO: fonte ausente: $src"
  }

  if (-not (Test-Path -LiteralPath $dest)) {
    # Copy-Item preserva bytes: scripts bash continuam com LF.
    Copy-Item -LiteralPath $src -Destination $dest
    $script:installedNew++
    Write-Host "  [novo]         $Rel"
    return
  }

  $idemNote = ''
  if (Test-SameContent $src $dest) { $idemNote = ' (idêntico ao existente)' }

  if (-not $HasTty) {
    $script:skipped++
    Write-Host "  [pulado, sem TTY]$idemNote $Rel"
    return
  }

  while ($true) {
    $answer = Read-Host "  $Rel$idemNote já existe. Sobrescrever? [s/N/d=ver diff]"
    if ($null -eq $answer) { $answer = '' }
    switch -Regex ($answer.Trim()) {
      '^[Dd]' { Show-Diff -Existing $dest -New $src; continue }
      '^[Ss]' {
        Copy-Item -LiteralPath $src -Destination $dest -Force
        $script:overwritten++
        Write-Host "  [sobrescrito]  $Rel"
        return
      }
      default {
        $script:skipped++
        Write-Host "  [mantido]      $Rel"
        return
      }
    }
  }
}

foreach ($rel in $Files) { Install-One -Rel $rel -Optional $false }
foreach ($rel in $OptionalFiles) { Install-One -Rel $rel -Optional $true }

$total = $script:installedNew + $script:overwritten + $script:skipped

Write-Host ''
Write-Host '==> Resumo da instalação'
Write-Host ("    Novos instalados : {0}" -f $script:installedNew)
Write-Host ("    Sobrescritos     : {0}" -f $script:overwritten)
Write-Host ("    Pulados/mantidos : {0}" -f $script:skipped)
Write-Host ("    Total processado : {0}" -f $total)
Write-Host ''
Write-Host "==> Destino: $CursorHome"

# -------------------------------------------------- verificação informativa

Write-Host ''
Write-Host '==> Verificação de componentes usados pelo /init-project'
Write-Host ''

function Read-YesNo {
  param([string]$Prompt)
  if (-not $HasTty) { return $false }
  $a = Read-Host $Prompt
  if ($null -eq $a) { return $false }
  return ($a.Trim() -match '^[Ss]')
}

Write-Host '-- Skills e agentes --'
$ScanSh = Join-Rel $CursorHome 'templates/init-project/_scan.sh'
# Prefere o bash do Git for Windows: o bash.exe de System32 é o do WSL e não
# enxerga caminhos do Windows sem conversão.
$bash = $null
foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA)) {
  if (-not $root) { continue }
  foreach ($sub in @('Git\bin\bash.exe', 'Programs\Git\bin\bash.exe')) {
    $candidate = Join-Path $root $sub
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      $bash = Get-Command $candidate
      break
    }
  }
  if ($bash) { break }
}
if (-not $bash) { $bash = Get-Command bash -ErrorAction SilentlyContinue }
if ($bash -and (Test-Path -LiteralPath $ScanSh -PathType Leaf)) {
  Write-Host ("ok: bash encontrado ({0}); rodando _scan.sh capacidades" -f $bash.Source)
  try {
    & $bash.Source $ScanSh capacidades
  } catch {
    Write-Host "AVISO: _scan.sh falhou via bash: $($_.Exception.Message)" -ForegroundColor Yellow
  }
} elseif (-not $bash) {
  Write-Host 'ausente: bash.exe não encontrado no PATH.' -ForegroundColor Yellow
  Write-Host '  _scan.sh (varredura de capacidades/projeto) e hooks\session-scan.sh são bash.'
  Write-Host '  Instale o Git for Windows (traz bash.exe) ou use o WSL com CURSOR_CONFIG_DIR apontando para o perfil do Windows,'
  Write-Host '  por exemplo: export CURSOR_CONFIG_DIR=/mnt/c/Users/<usuario>/.cursor'
  Write-Host '  Sem bash, o /init-project continua funcionando, mas sem a varredura automática.'
} else {
  Write-Host "AVISO: $ScanSh não encontrado — não foi possível checar skills/agentes." -ForegroundColor Yellow
}

Write-Host ''
Write-Host '-- RTK (Rust Token Killer) --'
$rtk = Get-Command rtk -ErrorAction SilentlyContinue
if ($rtk) {
  $rtkVersion = 'versão indisponível'
  try { $rtkVersion = (& $rtk.Source --version 2>$null | Select-Object -First 1) } catch { }
  Write-Host ("ok: rtk encontrado em {0} ({1})" -f $rtk.Source, $rtkVersion)
} else {
  Write-Host "ausente: binário 'rtk' não encontrado no PATH."
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if ($winget) {
    if (Read-YesNo '  Deseja instalar rtk agora via winget? [s/N]') {
      try { & $winget.Source install rtk-ai.rtk } catch { Write-Host '  ✗ Falha ao instalar rtk via winget' -ForegroundColor Yellow }
    } else {
      Write-Host '  ℹ Para instalar: winget install rtk-ai.rtk'
    }
  } else {
    Write-Host '  ℹ winget não encontrado. Para instalar: winget install rtk-ai.rtk (ou veja https://github.com/rtk-ai/rtk)'
  }
}

Write-Host ''
Write-Host '-- Skill archify --'
$archifySkill = Join-Rel $CursorHome 'skills/archify/SKILL.md'
if (Test-Path -LiteralPath $archifySkill -PathType Leaf) {
  Write-Host ("ok: archify instalado em {0}" -f (Split-Path -Parent $archifySkill))
} else {
  Write-Host "ausente: skill 'archify' não encontrada."
  $npx = Get-Command npx -ErrorAction SilentlyContinue
  $archifyCmd = 'npx -y skills add tt-a1i/archify --skill archify --agent cursor --global --copy --yes'
  if ($npx -and (Read-YesNo '  Deseja instalar archify agora? [s/N]')) {
    try {
      & $npx.Source -y skills add tt-a1i/archify --skill archify --agent cursor --global --copy --yes
      if (Test-Path -LiteralPath $archifySkill -PathType Leaf) {
        Write-Host '  ✓ archify instalado com sucesso'
      } else {
        Write-Host '  ✗ Arquivo de skill não encontrado após instalação (verifique path do agent)' -ForegroundColor Yellow
      }
    } catch {
      Write-Host '  ✗ Falha ao instalar archify' -ForegroundColor Yellow
    }
  } elseif (-not $npx) {
    Write-Host "  ✗ npx não encontrado. Instale Node.js (≥18) e rode: $archifyCmd"
  } else {
    Write-Host "  ℹ Para instalar: $archifyCmd"
  }
}

Write-Host ''
Write-Host '-- Hook sessionStart --'
$HooksJson = Join-Path $CursorHome 'hooks.json'
$Snippet = Join-Path $CursorHome 'hooks.json.snippet'
if (Test-Path -LiteralPath $HooksJson -PathType Leaf) {
  # Só procura a assinatura do hook; nunca imprime o conteúdo do arquivo.
  if (Select-String -LiteralPath $HooksJson -Pattern 'session-scan|sessionStart|_scan\.sh sessao' -Quiet) {
    Write-Host 'ok: hook de sessão / scan encontrado em hooks.json'
  } else {
    Write-Host 'ausente: nenhum hook sessionStart/scan em hooks.json'
    if (Test-Path -LiteralPath $Snippet -PathType Leaf) {
      Write-Host "  Veja $Snippet para um fragmento a mesclar manualmente."
    }
  }
} else {
  Write-Host "indisponivel: $HooksJson não encontrado — hook sessionStart não verificado."
  if (Test-Path -LiteralPath $Snippet -PathType Leaf) {
    Write-Host "  Fragmento disponível em $Snippet"
  }
}
Write-Host '  No Windows o hook depende de bash.exe acessível pelo Cursor — não verificado por este instalador.'

Write-Host ''
Write-Host '-- MCP de memória --'
Write-Host 'MCP de memória não é verificável por script — numa sessão do Cursor, testar list_corpora (claude-mem) ou memory_status (ai-memory). Basta um dos dois.'
Write-Host ("Instalação de cada backend: {0}" -f (Join-Rel $CursorHome 'templates/init-project/_capacidades.md'))
Write-Host ''
Write-Host '==> Instalação concluída. No Agent do Cursor, use /init-project na raiz de um projeto.'
exit 0
