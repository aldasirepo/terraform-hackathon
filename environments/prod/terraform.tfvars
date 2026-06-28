aws_region   = "us-east-1"
project_name = "solidarytech"
# aws_account_id passado via secret: TF_VAR_aws_account_id no GitHub Actions
cidr_block             = "10.0.0.0/16"
eks_cluster_name       = "solidarytech-prod"
repository_names       = ["solidarytech/ngo-service", "solidarytech/donation-service", "solidarytech/volunteer-service"]
rds_identifier         = "solidarytech-prod"
rds_username           = "solidarytech"
dynamodb_table_name    = "solidarytech-volunteers-prod"
eks_kubernetes_version = "1.32"
