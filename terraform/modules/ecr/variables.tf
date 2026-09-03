variable "name_prefix" {
  description = "Prefix namespace for repos, e.g. \"myorg\" produces myorg/auth-service"
  type        = string
}

variable "repository_names" {
  description = "One ECR repository is created per name in this list"
  type        = list(string)
}

variable "pull_principal_arns" {
  description = "IAM principal ARNs allowed to pull (leave empty to rely on node/CI role IAM policies instead)"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
