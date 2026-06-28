# IAM Role para GitHub Actions via OIDC
# Execute: terraform apply no bootstrap/ antes de qualquer pipeline

variable "github_org" {
  type        = string
  description = "Org ou usuario do GitHub (ex: aldasirepo)"
}

variable "github_repo" {
  type        = string
  description = "Nome do repo terraform (ex: terraform-hackathon)"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "solidarytech-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
  tags = {
    Project   = "SolidaryTech"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "solidarytech-github-actions-policy"
  description = "Permissoes minimas para Terraform via GitHub Actions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:*", "ec2:*", "elasticloadbalancing:*"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["iam:*"]
        Resource = [
          "arn:aws:iam::*:role/solidarytech-*",
          "arn:aws:iam::*:policy/solidarytech-*",
          "arn:aws:iam::*:oidc-provider/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["rds:*", "dynamodb:*", "sqs:*"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = ["arn:aws:s3:::solidarytech-*", "arn:aws:s3:::solidarytech-*/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:*"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sts:AssumeRole", "sts:GetCallerIdentity"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:*"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Valor para o GitHub Secret AWS_ROLE_ARN"
}
