variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "name_prefix" {
  description = "Short project identifier, used to namespace resources (e.g. \"msdemo\")"
  type        = string
  default     = "msdemo"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 3
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 6
}

variable "microservices" {
  description = "Names of the microservices — drives ECR repo creation and IRSA role names"
  type        = list(string)
  default     = ["auth-service", "user-service", "order-service", "inventory-service", "api-gateway"]
}

variable "github_org" {
  description = "GitHub org/user that owns the repo, for the OIDC trust policy"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name, for the OIDC trust policy"
  type        = string
}
