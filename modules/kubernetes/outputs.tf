output "namespace" {
  value = kubernetes_namespace_v1.solidarytech.metadata[0].name
}
