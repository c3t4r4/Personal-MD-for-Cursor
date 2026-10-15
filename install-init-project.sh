#!/usr/bin/env bash
#
# install-init-project.sh — macOS e Linux
#
# Instala (ou atualiza) o comando /init-project do Cursor a partir de uma pasta
# gerada por package-init-project.sh (ou do dist/ deste repositório).
# O Cursor usa ~/.cursor/ nos dois sistemas; no Windows, usar
# install-init-project.ps1.
# Destino: $CURSOR_CONFIG_DIR, se definido; senão ~/.cursor (mesma regra do
# .ps1 e do hook session-scan.sh). Útil em WSL e em testes.
# Nunca sobrescreve um arquivo existente sem perguntar, arquivo por arquivo,
# com opção de ver o diff antes de decidir.
#
# Uso:
#   install-init-project.sh [caminho/para/pasta-do-pacote]
#
# Sem argumento, usa (nesta ordem):
#   1. ./dist/init-project/ relativo a este script, se existir
#   2. ~/.cursor/initProjectsInstall/dist/init-project/

set -uo pipefail
# Sem "set -e" de propósito: o laço de perguntas interativas usa "read" e
# "diff", que retornam status != 0 em casos normais.

CURSOR_HOME="${CURSOR_CONFIG_DIR:-${HOME}/.cursor}"
DIST_DIR="${CURSOR_HOME}/initProjectsInstall/dist"
DEFAULT_PACKAGE_DIR="${DIST_DIR}/init-project"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PACKAGE_DIR="${SCRIPT_DIR}/dist/init-project"

FILES=(
  "rules/personal-md-global.mdc"
  "commands/init-project.md"
  "templates/init-project/_scan.sh"
  "templates/init-project/_capacidades.md"
  "templates/init-project/_checklist-entrevista.md"
  "templates/init-project/_varredura-regras.md"
  "templates/init-project/API.md.tpl.md"
  "templates/init-project/Arquitetura.md.tpl.md"
  "templates/init-project/Auth.md.tpl.md"
  "templates/init-project/AGENTS.md.tpl.md"
  "templates/init-project/Frontend.md.tpl.md"
  "templates/init-project/Harness.md.tpl.md"
  "templates/init-project/Infraestrutura.md.tpl.md"
  "templates/init-project/Memoria.md.tpl.md"
  "templates/init-project/Organograma.md.tpl.md"
  "templates/init-project/Progresso.md.tpl.md"
  "templates/init-project/RAG.md.tpl.md"
  "templates/init-project/RegrasNegocio.md.tpl.md"
)

OPTIONAL_FILES=(
  "hooks/session-scan.sh"
  "hooks.json.snippet"
)

if [[ -n "${1:-}" ]]; then
  PACKAGE_DIR="$1"
elif [[ -d "${REPO_PACKAGE_DIR}" ]]; then
  PACKAGE_DIR="${REPO_PACKAGE_DIR}"
else
  PACKAGE_DIR="${DEFAULT_PACKAGE_DIR}"
fi

if [[ ! -d "${PACKAGE_DIR}" ]]; then
  echo "ERRO: pasta de pacote não encontrada: ${PACKAGE_DIR}" >&2
  echo "Uso: $0 [caminho/para/pasta-do-pacote]" >&2
  echo "Sem argumento, espera encontrar: ${REPO_PACKAGE_DIR} ou ${DEFAULT_PACKAGE_DIR}" >&2
  exit 1
fi

if [[ -z "${1:-}" ]]; then
  echo "==> Nenhuma pasta informada. Usando: ${PACKAGE_DIR}"
fi

missing=()
for rel in "${FILES[@]}"; do
  if [[ ! -f "${PACKAGE_DIR}/${rel}" ]]; then
    missing+=("${rel}")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo "ERRO: a pasta não contém todos os ${#FILES[@]} arquivos esperados:" >&2
  for m in "${missing[@]}"; do
    echo "  - ${m}" >&2
  done
  echo "Abortando. Nada foi copiado para ${CURSOR_HOME}." >&2
  exit 1
fi

echo "==> OK: os ${#FILES[@]} arquivos esperados estão presentes em ${PACKAGE_DIR}."

mkdir -p "${CURSOR_HOME}"
mkdir -p "${CURSOR_HOME}/commands"
mkdir -p "${CURSOR_HOME}/rules"
mkdir -p "${CURSOR_HOME}/templates/init-project"
mkdir -p "${CURSOR_HOME}/hooks"

installed_new=0
overwritten=0
skipped=0

HAS_TTY=1
if { exec 3< /dev/tty; } 2>/dev/null; then
  exec 3<&-
else
  HAS_TTY=0
  echo "AVISO: nenhum terminal interativo disponível (/dev/tty não pôde ser aberto). Arquivos existentes serão pulados por padrão (sem sobrescrever)." >&2
fi

install_one() {
  local rel="$1"
  local optional="${2:-0}"
  local src="${PACKAGE_DIR}/${rel}"
  local dest="${CURSOR_HOME}/${rel}"
  local dest_dir
  dest_dir="$(dirname "${dest}")"
  mkdir -p "${dest_dir}"

  if [[ ! -f "${src}" ]]; then
    if [[ "${optional}" -eq 1 ]]; then
      return 0
    fi
    echo "ERRO: fonte ausente: ${src}" >&2
    return 1
  fi

  if [[ ! -e "${dest}" ]]; then
    cp -p "${src}" "${dest}"
    installed_new=$((installed_new + 1))
    echo "  [novo]         ${rel}"
    return 0
  fi

  local idem_note=""
  if cmp -s "${src}" "${dest}"; then
    idem_note=" (idêntico ao existente)"
  fi

  if [[ "${HAS_TTY}" -eq 0 ]]; then
    skipped=$((skipped + 1))
    echo "  [pulado, sem TTY]${idem_note} ${rel}"
    return 0
  fi

  while true; do
    local answer=""
    if ! read -r -p "  ${rel}${idem_note} já existe. Sobrescrever? [s/N/d=ver diff] " answer < /dev/tty; then
      skipped=$((skipped + 1))
      echo "  [pulado, leitura falhou] ${rel}"
      break
    fi
    case "${answer}" in
      [Dd]*)
        echo "----- diff: existente (esquerda) vs. novo (direita) -----"
        diff -u "${dest}" "${src}" || true
        echo "-----------------------------------------------------------"
        continue
        ;;
      [Ss]*)
        cp -p "${src}" "${dest}"
        overwritten=$((overwritten + 1))
        echo "  [sobrescrito]  ${rel}"
        break
        ;;
      *)
        skipped=$((skipped + 1))
        echo "  [mantido]      ${rel}"
        break
        ;;
    esac
  done
}

for rel in "${FILES[@]}"; do
  install_one "${rel}" 0
done

for rel in "${OPTIONAL_FILES[@]}"; do
  install_one "${rel}" 1
done

SCAN_SH="${CURSOR_HOME}/templates/init-project/_scan.sh"
if [[ -f "${SCAN_SH}" ]]; then
  chmod 755 "${SCAN_SH}"
fi
if [[ -f "${CURSOR_HOME}/hooks/session-scan.sh" ]]; then
  chmod 755 "${CURSOR_HOME}/hooks/session-scan.sh"
fi

total=$(( installed_new + overwritten + skipped ))

echo ""
echo "==> Resumo da instalação"
echo "    Novos instalados : ${installed_new}"
echo "    Sobrescritos     : ${overwritten}"
echo "    Pulados/mantidos : ${skipped}"
echo "    Total processado : ${total}"
echo ""
echo "==> Destino: ${CURSOR_HOME}"

echo ""
echo "==> Verificação de componentes usados pelo /init-project"
echo ""

case "$(uname -s)" in
  Darwin*) OS_KIND="macos" ;;
  Linux*)  OS_KIND="linux" ;;
  CYGWIN*|MINGW*|MSYS*) OS_KIND="windows" ;;
  *) OS_KIND="desconhecido" ;;
esac

echo "-- Skills e agentes --"
if [[ -x "${SCAN_SH}" ]]; then
  "${SCAN_SH}" capacidades
else
  echo "AVISO: ${SCAN_SH} não encontrado ou não executável — não foi possível checar skills/agentes." >&2
fi

echo ""
echo "-- RTK (Rust Token Killer) --"
if command -v rtk >/dev/null 2>&1; then
  RTK_PATH="$(command -v rtk)"
  RTK_VERSION="$(rtk --version 2>/dev/null || echo "versão indisponível")"
  echo "ok: rtk encontrado em ${RTK_PATH} (${RTK_VERSION})"
else
  echo "ausente: binário 'rtk' não encontrado no PATH."
  if [[ "${HAS_TTY}" -eq 1 ]] && [[ "${OS_KIND}" != "desconhecido" ]]; then
    answer=""
    if read -r -p "  Deseja instalar rtk agora? [s/N] " answer < /dev/tty; then
      if [[ "${answer}" == [Ss]* ]]; then
        case "${OS_KIND}" in
          macos)
            if command -v brew >/dev/null 2>&1; then
              brew install rtk || echo "  ✗ Falha ao instalar rtk via brew"
            else
              echo "  ✗ Homebrew não encontrado. Instale com: brew install rtk"
            fi
            ;;
          linux)
            curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh || echo "  ✗ Falha ao instalar rtk"
            ;;
          windows)
            if command -v winget >/dev/null 2>&1; then
              winget install rtk-ai.rtk || echo "  ✗ Falha ao instalar rtk via winget"
            else
              echo "  ✗ winget não encontrado."
            fi
            ;;
        esac
      fi
    fi
  else
    # Sem TTY (ou SO desconhecido): só informa o comando manual, como o .ps1.
    case "${OS_KIND}" in
      macos)   echo "  ℹ Para instalar: brew install rtk" ;;
      linux)   echo "  ℹ Para instalar: curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh" ;;
      windows) echo "  ℹ Para instalar: winget install rtk-ai.rtk" ;;
      *)       echo "  ℹ Para instalar: veja https://github.com/rtk-ai/rtk" ;;
    esac
  fi
fi

echo ""
echo "-- Skill archify --"
if [[ -f "${CURSOR_HOME}/skills/archify/SKILL.md" ]]; then
  echo "ok: archify instalado em ${CURSOR_HOME}/skills/archify"
else
  echo "ausente: skill 'archify' não encontrada."
  if [[ "${HAS_TTY}" -eq 1 ]]; then
    answer=""
    if read -r -p "  Deseja instalar archify agora? [s/N] " answer < /dev/tty; then
      if [[ "${answer}" == [Ss]* ]]; then
        if command -v npx >/dev/null 2>&1; then
          if npx -y skills add tt-a1i/archify --skill archify --agent cursor --global --copy --yes; then
            if [[ -f "${CURSOR_HOME}/skills/archify/SKILL.md" ]]; then
              echo "  ✓ archify instalado com sucesso"
            else
              echo "  ✗ Arquivo de skill não encontrado após instalação (verifique path do agent)"
            fi
          else
            echo "  ✗ Falha ao instalar archify"
          fi
        else
          echo "  ✗ npx não encontrado. Instale Node.js (≥18)."
        fi
      fi
    fi
  else
    echo "  ℹ Para instalar: npx -y skills add tt-a1i/archify --skill archify --agent cursor --global --copy --yes"
  fi
fi

HOOKS_JSON="${CURSOR_HOME}/hooks.json"
if [[ -f "${HOOKS_JSON}" ]]; then
  if grep -q "session-scan\|sessionStart\|_scan.sh sessao" "${HOOKS_JSON}" 2>/dev/null; then
    echo "ok: hook de sessão / scan encontrado em hooks.json"
  else
    echo "ausente: nenhum hook sessionStart/scan em hooks.json"
    if [[ -f "${CURSOR_HOME}/hooks.json.snippet" ]]; then
      echo "  Veja ${CURSOR_HOME}/hooks.json.snippet para um fragmento a mesclar manualmente."
    fi
  fi
else
  echo "indisponivel: ${HOOKS_JSON} não encontrado — hook sessionStart não verificado."
  if [[ -f "${CURSOR_HOME}/hooks.json.snippet" ]]; then
    echo "  Fragmento disponível em ${CURSOR_HOME}/hooks.json.snippet"
  fi
fi

echo ""
echo "-- MCP de memória --"
echo "MCP de memória não é verificável por script — numa sessão do Cursor, testar list_corpora (claude-mem) ou memory_status (ai-memory). Basta um dos dois."
echo "Instalação de cada backend: ${CURSOR_HOME}/templates/init-project/_capacidades.md"
echo ""
echo "==> Instalação concluída. No Agent do Cursor, use /init-project na raiz de um projeto."
