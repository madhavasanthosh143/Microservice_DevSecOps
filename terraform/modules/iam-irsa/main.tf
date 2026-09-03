# --- GitHub Actions OIDC federation -----------------------------------------
# Lets CI assume an AWS role via short-lived OIDC tokens (no long-lived access
# keys stored in GitHub secrets) to push images and deploy to EKS.

data "tls_certificate" "github" {
  count = var.create_github_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_github_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github[0].certificates[0].sha1_fingerprint]

  tags = var.tags
}

locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_github_oidc_provider_arn
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "${var.name_prefix}-github-actions-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.github_oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Restrict to this repo, any branch/tag/PR — tighten to a specific
          # ref (e.g. "repo:org/repo:ref:refs/heads/main") for prod deploys.
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "ecr-push-pull"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
        ]
        Resource = var.ecr_repository_arns
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_eks" {
  name = "eks-describe-deploy"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster", "eks:ListClusters"]
      Resource = var.eks_cluster_arn
    }]
  })
}

# --- IRSA: pod-level IAM roles ----------------------------------------------
# One role per Kubernetes ServiceAccount, scoped to only the policies that
# service actually needs (least privilege, no shared node-wide credentials).

resource "aws_iam_role" "irsa" {
  for_each = var.irsa_roles

  name = "${var.name_prefix}-irsa-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.eks_oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.eks_oidc_provider_url}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
          "${var.eks_oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "irsa" {
  for_each = {
    for pair in flatten([
      for role_key, role in var.irsa_roles : [
        for policy_arn in role.policy_arns : {
          key        = "${role_key}-${policy_arn}"
          role_key   = role_key
          policy_arn = policy_arn
        }
      ]
    ]) : pair.key => pair
  }

  role       = aws_iam_role.irsa[each.value.role_key].name
  policy_arn = each.value.policy_arn
}
