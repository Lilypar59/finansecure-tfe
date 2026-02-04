variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "finansecure"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks (3 AZs for HA)"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks (3 AZs for HA)"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "asg_desired_capacity" {
  description = "Desired capacity of ASG"
  type        = number
  default     = 3
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "finansecure"
}

variable "ecr_registry_url" {
  description = "ECR registry URL"
  type        = string
}

variable "domain_name" {
  description = "Production domain name"
  type        = string
}

variable "docker_compose_content" {
  description = "Content of docker-compose file"
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL password (from AWS Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret (from AWS Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 50
}

variable "database_user" {
  description = "RDS master user"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "database_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_connection_string" {
  description = "Database connection string for application"
  type        = string
  sensitive   = true
}
