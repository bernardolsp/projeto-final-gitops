module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "this" {
  for_each                                 = toset(["dev", "infra", "prod"])
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "20.13.0"
  cluster_name                             = "${each.key}-eks-lab"
  cluster_version                          = "1.29"
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access          = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    eks_nodes = {
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      instance_types = ["t3.medium", "t3a.medium"]
    }
  }

  cluster_addons = {
    coredns                = {},
    kube-proxy             = {},
    vpc-cni                = {},
    eks-pod-identity-agent = {},
  }

  tags = {
    Terraform   = "true"
    Environment = each.key
  }

}

resource "aws_secretsmanager_secret" "argocd_cluster_dev_secret" {
  name = "argocd_cluster2_dev_secret"
}

resource "aws_secretsmanager_secret" "argocd_cluster_prod_secret" {
  name = "argocd_cluster2_prod_secret"
}


resource "aws_secretsmanager_secret_version" "argocd_cluster_dev_secret_version" {
  secret_id = aws_secretsmanager_secret.argocd_cluster_dev_secret.id
  secret_string = jsonencode({
    config = {
      bearerToken = nonsensitive(data.kubernetes_secret.argocd_dev_secret_sa.data.token)
      tlsClientConfig = {
        caData   = base64encode(nonsensitive(data.kubernetes_secret.argocd_dev_secret_sa.data["ca.crt"]))
        insecure = false
      }}
      name   = module.this["dev"].cluster_name
      server = module.this["dev"].cluster_endpoint
    }
  )
}

resource "aws_secretsmanager_secret_version" "argocd_cluster_prod_secret_version" {
  secret_id = aws_secretsmanager_secret.argocd_cluster_prod_secret.id
  secret_string = jsonencode({
    config = {
      bearerToken = nonsensitive(data.kubernetes_secret.argocd_prod_secret_sa.data.token)
      tlsClientConfig = {
        caData   = base64encode(nonsensitive(data.kubernetes_secret.argocd_prod_secret_sa.data["ca.crt"]))
        insecure = false
      }}
      name   = module.this["prod"].cluster_name
      server = module.this["prod"].cluster_endpoint
  })
}