# Personal-MD for Cursor

Empacota a governança Personal-MD (`/init-project` + regra global + templates) para o **Cursor**: regras de negócio, sync de docs e harness, com paths e mecânica de `~/.cursor/`.

## Por que isso existe

`/init-project` não é um arquivo isolado: ele depende da regra global, do comando slash e de 17 arquivos de apoio (scan, checklists, templates). Este repositório empacota tudo para instalar em outra máquina sem zip.

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

## Os 20 arquivos obrigatórios

| Arquivo | Papel |
| --- | --- |
| `VERSION` | Versão semver do pacote; instalada em `~/.cursor/VERSION` e comparada à última release do GitHub |
| `rules/personal-md-global.mdc` | Governança global (sempre aplicada no Agent) |
| `commands/init-project.md` | Comando `/init-project` (9 fases, modos `--check`/`--update`/`--rag`/`--regras`) |
| `templates/init-project/_scan.sh` | Varredura de capacidades e projeto (única implementação; macOS/Linux) |
| `templates/init-project/scan.cmd` | Entrada da mesma varredura no Windows. Acha o Git Bash e chama o `_scan.sh` |
| `templates/init-project/_capacidades.md` | Fallback/instalação quando falta MCP, skill ou agente |
| `templates/init-project/_checklist-entrevista.md` | Cobertura da entrevista |
| `templates/init-project/_varredura-regras.md` | Procedimento do modo `--regras` |
| `templates/init-project/*.md.tpl.md` (12) | Templates de `AGENTS.md` e dos 11 `docs/*` |

Opcionais no pacote: `hooks/session-scan.sh`, `hooks/session-scan.cmd`, `hooks.json.snippet` (macOS/Linux) e `hooks.json.windows.snippet` (hook `sessionStart`).

`README.md` do projeto governado não tem template: é o 12.º documento da tabela de sincronização obrigatória (nunca `n/a`) e, quando ausente, é criado com a estrutura mínima descrita na regra global.

## Instalação

### macOS e Linux

O Cursor usa `~/.cursor/` nos dois sistemas; o mesmo script serve para ambos. Na raiz deste repositório:

```bash
chmod +x install-init-project.sh package-init-project.sh
./install-init-project.sh
# ou: ./install-init-project.sh ./dist/init-project
```

### Windows

O Cursor usa `%USERPROFILE%\.cursor\`. No PowerShell (5.1 ou 7+), na raiz deste repositório:

```powershell
.\install-init-project.ps1
# ou: .\install-init-project.ps1 .\dist\init-project
```

Se a política de execução bloquear o script, use o lançador, que aplica `Bypass` só naquele processo (sem alterar a política da máquina) e prefere `pwsh` quando existir:

```bat
install-init-project.cmd
rem ou: install-init-project.cmd .\dist\init-project
```

Equivalente manual: `powershell -ExecutionPolicy Bypass -File .\install-init-project.ps1`.

Ressalvas no Windows:

- O `.ps1` é compatível com Windows PowerShell 5.1 e PowerShell 7+, gravado em UTF-8 com BOM (o 5.1 lê sem BOM como ANSI e quebra os acentos) e com CRLF no checkout via `.gitattributes`.
- A varredura não chama `_scan.sh` direto. O instalador roda `scan.cmd`, e o hook fica em `session-scan.cmd`. Os dois procuram o `bash.exe` do Git for Windows e só então delegam ao `.sh`. Sem Git Bash, o cmd avisa (ou imprime `{}` no hook) e sai 0: a sessão não fica falhando, e o `/init-project` segue sem a varredura automática.
- Se `hooks.json` ainda tiver `session-scan.sh`, o instalador troca só essa string por `session-scan.cmd` e deixa um backup `hooks.json.bak-<data>`. O conteúdo do arquivo não é impresso.
- O hook `sessionStart` depende de `bash.exe` acessível pelo Cursor — não verificado neste pacote.
- Em WSL, o `$HOME` é o do Linux; para apontar ao perfil do Windows, exportar `CURSOR_CONFIG_DIR=/mnt/c/Users/<usuario>/.cursor`.

### O que os instaladores fazem

1. Conferem os 20 arquivos.
2. Copiam para a pasta do Cursor (rules, commands, templates, hooks), arquivo a arquivo. O destino é `~/.cursor` (`%USERPROFILE%\.cursor` no Windows); a variável `CURSOR_CONFIG_DIR` sobrepõe isso nos dois instaladores.
3. Se o destino já existe: perguntam `[s/N/d=ver diff]` — nunca sobrescrevem em silêncio.
4. Sem terminal interativo: pulam existentes.
5. Rodam verificação informativa (`_scan.sh capacidades`, RTK, archify, hook, versão do pacote, backend de memória).

Depois, no Agent do Cursor, na raiz de um projeto: `/init-project`.

### Versão e aviso de atualização

O pacote tem versão semver em `dist/init-project/VERSION`, instalada em `~/.cursor/VERSION`. Cada versão publicada é uma [GitHub Release](https://github.com/c3t4r4/Personal-MD-for-Cursor/releases) com tag `v<versão>` e o pacote anexado em `.tar.gz`/`.zip` (mais os instaladores e `SHA256SUMS.txt`).

Onde o aviso aparece:

- **Instaladores** (`.sh`/`.ps1`): seção `-- Versão do pacote --` com `pacote`, `instalada antes` e `última release`. Se a release for mais nova que o pacote que você está instalando, avisam e mostram a URL.
- **`/init-project`**: `_scan.sh capacidades` emite a seção `[VERSAO]` (`instalada`, `ultima_release`, `atualizacao: disponivel|nao|desconhecido`); o comando avisa uma vez, na FASE 0.5, só quando `disponivel`.

O que a verificação **não** faz: não baixa, não atualiza, não roda o instalador. Lê apenas o `tag_name` da release pública (`api.github.com/repos/c3t4r4/Personal-MD-for-Cursor/releases/latest`), sem token, com 5 s de timeout e falha silenciosa; o `_scan.sh` cacheia a resposta por 24 h em `~/.cursor/.scan-cache/update-check.out`. Para desligar: `PERSONAL_MD_NO_UPDATE_CHECK=1`.

Para atualizar: baixe a release, extraia e rode o instalador apontando para a pasta extraída (`./install-init-project.sh ./init-project` ou `install-init-project.cmd .\init-project`). Ele mostra o diff e pergunta arquivo por arquivo.

### Hook opcional `sessionStart`

O instalador copia os dois wrappers e os dois snippets, se presentes. No macOS/Linux o comando é `session-scan.sh`. No Windows o instalador usa `session-scan.cmd` e, quando `hooks.json` já existe apontando para o `.sh`, faz a troca. Para ativar num perfil ainda sem hook:

1. Se ainda não existe `~/.cursor/hooks.json`, copie o snippet:

```bash
cp ~/.cursor/hooks.json.snippet ~/.cursor/hooks.json
```

No Windows, o arquivo é `hooks.json.windows.snippet` (`session-scan.cmd`).

2. Se já existe `hooks.json`, mescle o bloco `sessionStart` do snippet do seu sistema (não sobrescreva hooks existentes). No Windows, se o comando ainda for `session-scan.sh`, rode o instalador de novo: ele troca só essa string.

O wrapper chama a varredura `sessao` e devolve um `followup_message` com o resumo do projeto, sem bloquear a sessão.

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

## Publicar uma release

Não há workflow. Push de commit ou de tag não cria release. Quem publica roda o script, num terminal, e confirma com `s`:

1. Atualize `dist/init-project/VERSION` (semver `X.Y.Z`) e a seção `## [X.Y.Z]` em `CHANGELOG.md`.
2. Commit em `main`, com a árvore limpa.
3. `./release.sh` — ou `./release.sh --dry-run` para só validar.

O script recusa branch diferente de `main`, árvore suja, `shellcheck` falho, listas `FILES` divergentes, tag ou release já existente, e `main` atrás do `origin`. Sem terminal, também recusa. Confirmado, envia `main` se ainda houver commits locais, cria a tag anotada `vX.Y.Z`, envia a tag e publica `init-project-X.Y.Z.tar.gz`, `.zip`, os três instaladores e `SHA256SUMS.txt`, com as notas da seção do changelog. É essa release que os instaladores e o `/init-project` consultam.

## Fluxo em máquina nova

1. Copie `dist/init-project/` (ou o pacote gerado em `~/.cursor/initProjectsInstall/dist/init-project/`).
2. Rode `install-init-project.sh <pasta-do-pacote>` (macOS/Linux) ou `install-init-project.cmd <pasta-do-pacote>` / `install-init-project.ps1` (Windows).
3. Revise o relatório de componentes; instale MCP/skills se quiser.
4. Opcional: ative o hook `sessionStart`.
5. Use `/init-project` nos projetos.

## Garantias

- Não sobrescreve sem confirmação (ou pula sem TTY).
- Aborta sem copiar nada se faltar algum dos 20 arquivos.
- Sem rede obrigatória; installs opcionais (rtk, archify) só se você confirmar.
- Verificação de atualização só informa; nunca baixa nem atualiza. Desligável com `PERSONAL_MD_NO_UPDATE_CHECK=1`.

## Governança deste repositório

Este repositório também é governado pelo que distribui. Ordem de leitura para quem for alterá-lo: `AGENTS.md` → `docs/RegrasNegocio.md` (invariantes dos instaladores, do pacote e da varredura: `RN-INSTALADOR-*`, `RN-PACOTE-*`, `RN-SCAN-*`, `RN-HOOK-*`) → `docs/Arquitetura.md` (+ `docs/arquitetura.html`, gerado pela skill `archify` a partir de `docs/archify/instalacao.workflow.json`) → `docs/Organograma.md` → `docs/RAG.md` → `docs/Progresso.md` → `docs/Memoria.md` → `docs/Harness.md`.

Regras que mais pegam quem edita o pacote:

- A tabela de sincronização (12 documentos) existe em quatro cópias idênticas: regra global (tabela + modelo de plano), `AGENTS.md.tpl.md`, `Harness.md.tpl.md` e o modelo de plano de `commands/init-project.md`.
- A lista dos 20 arquivos existe em três: `install-init-project.sh`, `install-init-project.ps1`, `package-init-project.sh`.
- Nenhum script imprime conteúdo de `mcp.json`, `hooks.json` ou `.env`.
- `VERSION` só muda junto com `CHANGELOG.md`. A tag `v` + `VERSION` só nasce quando alguém roda `./release.sh` e responde `s`.

Verificação local, sem tocar `~/.cursor`:

```bash
shellcheck -S warning install-init-project.sh package-init-project.sh release.sh dist/init-project/templates/init-project/_scan.sh dist/init-project/hooks/session-scan.sh
CURSOR_CONFIG_DIR=/tmp/x PERSONAL_MD_NO_UPDATE_CHECK=1 ./install-init-project.sh ./dist/init-project
CURSOR_CONFIG_DIR=/tmp/y PERSONAL_MD_NO_UPDATE_CHECK=1 pwsh -NoProfile -NonInteractive -File ./install-init-project.ps1 ./dist/init-project
diff -r /tmp/x /tmp/y
```

Licença e branch de desenvolvimento: a definir.

## Mecânica no Cursor

- Regra global em `.mdc` com `alwaysApply`.
- Instruções do projeto em `./AGENTS.md`.
- Planos em `.cursor/plans/`; regras locais em `.cursor/rules/*.mdc`.
- Entrevista com perguntas inline.
- Harness via Task/subagentes do Cursor. O modelo padrão é `inherit`; a profundidade do papel é `profunda` ou `econômica`.
- Memória do projeto por um de dois backends MCP, ou ambos: `claude-mem` (`list_corpora`, `observation_search`, `smart_search`, `query_corpus`) ou `ai-memory` (`memory_status`, `memory_query`, `memory_briefing`, handoffs). Instalação em `templates/init-project/_capacidades.md`.
- Preferências de stack por ecossistema (uv, Tailwind, pnpm + Biome, gofumpt, Laravel...) e seção de Performance na regra global — sempre como sugestão com confirmação, nunca aplicadas sem autorização.
- Skills em `~/.cursor/skills/`; MCP em Settings → MCP.
- Visão de arquitetura somente via skill `archify` (`docs/arquitetura.html`).
