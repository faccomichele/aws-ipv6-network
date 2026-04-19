terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  selected_azs = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnets = {
    for index, az in local.selected_azs : az => {
      az              = az
      ipv6_cidr_block = cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, index)
    }
  }

  private_subnets = {
    for index, az in local.selected_azs : az => {
      az              = az
      ipv6_cidr_block = cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, index + 3)
    }
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_vpc" "this" {
  cidr_block                       = var.vpc_ipv4_cidr
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = true
  enable_dns_hostnames             = true

  tags = merge(local.tags, { Name = "${var.project_name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project_name}-igw" })
}

resource "aws_egress_only_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project_name}-eigw" })
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

  tags = merge(local.tags, {
    Name = "${var.project_name}-public-${each.key}"
    Tier = "public"
  })
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

  tags = merge(local.tags, {
    Name = "${var.project_name}-private-${each.key}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project_name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project_name}-private-rt" })
}

resource "aws_route" "private_egress" {
  route_table_id              = aws_route_table.private.id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.this.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project_name}-public-nacl" })
}

resource "aws_network_acl_association" "public" {
  for_each = aws_subnet.public

  network_acl_id = aws_network_acl.public.id
  subnet_id      = each.value.id
}

resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project_name}-private-nacl" })
}

resource "aws_network_acl_association" "private" {
  for_each = aws_subnet.private

  network_acl_id = aws_network_acl.private.id
  subnet_id      = each.value.id
}

resource "aws_network_acl_rule" "public_ingress_vpc" {
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 100
  egress          = false
  protocol        = "-1"
  rule_action     = "allow"
  ipv6_cidr_block = aws_vpc.this.ipv6_cidr_block
  from_port       = 0
  to_port         = 0
}

resource "aws_network_acl_rule" "public_ingress_https" {
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 110
  egress          = false
  protocol        = "6"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 443
  to_port         = 443
}

resource "aws_network_acl_rule" "public_ingress_ephemeral" {
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 120
  egress          = false
  protocol        = "6"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 1024
  to_port         = 65535
}

resource "aws_network_acl_rule" "public_egress_vpc" {
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 100
  egress          = true
  protocol        = "-1"
  rule_action     = "allow"
  ipv6_cidr_block = aws_vpc.this.ipv6_cidr_block
  from_port       = 0
  to_port         = 0
}

resource "aws_network_acl_rule" "public_egress_https" {
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 110
  egress          = true
  protocol        = "6"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 443
  to_port         = 443
}

resource "aws_network_acl_rule" "public_egress_ssh" {
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 120
  egress          = true
  protocol        = "6"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 22
  to_port         = 22
}

resource "aws_network_acl_rule" "public_egress_ephemeral" {
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 130
  egress          = true
  protocol        = "6"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 1024
  to_port         = 65535
}

resource "aws_network_acl_rule" "private_ingress_vpc" {
  network_acl_id  = aws_network_acl.private.id
  rule_number     = 100
  egress          = false
  protocol        = "-1"
  rule_action     = "allow"
  ipv6_cidr_block = aws_vpc.this.ipv6_cidr_block
  from_port       = 0
  to_port         = 0
}

resource "aws_network_acl_rule" "private_ingress_ephemeral" {
  network_acl_id  = aws_network_acl.private.id
  rule_number     = 110
  egress          = false
  protocol        = "6"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 1024
  to_port         = 65535
}

resource "aws_network_acl_rule" "private_egress_vpc" {
  network_acl_id  = aws_network_acl.private.id
  rule_number     = 100
  egress          = true
  protocol        = "-1"
  rule_action     = "allow"
  ipv6_cidr_block = aws_vpc.this.ipv6_cidr_block
  from_port       = 0
  to_port         = 0
}

resource "aws_network_acl_rule" "private_egress_https" {
  network_acl_id  = aws_network_acl.private.id
  rule_number     = 110
  egress          = true
  protocol        = "6"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 443
  to_port         = 443
}

resource "aws_network_acl_rule" "private_egress_ssh" {
  network_acl_id  = aws_network_acl.private.id
  rule_number     = 120
  egress          = true
  protocol        = "6"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 22
  to_port         = 22
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project_name}-default-sg-locked" })
}

resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.this.default_network_acl_id
  tags                   = merge(local.tags, { Name = "${var.project_name}-default-nacl-locked" })
}
