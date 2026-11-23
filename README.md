# VIPERA — Linux Privilege Escalation Awesome Script

Ferramenta de enumeração ofensiva para escalonamento de privilégios em Linux.  
Baseada no [linPEAS original (PEASS-ng)](https://github.com/peass-ng/PEASS-ng), com extensões para pentest e CTF.

---

## Uso Rápido

```bash
# Enumeração padrão (com cores)
bash vipera.sh

# Modo rápido (stealth, sem verificações lentas)
bash vipera.sh -s

# Sem cores (para pipe / grep)
bash vipera.sh -N

# Salvar resultado sem ANSI em arquivo
bash vipera.sh -R /tmp/relatorio.txt

# Exportar hits/score/razões como JSON
bash vipera.sh -j /tmp/hits.json

# Todas as verificações extras
bash vipera.sh -a
```

---

## Flags

| Flag | Descrição |
|------|-----------|
| `-a` | Todas as verificações: processos 1 min, brute force su, checks extras |
| `-s` | Modo rápido/stealth (pula checks lentos) |
| `-e` | Verificações extras |
| `-r` | Habilita regexes (pode demorar horas) |
| `-N` | Sem cores (também respeita `NO_COLOR`) |
| `-q` | Sem banner |
| `-R <arquivo>` | Salva saída em arquivo sem códigos ANSI |
| `-j <arquivo>` | Exporta hits, score e razões como JSON |
| `-P <senha>` | Senha para `sudo -l` e brute force de outros usuários via `su` |
| `-o <checks>` | Executa apenas checks selecionados (lista separada por vírgula) |
| `-T <técnicas>` | Filtra por técnicas MITRE ATT&CK (ex: `-T T1057,T1082`) |
| `-w` | Aguarda entre blocos grandes |
| `-D` | Modo debug |
| `-V` | Envia inventário para HackTricks (lookup online de CVEs) |
| `-n` | Não verifica hostname/IP em listas de maliciosos |
| `-z <N>` | Define número de threads para checks paralelos |
| `-d <IP/MASK>` | Descoberta de hosts (fping/ping) |
| `-p <portas> -d <IP/MASK>` | Descoberta com scan de portas TCP (nc) |
| `-i <IP> [-p <portas>]` | Scan de IP com nc |
| `-f <pasta>` | Analisa firmware/pasta em busca de senhas e permissões |
| `-F LOCAL:LPORT:REMOTE:RPORT` | Port forwarding reverso |
| `-h` | Exibe ajuda |

---

## Sistema de Pontuação (Score)

Ao final da execução é exibido um **sumário visual** com:

- **Nível de risco**: CRÍTICO / ALTO / MÉDIO / BAIXO / MÍNIMO
- **Barra Unicode** proporcional ao score total
- **Top-5 findings** mais pontuados
- **Ajustes por mitigações ativas**: AppArmor (-3), SELinux Enforcing (-5), seccomp estrito (-2)

### Pesos por categoria (aproximado)

| Pontuação | Exemplos |
|-----------|---------|
| 10 | SUID em bash, sudo NOPASSWD ALL, shadow legível |
| 9 | /etc/passwd gravável, container privilegiado, motd.d gravável, CVE crítico |
| 8 | cap_setuid, cron com PATH inseguro, kernel UAF (CVE-2025-21756) |
| 7 | env_keep com PYTHONPATH, /proc/sysrq-trigger gravável, sudo heap overflow |
| 5 | Usuário no grupo docker, chave SSH privada exposta |
| 3-4 | Configurações suspeitas, credenciais em arquivos |

### Exportação JSON (`-j`)

O arquivo gerado contém:

```json
{
  "score": 42,
  "risk_level": "CRÍTICO",
  "hits": ["sudo NOPASSWD ALL detectado", "..."],
  "top_findings": ["[+10] bash suid detectado", "..."],
  "exploits": ["python3 -c 'import os; os.execl(\"/bin/sh\", \"sh\")' # via SUID"],
  "timestamp": "2026-11-22T10:30:00Z",
  "hostname": "target01",
  "user": "www-data"
}
```

---

## CVEs Detectados

| CVE | Descrição | Score | Condição |
|-----|-----------|-------|---------|
| CVE-2024-26809 | OtterRoot — nftables pipapo double-free | 9 | kernel 5.6–6.7 + nf_tables + userns |
| CVE-2021-3156 | Baron Samedit — sudo heap overflow (< 1.9.5p2) | 9 | Versão sudo |
| CVE-2021-4034 | PwnKit — pkexec LPE | 9 | polkit instalado |
| CVE-2022-0847 | Dirty Pipe — kernel 5.8–5.16.11 | 9 | Versão kernel |
| CVE-2024-1086 | nftables UAF — kernel 5.14–6.5 | 9 | kernel + nf_tables + userns |
| CVE-2024-21626 | runc container escape (< 1.1.12) | 9 | runc em container |
| CVE-2024-50264 | vsock/virtio UAF — kernel 4.8–6.11 | 8 | vsock/virtio_transport carregado |
| CVE-2024-56614 | eBPF XSK OOB write — kernel 4.18–6.12 | 8 | BPF não restrito |
| CVE-2024-56615 | eBPF DEVMAP OOB write — kernel 4.18–6.12 | 8 | BPF não restrito |
| CVE-2024-26923 | af_unix race UAF — Ubuntu 24.04 kernel 6.8.x | 8 | Ubuntu 24.04 + kernel < 6.8.7 |
| CVE-2025-21756 | vmalloc UAF — kernel 6.1–6.12.4 | 8 | Versão kernel |
| CVE-2024-53141 | ipset bitmap OOB write — kernel 2.6–6.12 | 7 | ip_set carregado |
| CVE-2024-43882 | execve TOCTOU setuid race — kernel 5.5–6.10.6 | 7 | Versão kernel |
| CVE-2025-32463 | sudo heap overflow (< 1.9.17p1) | 7 | Versão sudo |
| CVE-2016-5195 | Dirty COW | 7 | Versão kernel < 4.8.3 |
| CVE-2025-6019 | udisks2 < 2.10.1 — Polkit filesystem mount bypass | 7 | udisks2 ativo + versão |
| CVE-2023-4911 | Looney Tunables — glibc < 2.38 GLIBC_TUNABLES | 7 | Versão glibc |
| CVE-2024-6387 | regreSSHion — sshd 8.5p1–9.7p1 RCE pre-auth | 9 | Versão sshd |
| CVE-2022-0185 | fsconfig heap overflow — kernel < 5.16.2 | 8 | Versão kernel |
| CVE-2023-0386 | overlayfs setuid copy-up — kernel < 6.2 | 8 | Versão kernel |

---

## Detecções Especiais

Além das verificações padrão, a ferramenta inclui:

- **`/etc/update-motd.d/` gravável** — permite execução como root no login (score 9)
- **Systemd timers com ExecStart gravável** — escalação via serviço agendado (score 9)  
- **`/proc/sysrq-trigger` gravável** — pode travar/reiniciar sistema (score 7)
- **PYTHONPATH / PERL5LIB / RUBYLIB em `env_keep`** — hijacking de módulos via sudo (score 7)
- **`__pycache__` gravável em PATH de root** — injeção de código Python
- **Credenciais em `.env`, histórico bash, `.my.cnf`, `.pgpass`**
- **Tokens HashiCorp Vault, AWS keys, GitHub tokens**

---

## Lab de Testes

Ver [lab/README.md](lab/README.md) para instruções completas.

```bash
cd lab/

# Executar suite completa
make test

# Testar apenas um target
make test TARGET=sudo

# Abrir shell no container
make shell TARGET=suid

# Rodar vipera manualmente
make vipera TARGET=secrets
```

---

## Estrutura do Projeto

```
vipera/
├── vipera.sh          # Script principal (26812 linhas)
└── lab/
    ├── docker-compose.yml
    ├── Makefile
    ├── run_tests.sh    # Suite de testes funcionais (40 testes)
    ├── results/        # Outputs dos testes (gerado)
    └── targets/        # Dockerfiles dos containers vulneráveis
        ├── suid/       # SUID bits + capabilities
        ├── sudo/       # Sudo misconfigs
        ├── cron/       # Cron wildcards + PATH inseguro
        ├── secrets/    # Credenciais expostas
        ├── kernel/     # Container escape + cgroups
        └── misc/       # umask, ld.so, logrotate, docker group
```

---

## Variáveis de Ambiente

| Variável | Efeito |
|----------|--------|
| `NO_COLOR=1` | Desabilita cores (equivalente a `-N`) |
| `EXTRA_JSON=1` | Habilita exportação JSON (equivalente a `-j`) |
| `DEBUG=1` | Modo debug verboso |

---

## Notas de Segurança

- Execute **somente em ambientes autorizados** (pentest, CTF, lab)
- A flag `-V` envia dados para servidor externo (HackTricks)
- Arquivos temporários são criados em `/tmp/.lpe_*` e removidos ao final
- Use `-R` para gerar relatórios limpos sem ANSI para inclusão em documentos
