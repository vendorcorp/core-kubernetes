################################################################################
# Helm Provider
################################################################################
provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = data.aws_eks_cluster.vendorcorp_eks_cluster.arn
  }

  registry {
    url         = "oci://ghcr.io"
    username    = var.ghrc_io_username
    password    = var.ghrc_io_password
  }
}

################################################################################
# Kubernetes Provider
################################################################################
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = data.aws_eks_cluster.vendorcorp_eks_cluster.arn
}