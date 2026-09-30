#!/usr/bin/env bash
# Запускать от root/sudo на узле (нужен kubeconfig).
set -euo pipefail
export KUBECONFIG=${KUBECONFIG:-/etc/kubernetes/admin.conf}
NODE_IP=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NODEPORT=$(kubectl -n envoy-gateway-system get svc -l gateway.envoyproxy.io/owning-gateway-name=demo-gw \
  -o jsonpath='{.items[0].spec.ports[0].nodePort}')

echo "== 1. Gateway API =="
kubectl -n demo get gateway demo-gw
kubectl -n demo get httproute hello
BODY=$(curl -fsS "http://${NODE_IP}:${NODEPORT}/")
echo "ответ: ${BODY}"; [ "${BODY}" = "Hello World!" ]

echo "== 2. Prometheus =="
kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090:9090 >/dev/null 2>&1 &
PF=$!; trap 'kill $PF 2>/dev/null || true' EXIT; sleep 5
echo "targets up: $(curl -fsS 'localhost:9090/api/v1/query?query=count(up==1)' | sed 's/.*"value":\[[^,]*,"\([0-9]*\)".*/\1/')"
curl -fsS 'localhost:9090/api/v1/query?query=up{job="apiserver"}' | head -c 300; echo

echo "== 3. Логи (Loki) =="
MARK="verify-$(date +%s)"
curl -fsS "http://${NODE_IP}:${NODEPORT}/${MARK}" >/dev/null
kubectl -n logging port-forward svc/loki 3100:3100 >/dev/null 2>&1 &
PF2=$!; trap 'kill $PF $PF2 2>/dev/null || true' EXIT; sleep 10
curl -fsSG 'localhost:3100/loki/api/v1/query_range' \
  --data-urlencode "query={namespace_name=\"demo\"} |= \"${MARK}\"" | grep -q "${MARK}" \
  && echo "запись ${MARK} найдена в Loki" || { echo "запись не найдена"; exit 1; }
echo "OK"
