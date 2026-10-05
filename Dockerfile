# Argo CD's own image, with SOPS and the ksops Kustomize plugin added so the
# repo server can decrypt SOPS-encrypted secrets while it builds manifests.
FROM quay.io/argoproj/argocd:v3.5.3

# Set by BuildKit to the platform each image of a multi-platform build is for.
ARG TARGETARCH

# renovate: datasource=github-releases depName=getsops/sops
ARG SOPS_VERSION="v3.13.3"
# renovate: datasource=github-releases depName=viaduct-ai/kustomize-sops
ARG KSOPS_VERSION="v4.5.1"

ENV HOME=/home/argocd
ENV XDG_CONFIG_HOME=$HOME/.config

# Kustomize finds the legacy exec plugin for `kind: ksops` at
# $KUSTOMIZE_PLUGIN_HOME/viaduct.ai/v1/ksops/ksops when it runs with
# --enable-alpha-plugins.
ENV KUSTOMIZE_PLUGIN_HOME=$XDG_CONFIG_HOME/kustomize/plugin
ENV PLUGIN_PATH=$KUSTOMIZE_PLUGIN_HOME/viaduct.ai/v1/ksops
# The age key lives in the helm-secrets Secret that the repo server mounts
# here; the path is part of the deployment, so it keeps its old name.
ENV SOPS_AGE_KEY_FILE=/helm-secrets/age_private_key

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# The base image has gpg and gpg-agent already, which SOPS uses for PGP keys;
# the only recommended package it would add is bash-completion.
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl gpg age && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Both downloads are checked against the checksums their release publishes;
# the awk lookup prints nothing for a file the list doesn't have, which
# sha256sum then rejects.
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) ksops_arch="x86_64" ;; \
        arm64) ksops_arch="arm64" ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    tmp="$(mktemp -d)"; \
    verify() { \
        printf '%s  %s\n' "$(awk -v f="$2" '$2 == f { print $1 }' "$1")" "${tmp}/$2" \
            | sha256sum --check --strict; \
    }; \
    sops="sops-${SOPS_VERSION}.linux.${TARGETARCH}"; \
    sops_url="https://github.com/getsops/sops/releases/download/${SOPS_VERSION}"; \
    curl -fsSL -o "${tmp}/${sops}" "${sops_url}/${sops}"; \
    curl -fsSL -o "${tmp}/sops.sums" "${sops_url}/sops-${SOPS_VERSION}.checksums.txt"; \
    verify "${tmp}/sops.sums" "${sops}"; \
    install -m 0755 "${tmp}/${sops}" /usr/local/bin/sops; \
    ksops="ksops_${KSOPS_VERSION#v}_Linux_${ksops_arch}.tar.gz"; \
    ksops_url="https://github.com/viaduct-ai/kustomize-sops/releases/download/${KSOPS_VERSION}"; \
    curl -fsSL -o "${tmp}/${ksops}" "${ksops_url}/${ksops}"; \
    curl -fsSL -o "${tmp}/ksops.sums" "${ksops_url}/checksums.txt"; \
    verify "${tmp}/ksops.sums" "${ksops}"; \
    tar -xzf "${tmp}/${ksops}" -C "${tmp}" ksops; \
    mkdir -p "${PLUGIN_PATH}"; \
    install -m 0755 "${tmp}/ksops" "${PLUGIN_PATH}/ksops"; \
    rm -rf "${tmp}"; \
    chown -R argocd "${HOME}"

USER $ARGOCD_USER_ID
