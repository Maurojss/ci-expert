# ==========================================
# AES + SPI — Projeto RTL Design Track
# Makefile — Semanas 1, 2 e 3 (VCS)
# ==========================================

SHELL       := /bin/bash

ROOT_DIR    := $(CURDIR)
RTL_DIR     := $(ROOT_DIR)/rtl
TB_DIR      := $(ROOT_DIR)/tb
SCRIPTS_DIR := $(ROOT_DIR)/scripts

BUILD_DIR   := $(ROOT_DIR)/build
SIM_OUT     := $(BUILD_DIR)/sim
REPORT_DIR  := $(ROOT_DIR)/reports

EXAMPLE_RTL := $(RTL_DIR)/example/counter.sv
EXAMPLE_TB  := $(TB_DIR)/example/tb_counter.sv
EXAMPLE_TOP := tb_counter

AES_DIR     := $(RTL_DIR)/minisoc_aes
AES_RTL     := $(AES_DIR)/minisoc_aes_sbox.sv $(AES_DIR)/minisoc_aes_inv_sbox.sv \
               $(AES_DIR)/minisoc_aes_sub_bytes.sv $(AES_DIR)/minisoc_aes_shift_rows.sv \
               $(AES_DIR)/minisoc_aes_inv_sub_bytes.sv $(AES_DIR)/minisoc_aes_inv_shift_rows.sv
AES_TOPS    := minisoc_aes_sub_bytes minisoc_aes_shift_rows \
               minisoc_aes_inv_sub_bytes minisoc_aes_inv_shift_rows
AES_TB_DIR  := $(TB_DIR)/minisoc_aes
AES_TB      := $(AES_TB_DIR)/tb_minisoc_aes_sub_shift.sv
AES_TB_TOP  := tb_minisoc_aes_sub_shift

# Semana 3: MixColumns, AddRoundKey, InvMixColumns e AES-128 completo
ROUND_RTL    := $(AES_RTL) $(AES_DIR)/minisoc_aes_mix_columns.sv \
                $(AES_DIR)/minisoc_aes_inv_mix_columns.sv $(AES_DIR)/minisoc_aes_add_round_key.sv
ROUND_TOPS   := minisoc_aes_mix_columns minisoc_aes_inv_mix_columns minisoc_aes_add_round_key
ROUND_TB     := $(AES_TB_DIR)/tb_minisoc_aes_round.sv
ROUND_TB_TOP := tb_minisoc_aes_round

.PHONY: all sim lint sim_aes lint_aes sim_round lint_round regress clean help

all: sim

$(SIM_OUT):
	mkdir -p $(SIM_OUT)

sim: $(SIM_OUT)
	cd $(SIM_OUT) && \
	vcs -full64 -sverilog -timescale=1ns/1ps \
		-debug_access+all -kdb \
		$(EXAMPLE_RTL) $(EXAMPLE_TB) \
		-top $(EXAMPLE_TOP) -o simv \
		| tee vcs_compile.log && \
	./simv | tee sim.log

lint: $(SIM_OUT)
	cd $(SIM_OUT) && \
	vcs -full64 -sverilog +lint=all,noVCDE \
		$(EXAMPLE_RTL) -top counter -o simv_lint \
		| tee lint.log

sim_aes: $(SIM_OUT)
	set -o pipefail; \
	cd $(SIM_OUT) && \
	vcs -full64 -sverilog -timescale=1ns/1ps \
		-debug_access+all -kdb +incdir+$(AES_TB_DIR) \
		$(AES_RTL) $(AES_TB) \
		-top $(AES_TB_TOP) -o simv_aes \
		| tee vcs_compile_aes.log && \
	./simv_aes | tee sim_aes.log
	mkdir -p $(REPORT_DIR) && cp $(SIM_OUT)/sim_aes.log $(REPORT_DIR)/sim_aes.rpt
	@grep -q '^PASS' $(SIM_OUT)/sim_aes.log || { echo "ERRO: testbench sem PASS (veja $(REPORT_DIR)/sim_aes.rpt)"; exit 1; }

lint_aes: $(SIM_OUT)
	set -o pipefail; \
	cd $(SIM_OUT) && rm -f lint_aes.log && \
	for top in $(AES_TOPS); do \
		echo "=== lint: $$top ===" | tee -a lint_aes.log; \
		vcs -full64 -sverilog -timescale=1ns/1ps +lint=all,noVCDE \
			$(AES_RTL) -top $$top -o simv_lint_$$top \
			| tee -a lint_aes.log || exit 1; \
	done
	mkdir -p $(REPORT_DIR) && cp $(SIM_OUT)/lint_aes.log $(REPORT_DIR)/lint_aes.rpt

sim_round: $(SIM_OUT)
	set -o pipefail; \
	cd $(SIM_OUT) && \
	vcs -full64 -sverilog -timescale=1ns/1ps \
		-debug_access+all -kdb +incdir+$(AES_TB_DIR) \
		$(ROUND_RTL) $(ROUND_TB) \
		-top $(ROUND_TB_TOP) -o simv_round \
		| tee vcs_compile_round.log && \
	./simv_round | tee sim_round.log
	mkdir -p $(REPORT_DIR) && cp $(SIM_OUT)/sim_round.log $(REPORT_DIR)/sim_round.rpt
	@grep -q '^PASS' $(SIM_OUT)/sim_round.log || { echo "ERRO: testbench sem PASS (veja $(REPORT_DIR)/sim_round.rpt)"; exit 1; }

lint_round: $(SIM_OUT)
	set -o pipefail; \
	cd $(SIM_OUT) && rm -f lint_round.log && \
	for top in $(ROUND_TOPS); do \
		echo "=== lint: $$top ===" | tee -a lint_round.log; \
		vcs -full64 -sverilog -timescale=1ns/1ps +lint=all,noVCDE \
			$(ROUND_RTL) -top $$top -o simv_lint_$$top \
			| tee -a lint_round.log || exit 1; \
	done
	mkdir -p $(REPORT_DIR) && cp $(SIM_OUT)/lint_round.log $(REPORT_DIR)/lint_round.rpt

regress: sim lint sim_aes lint_aes sim_round lint_round

clean:
	rm -rf $(BUILD_DIR) *.log simv* csrc ucli.key vc_hdrs.h DVEfiles verdiLog novas.*

help:
	@echo "Alvos disponiveis:"
	@echo "  make sim      - compila e simula o exemplo minimo"
	@echo "  make lint     - roda lint no exemplo minimo"
	@echo "  make sim_aes  - testbench de S-box, SubBytes e ShiftRows"
	@echo "  make lint_aes - lint das transformacoes do AES"
	@echo "  make sim_round  - testbench de MixColumns, AddRoundKey e AES-128 completo"
	@echo "  make lint_round - lint dos modulos da Semana 3"
	@echo "  make regress  - roda sim, lint, sim_aes, lint_aes, sim_round e lint_round"
	@echo "  make clean    - remove artefatos gerados"