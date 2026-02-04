# IAM Role para EC2 instances
resource "aws_iam_role" "ec2_role" {
  name               = "${var.environment}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-ec2-role"
  }
}

# Permisos para ECR Pull (obtener imágenes)
resource "aws_iam_role_policy" "ecr_pull" {
  name   = "${var.environment}-ecr-pull-policy"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetAuthorizationToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "PullFromECR"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeImages"
        ]
        Resource = "${var.ecr_repository_arn}/*"
      }
    ]
  })
}

# Permisos para SSM Parameter Store (leer secretos)
resource "aws_iam_role_policy" "ssm_read" {
  name   = "${var.environment}-ssm-read-policy"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetSSMParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/finansecure/${var.environment}/*"
      },
      {
        Sid    = "DescribeSSMParameters"
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Permisos para CloudWatch Logs
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name   = "${var.environment}-cloudwatch-logs-policy"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PutLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/finansecure/${var.environment}/*"
      }
    ]
  })
}

# Permisos para acceder a Secrets Manager (alternativa a SSM)
resource "aws_iam_role_policy" "secrets_manager" {
  count  = var.use_secrets_manager ? 1 : 0
  name   = "${var.environment}-secrets-manager-policy"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:finansecure/${var.environment}/*"
      }
    ]
  })
}

# Instance Profile (vincula el role con EC2)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Data source para obtener account ID
data "aws_caller_identity" "current" {}

# Politica para RDS (solo prod)
resource "aws_iam_role_policy" "rds_access" {
  count  = var.create_rds ? 1 : 0
  name   = "${var.environment}-rds-access-policy"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ConnectToRDS"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
