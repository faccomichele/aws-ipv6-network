output "vpc_id" {
  description = "ID of the IPv6-enabled VPC."
  value       = aws_vpc.this.id
}

output "vpc_ipv6_cidr_block" {
  description = "AWS-assigned IPv6 CIDR block for the VPC."
  value       = aws_vpc.this.ipv6_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the three public IPv6-native subnets."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of the three private IPv6-native subnets."
  value       = [for subnet in aws_subnet.private : subnet.id]
}
