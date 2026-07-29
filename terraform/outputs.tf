output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.app_sg.id
}

output "elastic_ip" {
  description = "The Elastic IP address associated with the EC2 instance"
  value       = aws_eip.app_eip.public_ip
}