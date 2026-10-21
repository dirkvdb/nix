# FreshRSS and Fresher RSS

The combined container serves FreshRSS administration on port 8086 and the
Fresher frontend at `http://mediastation:8087/reader/`.

## One-time account setup

1. In FreshRSS (`http://mediastation:8086/`), enable **Administration →
   Authentication → Allow API access**.
2. Under **Profile → API management**, set an **API password** and use it to
   sign into Fresher RSS.
3. Under **Profile**, set and save a strong, random **Master authentication
   token**. This is separate from the API password and enables article refresh.
4. Run `just secrets_edit`. Set `freshrss_refresh_tokens` to a **single-line
   JSON string** mapping FreshRSS usernames to their master tokens:

   ```yaml
   freshrss_refresh_tokens: '{"dirk":"your-master-authentication-token"}'
   ```

   The encrypted entry starts as `'{}'`; manual refresh is unavailable until
   you add your token. Multiple users can be included in the same JSON map.
5. Deploy the configuration on mediastation. SOPS renders a root-only (0400)
   environment file and restarts `podman-freshrss.service` when it changes.

The Quadlet supplies the rendered file directly to Podman. No custom loader,
host PHP runtime, or Python runtime is required. Tokens stay server-side and
are stored encrypted in Git, never as plaintext in the Nix store. FreshRSS user
settings are not read or modified by the host configuration.

When rotating a token, update it in both FreshRSS Profile and the SOPS entry,
then deploy the changed secrets. The scheduled refresh at minutes 7 and 37 is
unchanged.

## Verification

After deployment, sign into Fresher RSS and trigger an article refresh. If it
fails, inspect `sudo journalctl -u podman-freshrss.service -b` and check that the
SOPS map contains the correct username and current master token.
