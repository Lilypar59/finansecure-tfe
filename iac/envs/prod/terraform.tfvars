# ==================================================
# PROD ENVIRONMENT - terraform.tfvars
# ==================================================
# NOTA: Usa terraform.tfvars.example como plantilla
# NUNCA commitear secretos en el repo

aws_region                = "eu-west-1"
environment               = "prod"
project_name              = "finansecure"

# Networking (HA con 3 AZs)
vpc_cidr                  = "10.1.0.0/16"
public_subnet_cidrs       = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs      = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]

# EC2 Configuration
instance_type             = "t3.medium"
asg_desired_capacity      = 3

# ECR Configuration
ecr_repository_name       = "finansecure"
ecr_registry_url          = "YOUR_ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com"

# Domain & SSL
domain_name               = "api.finansecure.example.com"

# Docker Compose (se cargará desde archivo)
docker_compose_content    = file("${path.module}/../../deploy/docker-compose.prod.yml")

# RDS Configuration
db_instance_class         = "db.t3.small"
allocated_storage         = 100
database_user             = "postgres"

# Secretos (USAR AWS SECRETS MANAGER EN PROD)
# Cambiar estos valores y usar encrypted terraform.tfvars o use environment variables
postgres_password         = "CHANGE_ME_USE_AWS_SECRETS_MANAGER"
jwt_secret                = "CHANGE_ME_USE_AWS_SECRETS_MANAGER"
database_password         = "CHANGE_ME_USE_AWS_SECRETS_MANAGER"
db_connection_string      = "postgresql://postgres:CHANGE_ME@your-rds-endpoint:5432/finansecure"
