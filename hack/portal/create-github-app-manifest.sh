#!/usr/bin/env bash
# DEPRECATED for GSK portal.lab login.
#
# The App Manifest flow used http://127.0.0.1:PORT/callback ONLY to capture the
# one-time create code. That URL must NEVER be the GitHub OAuth Authorization
# callback for Backstage on GSK.
#
# GSK values (only these):
#   Homepage:  https://portal.lab.platformrelay.dev
#   Callback:  https://portal.lab.platformrelay.dev/api/auth/github/handler/frame
#
# Use instead:
#   bash hack/portal/wire-github-oauth-secret.sh
#
# And create/fix the app at:
#   https://github.com/organizations/PlatformRelay/settings/applications/new
# or (if you already created a GitHub App via Manifest) set its
# "User authorization callback URL" to the Callback above under
#   https://github.com/organizations/PlatformRelay/settings/apps
set -euo pipefail
echo "DEPRECATED: do not use this script for GSK portal.lab OAuth." >&2
echo "  GSK callback MUST be https://portal.lab.platformrelay.dev/api/auth/github/handler/frame" >&2
echo "  (never http://127.0.0.1:8765/callback)" >&2
echo "Run: bash hack/portal/wire-github-oauth-secret.sh" >&2
exit 2
