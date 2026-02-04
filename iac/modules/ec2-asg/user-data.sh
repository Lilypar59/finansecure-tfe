#!/bin/bash
set -e

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/user-data.log
}

# Error handler
error_exit() {
    log "ERROR: $1"
    exit 1
}

log "========== User-Data Script Started =========="
log "Environment: ${environment}"
log "AWS Region: ${aws_region}"

# ==================================================
# 1. SYSTEM UPDATES
# ==================================================
log "Updating system packages..."
yum update -y 2>&1 | tail -5 || error_exit "Failed to update packages"

# ==================================================
# 2. INSTALL DOCKER
# ==================================================
log "Installing Docker..."
yum install -y docker 2>&1 | tail -5 || error_exit "Failed to install Docker"
systemctl start docker || error_exit "Failed to start Docker"
systemctl enable docker || error_exit "Failed to enable Docker"
log "Docker installed successfully"

# ==================================================
# 3. INSTALL DOCKER-COMPOSE
# ==================================================
log "Installing docker-compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>&1 || error_exit "Failed to download docker-compose"
chmod +x /usr/local/bin/docker-compose || error_exit "Failed to set docker-compose permissions"
log "docker-compose installed: $(docker-compose --version)"

# ==================================================
# 4. INSTALL AWS CLI & SESSION MANAGER
# ==================================================
log "Installing AWS CLI and Session Manager agent..."
yum install -y amazon-ssm-agent amazon-cloudwatch-agent 2>&1 | tail -5 || error_exit "Failed to install AWS agents"
systemctl start amazon-ssm-agent || error_exit "Failed to start SSM agent"
systemctl enable amazon-ssm-agent || error_exit "Failed to enable SSM agent"
log "AWS agents installed successfully"

# ==================================================
# 5. LOGIN TO ECR
# ==================================================
log "Authenticating with ECR..."
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_registry} 2>&1 || error_exit "Failed to login to ECR"
log "ECR authentication successful"

# ==================================================
# 6. RETRIEVE DOCKER-COMPOSE FROM SSM
# ==================================================
log "Retrieving docker-compose from SSM Parameter Store..."
mkdir -p /opt/finansecure || error_exit "Failed to create application directory"
cd /opt/finansecure || error_exit "Failed to change directory"

# Obtener el archivo docker-compose desde SSM
aws ssm get-parameter \
    --name "${docker_compose_ssm_path}" \
    --query 'Parameter.Value' \
    --output text \
    --region ${aws_region} > docker-compose.yml 2>&1 || error_exit "Failed to retrieve docker-compose from SSM"

log "docker-compose.yml retrieved successfully"
log "Content preview:"
head -20 docker-compose.yml | sed 's/^/  /'

# ==================================================
# 7. RETRIEVE ENVIRONMENT VARIABLES FROM SSM
# ==================================================
log "Creating environment file from SSM parameters..."
cat > .env << 'ENVFILE'
ENVIRONMENT=${environment}
AWS_REGION=${aws_region}
ECR_REGISTRY=${ecr_registry}
ENVFILE

# Obtener secretos individuales si existen
if [ -n "${postgres_password_ssm_path}" ]; then
    log "Retrieving PostgreSQL password from SSM..."
    POSTGRES_PASSWORD=$(aws ssm get-parameter \
        --name "${postgres_password_ssm_path}" \
        --with-decryption \
        --query 'Parameter.Value' \
        --output text \
        --region ${aws_region} 2>&1) || log "Warning: Could not retrieve PostgreSQL password"
    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> .env
fi

if [ -n "${jwt_secret_ssm_path}" ]; then
    log "Retrieving JWT secret from SSM..."
    JWT_SECRET=$(aws ssm get-parameter \
        --name "${jwt_secret_ssm_path}" \
        --with-decryption \
        --query 'Parameter.Value' \
        --output text \
        --region ${aws_region} 2>&1) || log "Warning: Could not retrieve JWT secret"
    echo "JWT_SECRET=$JWT_SECRET" >> .env
fi

if [ -n "${db_connection_ssm_path}" ]; then
    log "Retrieving database connection string from SSM..."
    DB_CONNECTION=$(aws ssm get-parameter \
        --name "${db_connection_ssm_path}" \
        --with-decryption \
        --query 'Parameter.Value' \
        --output text \
        --region ${aws_region} 2>&1) || log "Warning: Could not retrieve DB connection"
    echo "DB_CONNECTION=$DB_CONNECTION" >> .env
fi

log ".env file created"

# ==================================================
# 8. PULL DOCKER IMAGES
# ==================================================
log "Pulling Docker images from ECR..."
docker-compose pull 2>&1 | tail -10 || error_exit "Failed to pull Docker images"
log "Docker images pulled successfully"

# ==================================================
# 9. START SERVICES
# ==================================================
log "Starting docker-compose services..."
docker-compose up -d 2>&1 || error_exit "Failed to start docker-compose"

log "Waiting for services to be healthy..."
sleep 10

# ==================================================
# 10. VERIFY SERVICES
# ==================================================
log "Verifying service status..."
docker-compose ps

log "Checking container logs..."
docker-compose logs --tail=20 | head -50

# ==================================================
# 11. SETUP CLOUDWATCH LOGS
# ==================================================
if [ -n "${cloudwatch_log_group}" ]; then
    log "Setting up CloudWatch Logs agent..."
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/user-data.log"
          },
          {
            "file_path": "/var/log/docker.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/docker.log"
          }
        ]
      }
    }
  }
}
CWCONFIG

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -s \
        -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json 2>&1 || log "Warning: CloudWatch agent setup had issues"
fi

# ==================================================
# 12. CREATE HEALTH CHECK ENDPOINT
# ==================================================
log "Creating health check endpoint..."
mkdir -p /var/www/html
cat > /var/www/html/health << 'HEALTH'
{
  "status": "healthy",
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "environment": "${environment}",
  "version": "1.0"
}
HEALTH

# Iniciar simple HTTP server en puerto 5000 para health checks (alternativa)
# docker run -d --name health-check \
#     --restart unless-stopped \
#     -p 5000:80 \
#     -v /var/www/html:/usr/share/nginx/html \
#     nginx:latest || log "Warning: Could not start health check container"

# ==================================================
# 13. SETUP CRON JOB PARA LOGGING
# ==================================================
log "Setting up log rotation..."
cat > /etc/logrotate.d/finansecure << 'LOGROTATE'
/var/log/user-data.log
/var/log/docker.log
{
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
LOGROTATE

log "========== User-Data Script Completed Successfully =========="
log "Services are now running. Check docker-compose ps for status."
