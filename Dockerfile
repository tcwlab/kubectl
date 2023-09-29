#####
# STEP 1: build base image
#####
FROM alpine:3.18@sha256:eece025e432126ce23f223450a0326fbebde39cdf496a85d8c016293fc851978 AS base
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
    chmod +rx /usr/bin/kustomize

#####
# STEP 3: build production image
#####
FROM base AS release
COPY --from=dependencies /usr/bin /usr/bin
RUN addgroup -S kubectlusr && adduser -S kubectlusr -G kubectlusr
COPY /entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh && \
    mkdir /.kube && \
    ln -s /.kube /home/kubectlusr/.kube && \
    chown -R kubectlusr:kubectlusr /home/kubectlusr && \
    chown -R kubectlusr:kubectlusr /.kube
USER kubectlusr
VOLUME ["/.kube"]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
