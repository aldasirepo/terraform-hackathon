data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  tags            = var.tags
}

# IRSA Role - volunteer-service (DynamoDB)
data "aws_iam_policy_document" "volunteer_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:solidarytech:volunteer-service-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "volunteer_service" {
  name               = "${var.project_name}-volunteer-service-role"
  assume_role_policy = data.aws_iam_policy_document.volunteer_assume.json
  tags               = var.tags
}

resource "aws_iam_policy" "volunteer_dynamodb" {
  name        = "${var.project_name}-volunteer-dynamodb-policy"
  description = "Permite volunteer-service acessar DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ]
      Resource = [
        "arn:aws:dynamodb:*:*:table/${var.project_name}-volunteers-*",
        "arn:aws:dynamodb:*:*:table/${var.project_name}-volunteers-*/index/*"
      ]
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "volunteer_dynamodb" {
  role       = aws_iam_role.volunteer_service.name
  policy_arn = aws_iam_policy.volunteer_dynamodb.arn
}
