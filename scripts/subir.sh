#!/usr/bin/env bash
# Sobe (ou atualiza) a plataforma: cluster kind "obs" + LGTM multi-tenant + Grafana.
# Idempotente: rodar de novo só aplica o que mudou.
set -euo pipefail
cd "$(dirname "$0")/.."

GRAFANA_CHART_VERSAO="${GRAFANA_CHART_VERSAO:-10.5.15}"
NS=observabilidade

if ! kind get clusters | grep -qx obs; then
  kind create cluster --config kind/obs.yaml
fi
kubectl config use-context kind-obs >/dev/null

helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update grafana >/dev/null

helm upgrade --install lgtm charts/lgtm -n "$NS" --create-namespace --wait --timeout 5m
helm upgrade --install grafana grafana/grafana -n "$NS" --version "$GRAFANA_CHART_VERSAO" \
  -f grafana/values.yaml --wait --timeout 5m

echo
echo "Plataforma no ar:"
echo "  Grafana ............ http://localhost:3300"
echo "  Entrada OTLP ....... <nó obs>:30317 (de outros clusters) / localhost:14317 (do PC)"
echo "  Mimir .............. <nó obs>:30909 (de outros clusters) / localhost:19009 (do PC)"
echo "  Rede dos clusters .. $(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' obs-control-plane) (IP do nó obs na rede 'kind')"
