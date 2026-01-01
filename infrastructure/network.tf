module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = "${var.name}-${local.name}"
  cidr = var.cidr_block
  azs  = local.azs

  private_subnets  = [for idx, _ in local.azs : cidrsubnet(var.cidr_block, 4, idx)]
  public_subnets   = [for idx, _ in local.azs : cidrsubnet(var.cidr_block, 8, idx + 48)]
  intra_subnets    = [for idx, _ in local.azs : cidrsubnet(var.cidr_block, 8, idx + 52)]
  database_subnets = [for idx, _ in local.azs : cidrsubnet(var.cidr_block, 8, idx + 56)]

  private_subnet_names  = [for idx, _ in local.azs : "${local.name}-private-${idx}"]
  public_subnet_names   = [for idx, _ in local.azs : "${local.name}-public-${idx}"]
  intra_subnet_names    = [for idx, _ in local.azs : "${local.name}-intra-${idx}"]
  database_subnet_names = [for idx, _ in local.azs : "${local.name}-database-${idx}"]

  # Default Security Group, Route Table, and Network ACL Management
  manage_default_security_group = true
  manage_default_route_table    = true
  manage_default_network_acl    = true

  # Enable DNS and NAT Gateway Configuration
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs Configuration
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  flow_log_max_aggregation_interval    = 60

  # Tagging for Subnets and VPC Resources
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "karpenter-managed"                         = "true"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "karpenter-managed"                         = "true"
  }

  tags = merge(local.tags, { Name = "${var.name}-vpc" })
}
