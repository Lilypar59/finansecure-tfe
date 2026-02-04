# Data source para AMI de Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# User Data Script - CRITICAL
# Este script se ejecuta automáticamente en cada EC2 instancia
# Instala Docker, docker-compose y levanta los servicios
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.ec2_security_group_id]

  # EBS Configuration
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # Monitoring
  monitoring {
    enabled = true
  }

  # User Data Script
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    environment                = var.environment
    aws_region                 = var.aws_region
    ecr_registry              = var.ecr_registry
    docker_compose_ssm_path    = var.docker_compose_ssm_path
    postgres_password_ssm_path = var.postgres_password_ssm_path
    jwt_secret_ssm_path       = var.jwt_secret_ssm_path
    db_connection_ssm_path    = var.db_connection_ssm_path
    cloudwatch_log_group      = var.cloudwatch_log_group
    postgres_container_enabled = var.postgres_container_enabled
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.environment}-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${var.environment}-volume"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-asg-instance"
    propagate_launch_template = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_launch_template = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_launch_template.app]
}

# Scaling Policy - CPU based
resource "aws_autoscaling_policy" "cpu_scaling_up" {
  name                   = "${var.environment}-cpu-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "cpu_scaling_down" {
  name                   = "${var.environment}-cpu-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Trigger scale up when CPU > 70%"
  alarm_actions       = [aws_autoscaling_policy.cpu_scaling_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.environment}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "Trigger scale down when CPU < 30%"
  alarm_actions       = [aws_autoscaling_policy.cpu_scaling_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

# CloudWatch Log Group para user-data
resource "aws_cloudwatch_log_group" "user_data" {
  name              = var.cloudwatch_log_group
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.environment}-user-data-logs"
  }
}
