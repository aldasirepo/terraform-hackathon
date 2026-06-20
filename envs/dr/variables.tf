variable "aws_region" {
  description = "Região AWS de DR"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  type    = string
  default = "dr"
}
