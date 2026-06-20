variable "aws_region" {
  type    = string
  default = "us-west-2"
}
variable "project_name" {
  type    = string
  default = "solidarytech"
}
variable "aws_account_id" {
  type = string
}
variable "eks_cluster_name" {
  type    = string
  default = "solidarytech-dr"
}
variable "rds_username" {
  type    = string
  default = "solidarytech"
}
variable "rds_password" {
  type      = string
  sensitive = true
}
