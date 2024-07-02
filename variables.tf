variable "region" {
  description = "The AWS region to deploy in"
  default     = "eu-west-1"
}

variable "instance_name" {
  description = "The name of the instance"
  type        = string
}

variable "instance_type" {
  description = "The instance type"
  type        = string
}

variable "key_name" {
  description = "The name of the key pair"
  type        = string
}

variable "key_pair_public_material" {
  description = "The public material for the key pair"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID of the Windows Server"
  type        = string
}

variable "admin_password" {
  description = "The password for the Administrator user"
  type        = string
}
