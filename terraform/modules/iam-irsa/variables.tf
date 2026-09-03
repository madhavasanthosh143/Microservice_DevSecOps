variable "name_prefix" {
  type = string
}

variable "create_github_oidc_provider" {
  description = "False if the GitHub OIDC provider already exists in this AWS account"
  type        = bool
  default     = true
}

variable "existing_github_oidc_provider_arn" {
  type    = string
  default = ""
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "ecr_repository_arns" {
  type = list(string)
}

variable "eks_cluster_arn" {
  type = string
}

variable "eks_oidc_provider_arn" {
  type = string
}

variable "eks_oidc_provider_url" {
  description = "OIDC provider URL without the https:// prefix"
  type        = string
}

variable "irsa_roles" {
  description = "Map of role key -> { namespace, service_account, policy_arns }"
  type = map(object({
    namespace       = string
    service_account = string
    policy_arns     = list(string)
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
