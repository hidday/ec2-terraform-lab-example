terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "random" {}

data "aws_caller_identity" "current" {}

module "iam_assumable_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_arns = [
    "arn:aws:iam::214514861431:root",
    "arn:aws:sso:::group/906765d90c-08ca88e5-b5c0-4510-af1a-001a974ce5e4" // Strigo SSO Engineering group
  ]

  create_role = true

  role_name         = "StrigoTestAssumableRole"
  role_requires_mfa = false

  attach_admin_policy = true

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/sso.amazonaws.com/d-906765d90c"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "sso.amazonaws.com/sso/group": "arn:aws:sso:::group/906765d90c-08ca88e5-b5c0-4510-af1a-001a974ce5e4"
          }
        }
      }
    ]
  })
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true  # Enable automatic public IP assignment
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "create_role" {
  description = "Flag to control whether the IAM role should be created"
  type        = bool
  default     = true
}

data "aws_iam_role" "existing" {
  count = var.create_role ? 0 : 1
  name  = "ec2_ssm_role"
}

resource "aws_iam_role" "main" {
  count = var.create_role ? 1 : 0

  name = "ec2_ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "main" {
  name = "ec2_ssm_profile"
  role = var.create_role ? aws_iam_role.main[0].name : data.aws_iam_role.existing[0].name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = var.create_role ? aws_iam_role.main[0].name : data.aws_iam_role.existing[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]  // Use security group ID
  key_name               = var.ec2_instance_keypair
  iam_instance_profile   = aws_iam_instance_profile.main.name

  user_data = <<-EOF
              <powershell>
              $password = "${coalesce(var.admin_password, random_password.password.result)}"
              net user Administrator $password
              </powershell>
              EOF

  # Ensure the instance gets a public IP
  associate_public_ip_address = true

  tags = {
    Name = var.instance_name
  }
}
