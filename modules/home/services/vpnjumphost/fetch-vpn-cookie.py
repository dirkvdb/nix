#!/usr/bin/env python3
"""
Fetch the F5 MRHSession VPN cookie from byod.vito.be via interactive browser login.

Flow:
  1. Open Firefox and navigate to byod.vito.be.
  2. Wait for the user to complete SSO / Microsoft Authenticator MFA.
     (Detected by F5 redirecting the browser to /vdesk/ after authentication.)
  3. Capture the MRHSession cookie and close the browser.

The final cookie value is printed to stdout; all status messages go to stderr.
When --output is given, the cookie is also written to the specified file
(mode 600, parent directories created automatically).

Exit codes:
  0  Cookie obtained and printed to stdout.
  1  Timed out or error (message printed to stderr).
  2  playwright not installed (installation hint printed to stderr).

Usage:
  python3 fetch-vpn-cookie.py
  python3 fetch-vpn-cookie.py --output ~/.local/state/vito-vpn-jumphost/cookie
  cookie=$(python3 fetch-vpn-cookie.py)
"""

import argparse
import os
import sys
import time
import urllib.error
import urllib.request

XDG_STATE_HOME = os.getenv("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
PROFILE_DIR = os.getenv(
    "VPN_BROWSER_PROFILE_DIR",
    os.path.join(XDG_STATE_HOME, "vito-vpn-jumphost", "playwright-profile"),
)

VPN_URL = "https://byod.vito.be"
COOKIE_NAME = "MRHSession"
# How long to wait for SSO to complete (seconds).
MAX_WAIT_SECONDS = 300


class LoginState:
    def __init__(self) -> None:
        self.account_selected = False
        self.username_submitted = False
        self.password_submitted = False


def _playwright_installed() -> bool:
    try:
        import playwright  # noqa: F401

        return True
    except ImportError:
        return False


def _get_cookie(context) -> str | None:
    for cookie in context.cookies():
        if cookie["name"] == COOKIE_NAME and cookie["value"]:
            return cookie["value"]
    return None


def _cookie_is_accepted_by_vpn(cookie_value: str) -> bool:
    probe_url = f"{VPN_URL}/vdesk/vpn/index.php3?outform=xml"
    req = urllib.request.Request(
        probe_url,
        headers={
            "Cookie": f"{COOKIE_NAME}={cookie_value}",
            "User-Agent": "vito-vpn-jumphost-cookie-check",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status != 404
    except urllib.error.HTTPError as exc:
        return exc.code != 404
    except Exception:
        # Network flake/temporary issue: do not reject the cookie solely on this.
        return True


def _try_microsoft_login_steps(
    page, username: str | None, password: str | None, state: LoginState
) -> None:
    from playwright.sync_api import Error as PlaywrightError

    def _submit_password_form() -> None:
        # Microsoft pages vary heavily across tenants/locales.
        submit_candidates = [
            page.locator("#idSIButton9").first,
            page.locator("input[type='submit']").first,
            page.locator("button[type='submit']").first,
            page.get_by_role("button", name="Sign in").first,
            page.get_by_role("button", name="Next").first,
        ]
        for candidate in submit_candidates:
            try:
                if candidate.is_visible(timeout=300):
                    candidate.click()
                    print("Submitted password form.", file=sys.stderr)
                    state.password_submitted = True
                    return
            except PlaywrightError:
                continue
        try:
            page.locator("#i0118").press("Enter")
            print("Submitted password form via Enter.", file=sys.stderr)
            state.password_submitted = True
        except PlaywrightError:
            pass

    if username:
        # If an account picker is shown, select the first matching account.
        if not state.account_selected:
            account_candidates = [
                page.get_by_role("button", name=username).first,
                page.locator(f"div[role='button']:has-text('{username}')").first,
                page.locator(f"button:has-text('{username}')").first,
                page.get_by_text(username).first,
            ]
            for account in account_candidates:
                try:
                    if account.is_visible(timeout=300):
                        account.click()
                        state.account_selected = True
                        print(f"Selected existing account: {username}", file=sys.stderr)
                        break
                except PlaywrightError:
                    continue

        # Fresh sign-in screen: username/email form.
        # If we already selected an existing account tile, the next expected
        # step is password entry, so skip username filling.
        if not state.account_selected and not state.username_submitted:
            try:
                user_field = page.locator("#i0116").first
                if user_field.is_visible(timeout=300):
                    user_field.fill(username)
                    print("Filled username field.", file=sys.stderr)
                    submit_candidates = [
                        page.locator("#idSIButton9").first,
                        page.locator("input[type='submit']").first,
                        page.locator("button[type='submit']").first,
                        page.get_by_role("button", name="Next").first,
                    ]
                    for candidate in submit_candidates:
                        try:
                            if candidate.is_visible(timeout=300):
                                candidate.click()
                                state.username_submitted = True
                                print("Submitted username form.", file=sys.stderr)
                                break
                        except PlaywrightError:
                            continue
            except PlaywrightError:
                pass

    if password:
        # Second form after account selection/username step.
        try:
            password_field = page.locator("#i0118")
            if password_field.is_visible(timeout=300) and not state.password_submitted:
                # Always overwrite anything prefilled/stale before submit.
                password_field.fill("")
                password_field.fill(password)
                print("Filled password field.", file=sys.stderr)
                _submit_password_form()
        except PlaywrightError:
            pass

        # If Microsoft reports a bad password, retype and resubmit once more.
        try:
            wrong_password_text = page.get_by_text(
                "The password is incorrect. Please try again."
            )
            if wrong_password_text.is_visible(timeout=250):
                password_field = page.locator("#i0118")
                if password_field.is_visible(timeout=300):
                    password_field.fill("")
                    password_field.fill(password)
                    print(
                        "Retrying password after incorrect-password message.",
                        file=sys.stderr,
                    )
                    state.password_submitted = False
                    _submit_password_form()
        except PlaywrightError:
            pass


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Fetch the F5 MRHSession VPN cookie via browser login.",
    )
    parser.add_argument(
        "-o",
        "--output",
        metavar="FILE",
        default=None,
        help="Write the cookie to FILE (mode 600, parent dirs created). "
        "The cookie is still printed to stdout.",
    )
    parser.add_argument(
        "--username-file",
        metavar="FILE",
        default=None,
        help="Read the VPN username from FILE instead of the VPN_USERNAME env var.",
    )
    parser.add_argument(
        "--password-file",
        metavar="FILE",
        default=None,
        help="Read the VPN password from FILE instead of the VPN_PASSWORD env var.",
    )
    args = parser.parse_args()
    output_path: str | None = args.output

    username: str | None
    password: str | None
    if args.username_file:
        with open(args.username_file) as fh:
            username = fh.read().strip() or None
    else:
        username = os.getenv("VPN_USERNAME")
    if args.password_file:
        with open(args.password_file) as fh:
            password = fh.read().strip() or None
    else:
        password = os.getenv("VPN_PASSWORD")

    if not _playwright_installed():
        print(
            "error: playwright is not installed.\n"
            "Install it with:\n"
            "  pipx install playwright\n"
            "  python -m playwright install firefox",
            file=sys.stderr,
        )
        sys.exit(2)

    from playwright.sync_api import Error as PlaywrightError
    from playwright.sync_api import sync_playwright

    print(
        f"Opening {VPN_URL} in a browser window.\n"
        "Step 1: Log in with your VITO credentials and complete the Microsoft Authenticator prompt.\n"
        f"Using persistent browser profile: {PROFILE_DIR}\n",
        file=sys.stderr,
    )

    cookie_value: str | None = None

    with sync_playwright() as p:
        context = p.firefox.launch_persistent_context(
            user_data_dir=PROFILE_DIR,
            headless=False,
            viewport={"width": 1280, "height": 900},
        )
        page = context.pages[0] if context.pages else context.new_page()

        try:
            page.goto(VPN_URL, wait_until="domcontentloaded", timeout=30_000)
        except PlaywrightError:
            pass

        # Wait for the authenticated cookie to appear. This is more resilient than
        # waiting for a specific URL and allows session reuse from persistent state.
        print(
            "Waiting for Microsoft SSO / MFA to complete (or reusing existing session)...",
            file=sys.stderr,
        )

        login_state = LoginState()
        _try_microsoft_login_steps(page, username, password, login_state)

        deadline = time.time() + MAX_WAIT_SECONDS
        warned_invalid_cookie = False
        while time.time() < deadline and not cookie_value:
            candidate_cookie = _get_cookie(context)
            if candidate_cookie:
                if _cookie_is_accepted_by_vpn(candidate_cookie):
                    cookie_value = candidate_cookie
                    break
                if not warned_invalid_cookie:
                    print(
                        f"Found {COOKIE_NAME}, but VPN endpoint rejected it; waiting for fresh login...",
                        file=sys.stderr,
                    )
                    warned_invalid_cookie = True
            try:
                active_page = context.pages[-1] if context.pages else page
                _try_microsoft_login_steps(active_page, username, password, login_state)
            except PlaywrightError:
                pass
            time.sleep(1)

        if not cookie_value:
            print(
                f"error: could not find {COOKIE_NAME} within {MAX_WAIT_SECONDS}s. "
                "Session may require a fresh login.",
                file=sys.stderr,
            )
            try:
                context.close()
            except PlaywrightError:
                pass
            sys.exit(1)

        try:
            context.close()
        except PlaywrightError:
            pass

    if not cookie_value:
        print(
            f"error: could not obtain a VPN-level {COOKIE_NAME!r} cookie.",
            file=sys.stderr,
        )
        sys.exit(1)

    sys.stdout.write(cookie_value)
    sys.stdout.flush()

    if output_path:
        os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
        old_umask = os.umask(0o077)
        try:
            with open(output_path, "w") as f:
                f.write(cookie_value)
            os.chmod(output_path, 0o600)
        finally:
            os.umask(old_umask)
        print(f"\nCookie saved to {output_path}", file=sys.stderr)
    else:
        print("\nCookie captured.", file=sys.stderr)


if __name__ == "__main__":
    main()
