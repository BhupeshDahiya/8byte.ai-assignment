# SSM for EC2
# IAM role assumed by EC2
resource "aws_iam_role" "ssm_ecr_perms" {
  name = "ec2-ssm-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ecr_policy" {
  name = "ecr-policy"
  role = aws_iam_role.ssm_ecr_perms.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.db_credentials.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm_ecr_perms.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ssm_ecr_perms.name
}

data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amzn-linux-2023-ami.id
  instance_type          = "t3.small"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name
  user_data              = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y docker

                systemctl start docker
                systemctl enable docker

                usermod -aG docker ec2-user
                mkdir -p /opt/alloy

                cat > /opt/alloy/config.alloy <<'ALLOY'
                logging {
                  level  = "info"
                  format = "logfmt"
                }

                discovery.docker "containers" {
                  host = "unix:///var/run/docker.sock"
                }

                loki.write "default" {
                  endpoint {
                    url = "http://10.0.2.10:3100/loki/api/v1/push"
                  }
                }

                loki.source.docker "containers" {
                  host    = "unix:///var/run/docker.sock"
                  targets = discovery.docker.containers.targets

                  labels = {
                    host = "app-ec2",
                    env  = "staging",
                  }

                  forward_to = [loki.write.default.receiver]
                }

                loki.source.journal "system" {
                  max_age = "24h"

                  labels = {
                    host = "app-ec2",
                    env  = "staging",
                    type = "system",
                  }

                  forward_to = [loki.write.default.receiver]
                }
                ALLOY

                docker pull grafana/alloy:v1.19.0

                docker rm -f alloy 2>/dev/null || true

                docker run -d \
                  --name alloy \
                  --restart unless-stopped \
                  -v /opt/alloy/config.alloy:/etc/alloy/config.alloy:ro \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  -v /run/log/journal:/run/log/journal:ro \
                  -v /var/log/journal:/var/log/journal:ro \
                  -v /etc/machine-id:/etc/machine-id:ro \
                  grafana/alloy:v1.19.0 \
                  run \
                  --storage.path=/var/lib/alloy/data \
                  --disable-reporting \
                  /etc/alloy/config.alloy
              EOF

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}