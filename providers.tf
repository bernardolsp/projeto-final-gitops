provider "aws" {
  region = "us-east-1"
}

data "aws_eks_cluster_auth" "this" {
  for_each = toset(["infra", "dev", "prod"])
  name     = module.this[each.key].cluster_name
}


provider "kubernetes" {
  host                   = module.this["infra"].cluster_endpoint
  cluster_ca_certificate = base64decode(module.this["infra"].cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this["infra"].token
}

provider "kubernetes" {
  alias                  = "k8sdev"
  host                   = module.this["dev"].cluster_endpoint
  cluster_ca_certificate = base64decode(module.this["dev"].cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this["dev"].token
}

provider "kubernetes" {
  alias                  = "k8sprod"
  host                   = module.this["prod"].cluster_endpoint
  cluster_ca_certificate = base64decode(module.this["prod"].cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this["prod"].token
}