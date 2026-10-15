# Memória — Personal-MD-for-Cursor

Última atualização: 2026-10-15

## Aprendizados

### Windows PowerShell 5.1 e acentos

O Windows ainda abre `powershell.exe` na versão 5.1. Esse host lê um `.ps1` sem BOM como ANSI e quebra o português e os símbolos (`✓`, `ℹ`, `≥`). `install-init-project.ps1` é gravado em UTF-8 **com BOM**; `.gitattributes` garante CRLF no checkout Windows e mantém LF nos `.sh`, `.md`, `.mdc` e `.json`. A ferramenta de escrita do Cursor gera arquivos sem BOM — conferir com `head -c 3 | xxd` (`efbb bf`) depois de reescrever o `.ps1`.

### ExecutionPolicy e o `.cmd`

`Bypass` fica na linha `-ExecutionPolicy Bypass -File` dentro de `install-init-project.cmd`; a política da máquina não é alterada. O `.cmd` prefere `pwsh` (PowerShell 7) e cai para `powershell` (5.1). `cmd.exe` tem comportamento indefinido com arquivos em LF puro, por isso `.gitattributes` força CRLF em `*.cmd` e o arquivo é mantido sem acentos (página de código do console não é garantida).

### Testar os instaladores sem tocar `~/.cursor`

Os dois instaladores e o hook honram `CURSOR_CONFIG_DIR`. Teste padrão: `CURSOR_CONFIG_DIR=/tmp/x ./install-init-project.sh ./dist/init-project` e `CURSOR_CONFIG_DIR=/tmp/y pwsh -NoProfile -NonInteractive -File ./install-init-project.ps1 ./dist/init-project`, depois `diff -r /tmp/x /tmp/y`. Segunda rodada deve dar 21 `[pulado, sem TTY]`. Cenário de falha: remover um dos 19 arquivos do pacote → exit 1 e zero arquivos copiados.

### `pwsh` no macOS não roda dentro do sandbox do Cursor

O `pwsh` do Homebrew falha na inicialização (`sysctl argmax errno 1`) quando o comando roda no sandbox do agente. Parse e execução do `.ps1` precisam de shell fora do sandbox. O parse estático é `[System.Management.Automation.Language.Parser]::ParseFile(...)`.

### Shell persistente do agente

A shell do Cursor mantém `cd` e `export` entre comandos. Nunca `export HOME=...` para testar — usar prefixo por comando (`HOME=/tmp/x ./script`). Sempre começar pela raiz do repositório: um `cd` esquecido num subdiretório já criou `dist/init-project/.cursor/plans/` por engano.

### `sed -i` do macOS e `\b`

O `sed` BSD não entende `\b`. Para substituição por palavra inteira, usar `perl -pi -e 's/\bonze\b/doze/g'`.

### Tabelas Markdown alinhadas com espaços

A regra `.mdc` tem tabelas alinhadas com espaços; os templates não. Para conferir que as quatro cópias da tabela de gatilhos são idênticas, normalizar espaços antes de comparar (`sed -E 's/ +/ /g; s/ \|/|/g; s/\| /|/g'`) e extrair a tabela pela seção, não por regex de linha única — o modelo de plano tem linhas parecidas.

### `_scan.sh capacidades` e os arquivos do Cursor

`~/.cursor/settings.json` e `~/.cursor/plugins/known_marketplaces.json` não existem. O que existe: `~/.cursor/mcp.json` (servidores MCP — listar só as chaves de `mcpServers`), `~/.claude/plugins/installed_plugins.json` e `~/.claude/plugins/known_marketplaces.json` (plugins do Claude Code, que o `claude-mem` usa). Antes dessa correção o scan imprimia sempre `indisponivel`.

### `rtk init` e o `.gitignore`

`rtk init --global --agent cursor` registra `preToolUse → rtk hook cursor` em `~/.cursor/hooks.json` e, como efeito colateral, acrescentou `.claude` ao `.gitignore` deste repositório mesmo rodando a partir de `$HOME`. Conferir `git status` depois de rodar qualquer `init` de ferramenta. Com o hook RTK ativo, a saída de `ls`/`find`/`git` no terminal do agente vem comprimida; para saída exata usar `rtk proxy <cmd>`.

### Hook `sessionStart` no `hooks.json`

Os hooks existentes do `claude-mem` usam caminhos absolutos; o `sessionStart` foi registrado do mesmo jeito (`/Users/<usuario>/.cursor/hooks/session-scan.sh`), em vez do `./hooks/session-scan.sh` do snippet, para não depender de como o Cursor resolve caminho relativo. Backup antes de editar: `hooks.json.bak-<data>`.

### Governança copiada do repositório irmão

Os `docs/*` e o `AGENTS.md` iniciais vieram do repositório `Personal-MD-for-Claude` (`initProjectsInstall`), datados de 2026-10-06, com `~/.claude`, `CLAUDE.md`, `.cmd` e `CLAUDE_CONFIG_DIR`. Ao reaproveitar documentação entre as duas variantes, revisar destino, nomes de variáveis, nome do arquivo de instruções e os lançadores — e conferir cada regra contra o código desta variante antes de mantê-la `confirmada`.

### Comparar semver sem `sort -V`

`sort -V` existe no GNU coreutils e no `sort` do macOS atual, mas não em todo BSD/busybox, e o comportamento com prefixo `v` e sufixos varia. `_scan.sh` e o `.sh` usam `semver_maior()` em bash puro (três inteiros, `10#` para evitar octal, sufixo `-rc1` descartado); o `.ps1` usa `Test-SemverMaior` com `[int]::TryParse`. Para testar sem rede: gravar a versão desejada em `~/.cursor/.scan-cache/update-check.out` (cache de 24 h) e rodar `_scan.sh capacidades` com `CURSOR_CONFIG_DIR` apontando para uma pasta temporária.

### API de releases do GitHub sem token

`GET /repos/<owner>/<repo>/releases/latest` responde 404 enquanto não há release publicada (não é erro de rede) e tem limite anônimo de 60 requisições/hora por IP — por isso o cache de 24 h no `_scan.sh` e a falha silenciosa nos três lugares. O `sed` que extrai `tag_name` foi validado contra a resposta real de outro repositório (`rtk-ai/rtk`). Em PowerShell 5.1, forçar TLS 1.2 (`[Net.ServicePointManager]::SecurityProtocol`) antes do `Invoke-RestMethod`, senão a chamada falha em máquinas antigas.

### Limites do archify

`meta.views[].note` aceita no máximo 140 caracteres e `sublabel` de nó cabe em ~84 px; textos mais longos falham na validação (`schema/maxLength`) antes de renderizar. Encurtar em vez de quebrar linha.

## Histórico

| Data | Alteração |
| --- | --- |
| 2026-10-06 | Versão original no repositório irmão: BOM, ExecutionPolicy, Git Bash/WSL, winget e npx.cmd. |
| 2026-10-15 | Reescrito para o Cursor: BOM mantido, `CURSOR_CONFIG_DIR` para testes, sandbox × `pwsh`, shell persistente, `sed`/`perl`, comparação de tabelas, arquivos reais do Cursor, `rtk init`, hook absoluto, origem dos docs. |
| 2026-10-15 | ExecutionPolicy e `.cmd` (CRLF, sem acentos, `pwsh` → `powershell`). |
| 2026-10-15 | Semver sem `sort -V`, API de releases sem token (404 sem release, 60 req/h, TLS 1.2 no PS 5.1), limites do archify; teste e2e passa a esperar 21 `[pulado, sem TTY]`. |
