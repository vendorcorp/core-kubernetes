# We purposefully use the Sonatype shared library here so we don't cyclically depend on the Vendor Corp EKS Cluster
# existing!
module "shared" {
  source      = "git::ssh://git@github.com/vendorcorp/terraform-shared-infrastructure.git?ref=v0.3.1"
  environment = var.environment
}

data "aws_eks_cluster" "vendorcorp_eks_cluster" {
  name = var.default_eks_cluster_name
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = data.aws_eks_cluster.vendorcorp_eks_cluster.arn
}
