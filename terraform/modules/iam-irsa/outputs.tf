output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_deploy.arn
}

output "irsa_role_arns" {
  value = { for key, role in aws_iam_role.irsa : key => role.arn }
}
