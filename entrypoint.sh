#!/usr/bin/env ash
set -e

if [ -n "${KUBE_CONFIG_B64}" ]; then
	echo -n "${KUBE_CONFIG_B64}" | base64 -d >/home/kubeusr/.kube/config
fi

if [ ! -f /home/kubeusr/.kube/config ]; then
	echo "Please mount your kubeconfig file to /home/kubeusr/.kube/config or pass it as base64 to environment variable KUBE_CONFIG_B64"
	exit 1
fi

exec "$@"
