ANSIBLE := cd ansible && ansible-playbook

.PHONY: deps cluster deploy verify all clean
deps:      ## Ansible + коллекции (Ubuntu 24.04)
	./scripts/bootstrap.sh
cluster:   ## kubeadm single-node + CRI-O + Cilium
	$(ANSIBLE) cluster.yml
deploy:    ## Envoy Gateway, Prometheus, Loki, Fluent Bit, приложение
	$(ANSIBLE) addons.yml
verify:    ## 3 проверки: gateway, мониторинг, логи
	./scripts/verify-all.sh
all: deps cluster deploy verify
clean:     ## kubeadm reset (повторные прогоны с нуля)
	./scripts/reset.sh
