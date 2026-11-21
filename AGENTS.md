# AGENTS.md

Contexto para assistentes de IA neste repositório.

- **O que é:** a plataforma de observabilidade compartilhada da Bruna (DevOps/SRE): cluster kind `obs` com LGTM multi-tenant. Projetos (ex.: `vida-da-bruna-api`) mandam dados para cá. Decisão em `docs/adr/0001-plataforma-compartilhada.md`.
- **Repo público:** nada de dados pessoais nem de configuração de empregador.
- **Idioma:** comentários, commits e docs em português. Conventional Commits.
- **Subir/atualizar:** `bash scripts/subir.sh` (idempotente). Apagar: `bash scripts/derrubar.sh`. Teste de isolamento: `bash scripts/teste-tenants.sh`.
- **Novo projeto:** acrescentar em `tenants` (`charts/lgtm/values.yaml`) e rodar `subir.sh`. Fontes no Grafana: uids `mimir-<tenant>`, `loki-<tenant>`, `tempo-<tenant>`, `alertmanager-<tenant>`.
- **Portas no PC:** Grafana `localhost:3300`, OTLP `localhost:14317`, Mimir `localhost:19009`. De outros clusters kind: `obs-control-plane:30317` (OTLP) e `:30909` (Mimir), sempre com `X-Scope-OrgID`.
- **Contêineres** rodam não-root com sistema de arquivos somente leitura: tudo que grava vai para `/data`, `/loki`, `/var/tempo` ou `/tmp`.
- **StatefulSet em CrashLoop não é substituído no upgrade:** apague o pod (`kubectl -n observabilidade delete pod <nome>-0`).
- No Windows da Bruna: kind e helm via winget (pasta `WinGet\Packages`), Docker CLI em `C:\Program Files\Docker\Docker\resources\bin`. No Git Bash, use `MSYS_NO_PATHCONV=1` para caminhos dentro de contêineres.
