# SSM Parameter Store para docker-compose
resource "aws_ssm_parameter" "docker_compose" {
  name            = "/finansecure/${var.environment}/docker-compose"
  description     = "docker-compose configuration for ${var.environment}"
  type            = "String"
  value           = var.docker_compose_content
  tier            = "Standard"
  overwrite       = true
  allowed_pattern = ".*"

  tags = {
    Name        = "${var.environment}-docker-compose"
    Environment = var.environment
  }
}

# SSM Parameter para PostgreSQL password (si se usa RDS)
resource "aws_ssm_parameter" "postgres_password" {
  count           = var.store_postgres_password ? 1 : 0
  name            = "/finansecure/${var.environment}/db/password"
  description     = "PostgreSQL password for ${var.environment}"
  type            = "SecureString"
  value           = var.postgres_password
  key_id          = var.kms_key_id
  overwrite       = true

  tags = {
    Name        = "${var.environment}-postgres-password"
    Environment = var.environment
    Sensitive   = "true"
  }
}

# SSM Parameter para JWT secret
resource "aws_ssm_parameter" "jwt_secret" {
  count           = var.store_jwt_secret ? 1 : 0
  name            = "/finansecure/${var.environment}/jwt/secret"
  description     = "JWT secret key for ${var.environment}"
  type            = "SecureString"
  value           = var.jwt_secret
  key_id          = var.kms_key_id
  overwrite       = true

  tags = {
    Name        = "${var.environment}-jwt-secret"
    Environment = var.environment
    Sensitive   = "true"
  }
}

# SSM Parameter para Database Connection String
resource "aws_ssm_parameter" "db_connection" {
  count           = var.store_db_connection ? 1 : 0
  name            = "/finansecure/${var.environment}/db/connection"
  description     = "Database connection string for ${var.environment}"
  type            = "SecureString"
  value           = var.db_connection_string
  key_id          = var.kms_key_id
  overwrite       = true

  tags = {
    Name        = "${var.environment}-db-connection"
    Environment = var.environment
    Sensitive   = "true"
  }
}

# SSM Parameter para API Key (si es necesario)
resource "aws_ssm_parameter" "api_key" {
  count           = var.store_api_key ? 1 : 0
  name            = "/finansecure/${var.environment}/api/key"
  description     = "API key for ${var.environment}"
  type            = "SecureString"
  value           = var.api_key
  key_id          = var.kms_key_id
  overwrite       = true

  tags = {
    Name        = "${var.environment}-api-key"
    Environment = var.environment
    Sensitive   = "true"
  }
}

# SSM Parameter para CORS configuration
resource "aws_ssm_parameter" "cors_origins" {
  count           = var.store_cors_origins ? 1 : 0
  name            = "/finansecure/${var.environment}/cors/origins"
  description     = "CORS allowed origins for ${var.environment}"
  type            = "String"
  value           = var.cors_origins
  overwrite       = true

  tags = {
    Name        = "${var.environment}-cors-origins"
    Environment = var.environment
  }
}

# SSM Parameter para Email configuration
resource "aws_ssm_parameter" "email_config" {
  count           = var.store_email_config ? 1 : 0
  name            = "/finansecure/${var.environment}/email/config"
  description     = "Email configuration for ${var.environment}"
  type            = "String"
  value           = var.email_config
  overwrite       = true

  tags = {
    Name        = "${var.environment}-email-config"
    Environment = var.environment
  }
}

# KMS Key para encriptar parámetros sensibles
resource "aws_kms_key" "ssm_key" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "KMS key for SSM Parameter Store encryption - ${var.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.environment}-ssm-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "ssm_key" {
  count         = var.create_kms_key ? 1 : 0
  name          = "alias/${var.environment}-finansecure-ssm"
  target_key_id = aws_kms_key.ssm_key[0].key_id
}
