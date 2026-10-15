# AGENTS.md — Personal-MD-for-Cursor

## Ordem obrigatória de leitura

Antes de qualquer plano, leitura de código, comando ou alteração:

1. `~/.cursor/rules/personal-md-global.mdc`
2. `./AGENTS.md` (este arquivo)
3. `./docs/RegrasNegocio.md`
4. `./docs/Arquitetura.md`
5. `./docs/Organograma.md`
6. `./docs/Infraestrutura.md`, se existir
7. `./docs/API.md`, se existir
8. `./docs/Frontend.md`, se existir
9. `./docs/Auth.md`, se existir
10. `./docs/RAG.md`
11. `./docs/Progresso.md`
12. `./docs/Memoria.md`
13. `./docs/Harness.md`

## Regras obrigatórias

- Ler a regra global do Cursor antes deste arquivo.
- Ler este arquivo antes de criar planos.
- Ler este arquivo antes de executar alterações.
- Consultar `docs/RegrasNegocio.md` antes de alterar qualquer comportamento do sistema.
- Atualizar `docs/RegrasNegocio.md` sempre que o comportamento mudar.
- Seguir o protocolo retrieval-first de `docs/RAG.md` antes de leitura ampla de código.
- Utilizar o backend de memória detectado (`claude-mem` e `ai-memory`, ambos cadastrados em `~/.cursor/mcp.json`) no início da sessão e após tarefas significativas, com as ferramentas da tabela `Memória do projeto` da regra global.
- Utilizar RTK conforme as instruções globais.
- Seguir as preferências de stack por ecossistema de `~/.cursor/rules/personal-md-global.mdc` — sugerir e confirmar, nunca aplicar sem autorização; nunca propor migrar o que este projeto já usa.
- Consultar a seção `Performance` da regra global antes de decidir estrutura de Docker, paginação de API ou carregamento de frontend.
- Iniciar tarefas não triviais em modo plan.
- Criar planos em `.cursor/plans/`, sempre na raiz deste projeto (onde está este arquivo), nunca em um subdiretório de trabalho.
- Nomear planos com nome da pasta, timestamp e sufixo descritivo.
- Não sobrescrever arquivos sem confirmação.
- Consultar documentação antes de alterar API, frontend, autenticação, banco ou infraestrutura.
- Executar a sincronização obrigatória de documentação ao fim de **toda** implementação, conforme a seção `## Sincronização de documentação` deste arquivo.
- Utilizar Planner, Coder, Validator, Tester e Security Specialist.
- Delegar Planner, Validator e Security Specialist com profundidade `profunda`, e Coder e Tester com profundidade `econômica`, usando `model: "inherit"` salvo quando o usuário indicar outro modelo, conforme a tabela `Profundidade por papel` de `~/.cursor/rules/personal-md-global.mdc`.
- Uma tarefa só está concluída após aprovação do Validator, Tester e Security Specialist e com a tabela de sincronização preenchida.

## Regras específicas deste repositório

Este repositório **é a fonte** do pacote que outros projetos instalam. Toda edição em `dist/init-project/` muda a governança de todas as máquinas que instalarem o pacote depois.

- `dist/init-project/` é o artefato. Editar os arquivos ali e, quando o ambiente local for a referência, regenerar com `./package-init-project.sh`.
- A tabela de gatilhos da sincronização (12 linhas) vive em **quatro cópias** que devem ser idênticas palavra por palavra: `rules/personal-md-global.mdc` (tabela + modelo de plano), `templates/init-project/AGENTS.md.tpl.md`, `templates/init-project/Harness.md.tpl.md` e o modelo de plano em `commands/init-project.md`. Alterou uma, propaga às outras na mesma tarefa.
- A lista `FILES` (18 arquivos) existe em três lugares e deve ser idêntica: `install-init-project.sh`, `install-init-project.ps1`, `package-init-project.sh`.
- Nenhum script imprime conteúdo de `mcp.json`, `hooks.json` ou `.env`. `_scan.sh capacidades` lista só **nomes** de servidores MCP.
- Nenhum instalador instala nada sem confirmação explícita num terminal interativo. Sem TTY, apenas informa o comando manual (rtk e archify, nos dois instaladores).
- `install-init-project.cmd` é só lançador do `.ps1`: nunca duplicar lógica de cópia nele.
- Mensagens ao usuário em português; texto dos templates em português.
- Scripts bash: `set -uo pipefail` (sem `-e` no instalador, de propósito), `shellcheck -S warning` limpo. PowerShell: compatível com Windows PowerShell 5.1 (sem `??`, ternário ou `-Parallel`), UTF-8 **com BOM**, CRLF no checkout Windows via `.gitattributes`.

## Stack confirmada

- Objetivo: distribuir e instalar a governança Personal-MD (`/init-project` + regra global + templates + hook `sessionStart`) em máquinas com Cursor, sem zip, sem sobrescrever em silêncio.
- Frontend: nenhum.
- Backend: nenhum — scripts Bash (macOS/Linux, `_scan.sh`, hook), PowerShell (Windows) com lançador `.cmd`, templates Markdown/MDC.
- Banco de dados: nenhum.
- ORM: nenhum.
- Autenticação: nenhuma.
- API própria: não.
- APIs externas: nenhuma em runtime. Os instaladores apenas sugerem `brew`/`curl`/`winget` (rtk) e `npx skills add` (archify), sempre após confirmação.
- Docker: nenhum.
- Testes: sem suíte automatizada. Validação por `bash -n`, `shellcheck`, parse do `.ps1` via `[System.Management.Automation.Language.Parser]::ParseFile`, execução ponta a ponta dos dois instaladores com `CURSOR_CONFIG_DIR` apontando para pasta temporária e comparação `diff -r` das árvores geradas.

## Comandos

- Instalação (macOS/Linux): `./install-init-project.sh [pasta-do-pacote]`
- Instalação (Windows): `install-init-project.cmd [pasta-do-pacote]` (lançador com `ExecutionPolicy Bypass` só no processo; prefere `pwsh`) ou `.\install-init-project.ps1 [pasta-do-pacote]`
- Empacotar a partir de `~/.cursor`: `./package-init-project.sh`
- Empacotar só a partir do repo: `PACKAGE_FROM_REPO=1 ./package-init-project.sh`
- Varredura de capacidades: `bash dist/init-project/templates/init-project/_scan.sh capacidades`
- Varredura do projeto: `bash dist/init-project/templates/init-project/_scan.sh projeto --no-cache`
- Lint bash: `shellcheck -S warning install-init-project.sh dist/init-project/templates/init-project/_scan.sh dist/init-project/hooks/session-scan.sh`
- Parse do PowerShell: `pwsh -NoProfile -Command '[System.Management.Automation.Language.Parser]::ParseFile("./install-init-project.ps1",[ref]$null,[ref]$e); $e'`
- Teste ponta a ponta sem tocar `~/.cursor`: `CURSOR_CONFIG_DIR=/tmp/x ./install-init-project.sh ./dist/init-project` e `CURSOR_CONFIG_DIR=/tmp/y pwsh -NoProfile -NonInteractive -File ./install-init-project.ps1 ./dist/init-project`
- Build / Typecheck / Docker: não se aplica.

## Regras de negócio

- Consultar `docs/RegrasNegocio.md` antes de alterar telas, fluxos, validações ou lógica de decisão.
- Verificar se a mudança pedida contradiz alguma regra `confirmada`; se contradisser, parar e perguntar.
- Registrar toda regra nova com ID estável (`RN-<DOMINIO>-<NNN>`).
- Regras extraídas do código entram como `⚠ inferida` até confirmação do usuário.
- Nunca apagar regra: marcar como `revogada`, com data e motivo.
- Tarefa que muda comportamento não está concluída com `RegrasNegocio.md` desatualizado.

## Sincronização de documentação

Regra herdada de `~/.cursor/rules/personal-md-global.mdc`, seção `Sincronização obrigatória de documentação`, que é a fonte única. Replicada aqui para leitura sem o arquivo global à mão.

Toda tarefa que altere código, configuração, schema, API, autenticação, infraestrutura ou documentação técnica somente está concluída depois que os doze documentos abaixo forem avaliados e cada um receber um estado explícito: `atualizado`, `criado`, `sem alteração` ou `n/a`.

A sincronização é etapa de **toda implementação**. `/init-project` cria e audita a estrutura; ele não é o mecanismo de manutenção.

| Documento | Gatilho | Sem gatilho |
| --- | --- | --- |
| `docs/RegrasNegocio.md` | comportamento, validação, permissão, máquina de estado ou regra de cálculo mudou | `sem alteração` |
| `docs/Arquitetura.md` | camada, módulo, padrão, dependência, fluxo de dados, schema ou decisão arquitetural mudou — regenerar também `docs/arquitetura.html` via skill `archify`, quando disponível | `sem alteração` |
| `docs/Organograma.md` | módulo, camada, fluxo de negócio, tela, integração externa ou relação entre componentes mudou de forma que o diagrama fique desatualizado | `sem alteração` |
| `docs/Infraestrutura.md` | Docker, Compose, deploy, rede, volume, variável de ambiente, build ou observabilidade mudou | `sem alteração` / `n/a` |
| `docs/API.md` | rota, método, payload, header, código HTTP, autenticação de endpoint, paginação ou filtro mudou | `sem alteração` / `n/a` |
| `docs/Frontend.md` | componente, tela, rota de UI, token de design, padrão de estado ou acessibilidade mudou | `sem alteração` / `n/a` |
| `docs/Auth.md` | authn, authz, sessão, token, papel, permissão ou política de senha mudou | `sem alteração` / `n/a` |
| `docs/RAG.md` | fonte indexada, corpus, exclusão de segurança ou capacidade do ambiente mudou | `sem alteração` |
| `docs/Progresso.md` | **sempre** — toda tarefa concluída gera uma linha | nunca `sem alteração` |
| `docs/Memoria.md` | aprendizado não óbvio, armadilha de ambiente, comando descoberto ou decisão com motivo | `sem alteração` |
| `docs/Harness.md` | papel, agente, fluxo de aprovação ou ferramenta do harness mudou | `sem alteração` |
| `README.md` | nome, propósito, instruções de instalação/uso, stack, comandos principais, configuração ou licença do projeto mudou | `sem alteração` |

Como ler a tabela:

- `docs/arquitetura.html` é o companion renderizado de `docs/Arquitetura.md`, gerado pela skill `archify`. Não é um documento novo — não altera a contagem dos doze — e é regenerado sob o mesmo gatilho da linha acima. Skill `archify` ausente degrada (HTML fica pendente, registrado no resumo da tarefa), nunca bloqueia.
- `sem alteração` é julgamento declarado, não silêncio. Documento não avaliado bloqueia a conclusão da tarefa.
- `n/a` vale apenas para documento condicional que este projeto legitimamente não tem.
- `README.md` segue a regra dos documentos permanentes: nunca `n/a`. Se não existir, é criado com a estrutura mínima descrita na regra global; se existir, é corrigido no ponto que ficou falso.
- Gatilho disparado em documento condicional ausente **obriga a criar o documento**, a partir de `~/.cursor/templates/init-project/<Nome>.md.tpl.md`.
- Documento `atualizado` ganha linha datada no seu `## Histórico`. Documento `sem alteração` não recebe linha.
- A regra não se aplica a resposta puramente conversacional, sem alteração de arquivo.

A tabela é preenchida três vezes: no plano pelo Planner (estado previsto), na implementação pelo Coder (estado real) e no resumo final, conferida pelo Validator contra o diff.

Neste projeto, os documentos condicionais têm o seguinte estado inicial:

- `docs/Infraestrutura.md`: n/a — criar quando houver Docker, deploy ou infraestrutura.
- `docs/API.md`: n/a — criar quando houver API própria ou integração relevante.
- `docs/Frontend.md`: n/a — criar quando houver frontend.
- `docs/Auth.md`: n/a — criar quando houver autenticação.

Atenção à dupla camada: uma mudança em `dist/init-project/templates/init-project/*.tpl.md` altera o **template** que outros projetos usam, não um documento deste repositório. A sincronização acima se refere aos documentos **deste** repositório (`docs/*` e `README.md` na raiz).

## Regras de recuperação de contexto

- Seguir a ordem definida em `docs/RAG.md`: regras de negócio → observações/corpus → busca AST → leitura de arquivos.
- Nunca indexar `.env`, secrets, chaves, tokens ou dados pessoais.
- `/learn-codebase` é opt-in e caro — só com confirmação explícita.

## Regras de autenticação

Não se aplica a este repositório. Se algum dia houver armazenamento de senha: Argon2id, nunca MD5/SHA-1/SHA-256 puro, nunca texto puro, nunca em log, e criar `docs/Auth.md` antes.

## Regras de API

Não se aplica. Criar `docs/API.md` a partir do template assim que houver o primeiro endpoint ou integração externa relevante.

## Regras de frontend

Não se aplica. Criar `docs/Frontend.md` a partir do template assim que houver a primeira tela.

## Referências

Documentos permanentes — sempre existem e sempre entram na sincronização:

- Regras de negócio: `docs/RegrasNegocio.md`
- Arquitetura: `docs/Arquitetura.md`
- Organograma: `docs/Organograma.md`
- RAG: `docs/RAG.md`
- Harness: `docs/Harness.md`
- Progresso: `docs/Progresso.md`
- Memória: `docs/Memoria.md`
- README do projeto: `README.md`

Documentos condicionais — existem quando o projeto os justifica e devem ser **criados** assim que o gatilho correspondente disparar:

- Infraestrutura: `docs/Infraestrutura.md`
- API: `docs/API.md`
- Frontend: `docs/Frontend.md`
- Auth: `docs/Auth.md`
