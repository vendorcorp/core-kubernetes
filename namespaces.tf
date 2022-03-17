resource "kubernetes_namespace" "namespace_shared_core" {
  metadata {
    # annotations = {
    #   name = "example-annotation"
    # }

    # labels = {
    #   mylabel = "label-value"
    # }

    name = "shared-core"
  }
}
