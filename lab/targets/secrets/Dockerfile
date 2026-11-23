FROM debian:12-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    bash procps curl wget git python3 openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash testuser && echo "testuser:testpass" | chpasswd

# ── Vetor 1: senha fraca em /etc/shadow ───────────────────
# hash de "password" em SHA-512
RUN echo 'weakuser:$6$saltsalt$oP/h5oMUb8BoQfnBpJx5pNVT.K8rBKWCT9pFW3RRjPvBJpj9Cjpz4xbJtj3Bkp7a5Z0EHFiF1KP2JEMbDHpg1:19000:0:99999:7:::' \
    >> /etc/shadow && \
    echo 'weakuser:x:1001:1001::/home/weakuser:/bin/bash' >> /etc/passwd

# ── Vetor 2: chave SSH privada em local exposto ────────────
RUN mkdir -p /opt/deploy && \
    ssh-keygen -t rsa -b 2048 -f /opt/deploy/id_rsa -N "" -C "deploy@prod" 2>/dev/null && \
    chmod 644 /opt/deploy/id_rsa

# ── Vetor 3: credenciais em variáveis de ambiente ─────────
RUN echo 'export DB_PASSWORD=supersecret123' >> /etc/environment && \
    echo 'export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY' >> /etc/environment && \
    echo 'export API_KEY=sk-proj-abcdefghijklmnop1234567890' >> /etc/environment

# ── Vetor 4: arquivo .env com credenciais ─────────────────
RUN echo 'DB_HOST=db.internal\nDB_USER=admin\nDB_PASS=admin123\nSECRET_KEY=django-insecure-xxxxx' \
    > /opt/app/.env 2>/dev/null || \
    (mkdir -p /opt/app && printf 'DB_HOST=db.internal\nDB_USER=admin\nDB_PASS=admin123\nSECRET_KEY=django-insecure-xxxxx\n' > /opt/app/.env) && \
    chmod 644 /opt/app/.env

# ── Vetor 5: token Vault no filesystem ────────────────────
RUN echo 'hvs.CAESIFAKE_VAULT_TOKEN_FOR_TESTING_ONLY_XXXXXX' > /root/.vault-token && \
    chmod 644 /root/.vault-token && \
    echo 'hvs.CAESIFAKE_VAULT_TOKEN_FOR_TESTING_ONLY_XXXXXX' > /home/testuser/.vault-token && \
    chown testuser:testuser /home/testuser/.vault-token && chmod 644 /home/testuser/.vault-token && \
    echo 'VAULT_TOKEN=hvs.CAESIFAKE_VAULT_TOKEN_FOR_TESTING_ONLY_XXXXXX' >> /etc/environment

# ── Vetor 6: .git-credentials com token GitHub ────────────
RUN echo 'https://user:ghp_FakeGitHubTokenXXXXXXXXXXXXXXXX@github.com' \
    > /home/testuser/.git-credentials && \
    chmod 644 /home/testuser/.git-credentials

# ── Vetor 7: history com senha em linha de comando ─────────
RUN echo 'mysql -u root -pMyS3cur3Pass database' >> /home/testuser/.bash_history && \
    echo 'curl -u admin:Admin123 http://api.internal/v1/users' >> /home/testuser/.bash_history && \
    chown testuser:testuser /home/testuser/.bash_history

# ── Vetor 8: arquivo de configuração com credenciais ───────
RUN printf '[client]\nuser=dbadmin\npassword=DbPass456\nhost=localhost\n' \
    > /home/testuser/.my.cnf && \
    chown testuser:testuser /home/testuser/.my.cnf && chmod 644 /home/testuser/.my.cnf

# ── Vetor 9: .pgpass exposto ──────────────────────────────
RUN echo 'localhost:5432:mydb:pguser:PgSecret789' \
    > /home/testuser/.pgpass && \
    chown testuser:testuser /home/testuser/.pgpass && chmod 644 /home/testuser/.pgpass

WORKDIR /opt
USER testuser
