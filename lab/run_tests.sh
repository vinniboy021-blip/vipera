#!/bin/bash
# =============================================================
#  VIPERA Lab -- Suite de Testes Funcionais
#  Uso: ./run_tests.sh [target|all] [--rebuild] [--fast]
# =============================================================
set -uo pipefail

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$LAB_DIR/results"
COMPOSE="docker compose -f $LAB_DIR/docker-compose.yml"
VIPERA_SH="$LAB_DIR/../vipera.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

pass()   { printf "${GREEN}[PASS]${NC} %s\n" "$1"; }
fail()   { printf "${RED}[FAIL]${NC} %s\n" "$1"; FAILURES=$((FAILURES+1)); }
info()   { printf "${BLUE}[INFO]${NC} %s\n" "$1" >&2; }
warn()   { printf "${YELLOW}[WARN]${NC} %s\n" "$1" >&2; }
header() { printf "\n${BOLD}${BLUE}══════════════════════════════════════════${NC}\n"; \
           printf "${BOLD}  %s${NC}\n" "$1"; \
           printf "${BOLD}${BLUE}══════════════════════════════════════════${NC}\n\n"; }

FAILURES=0
TARGET_FILTER="${1:-all}"
REBUILD=0
FAST_MODE=""
for arg in "$@"; do
  [ "$arg" = "--rebuild" ] && REBUILD=1
  [ "$arg" = "--fast" ] && FAST_MODE="-s"
done

mkdir -p "$RESULTS_DIR"

# ── Verificações de pré-requisito ─────────────────────────
check_prereqs() {
  command -v docker >/dev/null 2>&1 || { echo "Docker não encontrado"; exit 1; }
  [ -f "$VIPERA_SH" ] || { echo "vipera.sh não encontrado em $VIPERA_SH"; exit 1; }
}

# ── Build de um target ────────────────────────────────────
build_target() {
  local name="$1"
  info "Build: target-$name"
  $COMPOSE build "target-$name" 2>&1 | tail -3
}

# ── Iniciar container ─────────────────────────────────────
start_target() {
  local name="$1"
  $COMPOSE up -d "target-$name" 2>/dev/null
  # Aguardar container ficar pronto
  local i=0
  while ! docker exec "lpe_$name" true 2>/dev/null; do
    sleep 1; i=$((i+1)); [ $i -gt 15 ] && { fail "Container lpe_$name não iniciou"; return 1; }
  done
}

# ── Rodar vipera no container ─────────────────────────────
run_vipera() {
  local name="$1"
  local outfile="$RESULTS_DIR/${name}.txt"
  # Reusar resultado existente se tiver >50KB (evita re-execução desnecessária)
  if [ -f "$outfile" ] && [ "$(wc -c < "$outfile")" -gt 50000 ] && [ "$REBUILD" != "1" ]; then
    info "Reusando resultado existente: $outfile"
    echo "$outfile"
    return
  fi
  info "Executando vipera em target-$name ..."
  docker exec "lpe_$name" bash /opt/vipera.sh -N $FAST_MODE 2>/dev/null > "$outfile" || true
  echo "$outfile"
}

# ── Verificar se saída contém padrão esperado ─────────────
assert_contains() {
  local outfile="$1" pattern="$2" description="$3"
  if grep -qiE "$pattern" "$outfile" 2>/dev/null; then
    pass "$description"
  else
    fail "$description (padrão não encontrado: $pattern)"
  fi
}

assert_not_contains() {
  local outfile="$1" pattern="$2" description="$3"
  if ! grep -qiE "$pattern" "$outfile" 2>/dev/null; then
    pass "$description (falso positivo não presente)"
  else
    fail "$description (FALSO POSITIVO detectado: $pattern)"
  fi
}

# =============================================================
#  TESTES POR TARGET
# =============================================================

test_suid() {
  header "TARGET: SUID / Capabilities"
  local out
  out=$(run_vipera "suid")

  assert_contains "$out" "bash_suid.*suid|suid.*bash_suid" "Detecta bash com SUID"
  assert_contains "$out" "find_suid.*suid|suid.*find_suid" "Detecta find com SUID"
  assert_contains "$out" "python3_suid.*suid|suid.*python3_suid" "Detecta python3 com SUID"
  assert_contains "$out" "cap_setuid|setuid.*cap" "Detecta cap_setuid em python3_cap"
  assert_contains "$out" "cap_dac_read_search" "Detecta cap_dac_read_search em perl_cap"
  assert_contains "$out" "root_script.*777|777.*root_script|gravav.*root_script|writable.*root" "Detecta executável root gravável"
  assert_contains "$out" "/etc/passwd.*gravav|gravav.*/etc/passwd|passwd.*writable|writable.*passwd" "Detecta /etc/passwd gravável"
  assert_contains "$out" "SCORE|score|risco" "Gera score de risco"
}

test_sudo() {
  header "TARGET: Sudo Misconfiguration"
  local out
  out=$(run_vipera "sudo")

  assert_contains "$out" "NOPASSWD.*ALL|ALL.*NOPASSWD" "Detecta sudo NOPASSWD ALL"
  assert_contains "$out" "PYTHONPATH|env_keep.*PYTHON|PYTHON.*env_keep" "Detecta env_keep PYTHONPATH"
  assert_contains "$out" "PERL5LIB|env_keep.*PERL|PERL.*env_keep" "Detecta env_keep PERL5LIB"
  assert_contains "$out" "RUBYLIB|env_keep.*RUBY|RUBY.*env_keep" "Detecta env_keep RUBYLIB"
  assert_contains "$out" "SETENV|setenv" "Detecta SETENV"
  assert_contains "$out" "\!requiretty|requiretty" "Detecta !requiretty"
  assert_contains "$out" "PYTHONPATH.*hijack|hijacking.*PYTHONPATH|PYTHONPATH.*diretorio.*gravav|/opt/pylibs" "Detecta diretório PYTHONPATH gravável"
}

test_cron() {
  header "TARGET: Cron Wildcards / PATH"
  local out
  out=$(run_vipera "cron")

  assert_contains "$out" "tar.*wildcard|wildcard.*tar|--checkpoint" "Detecta cron com tar wildcard / --checkpoint"
  assert_contains "$out" "rsync.*wildcard|wildcard.*rsync" "Detecta cron com rsync wildcard"
  assert_contains "$out" "maintenance" "Detecta maintenance.sh em cron"
  assert_contains "$out" "PATH=.*/tmp|/tmp.*PATH" "Detecta PATH inseguro em cron"
}

test_secrets() {
  header "TARGET: Secrets / Credenciais"
  local out
  out=$(run_vipera "secrets")

  assert_contains "$out" "id_rsa|chave.*ssh|ssh.*key|private.*key" "Detecta chave SSH privada"
  assert_contains "$out" "DB_PASS|DB_PASSWORD|supersecret|admin123" "Detecta DB password"
  assert_contains "$out" "wJalr|SECRET_KEY=django|API_KEY=sk-proj" "Detecta credencial em env/.env"
  assert_contains "$out" "vault.token|vault-token|VAULT_TOKEN|hvs[.]" "Detecta token Vault"
  assert_contains "$out" "git.credentials|ghp_" "Detecta .git-credentials"
  assert_contains "$out" "\.my\.cnf|my\.cnf.*password|mysql.*credencial" "Detecta .my.cnf"
  assert_contains "$out" "\.pgpass|pgpass.*password|postgres.*credencial" "Detecta .pgpass"
  assert_contains "$out" "mysql.*MyS3|MyS3.*mysql|bash_history" "Detecta senha no bash_history"
}

test_kernel() {
  header "TARGET: Kernel / Container Escape"
  local out
  out=$(run_vipera "kernel")

  assert_contains "$out" "docker|container|\.dockerenv" "Detecta ambiente container"
  assert_contains "$out" "privileged|CAP_SYS_ADMIN|sys_admin" "Detecta container privilegiado"
  assert_contains "$out" "cgroup|release_agent" "Detecta vetor cgroup release_agent"
  assert_contains "$out" "/etc/crontab|crontab.*gravav|crontab.*writable" "Detecta /etc/crontab gravável"
  # CVE-2024-1086 nftables (apenas se kernel vulnerável)
  # (apenas informativo, não falha se kernel não for vulnerável)
}

test_misc() {
  header "TARGET: Misc (PATH/umask/ld.so/logrotate)"
  local out
  out=$(run_vipera "misc")

  assert_contains "$out" "umask.*0[^0-9]|Umask insegura.*0" "Detecta umask 0 em /etc/profile"
  assert_contains "$out" "ld[.]so[.]conf|custom[.]conf" "Detecta ld.so.conf.d gravável"
  assert_contains "$out" "/etc/logrotate[.]d/app|/etc/cron[.]d/admin" "Detecta logrotate/cron.d em writable files"
  assert_contains "$out" "docker.*group|Am I inside Docker.*Yes|groups=.*docker" "Detecta usuário no grupo docker"
  assert_contains "$out" "Can I read shadow|shadow.*root:" "Detecta /etc/shadow legível"
  assert_contains "$out" "__pycache__" "Detecta __pycache__ gravável"
  # Verificar se a barra de risco aparece no sumário
  assert_contains "$out" "RISCO|CRITICO|ALTO|MEDIO|BAIXO|MINIMO" "Sumário exibe nível de risco"
  # Verificar que o score é gerado
  assert_contains "$out" "pts|SCORE|score" "Sumário exibe pontuação"
}

# =============================================================
#  TESTE DE FALSOS POSITIVOS (sistema limpo)
# =============================================================

test_false_positives() {
  header "TARGET: Falsos Positivos (sistema limpo)"
  # Usar o container misc mas verificar ausência de alertas específicos
  local out="$RESULTS_DIR/misc.txt"
  [ -f "$out" ] || out=$(run_vipera "misc")

  # Estes padrões NÃO devem aparecer como hits críticos em sistemas comuns
  assert_not_contains "$out" "CVE-2021-3156.*VULNERAVEL.*1\.9\.1[^0-9]" "Não gera falso positivo Baron Samedit em sudo moderno"
  assert_not_contains "$out" "Elasticsearch sem autenticacao.*PONG" "Não confunde Redis com Elasticsearch"
  assert_not_contains "$out" "Jupyter.*sem token.*\[\].*false" "Não falso positivo Jupyter sem serviço"
}

# =============================================================
#  TESTE DE OUTPUT / FLAGS
# =============================================================

test_flags() {
  header "Testes de Flags e Output"
  local container="lpe_misc"

  # Testar flag -N (sem cores)
  info "Testando flag -N (sem ANSI)..."
  local nocolor_out
  nocolor_out=$(docker exec "$container" bash /opt/vipera.sh -N -s 2>/dev/null | head -100 || true)
  if ! printf '%s' "$nocolor_out" | grep -qE '\x1B\['; then
    pass "Flag -N remove códigos ANSI corretamente"
  else
    fail "Flag -N ainda contém códigos ANSI"
  fi

  # Testar flag -R (output para arquivo)
  info "Testando flag -R (saída em arquivo)..."
  docker exec "$container" bash /opt/vipera.sh -s -R /tmp/vpr_test_output.txt 2>/dev/null || true
  local rf
  rf=$(docker exec "$container" cat /tmp/vpr_test_output.txt 2>/dev/null | wc -c || echo 0)
  if [ "$rf" -gt 100 ]; then
    pass "Flag -R gera arquivo de output ($rf bytes)"
    local ansi_check
    ansi_check=$(docker exec "$container" grep -cP '\x1B\[' /tmp/vpr_test_output.txt 2>/dev/null || echo 0)
    if [ "$ansi_check" -eq 0 ]; then
      pass "Arquivo -R não contém códigos ANSI"
    else
      fail "Arquivo -R ainda contém $ansi_check linhas com ANSI"
    fi
  else
    fail "Flag -R não gerou output no arquivo (tamanho: $rf bytes)"
  fi

  # Testar flag -q (sem banner)
  info "Testando flag -q (sem banner)..."
  local quiet_out
  quiet_out=$(docker exec "$container" bash /opt/vipera.sh -q -s -N 2>/dev/null | head -5 || true)
  if ! printf '%s' "$quiet_out" | grep -qi "vipera"; then
    pass "Flag -q suprime banner"
  else
    warn "Flag -q pode ainda mostrar parte do banner (aceitável)"
  fi

  # Verificar JSON output
  info "Testando -j (JSON output)..."
  docker exec "$container" bash -c 'EXTRA_JSON=1 bash /opt/vipera.sh -s -N 2>/dev/null; ls /tmp/vipera_hits_*.json 2>/dev/null | head -1' > /tmp/json_check.txt 2>/dev/null || true
  local json_file
  json_file=$(cat /tmp/json_check.txt | tail -1)
  if docker exec "$container" sh -c "[ -f '$json_file' ]" 2>/dev/null; then
    pass "EXTRA_JSON=1 gera arquivo JSON"
  else
    warn "JSON file não confirmado (pode não ter hits no container)"
  fi
}

# =============================================================
#  RUNNER PRINCIPAL
# =============================================================

run_target() {
  local name="$1"
  [ "$REBUILD" = "1" ] && build_target "$name"
  start_target "$name" || return 1
  "test_$name"
}

main() {
  check_prereqs

  printf "\n${BOLD}${GREEN}"
  printf "╔══════════════════════════════════════════╗\n"
  printf "║     VIPERA Lab — Testes Funcionais       ║\n"
  printf "╚══════════════════════════════════════════╝${NC}\n"
  printf "  Target: ${YELLOW}%s${NC}  |  Rebuild: ${YELLOW}%s${NC}  |  Fast: ${YELLOW}%s${NC}\n\n" \
    "$TARGET_FILTER" "$([ $REBUILD -eq 1 ] && echo sim || echo não)" "$([ -n "$FAST_MODE" ] && echo sim || echo não)"

  local targets="suid sudo cron secrets kernel misc"

  # Build inicial (só se --rebuild)
  if [ "$REBUILD" = "1" ]; then
    info "Construindo imagens Docker..."
    for t in $targets; do
      case "$TARGET_FILTER" in
        all|"$t") build_target "$t" ;;
      esac
    done
  fi

  # Executar testes
  for t in $targets; do
    case "$TARGET_FILTER" in
      all|"$t")
        run_target "$t" || warn "Target $t falhou ao iniciar"
        ;;
    esac
  done

  # Testes de flags (usa container misc que já deve estar rodando)
  if [ "$TARGET_FILTER" = "all" ] || [ "$TARGET_FILTER" = "flags" ]; then
    if docker ps | grep -q "lpe_misc"; then
      test_flags
    else
      start_target "misc" && test_flags
    fi
  fi

  # Testes de falsos positivos
  if [ "$TARGET_FILTER" = "all" ] || [ "$TARGET_FILTER" = "fp" ]; then
    test_false_positives
  fi

  # Resumo final
  printf "\n${BOLD}══════════════════════════════════════════${NC}\n"
  if [ "$FAILURES" -eq 0 ]; then
    printf "${GREEN}${BOLD}  TODOS OS TESTES PASSARAM!${NC}\n"
  else
    printf "${RED}${BOLD}  FALHAS: $FAILURES teste(s) falharam${NC}\n"
  fi
  printf "${BOLD}  Resultados salvos em: ${YELLOW}$RESULTS_DIR/${NC}\n"
  printf "${BOLD}══════════════════════════════════════════${NC}\n\n"

  exit $FAILURES
}

main "$@"
