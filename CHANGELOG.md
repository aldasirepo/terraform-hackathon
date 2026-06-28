# Changelog — terraform-hackathon

## [2.0.0] — 2026-06-27

### Added
- `modules/aws-lb-controller/` — IRSA + Helm release AWS Load Balancer Controller v1.7.2
- `modules/velero/` — S3 bucket, IRSA, Helm release Velero 6.0.0 (backup diário)
- `modules/eks-cluster/irsa.tf` — OIDC Provider + IRSA role para volunteer-service (DynamoDB)
- `modules/kubernetes/grafana-secret.tf` — random_password para Grafana admin (sem hardcode)
- `CD/apps/monitoring/argocd-app-otel.yaml` — OpenTelemetry Collector via ArgoCD
- `CD/apps/monitoring/argocd-app-tempo.yaml` — Grafana Tempo (distributed tracing) via ArgoCD
- `CD/apps/monitoring/argocd-app-velero.yaml` — Velero schedule via ArgoCD
- `environments/dr/outputs.tf` — outputs para ambiente DR
- `environments/dr/terraform.tfvars.example` — exemplo sem secrets

### Changed
- `environments/prod/providers.tf` — backend S3 agora inclui `dynamodb_table` para state lock
- `environments/prod/providers.tf` — adicionados providers `tls` e `random`
- `environments/prod/modules.tf` — inclui módulos alb_controller, velero, argocd
- `environments/dr/main.tf` — backend S3 com lock + providers kubectl/tls
- `modules/argocd/main.tf` — substituído helm argocd-apps quebrado por `kubectl_manifest`
- `modules/eks-cluster/outputs.tf` — adicionados outputs OIDC provider + volunteer role ARN
- `modules/kubernetes/secrets.tf` — variável `db_user` → `rds_username` (consistência)
- `modules/kubernetes/variables.tf` — idem
- `CD/apps/monitoring/argocd-app-prometheus.yaml` — removida senha hardcoded, usa existingSecret
- `CD/apps/kustomization.yaml` — adicionados otel, tempo, velero

### Removed
- `fix.py` — script perigoso que corrompia HCL (deletar via PowerShell)
- `modules/*/placeholder.tf` — arquivos vazios (deletar via PowerShell)
- `.gitkeep` em diretórios com conteúdo real (deletar via PowerShell)
- `.github/workflows/test.yml` — workflow vazio (deletar via PowerShell)

### Security
- `aws_account_id` movido para GitHub Secret `TF_VAR_aws_account_id`
- Grafana admin password gerada via `random_password` (nunca em código)
- CI/CD: substituído `aws-access-key-id/secret-key` por `role-to-assume` (OIDC)
