resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "SG do RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS cluster SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }

  ingress {
    description = "PostgreSQL from VPC CIDR (EKS nodes)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-rds-sg"
  })
}

resource "aws_db_subnet_group" "main" {
  name = "${
    var.project_name
  }-rds-subnet"
  subnet_ids = var.private_subnet_ids
  tags = merge(var.tags, {
    Name = "${
      var.project_name
    }-rds-subnet"
  })
}

resource "aws_db_instance" "main" {
  identifier              = var.rds_identifier
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  storage_type            = "gp3"
  storage_encrypted       = true
  db_name                 = var.rds_db_name
  username                = var.rds_username
  password                = var.rds_password
  port                    = var.rds_port
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = false
  publicly_accessible     = false
  backup_retention_period = 0
  backup_window           = var.rds_backup_window
  maintenance_window      = var.rds_maintenance_window
  skip_final_snapshot     = false
  final_snapshot_identifier = "${
    var.rds_identifier
  }-final"
  deletion_protection = var.rds_deletion_protection
  tags                = var.tags
}
