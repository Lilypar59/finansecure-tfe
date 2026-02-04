output "rds_endpoint" {
  description = "RDS endpoint"
  value       = try(aws_db_instance.postgres[0].endpoint, null)
}

output "rds_address" {
  description = "RDS database address"
  value       = try(aws_db_instance.postgres[0].address, null)
}

output "rds_port" {
  description = "RDS database port"
  value       = try(aws_db_instance.postgres[0].port, null)
}

output "rds_database_name" {
  description = "RDS database name"
  value       = try(aws_db_instance.postgres[0].db_name, null)
}

output "rds_username" {
  description = "RDS master username"
  value       = try(aws_db_instance.postgres[0].username, null)
  sensitive   = true
}

output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = try(aws_db_instance.postgres[0].id, null)
}
