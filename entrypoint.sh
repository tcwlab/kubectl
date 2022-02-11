#!/usr/bin/env bash
set -eo pipefail

if [ -n "${KUBE_CONFIG_B64}" ]; then
	echo -n "${KUBE_CONFIG_B64}" | base64 -d >/home/kubectlusr/.kube/config
	chmod 600 /home/kubectlusr/.kube/config
fi

if [ ! -f /home/kubectlusr/.kube/config ]; then
	echo "Please mount your kubeconfig file to /.kube or pass it as base64 to environment variable KUBE_CONFIG_B64"
	exit 1
else
	exec "$@"
fi
