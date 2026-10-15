# Memória — Personal-MD-for-Cursor

Última atualização: 2026-10-15

## Aprendizados

### Windows PowerShell 5.1 e acentos

O Windows ainda abre `powershell.exe` na versão 5.1. Esse host lê um `.ps1` sem BOM como ANSI e quebra o português e os símbolos (`✓`, `ℹ`, `≥`). `install-init-project.ps1` é gravado em UTF-8 **com BOM**; `.gitattributes` garante CRLF no checkout Windows e mantém LF nos `.sh`, `.md`, `.mdc` e `.json`. A ferramenta de escrita do Cursor gera arquivos sem BOM — conferir com `head -c 3 | xxd` (`efbb bf`) depois de reescrever o `.ps1`.

### ExecutionPolicy e o `.cmd`

`Bypass` fica na linha `-ExecutionPolicy Bypass -File` dentro de `install-init-project.cmd`; a política da máquina não é alterada. O `.cmd` prefere `pwsh` (PowerShell 7) e cai para `powershell` (5.1). `cmd.exe` tem comportamento indefinido com arquivos em LF puro, por isso `.gitattributes` força CRLF em `*.cmd` e o arquivo é mantido sem acentos (página de código do console não é garantida).

### Testar os instaladores sem tocar `~/.cursor`

Os dois instaladores e o hook honram `CURSOR_CONFIG_DIR`. Teste padrão: `CURSOR_CONFIG_DIR=/tmp/x ./install-init-project.sh ./dist/init-project` e `CURSOR_CONFIG_DIR=/tmp/y pwsh -NoProfile -NonInteractive -File ./install-init-project.ps1 ./dist/init-project`, depois `diff -r /tmp/x /tmp/y`. Segunda rodada deve dar 20 `[pulado, sem TTY]`. Cenário de falha: remover um dos 18 arquivos do pacote → exit 1 e zero arquivos copiados.

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

## Histórico

| Data | Alteração |
| --- | --- |
| 2026-10-06 | Versão original no repositório irmão: BOM, ExecutionPolicy, Git Bash/WSL, winget e npx.cmd. |
| 2026-10-15 | Reescrito para o Cursor: BOM mantido, `CURSOR_CONFIG_DIR` para testes, sandbox × `pwsh`, shell persistente, `sed`/`perl`, comparação de tabelas, arquivos reais do Cursor, `rtk init`, hook absoluto, origem dos docs. |
| 2026-10-15 | ExecutionPolicy e `.cmd` (CRLF, sem acentos, `pwsh` → `powershell`). |
