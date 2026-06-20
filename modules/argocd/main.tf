resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = merge(var.tags, { "app.kubernetes.io/managed-by" = "terraform" })
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  set { name = "configs.params.server\\.insecure"; value = "true" }
  set { name = "server.service.type";              value = "ClusterIP" }

  timeout    = 600
  wait       = true
  depends_on = [kubernetes_namespace_v1.argocd]
}

resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.0"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  values = [file("${var.cd_apps_path}/kustomization.yaml")]

  depends_on = [helm_release.argocd]
}
