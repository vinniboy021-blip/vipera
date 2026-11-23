# VIPERA Lab -- Makefile
# Uso: make [target]

LAB_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
COMPOSE  := docker compose -f $(LAB_DIR)/docker-compose.yml

.PHONY: all build run test clean stop logs help

help:
	@echo ""
	@echo "  VIPERA Lab — Comandos disponíveis:"
	@echo ""
	@echo "  make build        Constrói todas as imagens Docker"
	@echo "  make run          Sobe todos os containers em background"
	@echo "  make test         Roda suite completa de testes"
	@echo "  make test-fast    Roda testes com flag -s (rápido)"
	@echo "  make test TARGET=suid  Testa apenas um target específico"
	@echo "  make shell TARGET=suid  Abre shell no container"
	@echo "  make vipera TARGET=suid  Roda vipera manualmente no container"
	@echo "  make stop         Para todos os containers"
	@echo "  make clean        Remove containers e imagens"
	@echo "  make logs TARGET=suid  Mostra logs de um container"
	@echo ""

build:
	@echo "[*] Construindo imagens..."
	$(COMPOSE) build

run:
	@echo "[*] Subindo containers..."
	$(COMPOSE) up -d
	@echo "[*] Containers ativos:"
	@$(COMPOSE) ps

test: run
	@echo "[*] Executando suite de testes..."
	@mkdir -p $(LAB_DIR)/results
	$(LAB_DIR)/run_tests.sh all

test-fast: run
	@$(LAB_DIR)/run_tests.sh all --fast

test-rebuild:
	@$(LAB_DIR)/run_tests.sh all --rebuild

test:
ifdef TARGET
	@$(LAB_DIR)/run_tests.sh $(TARGET)
else
	@$(LAB_DIR)/run_tests.sh all
endif

shell:
ifdef TARGET
	$(COMPOSE) exec target-$(TARGET) bash
else
	@echo "Uso: make shell TARGET=suid|sudo|cron|secrets|kernel|misc"
endif

vipera:
ifdef TARGET
	$(COMPOSE) exec target-$(TARGET) bash /opt/vipera.sh -N
else
	@echo "Uso: make vipera TARGET=suid|sudo|cron|secrets|kernel|misc"
endif

logs:
ifdef TARGET
	$(COMPOSE) logs target-$(TARGET)
else
	$(COMPOSE) logs
endif

stop:
	$(COMPOSE) stop

clean:
	$(COMPOSE) down --rmi local -v
	@rm -rf $(LAB_DIR)/results/*.txt
