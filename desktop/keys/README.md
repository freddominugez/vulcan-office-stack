# Vulcan Office release signing keys

## Active release key

- **User ID:** `Vulcan Office Releases (v9.3.1-vulcan.1 desktop signing key) <releases@vulcanoffice.com>`
- **Type:** Ed25519 signing, Cv25519 encryption subkey
- **Key ID (long):** `43CEDF20090D3550`
- **Fingerprint:** `13E3 C257 5E73 4C89 10D5  205A 43CE DF20 090D 3550`
- **Created:** 2026-07-05
- **Expires:** 2028-07-04
- **Passphrase:** none (batch-friendly for CI)

The public half is at [`releases-pubkey.asc`](./releases-pubkey.asc) in this
directory. Every Windows Release attached to a `v*-vulcan.*` tag ships the same
`releases-pubkey.asc` as one of its assets so verifiers do not have to trust
this repository to obtain the key.

## Verifying a downloaded installer

```bash
# One-time: import the release key
curl -O https://vulcanoffice.com/downloads/keys/releases-pubkey.asc
gpg --import releases-pubkey.asc

# Per download:
gpg --verify sha256sums.txt.asc sha256sums.txt
sha256sum -c sha256sums.txt
```

Expected `gpg --verify` output:

> Good signature from "Vulcan Office Releases (...) <releases@vulcanoffice.com>"

## Adding the private half to CI (one-time, by the repo owner)

1. On the machine where the key was generated, the private key was exported
   to `/tmp/vo-release-privkey.asc` (mode 0600). This file is NOT in git.
2. In `github.com/freddominugez/vulcan-office-stack` → **Settings → Secrets
   and variables → Actions → New repository secret**.
3. Name: `GPG_RELEASE_PRIVATE_KEY`. Value: the entire content of
   `/tmp/vo-release-privkey.asc`, including the
   `-----BEGIN PGP PRIVATE KEY BLOCK-----` and `-----END ...-----` lines.
4. After saving the secret, delete the local copy immediately:
   ```bash
   shred -u /tmp/vo-release-privkey.asc 2>/dev/null || rm -Pf /tmp/vo-release-privkey.asc
   ```
5. On future workstations, do NOT reimport this private key. If you need to
   sign locally, use a subkey delegated for that machine, or rotate.

## Key rotation

- Renewal every 24 months (before `Expires:` above). The renewal keeps the
  same fingerprint.
- Compromise: revoke immediately with the revocation certificate at
  `/tmp/vo-gpg/openpgp-revocs.d/13E3C2575E734C8910D5205A43CEDF20090D3550.rev`
  (was generated alongside the key). Distribute the revoked pubkey and
  generate a new key. Announce on
  `github.com/freddominugez/vulcan-office-stack` and
  `vulcanoffice.com/downloads/keys/`.

## Publishing the pubkey on vulcanoffice.com

Copy `releases-pubkey.asc` to the download server:

```bash
scp releases-pubkey.asc user@server:/srv/vulcanoffice/downloads/keys/
```

The Caddy `Caddyfile` in the repo root should already serve
`/downloads/keys/releases-pubkey.asc` under
`https://vulcanoffice.com/downloads/keys/releases-pubkey.asc`.
