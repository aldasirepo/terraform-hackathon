variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "project_name" {
  type = string
}

variable "aws_account_id" {
  type      = string
  sensitive = true
}

variable "eks_cluster_name" {
  type = string
}

variable "eks_kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "rds_username" {
  type = string
}

variable "rds_password" {
  type      = string
  sensitive = true
}
