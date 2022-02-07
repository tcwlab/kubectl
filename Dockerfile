#####
# STEP 1: build base image
#####
FROM alpine:3.15 AS base
RUN apk add -U --no-cache bash && \
    apk upgrade && \
    rm -rf /var/cache/apk/*

#####
# STEP 2: install dependencies
#####
FROM base AS dependencies
RUN apk add -U --no-cache wget curl && \
    wget -q "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -O /usr/bin/kubectl && \
    chmod +rx /usr/bin/kubectl && \
    wget -q $(curl -s "https://api.github.com/repos/kubernetes-sigs/kustomize/releases" | grep "browser_download.*linux_amd64" | cut -d '"' -f 4 | sort -V | tail -n 1) -O kustomize.tgz && \
    tar xzf kustomize.tgz -C /usr/bin && \
    chmod +rx /usr/bin/kustomize && \
    wget -q "https://get.helm.sh/helm-$(curl -s "https://api.github.com/repos/helm/helm/releases" | grep "tag_name" | cut -d '"' -f 4 | sort -V | grep -v "rc." | tail -n 1)-linux-amd64.tar.gz" -O helm.tgz && \
    tar xzf helm.tgz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +rx /usr/bin/helm

#####
# STEP 3: build production image
#####
FROM base AS release
COPY --from=dependencies /usr/bin /usr/bin
CMD ["sh"]
