resource "aws_db_subnet_group" "main" {
  name       = "solidarytech-rds-subnet-${var.environment}"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "solidarytech-rds-subnet-${var.environment}" })
}

resource "aws_security_group" "rds" {
  name        = "solidarytech-rds-sg-${var.environment}"
  description = "SG do RDS SolidaryTech"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_sg_id]
  }

  tags = merge(var.tags, { Name = "solidarytech-rds-sg-${var.environment}" })
}

resource "aws_db_instance" "main" {
  identifier              = "solidarytech-${var.environment}"
  engine                  = "postgres"
  engine_version          = "15.4"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp3"
  storage_encrypted       = true

  db_name  = "solidarytech"
  username = "solidarytech"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = var.environment == "production"
  publicly_accessible    = false
  skip_final_snapshot    = false
  final_snapshot_identifier = "solidarytech-${var.environment}-final"
  backup_retention_period = 7
  deletion_protection     = var.environment == "production"

  tags = var.tags
}
