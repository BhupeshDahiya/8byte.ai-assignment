# ALB SG

resource "aws_security_group" "alb_sg" {
name        = "alb_sg"
description = "SG for alb"
vpc_id      = module.vpc.vpc_id

tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
}
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_http" {
security_group_id = aws_security_group.alb_sg.id
cidr_ipv4         = "0.0.0.0/0"
ip_protocol       = "tcp"
from_port         = 80
to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_https" {
security_group_id = aws_security_group.alb_sg.id
cidr_ipv4         = "0.0.0.0/0"
ip_protocol       = "tcp"
from_port         = 443
to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_traffic_to_ec2" {
security_group_id = aws_security_group.alb_sg.id
referenced_security_group_id = aws_security_group.ec2_sg.id
ip_protocol       = "tcp"
from_port         = 3000
to_port           = 3000
}

# EC2 SG

resource "aws_security_group" "ec2_sg" {
name        = "ec2_sg"
description = "SG for ec2"
vpc_id      = module.vpc.vpc_id

tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
}
}

resource "aws_vpc_security_group_ingress_rule" "ec2_allow_only_alb" {
security_group_id = aws_security_group.ec2_sg.id
referenced_security_group_id = aws_security_group.alb_sg.id
ip_protocol       = "tcp"
from_port         = 3000
to_port           = 3000
}

resource "aws_vpc_security_group_egress_rule" "allow_traffic_to_rds" {
security_group_id = aws_security_group.ec2_sg.id
cidr_ipv4         = "0.0.0.0/0"
ip_protocol       = "tcp"
from_port         = 5432
to_port           = 5432
}

# RDS SG

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Database security group"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_allow_only_ec2" {
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432 
  to_port                      = 5432
}