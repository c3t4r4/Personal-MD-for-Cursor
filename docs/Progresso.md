# Progresso — Personal-MD-for-Cursor

## Status atual

- Estado: estável para empacotar e instalar o `/init-project` no Cursor (macOS, Linux, Windows)
- Última atualização: 2026-10-15
- Branch atual: `main` (2 commits; versionamento de 2026-10-15 ainda não commitado — nenhuma tag/release publicada)
- Versão do pacote: `1.0.0` (`dist/init-project/VERSION`), aguardando a primeira tag `v1.0.0`

## Em andamento

- Nenhuma.

## Concluído

| Data | Tarefa | Plano | Rodadas | Validator | Tester | Segurança | Regras | Documentos | Observações |
| --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- |
| 2026-10-06 | Instalador Windows 11 (repositório irmão, Claude Code) | `Personal-MD-for-Claude-2026-10-06-17-05-instalador-windows.md` | 1 | APPROVED | APPROVED | APPROVED | RN-INSTALADOR-001 a 010 (versão Claude) | docs iniciais | Origem dos `docs/*` copiados para cá em 2026-10-15 |
| 2026-10-15 | Pacote: `ai-memory` como 2.º backend, `README.md` como 12.º documento (4 cópias), preferências de stack, seção Performance, `_scan.sh` (`[MCP_CURSOR]`, `[PLUGINS_CLAUDE]`, `[MARKETPLACES]`, `[BINARIOS]`, `[QUALIDADE]`), `install-init-project.ps1`, `.gitattributes` | `.cursor/plans/Personal-MD-for-Cursor-2026-10-15-09-59-ai-memory-readme-preferencias-stack.md` | 1 | APPROVED | APPROVED | APPROVED | — (governança local ainda não existia) | `README.md` | `bash -n`, `shellcheck`, parse + e2e do `.ps1` em `/tmp`, `onze`=0, 4 tabelas idênticas |
| 2026-10-15 | `install-init-project.sh` honra `CURSOR_CONFIG_DIR`; `~/.cursor/RTK.md`; hook `sessionStart` e hook RTK em `~/.cursor/hooks.json` | — (trivial, inline) | 1 | APPROVED | APPROVED | APPROVED | — | `README.md` | backups `hooks.json.bak-2026-10-15*`; `rtk init` tocou `.gitignore` (revertido) |
| 2026-10-15 | Remoção das menções a outra ferramenta de diagrama na regra e em `_capacidades.md` (só `archify`); `.sh` sem TTY imprime comando manual do rtk; lançador `install-init-project.cmd`; `.gitattributes` para `.cmd` | — (trivial, inline) | 1 | APPROVED | APPROVED | APPROVED | RN-INSTALADOR-008 (atualizada), RN-INSTALADOR-012 (nova) | RegrasNegocio, Arquitetura (+html), Organograma, Memoria, Progresso, README | `shellcheck` limpo; `.sh` sem TTY mostra `brew install rtk`; archify `showcase` 0 erros |
| 2026-10-15 | Governança deste repositório adaptada ao Cursor: `AGENTS.md`, `docs/*` reescritos, `docs/RAG.md` e `docs/Harness.md` criados, `docs/arquitetura.html` regenerado, BOM no `.ps1` | `.cursor/plans/Personal-MD-for-Cursor-2026-10-15-11-05-governanca-cursor.md` | 1 | APPROVED | APPROVED | APPROVED | RN-INSTALADOR-001 a 011, RN-PACOTE-001 a 006, RN-SCAN-001 a 003, RN-HOOK-001 | RegrasNegocio, Arquitetura (+html), Organograma, RAG (novo), Memoria, Harness (novo), Progresso, README | archify `showcase`: 9 checks, 0 erros, 0 avisos; `.sh` e `.ps1` geram árvores idênticas |
| 2026-10-15 | Versionamento: `VERSION` (19.º arquivo), `CHANGELOG.md`, `.github/workflows/release.yml`, seção `-- Versão do pacote --` nos instaladores, `[VERSAO]` em `_scan.sh capacidades`, aviso na FASE 0.5 do `/init-project`, seção em `_capacidades.md` | `.cursor/plans/Personal-MD-for-Cursor-2026-10-15-11-32-versionamento-releases.md` | 1 | APPROVED | APPROVED | APPROVED | RN-VERSAO-001/002 (novas); RN-INSTALADOR-001/007/010, RN-PACOTE-001, RN-SCAN-003 (atualizadas) | RegrasNegocio, Arquitetura (+html), Organograma, RAG, Memoria, Progresso, README | `shellcheck` limpo; semver 9/9 (bash) e 9/9 (pwsh); e2e `.sh`/`.ps1` idênticos (`diff -r`), 21 pulados na 2.ª rodada; pacote sem `VERSION` aborta; workflow validado localmente, sem execução no Actions |

## Backlog

- [x] Commit inicial das alterações de 2026-10-15 (feito pelo usuário: `25b2f6e`, `262ec06`).
- [ ] Commitar o versionamento e publicar a primeira release: `git tag v1.0.0 && git push origin main v1.0.0` (dispara `.github/workflows/release.yml`; primeira execução real do workflow).
- [ ] Rodar `./install-init-project.sh` interativamente para atualizar os arquivos antigos em `~/.cursor` (hoje só os novos foram instalados; o hook `sessionStart` usa o `_scan.sh` antigo).
- [ ] Executar `install-init-project.ps1` num Windows real (PowerShell 5.1) com Git Bash e um arquivo já existente, para cobrir o prompt `[s/N/d]` e o BOM.
- [ ] Decidir RN-INSTALADOR-011 (origem = destino; destino que é pasta).
- [ ] Decidir LICENSE e branch `dev` (`a definir`).
- [x] `install-init-project.cmd` como lançador com `ExecutionPolicy Bypass` (2026-10-15).
- [x] `.sh` sem TTY imprime o comando manual do rtk (2026-10-15).

## Bloqueios

- Nenhum.

## Pendências de segurança

- Nenhuma. Nenhum segredo nos arquivos; `_scan.sh` e `.ps1` imprimem só nomes de servidores MCP; backups de `hooks.json` ficam fora do repositório.

## Regras de negócio pendentes

- RN-INSTALADOR-011 — `a definir`.

## Dívida de testes

- RN-INSTALADOR-003 (prompt `s/N/d`) e RN-INSTALADOR-007 (Git Bash) no Windows real: só o caminho sem TTY foi executado (via `pwsh` no macOS).
- Não há suíte automatizada; a verificação é o bloco de comandos em `AGENTS.md` → `Comandos`.
- Caminho "release mais nova" dos instaladores só foi exercitado por teste unitário de `semver_maior`/`Test-SemverMaior` e pelo cache simulado do `_scan.sh`; a chamada real à API ainda responde 404 (sem release). `release.yml` não rodou no GitHub Actions (passos reproduzidos localmente).
