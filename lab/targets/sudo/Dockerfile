FROM debian:12-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    sudo python3 perl ruby bash procps curl wget \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash testuser && echo "testuser:testpass" | chpasswd && \
    usermod -aG sudo testuser

# ── Vetor 1: NOPASSWD total ────────────────────────────────
RUN echo 'testuser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/testuser

# ── Vetor 2: sudo com env_keep de PYTHONPATH ──────────────
RUN echo 'Defaults env_keep += "PYTHONPATH PERL5LIB RUBYLIB"' >> /etc/sudoers.d/testuser

# ── Vetor 3: sudo com SETENV e wildcard ───────────────────
RUN echo 'testuser ALL=(ALL) SETENV: NOPASSWD: /usr/bin/python3 *' >> /etc/sudoers.d/testuser

# ── Vetor 4: sudoedit em arquivo arbitrário ────────────────
RUN echo 'testuser ALL=(root) NOPASSWD: sudoedit /etc/hosts' >> /etc/sudoers.d/testuser

# ── Vetor 5: diretório de PYTHONPATH gravável ──────────────
RUN mkdir -p /opt/pylibs && chmod 777 /opt/pylibs && \
    echo 'export PYTHONPATH=/opt/pylibs' >> /home/testuser/.bashrc

# ── Vetor 6: !requiretty ──────────────────────────────────
RUN echo 'Defaults !requiretty' >> /etc/sudoers.d/testuser

RUN chmod 0440 /etc/sudoers.d/testuser

WORKDIR /opt
USER testuser
