stack {
  name        = "gridscale-object-storage"
  description = "State backend anchor: object-storage bucket + access key. Bootstrapped with LOCAL state (the one cheap persistent anchor, DECIDED-B); all other stacks use this bucket as their S3-compatible remote backend."
  id          = "e1g-gridscale-object-storage"
  tags        = ["gridscale", "day0", "bootstrap", "state"]
}

globals {
  service     = "tfstate"
  name_suffix = ""
  # Bootstrap anchor keeps LOCAL state — there is no backend to point at yet.
  backend = "local"
}
