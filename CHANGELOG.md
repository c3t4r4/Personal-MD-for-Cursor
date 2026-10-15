# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/). Versionamento: [SemVer](https://semver.org/lang/pt-BR/).

A versão do pacote vive em `dist/init-project/VERSION`; cada release no GitHub é a tag `v<versão>` com o conteúdo de `dist/init-project/` anexado em `.tar.gz` e `.zip`.

## [Unreleased]

## [1.0.0] — 2026-10-15

### Adicionado

- Pacote `dist/init-project/` para o Cursor: regra global `personal-md-global.mdc`, comando `/init-project`, 12 templates, `_scan.sh`, `_capacidades.md`, `_checklist-entrevista.md`, `_varredura-regras.md`, hook `sessionStart` opcional.
- Instaladores `install-init-project.sh` (macOS/Linux), `install-init-project.ps1` (Windows) e lançador `install-init-project.cmd`; todos honram `CURSOR_CONFIG_DIR`.
- Dois backends de memória (`claude-mem`, `ai-memory`); `README.md` como 12.º documento da sincronização; preferências de stack por ecossistema e seção Performance na regra global.
- `_scan.sh capacidades` com `[MCP_CURSOR]`, `[PLUGINS_CLAUDE]`, `[MARKETPLACES]`, `[BINARIOS]` e `[VERSAO]`; `_scan.sh projeto` com `[QUALIDADE]`.
- Arquivo `VERSION` no pacote e aviso de atualização (GitHub Releases) nos instaladores e no `/init-project`, sem atualização automática.
- Governança do próprio repositório (`AGENTS.md`, `docs/*`).

[Unreleased]: https://github.com/c3t4r4/Personal-MD-for-Cursor/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/c3t4r4/Personal-MD-for-Cursor/releases/tag/v1.0.0
