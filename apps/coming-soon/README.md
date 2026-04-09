# O'Connell Coming Soon Site

This app serves a single static "Coming Soon" page for `www.oconnell.network`.

## Files

- `site/index.html`: page markup
- `site/styles.css`: styling
- `site/assets/shield.png`: shield image used on the page

## Local preview

```bash
docker compose -p oconnell -f compose/compose.yml --profile oconnell up -d --build coming-soon
```

Then open:

```text
http://localhost:8081
```

If `site/assets/shield.png` is missing, the page shows an `OC` fallback badge.

The page includes a collapsed `Image attribution` control linking to Wikimedia Commons and the CC BY-SA 4.0 license.

## Cloudflare publish

### Quick start

1. Create the token secret file:

```bash
cp compose/secrets/cloudflared_token.txt.example compose/secrets/cloudflared_token.txt
chmod 600 compose/secrets/cloudflared_token.txt
```

2. Start local services:

```bash
docker compose -p oconnell -f compose/compose.yml --profile oconnell up -d coming-soon cloudflared
```

3. In Zero Trust tunnel `oconnell-home`, publish:
- Hostname: `www.oconnell.network`
- Service: `http://coming-soon:80`

4. If the service URL field rejects this value, use:
```text
Type: HTTP
URL field value: coming-soon:80
```

5. In DNS, keep:
- `CNAME` `oconnell.network` -> `www.oconnell.network` (Proxied)
- `CNAME` `www` -> `7b83675f-5ec0-4776-a50a-e180a85115fd.cfargotunnel.com` (Proxied)

### Troubleshooting

- `An A, AAAA, or CNAME record with that host already exists`:
Delete conflicting DNS record(s) for the hostname, then create the route again.
- `404 page not found` at `www`:
`www.oconnell.network` is missing from published routes.
