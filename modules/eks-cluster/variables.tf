variable "project_name"           { type = string }
variable "aws_region"             { type = string }
variable "aws_account_id"         { type = string }
variable "eks_cluster_name"       { type = string }
variable "eks_kubernetes_version" { type = string; default = "1.29" }
variable "vpc_id"                 { type = string }
variable "private_subnet_ids"     { type = list(string) }
variable "tags"                   { type = map(string) }
