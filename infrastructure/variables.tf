#-----------------------------------
# General variables
#-----------------------------------
variable "region" {
  description = "The AWS region to deploy resources."
  default     = "eu-south-1"
  type        = string
  validation {
    condition     = startswith(var.region, "eu-")
    error_message = "The region must be in Europe"
  }

}

variable "name" {
  description = "The name of the application."
  type        = string
  validation {
    condition     = length(var.name) > 0
    error_message = "Variable name must be a string, and cannot be empty."
  }
}

variable "environment" {
  description = "The environment to deploy the application."
  type        = string
  default     = "prod"
  validation {
    condition     = can(regex("^(dev|tst|stg|prod)$", var.environment))
    error_message = "The environment must be dev, tst, stg, or prod."
  }
}

variable "profile" {
  description = "The AWS profile to use."
  type        = string
  validation {
    condition     = length(var.profile) > 0
    error_message = "The profile must be a string, and cannot be empty."
  }
}

variable "project" {
  description = "The project name."
  type        = string
  validation {
    condition     = length(var.project) > 0
    error_message = "The project name must be a string, and cannot be empty."
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}


#-----------------------------------
# VPC variables
#-----------------------------------
variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "The CIDR block must be a valid IPv4 address range."
  }
}

variable "az_count" {
  default     = 3
  description = "The number of availability zones to use."
  type        = number
  validation {
    condition     = var.az_count > 0 && var.az_count <= 3
    error_message = "The number of availability zones must be between 1 and 3."
  }
}

#-----------------------------------
# EKS variables
#-----------------------------------
variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
  default     = "eks-cluster"
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster name must be a string, and cannot be empty."
  }
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.29`)"
  type        = string
  default     = "1.32"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.cluster_version))
    error_message = "The cluster version must be in the format `<major>.<minor>`."
  }
}

variable "instance_types" {
  type        = list(string)
  description = "The instance type of the EKS cluster nodes."
  default     = ["t3.large"]

  validation {
    condition     = alltrue([for it in var.instance_types : contains(["t3.large", "t3.xlarge", "t3.2xlarge", "c7a.2xlarge"], it)])
    error_message = "Each instance type must be one of 't3.large', 't3.xlarge', or 't3.2xlarge', 'c7a.2xlarge'."
  }
}

variable "instance_types_system" {
  type        = list(string)
  description = "The instance type of the EKS cluster nodes."
  default     = ["t3.large"]

  validation {
    condition     = alltrue([for it in var.instance_types_system : contains(["t3.large", "t3.xlarge", "t3.2xlarge", "c7a.2xlarge"], it)])
    error_message = "Each instance type must be one of 't3.large', 't3.xlarge', or 't3.2xlarge', 'c7a.2xlarge'."
  }
}

variable "disk_size" {
  type        = number
  description = "The disk size of the EKS cluster nodes."
  default     = 80
  validation {
    condition     = contains([40, 80, 100], var.disk_size)
    error_message = "The disk size must be greater than 0."
  }
}

variable "disk_size_system" {
  type        = number
  description = "The disk size of the EKS cluster nodes."
  default     = 80
  validation {
    condition     = contains([40, 80, 100], var.disk_size_system)
    error_message = "The disk size must be greater than 0."
  }
}

variable "node_count" {
  type        = number
  description = "The number of nodes in the EKS cluster."
  default     = 3
  validation {
    condition     = var.node_count > 0
    error_message = "The number of nodes must be greater than 0."
  }
}

variable "node_count_system" {
  type        = number
  description = "The number of nodes in the EKS cluster."
  default     = 3
  validation {
    condition     = var.node_count_system > 0
    error_message = "The number of nodes must be greater than 0."
  }
}

variable "node_count_max" {
  type        = number
  description = "The maximum number of nodes in the EKS cluster."
  default     = 6
  validation {
    condition     = var.node_count_max > 0
    error_message = "The maximum number of nodes must be greater than node_count."
  }
}

variable "node_count_max_system" {
  type        = number
  description = "The maximum number of nodes in the EKS cluster."
  default     = 6
  validation {
    condition     = var.node_count_max_system > 0
    error_message = "The maximum number of nodes must be greater than node_count."
  }
}

variable "node_count_min" {
  type        = number
  description = "The minimum number of nodes in the EKS cluster."
  default     = 1
  validation {
    condition     = var.node_count_min >= 0
    error_message = "The minimum number of nodes must be less than node_count."
  }
}

variable "node_count_min_system" {
  type        = number
  description = "The minimum number of nodes in the EKS cluster."
  default     = 1
  validation {
    condition     = var.node_count_min_system >= 0
    error_message = "The minimum number of nodes must be less than node_count."
  }
}

variable "ami_type" {
  type        = string
  description = "The AMI type of the EKS cluster nodes (AL2023, AL2, or Bottlerocket)."
  default     = "AL2023_x86_64_STANDARD"
  validation {
    condition = contains([
      "AL2_x86_64",
      "AL2_x86_64_GPU",
      "AL2_ARM_64",
      "AL2023_x86_64_STANDARD",
      "AL2023_ARM_64_STANDARD",
      "BOTTLEROCKET_x86_64",
      "BOTTLEROCKET_ARM_64"
    ], var.ami_type)
    error_message = "The AMI type must be one of: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64."
  }
}

variable "ami_type_system" {
  type        = string
  description = "The AMI type of the EKS system node group (AL2023, AL2, or Bottlerocket)."
  default     = "AL2023_x86_64_STANDARD"
  validation {
    condition = contains([
      "AL2_x86_64",
      "AL2_x86_64_GPU",
      "AL2_ARM_64",
      "AL2023_x86_64_STANDARD",
      "AL2023_ARM_64_STANDARD",
      "BOTTLEROCKET_x86_64",
      "BOTTLEROCKET_ARM_64"
    ], var.ami_type_system)
    error_message = "The AMI type must be one of: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64."
  }
}

variable "bottlerocket_admin_container_enabled" {
  type        = bool
  description = "Enable the Bottlerocket admin container for debugging."
  default     = false
}

variable "bottlerocket_control_container_enabled" {
  type        = bool
  description = "Enable the Bottlerocket control container."
  default     = true
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "node-group-app"
}

variable "node_group_name_system" {
  description = "Name of the EKS node group"
  type        = string
  default     = "node-group-system"
}

#-----------------------------------
# EKS Security variables
#-----------------------------------
variable "cluster_endpoint_public_access" {
  description = "Enable public access to the EKS cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks to allow public access to the EKS cluster endpoint. Use your IP/CIDR for security."
  type        = list(string)
  default     = ["0.0.0.0/0"] # CHANGE THIS to your IP range for production
  validation {
    condition     = length(var.cluster_endpoint_public_access_cidrs) > 0
    error_message = "At least one CIDR block must be specified."
  }
}
