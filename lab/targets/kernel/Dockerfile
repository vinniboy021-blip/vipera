FROM debian:12-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    bash procps kmod iproute2 curl wget util-linux \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash testuser && echo "testuser:testpass" | chpasswd

# ── Container escape indicators ───────────────────────────
# Docker socket (montado em runtime via docker-compose se desejado)
# Este target roda privilegiado para simular escape de container

# ── Vetor 1: cgroup release_agent (privileged) ────────────
# Simulado pelo modo privileged do container

# ── Vetor 2: /proc/sysrq-trigger acessível ────────────────
# Disponível automaticamente em modo privileged

# ── Vetor 3: /dev/mem ou /dev/kmem ────────────────────────
# Disponível em modo privileged

# ── Vetor 4: arquivo de indicadores de container ──────────
RUN echo 'docker' > /proc/1/cgroup 2>/dev/null || true
# .dockerenv já existe automaticamente em containers Docker

# ── Vetor 5: capabilities perigosas disponíveis ───────────
# Em modo privileged: CAP_SYS_ADMIN, CAP_NET_ADMIN, etc.

# ── Vetor 6: /etc/crontab gravável (simular) ──────────────
RUN echo '# crontab' > /etc/crontab && chmod 666 /etc/crontab

WORKDIR /opt
USER testuser
