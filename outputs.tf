output "ec2_public_ip" {
  value = "http://${aws_spot_instance_request.ecr_instance.public_ip}"
}

output "ec2_private_ip" {
  value = "http://${aws_spot_instance_request.ecr_instance.private_ip}"
}

output "ec2_public_dns" {
  value = "http://${aws_spot_instance_request.ecr_instance.public_dns}"
}

output "ssh_connection" {
  value = "ssh -i ~/.ssh/${var.key_name}.pem ${var.ec2_user}@${aws_spot_instance_request.ecr_instance.public_ip}"
}
