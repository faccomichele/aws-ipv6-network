resource "aws_vpc" "this" {
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = true
  enable_dns_hostnames             = true

  tags = merge(local.tags,
    {
      Name = "${local.project_name}-vpc"
      File = "main.tf"
    }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags,
    {
      Name = "${local.project_name}-igw"
      File = "main.tf"
    }
  )
}

resource "aws_egress_only_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags,
    {
      Name = "${local.project_name}-eigw"
      File = "main.tf"
      Tier = "public"
    }
  )
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                              = aws_vpc.this.id
  availability_zone                   = each.value.az
  ipv6_cidr_block                     = each.value.ipv6_cidr_block
  ipv6_native                         = true
  assign_ipv6_address_on_creation     = true
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "resource-name"

  tags = merge(local.tags,
    {
      Name = "${local.project_name}-public-${each.key}"
      File = "main.tf"
      Tier = "public"
    }
  )
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                              = aws_vpc.this.id
  availability_zone                   = each.value.az
  ipv6_cidr_block                     = each.value.ipv6_cidr_block
  ipv6_native                         = true
  assign_ipv6_address_on_creation     = true
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "resource-name"

  tags = merge(local.tags,
    {
      Name = "${local.project_name}-private-${each.key}"
      File = "main.tf"
      Tier = "private"
    }
  )
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags,
    {
      Name = "${local.project_name}-default-sg-locked"
      File = "main.tf"
    }
  )
}

resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.this.default_network_acl_id
  tags                   = merge(local.tags, { Name = "${local.project_name}-default-nacl-locked" })
}
