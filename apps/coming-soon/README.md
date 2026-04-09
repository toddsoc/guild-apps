# O'Connell Coming Soon Site

This app serves a single static "Coming Soon" page for `www.oconnell.network`.

## Files

- `site/index.html`: page markup
- `site/styles.css`: styling
- `site/assets/crest.png`: your crest image (add this file)

## Local preview

```bash
docker compose -p oconnell -f compose/compose.yml --profile oconnell up -d --build coming-soon
```

Then open:

```text
http://localhost:8081
```

If `site/assets/crest.png` is missing, the page shows an `OC` fallback badge.

## Cloudflare publish

### Quick start

1. In Zero Trust tunnel `oconnell-home`, publish:
- Hostname: `oconnell.network`
- Service: `http://coming-soon:80`

2. If the service URL field rejects this value, use:
```text
Type: HTTP
URL field value: coming-soon:80
```

3. In DNS, keep:
- `CNAME` `oconnell.network` -> `www.oconnell.network` (Proxied)
- `CNAME` `www` -> `7b83675f-5ec0-4776-a50a-e180a85115fd.cfargotunnel.com` (Proxied)

### Troubleshooting

- `An A, AAAA, or CNAME record with that host already exists`:
Delete conflicting DNS record(s) for the hostname, then create the route again.
- `404 page not found` at `www`:
`www.oconnell.network` is missing from published routes.
