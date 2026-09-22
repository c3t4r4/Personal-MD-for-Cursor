# RAG e recuperação de contexto — [NOME DO PROJETO]

> Contrato de recuperação de informação deste projeto: o que está indexado, o que **nunca** pode ser indexado, em que ordem consultar e quando reindexar.

Última atualização: [DATA]

---

## Capacidades do ambiente

Estado detectado em [DATA]. Ambiente muda; reconferir com `_scan.sh capacidades` quando algo aqui não bater.

| Capacidade | Situação | Uso neste projeto | Fallback em uso |
| --- | --- | --- | --- |
| MCP de memória | [DISPONÍVEL / INDISPONÍVEL] | Base — observações, corpora e busca AST | Glob/Grep com escopo restrito |
| skill `archify` | [DISPONÍVEL / INDISPONÍVEL] | Indispensável — `docs/arquitetura.html` a partir de `docs/Arquitetura.md` | HTML pendente; registrar em `docs/RAG.md` |
| agentes do harness | [DISPONÍVEIS / PARCIAIS / AUSENTES] | Papéis de `docs/Harness.md` com contexto isolado | papéis executados inline |
| skill `ui-ux-pro-max` | [DISPONÍVEL / INDISPONÍVEL / NÃO APLICÁVEL] | Apoio ao `docs/Frontend.md` | design system vindo da entrevista |

Capacidade ausente degrada o trabalho, **nunca o impede**. Instruções de instalação em `~/.cursor/templates/init-project/_capacidades.md`.

Se nenhum backend de recuperação estiver disponível, registrar aqui e usar Glob/Grep com escopo restrito.

---

## Índices deste projeto

| Índice | Tipo | Conteúdo | Como atualizar |
| --- | --- | --- | --- |
| `[PROJETO]-geral` | corpus do MCP de memória | Decisões, correções e descobertas do projeto | `build_corpus` |
| `[PROJETO]-regras` | corpus do MCP de memória | Filtrado por `types=decision,feature` — apoio ao `RegrasNegocio.md` | `build_corpus` |
| Código-fonte | busca AST sob demanda | Símbolos, funções, classes | Não exige build — `smart_search` lê o disco |
| `docs/arquitetura.html` | HTML archify | Arquitetura navegável (companion de `docs/Arquitetura.md`) | skill `archify` (tipo `architecture`) |

---

## Protocolo retrieval-first

**Ordem obrigatória.** Só avançar para o passo seguinte quando o anterior não responder.

1. **Pergunta sobre comportamento ou regra de negócio** → `docs/RegrasNegocio.md`, pelo ID da regra ou pelo índice de telas.
2. **Pergunta sobre histórico, decisão anterior ou bug já resolvido** → `observation_search`; se houver corpus primado, `query_corpus`.
3. **Localizar código** → `smart_search` (encontra o símbolo) → `smart_outline` (estrutura do arquivo) → `smart_unfold` (só o trecho necessário).
4. **Leitura completa de arquivos** — somente depois dos passos acima, e apenas nos arquivos identificados.

O objetivo é não gastar contexto lendo arquivos inteiros para responder o que já está documentado ou indexado.

### Quando o RAG não serve

Recuperar não substitui ler o código nos casos em que a resposta precisa ser exata:

- Antes de editar um arquivo — ler o arquivo.
- Ao verificar se uma regra `⚠ inferida` é real — ler a implementação.
- Ao auditar segurança — ler, não recuperar.

---

## Exclusões de segurança

**Nunca indexar, nunca gravar em observação, nunca incluir em corpus:**

- `.env` e variantes (`.env.local`, `.env.production`).
- Secrets, chaves privadas, certificados, tokens.
- Credenciais de banco, strings de conexão com senha.
- Dumps de banco ou fixtures com dados pessoais reais.
- Logs de produção com dados de usuário.
- [OUTROS CAMINHOS ESPECÍFICOS DESTE PROJETO]

Caminhos excluídos da indexação:

```text
[LISTA DE CAMINHOS]
```

Se um segredo entrar em um índice por engano: reconstruir o índice do zero e registrar em `docs/Memoria.md`.

---

## Política de refresh

| Evento | Ação |
| --- | --- |
| Tarefa aprovada que muda decisão ou arquitetura | Reconstruir `[PROJETO]-geral`; regenerar `docs/arquitetura.html` via `archify` |
| Regras de negócio alteradas | Reconstruir `[PROJETO]-regras` |
| Mudança estrutural grande no código / `docs/Arquitetura.md` | Regenerar `docs/arquitetura.html` via skill `archify` |
| Índice desatualizado ou suspeito | Reconstruir do zero |

`/learn-codebase` lê **todo arquivo-fonte na íntegra** — é caro e demorado. É **opt-in**: só executar com confirmação explícita do usuário, nunca automaticamente.

---

## Estado atual

- Corpora existentes: [LISTA OU "nenhum"]
- Última indexação: [DATA OU "nunca"]
- Arquitetura HTML (`docs/arquitetura.html`): [gerado / desatualizado / pendente — skill archify ausente]
- Observações registradas: [QUANTIDADE OU "a definir"]

---

## Histórico

| Data | Índice | Ação | Motivo |
| --- | --- | --- | --- |
| [DATA] | [ÍNDICE] | [criado / reconstruído / removido] | [MOTIVO] |
