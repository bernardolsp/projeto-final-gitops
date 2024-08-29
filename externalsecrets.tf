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

