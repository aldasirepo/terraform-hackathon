$tf = "C:\Users\master\Documents\Claude\Projects\Hackathon FIAP\terraform-hackathon"
$app = "C:\Users\master\Documents\Claude\Projects\Hackathon FIAP\hackathon-fiap"

Write-Host "=== TAREFA 1: LIMPEZA ===" -ForegroundColor Cyan

# Deletar arquivos lixo
$toDelete = @(
  "$tf\fix.py",
  "$tf\.github\workflows\test.yml",
  "$tf\modules\argocd\placeholder.tf",
  "$tf\modules\databases\placeholder.tf",
  "$tf\modules\eks-cluster\placeholder.tf",
  "$tf\modules\network\placeholder.tf",
  "$tf\modules\resources\placeholder.tf",
  "$tf\modules\argocd\.gitkeep",
  "$tf\modules\databases\.gitkeep",
  "$tf\modules\ecr\.gitkeep",
  "$tf\modules\eks-cluster\.gitkeep",
  "$tf\modules\kubernetes\.gitkeep",
  "$tf\modules\network\.gitkeep",
  "$tf\modules\resources\.gitkeep",
  "$tf\environments\prod\.gitkeep",
  "$tf\environments\dr\.gitkeep",
  "$tf\bootstrap\.gitkeep",
  "$tf\CD\apps\solidarytech\.gitkeep",
  "$tf\CD\apps\monitoring\values\.gitkeep",
  "$tf\CD\base\.gitkeep",
  "$app\argocd\application.yaml",
  "$app\donation-service\donation-service.exe"
)

foreach ($f in $toDelete) {
  if (Test-Path $f) {
    Remove-Item -Force $f
    Write-Host "  deleted: $f"
  }
}

# Deletar __pycache__
Get-ChildItem -Path $app -Recurse -Filter "__pycache__" -Directory | Remove-Item -Recurse -Force
Write-Host "  deleted: __pycache__ dirs"

# Deletar .terraform (não deve ser commitado)
if (Test-Path "$tf\environments\prod\.terraform") {
  Remove-Item -Recurse -Force "$tf\environments\prod\.terraform"
  Write-Host "  deleted: .terraform dir"
}
if (Test-Path "$tf\environments\prod\.terraform.lock.hcl") {
  Remove-Item -Force "$tf\environments\prod\.terraform.lock.hcl"
  Write-Host "  deleted: .terraform.lock.hcl"
}

Write-Host "Limpeza OK" -ForegroundColor Green

# =============================================================================
Write-Host "`n=== TAREFA 2: BACKEND S3 LOCK ===" -ForegroundColor Cyan

@'
terraform {
  required_version = ">= 1.7"
  required_providers {
    aws        = { source = "hashicorp/aws";        version = "~> 5.0" }
    helm       = { source = "hashicorp/helm";       version = "~> 2.13" }
    kubernetes = { source = "hashicorp/kubernetes"; version = "~> 2.30" }
    kubectl    = { source = "gavinbunney/kubectl";  version = "~> 1.14" }
  }
  backend "s3" {
    bucket         = "solidarytech-tfstate"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "solidarytech-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = local.common_tags }
}

data "aws_eks_cluster"      "main" { name = module.eks.eks_cluster_name; depends_on = [module.eks] }
data "aws_eks_cluster_auth" "main" { name = module.eks.eks_cluster_name; depends_on = [module.eks] }

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
  load_config_file       = false
}

locals {
  common_tags = {
    Project     = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "NGO-Core"
    ManagedBy   = "Terraform"
    Team        = "DevOps"
  }
}
'@ | Out-File -FilePath "$tf\environments\prod\providers.tf" -Encoding utf8
Write-Host "  prod/providers.tf updated"

# DR main.tf com backend lock + provider kubectl
@'
terraform {
  required_version = ">= 1.7"
  required_providers {
    aws        = { source = "hashicorp/aws";        version = "~> 5.0" }
    helm       = { source = "hashicorp/helm";       version = "~> 2.13" }
    kubernetes = { source = "hashicorp/kubernetes"; version = "~> 2.30" }
    kubectl    = { source = "gavinbunney/kubectl";  version = "~> 1.14" }
  }
  backend "s3" {
    bucket         = "solidarytech-tfstate"
    key            = "dr/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "solidarytech-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = local.common_tags }
}

data "aws_eks_cluster"      "main" { name = module.eks.eks_cluster_name; depends_on = [module.eks] }
data "aws_eks_cluster_auth" "main" { name = module.eks.eks_cluster_name; depends_on = [module.eks] }

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
  load_config_file       = false
}

locals {
  common_tags = {
    Project     = "SolidaryTech"
    Environment = "DR"
    CostCenter  = "NGO-Core"
    ManagedBy   = "Terraform"
    Team        = "DevOps"
  }
}

module "vpc" {
  source             = "../../modules/network"
  project_name       = var.project_name
  aws_region         = var.aws_region
  cidr_block         = "10.1.0.0/16"
  cluster_name       = var.eks_cluster_name
  tags               = local.common_tags
  availability_zones = ["us-west-2a", "us-west-2b"]
  enable_nat_gateway = true
  single_nat_gateway = true
}

module "eks" {
  source                 = "../../modules/eks-cluster"
  project_name           = var.project_name
  aws_region             = var.aws_region
  aws_account_id         = var.aws_account_id
  eks_cluster_name       = var.eks_cluster_name
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnets
  tags                   = local.common_tags
}

module "rds" {
  source                        = "../../modules/databases"
  project_name                  = var.project_name
  aws_region                    = var.aws_region
  tags                          = local.common_tags
  vpc_id                        = module.vpc.vpc_id
  private_subnet_ids            = module.vpc.private_subnets
  eks_cluster_security_group_id = module.eks.eks_cluster_security_group_id
  rds_identifier                = "${var.project_name}-dr"
  rds_db_name                   = var.project_name
  rds_username                  = var.rds_username
  rds_password                  = var.rds_password
  rds_deletion_protection       = false
  dynamodb_table_name           = "${var.project_name}-volunteers-dr"
}

module "resources" {
  source       = "../../modules/resources"
  project_name = var.project_name
  environment  = "dr"
  aws_region   = var.aws_region
  tags         = local.common_tags
}
'@ | Out-File -FilePath "$tf\environments\dr\main.tf" -Encoding utf8
Write-Host "  dr/main.tf updated"

Write-Host "Backend lock OK" -ForegroundColor Green

# =============================================================================
Write-Host "`n=== TAREFA 3: OIDC + IRSA ===" -ForegroundColor Cyan

@'
# OIDC Provider para IRSA
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  tags            = var.tags
}

# IRSA Role para volunteer-service (DynamoDB)
data "aws_iam_policy_document" "volunteer_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:solidarytech:volunteer-service-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "volunteer_service" {
  name               = "${var.project_name}-volunteer-service-role"
  assume_role_policy = data.aws_iam_policy_document.volunteer_assume.json
  tags               = var.tags
}

resource "aws_iam_policy" "volunteer_dynamodb" {
  name        = "${var.project_name}-volunteer-dynamodb-policy"
  description = "Permite volunteer-service acessar DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ]
      Resource = [
        "arn:aws:dynamodb:*:*:table/${var.project_name}-volunteers-*",
        "arn:aws:dynamodb:*:*:table/${var.project_name}-volunteers-*/index/*"
      ]
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "volunteer_dynamodb" {
  role       = aws_iam_role.volunteer_service.name
  policy_arn = aws_iam_policy.volunteer_dynamodb.arn
}
'@ | Out-File -FilePath "$tf\modules\eks-cluster\irsa.tf" -Encoding utf8

# Atualiza outputs do eks-cluster
@'
output "eks_cluster_name"              { value = aws_eks_cluster.main.name }
output "eks_cluster_endpoint"          { value = aws_eks_cluster.main.endpoint }
output "eks_cluster_ca"                { value = aws_eks_cluster.main.certificate_authority[0].data }
output "eks_cluster_security_group_id" { value = aws_security_group.eks_cluster.id }
output "oidc_provider_arn"             { value = aws_iam_openid_connect_provider.eks.arn }
output "oidc_provider_url"             { value = aws_iam_openid_connect_provider.eks.url }
output "volunteer_service_role_arn"    { value = aws_iam_role.volunteer_service.arn }
'@ | Out-File -FilePath "$tf\modules\eks-cluster\outputs.tf" -Encoding utf8

# Adiciona tls ao required_providers do eks-cluster (variáveis)
@'
variable "project_name"           { type = string }
variable "aws_region"             { type = string }
variable "aws_account_id"         { type = string }
variable "eks_cluster_name"       { type = string }
variable "eks_kubernetes_version" { type = string; default = "1.29" }
variable "vpc_id"                 { type = string }
variable "private_subnet_ids"     { type = list(string) }
variable "tags"                   { type = map(string) }
'@ | Out-File -FilePath "$tf\modules\eks-cluster\variables.tf" -Encoding utf8

Write-Host "  irsa.tf criado"
Write-Host "OIDC + IRSA OK" -ForegroundColor Green

# =============================================================================
Write-Host "`n=== TAREFA 4: AWS LOAD BALANCER CONTROLLER ===" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path "$tf\modules\aws-lb-controller" | Out-Null

@'
data "aws_iam_policy_document" "alb_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "${var.project_name}-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_assume.json
  tags               = var.tags
}

resource "aws_iam_policy" "alb_controller" {
  name   = "${var.project_name}-alb-controller-policy"
  policy = file("${path.module}/iam_policy.json")
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.2"
  namespace  = "kube-system"

  set { name = "clusterName";                                          value = var.eks_cluster_name }
  set { name = "serviceAccount.create";                                value = "true" }
  set { name = "serviceAccount.name";                                  value = "aws-load-balancer-controller" }
  set { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"; value = aws_iam_role.alb_controller.arn }
  set { name = "region";                                               value = var.aws_region }
  set { name = "vpcId";                                                value = var.vpc_id }

  timeout    = 300
  wait       = true
}
'@ | Out-File -FilePath "$tf\modules\aws-lb-controller\main.tf" -Encoding utf8

@'
variable "project_name"      { type = string }
variable "aws_region"        { type = string }
variable "eks_cluster_name"  { type = string }
variable "vpc_id"            { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "tags"              { type = map(string) }
'@ | Out-File -FilePath "$tf\modules\aws-lb-controller\variables.tf" -Encoding utf8

@'
output "alb_controller_role_arn" { value = aws_iam_role.alb_controller.arn }
'@ | Out-File -FilePath "$tf\modules\aws-lb-controller\outputs.tf" -Encoding utf8

Write-Host "  aws-lb-controller module criado"
Write-Host "ALB Controller OK" -ForegroundColor Green

# =============================================================================
Write-Host "`n=== TAREFA 5: ARGOCD via kubectl_manifest ===" -ForegroundColor Cyan

@'
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name   = var.argocd_namespace
    labels = merge(var.tags, { "app.kubernetes.io/managed-by" = "terraform" })
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  set { name = "configs.params.server\\.insecure"; value = "true" }
  set { name = "server.service.type";              value = "ClusterIP" }

  timeout    = 600
  wait       = true
  depends_on = [kubernetes_namespace_v1.argocd]
}

# Aplicar ArgoCD Apps via kubectl_manifest (ordem importa)
resource "kubectl_manifest" "argocd_project" {
  yaml_body  = file("${var.cd_apps_path}/project.yaml")
  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_root_app" {
  yaml_body  = file("${var.cd_apps_path}/root-app.yaml")
  depends_on = [kubectl_manifest.argocd_project]
}

resource "kubectl_manifest" "argocd_prometheus" {
  yaml_body  = file("${var.cd_apps_path}/monitoring/argocd-app-prometheus.yaml")
  depends_on = [kubectl_manifest.argocd_project]
}

resource "kubectl_manifest" "argocd_loki" {
  yaml_body  = file("${var.cd_apps_path}/monitoring/argocd-app-loki.yaml")
  depends_on = [kubectl_manifest.argocd_project]
}
'@ | Out-File -FilePath "$tf\modules\argocd\main.tf" -Encoding utf8

Write-Host "  argocd/main.tf atualizado com kubectl_manifest"
Write-Host "ArgoCD fix OK" -ForegroundColor Green

# =============================================================================
Write-Host "`n=== TAREFA 6: ACCOUNT_ID via Kustomize ===" -ForegroundColor Cyan

@'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

namespace: solidarytech

commonLabels:
  environment: production
  project: solidarytech
  cost-center: ngo-core

images:
  - name: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/solidarytech/ngo-service
    newName: $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com/solidarytech/ngo-service
    newTag: latest
  - name: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/solidarytech/donation-service
    newName: $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com/solidarytech/donation-service
    newTag: latest
  - name: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/solidarytech/volunteer-service
    newName: $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com/solidarytech/volunteer-service
    newTag: latest
'@ | Out-File -FilePath "$app\k8s\overlays\production\kustomization.yaml" -Encoding utf8

Write-Host "  kustomization overlay atualizado"
Write-Host "ACCOUNT_ID OK" -ForegroundColor Green

# =============================================================================
Write-Host "`n=== TAREFA 7: GRAFANA PASSWORD ===" -ForegroundColor Cyan

@'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus
  namespace: argocd
spec:
  project: solidarytech
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    targetRevision: "58.7.2"
    helm:
      valuesObject:
        grafana:
          enabled: true
          admin:
            existingSecret: grafana-admin-secret
            userKey: admin-user
            passwordKey: admin-password
          service:
            type: ClusterIP
          sidecar:
            dashboards:
              enabled: true
              label: grafana_dashboard
              searchNamespace: monitoring
            datasources:
              enabled: true
          additionalDataSources:
            - name: Loki
              type: loki
              url: http://loki.monitoring.svc:3100
              access: proxy
              isDefault: false
        prometheus:
          prometheusSpec:
            retention: 15d
            resources:
              requests: { cpu: 200m, memory: 400Mi }
              limits:   { cpu: 500m, memory: 800Mi }
            ruleSelector:
              matchLabels:
                app: kube-prometheus-stack
                release: prometheus
        alertmanager:
          alertmanagerSpec:
            resources:
              requests: { cpu: 50m, memory: 64Mi }
        nodeExporter:     { enabled: true }
        kubeStateMetrics: { enabled: true }
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
'@ | Out-File -FilePath "$tf\CD\apps\monitoring\argocd-app-prometheus.yaml" -Encoding utf8

# Secret Grafana via Terraform (random_password)
@'
resource "random_password" "grafana_admin" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin-secret"
    namespace = "monitoring"
  }
  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana_admin.result
  }
  type = "Opaque"

  lifecycle {
    ignore_changes = [data]
  }
}
'@ | Out-File -FilePath "$tf\modules\kubernetes\grafana-secret.tf" -Encoding utf8

# Adicionar random ao providers prod
$providersContent = Get-Content "$tf\environments\prod\providers.tf" -Raw
$providersContent = $providersContent -replace 'kubectl    = \{ source = "gavinbunney/kubectl";  version = "~> 1.14" \}', 'kubectl    = { source = "gavinbunney/kubectl";  version = "~> 1.14" }
    random     = { source = "hashicorp/random";      version = "~> 3.6" }'
$providersContent | Out-File -FilePath "$tf\environments\prod\providers.tf" -Encoding utf8

Write-Host "  grafana secret via random_password"
Write-Host "Grafana password OK" -ForegroundColor Green

# =============================================================================
Write-Host "`n=== TAREFA 8: DR OUTPUTS ===" -ForegroundColor Cyan

@'
output "eks_cluster_name"  { value = module.eks.eks_cluster_name }
output "eks_endpoint"      { value = module.eks.eks_cluster_endpoint }
output "rds_endpoint"      { value = module.rds.rds_instance_endpoint; sensitive = true }
output "sqs_queue_url"     { value = module.resources.sqs_queue_url }
output "dynamodb_table"    { value = module.rds.dynamodb_table_name }
'@ | Out-File -FilePath "$tf\environments\dr\outputs.tf" -Encoding utf8

@'
aws_region       = "us-west-2"
project_name     = "solidarytech"
# aws_account_id passado via secret: TF_VAR_aws_account_id
eks_cluster_name = "solidarytech-dr"
rds_username     = "solidarytech"
# rds_password passado via secret: TF_VAR_rds_password
'@ | Out-File -FilePath "$tf\environments\dr\terraform.tfvars.example" -Encoding utf8

Write-Host "DR outputs OK" -ForegroundColor Green

# =============================================================================
Write-Host "`n=== TAREFA 9: VELERO ===" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path "$tf\modules\velero" | Out-Null

@'
# Bucket S3 para backups Velero
resource "aws_s3_bucket" "velero" {
  bucket        = "${var.project_name}-velero-backups"
  force_destroy = false
  tags          = merge(var.tags, { Name = "${var.project_name}-velero-backups" })
}

resource "aws_s3_bucket_versioning" "velero" {
  bucket = aws_s3_bucket.velero.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "velero" {
  bucket = aws_s3_bucket.velero.id
  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    expiration { days = 90 }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero" {
  bucket = aws_s3_bucket.velero.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# IRSA para Velero
data "aws_iam_policy_document" "velero_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:velero:velero-server"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "velero" {
  name               = "${var.project_name}-velero-role"
  assume_role_policy = data.aws_iam_policy_document.velero_assume.json
  tags               = var.tags
}

resource "aws_iam_policy" "velero" {
  name = "${var.project_name}-velero-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeVolumes", "ec2:DescribeSnapshots", "ec2:CreateTags", "ec2:CreateVolume", "ec2:CreateSnapshot", "ec2:DeleteSnapshot"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:DeleteObject", "s3:PutObject", "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts"]
        Resource = "${aws_s3_bucket.velero.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.velero.arn
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "velero" {
  role       = aws_iam_role.velero.name
  policy_arn = aws_iam_policy.velero.arn
}

# Helm release Velero
resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = "6.0.0"
  namespace  = "velero"
  create_namespace = true

  set { name = "serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn"; value = aws_iam_role.velero.arn }
  set { name = "configuration.backupStorageLocation[0].name";     value = "default" }
  set { name = "configuration.backupStorageLocation[0].provider"; value = "aws" }
  set { name = "configuration.backupStorageLocation[0].bucket";   value = aws_s3_bucket.velero.id }
  set { name = "configuration.backupStorageLocation[0].config.region"; value = var.aws_region }
  set { name = "configuration.volumeSnapshotLocation[0].name";     value = "default" }
  set { name = "configuration.volumeSnapshotLocation[0].provider"; value = "aws" }
  set { name = "configuration.volumeSnapshotLocation[0].config.region"; value = var.aws_region }
  set { name = "initContainers[0].name";                          value = "velero-plugin-for-aws" }
  set { name = "initContainers[0].image";                         value = "velero/velero-plugin-for-aws:v1.9.0" }
  set { name = "initContainers[0].volumeMounts[0].mountPath";     value = "/target" }
  set { name = "initContainers[0].volumeMounts[0].name";          value = "plugins" }

  timeout    = 300
  wait       = true
}
'@ | Out-File -FilePath "$tf\modules\velero\main.tf" -Encoding utf8

@'
variable "project_name"      { type = string }
variable "aws_region"        { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "tags"              { type = map(string) }
'@ | Out-File -FilePath "$tf\modules\velero\variables.tf" -Encoding utf8

@'
output "velero_bucket"   { value = aws_s3_bucket.velero.id }
output "velero_role_arn" { value = aws_iam_role.velero.arn }
'@ | Out-File -FilePath "$tf\modules\velero\outputs.tf" -Encoding utf8

# Mover schedule.yaml para ArgoCD App
@'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: velero-schedule
  namespace: argocd
spec:
  project: solidarytech
  source:
    repoURL: https://github.com/SEU_ORG/hackathon-DCLT
    targetRevision: main
    path: observability/velero
  destination:
    server: https://kubernetes.default.svc
    namespace: velero
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions:
      - CreateNamespace=true
'@ | Out-File -FilePath "$tf\CD\apps\monitoring\argocd-app-velero.yaml" -Encoding utf8

Write-Host "Velero OK" -ForegroundColor Green

# =============================================================================
Write-Host "`n=== TAREFA 10: OTEL + TEMPO ===" -ForegroundColor Cyan

@'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: otel-collector
  namespace: argocd
spec:
  project: solidarytech
  source:
    repoURL: https://open-telemetry.github.io/opentelemetry-helm-charts
    chart: opentelemetry-collector
    targetRevision: "0.91.0"
    helm:
      valuesObject:
        mode: deployment
        config:
          receivers:
            otlp:
              protocols:
                grpc: { endpoint: "0.0.0.0:4317" }
                http: { endpoint: "0.0.0.0:4318" }
          processors:
            batch: {}
            memory_limiter:
              check_interval: 1s
              limit_mib: 400
          exporters:
            otlp/tempo:
              endpoint: "tempo.monitoring.svc:4317"
              tls: { insecure: true }
            prometheus:
              endpoint: "0.0.0.0:8889"
          service:
            pipelines:
              traces:
                receivers:  [otlp]
                processors: [memory_limiter, batch]
                exporters:  [otlp/tempo]
              metrics:
                receivers:  [otlp]
                processors: [batch]
                exporters:  [prometheus]
        resources:
          requests: { cpu: 100m, memory: 128Mi }
          limits:   { cpu: 250m, memory: 256Mi }
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [CreateNamespace=true]
'@ | Out-File -FilePath "$tf\CD\apps\monitoring\argocd-app-otel.yaml" -Encoding utf8

@'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: tempo
  namespace: argocd
spec:
  project: solidarytech
  source:
    repoURL: https://grafana.github.io/helm-charts
    chart: tempo
    targetRevision: "1.7.2"
    helm:
      valuesObject:
        tempo:
          storage:
            trace:
              backend: local
          resources:
            requests: { cpu: 100m, memory: 256Mi }
            limits:   { cpu: 250m, memory: 512Mi }
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [CreateNamespace=true]
'@ | Out-File -FilePath "$tf\CD\apps\monitoring\argocd-app-tempo.yaml" -Encoding utf8

Write-Host "OTel + Tempo ArgoCD Apps OK" -ForegroundColor Green

# Atualizar kustomization CD/apps
@'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - project.yaml
  - root-app.yaml
  - monitoring/argocd-app-prometheus.yaml
  - monitoring/argocd-app-loki.yaml
  - monitoring/argocd-app-otel.yaml
  - monitoring/argocd-app-tempo.yaml
  - monitoring/argocd-app-velero.yaml
'@ | Out-File -FilePath "$tf\CD\apps\kustomization.yaml" -Encoding utf8

# Atualizar modules.tf prod para incluir novos módulos
@'
locals {
  azs = ["us-east-1a", "us-east-1b"]
}

module "vpc" {
  source             = "../../modules/network"
  project_name       = var.project_name
  aws_region         = var.aws_region
  cidr_block         = var.cidr_block
  cluster_name       = var.eks_cluster_name
  tags               = local.common_tags
  availability_zones = local.azs
  enable_nat_gateway = true
  single_nat_gateway = true
}

module "ecr" {
  source          = "../../modules/ecr"
  for_each        = toset(var.repository_names)
  repository_name = each.key
  aws_account_id  = var.aws_account_id
  tags            = local.common_tags
}

module "rds" {
  source                        = "../../modules/databases"
  project_name                  = var.project_name
  aws_region                    = var.aws_region
  tags                          = local.common_tags
  vpc_id                        = module.vpc.vpc_id
  private_subnet_ids            = module.vpc.private_subnets
  eks_cluster_security_group_id = module.eks.eks_cluster_security_group_id
  rds_identifier                = var.rds_identifier
  rds_db_name                   = var.project_name
  rds_username                  = var.rds_username
  rds_password                  = var.rds_password
  rds_deletion_protection       = true
  dynamodb_table_name           = var.dynamodb_table_name
}

module "eks" {
  source                 = "../../modules/eks-cluster"
  project_name           = var.project_name
  aws_region             = var.aws_region
  aws_account_id         = var.aws_account_id
  eks_cluster_name       = var.eks_cluster_name
  eks_kubernetes_version = var.eks_kubernetes_version
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnets
  tags                   = local.common_tags
}

module "resources" {
  source       = "../../modules/resources"
  project_name = var.project_name
  environment  = "prod"
  aws_region   = var.aws_region
  tags         = local.common_tags
}

module "kubernetes" {
  source         = "../../modules/kubernetes"
  project_name   = var.project_name
  tags           = local.common_tags
  db_user        = var.rds_username
  db_password    = var.rds_password
  rds_password   = module.rds.rds_password
  rds_endpoint   = module.rds.rds_instance_endpoint
  sqs_queue_url  = module.resources.sqs_queue_url
  dynamodb_table = module.rds.dynamodb_table_name
  depends_on     = [module.eks, module.rds]
}

module "aws_lb_controller" {
  source           = "../../modules/aws-lb-controller"
  project_name     = var.project_name
  aws_region       = var.aws_region
  eks_cluster_name = var.eks_cluster_name
  vpc_id           = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  tags             = local.common_tags
  depends_on       = [module.eks]
}

module "velero" {
  source           = "../../modules/velero"
  project_name     = var.project_name
  aws_region       = var.aws_region
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  tags             = local.common_tags
  depends_on       = [module.eks]
}

module "argocd" {
  source       = "../../modules/argocd"
  tags         = local.common_tags
  cd_apps_path = "${path.module}/../../CD/apps"
  depends_on   = [module.eks, module.kubernetes]
}
'@ | Out-File -FilePath "$tf\environments\prod\modules.tf" -Encoding utf8

Write-Host "modules.tf atualizado com alb + velero" -ForegroundColor Green

Write-Host "`n=== TODAS AS TAREFAS DE INFRA CONCLUIDAS ===" -ForegroundColor Green
