# Kubernetes + Gateway API + Prometheus + Fluent Bit/Loki

Демо-инфраструктура на одном узле: nginx публикуется через Envoy Gateway (Kubernetes Gateway API),
метрики собирает Prometheus, логи — Fluent Bit → Loki. Всё разворачивается Helm-чартами (Ansible только ставит кластер и вызывает helm): сторонние чарты — Envoy Gateway, kube-prometheus-stack, Loki, Fluent Bit; собственный чарт [charts/demo](charts/demo) — nginx, Gateway, HTTPRoute, PodMonitor, datasource Loki.

## Архитектура

```
Пользователь ─HTTP:30080─> Envoy Gateway (Gateway/HTTPRoute) ─> Service hello ─> nginx (2 pod)
                                   │                                   │ stdout (JSON access-log)
                          Prometheus (kube-prometheus-stack)      Fluent Bit (DaemonSet) ─> Loki ─> Grafana
```

## Версии (источник истины: [ansible/group_vars/all.yml](ansible/group_vars/all.yml))

| Компонент | Версия |
|---|---|
| ОС (тестировалось) | Ubuntu 24.04 — TODO: подтвердить после прогона |
| Kubernetes (kubeadm) | 1.36 |
| CRI | CRI-O v1.36 |
| CNI | Cilium 1.20.2 |
| Gateway API реализация | Envoy Gateway v1.9.2 (Gateway API CRD v1.6.1) (ресурсы: GatewayClass, EnvoyProxy, Gateway, HTTPRoute) |
| Мониторинг | kube-prometheus-stack 91.8.2 (Helm) |
| Логи | Fluent Bit chart 0.58.2 (app 5.1.2) + Loki chart 18.13.7 (app 3.7.8) |

## Требования
Чистая VM Ubuntu 24.04, 4 vCPU / 8 ГБ RAM / 30 ГБ диска, доступ в интернет, root/sudo.

## Развёртывание
```bash
sudo apt-get update && sudo apt-get install -y git make   # на чистой Ubuntu их нет
git clone <URL> && cd mts-engineers-hack-devops
export GRAFANA_ADMIN_PASSWORD='<свой пароль>'   # опционально
sudo -E make deps cluster deploy
sudo make verify
```
Повторный запуск `make cluster deploy` безопасен (идемпотентно). Сброс: `make clean`.

## Проверка
- **Gateway API:** `curl http://<IP узла>:30080/` → `Hello World!`; `kubectl -n demo get gateway,httproute`.
- **Мониторинг:** `kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090` →
  Status → Targets (UP); запрос `up`, `rate(apiserver_request_total[5m])`.
- **Логи:** после `curl` — в Grafana (Explore → Loki) запрос `{namespace_name="demo"}`;
  автоматически: `scripts/verify-all.sh`.

## Дополнительно
TODO: перечислить реализованные улучшения (PodMonitor Envoy, securityContext, …).

## Ограничения
Loki без постоянного хранилища (демо); один узел, без HA; TLS не настроен.
