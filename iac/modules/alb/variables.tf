variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group del ALB"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de subnets públicas para ALB"
  type        = list(string)
}

variable "use_https" {
  description = "Usar HTTPS (prod)"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Dominio para certificado SSL"
  type        = string
  default     = ""
}
