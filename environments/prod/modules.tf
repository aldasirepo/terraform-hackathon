locals {
  azs = ["us-east-1a", "us-east-1b"]
}

module "vpc" {
  source = "../../modules/network"

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
  source = "../../modules/databases"

  project_name                  = var.project_name
  aws_region                    = var.aws_region
  tags                          = local.common_tags
  vpc_id                        = module.vpc.vpc_id
  private_subnet_ids            = module.vpc.private_subnets
  eks_cluster_security_group_id = module.eks.eks_cluster_security_group_id

  rds_identifier          = var.rds_identifier
  rds_db_name             = var.project_name
  rds_username            = var.rds_username
  rds_password            = var.rds_password
  rds_deletion_protection = true
  dynamodb_table_name     = var.dynamodb_table_name
}

module "eks" {
  source = "../../modules/eks-cluster"

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
  source = "../../modules/kubernetes"

  project_name   = var.project_name
  tags           = local.common_tags
  db_user        = var.rds_username
  db_password    = var.rds_password
  rds_password   = module.rds.rds_password
  rds_endpoint   = module.rds.rds_instance_endpoint
  sqs_queue_url  = module.resources.sqs_queue_url
  dynamodb_table = module.rds.dynamodb_table_name

  depends_on = [module.eks, module.rds]
}

module "argocd" {
  source = "../../modules/argocd"

  tags = local.common_tags
  cd_apps_path = "${
    path.module
  }/../../CD/apps"

  depends_on = [module.eks, module.kubernetes]
}
