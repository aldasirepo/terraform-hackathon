output "eks_cluster_name" {
  value = module.eks.eks_cluster_name
}
output "eks_endpoint" {
  value     = module.eks.eks_cluster_endpoint
  sensitive = true
}
output "rds_endpoint" {
  value     = module.rds.rds_instance_endpoint
  sensitive = true
}
output "sqs_queue_url" {
  value = module.resources.sqs_queue_url
}
output "dynamodb_table" {
  value = module.rds.dynamodb_table_name
}
