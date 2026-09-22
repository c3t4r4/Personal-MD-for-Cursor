#!/usr/bin/env bash
#
# package-init-project.sh
#
# Empacota o comando /init-project (regra global + commands/init-project.md)
# e seus arquivos de suporte (templates/init-project/*) em uma pasta simples
# — sem zip — pronta para copiar para outra máquina e instalar com
# install-init-project.sh.
#
# Uso:
#   ./package-init-project.sh
#   # ou, após instalado:
#   ~/.cursor/initProjectsInstall/package-init-project.sh
#
# Por padrão, a origem é ~/.cursor. Para empacotar a partir do dist deste
# repositório (sem precisar ter instalado antes):
#   PACKAGE_FROM_REPO=1 ./package-init-project.sh
#
# A cada execução, ~/.cursor/initProjectsInstall/dist/init-project/ é
# substituída inteiramente — não guarda histórico de versões anteriores.

set -euo pipefail

CURSOR_HOME="${HOME}/.cursor"
INSTALL_DIR="${CURSOR_HOME}/initProjectsInstall"
DIST_DIR="${INSTALL_DIR}/dist"
PACKAGE_DIR="${DIST_DIR}/init-project"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIST="${SCRIPT_DIR}/dist/init-project"

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

if [[ "${PACKAGE_FROM_REPO:-0}" == "1" ]]; then
  SOURCE_ROOT="${REPO_DIST}"
else
  SOURCE_ROOT="${CURSOR_HOME}"
fi

echo "==> Verificando integridade dos ${#FILES[@]} arquivos de origem em ${SOURCE_ROOT}"

missing=()
for rel in "${FILES[@]}"; do
  if [[ ! -f "${SOURCE_ROOT}/${rel}" ]]; then
    missing+=("${rel}")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo "ERRO: ${#missing[@]} arquivo(s) esperado(s) não encontrado(s):" >&2
  for m in "${missing[@]}"; do
    echo "  - ${SOURCE_ROOT}/${m}" >&2
  done
  echo "Abortando. Nenhum pacote foi gerado." >&2
  echo "Dica: PACKAGE_FROM_REPO=1 $0  empacota a partir de ${REPO_DIST}" >&2
  exit 1
fi

echo "==> OK: todos os ${#FILES[@]} arquivos encontrados."

mkdir -p "${DIST_DIR}"

STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "${STAGE_DIR}"' EXIT

for rel in "${FILES[@]}"; do
  dest="${STAGE_DIR}/${rel}"
  mkdir -p "$(dirname "${dest}")"
  if command -v ditto >/dev/null 2>&1; then
    ditto "${SOURCE_ROOT}/${rel}" "${dest}"
  else
    cp -p "${SOURCE_ROOT}/${rel}" "${dest}"
  fi
done

for rel in "${OPTIONAL_FILES[@]}"; do
  src=""
  if [[ -f "${SOURCE_ROOT}/${rel}" ]]; then
    src="${SOURCE_ROOT}/${rel}"
  elif [[ -f "${REPO_DIST}/${rel}" ]]; then
    src="${REPO_DIST}/${rel}"
  fi
  if [[ -n "${src}" ]]; then
    dest="${STAGE_DIR}/${rel}"
    mkdir -p "$(dirname "${dest}")"
    cp -p "${src}" "${dest}"
  fi
done

chmod 755 "${STAGE_DIR}/templates/init-project/_scan.sh"
if [[ -f "${STAGE_DIR}/hooks/session-scan.sh" ]]; then
  chmod 755 "${STAGE_DIR}/hooks/session-scan.sh"
fi

echo "==> Publicando em ${PACKAGE_DIR}"

if [[ -e "${PACKAGE_DIR}" ]]; then
  rm -rf "${PACKAGE_DIR}"
fi

mv "${STAGE_DIR}" "${PACKAGE_DIR}"
trap - EXIT

# Se empacotou de ~/.cursor e este script está no repositório, espelhar no dist/
if [[ "${PACKAGE_FROM_REPO:-0}" != "1" ]] && [[ -f "${SCRIPT_DIR}/install-init-project.sh" ]]; then
  echo "==> Espelhando em ${REPO_DIST}"
  mkdir -p "$(dirname "${REPO_DIST}")"
  rm -rf "${REPO_DIST}"
  if command -v ditto >/dev/null 2>&1; then
    ditto "${PACKAGE_DIR}" "${REPO_DIST}"
  else
    cp -a "${PACKAGE_DIR}" "${REPO_DIST}"
  fi
fi

echo "==> Concluído."
echo "==> Pasta: ${PACKAGE_DIR}"
echo "==> Conteúdo:"
( cd "${PACKAGE_DIR}" && find . -type f | sed 's|^\./||' | sort )
