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
| `package-init-project.sh` | Lê os 20 arquivos de `~/.cursor` (ou do próprio repo com `PACKAGE_FROM_REPO=1`) e publica `dist/init-project/`. |
| `dist/init-project/` | O pacote. A estrutura relativa é a mesma do destino (`rules/`, `commands/`, `templates/init-project/`, `hooks/`). |
| `install-init-project.sh` | Instala o pacote em `~/.cursor` no macOS e no Linux. |
| `install-init-project.ps1` | Instala o mesmo pacote em `%USERPROFILE%\.cursor` no Windows. |
| `install-init-project.cmd` | Lançador do `.ps1`: `ExecutionPolicy Bypass` só no processo, prefere `pwsh`, cai para `powershell` 5.1. Sem lógica própria. |
| `rules/personal-md-global.mdc` | Regra global `alwaysApply`: fluxo, harness, sincronização de 12 documentos, memória (dois backends), preferências de stack, Performance, segurança. Fonte única da tabela de gatilhos. |
| `commands/init-project.md` | Comando `/init-project` (FASES 0–8; modos `--check`, `--update`, `--rag`, `--regras`). |
| `templates/init-project/*.md.tpl.md` | 12 templates: `AGENTS.md` e os 11 `docs/*`. |
| `templates/init-project/_scan.sh` | Varredura em bash: `capacidades`, `projeto [--no-cache]`, `sessao`. Única implementação. No Windows não é o comando de entrada. |
| `templates/init-project/scan.cmd` | Entrada Windows. Acha o Git Bash (nunca o `bash.exe` de `System32`) e chama `_scan.sh`. Sem Git Bash, avisa e sai 0. |
| `hooks/session-scan.cmd` | Entrada Windows do hook `sessionStart`. Herda o stdin, chama `session-scan.sh` e sai 0. |
| `templates/init-project/_capacidades.md`, `_checklist-entrevista.md`, `_varredura-regras.md` | Apoio ao comando: instalação de capacidades ausentes, cobertura da entrevista, procedimento do modo `--regras`. |
| `hooks/session-scan.sh` + `hooks.json.snippet` | Hook `sessionStart` opcional: roda `_scan.sh sessao` e devolve `followup_message`. |
| `VERSION` | Versão semver do pacote (instalada em `<destino>/VERSION`). Lida pelos instaladores e por `_scan.sh capacidades` (`[VERSAO]`) para comparar com a última release. |
| `CHANGELOG.md` + `release.sh` | Publicação sob demanda: o script valida (`VERSION` `X.Y.Z`, seção no changelog, `shellcheck`, paridade `FILES`, `main` limpa), pede `s` e só então cria a tag e a GitHub Release. Push não publica. |
| `.gitattributes` | LF para `.sh`, `.md`, `.mdc`, `.json`; CRLF para `.ps1` e `.cmd`. |

## Fluxo de instalação

1. O usuário entrega a pasta do pacote, ou o script usa `./dist/init-project` relativo a si, ou `<destino>/initProjectsInstall/dist/init-project`.
2. Os 20 arquivos são conferidos. Qualquer ausência encerra o processo antes da cópia (RN-INSTALADOR-001). No Windows, em seguida, a verificação chama `scan.cmd` e o `hooks.json` que ainda cita `session-scan.sh` passa a citar `session-scan.cmd`.
3. Cada arquivo novo é copiado. Cada arquivo já presente espera `s`, `N` ou `d`; sem terminal, permanece (RN-INSTALADOR-003/004).
4. O resumo imprime contagens. Em seguida o relatório de capacidades, RTK, archify, hook, versão do pacote e backend de memória roda sem mudar o código de saída (RN-INSTALADOR-005).

## Fluxo de versão e atualização

```text
dist/init-project/VERSION + CHANGELOG.md  (commit em main)
        │
        ▼
   ./release.sh  ── valida; sem o "s" no terminal, para
        │  com "s": envia main se preciso, tag anotada, push da tag, gh release create
        ▼
   GitHub Release  (tar.gz, zip, instaladores, SHA256SUMS)
        │
        ▼
   api.github.com/.../releases/latest  (tag_name)
        ▲
   install-init-project.{sh,ps1}  ── curl / Invoke-RestMethod, 5 s, anônimo
   _scan.sh capacidades [VERSAO]  ── idem, cache 24 h em .scan-cache
        │
        ▼
   "há versão mais nova" + URL  (nunca baixa, nunca instala)
```

A comparação semver é feita em bash puro e em PowerShell (sem `sort -V`, que difere entre BSD e GNU), considerando só `X.Y.Z`. Opt-out por `PERSONAL_MD_NO_UPDATE_CHECK=1` (RN-VERSAO-001/002).

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

A tabela de sincronização (12 documentos) existe em quatro cópias que devem ser idênticas (RN-PACOTE-002). A lista dos 20 arquivos existe em três (RN-PACOTE-001).

## Decisões

- **Pasta, não zip.** O pacote é copiado por USB, rede ou clone; o instalador valida antes de copiar.
- **Mesmo `.sh` para macOS e Linux.** O Cursor usa `~/.cursor` nos dois; só bash e coreutils são exigidos.
- **PowerShell 5.1 como piso no Windows.** Já vem no Windows 10/11; o script evita `??`, ternário e `-Parallel`. BOM UTF-8 obrigatório para o 5.1 ler acentos. O `.cmd` existe para a ExecutionPolicy, não para duplicar a lógica de cópia.
- **`_scan.sh` não foi portado.** No Windows roda via Git Bash (preferido) ou WSL; sem bash, a cópia continua válida e a varredura degrada.
- **Dois backends de memória** (`claude-mem`, `ai-memory`) detectados por chamada MCP, nunca instalados pelo comando.
- **Preferências de stack são sugestão**, nunca aplicação automática — mesmo em projeto novo.
- **Segurança por construção:** nenhum script imprime `mcp.json`, `hooks.json` ou `.env`; `_scan.sh` lista só nomes de servidores MCP.
- **Atualização é aviso, não ação.** A única chamada de rede do pacote é anônima, lê um campo de uma release pública e falha em silêncio. Atualizar continua sendo rodar o instalador, que mostra diff e pergunta arquivo por arquivo. Fonte da verdade da versão é a release do GitHub, não o `git pull`, para que quem instalou por pasta/USB também seja avisado.
- **Release é manual.** `./release.sh` é o único caminho que cria tag e release, e só depois do `s`. Não há GitHub Actions neste repositório.

## Histórico

| Data | Alteração |
| --- | --- |
| 2026-10-06 | Versão original no repositório irmão (Claude Code), com instalador Windows. |
| 2026-10-15 | Reescrito para o Cursor: destino `~/.cursor`, `CURSOR_CONFIG_DIR`, sem `.cmd`, peças do pacote detalhadas, camadas de governança, decisões atualizadas; `docs/arquitetura.html` regenerado. |
| 2026-10-15 | Lançador `install-init-project.cmd` adicionado às peças; `.gitattributes` cobre `.cmd`; `docs/arquitetura.html` regenerado. |
| 2026-10-15 | Versionamento: `VERSION` (19.º arquivo), `CHANGELOG.md`, workflow de release, seção "Fluxo de versão e atualização", decisão "Atualização é aviso, não ação"; `docs/arquitetura.html` regenerado. |
| 2026-10-15 | O workflow sai. A publicação passa a ser `release.sh` (confirmação `s`); decisão "Release é manual". O diagrama de instalação não muda, então `docs/arquitetura.html` permanece. |
| 2026-10-15 | Entrada Windows: `scan.cmd` e `session-scan.cmd`. O instalador não chama `_scan.sh` no Windows e reescreve o comando do hook. `docs/arquitetura.html` regenerado (20 arquivos). |
