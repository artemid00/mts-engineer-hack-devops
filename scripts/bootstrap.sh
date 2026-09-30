#!/usr/bin/env bash
# Подготовка управляющей машины (Ubuntu 24.04): ansible + коллекции.
set -euo pipefail
sudo apt-get update -y
sudo apt-get install -y ansible python3-debian curl
ansible-galaxy collection install community.general ansible.posix
