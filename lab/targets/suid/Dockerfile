FROM debian:12-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    sudo python3 findutils curl wget bash procps net-tools \
    libcap2-bin attr iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Usuário não privilegiado para rodar os testes
RUN useradd -m -s /bin/bash testuser && echo "testuser:testpass" | chpasswd

# ── Vetor 1: binários SUID clássicos ──────────────────────
# find com SUID (GTFOBins)
RUN cp /usr/bin/find /usr/local/bin/find_suid && chmod u+s /usr/local/bin/find_suid

# python3 com SUID
RUN cp /usr/bin/python3 /usr/local/bin/python3_suid && chmod u+s /usr/local/bin/python3_suid

# bash com SUID (crítico)
RUN cp /bin/bash /usr/local/bin/bash_suid && chmod u+s /usr/local/bin/bash_suid

# ── Vetor 2: capabilities perigosas ───────────────────────
# python3 com cap_setuid
RUN cp /usr/bin/python3 /usr/local/bin/python3_cap && \
    setcap cap_setuid+eip /usr/local/bin/python3_cap

# perl com cap_dac_read_search
RUN apt-get update -qq && apt-get install -y --no-install-recommends perl && \
    rm -rf /var/lib/apt/lists/* && \
    cp /usr/bin/perl /usr/local/bin/perl_cap && \
    setcap cap_dac_read_search+eip /usr/local/bin/perl_cap

# ── Vetor 3: arquivo gravável do root executável ──────────
RUN echo '#!/bin/bash' > /usr/local/bin/root_script.sh && \
    echo 'echo running as $(id)' >> /usr/local/bin/root_script.sh && \
    chmod 777 /usr/local/bin/root_script.sh

# ── Vetor 4: /etc/passwd gravável ─────────────────────────
RUN chmod 666 /etc/passwd

WORKDIR /opt
USER testuser
