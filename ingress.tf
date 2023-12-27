# See https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/deploy/installation

################################################################################
# IAM Policy allowing Nodes access to AWS ALB and NLB
#
# See https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/install/iam_policy.json
# See https://github.com/terraform-aws-modules/terraform-aws-iam/blob/v5.33.0/modules/iam-role-for-service-accounts-eks/policies.tf
################################################################################
module "aws_alb_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${module.shared.eks_cluster_id}-aws-alb-${var.aws_region}"

  # Auto attach required IAM Policy
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.shared.eks_cluster_oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = var.default_resource_tags
}

################################################################################
# Helm Provider
################################################################################
provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = data.aws_eks_cluster.vendorcorp_eks_cluster.arn
  }
}

################################################################################
# Deploy aws-load-balancer-controller
################################################################################
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.2"
  namespace  = "kube-system"

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
    name  = "clusterName"
    value = var.default_eks_cluster_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_alb_irsa_role.iam_role_arn
  }

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}

################################################################################
# Create Token for Service Account (manual since k8s 1.24)
################################################################################
# resource "kubernetes_secret" "aws_alb_sa_token" {
#   metadata {
#     annotations = {
#       "kubernetes.io/service-account.name" = "aws-load-balancer-controller"
#     }
#     name      = "aws-load-balancer-controller-sa-token"
#     namespace = "kube-system"
#   }

#   type = "kubernetes.io/service-account-token"
# }
