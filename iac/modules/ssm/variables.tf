variable "environment" {
  description = "Environment name"
  type        = string
}

variable "docker_compose_content" {
  description = "docker-compose file content"
  type        = string
}

variable "store_postgres_password" {
  description = "Store PostgreSQL password in SSM"
  type        = bool
  default     = true
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "store_jwt_secret" {
  description = "Store JWT secret in SSM"
  type        = bool
  default     = true
}

variable "jwt_secret" {
  description = "JWT secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "store_db_connection" {
  description = "Store database connection string"
  type        = bool
  default     = true
}

variable "db_connection_string" {
  description = "Database connection string"
  type        = string
  sensitive   = true
  default     = ""
}

variable "store_api_key" {
  description = "Store API key"
  type        = bool
  default     = false
}

variable "api_key" {
  description = "API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "store_cors_origins" {
  description = "Store CORS origins"
  type        = bool
  default     = false
}

variable "cors_origins" {
  description = "CORS allowed origins (comma-separated)"
  type        = string
  default     = ""
}

variable "store_email_config" {
  description = "Store email configuration"
  type        = bool
  default     = false
}

variable "email_config" {
  description = "Email configuration (JSON)"
  type        = string
  default     = ""
}

variable "create_kms_key" {
  description = "Create KMS key for encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (si no se crea una nueva)"
  type        = string
  default     = null
}
