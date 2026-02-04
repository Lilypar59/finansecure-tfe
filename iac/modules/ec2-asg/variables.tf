variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "ec2_security_group_id" {
  description = "Security group ID para EC2"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs para ASG"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN del target group"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum size of ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum size of ASG"
  type        = number
  default     = 6
}

variable "asg_desired_capacity" {
  description = "Desired capacity of ASG"
  type        = number
  default     = 2
}

variable "ecr_registry" {
  description = "ECR registry URL"
  type        = string
}

variable "docker_compose_ssm_path" {
  description = "SSM Parameter Store path para docker-compose"
  type        = string
}

variable "postgres_password_ssm_path" {
  description = "SSM Parameter Store path para PostgreSQL password"
  type        = string
  default     = ""
}

variable "jwt_secret_ssm_path" {
  description = "SSM Parameter Store path para JWT secret"
  type        = string
  default     = ""
}

variable "db_connection_ssm_path" {
  description = "SSM Parameter Store path para connection string"
  type        = string
  default     = ""
}

variable "cloudwatch_log_group" {
  description = "CloudWatch log group para user-data"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch logs retention days"
  type        = number
  default     = 7
}

variable "postgres_container_enabled" {
  description = "Si PostgreSQL está en contenedor"
  type        = bool
  default     = false
}
