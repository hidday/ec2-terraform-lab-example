creator_tag           = "Strigo-Netapp"
environment           = "Netapp-Demo"
aws_location          = "eu-west-1"
availability_zones    = ["eu-west-1a", "eu-west-1b"]
ec2_instance_type     = "t3.2xlarge"
ec2_instance_keypair  = "TerraformKeyPair"
fsxn_password         = "P@ssw0rd@123"
volume_security_style = "NTFS"
vpc_cidr              = "10.0.0.0/16"
public_subnets_cidr   = ["10.0.0.0/20", "10.0.16.0/20"]
private_subnets_cidr  = ["10.0.128.0/20", "10.0.144.0/20"]
sevenzip_download_url = ""
sample_databasde_download_url = ""
admin_password           = "NetAppStudent123!"
