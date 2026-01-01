#--------------------------------
# IAM Roles and Policies
#--------------------------------
resource "aws_iam_policy" "eks_full_access" {
  name        = "${var.name}-EKSNodePolicy"
  description = "Scoped access for EKS node operations"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EKSClusterAccess"
        Effect = "Allow",
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:AccessKubernetesApi"
        ],
        Resource = "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
      },
      {
        Sid    = "EC2DescribeAccess"
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeRouteTables"
        ],
        Resource = "*"
      },
      {
        Sid    = "ECRAccess"
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

#--------------------------------
# IRSA for External Secrets Operator
#--------------------------------
module "irsa_external_secrets" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.3"

  name = "ExternalSecretsRole-${module.eks.cluster_name}"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }

  tags = local.tags

  depends_on = [module.eks]
}

resource "aws_iam_role_policy" "external_secrets_policy" {
  name = "external-secrets-policy"
  role = module.irsa_external_secrets.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:oda-canvas/*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:datadog/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/oda-canvas/*",
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/datadog/*"
        ]
      }
    ]
  })

  depends_on = [module.irsa_external_secrets]
}
