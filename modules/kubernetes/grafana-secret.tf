resource "random_password" "grafana_admin" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin-secret"
    namespace = "monitoring"
  }
  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana_admin.result
  }
  type = "Opaque"

  lifecycle {
    # Evita rotação automática - senha gerenciada externamente após primeiro apply
    ignore_changes = [data]
  }
}
