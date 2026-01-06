# DNS

Internal split DNS recommendation:
- `*.home.mstorm.net` -> Traefik (VM IP)
- `home.mstorm.net`   -> Traefik (VM IP)
- (optional) `aitne.mstorm.net` internal -> Traefik (VM IP) to unify TLS

External Cloudflare Tunnel exposure (manual allow-list):
- id.mstorm.net
- vault.mstorm.net
- ztna.mstorm.net
- aitne.mstorm.net
