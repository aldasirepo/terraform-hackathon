# Terraform - SolidaryTech Hackathon FIAP Fase 5

## Estrutura

```
terraform-hackathon/
├── bootstrap/          # Cria bucket S3 + DynamoDB para state remoto (executar 1x)
├── modules/
│   ├── network/        # VPC, subnets, NAT Gateway
│   ├── eks-cluster/    # Cluster EKS + Node Group + IAM
│   ├── databases/      # RDS PostgreSQL + DynamoDB
│   ├── ecr/            # Repositórios de imagens Docker
│   ├── resources/      # SQS (fila de doações + DLQ)
│   ├── argocd/         # ArgoCD instalado via Helm
│   └── kubernetes/     # Namespace + Secrets no K8s
├── environments/
│   ├── prod/           # us-east-1 (ambiente principal)
│   └── dr/             # us-west-2 (Warm Standby - 1 comando)
└── CD/
    └── apps/
        ├── root-app.yaml           # ArgoCD App principal (solidarytech)
        ├── project.yaml            # ArgoCD Project
        ├── kustomization.yaml      # App of Apps
        └── monitoring/
            ├── argocd-app-prometheus.yaml  # kube-prometheus-stack + Grafana
            └── argocd-app-loki.yaml        # Loki + Promtail
```

## Como usar

### 1. Bootstrap (uma vez)
```bash
cd bootstrap
terraform init && terraform apply
```

### 2. Production (us-east-1)
```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars  # edite com seus valores
terraform init
terraform plan
terraform apply
```

### 3. DR - Warm Standby (us-west-2)
```bash
cd environments/dr
terraform init
terraform apply -var="rds_password=SENHA" -var="aws_account_id=ACCOUNT_ID"
```

## Tags FinOps (aplicadas via default_tags)

| Tag         | Valor            |
|-------------|------------------|
| Project     | SolidaryTech     |
| Environment | Production / DR  |
| CostCenter  | NGO-Core         |
| ManagedBy   | Terraform        |
| Team        | DevOps           |

## O que é provisionado

- **VPC** — 2 AZs, subnets públicas/privadas, NAT Gateway
- **EKS** — cluster 1.29, node group t3.medium (2-4 nodes)
- **RDS** — PostgreSQL 15 Multi-AZ (ngo-service + donation-service)
- **DynamoDB** — tabela volunteers com GSI (volunteer-service)
- **SQS** — fila de eventos de doações + DLQ
- **ECR** — 3 repositórios com scan on push
- **ArgoCD** — instalado via Helm, gerencia todos os apps
- **Prometheus + Grafana + Loki** — via ArgoCD App of Apps
