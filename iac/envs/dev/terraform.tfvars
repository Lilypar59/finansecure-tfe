# ==================================================
# DEV ENVIRONMENT - terraform.tfvars
# ==================================================
# Este archivo contiene los valores específicos para DEV

aws_region                = "eu-west-1"
environment               = "dev"
project_name              = "finansecure"

# Networking
vpc_cidr                  = "10.0.0.0/16"
public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs      = ["10.0.10.0/24", "10.0.11.0/24"]

# EC2 Configuration
instance_type             = "t3.small"
asg_desired_capacity      = 1

# ECR Configuration
ecr_repository_name       = "finansecure"
ecr_registry_url          = "YOUR_ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com"

# Features
postgres_container_enabled = true

# Docker Compose (se cargará desde archivo)
docker_compose_content    = file("${path.module}/../../deploy/docker-compose.dev.yml")

# Secretos (cambiar en producción)
postgres_password         = "dev-changeme-12345"
jwt_secret                = "dev-jwt-secret-changeme-abc123xyz"
