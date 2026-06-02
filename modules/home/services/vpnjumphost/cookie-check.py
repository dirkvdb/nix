#!/usr/bin/env python3
"""Exit 0 when the MRHSession cookie in argv[1] is accepted by the VPN endpoint.

Critical: we must NOT follow HTTP redirects. A 302 from the F5 gateway means
the session cookie is expired and the server is redirecting to the SSO login
page. urllib follows redirects silently, which would make us see a 200 from
the login page and wrongly conclude the cookie is still valid — while
openconnect (which does NOT follow redirects) fails with 'Creating SSL
connection failed'.
"""

import sys
import urllib.error
import urllib.request


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    """Raise an HTTPError instead of following any redirect."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise urllib.error.HTTPError(req.full_url, code, msg, headers, fp)


if len(sys.argv) < 3:
    print("usage: cookie-check.py COOKIE_FILE VPN_URL", file=sys.stderr)
    sys.exit(2)

cookie_file, vpn_url = sys.argv[1], sys.argv[2]

try:
    with open(cookie_file) as fh:
        cookie = fh.read().strip()
    if not cookie:
        sys.exit(1)
    opener = urllib.request.build_opener(_NoRedirect)
    req = urllib.request.Request(
        f"{vpn_url}/vdesk/vpn/index.php3?outform=xml",
        headers={
            "Cookie": f"MRHSession={cookie}",
            "User-Agent": "vito-vpn-jumphost-cookie-check",
        },
    )
    with opener.open(req, timeout=10) as resp:
        sys.exit(0 if resp.status != 404 else 1)
except urllib.error.HTTPError as exc:
    # 3xx redirect → cookie is stale (server wants us to re-authenticate)
    if 300 <= exc.code < 400:
        print(
            f"cookie-check: got redirect ({exc.code}) — cookie expired", file=sys.stderr
        )
        sys.exit(1)
    sys.exit(0 if exc.code != 404 else 1)
except Exception as exc:
    print(f"cookie-check: probe error: {exc}", file=sys.stderr)
    sys.exit(1)
