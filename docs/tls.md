# TLS

- Traefik obtains certificates via Let's Encrypt DNS-01 using Cloudflare API token.
- ACME storage lives under `/lib/traefik/acme.json` (create with 600 perms).

Notes:
- Do NOT expose Traefik dashboard to the internet.
