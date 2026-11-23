# VIPERA Lab — Ambiente de Testes Docker

Suite de testes funcionais para validar detecções do `vipera.sh` em containers Docker isolados.

---

## Pré-requisitos

- Docker + Docker Compose
- `vipera.sh` em `../vipera.sh` (relativo a este diretório)

---

## Uso Rápido

```bash
# Suite completa (build + teste)
make test

# Modo rápido (flag -s no vipera)
make test-fast

# Apenas um target
make test TARGET=sudo

# Reconstruir imagens e testar
bash run_tests.sh all --rebuild

# Shell interativo no container
make shell TARGET=suid

# Rodar vipera manualmente
make vipera TARGET=secrets
```

---

## Targets Disponíveis

| Target | Container | Vulnerabilidades Configuradas |
|--------|-----------|------------------------------|
| `suid` | `lpe_suid` | bash/find/python3 com SUID; cap_setuid em python3; cap_dac_read_search em perl; executável root gravável; /etc/passwd gravável |
| `sudo` | `lpe_sudo` | NOPASSWD ALL; env_keep PYTHONPATH/PERL5LIB/RUBYLIB; SETENV; !requiretty; diretório PYTHONPATH gravável |
| `cron` | `lpe_cron` | cron com tar wildcard; rsync wildcard; PATH inseguro em crontab; maintenance.sh |
| `secrets` | `lpe_secrets` | Chave SSH privada; DB_PASSWORD em env; token Vault; .git-credentials; .my.cnf; .pgpass; senha em bash_history |
| `kernel` | `lpe_kernel` | Container privilegiado; CAP_SYS_ADMIN; cgroup release_agent; /etc/crontab gravável |
| `misc` | `lpe_misc` | umask 0 em /etc/profile; ld.so.conf.d gravável; logrotate.d gravável; usuário no grupo docker; /etc/shadow legível; __pycache__ gravável |

---

## Suite de Testes

O arquivo `run_tests.sh` contém **40 testes** distribuídos por categoria:

| Categoria | Testes | Descrição |
|-----------|--------|-----------|
| `suid` | 8 | SUID bits, capabilities, arquivos graváveis |
| `sudo` | 7 | Misconfigs sudo, env_keep, PYTHONPATH hijacking |
| `cron` | 4 | Wildcards, PATH inseguro |
| `secrets` | 8 | Credenciais, tokens, histórico |
| `kernel` | 4 | Container escape, cgroups |
| `misc` | 8 | Permissões, grupos, sumário de score |
| `flags` | 4–5 | Flags -N, -R, -q, -j |
| `fp` | 3 | Falsos positivos (sistema limpo) |

### Funções de assert

```bash
# Verifica que o padrão aparece na saída
assert_contains "$outfile" "pattern" "descrição do teste"

# Verifica que o padrão NÃO aparece (falso positivo)
assert_not_contains "$outfile" "pattern" "descrição do teste"
```

---

## Resultados

Os outputs brutos dos containers ficam em `results/`:

```
results/
├── suid.txt
├── sudo.txt
├── cron.txt
├── secrets.txt
├── kernel.txt
└── misc.txt
```

Resultados com `> 50KB` são **reutilizados** entre execuções (evita re-execução).  
Use `--rebuild` para forçar nova execução.

---

## Comandos Make

| Comando | Descrição |
|---------|-----------|
| `make build` | Constrói todas as imagens Docker |
| `make run` | Sobe todos os containers em background |
| `make test` | Suite completa |
| `make test-fast` | Suite com flag `-s` (mais rápido) |
| `make test TARGET=<t>` | Testa apenas o target especificado |
| `make shell TARGET=<t>` | Shell interativo no container |
| `make vipera TARGET=<t>` | Roda vipera manualmente (com cores) |
| `make stop` | Para todos os containers |
| `make clean` | Remove containers, imagens e resultados |
| `make logs TARGET=<t>` | Exibe logs do container |

---

## Adicionar Novo Target

1. Criar `targets/<nome>/Dockerfile` baseado em `debian:12-slim`
2. Adicionar serviço no `docker-compose.yml`:
   ```yaml
   target-nome:
     build: ./targets/nome
     container_name: lpe_nome
     volumes:
       - ../vipera.sh:/opt/vipera.sh:ro
     ...
   ```
3. Adicionar função `test_nome()` em `run_tests.sh`
4. Incluir `nome` na lista `targets` na função `main()`

---

## Executar Sem Make

```bash
# Script direto
bash run_tests.sh all
bash run_tests.sh sudo
bash run_tests.sh all --fast
bash run_tests.sh all --rebuild

# Flags especiais
#   --rebuild   Reconstrói imagens Docker antes de testar
#   --fast      Passa -s ao vipera (modo stealth/rápido)
```
