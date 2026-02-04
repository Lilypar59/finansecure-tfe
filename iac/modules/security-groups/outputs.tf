output "alb_security_group_id" {
  description = "ID del SG del ALB"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "ID del SG de EC2"
  value       = aws_security_group.ec2.id
}

output "rds_security_group_id" {
  description = "ID del SG de RDS"
  value       = try(aws_security_group.rds[0].id, null)
}

output "postgres_container_security_group_id" {
  description = "ID del SG de PostgreSQL contenedor"
  value       = try(aws_security_group.postgres_container[0].id, null)
}
