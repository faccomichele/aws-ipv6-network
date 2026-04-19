variable "aws_region" {
  description = "AWS region where resources are created."
  type        = string
}

variable "project_name" {
  description = "Prefix used in tags and resource names."
  type        = string
  default     = "ipv6-only-network"
}

variable "vpc_ipv4_cidr" {
  description = "Minimal IPv4 CIDR required by AWS for the VPC control plane."
  type        = string
  default     = "10.0.0.0/28"
}
