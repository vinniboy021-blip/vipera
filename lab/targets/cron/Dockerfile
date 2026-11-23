FROM debian:12-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    sudo cron tar bash procps curl wget rsync \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash testuser && echo "testuser:testpass" | chpasswd

# ── Vetor 1: cron root com tar wildcard ──────────────────
RUN mkdir -p /var/backups/data && chmod 777 /var/backups/data
RUN echo '* * * * * root tar czf /tmp/backup.tgz -C /var/backups/data *' \
    > /etc/cron.d/backup && chmod 644 /etc/cron.d/backup

# ── Vetor 2: cron root com rsync wildcard ─────────────────
RUN mkdir -p /var/sync && chmod 777 /var/sync
RUN echo '*/5 * * * * root rsync -av /var/sync/* /tmp/synced/' \
    >> /etc/cron.d/backup

# ── Vetor 3: script de cron gravável por outros ───────────
RUN echo '#!/bin/bash' > /opt/maintenance.sh && \
    echo 'echo "maintenance running"' >> /opt/maintenance.sh && \
    chmod 777 /opt/maintenance.sh
RUN echo '* * * * * root /opt/maintenance.sh' > /etc/cron.d/maintenance && \
    chmod 644 /etc/cron.d/maintenance

# ── Vetor 4: PATH inseguro no cron ────────────────────────
RUN echo 'PATH=/tmp:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' \
    > /etc/cron.d/pathtest && \
    echo '* * * * * root cleanup' >> /etc/cron.d/pathtest && \
    chmod 644 /etc/cron.d/pathtest

# ── Vetor 5: anacrontab com job gravável ──────────────────
RUN echo '1 5 cron.daily run-parts /etc/cron.daily' > /etc/anacrontab && \
    chmod 644 /etc/anacrontab

# Iniciar cron em background
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'service cron start 2>/dev/null || true' >> /start.sh && \
    echo 'exec sleep infinity' >> /start.sh && \
    chmod +x /start.sh

WORKDIR /opt
USER testuser
CMD ["/start.sh"]
