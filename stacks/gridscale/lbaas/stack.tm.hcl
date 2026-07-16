stack {
  name        = "gridscale-lbaas"
  description = "LBaaS entry point in front of the GSK Gateway. Listens on the public IPv4/IPv6 from the network stack; forwards 80/443 to the Gateway backend. Public IP feeds the Dex issuer URL / OAuth callback (E1g-S05)."
  id          = "e1g-gridscale-lbaas"
  tags        = ["gridscale", "day0", "lbaas", "ingress"]

  after = [
    "/stacks/gridscale/network",
    "/stacks/gridscale/k8s",
  ]
}

globals {
  service     = "lb"
  name_suffix = ""
  backend     = "s3"
}
