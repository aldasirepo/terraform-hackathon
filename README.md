# Terraform - SolidaryTech Hackathon FIAP

## Estrutura

```
terraform-hackathon/
├── modules/
│   ├── vpc/        # VPC, subnets, NAT Gateway
│   ├── eks/        # Cluster EKS + Node Group
│   ├── rds/        # PostgreSQL (ngo-service + donation-service)
│   ├── dynamodb/   # Tabela volunteers (volunteer-service)
│   ├── sqs/        # Fila de eventos de doações + DLQ
│   └── ecr/        # Repositórios de imagens Docker
├── envs/
│   ├── production/ # us-east-1 (ambiente principal)
│   └── dr/         # us-west-2 (Warm Standby - DR)
```

## Uso

### Production
```bash
cd envs/production
terraform init
terraform plan
terraform apply
```

### DR (Warm Standby - 1 comando)
```bash
cd envs/dr
terraform init
terraform plan
terraform apply
```

## Tags FinOps obrigatórias (aplicadas via default_tags)

| Tag         | Valor          |
|-------------|----------------|
| Project     | SolidaryTech   |
| Environment | Production / DR|
| CostCenter  | NGO-Core       |
| ManagedBy   | Terraform      |
| Team        | DevOps         |

## Pré-requisitos

- AWS CLI configurado
- Bucket S3 `solidarytech-tfstate` criado (para backend remoto)
- Terraform >= 1.7
