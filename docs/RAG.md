# RAG e recuperação de contexto — Personal-MD-for-Cursor

> Contrato de recuperação de informação deste projeto: o que está indexado, o que **nunca** pode ser indexado, em que ordem consultar e quando reindexar.

Última atualização: 2026-10-15

---

## Capacidades do ambiente

Estado detectado em 2026-10-15. Ambiente muda; reconferir com `_scan.sh capacidades` quando algo aqui não bater.

| Capacidade | Situação | Uso neste projeto | Fallback em uso |
| --- | --- | --- | --- |
| MCP de memória | ambos — `claude-mem` e `ai-memory` cadastrados em `~/.cursor/mcp.json` (`[MCP_CURSOR]`); `claude-mem` respondeu a `save_memory`; `ai-memory` cadastrado (`http://127.0.0.1:49374/mcp`), binário `ai-memory` ausente no PATH | Histórico, decisões e armadilhas das sessões; `smart_search` para localizar trechos nos scripts | Glob/Grep com escopo restrito |
| skill `archify` | DISPONÍVEL (`~/.claude/skills/archify`, `node bin/archify.mjs doctor` ok) | `docs/arquitetura.html` a partir de `docs/archify/instalacao.workflow.json` | — |
| agentes do harness | DISPONÍVEIS como subagentes do Cursor (`planner`, `coder`, `code-reviewer`, `test-engineer`, `security-auditor`); `~/.cursor/agents/` vazio | Papéis de `docs/Harness.md`; rodaram inline nas tarefas de 2026-10-15 | papéis executados inline |
| skill `ui-ux-pro-max` | NÃO APLICÁVEL (sem frontend) | — | — |
| RTK | DISPONÍVEL (`rtk 1.0.1`, hook `preToolUse` em `~/.cursor/hooks.json`) | Saída de terminal comprimida; `rtk proxy <cmd>` para saída exata | — |
| hook `sessionStart` | ATIVO (`~/.cursor/hooks/session-scan.sh`) | `_scan.sh sessao` ao abrir a sessão; alimenta o cache de `projeto` | `_scan.sh projeto --no-cache` |

Capacidade ausente degrada o trabalho, **nunca o impede**. Instruções de instalação em `~/.cursor/templates/init-project/_capacidades.md`.

---

## Índices deste projeto

| Índice | Tipo | Conteúdo | Como atualizar |
| --- | --- | --- | --- |
| `Personal-MD-for-Cursor-geral` | corpus do `claude-mem` | **não criado** — repositório pequeno (sem código de aplicação); `smart_search` e Grep bastam | `build_corpus`, se um dia justificar (`/init-project --rag`) |
| `Personal-MD-for-Cursor-regras` | corpus do `claude-mem` | **não criado** — `docs/RegrasNegocio.md` tem 21 regras e cabe em uma leitura | idem |
| observações `claude-mem` (projeto `Personal-MD-for-Cursor`) | observações | 2 notas salvas em 2026-10-15 (decisões do pacote; ambiente Cursor: hooks, RTK, `CURSOR_CONFIG_DIR`) + capturas automáticas dos hooks | Automático pelos hooks; `save_memory` ao fim de tarefa significativa |
| wiki `ai-memory` | wiki markdown do `ai-memory` | a definir — workspace/projeto não consultados nesta sessão (`memory_status` não foi chamado) | Automático pelos hooks; `memory_write_page` só a pedido |
| Código-fonte | busca sob demanda | Scripts bash/PowerShell e Markdown do pacote | Não exige build — `smart_search`/Grep leem o disco |
| `docs/arquitetura.html` | HTML archify (workflow v2) | Fluxo de instalação navegável (companion de `docs/Arquitetura.md`) | `node ~/.claude/skills/archify/bin/archify.mjs deliver workflow docs/archify/instalacao.workflow.json docs/arquitetura.html --quality showcase --json` |

---

## Protocolo retrieval-first

**Ordem obrigatória.** Só avançar para o passo seguinte quando o anterior não responder.

1. **Pergunta sobre comportamento dos instaladores, do pacote ou da varredura** → `docs/RegrasNegocio.md`, pelo ID da regra (`RN-INSTALADOR-*`, `RN-PACOTE-*`, `RN-SCAN-*`, `RN-HOOK-*`).
2. **Pergunta sobre histórico, decisão anterior ou bug já resolvido** → `observation_search` (`claude-mem`); ou `memory_query` (`ai-memory`). `docs/Memoria.md` tem as armadilhas de ambiente já conhecidas.
3. **Localizar trecho** → `smart_search` → `smart_outline` → `smart_unfold`; ou Grep com escopo (`dist/init-project/`, raiz).
4. **Leitura completa de arquivos** — somente depois dos passos acima, e apenas nos arquivos identificados. Os quatro arquivos com a tabela de gatilhos e os três com `FILES` são os que mais precisam de leitura exata antes de editar.

O objetivo é não gastar contexto lendo arquivos inteiros para responder o que já está documentado ou indexado.

### Quando o RAG não serve

Recuperar não substitui ler o código nos casos em que a resposta precisa ser exata:

- Antes de editar um arquivo — ler o arquivo.
- Ao verificar se uma regra `⚠ inferida` é real — ler a implementação.
- Ao auditar segurança — ler, não recuperar.
- Ao conferir paridade entre as quatro cópias da tabela ou as três listas `FILES` — comparar os arquivos, não a memória.

---

## Exclusões de segurança

**Nunca indexar, nunca gravar em observação, nunca incluir em corpus:**

- `.env` e variantes (`.env.local`, `.env.production`).
- Secrets, chaves privadas, certificados, tokens.
- Credenciais de banco, strings de conexão com senha.
- Dumps de banco ou fixtures com dados pessoais reais.
- Logs de produção com dados de usuário.
- Conteúdo de `~/.cursor/mcp.json` e `~/.cursor/hooks.json` (podem conter URLs locais, caminhos e variáveis de ambiente de servidores MCP) — só nomes de servidores e eventos.
- Backups `~/.cursor/hooks.json.bak-*`.

Caminhos excluídos da indexação:

```text
.env*
~/.cursor/mcp.json
~/.cursor/hooks.json
~/.cursor/hooks.json.bak-*
~/.cursor/.scan-cache/
```

Se um segredo entrar em um índice por engano: reconstruir o índice do zero e registrar em `docs/Memoria.md`.

---

## Política de refresh

| Evento | Ação |
| --- | --- |
| Tarefa aprovada que muda decisão ou arquitetura | `save_memory` com a decisão e o motivo; regenerar `docs/arquitetura.html` via `archify` |
| Regras de negócio alteradas | Atualizar `docs/RegrasNegocio.md` (histórico); corpus `-regras` só se vier a existir |
| Mudança estrutural em `docs/Arquitetura.md` ou no fluxo dos instaladores | Editar `docs/archify/instalacao.workflow.json` e regenerar `docs/arquitetura.html` |
| Índice desatualizado ou suspeito | Reconstruir do zero |

`/learn-codebase` lê **todo arquivo-fonte na íntegra** — é caro e demorado. É **opt-in**: só executar com confirmação explícita do usuário, nunca automaticamente. Neste repositório não se justifica: são 5 scripts e um conjunto de Markdown.

---

## Estado atual

- Corpora existentes: nenhum deste projeto (decisão de 2026-10-15: não criar).
- Última indexação: nunca.
- Arquitetura HTML (`docs/arquitetura.html`): gerado em 2026-10-15 a partir de `docs/archify/instalacao.workflow.json` (workflow v2, perfil `showcase`).
- Observações registradas: 2 explícitas (`save_memory`) + capturas automáticas dos hooks do `claude-mem`.

---

## Histórico

| Data | Índice | Ação | Motivo |
| --- | --- | --- | --- |
| 2026-10-15 | `docs/arquitetura.html` | reconstruído | HTML copiado do repositório irmão descrevia o fluxo Windows 11 com `.cmd` e `~/.claude` |
| 2026-10-15 | corpora `claude-mem` | não criados | repositório pequeno; decisão registrada |
