output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.main.public_dns
}

output "username" {
  description = "The username of the EC2 instance"
  value       = "Administrator"
}

output "password" {
  description = "The password of the EC2 instance"
  value       = random_password.password.result
  sensitive   = false
}

output "connection_type" {
    description = "The connection type to the EC2 instance"
    value       = "rdp"
}