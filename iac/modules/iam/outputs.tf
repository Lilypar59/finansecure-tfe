output "ec2_role_arn" {
  description = "ARN del IAM role para EC2"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_role_name" {
  description = "Nombre del IAM role para EC2"
  value       = aws_iam_role.ec2_role.name
}

output "instance_profile_arn" {
  description = "ARN del instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "instance_profile_name" {
  description = "Nombre del instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}
