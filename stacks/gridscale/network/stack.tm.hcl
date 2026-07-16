stack {
  name        = "gridscale-network"
  description = "Private network + firewall + public IPv4/IPv6 for the GSK cluster and LBaaS entry point. Feeds network_uuid → k8s and IP UUIDs → lbaas."
  id          = "e1g-gridscale-network"
  tags        = ["gridscale", "day0", "network"]

  # Consumes the state-backend bucket created by the object-storage anchor.
  after = ["/stacks/gridscale/object-storage"]
}

globals {
  service     = "network"
  name_suffix = ""
  backend     = "s3"
}
