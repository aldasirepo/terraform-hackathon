terraform {
  required_version = ">= 1.7"
  required_providers {
    aws        = { source = "hashicorp/aws";        version = "~> 5.0" }
    helm       = { source = "hashicorp/helm";       version = "~> 2.13" }
    kubernetes = { source = "hashicorp/kubernetes"; version = "~> 2.30" }
    kubectl    = { source = "gavinbunney/kubectl";  version = "~> 1.14" }
    tls        = { source = "hashicorp/tls";        version = "~> 4.0" }
  }
  backend "s3" {
    bucket         = "solidarytech-tfstate-215671569122"
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
