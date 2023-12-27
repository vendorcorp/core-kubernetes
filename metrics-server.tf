# See https://github.com/kubernetes-sigs/metrics-server

################################################################################
# Deploy metrics-server
#
# See https://artifacthub.io/packages/helm/metrics-server/metrics-server
################################################################################
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.11.0"
  namespace  = "kube-system"
}