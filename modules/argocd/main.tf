resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name   = var.argocd_namespace
    labels = merge(var.tags, { "app.kubernetes.io/managed-by" = "terraform" })
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  timeout    = 600
  wait       = true
  depends_on = [kubernetes_namespace_v1.argocd]
}

resource "kubectl_manifest" "argocd_project" {
  yaml_body  = file("${var.cd_apps_path}/project.yaml")
  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_root_app" {
  yaml_body  = file("${var.cd_apps_path}/root-app.yaml")
  depends_on = [kubectl_manifest.argocd_project]
}

resource "kubectl_manifest" "argocd_prometheus" {
  yaml_body  = file("${var.cd_apps_path}/monitoring/argocd-app-prometheus.yaml")
  depends_on = [kubectl_manifest.argocd_project]
}

resource "kubectl_manifest" "argocd_loki" {
  yaml_body  = file("${var.cd_apps_path}/monitoring/argocd-app-loki.yaml")
  depends_on = [kubectl_manifest.argocd_project]
}

resource "kubectl_manifest" "argocd_otel" {
  yaml_body  = file("${var.cd_apps_path}/monitoring/argocd-app-otel.yaml")
  depends_on = [kubectl_manifest.argocd_project]
}

resource "kubectl_manifest" "argocd_tempo" {
  yaml_body  = file("${var.cd_apps_path}/monitoring/argocd-app-tempo.yaml")
  depends_on = [kubectl_manifest.argocd_project]
}

resource "kubectl_manifest" "argocd_velero" {
  yaml_body  = file("${var.cd_apps_path}/monitoring/argocd-app-velero.yaml")
  depends_on = [kubectl_manifest.argocd_project]
}
