# See https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/installation

# NOTE:
# The public subnets of the VPC need to have the tag 'kubernetes.io/role/elb=1' 
# and 'kubernetes.io/cluster/vendorcorp-us-east-2-63pl3dng=shared'

################################################################################
# IAM Policy allowing Nodes access to AWS to create load balancers
################################################################################
resource "aws_iam_policy" "alb_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "Policy that allows EKS Nodes to manage Load Balancers in AWS"
  policy      = file("aws-load-balancer-iam-policy.json")
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
  version    = "1.4.1"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.default_eks_cluster_name
  }
}

################################################################################
# Attach the IAM policy (above) to the Node Groups in our EKS Cluster
################################################################################
data "aws_eks_node_groups" "all" {
  cluster_name = var.default_eks_cluster_name
}

data "aws_eks_node_group" "all" {
  for_each = data.aws_eks_node_groups.all.names

  cluster_name    = var.default_eks_cluster_name
  node_group_name = each.value
}

resource "aws_iam_role_policy_attachment" "node_group_alb_attach" {
  for_each   = data.aws_eks_node_group.all
  role       = split("/", each.value.node_role_arn)[1]
  policy_arn = aws_iam_policy.alb_policy.arn
}
