#!/usr/bin/env bash
# Runs inside the image (see the build task in .mise.toml). Encrypts a Secret
# with SOPS for a throwaway age key and builds it with Kustomize through the
# ksops plugin, the way Argo CD's repo server builds the Secrets in
# k8s-deployment.
set -euo pipefail

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
cd "${work}"

age-keygen -o key.txt 2>/dev/null
recipient="$(age-keygen -y key.txt)"

cat > secret.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: smoke
stringData:
  token: decrypted
EOF
sops --encrypt --age "${recipient}" --encrypted-regex '^(data|stringData)$' --in-place secret.yaml
if grep -q 'token: decrypted' secret.yaml; then
  echo "sops left the Secret unencrypted" >&2
  exit 1
fi

cat > generator.yaml <<'EOF'
apiVersion: viaduct.ai/v1
kind: ksops
metadata:
  name: smoke
files:
  - secret.yaml
EOF
cat > kustomization.yaml <<'EOF'
generators:
  - generator.yaml
EOF

# Argo CD passes these build options (kustomize.buildOptions in argocd-cm).
out="$(SOPS_AGE_KEY_FILE="${work}/key.txt" kustomize build --enable-alpha-plugins --enable-helm .)"
if ! grep -q 'token: decrypted' <<<"${out}"; then
  echo "kustomize build did not decrypt the Secret:" >&2
  echo "${out}" >&2
  exit 1
fi
echo "sops $(sops --version --disable-version-check | head -n1 | cut -d' ' -f2) and ksops decrypt through kustomize $(kustomize version)"
