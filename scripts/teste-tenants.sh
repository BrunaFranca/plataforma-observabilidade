#!/usr/bin/env bash
# Teste de ponta a ponta do multi-tenancy: dois "projetos" falsos mandam métricas, traces e logs
# pela rede dos clusters (como um cluster de projeto faria), e cada um só pode enxergar os próprios dados.
# Uso: scripts/teste-tenants.sh   (com a plataforma no ar)
set -euo pipefail
IMG=ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.129.0
MIMIR=${MIMIR:-http://localhost:19009}

for t in teste-a teste-b; do
  for sinal in metrics traces logs; do
    docker run --rm --network kind "$IMG" "$sinal" \
      --otlp-endpoint obs-control-plane:30317 --otlp-insecure \
      --otlp-header "X-Scope-OrgID=\"$t\"" --service "servico-$t" \
      --duration 3s --rate 5 >/dev/null
  done
done

consultar() { # tenant → jobs que ele enxerga
  curl -s -H "X-Scope-OrgID: $1" "$MIMIR/prometheus/api/v1/query" \
    --data-urlencode 'query=count by (job) ({__name__=~".+", job=~"servico-.*"})' |
    grep -o '"job":"[^"]*"' | tr '\n' ' ' || true
}

for i in $(seq 1 20); do # o gateway agrupa em lotes; espera os dados chegarem
  [[ "$(consultar teste-a)" == *servico-teste-a* ]] && break
  sleep 3
done

a=$(consultar teste-a); b=$(consultar teste-b); n=$(consultar outro)
echo "teste-a vê: $a"; echo "teste-b vê: $b"; echo "outro vê:   ${n:-(nada)}"
[[ "$a" == '"job":"servico-teste-a" ' ]] || { echo "FALHOU: teste-a"; exit 1; }
[[ "$b" == '"job":"servico-teste-b" ' ]] || { echo "FALHOU: teste-b"; exit 1; }
[[ -z "$n" ]] || { echo "FALHOU: tenant sem dados enxergou algo"; exit 1; }
echo "OK: cada tenant só vê os próprios dados."
