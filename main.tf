#   This terraform file creates a Compose enabled Docker machine on EC2 Instance. 
#   Docker Machine is configured to work with AWS ECR using IAM role, and also
#   upgraded to AWS CLI Version 2 to enable ECR commands.
#   Docker Machine will run on Amazon Linux 2 EC2 Instance with
#   custom security group allowing HTTP(80) and SSH (22) connections from anywhere. 

resource "aws_security_group" "ec2_sec_gr" {
  name = var.security_group
  tags = {
    Name = var.security_group
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2ecrfullaccess" {
  name                = "ecr_ec2_permission"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = var.iam_instance_profile
  role = aws_iam_role.ec2ecrfullaccess.name
}

resource "aws_spot_instance_request" "ecr_instance" {
  spot_price             = var.spot_price
  vpc_security_group_ids = [aws_security_group.ec2_sec_gr.id]
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  # count                  = var.instance_count

  depends_on = [
    aws_iam_instance_profile.ec2_profile
  ]

  tags = {
    Name = var.ec2_name
  }

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data            = <<-EOF
          #! /bin/bash
          yum update -y
          amazon-linux-extras install docker -y
          systemctl start docker
          systemctl enable docker
          usermod -a -G docker ec2-user
          curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" \
          -o /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose
          curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
          unzip awscliv2.zip
          ./aws/install
          EOF
}
