# ==========================================
# AES + SPI — Projeto RTL Design Track
# Makefile — Semana 1: ambiente mínimo (VCS)
# ==========================================
# Segue o mesmo padrão usado no projeto da vending machine:
# ROOT_DIR relativo ao diretório de execução, cada alvo com seu log.

ROOT_DIR    := $(CURDIR)
RTL_DIR     := $(ROOT_DIR)/rtl
TB_DIR      := $(ROOT_DIR)/tb
SCRIPTS_DIR := $(ROOT_DIR)/scripts

BUILD_DIR   := $(ROOT_DIR)/build
SIM_OUT     := $(BUILD_DIR)/sim

# ----- Exemplo mínimo (Semana 1): prova o fluxo, não é o AES ainda -----
EXAMPLE_RTL := $(RTL_DIR)/example/counter.sv
EXAMPLE_TB  := $(TB_DIR)/example/tb_counter.sv
EXAMPLE_TOP := tb_counter

.PHONY: all sim lint clean help

all: sim

$(SIM_OUT):
	mkdir -p $(SIM_OUT)

# Compila e roda o exemplo mínimo com VCS.
# Este é o "único comando" exigido pelo critério de aceite da Semana 1.
sim: $(SIM_OUT)
	cd $(SIM_OUT) && \
	vcs -full64 -sverilog -timescale=1ns/1ps \
		$(EXAMPLE_RTL) $(EXAMPLE_TB) \
		-top $(EXAMPLE_TOP) -o simv \
		| tee vcs_compile.log && \
	./simv | tee sim.log

# Lint básico (ajustar para a ferramenta de lint fornecida pelo instrutor,
# ex.: Spyglass, Verilator --lint-only, ou VCS -lint=all).
lint: $(SIM_OUT)
	cd $(SIM_OUT) && \
	vcs -full64 -sverilog -lint=all,noVCDE \
		$(EXAMPLE_RTL) -top counter \
		| tee lint.log

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "Alvos disponiveis:"
	@echo "  make sim    - compila e simula o exemplo minimo (VCS)"
	@echo "  make lint   - roda lint no exemplo minimo"
	@echo "  make clean  - remove artefatos gerados (build/)"
