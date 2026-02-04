variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_rds" {
  description = "Crear RDS (solo prod)"
  type        = bool
  default     = false
}

variable "create_postgres_container" {
  description = "Crear SG para PostgreSQL en contenedor (solo dev)"
  type        = bool
  default     = false
}
