variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN del repositorio ECR"
  type        = string
}

variable "create_rds" {
  description = "Crear políticas para RDS"
  type        = bool
  default     = false
}

variable "use_secrets_manager" {
  description = "Usar AWS Secrets Manager"
  type        = bool
  default     = false
}
