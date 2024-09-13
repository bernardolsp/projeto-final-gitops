resource "helm_release" "argocd" {
  name       = "argo"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  create_namespace = true
  namespace  = "argo"
  version    = "7.5.0"

}


resource "kubectl_manifest" "applicationset" {
  yaml_body = file("${path.module}/manifests/applicationset.yaml")
  depends_on = [
    helm_release.argocd
  ]
}