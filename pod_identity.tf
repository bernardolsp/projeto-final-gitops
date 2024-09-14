############## External Secrets ###############
module "external_secrets_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "external-secrets"

  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = ["arn:aws:secretsmanager:*:*:secret:*"]
  external_secrets_kms_key_arns         = ["arn:aws:kms:*:*:key/*"]
  external_secrets_create_permission    = true

  tags = {
    Environment = "Infra"
  }
}

resource "aws_eks_pod_identity_association" "infra" {
  cluster_name    = module.this["infra"].cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = module.external_secrets_pod_identity.iam_role_arn
}

############## Crossplane ###############

module "iam_eks_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "crossplane"

  assume_role_condition_test = "StringLike"
  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  oidc_providers = {
    infra = {
      provider_arn               = module.this["infra"].oidc_provider_arn
      namespace_service_accounts = ["crossplane:*"]
    }
    dev = {
      provider_arn               = module.this["dev"].oidc_provider_arn
      namespace_service_accounts = ["crossplane:*"]
    }
    prod = {
      provider_arn               = module.this["prod"].oidc_provider_arn
      namespace_service_accounts = ["crossplane:*"]
    }
  }
}

#### app

module "app_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "app"

  assume_role_condition_test = "StringLike"
  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }

  oidc_providers = {
    infra = {
      provider_arn               = module.this["infra"].oidc_provider_arn
      namespace_service_accounts = ["python-s3-api:*"]
    }
    dev = {
      provider_arn               = module.this["dev"].oidc_provider_arn
      namespace_service_accounts = ["python-s3-api:*"]
    }
    prod = {
      provider_arn               = module.this["prod"].oidc_provider_arn
      namespace_service_accounts = ["python-s3-api:*"]
    }
  }
}