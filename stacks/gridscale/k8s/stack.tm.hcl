stack {
  name        = "gridscale-k8s"
  description = "GSK managed Kubernetes cluster (gridscale_k8s) with ONE minimal node pool. Consumes network_uuid from the network stack; exports kubeconfig for ArgoCD re-bootstrap (E1g-S05)."
  id          = "e1g-gridscale-k8s"
  tags        = ["gridscale", "day0", "k8s", "gsk"]

  after = ["/stacks/gridscale/network"]
}

globals {
  service     = "gsk"
  name_suffix = ""
  backend     = "s3"
}
