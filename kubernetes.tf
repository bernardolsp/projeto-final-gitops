# 1 ServiceAccount em cada environment de workload (dev, prod)
# 1 ClusterRoleBinding para cada uma das serviceaccounts geradas anteriormente
# 1 Token para cada uma das serviceaccounts

###################### SA ###################### 
resource "kubernetes_service_account" "dev" {
  provider = kubernetes.k8sdev
  metadata {
    name      = "argocd-dev-sa"
    namespace = "default"
  }
}

resource "kubernetes_service_account" "prod" {
  provider = kubernetes.k8sprod
  metadata {
    name      = "argocd-prod-sa"
    namespace = "default"
  }
}

###################### Cluster Role Binding ######################

resource "kubernetes_cluster_role_binding" "argocd-dev" {
  provider = kubernetes.k8sdev
  metadata {
    name = "argocd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.dev.metadata.0.name
    namespace = kubernetes_service_account.dev.metadata.0.namespace
  }
}

resource "kubernetes_cluster_role_binding" "argocd-prod" {
  provider = kubernetes.k8sprod
  metadata {
    name = "argocd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.prod.metadata.0.name
    namespace = kubernetes_service_account.prod.metadata.0.namespace
  }
}

############## Service Account Secrets ##############

resource "kubernetes_secret" "argocd-dev-secret-sa" {
  provider = kubernetes.k8sdev
  metadata {
    name      = "argocd-dev-secret-sa"
    namespace = "default"
    annotations = {
      "kubernetes.io/service-account.name" = "argocd-dev-sa"
    }
  }
  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

resource "kubernetes_secret" "argocd-prod-secret-sa" {
  provider = kubernetes.k8sprod
  metadata {
    name      = "argocd-prod-secret-sa"
    namespace = "default"
    annotations = {
      "kubernetes.io/service-account.name" = "argocd-prod-sa"
    }
  }
  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

############## Data Sources ############## 

data "kubernetes_secret" "argocd_dev_secret_sa" {
  provider = kubernetes.k8sdev
  metadata {
    name      = kubernetes_secret.argocd-dev-secret-sa.metadata.0.name
    namespace = kubernetes_secret.argocd-dev-secret-sa.metadata.0.namespace
  }
}
data "kubernetes_secret" "argocd_prod_secret_sa" {
  provider = kubernetes.k8sprod
  metadata {
    name      = kubernetes_secret.argocd-prod-secret-sa.metadata.0.name
    namespace = kubernetes_secret.argocd-prod-secret-sa.metadata.0.namespace
  }
}