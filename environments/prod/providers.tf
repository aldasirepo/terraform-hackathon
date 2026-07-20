terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket         = "solidarytech-tfstate-215671569122"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "solidarytech-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}

data "aws_eks_cluster" "main" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "main" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}

locals {
  eks_host  = try(data.aws_eks_cluster.main.endpoint, "")
  eks_ca    = try(base64decode(data.aws_eks_cluster.main.certificate_authority[0].data), "")
  eks_token = try(data.aws_eks_cluster_auth.main.token, "")
}

provider "kubernetes" {
  host                   = local.eks_host
  cluster_ca_certificate = local.eks_ca
  token                  = local.eks_token
}

provider "helm" {
  kubernetes {
    host                   = local.eks_host
    cluster_ca_certificate = local.eks_ca
    token                  = local.eks_token
  }
}

provider "kubectl" {
  host                   = local.eks_host
  cluster_ca_certificate = local.eks_ca
  token                  = local.eks_token
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
