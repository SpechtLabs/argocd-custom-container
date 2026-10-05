# ArgoCD Custom Container

[![Publish](https://github.com/SpechtLabs/argocd-custom-container/actions/workflows/publish.yaml/badge.svg)](https://github.com/SpechtLabs/argocd-custom-container/actions/workflows/publish.yaml)

🚀 **A custom ArgoCD container with built-in support for**:

- [`ksops`] – SOPS integration for Kustomize to handle encrypted secrets in Kubernetes manifests.
- [`sops`] – the SOPS CLI itself, with `age` and `gpg` for the keys.

## ✨ Features

- Supports **KSOPS** for using SOPS-encrypted secrets in Kustomize overlays.
- Based on the official **ArgoCD container**, ensuring full compatibility.
- Ideal for **GitOps workflows** that require secret management in Kubernetes.

## 🔧 Usage

Modify your `argocd-repo-server` deployment to use this custom image and mount the
Secret that holds the age key at `/helm-secrets/` (the image reads the key from
`/helm-secrets/age_private_key`):

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
          image: ghcr.io/spechtlabs/argocd-custom-container:main
          volumeMounts:
            - mountPath: /helm-secrets/
              name: helm-secrets
      volumes:
        - name: helm-secrets
          secret:
            secretName: helm-secrets
```

### 🔑 Using KSOPS with Kustomize

ksops is installed as a legacy Kustomize exec plugin, so Argo CD has to run
Kustomize with `--enable-alpha-plugins` (`kustomize.buildOptions` in
`argocd-cm`). Ensure your kustomization.yaml includes an encrypted secret. See
[Getting Started | (ksops Readme.md)]

```yaml
apiVersion: viaduct.ai/v1
kind: ksops
metadata:
  name: my-secret
files:
  - secrets.enc.yaml
```

## 🛠 Development

The tools are pinned in `.mise.toml`. `mise run check` lints the Dockerfile,
the smoke test, YAML and the workflows, builds the image for your platform and
runs `test/smoke.sh` in it, which decrypts a SOPS-encrypted Secret through
Kustomize and ksops. It needs a Docker daemon.

[`ksops`]: https://github.com/viaduct-ai/kustomize-sops
[`sops`]: https://github.com/getsops/sops
[Getting Started | (ksops Readme.md)]: https://github.com/viaduct-ai/kustomize-sops?tab=readme-ov-file#getting-started-tutorial
