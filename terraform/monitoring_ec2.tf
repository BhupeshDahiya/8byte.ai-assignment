resource "aws_instance" "monitoring_instance" {
  ami                    = data.aws_ami.amzn-linux-2023-ami.id
  instance_type          = "t3.small"
  subnet_id              = module.vpc.private_subnets[1]
  private_ip = "10.0.2.10"
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name #using the same IAM role as EC2 instance to access SSM

  user_data = templatefile("${path.module}/monitoring-user-data.sh", {
    app_private_ip = aws_instance.ec2_instance.private_ip
    secret_name    = aws_secretsmanager_secret.db_credentials.name
    aws_region     = "us-east-1"

    application_dashboard    = file("${path.module}/dashboards/Application dash-1788451500386.json")
    infrastructure_dashboard = file("${path.module}/dashboards/Infra dash-1788451529518.json")
  })

  tags = {
    Project     = var.project_name
    Environment = "monitoring"
    ManagedBy   = "Terraform"
  }
}

output "monitoring_instance_id" {
  value = aws_instance.monitoring_instance.id
}

