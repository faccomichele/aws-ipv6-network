resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags,
    {
      Name = "${local.project_name}-public-nacl"
      File = "nacls.tf"
    }
  )
}

resource "aws_network_acl_association" "public" {
  for_each = aws_subnet.public

  network_acl_id = aws_network_acl.public.id
  subnet_id      = each.value.id
}

resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags,
    {
      Name = "${local.project_name}-private-nacl"
      File = "nacls.tf"
    }
  )
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
