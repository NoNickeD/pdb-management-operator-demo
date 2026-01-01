data "aws_iam_policy" "ecr_readonly_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.10.1"

  # Cluster Configuration (v21.x argument names)
  name                                     = var.cluster_name
  kubernetes_version                       = var.cluster_version
  endpoint_public_access                   = var.cluster_endpoint_public_access
  endpoint_public_access_cidrs             = var.cluster_endpoint_public_access_cidrs
  endpoint_private_access                  = true
  enable_cluster_creator_admin_permissions = true
  create_iam_role                          = true
  enable_irsa                              = true

  # Cluster Addons (v21.x: cluster_addons → addons)
  addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa_ebs_csi.arn
      most_recent              = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true # Ensure CNI is ready before nodes join
      service_account_role_arn = module.irsa_vpc_cni.arn
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  # Network Configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cluster Logging Configuration (v21.x: cluster_enabled_log_types → enabled_log_types)
  enabled_log_types                      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 90

  # Managed Node Groups (v21.x: eks_managed_node_group_defaults removed, use node_iam_role_additional_policies)
  node_iam_role_additional_policies = {
    ecr_readonly = data.aws_iam_policy.ecr_readonly_policy.arn
  }

  eks_managed_node_groups = {
    default = {
      name           = var.node_group_name
      ami_type       = var.ami_type
      instance_types = var.instance_types
      min_size       = var.node_count_min
      max_size       = var.node_count_max
      desired_size   = var.node_count
      capacity_type  = "ON_DEMAND"

      # Explicit block device mapping for root volume
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.disk_size
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # Update configuration for rolling updates
      update_config = {
        max_unavailable_percentage = 33
      }

      # Bottlerocket-specific configuration
      bootstrap_extra_args = local.is_bottlerocket ? local.bottlerocket_bootstrap_extra_args : null

      labels = {
        "app-type" = "default"
      }
    }

    system = {
      name           = var.node_group_name_system
      ami_type       = var.ami_type_system
      instance_types = var.instance_types_system
      min_size       = var.node_count_min_system
      max_size       = var.node_count_max_system
      desired_size   = var.node_count_system
      capacity_type  = "ON_DEMAND"

      # Explicit block device mapping for root volume
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.disk_size_system
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # Update configuration for rolling updates
      update_config = {
        max_unavailable_percentage = 33
      }

      # Bottlerocket-specific configuration
      bootstrap_extra_args = local.is_bottlerocket_system ? local.bottlerocket_bootstrap_extra_args : null

      labels = {
        "node-type" = "system"
      }
      taints = {
        system = {
          key    = "node-type"
          value  = "system"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  iam_role_additional_policies = {
    eks_full_access = aws_iam_policy.eks_full_access.arn
  }

  # Tagging
  tags = merge(local.tags, { Name = "${var.name}-eks" })
}


module "irsa_ebs_csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.3"

  name                  = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "irsa_vpc_cni" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.3"

  name                  = "AmazonEKSVPCCNIRole-${module.eks.cluster_name}"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}

module "irsa_aws_lb_controller" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.3"

  name                                   = "EKSLBController-${module.eks.cluster_name}"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}

# =============================================================================
# AWS Load Balancer Controller (required for EKS LoadBalancer services)
# =============================================================================
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.11.0"

  values = [
    yamlencode({
      clusterName = module.eks.cluster_name
      region      = var.region
      vpcId       = module.vpc.vpc_id
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.irsa_aws_lb_controller.arn
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    module.irsa_aws_lb_controller
  ]
}
