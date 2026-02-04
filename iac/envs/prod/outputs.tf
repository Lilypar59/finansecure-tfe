# ==================================================
# ALB & Access
# ==================================================
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = module.alb.alb_arn
}

output "application_url" {
  description = "URL to access the application"
  value       = "https://${var.domain_name}"
}

# ==================================================
# VPC
# ==================================================
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT Gateway IPs"
  value       = module.vpc.nat_gateway_ips
}

# ==================================================
# RDS
# ==================================================
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.rds_endpoint
}

output "rds_address" {
  description = "RDS database address"
  value       = module.rds.rds_address
}

output "rds_port" {
  description = "RDS database port"
  value       = module.rds.rds_port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.rds_database_name
}

# ==================================================
# ASG
# ==================================================
output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.ec2_asg.asg_name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = module.ec2_asg.asg_arn
}

# ==================================================
# Security
# ==================================================
output "kms_key_id" {
  description = "KMS Key ID for SSM encryption"
  value       = module.ssm.kms_key_id
}

output "docker_compose_parameter" {
  description = "SSM Parameter name for docker-compose"
  value       = module.ssm.docker_compose_parameter_name
}

# ==================================================
# Monitoring
# ==================================================
output "cloudwatch_log_group" {
  description = "CloudWatch log group for user-data"
  value       = "/finansecure/${var.environment}/user-data"
}
