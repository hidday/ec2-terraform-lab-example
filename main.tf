terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.25.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }

}

provider "random" {}

provider "aws" {
  region = var.aws_location

  default_tags {
    tags = {
      "creator" = var.creator_tag
    }
  }
}

locals {
  ec2_name = "${var.creator_tag}_SQL_${var.environment}"
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
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

module "fsxontap" {
  source = "./modules/fsxn"

  fsxn_password           = var.fsxn_password
  fsxn_deployment_type    = "SINGLE_AZ_1"
  fsxn_subnet_ids         = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]
  fsxn_security_group_ids = [aws_security_group.sg-fsx.id]
  fsxn_volume_name_prefix = local.ec2_name

  creator_tag = var.creator_tag
}

module "sqlserver" {
  source = "./modules/ec2"

  ec2_instance_name       = local.ec2_name
  ec2_instance_type       = var.ec2_instance_type
  ec2_instance_key_pair   = var.ec2_instance_keypair
  iam_instance_profile   =  aws_iam_instance_profile.main.name
  ec2_subnet_id           = aws_subnet.public_subnet[0].id
  ec2_security_groups_ids = [aws_security_group.sg-fsx.id, aws_security_group.sg-AllowRemoteToEC2.id]
  admin_password          = random_password.password.result

  fsxn_password        = var.fsxn_password
  fsxn_iscsi_ips       = module.fsxontap.fsx_svm_iscsi_endpoints
  fsxn_svm             = module.fsxontap.fsx_svm.name
  fsxn_management_ip   = module.fsxontap.fsx_management_management_ip
  fsxn_sql_data_volume = module.fsxontap.fsx_sql_data_volume
  fsxn_sql_log_volume  = module.fsxontap.fsx_sql_log_volume

  sql_data_volume_drive_letter  = "D"
  sql_log_volume_drive_letter   = "E"
  sql_install_sample_database   = true
  sevenzip_download_url         = var.sevenzip_download_url
  sample_databasde_download_url = var.sample_databasde_download_url

  creator_tag = var.creator_tag
  depends_on  = [module.fsxontap]
}
