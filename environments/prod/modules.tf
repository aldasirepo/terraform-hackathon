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

module "rds" {
  source                        = "../../modules/databases"
  project_name                  = var.project_name
  aws_region                    = var.aws_region
  tags                          = local.common_tags
  vpc_id                        = module.vpc.vpc_id
  private_subnet_ids            = module.vpc.private_subnets
  eks_cluster_security_group_id = module.eks.eks_cluster_security_group_id
  vpc_cidr                      = module.vpc.vpc_cidr_block
  rds_identifier                = var.rds_identifier
  rds_db_name                   = var.project_name
  rds_username                  = var.rds_username
  rds_password                  = var.rds_password
  rds_deletion_protection       = true
  dynamodb_table_name           = var.dynamodb_table_name
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
  rds_endpoint   = module.rds.rds_instance_endpoint
  rds_password   = var.rds_password
  rds_username   = var.rds_username
  sqs_queue_url  = module.resources.sqs_queue_url
  dynamodb_table = module.rds.dynamodb_table_name
  depends_on     = [module.eks, module.rds]
}

module "aws_lb_controller" {
  source            = "../../modules/aws-lb-controller"
  project_name      = var.project_name
  aws_region        = var.aws_region
  eks_cluster_name  = var.eks_cluster_name
  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  tags              = local.common_tags
  depends_on        = [module.eks]
}

module "velero" {
  source            = "../../modules/velero"
  project_name      = var.project_name
  aws_region        = var.aws_region
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  tags              = local.common_tags
  depends_on        = [module.eks]
}

module "argocd" {
  source       = "../../modules/argocd"
  tags         = local.common_tags
  cd_apps_path = "${path.module}/../../CD/apps"
  depends_on   = [module.eks, module.kubernetes]
}
