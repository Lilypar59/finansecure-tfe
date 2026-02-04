# RDS Subnet Group (solo prod)
resource "aws_db_subnet_group" "postgres" {
  count              = var.create_rds ? 1 : 0
  name               = "${var.environment}-postgres-subnet-group"
  subnet_ids         = var.private_subnet_ids
  skip_final_snapshot = var.environment != "prod" ? true : false

  tags = {
    Name = "${var.environment}-postgres-subnet-group"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  count              = var.create_rds ? 1 : 0
  identifier         = "${var.environment}-postgres"
  engine             = "postgres"
  engine_version     = var.postgres_version
  instance_class     = var.db_instance_class
  allocated_storage  = var.allocated_storage
  storage_type       = "gp3"
  storage_encrypted  = true

  # Database configuration
  db_name  = var.database_name
  username = var.database_user
  password = var.database_password

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.postgres[0].name
  publicly_accessible    = false
  vpc_security_group_ids = [var.rds_security_group_id]

  # Backup configuration
  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot   = true
  skip_final_snapshot     = var.environment != "prod" ? true : false
  final_snapshot_identifier = var.environment == "prod" ? "${var.environment}-postgres-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  # High Availability
  multi_az = var.environment == "prod" ? true : false

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring[0].arn

  # Performance Insights
  performance_insights_enabled    = var.environment == "prod" ? true : false
  performance_insights_retention_period = 7

  # Deletion protection
  deletion_protection = var.environment == "prod" ? true : false

  # Parameters
  parameter_group_name = aws_db_parameter_group.postgres[0].name

  tags = {
    Name = "${var.environment}-postgres"
  }

  depends_on = [aws_iam_role.rds_monitoring[0]]
}

# Parameter Group para PostgreSQL
resource "aws_db_parameter_group" "postgres" {
  count       = var.create_rds ? 1 : 0
  family      = "postgres${var.postgres_major_version}"
  name        = "${var.environment}-postgres-params"
  description = "PostgreSQL parameter group for ${var.environment}"

  # Parámetros de seguridad y performance
  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pgaudit"
  }

  tags = {
    Name = "${var.environment}-postgres-params"
  }
}

# IAM Role para RDS monitoring
resource "aws_iam_role" "rds_monitoring" {
  count              = var.create_rds ? 1 : 0
  name               = "${var.environment}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.create_rds ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Alarms para RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count               = var.create_rds ? 1 : 0
  alarm_name          = "${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when RDS CPU > 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  count               = var.create_rds ? 1 : 0
  alarm_name          = "${var.environment}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2147483648" # 2GB
  alarm_description   = "Alert when RDS free storage < 2GB"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_database_connections" {
  count               = var.create_rds ? 1 : 0
  alarm_name          = "${var.environment}-rds-db-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when database connections > 80"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres[0].id
  }
}
