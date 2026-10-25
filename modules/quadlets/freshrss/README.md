# FreshRSS and Fresher RSS

The combined container serves FreshRSS administration on port 8086 and the
Fresher frontend at `http://mediastation:8087/reader/`.

## One-time account setup

1. In FreshRSS (`http://mediastation:8086/`), enable **Administration →
   Authentication → Allow API access**.
2. Under **Profile → API management**, set an **API password** and use it to
   sign into Fresher RSS.
3. Under **Profile**, set and save the **Master authentication token** used
   for article refresh. This deployment uses the same value as the API password
   so the existing SOPS map can supply both refresh and caching credentials.
4. Run `just secrets_edit`. Set `freshrss_refresh_tokens` to a **single-line
   JSON string** mapping FreshRSS usernames to those shared credentials:

   ```yaml
   freshrss_refresh_tokens: '{"dirk":"your-shared-api-password-and-master-token"}'
   ```

   The Quadlet supplies this existing map as both `FRESHRSS_REFRESH_TOKENS` and
   `FRESHRSS_API_PASSWORDS`; no additional secret is needed. Multiple users can
   be included, provided each user's API password and master token match.
5. Deploy the configuration on mediastation. SOPS renders a root-only (0400)
   environment file and restarts `podman-freshrss.service` when it changes.

The Quadlet supplies the rendered file directly to Podman. No custom loader,
host PHP runtime, or Python runtime is required. Tokens and API passwords stay
server-side and are stored encrypted in Git, never as plaintext in the Nix store.
FreshRSS user settings are not read or modified by the host configuration.

When rotating credentials, update both the API password and master token in
FreshRSS Profile and the existing `freshrss_refresh_tokens` SOPS entry, then
deploy the changed secrets. Also update `panda-reader/secret` for the same account.
The scheduled refresh runs every 15 minutes (at minutes 0, 15, 30, and 45).

## Unread content and image caching

The Quadlet explicitly enables `IMAGE_UNREAD_CACHE_ENABLED` and
`CONTENT_UNREAD_CACHE_ENABLED`. With the API-password map configured, the
server prefetches unread thumbnails and readable article contents at startup
and reconciles both caches every five minutes, independently of open browsers.
The existing `latest` image and `Pull=always` policy fetch upstream updates
when the container starts; the image must include commit `2fc2f1b` or later.

Caches are in memory only, so no additional volumes are needed. Upstream defaults
limit thumbnails and readable contents to 64 MiB each and 512 entries each,
with a 2 MiB limit per thumbnail. Articles leave the caches once no configured
user has them unread. Cache misses retain the existing on-demand behavior.
Background prefetching contacts publishers even when no browser is connected;
FreshRSS credentials are sent only to the local FreshRSS instance.

## Verification

After deployment, sign into Fresher RSS and trigger an article refresh. If it
fails, inspect `sudo journalctl -u podman-freshrss.service -b` and check that the
SOPS map contains the correct username and current master token.

For caching, leave an article unread, allow the startup prefetch or next
five-minute sync to complete, then open it in Fresher RSS. Cached contents and
covers should load without another publisher fetch. If they do not, inspect
the same service logs for FreshRSS authentication or publisher-fetch errors
and verify `freshrss_refresh_tokens` contains the current API password as well
as a matching master token.
