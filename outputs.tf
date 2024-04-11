output "ec2_arn" {
  description = "The ARN of the EC2 instance"
  value       = module.ec2_instance.arn
}

output "ec2_private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = module.ec2_instance.private_ip
}

output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = module.ec2_instance.public_ip
}

output "ec2_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = module.ec2_instance.public_dns
}
