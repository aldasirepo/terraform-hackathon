output "rds_instance_endpoint" { value = aws_db_instance.main.endpoint }
output "rds_password"          { value = var.rds_password; sensitive = true }
output "dynamodb_table_name"   { value = aws_dynamodb_table.volunteers.name }
output "dynamodb_table_arn"    { value = aws_dynamodb_table.volunteers.arn }
