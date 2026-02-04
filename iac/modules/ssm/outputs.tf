output "docker_compose_parameter_name" {
  description = "SSM Parameter name para docker-compose"
  value       = aws_ssm_parameter.docker_compose.name
}

output "postgres_password_parameter_name" {
  description = "SSM Parameter name para PostgreSQL password"
  value       = try(aws_ssm_parameter.postgres_password[0].name, null)
}

output "jwt_secret_parameter_name" {
  description = "SSM Parameter name para JWT secret"
  value       = try(aws_ssm_parameter.jwt_secret[0].name, null)
}

output "db_connection_parameter_name" {
  description = "SSM Parameter name para DB connection"
  value       = try(aws_ssm_parameter.db_connection[0].name, null)
}

output "kms_key_id" {
  description = "KMS Key ID para SSM"
  value       = try(aws_kms_key.ssm_key[0].id, null)
}

output "kms_key_arn" {
  description = "KMS Key ARN para SSM"
  value       = try(aws_kms_key.ssm_key[0].arn, null)
}
