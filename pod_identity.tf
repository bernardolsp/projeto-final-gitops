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

module "pod_identity_s3" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "crossplane-s3"

  attach_custom_policy      = true

  policy_statements = [
    {
      sid       = "S3CrossplaneAccess"
      actions   = ["s3:List*", "s3:Get*", "s3:Put*", "s3:Delete*", "s3:Create*"]
      resources = ["*"]
    }
  ]

  additional_policy_arns = {
    AmazonS3FullAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }

  tags = {
    Environment = "dev"
  }
}

resource "aws_eks_pod_identity_association" "crossplane-s3" {
  cluster_name    = module.this["infra"].cluster_name
  namespace       = "crossplane-system"
  service_account = "crossplane-s3"
  role_arn        = module.pod_identity_s3.iam_role_arn
}
