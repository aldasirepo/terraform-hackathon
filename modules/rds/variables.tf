variable "environment"        { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "eks_sg_id"          { type = string }
variable "db_password"        { 
  type      = string
  sensitive = true
  default   = "ChangeMeInProd123!"
}
variable "tags" { type = map(string) }
