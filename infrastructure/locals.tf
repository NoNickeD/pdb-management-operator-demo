locals {
  tags = merge({
    ManagedBy   = "opentofu"
    Project     = var.project
    Environment = var.environment
  }, var.additional_tags)

  name = format("%s-%s", var.project, var.environment)

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Bottlerocket bootstrap configuration (TOML format)
  bottlerocket_bootstrap_extra_args = <<-EOT
    [settings.host-containers.admin]
    enabled = ${var.bottlerocket_admin_container_enabled}

    [settings.host-containers.control]
    enabled = ${var.bottlerocket_control_container_enabled}

    [settings.kernel]
    lockdown = "integrity"
  EOT

  # Check if AMI type is Bottlerocket
  is_bottlerocket        = startswith(var.ami_type, "BOTTLEROCKET_")
  is_bottlerocket_system = startswith(var.ami_type_system, "BOTTLEROCKET_")

  validation_errors = concat(
    # Validate node_count > 0
    var.node_count > 0 ? [] : ["The number of nodes must be greater than 0."],
    # Validate node_count_max > node_count
    var.node_count_max > var.node_count ? [] : ["The maximum number of nodes must be greater than node_count."],
    # Validate node_count_min < node_count
    var.node_count_min < var.node_count ? [] : ["The minimum number of nodes must be less than node_count."]
  )

  current_identity = data.aws_caller_identity.current.arn

}
