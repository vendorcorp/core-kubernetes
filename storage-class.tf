# See https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html

################################################################################
# IAM Policy
################################################################################
resource "aws_iam_policy" "efs" {
  name   = "${module.shared.eks_cluster_id}-EKS-CFS-CSI-Driver-Policy"
  policy = data.aws_iam_policy_document.efs.json

  tags = var.default_resource_tags
}

data "aws_iam_policy_document" "efs" {
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      values   = [true]
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      values   = [true]
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
    }
  }
}

################################################################################
# IAM Role
################################################################################
data "aws_iam_policy_document" "efs_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      identifiers = "arn:aws:iam::111122223333:oidc-provider/oidc.eks.${aws_region}.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "efs" {
  name               = "${module.shared.eks_cluster_id}-EKS-CFS-CSI-Driver-Role"
  assume_role_policy = data.aws_iam_policy_document.efs_trust_policy.json
}

################################################################################
# k8s Service Account
################################################################################
resource "kubernetes_service_account" "efs" {
  metadata {
    name      = "efs-csi-controller-sa"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "aws-efs-csi-driver"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::111122223333:role/AmazonEKS_EFS_CSI_DriverRole"
    }
  }
}

################################################################################
# Helm Provider
################################################################################
provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = module.shared.eks_cluster_arn
  }
}

################################################################################
# Deploy AWS EFS CSI Driver using Helm
################################################################################
resource "helm_release" "efs_driver" {
  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  version    = "1.3.6"
  namespace  = "kube-system"

  # See https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/charts/aws-efs-csi-driver/values.yaml
  set {
    name  = "controller.serviceAccount.create"
    value = false
  }
  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }
}
