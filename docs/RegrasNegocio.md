# Regras de Negócio — Personal-MD-for-Cursor

> Memória viva das regras dos instaladores, do pacote `dist/init-project/` e dos scripts de varredura. Não há telas: as "regras de negócio" deste repositório são os invariantes que o pacote promete a quem o instala.

Última atualização: 2026-10-15

---

## Como usar este documento

Antes de alterar o que o instalador copia, pergunta ou recusa, ou o que o pacote promete, ler as regras `confirmada` abaixo. Se a mudança as contradisser, parar e perguntar.

Não apagar regra. Regra que deixar de valer fica `revogada`, com data e motivo.

### Status

| Status | Significado |
| --- | --- |
| `confirmada` | Pedida pelo usuário, aprovada em plano ou explícita nos comentários dos scripts. |
| `⚠ inferida` | Extraída de código sem confirmação. Não tratar como verdade. |
| `a definir` | Ainda não decidida. |
| `revogada` | Histórica. |

---

## Glossário

| Termo | Significado | Onde aparece |
| --- | --- | --- |
| Pacote | Pasta com os 20 arquivos obrigatórios (+ 4 opcionais) do `/init-project` | `dist/init-project/`, argumento dos instaladores |
| Destino | Configuração global do Cursor | `~/.cursor` (macOS/Linux), `%USERPROFILE%\.cursor` (Windows), ou `CURSOR_CONFIG_DIR` |
| TTY | Terminal em que o usuário pode responder | `/dev/tty` no bash; console não redirecionado e sem `-NonInteractive` no PowerShell |
| Os 12 documentos | 11 `docs/*` + `README.md` da tabela de sincronização obrigatória | regra global, templates, comando |
| Backend de memória | MCP `claude-mem` ou `ai-memory` | `_capacidades.md`, `docs/RAG.md` dos projetos governados |

---

## Índice de telas

Não há telas. As regras são de linha de comando e de conteúdo do pacote.

---

## Regras — instaladores (`install-init-project.sh`, `install-init-project.ps1`)

### RN-INSTALADOR-001 — Integridade antes da cópia

- **Status:** `confirmada`
- **Enunciado:** Os 20 caminhos relativos precisam existir como arquivo na pasta do pacote. Se faltar algum, o instalador lista os ausentes, termina com código 1 e não copia nenhum arquivo para o destino. Os 4 opcionais (`hooks/session-scan.sh`, `hooks/session-scan.cmd`, `hooks.json.snippet`, `hooks.json.windows.snippet`) não entram nessa conferência.
- **Rastreabilidade:** `install-init-project.sh`, `install-init-project.ps1`; testado em 2026-10-15 removendo `RAG.md.tpl.md` do pacote.

### RN-INSTALADOR-002 — Arquivo novo

- **Status:** `confirmada`
- **Enunciado:** Se o caminho ainda não existe no destino, o arquivo é copiado sem pergunta, preservando bytes (`cp -p` / `Copy-Item`). Scripts bash continuam com LF.
- **Rastreabilidade:** `install-init-project.sh`, `install-init-project.ps1`

### RN-INSTALADOR-003 — Arquivo existente

- **Status:** `confirmada`
- **Enunciado:** Se o destino já tem o arquivo, o instalador pergunta `Sobrescrever? [s/N/d=ver diff]`, mesmo quando o conteúdo é idêntico (nesse caso anota "(idêntico ao existente)"). `s` sobrescreve, `d` mostra o diff e pergunta de novo, qualquer outra resposta mantém o arquivo.
- **Rastreabilidade:** `install-init-project.sh`, `install-init-project.ps1`

### RN-INSTALADOR-004 — Sem terminal interativo

- **Status:** `confirmada`
- **Enunciado:** Sem terminal interativo, todo arquivo que já existe é mantido e contado como pulado. Nada é sobrescrito. No PowerShell, `-NonInteractive`, stdin redirecionado ou `[Environment]::UserInteractive = $false` contam como "sem terminal".
- **Rastreabilidade:** `install-init-project.sh`, `install-init-project.ps1`; segunda rodada ponta a ponta em 2026-10-15: 20 `[pulado, sem TTY]`.

### RN-INSTALADOR-005 — Verificação não bloqueia

- **Status:** `confirmada`
- **Enunciado:** Depois da cópia, o relatório de agentes/skills (`_scan.sh capacidades`), RTK, archify, hook `sessionStart` e backend de memória é só informativo. Ausência desses componentes não altera o código de saída de uma instalação que já copiou os arquivos.
- **Rastreabilidade:** `install-init-project.sh`, `install-init-project.ps1`

### RN-INSTALADOR-006 — Destino e pacote padrão

- **Status:** `confirmada`
- **Enunciado:** O destino é `CURSOR_CONFIG_DIR` quando definido; senão `~/.cursor` (macOS/Linux) ou `%USERPROFILE%\.cursor` (Windows). Sem argumento, o pacote procurado é, nesta ordem: `./dist/init-project` relativo ao script, depois `<destino>/initProjectsInstall/dist/init-project`. Se nenhum existir, o instalador informa os dois caminhos e termina com código 1 — **não cria** a pasta.
- **Rastreabilidade:** `install-init-project.sh`, `install-init-project.ps1`

### RN-INSTALADOR-007 — Capacidades no Windows

- **Status:** `confirmada`
- **Enunciado:** No Windows o instalador não chama `_scan.sh`. A verificação roda `templates/init-project/scan.cmd capacidades`. Esse cmd procura o bash do Git for Windows em `%ProgramFiles%\Git\bin`, `%ProgramFiles(x86)%\Git\bin` e `%LOCALAPPDATA%\Programs\Git\bin`, nessa ordem, e só depois um `bash` do `PATH` que não esteja em `System32`. Sem Git Bash, `scan.cmd` avisa e sai 0; a instalação dos 20 arquivos permanece válida e a varredura degrada. O `bash.exe` de `System32` (WSL) não é usado porque não enxerga caminhos do Windows sem conversão.
- **Rastreabilidade:** `install-init-project.ps1`

### RN-INSTALADOR-008 — Componentes opcionais só com sim

- **Status:** `confirmada`
- **Enunciado:** RTK (`brew install rtk` no macOS, `install.sh` oficial no Linux, `winget install rtk-ai.rtk` no Windows) e archify (`npx -y skills add tt-a1i/archify --skill archify --agent cursor --global --copy --yes`) só são instalados depois de uma resposta que começa com `s`/`S` num terminal interativo. Sem terminal, nada é instalado e os dois instaladores imprimem o comando manual correspondente ao sistema (rtk e archify).
- **Rastreabilidade:** `install-init-project.sh`, `install-init-project.ps1`

### RN-INSTALADOR-009 — Permissão de execução

- **Status:** `confirmada`
- **Enunciado:** No macOS/Linux, após a cópia, `templates/init-project/_scan.sh` e `hooks/session-scan.sh` recebem `chmod 755`. No Windows não há bit de execução; o `.ps1` não altera permissões.
- **Rastreabilidade:** `install-init-project.sh`

### RN-INSTALADOR-010 — Paridade entre instaladores

- **Status:** `confirmada`
- **Enunciado:** O `.ps1` replica o `.sh`: mesma lista `FILES` (20) e `OPTIONAL_FILES` (4), mesma ordem de cópia, mesmas mensagens em português, mesmo resumo (novos / sobrescritos / pulados / total). Rodados sobre o mesmo pacote com destinos temporários, os dois produzem árvores idênticas (`diff -r`).
- **Rastreabilidade:** `install-init-project.sh`, `install-init-project.ps1`; conferido em 2026-10-15.

### RN-INSTALADOR-012 — Lançador `.cmd` só lança

- **Status:** `confirmada`
- **Enunciado:** `install-init-project.cmd` existe apenas para contornar a ExecutionPolicy do Windows: chama o `.ps1` da mesma pasta com `-NoProfile -ExecutionPolicy Bypass -File`, preferindo `pwsh` (PowerShell 7) quando existir e caindo para `powershell` (5.1). Repassa todos os argumentos e o código de saída. Não altera a política da máquina e não contém lógica de cópia; se o `.ps1` não estiver ao lado, termina com código 1.
- **Rastreabilidade:** `install-init-project.cmd`

### RN-INSTALADOR-011 — Origem igual ao destino ou destino que é pasta

- **Status:** `a definir`
- **Enunciado:** Não há tratamento quando o arquivo de origem e o de destino resolvem para o mesmo caminho, nem quando o caminho de destino existe como pasta. Hoje o primeiro caso cairia em RN-INSTALADOR-003 (pergunta) e o segundo falharia na cópia. Decidir se vale replicar o comportamento do repositório irmão (pular com aviso).
- **Rastreabilidade:** backlog em `docs/Progresso.md`

---

## Regras — pacote (`dist/init-project/`)

### RN-PACOTE-001 — Lista de arquivos em três lugares

- **Status:** `confirmada`
- **Enunciado:** A lista dos 20 arquivos obrigatórios existe em `install-init-project.sh`, `install-init-project.ps1` e `package-init-project.sh` e deve ser idêntica nos três. Arquivo novo no pacote entra nos três na mesma tarefa.
- **Rastreabilidade:** arrays `FILES` / `$Files`

### RN-PACOTE-002 — Tabela de gatilhos em quatro cópias

- **Status:** `confirmada`
- **Enunciado:** A tabela de sincronização obrigatória tem 12 linhas (11 `docs/*` + `README.md`) e é replicada palavra por palavra em `rules/personal-md-global.mdc` (tabela de gatilhos e modelo de plano), `templates/init-project/AGENTS.md.tpl.md`, `templates/init-project/Harness.md.tpl.md` e no modelo de plano de `commands/init-project.md`. A regra global é a fonte única; as cópias existem para o projeto ser legível sem ela.
- **Rastreabilidade:** os quatro arquivos; conferência por normalização de espaços em 2026-10-15.

### RN-PACOTE-003 — README nunca é `n/a`

- **Status:** `confirmada`
- **Enunciado:** `README.md` do projeto governado é o 12.º documento da sincronização e segue a regra dos permanentes: nunca `n/a`. Não tem template dedicado; quando ausente é criado com a estrutura mínima descrita em "Como ler a tabela" da regra global; quando existe, é corrigido no ponto que ficou falso, nunca reescrito do zero sem pedido.
- **Rastreabilidade:** `rules/personal-md-global.mdc`, `commands/init-project.md` (FASE 6 e checklist da FASE 8), `_checklist-entrevista.md`

### RN-PACOTE-004 — Preferências de stack são sugestão

- **Status:** `confirmada`
- **Enunciado:** A seção `## Preferências de stack por ecossistema` da regra global (uv, ruff, Tailwind v4 + shadcn, pnpm + Biome, Pest/Pint, gofumpt + golangci-lint, clippy, `dotnet format`, PostgreSQL etc.) é aplicada em três passos: sugerir, explicar, confirmar. Nunca aplicar sem autorização, nem em projeto novo. Nunca propor migrar o que o projeto já usa. Desvio detectado por `_scan.sh projeto` (`[LOCKS]`, `[QUALIDADE]`) é informativo na FASE 2, não pergunta.
- **Rastreabilidade:** `rules/personal-md-global.mdc`, `commands/init-project.md` (FASE 2 — Saída), `AGENTS.md.tpl.md`

### RN-PACOTE-005 — Dois backends de memória, basta um

- **Status:** `confirmada`
- **Enunciado:** O pacote reconhece `claude-mem` (detecção `list_corpora`) e `ai-memory` (detecção `memory_status`). Um dos dois basta para a capacidade "MCP de memória" contar como disponível; podem coexistir. Nenhum substitui `docs/Memoria.md`. Nenhum é instalado automaticamente — `_capacidades.md` só descreve como instalar.
- **Rastreabilidade:** `_capacidades.md`, `rules/personal-md-global.mdc` (Memória do projeto, RAG), `RAG.md.tpl.md`, `commands/init-project.md` (FASES 0.5 e 7)

### RN-PACOTE-006 — Nada é instalado automaticamente pelo `/init-project`

- **Status:** `confirmada`
- **Enunciado:** O comando `/init-project` não instala plugins, MCPs, skills nem edita `hooks.json`/`mcp.json`. Capacidade ausente degrada o trabalho e gera instrução de instalação; nunca interrompe.
- **Rastreabilidade:** `commands/init-project.md` (FASE 0.5 — Regras)

---

## Regras — varredura e hook (`_scan.sh`, `hooks/session-scan.sh`)

### RN-SCAN-001 — Só nomes de servidores MCP

- **Status:** `confirmada`
- **Enunciado:** `_scan.sh capacidades` lê `~/.cursor/mcp.json` e imprime apenas as chaves de `mcpServers`, em ordem. Nunca imprime `url`, `command`, `args`, `env` ou `headers`. O mesmo vale para plugins e marketplaces: só identificadores.
- **Rastreabilidade:** `templates/init-project/_scan.sh` (seções `[MCP_CURSOR]`, `[PLUGINS_CLAUDE]`, `[MARKETPLACES]`)

### RN-SCAN-002 — Arquivos de ambiente só por nome

- **Status:** `confirmada`
- **Enunciado:** `_scan.sh projeto` reporta `.env*` apenas como presença e estado de versionamento (`alerta_env_versionado`). Nunca lê nem imprime o conteúdo.
- **Rastreabilidade:** `templates/init-project/_scan.sh` (seção `[AMBIENTE]`)

### RN-SCAN-003 — Cache do modo `projeto`

- **Status:** `confirmada`
- **Enunciado:** `projeto` é cacheado em `~/.cursor/.scan-cache/`, fora do repositório, invalidado pelo mtime de `.git/HEAD`, `.git/index`, raiz, `docs/`, `.cursor/` e do próprio script, e expira em 6 h. `--no-cache` força nova varredura; `--check` do `/init-project` sempre usa `--no-cache`. O modo `capacidades` nunca é cacheado; a única exceção é a consulta de rede da seção `[VERSAO]`, cacheada 24 h em `update-check.out` (RN-VERSAO-001).
- **Rastreabilidade:** `templates/init-project/_scan.sh`, `commands/init-project.md` (FASE 2 — Cache)

### RN-SCAN-004 — No Windows a entrada é o `.cmd`

- **Status:** `confirmada`
- **Enunciado:** No Windows, `/init-project`, o instalador e o hook `sessionStart` usam `scan.cmd` e `session-scan.cmd`. Não chamam `_scan.sh` nem `session-scan.sh` como comando. O `.cmd` só delega ao `.sh` depois de achar o Git Bash. A lógica da varredura continua única, em `_scan.sh`.
- **Rastreabilidade:** `templates/init-project/scan.cmd`, `hooks/session-scan.cmd`, `commands/init-project.md` (FASES 0.5 e 2), `install-init-project.ps1`

### RN-HOOK-001 — O hook nunca bloqueia a sessão

- **Status:** `confirmada`
- **Enunciado:** `hooks/session-scan.sh` termina sempre com código 0 e emite JSON válido: `{"followup_message": "..."}` quando há contexto, `{}` quando `_scan.sh` está ausente, não executável ou não produz saída. Honra `CURSOR_CONFIG_DIR`. No Windows o comando registrado no hook é `hooks/session-scan.cmd`, que herda o stdin, chama o `.sh` pelo Git Bash e, sem Git Bash ou sem o `.sh`, imprime `{}` e sai 0. O instalador Windows, se `hooks.json` contiver `session-scan.sh`, troca só essa string por `session-scan.cmd`, grava backup `hooks.json.bak-<data>` e não imprime o arquivo.
- **Rastreabilidade:** `hooks/session-scan.sh`, `hooks/session-scan.cmd`, `install-init-project.ps1`; o `.sh` foi testado em 2026-10-15 com stdin `{"workspace_roots":[...]}`; a troca no `hooks.json` foi testada com `CURSOR_CONFIG_DIR` temporário e `OS=Windows_NT`.

---

## Regras — versão e atualização (`VERSION`, releases do GitHub)

### RN-VERSAO-001 — Aviso de atualização só informa

- **Status:** `confirmada`
- **Enunciado:** A versão do pacote é o conteúdo de `dist/init-project/VERSION` (semver `X.Y.Z`), instalado em `<destino>/VERSION`. Instaladores e `_scan.sh capacidades` (seção `[VERSAO]`) comparam a versão instalada/do pacote com o `tag_name` de `api.github.com/repos/c3t4r4/Personal-MD-for-Cursor/releases/latest` (prefixo `v` opcional). A consulta é anônima (sem token, sem cabeçalhos), tem 5 s de timeout e falha em silêncio (`indisponivel`). No `_scan.sh` a resposta é cacheada 24 h em `~/.cursor/.scan-cache/update-check.out`. `PERSONAL_MD_NO_UPDATE_CHECK=1` desliga a consulta nos três (`desativado`). **Nunca** baixa, atualiza ou roda o instalador: a saída é só `instalada`, `ultima_release`, `atualizacao: disponivel|nao|desconhecido` e `url`. O `/init-project` avisa uma única vez, na FASE 0.5, apenas quando `disponivel`; `indisponivel` e `desativado` são silenciosos.
- **Rastreabilidade:** `install-init-project.sh` (`-- Versão do pacote --`), `install-init-project.ps1` (idem), `templates/init-project/_scan.sh` (`release_mais_recente`, `semver_maior`, `[VERSAO]`), `commands/init-project.md` (FASE 0.5 — Versão do pacote), `_capacidades.md` (Atualização do pacote); testado em 2026-10-15 com cache simulado (`1.0.0` → `1.2.0` = `disponivel`), opt-out e API sem release.

### RN-VERSAO-002 — Tag, `VERSION` e `CHANGELOG.md` andam juntos

- **Status:** `confirmada`
- **Enunciado:** Uma release só existe como tag `v<VERSION>` em `main`, criada por `./release.sh` quando o mantenedor responde `s` num terminal interativo. Push de commit ou de tag não publica nada: não há workflow. O script recusa quando a branch não é `main`, a árvore está suja, `VERSION` não é `X.Y.Z`, `CHANGELOG.md` não tem a seção `## [<VERSION>]`, o `shellcheck` falha, as três listas `FILES` divergem ou citam arquivo ausente (RN-PACOTE-001), a tag ou a release já existe, `main` local está atrás de `origin/main`, ou não há terminal. `--dry-run` faz as mesmas conferências e empacota, sem tag, sem push e sem release. Confirmado, envia `main` se houver commits ainda não enviados, cria a tag anotada, envia a tag e publica `init-project-<VERSION>.tar.gz`, `.zip`, os três instaladores e `SHA256SUMS.txt`, com notas da seção do changelog. A comparação semver do aviso de atualização continua só com os três números.
- **Rastreabilidade:** `release.sh`, `CHANGELOG.md`, `dist/init-project/VERSION`; `--dry-run` e a recusa de árvore suja testados em 2026-10-15 (ainda sem publicação real).

---

## Histórico

| Data | Alteração |
| --- | --- |
| 2026-10-06 | Documento original criado no repositório irmão (Claude Code) com RN-INSTALADOR-001 a 010. |
| 2026-10-15 | Reescrito para o Cursor: destino `~/.cursor`/`CURSOR_CONFIG_DIR`, sem `.cmd`; RN-INSTALADOR-006/007/008 revisadas contra o código real; 009 (chmod) e 010 (paridade) novas; antiga 009/010 (mesmo arquivo / destino-pasta) viram RN-INSTALADOR-011 `a definir`; criadas RN-PACOTE-001 a 006, RN-SCAN-001 a 003 e RN-HOOK-001. |
| 2026-10-15 | RN-INSTALADOR-008: `.sh` sem TTY passa a imprimir o comando manual do rtk (paridade com o `.ps1`). RN-INSTALADOR-012 criada com o lançador `install-init-project.cmd`. |
| 2026-10-15 | `VERSION` vira o 19.º arquivo obrigatório (RN-INSTALADOR-001, 007, 010, RN-PACOTE-001, glossário). RN-SCAN-003 ganha a exceção da consulta de release. Criadas RN-VERSAO-001 (aviso de atualização só informa) e RN-VERSAO-002 (tag, `VERSION` e `CHANGELOG.md` juntos). |
| 2026-10-15 | RN-VERSAO-002: a release deixa de ser o workflow em tag e passa a ser `./release.sh`, só com confirmação `s`. Push não publica. |
| 2026-10-15 | 20 arquivos obrigatórios e 4 opcionais. RN-INSTALADOR-007 e RN-HOOK-001: Windows entra por `scan.cmd` / `session-scan.cmd` e o instalador troca `session-scan.sh` no `hooks.json`. RN-SCAN-004 criada. |
