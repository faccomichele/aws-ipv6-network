variable "tags" {
  description = "Map of tags to assign to resources"
  type        = map(string)
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/24"
}
