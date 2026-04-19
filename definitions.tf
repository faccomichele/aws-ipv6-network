locals {
  environment  = split("_", terraform.workspace)[0]
  aws_region   = split("_", terraform.workspace)[1]
  project_name = var.tags["Project"] != null ? var.tags["Project"] : "unknown"
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

  tags = merge (var.tags, {
    Project = local.project_name
  })
}
