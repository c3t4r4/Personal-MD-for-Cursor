# Arquitetura — Personal-MD-for-Cursor

Última atualização: 2026-10-15

## Papel deste repositório

Este repositório é a **fonte** da governança Personal-MD para o Cursor e o meio de levá-la a outra máquina. Não há serviço em execução, aplicação, banco nem API. O diagrama do fluxo de instalação está em `docs/arquitetura.html` (gerado pela skill `archify` a partir de `docs/archify/instalacao.workflow.json`).

## Stack

- Bash (`install-init-project.sh`, `package-init-project.sh`, `templates/init-project/_scan.sh`, `hooks/session-scan.sh`), com `set -uo pipefail` e `shellcheck` limpo.
- PowerShell 5.1+ (`install-init-project.ps1`), UTF-8 com BOM, sem recursos exclusivos do PowerShell 7.
- Markdown e MDC (regra global, comando, templates).
- `python3` opcional: usado por `_scan.sh` para ler JSON (`mcp.json`, plugins) e pelo hook para montar o `followup_message`; sem ele, há fallback degradado.

## Peças

| Peça | Função |
| --- | --- |
| `package-init-project.sh` | Lê os 18 arquivos de `~/.cursor` (ou do próprio repo com `PACKAGE_FROM_REPO=1`) e publica `dist/init-project/`. |
| `dist/init-project/` | O pacote. A estrutura relativa é a mesma do destino (`rules/`, `commands/`, `templates/init-project/`, `hooks/`). |
| `install-init-project.sh` | Instala o pacote em `~/.cursor` no macOS e no Linux. |
| `install-init-project.ps1` | Instala o mesmo pacote em `%USERPROFILE%\.cursor` no Windows. |
| `install-init-project.cmd` | Lançador do `.ps1`: `ExecutionPolicy Bypass` só no processo, prefere `pwsh`, cai para `powershell` 5.1. Sem lógica própria. |
| `rules/personal-md-global.mdc` | Regra global `alwaysApply`: fluxo, harness, sincronização de 12 documentos, memória (dois backends), preferências de stack, Performance, segurança. Fonte única da tabela de gatilhos. |
| `commands/init-project.md` | Comando `/init-project` (FASES 0–8; modos `--check`, `--update`, `--rag`, `--regras`). |
| `templates/init-project/*.md.tpl.md` | 12 templates: `AGENTS.md` e os 11 `docs/*`. |
| `templates/init-project/_scan.sh` | Varredura em bash: `capacidades` (agentes, skills, MCPs por nome, plugins, marketplaces, binários), `projeto [--no-cache]` (manifestos, locks, qualidade, Docker, código, testes, governança, Git), `sessao` (resumo curto para o hook). |
| `templates/init-project/_capacidades.md`, `_checklist-entrevista.md`, `_varredura-regras.md` | Apoio ao comando: instalação de capacidades ausentes, cobertura da entrevista, procedimento do modo `--regras`. |
| `hooks/session-scan.sh` + `hooks.json.snippet` | Hook `sessionStart` opcional: roda `_scan.sh sessao` e devolve `followup_message`. |
| `.gitattributes` | LF para `.sh`, `.md`, `.mdc`, `.json`; CRLF para `.ps1` e `.cmd`. |

## Fluxo de instalação

1. O usuário entrega a pasta do pacote, ou o script usa `./dist/init-project` relativo a si, ou `<destino>/initProjectsInstall/dist/init-project`.
2. Os 18 arquivos são conferidos. Qualquer ausência encerra o processo antes da cópia (RN-INSTALADOR-001).
3. Cada arquivo novo é copiado. Cada arquivo já presente espera `s`, `N` ou `d`; sem terminal, permanece (RN-INSTALADOR-003/004).
4. O resumo imprime contagens. Em seguida o relatório de capacidades, RTK, archify, hook e backend de memória roda sem mudar o código de saída (RN-INSTALADOR-005).

O destino é `CURSOR_CONFIG_DIR` quando definido — a mesma variável que `hooks/session-scan.sh` usa — o que permite testar os dois instaladores em pastas temporárias e usar WSL apontando para o perfil do Windows.

## Camadas de governança

```text
~/.cursor/rules/personal-md-global.mdc   (prioridade 2 — sempre injetada)
        │  referencia
        ├── ~/.cursor/RTK.md
        └── ~/.cursor/commands/init-project.md
                │  usa
                └── ~/.cursor/templates/init-project/*
                        │  gera, em cada projeto
                        └── ./AGENTS.md + ./docs/* + README.md  (prioridade 3–4)
```

A tabela de sincronização (12 documentos) existe em quatro cópias que devem ser idênticas (RN-PACOTE-002). A lista dos 18 arquivos existe em três (RN-PACOTE-001).

## Decisões

- **Pasta, não zip.** O pacote é copiado por USB, rede ou clone; o instalador valida antes de copiar.
- **Mesmo `.sh` para macOS e Linux.** O Cursor usa `~/.cursor` nos dois; só bash e coreutils são exigidos.
- **PowerShell 5.1 como piso no Windows.** Já vem no Windows 10/11; o script evita `??`, ternário e `-Parallel`. BOM UTF-8 obrigatório para o 5.1 ler acentos. O `.cmd` existe para a ExecutionPolicy, não para duplicar a lógica de cópia.
- **`_scan.sh` não foi portado.** No Windows roda via Git Bash (preferido) ou WSL; sem bash, a cópia continua válida e a varredura degrada.
- **Dois backends de memória** (`claude-mem`, `ai-memory`) detectados por chamada MCP, nunca instalados pelo comando.
- **Preferências de stack são sugestão**, nunca aplicação automática — mesmo em projeto novo.
- **Segurança por construção:** nenhum script imprime `mcp.json`, `hooks.json` ou `.env`; `_scan.sh` lista só nomes de servidores MCP.

## Histórico

| Data | Alteração |
| --- | --- |
| 2026-10-06 | Versão original no repositório irmão (Claude Code), com instalador Windows. |
| 2026-10-15 | Reescrito para o Cursor: destino `~/.cursor`, `CURSOR_CONFIG_DIR`, sem `.cmd`, peças do pacote detalhadas, camadas de governança, decisões atualizadas; `docs/arquitetura.html` regenerado. |
| 2026-10-15 | Lançador `install-init-project.cmd` adicionado às peças; `.gitattributes` cobre `.cmd`; `docs/arquitetura.html` regenerado. |
