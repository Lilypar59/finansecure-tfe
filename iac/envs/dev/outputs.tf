# ALB Endpoint (output para acceder a la aplicación)
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = module.alb.alb_arn
}

# VPC Outputs
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

# ASG Outputs
output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.ec2_asg.asg_name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = module.ec2_asg.asg_arn
}

# SSM Parameters
output "docker_compose_parameter" {
  description = "SSM Parameter name for docker-compose"
  value       = module.ssm.docker_compose_parameter_name
}

output "kms_key_id" {
  description = "KMS Key ID for SSM encryption"
  value       = module.ssm.kms_key_id
}

# EC2 Info
output "launch_template_id" {
  description = "Launch Template ID"
  value       = module.ec2_asg.launch_template_id
}

# Access URL (para dev)
output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "healthcheck_url" {
  description = "Health check endpoint"
  value       = "http://${module.alb.alb_dns_name}/health"
}
