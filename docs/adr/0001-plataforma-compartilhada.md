# 0001: Plataforma de observabilidade compartilhada e multi-tenant

**Data:** 21/11/2026 · **Status:** Aceita

## Contexto
O projeto `vida-da-bruna-api` precisa de observabilidade quando rodar no Kubernetes (etapa 5 do lab). A Bruna quer que **outros projetos futuros** usem a mesma observabilidade, sem subir um stack por projeto.

## Decisão
- **Um cluster kind só para observabilidade** (`obs`), separado dos clusters de projeto, e **um repo próprio** (este).
- Stack **LGTM** (Loki, Grafana, Tempo, Mimir) em modo monolítico (laboratório), com um chart próprio (`charts/lgtm`), e Grafana pelo chart oficial.
- **Multi-tenant:** cada projeto é um tenant (`X-Scope-OrgID`). Os dados ficam isolados; o Grafana ganha fontes de dados por tenant (`mimir-<tenant>`, `loki-<tenant>`, `tempo-<tenant>`).
- **Entrada única:** um gateway OTLP (OpenTelemetry Collector) recebe tudo dos projetos e repassa mantendo o tenant (`headers_setter` + `batch` por tenant). Métricas de infraestrutura podem ir direto ao Mimir (remote write com o cabeçalho).
- **"Você constrói, você opera":** dashboards e regras de SLO ficam no repo de cada projeto, que os envia para a plataforma (API do ruler do Mimir e API do Grafana). A plataforma só fornece a infraestrutura.
- Clusters conversam pela rede Docker `kind`: os projetos chegam ao nó `obs-control-plane` pelas NodePorts 30317 (OTLP) e 30909 (Mimir).

## Consequências
- Adicionar um projeto = acrescentar o tenant em `charts/lgtm/values.yaml` (`tenants`) e rodar `scripts/subir.sh`.
- Em produção seria object storage (S3/GCS), componentes distribuídos e autenticação na entrada; aqui é disco local e rede fechada no PC.
