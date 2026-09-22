# Capacidades — fallback e instalação

Ler **somente quando a FASE 0.5 detectar uma capacidade ausente que seja relevante para este projeto**. Se está tudo disponível, este arquivo não é lido.

O `/init-project` **nunca instala nada**. Não instala plugins/MCP automaticamente, não edita hooks/settings, não baixa arquivo. Apresenta a instrução e segue com o fallback.

## Regra geral

Capacidade ausente **degrada, nunca interrompe**. O comando conclui em qualquer ambiente. O que faltou é registrado em `docs/RAG.md` e no resumo final, para que a decisão de instalar fique com o usuário.

## MCP de memória

| | |
| --- | --- |
| Para que serve | Corpora do projeto, `smart_search`/`smart_outline`/`smart_unfold` (busca AST sem indexação), `observation_search`, `timeline` |
| Como detectar | Chamar `list_corpora`. Se a ferramenta não existir, está ausente |
| Fallback | `Glob` e `Grep` com escopo. Registrar em `docs/RAG.md`: "sem backend de RAG — recuperação por busca textual" |

Instalar o MCP de memória no Cursor em Settings → MCP, a partir do repositório `thedotmack/claude-mem`. No Cursor ele entra como servidor MCP. As ferramentas do `/init-project` são `list_corpora`, `build_corpus`, `observation_search`, `smart_search`, `smart_outline`, `smart_unfold` e `query_corpus`.

Sem ele, a FASE 7 não constrói corpus nenhum e o protocolo *retrieval-first* de `docs/RAG.md` passa a começar direto pelo `docs/RegrasNegocio.md` e pela busca textual.

## Skill `archify` (indispensável)

| | |
| --- | --- |
| Para que serve | Gerar e manter `docs/arquitetura.html`, versão navegável em HTML da arquitetura descrita em `docs/Arquitetura.md` |
| Como detectar | `_scan.sh capacidades`, seção `[SKILLS]` (lista qualquer skill instalada genericamente, sem necessidade de checagem específica) |
| Fallback | Pular a geração/atualização do HTML. Registrar a pendência em `docs/RAG.md` e no resumo final |

Esta skill **não é opcional** neste pacote: é o único gerador de visão de arquitetura navegável. Sempre tentada na FASE 6 e a cada gatilho de `docs/Arquitetura.md` na sincronização contínua. Ausência ainda **degrada, nunca interrompe** — o comando conclui normalmente, só sem o HTML.

Instalar:

```text
npx -y skills add tt-a1i/archify --skill archify --agent cursor --global --copy --yes
```

Não usar `graphify` nem `graphify-out/` — este pacote padroniza exclusivamente em `archify` + `docs/arquitetura.html`.

## Agentes do harness

| | |
| --- | --- |
| Para que serve | Planner, Coder, Validator, Tester e Security Specialist com contexto isolado |
| Como detectar | `_scan.sh capacidades`, seção `[AGENTES]` |
| Fallback | Executar os papéis inline, na conversa principal. O fluxo e o protocolo `APPROVED`/`REJECTED` não mudam |

Agentes esperados: `planner`, `coder`, `code-reviewer`, `test-engineer`, `security-auditor`.

No Cursor, papéis do harness rodam via Task/subagentes (tipos como `planner`, `coder`, `code-reviewer`, `test-engineer`, `security-auditor`) ou inline. Agentes customizados seguem a documentação atual do Cursor — ausência de agente nunca dispensa o papel.

## Skill `ui-ux-pro-max`

| | |
| --- | --- |
| Para que serve | Apoio ao `docs/Frontend.md`: design system, paletas, tipografia, componentes |
| Como detectar | `_scan.sh capacidades`, seção `[SKILLS]` |
| Fallback | Preencher `docs/Frontend.md` apenas com o que a entrevista confirmou; o não decidido vira `a definir` |

Instalar: copiar a skill para `~/.cursor/skills/ui-ux-pro-max/` (ou instalar via fluxo de skills do Cursor, se disponível).

Só é relevante quando o projeto tem frontend.

## Skill `/learn-codebase` (vem com o MCP de memória)

Lê **todo arquivo-fonte na íntegra**. Custa muito em repositório grande.

Nunca executar automaticamente. Oferecer como sugestão no resumo final, com o custo declarado, e deixar a decisão com o usuário.

## Como reportar

Na FASE 0.5, apresentar uma tabela com uma linha por capacidade — `disponível` ou `ausente`, e o fallback que será usado. Repetir no resumo final e gravar em `docs/RAG.md`, datada. Mencionar instalação **apenas** para o que é relevante a este projeto: sem frontend, não sugerir `ui-ux-pro-max`.
