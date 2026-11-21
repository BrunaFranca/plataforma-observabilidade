# plataforma-observabilidade

[![ci](https://github.com/BrunaFranca/plataforma-observabilidade/actions/workflows/ci.yml/badge.svg)](https://github.com/BrunaFranca/plataforma-observabilidade/actions/workflows/ci.yml)

Plataforma de observabilidade **compartilhada e multi-tenant** para os meus projetos, num cluster Kubernetes (kind) próprio: **Mimir, Loki, Tempo e Grafana** (stack LGTM), com um gateway OpenTelemetry como porta de entrada.

```
 cluster do projeto A ─┐   OTLP / remote write
 cluster do projeto B ─┼──────────────────────▶  cluster "obs": gateway → Mimir · Loki · Tempo → Grafana
 cluster do projeto C ─┘   (X-Scope-OrgID = projeto)          cada projeto só vê os próprios dados
```

```bash
bash scripts/subir.sh          # cria o cluster e instala tudo (idempotente)
bash scripts/teste-tenants.sh  # prova o isolamento entre tenants
# Grafana: http://localhost:3300
```

Decisões em [docs/adr](docs/adr). Primeiro projeto a usar: [vida-da-bruna-api](https://github.com/BrunaFranca/vida-da-bruna-api), que tem o diagrama completo da arquitetura e os resultados dos game days.
