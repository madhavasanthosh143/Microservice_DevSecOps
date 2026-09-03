output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "github_actions_role_arn" {
  description = "Put this in the GitHub repo/environment variable AWS_ROLE_ARN used by the CI workflows"
  value       = module.iam_irsa.github_actions_role_arn
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
