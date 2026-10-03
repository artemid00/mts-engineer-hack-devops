#!/usr/bin/env bash
# Полный сброс узла для повторного чистого прогона (kubeadm + остатки CNI/etcd/iptables).
set -uo pipefail
sudo kubeadm reset -f
sudo systemctl stop kubelet 2>/dev/null || true
sudo crictl rmp -fa 2>/dev/null || true
sudo rm -rf /etc/cni/net.d /var/lib/cni /var/lib/etcd /etc/kubernetes "$HOME/.kube" /root/.kube
for i in cilium_host cilium_net cilium_vxlan; do sudo ip link delete "$i" 2>/dev/null || true; done
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X || true
sudo ip6tables -F 2>/dev/null || true
sudo systemctl restart crio
echo "Готово. Запустите: sudo -E make cluster deploy verify"
