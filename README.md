# ArgoCD Custom Container

[![Docker Build](https://github.com/SpechtLabs/argocd-custom-container/actions/workflows/docker-build.yaml/badge.svg)](https://github.com/SpechtLabs/argocd-custom-container/actions/workflows/docker-build.yaml)

🚀 **A custom ArgoCD container with built-in support for**:

- [`helm-secrets`] – Securely manage Helm charts with encrypted secrets.
- [`ksops`] – SOPS integration for Kustomize to handle encrypted secrets in Kubernetes manifests.

## ✨ Features

- Pre-configured with **Helm-Secrets** for managing encrypted Helm values.
- Supports **KSOPS** for using SOPS-encrypted secrets in Kustomize overlays.
- Based on the official **ArgoCD container**, ensuring full compatibility.
- Ideal for **GitOps workflows** that require secret management in Kubernetes.

## 🔧 Usage

Modify your `argocd-repo-server` deployment to use this custom image and mount the

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-repo-server
spec:
  template:
    spec:
      containers:
        - name: argocd-repo-server
          image: ghcr.io/spechtlabs/argocd-custom-container:latest
          volumeMounts:
            - mountPath: /helm-secrets/
              name: helm-secrets
      volumes:
        - name: helm-secrets
          secret:
            secretName: helm-secrets
```

### 🛠 Using Helm Secrets

After deploying, you can use helm-secrets inside ArgoCD. See [Usage | (helm-secrets wiki)]

```bash
helm secrets template mychart
```

### 🔑 Using KSOPS with Kustomize

Ensure your kustomization.yaml includes an encrypted secret. See [Getting Started | (ksops Readme.md)]

```yaml
apiVersion: viaduct.ai/v1
kind: ksops
metadata:
  name: my-secret
files:
  - secrets.enc.yaml
```

[`helm-secrets`]: https://github.com/jkroepke/helm-secrets
[`ksops`]: https://github.com/viaduct-ai/kustomize-sops
[Usage | (helm-secrets wiki)]: https://github.com/jkroepke/helm-secrets/wiki/Usage
[Getting Started | (ksops Readme.md)]: https://github.com/viaduct-ai/kustomize-sops?tab=readme-ov-file#getting-started-tutorial
