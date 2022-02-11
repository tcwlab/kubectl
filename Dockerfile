#####
# STEP 1: build base image
#####
FROM alpine:3.15 AS base
RUN apk add -U --no-cache bash coreutils git && \
    apk upgrade && \
    rm -rf /var/cache/apk/*

#####
# STEP 2: install dependencies
#####
FROM base AS dependencies
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apk add -U --no-cache curl && \
    curl -Ls 'https://dl.k8s.io/release/'"$(curl -L -s https://dl.k8s.io/release/stable.txt)"'/bin/linux/amd64/kubectl' -o /usr/bin/kubectl && \
    chmod +rx /usr/bin/kubectl && \
    curl -Ls "$(curl -s 'https://api.github.com/repos/kubernetes-sigs/kustomize/releases' | grep 'browser_download.*linux_amd64' | cut -d '"' -f 4 | sort -V | tail -n 1)" -o kustomize.tgz && \
    tar xzf kustomize.tgz -C /usr/bin && \
    chmod +rx /usr/bin/kustomize && \
    curl -Ls 'https://get.helm.sh/helm-'"$(curl -s 'https://api.github.com/repos/helm/helm/releases' | grep 'tag_name' | cut -d '"' -f 4 | sort -V | grep -v 'rc.' | tail -n 1)"'-linux-amd64.tar.gz' -o helm.tgz && \
    tar xzf helm.tgz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +rx /usr/bin/helm

#####
# STEP 3: build production image
#####
FROM base AS release
COPY --from=dependencies /usr/bin /usr/bin
RUN addgroup -S kubeusr && adduser -S kubeusr -G kubeusr
COPY /entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh && \
    mkdir /.kube && \
    ln -s /.kube /home/kubeusr/.kube && \
    chown -R kubeusr:kubeusr /home/kubeusr && \
    chown -R kubeusr:kubeusr /.kube
USER kubeusr
VOLUME ["/.kube"]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
