# aws-ipv6-network

Terraform templates to deploy an AWS VPC designed for IPv6-native workloads:

- AWS-assigned IPv6 CIDR block on the VPC
- 3 public + 3 private IPv6-native subnets (`/64`, minimal IPv6 subnet size in AWS)
- Dedicated route table for public and private tiers
- Public internet routing through an Internet Gateway
- Private egress-only internet routing through an Egress-Only Internet Gateway
- Dedicated NACL per tier with:
  - free VPC-internal communications
  - internet egress limited to HTTPS (`443`) and SSH (`22`)
  - ephemeral return traffic rules
  - internet ingress HTTPS only on public tier (+ ephemeral return traffic)
- Default security group locked down (no rules)
- Default network ACL locked down (no rules)

> Note: AWS currently requires an IPv4 CIDR on the VPC itself. The template keeps it at the minimal `/28`, while all workload subnets are IPv6-native (no IPv4 CIDR on subnets).

## Usage

```hcl
module "ipv6_network" {
  source = "./"

  aws_region   = "eu-west-1"
  project_name = "example-ipv6-network"
}
```
