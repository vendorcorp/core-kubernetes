################################################################################
# Create internal DNS Zone for Vendor Corp
################################################################################
resource "aws_route53_zone" "vendorcorp_internal" {
  name    = "vendorcorp.internal"
  comment = "Vendor Corp internal DNS Zone"
  tags    = var.default_resource_tags

  vpc {
    vpc_id = module.shared.vpc_id
  }
}

################################################################################
# IAM Policy allowing Nodes access to AWS Route 53
#
# See https://github.com/terraform-aws-modules/terraform-aws-iam/blob/v5.33.0/modules/iam-role-for-service-accounts-eks/policies.tf#L429
# See https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
################################################################################
module "aws_r53_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${module.shared.eks_cluster_id}-aws-r53-${var.aws_region}"

  attach_external_dns_policy = true

  external_dns_hosted_zone_arns = [
    module.shared.dns_zone_public_arn,
    module.shared.dns_zone_internal_arn,
    module.shared_private.dns_zone_bma_arn
  ]

  oidc_providers = {
    main = {
      provider_arn               = module.shared.eks_cluster_oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = var.default_resource_tags
}

################################################################################
# Deploy external-dns
################################################################################
resource "helm_release" "external-dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.13.1"
  namespace  = "kube-system"

  set_list {
    name = "domainFilters"
    value = [
      "${module.shared.dns_zone_public_name}", 
      "${module.shared.dns_zone_internal_name}",
      "${module.shared_private.dns_zone_bma_name}"
    ]
  }

  set {
    name = "nodeSelector.instancegroup"
    value = "vendorcorp-core"
  }

  set {
    name = "tolerations[0].key"
    value = "dedicated"
  }

  set {
    name = "tolerations[0].value"
    value = "vendorcorp-core"
  }

  set {
    name = "tolerations[0].operator"
    value = "Equal"
  }

  set {
    name = "tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_r53_irsa_role.iam_role_arn
  }

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }
}