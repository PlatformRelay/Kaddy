# E10 — portal sign-in gate + /login redirect (live proof)

**Captured:** 2026-07-21T20:39:07Z · **main:** 6894e56 · **image:** ghcr.io/platformrelay/kaddy-portal:sha-4ecaecc
(== kaddy-portal 0.2.1, digest sha256:c8e1ced54812354efbdfc58585ebda44505bba93476cdd7c85ab170ed2469778)

## Sign-in gate (root URL, unauthenticated headless Chromium)

Rendered body at https://portal.lab.platformrelay.dev/ :

    kaddy Portal
    GitHub
    Sign in with GitHub
    SIGN IN

Zero page errors. Pod backstage-bd4dfcc67 1/1 Running; Argo App backstage-workload Synced/Healthy
@ 752ec47. Root cause fixed upstream (kaddy-portal 03ab568: same-id sign-in-page:app override —
the prior named variant never attached and the app rendered UNGATED).

## /login redirect (REQ: habit-proofing; review F1 follow-up)

    $ curl -sSI https://portal.lab.platformrelay.dev/login
    HTTP/2 302
    location: https://portal.lab.platformrelay.dev/

    $ curl -sS -o /dev/null -w "%{http_code}" https://portal.lab.platformrelay.dev/
    200

HTTPRoute portal: Accepted=True, ResolvedRefs=True after gateway-cloud-edge synced 6894e56
(Traefik accepted RequestRedirect + ReplaceFullPath — the Accepted=False risk did not materialize).
