#!/usr/bin/env bash
# Полный сброс узла для повторного чистого прогона.
set -euo pipefail
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d "$HOME/.kube" /root/.kube
echo "Готово. Запустите: make cluster deploy"
