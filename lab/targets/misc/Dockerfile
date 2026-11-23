FROM debian:12-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    sudo bash procps curl wget python3 nfs-common \
    libcap2-bin attr screen openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash testuser && echo "testuser:testpass" | chpasswd

# ── Vetor 1: PATH hijack em script executado como root ─────
RUN echo '#!/bin/bash' > /opt/admin_script.sh && \
    echo 'cleanup' >> /opt/admin_script.sh && \
    chmod 755 /opt/admin_script.sh
# PATH inclui /tmp que é gravável
RUN echo 'PATH=/tmp:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
    >> /etc/environment

# ── Vetor 2: ld.so.conf.d com diretório gravável ──────────
RUN echo '/opt/libs' > /etc/ld.so.conf.d/custom.conf && \
    mkdir -p /opt/libs && chmod 777 /opt/libs

# ── Vetor 3: umask insegura em /etc/profile ───────────────
RUN echo 'umask 0' >> /etc/profile

# ── Vetor 4: arquivo writable em cron.d ───────────────────
RUN echo '* * * * * root /opt/admin_script.sh' > /etc/cron.d/admin && \
    chmod 666 /etc/cron.d/admin

# ── Vetor 5: /etc/shadow readable ─────────────────────────
RUN chmod 644 /etc/shadow

# ── Vetor 6: grupo docker / lxd no usuário ────────────────
RUN groupadd docker 2>/dev/null || true && \
    usermod -aG docker testuser

# ── Vetor 7: Python pycache gravável com .pyc injetável ───
RUN mkdir -p /opt/app/__pycache__ && chmod 777 /opt/app/__pycache__ && \
    echo 'print("app running")' > /opt/app/main.py && \
    chmod 755 /opt/app/main.py

# ── Vetor 8: logrotate config gravável ────────────────────
RUN echo '/var/log/app.log {' > /etc/logrotate.d/app && \
    echo '    weekly' >> /etc/logrotate.d/app && \
    echo '    postrotate' >> /etc/logrotate.d/app && \
    echo '        /opt/admin_script.sh' >> /etc/logrotate.d/app && \
    echo '    endscript' >> /etc/logrotate.d/app && \
    echo '}' >> /etc/logrotate.d/app && \
    chmod 666 /etc/logrotate.d/app

# ── Vetor 9: socket gravável por outros ───────────────────
RUN mkdir -p /var/run/app && \
    touch /var/run/app/control.sock && \
    chmod 666 /var/run/app/control.sock

# ── Vetor 10: arquivo .sudo_as_admin_successful ───────────
RUN touch /home/testuser/.sudo_as_admin_successful

WORKDIR /opt
USER testuser
