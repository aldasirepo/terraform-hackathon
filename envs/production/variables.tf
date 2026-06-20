variable "aws_region" {
  description = "Região AWS principal"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente (production, staging)"
  type        = string
  default     = "production"
}
