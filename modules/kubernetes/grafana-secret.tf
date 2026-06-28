resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
    labels = merge(var.tags, {
      "app.kubernetes.io/managed-by" = "terraform"
    })
  }
}

resource "random_password" "grafana_admin" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin-secret"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }
  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana_admin.result
  }
  type = "Opaque"

  lifecycle {
    ignore_changes = [data]
  }

  depends_on = [kubernetes_namespace_v1.monitoring]
}
