# Personal-MD for Cursor

Empacota a governança Personal-MD (`/init-project` + regra global + templates) para o **Cursor**: regras de negócio, sync de docs e harness, com paths e mecânica de `~/.cursor/`.

## Por que isso existe

`/init-project` não é um arquivo isolado: ele depende da regra global, do comando slash e de 15 arquivos de apoio (scan, checklists, templates). Este repositório empacota tudo para instalar em outra máquina sem zip.

O pacote instalável é `dist/init-project/`.

## Onde cada peça mora no Cursor

| Função | Caminho |
| --- | --- |
| Regra global, sempre aplicada | `~/.cursor/rules/personal-md-global.mdc` (`alwaysApply: true`) |
| Comando `/init-project` | `~/.cursor/commands/init-project.md` |
| Templates | `~/.cursor/templates/init-project/*` |
| Instruções do projeto | `./AGENTS.md` (o Cursor lê este arquivo) |
| Planos | `.cursor/plans/` |
| Regras locais | `.cursor/rules/*.mdc` |
| Cache de scan | `~/.cursor/.scan-cache/` |

Projeto que ainda tenha só `./CLAUDE.md` continua legível. O `/init-project` propõe renomear esse arquivo para `./AGENTS.md` e não apaga nada sem confirmação.

## Os 18 arquivos obrigatórios

| Arquivo | Papel |
| --- | --- |
| `rules/personal-md-global.mdc` | Governança global (sempre aplicada no Agent) |
| `commands/init-project.md` | Comando `/init-project` (9 fases, modos `--check`/`--update`/`--rag`/`--regras`) |
| `templates/init-project/_scan.sh` | Varredura de capacidades e projeto (único executável obrigatório) |
| `templates/init-project/_capacidades.md` | Fallback/instalação quando falta MCP, skill ou agente |
| `templates/init-project/_checklist-entrevista.md` | Cobertura da entrevista |
| `templates/init-project/_varredura-regras.md` | Procedimento do modo `--regras` |
| `templates/init-project/*.md.tpl.md` (11) | Templates de `AGENTS.md` e `docs/*` |

Opcionais no pacote: `hooks/session-scan.sh` e `hooks.json.snippet` (hook `sessionStart`).

## Instalação

Na raiz deste repositório:

```bash
chmod +x install-init-project.sh package-init-project.sh
./install-init-project.sh
# ou: ./install-init-project.sh ./dist/init-project
```

O instalador:

1. Confere os 18 arquivos.
2. Copia para `~/.cursor/` (rules, commands, templates), arquivo a arquivo.
3. Se o destino já existe: pergunta `[s/N/d=ver diff]` — nunca sobrescreve em silêncio.
4. Sem TTY: pula existentes.
5. Roda verificação informativa (`_scan.sh capacidades`, RTK, archify, hook).

Depois, no Agent do Cursor, na raiz de um projeto: `/init-project`.

### Hook opcional `sessionStart`

O instalador copia `hooks/session-scan.sh` e `hooks.json.snippet` se presentes. Para ativar:

1. Se ainda não existe `~/.cursor/hooks.json`, copie o snippet:

```bash
cp ~/.cursor/hooks.json.snippet ~/.cursor/hooks.json
```

2. Se já existe `hooks.json`, mescle o bloco `sessionStart` do snippet manualmente (não sobrescreva hooks existentes).

O wrapper chama `_scan.sh sessao` e devolve um `followup_message` com o resumo do projeto, sem bloquear a sessão.

## Empacotar (máquina de origem)

Depois de customizar em `~/.cursor`:

```bash
./package-init-project.sh
# publica em ~/.cursor/initProjectsInstall/dist/init-project/
# e espelha em ./dist/init-project/ quando rodado neste repo
```

Só a partir do dist deste repositório (sem instalar antes):

```bash
PACKAGE_FROM_REPO=1 ./package-init-project.sh
```

## Fluxo em máquina nova

1. Copie `dist/init-project/` (ou o pacote gerado em `~/.cursor/initProjectsInstall/dist/init-project/`).
2. Rode `install-init-project.sh <pasta-do-pacote>`.
3. Revise o relatório de componentes; instale MCP/skills se quiser.
4. Opcional: ative o hook `sessionStart`.
5. Use `/init-project` nos projetos.

## Garantias

- Não sobrescreve sem confirmação (ou pula sem TTY).
- Aborta sem copiar nada se faltar algum dos 18 arquivos.
- Sem rede obrigatória; installs opcionais (rtk, archify) só se você confirmar.

## Mecânica no Cursor

- Regra global em `.mdc` com `alwaysApply`.
- Instruções do projeto em `./AGENTS.md`.
- Planos em `.cursor/plans/`; regras locais em `.cursor/rules/*.mdc`.
- Entrevista com perguntas inline.
- Harness via Task/subagentes do Cursor. O modelo padrão é `inherit`; a profundidade do papel é `profunda` ou `econômica`.
- Memória do projeto pelo MCP de memória (`list_corpora`, `observation_search`, `smart_search`, `query_corpus`).
- Skills em `~/.cursor/skills/`; MCP em Settings → MCP.
- Visão de arquitetura somente via skill `archify` (`docs/arquitetura.html`).
