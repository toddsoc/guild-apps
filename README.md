# Multi-App Nginx Workspace

This repository is now organized to host multiple small apps behind one shared nginx gateway. Each app lives in its own subdirectory under `apps/`, while shared deployment assets live under `infra/`, `compose/`, and `scripts/`.

Copyright (c) 2026 The Smart Guild LLC. Licensed under the MIT License. See [`LICENSE`](/home/toddsoc/projects/guild-apps/LICENSE).

## Layout

- `apps/`: self-contained applications
- `apps/regex/`: the current regex search app
- `compose/compose.yml`: shared Docker Compose entrypoint
- `infra/nginx/`: shared nginx routing and site examples
- `infra/systemd/`: service examples for non-Docker deployment
- `scripts/`: shared operational helpers such as Tailscale setup

## Current apps

- [`apps/regex/README.md`](/home/toddsoc/projects/guild-apps/apps/regex/README.md): Flask regex search app served at `/RegEx/`
- [`apps/coming-soon/README.md`](/home/toddsoc/projects/guild-apps/apps/coming-soon/README.md): static site for `www.oconnell.network`

## Shared Docker workflow

Start the shared gateway and the regex app with:

```bash
docker compose -f compose/compose.yml up -d --build
```

Then open:

```text
http://localhost:8080/RegEx/
```

You can also use the top-level helper script for app lifecycle actions:

```bash
./apps.sh list
./apps.sh status all
./apps.sh start regex
./apps.sh stop oconnell
./apps.sh rebuild all
```

## Tailscale HTTPS access

Once the Docker stack is up, publish the shared nginx endpoint with:

```bash
./scripts/tailscale_serve.sh
```

The expected app URL on this VM is:

```text
https://todd-ubuntu-docker.nuthatch-ruler.ts.net/RegEx/
```

## O'Connell domain setup (Cloudflare Tunnel)

### Quick start

1. Add your crest image:

```text
apps/coming-soon/site/assets/crest.png
```

2. Create a tunnel token file and set your token:

```bash
cp compose/.env.oconnell.example compose/.env.oconnell
```

3. Start the coming-soon stack:

```bash
docker compose -p oconnell --env-file compose/.env.oconnell -f compose/compose.yml --profile oconnell up -d --build coming-soon cloudflared
```

4. In Cloudflare Zero Trust (`oconnell-home` tunnel), add published application route:
- `oconnell.network` -> `http://coming-soon:80`

5. In Cloudflare DNS, set:
- `CNAME` `oconnell.network` -> `www.oconnell.network` (Proxied)
- `CNAME` `www` -> `7b83675f-5ec0-4776-a50a-e180a85115fd.cfargotunnel.com` (Proxied)
- Keep only one `www` record

6. Add redirect rule for apex to `www`:
- Rule expression:
```text
(http.host eq "oconnell.network")
```
- Dynamic target URL expression:
```text
concat("https://www.oconnell.network", http.request.uri.path)
```
- Preserve query string: on
- Status code: `301`

7. Verify:

```bash
curl -I https://oconnell.network
curl -I https://www.oconnell.network
docker compose -p oconnell --env-file compose/.env.oconnell -f compose/compose.yml --profile oconnell logs --no-color --tail=80 cloudflared
```

Expected:
- `oconnell.network` returns `301` to `https://www.oconnell.network/...`
- `www.oconnell.network` returns `200` (or `304`)

### Troubleshooting

- `An A, AAAA, or CNAME record with that host already exists`:
Delete conflicting DNS records for that hostname, then create the tunnel route again.
- `404` at `www`:
Published route is missing `www.oconnell.network` and only apex is configured.
- `Could not resolve host`:
Local resolver cache may be stale even if authoritative Cloudflare DNS is correct.

## Security

Security hardening notes and verification commands are documented in
[`SECURITY.md`](/home/toddsoc/projects/guild-apps/SECURITY.md).

## Adding another app

1. Create a new directory under `apps/<name>/`.
2. Add the app's container build and dependencies there.
3. Add an nginx path-routing file under `infra/nginx/conf.d/`.
4. Add a service to [`compose/compose.yml`](/home/toddsoc/projects/guild-apps/compose/compose.yml).
5. Mount the app at a stable path such as `/$AppName/`.

Current example deployment files for the regex app:

- [`infra/nginx/sites-available/regex-app.conf.example`](/home/toddsoc/projects/guild-apps/infra/nginx/sites-available/regex-app.conf.example)
- [`infra/systemd/regex-app.service.example`](/home/toddsoc/projects/guild-apps/infra/systemd/regex-app.service.example)

## License

This project is licensed under the MIT License and owned by The Smart Guild LLC.

Maintainer reference for source files: Todd O'Connell `<toddsoc@linux.com>`.
