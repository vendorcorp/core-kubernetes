# See https://grafana.github.io/grafana-operator/docs/installation/helm/

################################################################################
# Create Namespace
################################################################################
resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

################################################################################
# Deploy grafana using Helm
#
# See https://grafana.github.io/grafana-operator/docs/installation/helm/
################################################################################
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "oci://ghcr.io/grafana/helm-charts/grafana-operator"
  chart      = "grafana-operator"
  version    = "v5.6.0"
  namespace  = kubernetes_namespace.grafana.metadata[0].name

#   values = [
#     "${file("values/grafana.yaml")}"
#   ]

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
}
