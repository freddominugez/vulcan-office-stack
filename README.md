# vulcan-office-stack

Corresponding source code (AGPL-3.0) for the Vulcan Office instance running at
**https://drive.vulcanoffice.com** (Nextcloud UI) and **https://office.vulcanoffice.com** (editor).

This repository publishes the local modifications applied on top of two AGPL-3.0
upstream projects. It exists to satisfy AGPL-3.0 §13 for users interacting with
the service over the network.

## Upstreams

| Component | Upstream | Version pinned here |
|---|---|---|
| DocumentServer (editor) | https://github.com/Euro-Office/DocumentServer | `9.3.1-dev.1` (image digest below) |
| Nextcloud connector | https://github.com/ONLYOFFICE/onlyoffice-nextcloud | `9.11.0` (rebranded as `vulcanoffice`) |
| Nextcloud core | https://github.com/nextcloud/server | `30.0.17` (unmodified upstream image) |

## What this repo contains (i.e. what we changed)

The DocumentServer image itself is pulled unmodified from
`ghcr.io/euro-office/documentserver`. Our modifications are:

1. **Runtime brand assets** in [`branding/`](./branding/) — logos, favicons,
   accent CSS — mounted read-only over the upstream paths at container start.
   Every mount is declared in [`docker-compose.yml`](./docker-compose.yml)
   under the `documentserver` service.
2. **Reverse-proxy config** in [`caddy/Caddyfile`](./caddy/Caddyfile).
3. **Nextcloud connector rebrand** — the deterministic rename patch that
   transforms `ONLYOFFICE/onlyoffice-nextcloud` into `vulcanoffice` lives in
   [`vulcanoffice-patch/apply-rebrand.sh`](./vulcanoffice-patch/apply-rebrand.sh).
4. **Upstream update watcher** — [`scripts/check-eurooffice-updates.sh`](./scripts/check-eurooffice-updates.sh)
   and the [`systemd/`](./systemd/) unit files that run it daily.

Nothing else in the upstream DocumentServer binary is altered — no patched
source, no rebuilt image.

## Layout

```
.
├── docker-compose.yml           # production compose (secrets via env)
├── branding/                    # SVG logos, favicons, CSS accent
│   ├── header-logo_s.svg(.gz)
│   ├── dark-logo_s.svg(.gz)
│   ├── about-logo_s.svg(.gz)
│   ├── about-logo-white_s.svg(.gz)
│   ├── embed-logo.svg(.gz)
│   ├── welcome-logo.svg(.gz)
│   ├── favicon.ico
│   ├── welcome-docker.html
│   └── css/
│       ├── documenteditor.app.css
│       ├── spreadsheeteditor.app.css
│       ├── presentationeditor.app.css
│       ├── pdfeditor.app.css
│       └── visioeditor.app.css
├── caddy/
│   └── Caddyfile                # TLS + reverse proxy
├── vulcanoffice-patch/
│   └── apply-rebrand.sh         # onlyoffice → vulcanoffice deterministic patch
├── scripts/
│   └── check-eurooffice-updates.sh
├── systemd/
│   ├── vulcan-eurooffice-check.service
│   ├── vulcan-eurooffice-check.timer
│   └── eurooffice-check.env.example   # SMTP creds for the update watcher
├── .env.example                 # compose runtime env vars
├── .gitignore
├── LICENSE                      # AGPL-3.0
├── NOTICE                       # attribution
└── README.md
```

## Deploy on a fresh host

Prereqs: Docker + Docker Compose plugin, DNS pointing `drive.vulcanoffice.com`
and `office.vulcanoffice.com` at the host.

```bash
git clone https://github.com/freddominugez/vulcan-office-stack
cd vulcan-office-stack
cp .env.example .env         # fill in every value
docker network create vo-frontnet 2>/dev/null || true
docker compose up -d
```

## Applying the connector rebrand from upstream

The `vulcanoffice` connector shipped on this instance is currently pinned at
upstream `9.11.0`. To rebase on a newer upstream release (e.g. `v10.1.2`,
the current latest at the time this README was written):

```bash
VER=v10.1.2
curl -L -o /tmp/oo.tar.gz \
  https://github.com/ONLYOFFICE/onlyoffice-nextcloud/archive/refs/tags/${VER}.tar.gz
tar xzf /tmp/oo.tar.gz -C /tmp
./vulcanoffice-patch/apply-rebrand.sh /tmp/onlyoffice-nextcloud-${VER#v}
```

Deploy by copying `/tmp/vulcanoffice/` to `/var/www/html/custom_apps/vulcanoffice/`
inside the Nextcloud container and running `occ upgrade`.

## Upstream watcher

`scripts/check-eurooffice-updates.sh` polls the two upstream release feeds
daily and emails when a new tag appears. It never updates automatically.

Install:

```bash
sudo install -m 0755 scripts/check-eurooffice-updates.sh \
    /usr/local/bin/check-eurooffice-updates.sh
sudo install -m 0644 systemd/vulcan-eurooffice-check.service \
    systemd/vulcan-eurooffice-check.timer /etc/systemd/system/
sudo mkdir -p /etc/vulcan
sudo install -m 0600 systemd/eurooffice-check.env.example \
    /etc/vulcan/eurooffice-check.env
sudoedit /etc/vulcan/eurooffice-check.env   # fill in SMTP creds
sudo systemctl daemon-reload
sudo systemctl enable --now vulcan-eurooffice-check.timer
```

## License

This repository is distributed under the **GNU Affero General Public License,
version 3.0** — see [LICENSE](./LICENSE). Third-party attributions in
[NOTICE](./NOTICE).
