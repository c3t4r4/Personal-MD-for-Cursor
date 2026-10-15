# Organograma — Personal-MD-for-Cursor

Última atualização: 2026-10-15

## Relação entre as peças

```mermaid
flowchart TD
    subgraph origem["Máquina de origem"]
        CURSOR_SRC["~/.cursor (customizado)"]
        PKG["package-init-project.sh"]
        DIST["dist/init-project/<br/>19 arquivos + 2 opcionais"]
        CURSOR_SRC -->|lê| PKG
        PKG -->|publica| DIST
    end

    DIST -->|USB, rede ou clone| ENTREGA["Pasta do pacote"]

    ENTREGA --> SH["install-init-project.sh<br/>macOS / Linux"]
    ENTREGA --> CMD_WIN["install-init-project.cmd<br/>Windows: ExecutionPolicy Bypass só no processo"]
    CMD_WIN -->|pwsh ou powershell| PS1["install-init-project.ps1<br/>PowerShell 5.1+"]
    ENTREGA -.->|direto, se a política permitir| PS1

    SH --> DEST["Destino<br/>CURSOR_CONFIG_DIR ou ~/.cursor<br/>(%USERPROFILE%\\.cursor no Windows)"]
    PS1 --> DEST

    DEST --> RULE["rules/personal-md-global.mdc"]
    DEST --> CMD["commands/init-project.md"]
    DEST --> TPL["templates/init-project/*"]
    DEST --> HOOK["hooks/session-scan.sh<br/>+ hooks.json.snippet"]

    RULE -.->|referencia| RTK["~/.cursor/RTK.md"]
    CMD -->|usa| TPL
    HOOK -->|roda| SCAN["_scan.sh sessao"]
    TPL --- SCAN
```

## O que acontece dentro de um instalador

```mermaid
flowchart LR
    A["Resolver pasta do pacote<br/>arg → ./dist → destino/initProjectsInstall"] --> B{"19 arquivos<br/>presentes?"}
    B -->|não| X["Listar ausentes<br/>exit 1, nada copiado"]
    B -->|sim| C["Para cada arquivo"]
    C --> D{"Existe no destino?"}
    D -->|não| E["[novo] copiar"]
    D -->|sim| F{"TTY?"}
    F -->|não| G["[pulado, sem TTY]"]
    F -->|sim| H{"s / N / d"}
    H -->|d| I["mostrar diff"] --> H
    H -->|s| J["[sobrescrito]"]
    H -->|N| K["[mantido]"]
    E & G & J & K --> L["Resumo: novos / sobrescritos / pulados"]
    L --> M["Relatório informativo<br/>_scan.sh capacidades, RTK, archify,<br/>hook sessionStart, versão do pacote, backend de memória"]
    M --> N["exit 0"]
```

## Versão, release e aviso de atualização

```mermaid
flowchart LR
    V["dist/init-project/VERSION<br/>+ CHANGELOG.md"] -->|"git tag v&lt;VERSION&gt; + push"| W["GitHub Actions<br/>release.yml"]
    W -->|"valida: tag = VERSION, changelog,<br/>shellcheck, paridade FILES"| R["GitHub Release<br/>tar.gz, zip, instaladores, SHA256SUMS"]
    R --> API["api.github.com/.../releases/latest<br/>(tag_name)"]
    API -.->|"5 s, anônimo, silencioso"| INST["install-init-project.sh / .ps1<br/>-- Versão do pacote --"]
    API -.->|"cache 24 h"| SCAN["_scan.sh capacidades<br/>[VERSAO]"]
    SCAN --> CMD0["/init-project FASE 0.5<br/>avisa uma vez se disponivel"]
    INST --> AV["Aviso + URL<br/>nunca baixa, nunca instala"]
    CMD0 --> AV
```

`PERSONAL_MD_NO_UPDATE_CHECK=1` corta as duas linhas pontilhadas. Atualizar continua sendo rodar o instalador com a pasta da release extraída.

## Como o pacote governa um projeto

```mermaid
flowchart TD
    G["Regra global (alwaysApply)"] --> I["/init-project"]
    I -->|FASE 0.5| C["_scan.sh capacidades<br/>+ list_corpora / memory_status"]
    I -->|FASE 2| P["_scan.sh projeto"]
    I -->|FASE 4| Q["Entrevista enxuta"]
    I -->|FASE 6| T["Templates → AGENTS.md + docs/*<br/>README.md se ausente"]
    T --> S["Sincronização obrigatória<br/>12 documentos em toda tarefa"]
    S --> H["Harness: Planner → Coder →<br/>Validator / Tester / Security"]
```

Os instaladores não decidem o que o `/init-project` faz: eles só colocam a regra, o comando, os templates e o hook no lugar certo. O `.cmd` não decide o que copiar — só inicia o PowerShell. O `.ps1` não substitui o `_scan.sh`; no Windows a varredura depende de Git Bash ou WSL.

## Histórico

| Data | Alteração |
| --- | --- |
| 2026-10-06 | Versão original no repositório irmão (Claude Code), em ASCII, com o ramo `.cmd`. |
| 2026-10-15 | Reescrito em Mermaid para o Cursor: destino `~/.cursor`/`CURSOR_CONFIG_DIR`, sem `.cmd`, diagrama interno do instalador e diagrama de governança. |
| 2026-10-15 | Ramo Windows ganha o lançador `install-init-project.cmd` → `.ps1`. |
| 2026-10-15 | 19 arquivos; relatório do instalador inclui versão do pacote; novo diagrama "Versão, release e aviso de atualização". |
