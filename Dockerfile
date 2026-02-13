#####
# STEP 1: build base image
#####
FROM --platform=$BUILDPLATFORM alpine:3 AS base
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN apk add -U --no-cache bash coreutils git && \
    apk upgrade && \
    rm -rf /var/cache/apk/*

#####
# STEP 2: install dependencies
#####
FROM base AS dependencies
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apk add -U --no-cache curl && \
    case "$(apk --print-arch)" in \
        aarch64) export LOCAL_ARCH="arm64" ;; \
        x86_64) export LOCAL_ARCH="amd64" ;; \
    esac; \
    export K8S_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -Ls 'https://dl.k8s.io/release/'"$(curl -L -s https://dl.k8s.io/release/stable.txt)"'/bin/linux/'"${LOCAL_ARCH}"'/kubectl' -o /usr/bin/kubectl && \
    chmod +rx /usr/bin/kubectl && \
    KUSTOMIZE_URL=$(curl -s 'https://api.github.com/repos/kubernetes-sigs/kustomize/releases' | grep 'browser_download.*linux_' | grep "${LOCAL_ARCH}" | cut -d '"' -f 4 | sort -V | tail -n 1) && \
    curl -Ls ${KUSTOMIZE_URL} -o kustomize.tgz && \
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
