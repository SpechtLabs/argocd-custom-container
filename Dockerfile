FROM argoproj/argocd:v2.5.2

ARG SOPS_VERSION="v3.7.3"
ARG HELM_SECRETS_VERSION="3.13.0"

ENV HOME=/home/argocd
ENV XDG_CONFIG_HOME=$HOME/.config

ENV KUSTOMIZE_PLUGIN_HOME=$XDG_CONFIG_HOME/kustomize/plugin
ENV PLUGIN_PATH=$KUSTOMIZE_PLUGIN_HOME/viaduct.ai/v1/ksops
ENV HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/"
ENV SOPS_AGE_KEY_FILE=/helm-secrets/age_private_key

USER root

COPY helm-wrapper.sh /usr/local/bin/

# Update system
RUN apt-get update && \
    apt-get install -y curl gpg age && \
    apt-get clean

# Install SOPS
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* &&    \
    curl -o /usr/local/bin/sops -L https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux && \
    chmod +x /usr/local/bin/sops

# Install ksops
RUN mkdir -p $PLUGIN_PATH
RUN curl -o ./ksops.tar.gz -L https://github.com/viaduct-ai/kustomize-sops/releases/latest/download/ksops_latest_Linux_x86_64.tar.gz && \
    tar -xf ./ksops.tar.gz -C $PLUGIN_PATH && \
    chmod 777 $PLUGIN_PATH/ksops # fuck this...

# Rename helm binaries (helm and helm2) with to helm.bin and helm2.bin
RUN cd /usr/local/bin && \
    mv helm helm.bin

# Rename helm-wrapper.sh to helm and ensure the wrapper is also used when helm2 is being used
RUN cd /usr/local/bin && \
    mv helm-wrapper.sh helm && \
    chmod +x helm

RUN chown -R argocd ${HOME}

# helm secrets plugin should be installed as user argocd or it won't be found
USER argocd

# Install helm plugin
RUN /usr/local/bin/helm.bin plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION}

