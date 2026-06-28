variable "project_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "rds_username" {
  type = string
}

variable "rds_password" {
  type      = string
  sensitive = true
}

variable "rds_endpoint" {
  type = string
}

variable "sqs_queue_url" {
  type = string
}

variable "dynamodb_table" {
  type = string
}
