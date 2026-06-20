data "aws_region" "current" {}

resource "kubernetes_namespace_v1" "solidarytech" {
  metadata {
    name   = "solidarytech"
    labels = merge(var.tags, { "app.kubernetes.io/managed-by" = "terraform" })
  }
}

resource "kubernetes_secret_v1" "ngo_service" {
  depends_on = [kubernetes_namespace_v1.solidarytech]
  metadata {
    name      = "ngo-service-secrets"
    namespace = "solidarytech"
  }
  data = {
    database-url = "postgresql://${var.db_user}:${var.db_password}@${var.rds_endpoint}/solidarytech?sslmode=require"
  }
  type = "Opaque"
}

resource "kubernetes_secret_v1" "donation_service" {
  depends_on = [kubernetes_namespace_v1.solidarytech]
  metadata {
    name      = "donation-service-secrets"
    namespace = "solidarytech"
  }
  data = {
    database-url = "postgresql://${var.db_user}:${var.db_password}@${var.rds_endpoint}/solidarytech?sslmode=require"
    sqs-url      = var.sqs_queue_url
  }
  type = "Opaque"
}
