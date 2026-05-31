#!/usr/bin/env python3
"""Exit 0 when the MRHSession cookie in argv[1] is accepted by the VPN endpoint."""
import sys, urllib.request, urllib.error

if len(sys.argv) < 3:
    print("usage: cookie-check.py COOKIE_FILE VPN_URL", file=sys.stderr)
    sys.exit(2)

cookie_file, vpn_url = sys.argv[1], sys.argv[2]

try:
    with open(cookie_file) as fh:
        cookie = fh.read().strip()
    if not cookie:
        sys.exit(1)
    req = urllib.request.Request(
        f"{vpn_url}/vdesk/vpn/index.php3?outform=xml",
        headers={
            "Cookie": f"MRHSession={cookie}",
            "User-Agent": "vito-vpn-jumphost-cookie-check",
        },
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        sys.exit(0 if resp.status != 404 else 1)
except urllib.error.HTTPError as exc:
    sys.exit(0 if exc.code != 404 else 1)
except Exception as exc:
    print(f"cookie-check: probe error: {exc}", file=sys.stderr)
    sys.exit(1)
