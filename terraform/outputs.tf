output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.red_team_vpc.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.red_team_subnet.id
}

output "sliver_c2_public_ip" {
  description = "Public IP of Sliver C2 server"
  value       = aws_instance.sliver_c2.public_ip
}

output "sliver_c2_private_ip" {
  description = "Private IP of Sliver C2 server"
  value       = aws_instance.sliver_c2.private_ip
}

output "redirector_public_ip" {
  description = "Public IP of redirector"
  value       = aws_instance.redirector.public_ip
}

output "redirector_private_ip" {
  description = "Private IP of redirector"
  value       = aws_instance.redirector.private_ip
}

output "attacker_workstation_public_ip" {
  description = "Public IP of attacker workstation"
  value       = aws_instance.attacker_workstation.public_ip
}

output "attacker_workstation_private_ip" {
  description = "Private IP of attacker workstation"
  value       = aws_instance.attacker_workstation.private_ip
}
