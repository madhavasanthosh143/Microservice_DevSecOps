data "aws_caller_identity" "current" {}

locals {
  cluster_name = "${var.name_prefix}-${var.environment}"

  common_tags = {
    Project     = "microservices-demo"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix         = "${var.name_prefix}-${var.environment}"
  cluster_name        = local.cluster_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  tags                = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name           = local.cluster_name
  kubernetes_version     = var.kubernetes_version
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  public_subnet_ids      = module.vpc.public_subnet_ids
  enable_public_endpoint = true # dev only — keep false and use a VPN/bastion for prod
  node_instance_types    = var.node_instance_types
  node_desired_size      = var.node_desired_size
  node_min_size          = var.node_min_size
  node_max_size          = var.node_max_size
  tags                   = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix       = var.name_prefix
  repository_names  = var.microservices
  tags              = local.common_tags
}

module "iam_irsa" {
  source = "../../modules/iam-irsa"

  name_prefix            = "${var.name_prefix}-${var.environment}"
  github_org             = var.github_org
  github_repo            = var.github_repo
  ecr_repository_arns    = values(module.ecr.repository_arns)
  eks_cluster_arn        = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}"
  eks_oidc_provider_arn  = module.eks.oidc_provider_arn
  eks_oidc_provider_url  = module.eks.oidc_provider_url

  # Example IRSA grant: gives each service's pod identity read access to
  # Secrets Manager for pulling runtime secrets (JWT signing key, DB creds).
  irsa_roles = {
    for svc in var.microservices : svc => {
      namespace       = "microservices"
      service_account = svc
      policy_arns     = ["arn:aws:iam::aws:policy/SecretsManagerReadWrite"]
    }
  }

  tags = local.common_tags
}
