variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_name" {
  type    = string
  default = "solidarytech"
}
variable "aws_account_id" {
  type = string
}
variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}
variable "eks_cluster_name" {
  type    = string
  default = "solidarytech-prod"
}
variable "eks_kubernetes_version" {
  type    = string
  default = "1.29"
}
variable "repository_names" {
  type    = list(string)
  default = ["solidarytech/ngo-service", "solidarytech/donation-service", "solidarytech/volunteer-service"]
}
variable "rds_identifier" {
  type    = string
  default = "solidarytech-prod"
}
variable "rds_username" {
  type    = string
  default = "solidarytech"
}
variable "rds_password" {
  type      = string
  sensitive = true
}
variable "dynamodb_table_name" {
  type    = string
  default = "solidarytech-volunteers-prod"
}
