# ==========================================
# AES + SPI — Projeto RTL Design Track
# Makefile — Semanas 1, 2, 3 e 4 (VCS)
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
AES_RTL     := $(AES_DIR)/minisoc_aes_sbox.sv $(AES_DIR)/minisoc_aes_inv_sbox.sv $(AES_DIR)/minisoc_aes_sub_bytes.sv $(AES_DIR)/minisoc_aes_shift_rows.sv $(AES_DIR)/minisoc_aes_inv_sub_bytes.sv $(AES_DIR)/minisoc_aes_inv_shift_rows.sv
AES_TOPS    := minisoc_aes_sub_bytes minisoc_aes_shift_rows minisoc_aes_inv_sub_bytes minisoc_aes_inv_shift_rows
AES_TB_DIR  := $(TB_DIR)/minisoc_aes
AES_TB      := $(AES_TB_DIR)/tb_minisoc_aes_sub_shift.sv
AES_TB_TOP  := tb_minisoc_aes_sub_shift

# Semana 3: MixColumns, AddRoundKey, InvMixColumns
ROUND_RTL    := $(AES_RTL) $(AES_DIR)/minisoc_aes_mix_columns.sv $(AES_DIR)/minisoc_aes_inv_mix_columns.sv $(AES_DIR)/minisoc_aes_add_round_key.sv
ROUND_TOPS   := minisoc_aes_mix_columns minisoc_aes_inv_mix_columns minisoc_aes_add_round_key
ROUND_TB     := $(AES_TB_DIR)/tb_minisoc_aes_round.sv
ROUND_TB_TOP := tb_minisoc_aes_round

# Semana 4: Expansao de chave e Datapath (com testbenches modulares)
DP_RTL       := $(ROUND_RTL) $(AES_DIR)/minisoc_aes_key_exp.sv $(AES_DIR)/minisoc_aes_dp.sv
DP_TOPS      := minisoc_aes_key_exp minisoc_aes_dp
TB_KEY_EXP   := $(AES_TB_DIR)/tb_minisoc_aes_key_exp.sv
TB_DP        := $(AES_TB_DIR)/tb_minisoc_aes_dp.sv
TB_W04_TOP   := $(AES_TB_DIR)/tb_minisoc_aes_w04.sv

.PHONY: all sim lint sim_aes lint_aes sim_round lint_round sim_key_exp sim_dp_unit sim_dp lint_dp regress clean help

all: sim_dp

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

# Alvos unitarios de debug da Semana 4
sim_key_exp: $(SIM_OUT)
	set -o pipefail; \
	cd $(SIM_OUT) && \
	vcs -full64 -sverilog -timescale=1ns/1ps \
		-debug_access+all -kdb +incdir+$(AES_TB_DIR) \
		$(DP_RTL) $(TB_KEY_EXP) \
		-top tb_minisoc_aes_key_exp -o simv_key_exp \
		| tee vcs_compile_key_exp.log && \
	./simv_key_exp | tee sim_key_exp.log

sim_dp_unit: $(SIM_OUT)
	set -o pipefail; \
	cd $(SIM_OUT) && \
	vcs -full64 -sverilog -timescale=1ns/1ps \
		-debug_access+all -kdb +incdir+$(AES_TB_DIR) \
		$(DP_RTL) $(TB_DP) \
		-top tb_minisoc_aes_dp -o simv_dp_unit \
		| tee vcs_compile_dp_unit.log && \
	./simv_dp_unit | tee sim_dp_unit.log

# Alvo integrado da Semana 4 (instancia tb_key_exp e tb_dp em tb_minisoc_aes_w04)
sim_dp: $(SIM_OUT)
	set -o pipefail; \
	cd $(SIM_OUT) && \
	vcs -full64 -sverilog -timescale=1ns/1ps \
		-debug_access+all -kdb +incdir+$(AES_TB_DIR) \
		$(DP_RTL) $(TB_KEY_EXP) $(TB_DP) $(TB_W04_TOP) \
		-top tb_minisoc_aes_w04 -o simv_dp \
		| tee vcs_compile_dp.log && \
	./simv_dp | tee sim_dp.log
	mkdir -p $(REPORT_DIR) && cp $(SIM_OUT)/sim_dp.log $(REPORT_DIR)/sim_dp.rpt
	@grep -q '^PASS' $(SIM_OUT)/sim_dp.log || { echo "ERRO: testbench sem PASS (veja $(REPORT_DIR)/sim_dp.rpt)"; exit 1; }

lint_dp: $(SIM_OUT)
	set -o pipefail; \
	cd $(SIM_OUT) && rm -f lint_dp.log && \
	for top in $(DP_TOPS); do \
		echo "=== lint: $$top ===" | tee -a lint_dp.log; \
		vcs -full64 -sverilog -timescale=1ns/1ps +lint=all,noVCDE \
			$(DP_RTL) -top $$top -o simv_lint_$$top \
			| tee -a lint_dp.log || exit 1; \
	done
	mkdir -p $(REPORT_DIR) && cp $(SIM_OUT)/lint_dp.log $(REPORT_DIR)/lint_dp.rpt

regress: sim lint sim_aes lint_aes sim_round lint_round sim_dp lint_dp

clean:
	rm -rf $(BUILD_DIR) *.log simv* csrc ucli.key vc_hdrs.h DVEfiles verdiLog novas.*

help:
	@echo "Alvos disponiveis:"
	@echo "  make sim         - compila e simula o exemplo minimo"
	@echo "  make lint        - roda lint no exemplo minimo"
	@echo "  make sim_aes     - testbench de S-box, SubBytes e ShiftRows (Semana 2)"
	@echo "  make lint_aes    - lint dos modulos da Semana 2"
	@echo "  make sim_round   - testbench de MixColumns e AddRoundKey (Semana 3)"
	@echo "  make lint_round  - lint dos modulos da Semana 3"
	@echo "  make sim_key_exp - testbench isolado de expansao de chave (debug Semana 4)"
	@echo "  make sim_dp_unit - testbench isolado do datapath (debug Semana 4)"
	@echo "  make sim_dp      - testbench hierarquico completo da Semana 4 (key_exp + dp)"
	@echo "  make lint_dp     - lint dos modulos da Semana 4"
	@echo "  make regress     - roda todos os testes das Semanas 1 a 4"
	@echo "  make clean       - remove artefatos gerados"
