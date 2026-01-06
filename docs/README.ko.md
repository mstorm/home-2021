# 문서

## 설치 순서

### 1. 사전 요구사항 확인

다음 도구들이 설치되어 있어야 합니다:
- Docker
- Docker Compose (플러그인)

```bash
# Docker 및 Docker Compose 확인
docker --version
docker compose version
```

### 2. 디렉토리 구조 생성 및 초기 설정

`bootstrap` 명령을 실행하여 디렉토리 구조를 생성하고 초기 설정을 수행합니다:

```bash
./ops.sh bootstrap
```

이 명령은 다음을 수행합니다:
- 디렉토리 구조 생성 (`srv/`, `etc/`, `lib/`, `run/`, `shared/`, `docs/`, `scripts/`)
- Docker 네트워크 생성 (`net_external`, `net_internal`)
- Traefik ACME 저장소 생성 및 권한 설정

**참고:** 스크립트는 자동으로 프로젝트 루트를 감지합니다. 어디서든 실행 가능합니다.

### 3. 환경 변수 파일 설정

`etc/` 디렉토리의 `.env.example` 파일들을 참고하여 실제 `.env` 파일을 생성합니다:

```bash
# 전역 환경 변수
cp etc/global.env.example etc/global.env
# 필요에 따라 수정

# 각 서비스별 환경 변수
cp etc/srv/edge.traefik.env.example etc/srv/edge.traefik.env
cp etc/srv/edge.cloudflared.env.example etc/srv/edge.cloudflared.env
# ... 기타 필요한 서비스들
```

**중요 설정:**
- `edge.traefik.env`: Let's Encrypt 이메일 및 Cloudflare DNS-01 API 토큰
- `edge.cloudflared.env`: Cloudflare Tunnel 토큰 또는 credentials.json
- 기타 서비스별 필요한 환경 변수들

### 4. DNS 설정

내부 DNS 설정을 구성합니다. 자세한 내용은 [dns.md](./dns.md)를 참고하세요.

주요 설정:
- `*.home.mstorm.net` → Traefik (VM IP)
- `home.mstorm.net` → Traefik (VM IP)
- 외부 Cloudflare Tunnel 도메인 설정 (id.mstorm.net, vault.mstorm.net 등)

### 5. 초기화 실행

`preflight` 명령을 실행하여 각 서비스의 초기화 스크립트를 실행합니다:

```bash
./ops.sh preflight
```

이 명령은 다음 순서로 각 서비스의 `init.sh`를 실행합니다:
1. `edge/traefik`
2. `edge/cloudflared`
3. `data/postgres`
4. `data/redis`
5. `foundation/zitadel`
6. `foundation/headscale`
7. `observability/prometheus`
8. `observability/loki`
9. `observability/promtail`
10. `observability/alertmanager`
11. `observability/grafana`
12. `observability/uptime-kuma`
13. `apps/gitea`
14. `apps/portainer`
15. `apps/registry`
16. `apps/vaultwarden`
17. `apps/n8n`
18. `apps/teslamate`
19. `apps/unifi`

### 6. 서비스 배포

`deploy` 명령을 실행하여 서비스를 배포합니다:

```bash
# 모든 서비스 배포
./ops.sh deploy

# 특정 서비스만 배포
./ops.sh deploy edge/traefik
```

배포 순서는 초기화 순서와 동일합니다.

**경로 설정:**
- 스크립트는 자동으로 프로젝트 루트를 감지합니다.
- 감지된 루트는 `OPS_ROOT` 환경 변수로 export됩니다.
- 모든 `compose.yml` 파일은 `${OPS_ROOT:-.}`를 사용하여 경로를 설정합니다.
- 어디서든 스크립트를 실행할 수 있으며, 항상 올바른 프로젝트 루트를 찾습니다.

### 7. TLS 인증서 설정

Traefik이 Let's Encrypt 인증서를 자동으로 획득하도록 설정되어 있습니다. 자세한 내용은 [tls.md](./tls.md)를 참고하세요.

**주의사항:**
- Traefik 대시보드를 인터넷에 노출하지 마세요.
- ACME 저장소 파일(`lib/traefik/acme.json`)의 권한이 600으로 설정되어 있는지 확인하세요.

### 8. 검증

각 서비스의 `compose.yml` 파일을 검증하려면:

```bash
./ops.sh validate <unit-path>
```

예시:
```bash
./ops.sh validate edge/traefik
```

### 9. 서비스 중지

서비스를 중지하려면:

```bash
# 모든 서비스 중지 (역순)
./ops.sh down

# 특정 서비스만 중지
./ops.sh down apps/vaultwarden
```

