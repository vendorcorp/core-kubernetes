# # See https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html

# ################################################################################
# # IAM Policy allowing Nodes access to AWS EFS
# ################################################################################
module "efs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${module.shared.eks_cluster_id}-efs-${var.aws_region}"

  # Auto attach required EFS IAM Policy
  attach_efs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.shared.eks_cluster_oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = var.default_resource_tags
}

# ################################################################################
# # Deploy aws-efs-csi-controller
# ################################################################################
resource "helm_release" "aws_efs_csi_driver" {
  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  version    = "2.5.2"
  namespace  = "kube-system"

  set {
    name = "controller.nodeSelector.instancegroup"
    value = "vendorcorp-core"
  }

  set {
    name = "controller.tolerations[0].key"
    value = "dedicated"
  }

  set {
    name = "controller.tolerations[0].value"
    value = "vendorcorp-core"
  }

  set {
    name = "controller.tolerations[0].operator"
    value = "Equal"
  }

  set {
    name = "controller.tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.efs_csi_irsa_role.iam_role_arn
  }

  set {
    name = "node.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.efs_csi_irsa_role.iam_role_arn
  }
}

# ################################################################################
# # Create Token for Service Account (manual since k8s 1.24)
# ################################################################################
# resource "kubernetes_secret" "efs_csi_sa_token" {
#   metadata {
#     annotations = {
#       "kubernetes.io/service-account.name" = "efs-csi-controller-sa"
#     }
#     name      = "efs-csi-controller-sa-token"
#     namespace = "kube-system"
#   }

#   type = "kubernetes.io/service-account-token"
# }

# ################################################################################
# # KMS Key for EFS encryption
# ################################################################################
resource "aws_kms_key" "efs_kms_key" {
  description             = "EFS Secret Encryption Key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = var.default_resource_tags
}

# ################################################################################
# # Create EFS Filesystem
# ################################################################################
resource "aws_efs_file_system" "vendorcorp_eks_efs" {
  creation_token = "${module.shared.eks_cluster_id}-efs"

  encrypted        = true
  kms_key_id       = aws_kms_key.efs_kms_key.arn
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = merge(tomap({ Name = "Vendor Corp EFS for ${module.shared.eks_cluster_id}" }), var.default_resource_tags)
}

# ################################################################################
# Create Security Group to allow EFS access from EKS Nodes
# ################################################################################
resource "aws_security_group" "eks_node_efs_mount_access" {
  name        = "${module.shared.eks_cluster_id}-efs-mount-sg"
  description = "Allow nodes in ${module.shared.eks_cluster_id} Cluster to mount EFS via NFS"
  vpc_id      = module.shared.vpc_id
  
  ingress {
    cidr_blocks = module.shared.private_subnet_cidrs
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
  }
}

# ################################################################################
# Expose EFS Filesystem on our EKS Subnets
# ################################################################################
resource "aws_efs_mount_target" "efs_mount_targets" {
  for_each        = module.shared.private_subnet_ids_az_map
  file_system_id  = aws_efs_file_system.vendorcorp_eks_efs.id
  security_groups = [aws_security_group.eks_node_efs_mount_access.id]
  subnet_id       = each.value
}

# ################################################################################
# k8s Storage Class to use our EFS Filesystem
# ################################################################################
resource "kubernetes_storage_class" "storage_class_efs" {
  metadata {
    name = "efs-fs"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "efs.csi.aws.com"
  # mount_options       = ["tls"]
  parameters = {
    basePath         = "/dynamic-efs-fs"
    directoryPerms   = "700"
    fileSystemId     = aws_efs_file_system.vendorcorp_eks_efs.id
    gidRangeStart    = "1000"
    gidRangeEnd      = "2000"
    provisioningMode = "efs-ap"
  }
}