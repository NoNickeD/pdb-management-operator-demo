#-----------------------------------
# General Outputs
#-----------------------------------
output "region" {
  description = "AWS region"
  value       = var.region
}

output "profile" {
  description = "AWS CLI profile"
  value       = var.profile
}

#-----------------------------------
# EKS Outputs
#-----------------------------------
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

#-----------------------------------
# VPC Outputs
#-----------------------------------
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

#-----------------------------------
# Identity Outputs
#-----------------------------------
output "current_identity" {
  description = "The ARN of the current AWS caller identity"
  value       = local.current_identity
}

#-----------------------------------
# Validation Outputs
#-----------------------------------
output "validation_errors" {
  description = "List of validation errors (empty if all validations pass)"
  value       = local.validation_errors
}

#-----------------------------------
# IRSA Outputs
#-----------------------------------
output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = module.irsa_external_secrets.arn
}
