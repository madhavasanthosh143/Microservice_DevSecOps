resource "aws_ecr_repository" "this" {
  for_each = toset(var.repository_names)

  name                 = "${var.name_prefix}/${each.value}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 20 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = { type = "expire" }
      }
    ]
  })
}

locals {
  # Only attach a cross-principal pull policy when explicit principals are given;
  # otherwise repos rely on the node/CI role's IAM policy grants instead.
  repos_needing_policy = length(var.pull_principal_arns) > 0 ? aws_ecr_repository.this : {}
}

resource "aws_ecr_repository_policy" "this" {
  for_each   = local.repos_needing_policy
  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowNodeAndCIPull"
      Effect    = "Allow"
      Principal = { AWS = var.pull_principal_arns }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
      ]
    }]
  })
}
