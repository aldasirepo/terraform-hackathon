variable "project_name" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "tags" {
  type = map(string)
}
variable "vpc_id" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "eks_cluster_security_group_id" {
  type = string
}
variable "rds_identifier" {
  type = string
}
variable "rds_engine" {
  type    = string
  default = "postgres"
}
variable "rds_engine_version" {
  type    = string
  default = "15.4"
}
variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "rds_allocated_storage" {
  type    = number
  default = 20
}
variable "rds_db_name" {
  type = string
}
variable "rds_username" {
  type = string
}
variable "rds_password" {
  type      = string
  sensitive = true
}
variable "rds_port" {
  type    = number
  default = 5432
}
variable "rds_backup_window" {
  type    = string
  default = "03:00-04:00"
}
variable "rds_maintenance_window" {
  type    = string
  default = "Mon:04:00-Mon:05:00"
}
variable "rds_deletion_protection" {
  type    = bool
  default = true
}
variable "rds_iam_database_authentication_enabled" {
  type    = bool
  default = false
}
variable "rds_create_db_subnet_group" {
  type    = bool
  default = true
}
variable "rds_monitoring_interval" {
  type    = number
  default = 60
}
variable "rds_monitoring_role_name" {
  type    = string
  default = "rds-monitoring-role"
}
variable "rds_create_monitoring_role" {
  type    = bool
  default = true
}
variable "rds_family" {
  type    = string
  default = "postgres15"
}
variable "rds_major_engine_version" {
  type    = string
  default = "15"
}
variable "rds_parameters" {
  type    = list(map(string))
  default = []
}
variable "rds_options" {
  type    = list(map(string))
  default = []
}
variable "dynamodb_table_name" {
  type = string
}
