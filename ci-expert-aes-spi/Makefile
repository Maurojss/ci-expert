# ==========================================
# AES + SPI — Projeto RTL Design Track
# Makefile — Semana 1: ambiente mínimo (VCS)
# ==========================================

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
# Critério de aceite da Semana 1: execução com um único comando.
sim: $(SIM_OUT)
	cd $(SIM_OUT) && \
	vcs -full64 -sverilog -timescale=1ns/1ps \
		-debug_access+all -kdb \
		$(EXAMPLE_RTL) $(EXAMPLE_TB) \
		-top $(EXAMPLE_TOP) -o simv \
		| tee vcs_compile.log && \
	./simv | tee sim.log

# Lint com VCS:
# Usamos -compile para evitar que o linker (ld) seja chamado
lint: $(SIM_OUT)
	cd $(SIM_OUT) && \
	vcs -full64 -sverilog +lint=all,noVCDE \
		$(EXAMPLE_RTL) -top counter -o simv_lint \
		| tee lint.log

clean:
	rm -rf $(BUILD_DIR) *.log simv* csrc ucli.key vc_hdrs.h DVEfiles verdiLog novas.*

help:
	@echo "Alvos disponiveis:"
	@echo "  make sim    - compila e simula o exemplo minimo (VCS)"
	@echo "  make lint   - roda lint no exemplo minimo (VCS)"
	@echo "  make clean  - remove artefatos gerados (build/)"