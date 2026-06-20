variable "project_name"           { type = string }
variable "aws_region"             { type = string }
variable "cidr_block"             { type = string }
variable "cluster_name"           { type = string }
variable "tags"                   { type = map(string) }
variable "availability_zones"     { type = list(string) }
variable "enable_nat_gateway"     { type = bool; default = true }
variable "single_nat_gateway"     { type = bool; default = true }
variable "one_nat_gateway_per_az" { type = bool; default = false }
variable "enable_dns_hostnames"   { type = bool; default = true }
variable "enable_dns_support"     { type = bool; default = true }
variable "enable_flow_log"        { type = bool; default = false }
variable "assign_ipv6_address"    { type = bool; default = false }
variable "enable_ipv6"            { type = bool; default = false }
