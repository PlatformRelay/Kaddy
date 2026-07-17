# E13-S01 live proof — gridscale golden-image build (2026-07-17)

`packer build packer/caddy.pkr.hcl` against real gridscale (after the arg/ssh/template fixes).
Ephemeral build VM → provision Caddy → snapshot → template, then ALL ephemeral resources auto-destroyed.

## Build result (from /tmp/e13-caddy-build.log)
```
==> Created server 4c569265 (ephemeral build VM)
==> Enabled caddy.service (systemd) on the image
==> Created snapshot 459022a0 → template packer-1784247942 (76d0bb9f-92a5-41ab-852d-912f7d1988ba, private)
==> Destroyed: snapshot, IP 185.241.34.52, boot storage, SSH key, server 4c569265
Build 'kaddy-caddy.gridscale.caddy' finished after 3 minutes 32 seconds.
```

Proves E13-S01: the Packer golden-image pipeline builds a Caddy image on gridscale and snapshots it to a
private template. Template deleted after capture (cost discipline; rebuildable via packer/caddy.pkr.hcl).
Remaining E13 live (deferred, cost-gated): export → .gz to object storage, gridscale_marketplace_application
register + import (E13-S02), deploy-from-template + serve→scrape→fire (E13-S03).
