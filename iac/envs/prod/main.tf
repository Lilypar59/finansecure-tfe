# Data source para obtener ID del ECR repository
data "aws_ecr_repository" "main" {
  name = var.ecr_repository_name
}

# ==================================================
# VPC Module
# ==================================================
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  environment           = var.environment
  enable_flow_logs      = true # Enabled en prod para auditoría
}

# ==================================================
# Security Groups Module
# ==================================================
module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id                        = module.vpc.vpc_id
  vpc_cidr                      = var.vpc_cidr
  environment                   = var.environment
  create_rds                    = true  # Prod usa RDS
  create_postgres_container     = false # Sin containers en prod
}

# ==================================================
# IAM Module
# ==================================================
module "iam" {
  source = "../../modules/iam"

  environment           = var.environment
  aws_region            = var.aws_region
  ecr_repository_arn    = data.aws_ecr_repository.main.arn
  create_rds            = true
  use_secrets_manager   = true
}

# ==================================================
# ALB Module
# ==================================================
module "alb" {
  source = "../../modules/alb"

  environment              = var.environment
  vpc_id                   = module.vpc.vpc_id
  alb_security_group_id    = module.security_groups.alb_security_group_id
  public_subnet_ids        = module.vpc.public_subnet_ids
  use_https                = true # Prod usa HTTPS
  domain_name              = var.domain_name
}

# ==================================================
# RDS PostgreSQL Module
# ==================================================
module "rds" {
  source = "../../modules/rds-postgres"

  create_rds                = true
  environment               = var.environment
  private_subnet_ids        = module.vpc.private_subnet_ids
  rds_security_group_id     = module.security_groups.rds_security_group_id
  postgres_version          = "15.4"
  postgres_major_version    = "15"
  db_instance_class         = var.db_instance_class
  allocated_storage         = var.allocated_storage
  database_name             = "finansecure"
  database_user             = var.database_user
  database_password         = var.database_password
}

# ==================================================
# SSM Parameter Store Module
# ==================================================
module "ssm" {
  source = "../../modules/ssm"

  environment                = var.environment
  docker_compose_content     = var.docker_compose_content
  store_postgres_password    = true
  postgres_password          = var.postgres_password
  store_jwt_secret           = true
  jwt_secret                 = var.jwt_secret
  store_db_connection        = true
  db_connection_string       = var.db_connection_string
  create_kms_key             = true
  store_email_config         = false
  store_cors_origins         = false
}

# ==================================================
# EC2 + ASG Module
# ==================================================
module "ec2_asg" {
  source = "../../modules/ec2-asg"

  environment                    = var.environment
  aws_region                     = var.aws_region
  instance_type                  = var.instance_type
  instance_profile_name          = module.iam.instance_profile_name
  ec2_security_group_id          = module.security_groups.ec2_security_group_id
  private_subnet_ids             = module.vpc.private_subnet_ids
  target_group_arn               = module.alb.target_group_arn
  asg_min_size                   = 2
  asg_max_size                   = 6
  asg_desired_capacity           = var.asg_desired_capacity
  ecr_registry                   = var.ecr_registry_url
  docker_compose_ssm_path        = module.ssm.docker_compose_parameter_name
  postgres_password_ssm_path     = module.ssm.postgres_password_parameter_name
  jwt_secret_ssm_path            = module.ssm.jwt_secret_parameter_name
  db_connection_ssm_path         = module.ssm.db_connection_parameter_name
  cloudwatch_log_group           = "/finansecure/${var.environment}/user-data"
  log_retention_days             = 30
  postgres_container_enabled     = false
}
