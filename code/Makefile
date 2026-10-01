#==============================================================================
# PE_MP_v1 VCS / Verdi Makefile
#==============================================================================

SHELL := /bin/bash

# Run this Makefile from the pe_v1 directory in the Linux guest:
#   cd /mnt/hgfs/share/tpu/tpu/pe_v1
#   make run

SIM      ?= vcs
TOP      ?= tb_pe_mp_v1_smoke
SEED     ?= 1
GUI      ?= verdi

VCS      ?= vcs
VERDI    ?= verdi
DVE      ?= dve
LMUTIL   ?= $(if $(SCL_HOME),$(SCL_HOME)/linux64/bin/lmutil,lmutil)

VCS_OPTS ?= -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb
RUN_OPTS ?= +ntb_random_seed=$(SEED)
VCS_LIC_WAIT_MIN ?= 10
BUILD_DIR ?= /tmp/pe_v1_vcs_$(USER)
PROJECT_DIR := $(CURDIR)
WAVE_FILE ?= pe_mp_v1.fsdb
NOVAS_PLI_DIR ?= $(VERDI_HOME)/share/PLI/VCS/linux64
VCS_FSDB_OPTS ?= +define+FSDB -P $(NOVAS_PLI_DIR)/novas.tab $(NOVAS_PLI_DIR)/pli.a

RTL_SRCS := \
	fix2fp.v \
	fp2fix.v \
	fp32_adder.v \
	fp32_multi.v \
	PE_MP_v1.v

TB_SRCS := \
	tb_pe_mp_v1_smoke.v

ALL_SRCS := $(RTL_SRCS) $(TB_SRCS)

.PHONY: all env lic compile run run_wait wave verdi_wave sim verdi dve eda clean help

all: compile

# Print the EDA commands and versions visible in the current shell.
env:
	@echo "PWD      = $$PWD"
	@echo "VCS      = $$(command -v $(VCS) || true)"
	@echo "VERDI    = $$(command -v $(VERDI) || true)"
	@echo "DVE      = $$(command -v $(DVE) || true)"
	@echo "LMUTIL   = $$(command -v $(LMUTIL) || echo $(LMUTIL))"
	@echo "VCS_HOME = $${VCS_HOME:-}"
	@echo "VERDI_HOME = $${VERDI_HOME:-}"
	@echo "SCL_HOME = $${SCL_HOME:-}"
	@echo "SNPSLMD_LICENSE_FILE = $${SNPSLMD_LICENSE_FILE:-}"
	@$(VCS) -ID 2>&1 | sed -n '1,12p' || true

# Check whether the Synopsys license server is visible from this shell.
lic:
	@echo "Checking Synopsys license environment..."
	@( \
		echo "PWD=$$PWD"; \
		echo "SNPSLMD_LICENSE_FILE=$${SNPSLMD_LICENSE_FILE:-}"; \
		echo "LM_LICENSE_FILE=$${LM_LICENSE_FILE:-}"; \
		echo "SCL_HOME=$${SCL_HOME:-}"; \
		echo ""; \
		echo "[license daemons]"; \
		ps -ef | grep -E 'lmgrd|snpslmd' | grep -v grep || true; \
		echo ""; \
		echo "[lmstat]"; \
		if [ -x "$(LMUTIL)" ]; then \
			"$(LMUTIL)" lmstat -a -c "$${SNPSLMD_LICENSE_FILE:-$${LM_LICENSE_FILE:-}}" | sed -n '1,120p'; \
		else \
			lmutil lmstat -a -c "$${SNPSLMD_LICENSE_FILE:-$${LM_LICENSE_FILE:-}}" | sed -n '1,120p'; \
		fi \
	) 2>&1 | tee license.log

# Compile PE_MP_v1 and the smoke testbench with VCS.
compile:
	@echo "Preparing local VCS build directory: $(BUILD_DIR)"
	@mkdir -p $(BUILD_DIR)
	@cp -f $(ALL_SRCS) $(BUILD_DIR)/
	@cd $(BUILD_DIR) && rm -rf csrc simv simv.daidir simv.vdb DVEfiles verdiLog novas.* novas.conf *.log *.key *.vpd *.fsdb ucli.key
	@echo "Compiling $(TOP) with VCS..."
	@cd $(BUILD_DIR) && $(VCS) $(VCS_OPTS) $(ALL_SRCS) -top $(TOP) -l compile.log; \
	status=$$?; \
	cp -f $(BUILD_DIR)/compile.log $(PROJECT_DIR)/compile.log 2>/dev/null || true; \
	exit $$status

# Queue for a busy VCS license. This only helps when the license server is up.
run_wait: VCS_OPTS += -licwait $(VCS_LIC_WAIT_MIN)
run_wait: run

# Compile and run the smoke simulation. The testbench prints PASS/FAIL.
run: compile
	@echo "Running $(TOP)..."
	@cd $(BUILD_DIR) && ./simv $(RUN_OPTS) -l run.log; \
	status=$$?; \
	cp -f $(BUILD_DIR)/run.log $(PROJECT_DIR)/run.log 2>/dev/null || true; \
	cp -f $(BUILD_DIR)/*.fsdb $(PROJECT_DIR)/ 2>/dev/null || true; \
	ls -lh $(BUILD_DIR)/*.fsdb 2>/dev/null || true; \
	exit $$status

wave: VCS_OPTS += $(VCS_FSDB_OPTS)
wave: run

sim: run

# Open Verdi with the generated FSDB waveform and the local build database.
verdi_wave:
	@echo "Opening Verdi waveform: $(WAVE_FILE)"
	@if [ ! -f "$(WAVE_FILE)" ]; then \
		echo "Waveform $(WAVE_FILE) not found. Run 'make wave' first."; \
		exit 1; \
	fi
	@cd $(BUILD_DIR) && $(VERDI) -sv $(ALL_SRCS) -top $(TOP) -ssf $(CURDIR)/$(WAVE_FILE) -nologo &

# Open Verdi for source/design browsing. This target does not require a waveform.
verdi:
	@echo "Opening Verdi..."
	$(VERDI) -sv $(ALL_SRCS) -top $(TOP) -nologo &

# Open the VCS/DVE GUI from the compiled simulation image.
dve: compile
	@echo "Opening DVE..."
	@cd $(BUILD_DIR) && ./simv -gui $(RUN_OPTS) &

eda: $(GUI)

# Remove generated simulation and GUI files from this project directory.
clean:
	rm -rf $(BUILD_DIR)
	rm -f *.log *.key *.vpd *.fsdb ucli.key novas.* novas.conf codex_*
	rm -rf csrc simv simv.daidir simv.vdb DVEfiles work
	rm -rf verdiLog 2>/dev/null || true

help:
	@echo "PE_MP_v1 VCS / Verdi Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make env       # show EDA environment"
	@echo "  make lic       # check Synopsys license server status"
	@echo "  make compile   # compile RTL + TB with VCS"
	@echo "  make run       # compile and run smoke simulation"
	@echo "  make wave      # run simulation and dump pe_mp_v1.fsdb"
	@echo "  make verdi_wave # open Verdi with pe_mp_v1.fsdb"
	@echo "  make run_wait  # wait for a busy VCS license before compiling"
	@echo "  make verdi     # open Verdi source/design browser"
	@echo "  make dve       # compile and open VCS DVE GUI"
	@echo "  make eda       # open GUI selected by GUI=verdi|dve"
	@echo "  make clean     # remove generated files"
	@echo "  make run BUILD_DIR=/tmp/my_pe_build"
	@echo ""
	@echo "Examples:"
	@echo "  make run"
	@echo "  make wave"
	@echo "  make verdi_wave"
	@echo "  make lic"
	@echo "  make run_wait VCS_LIC_WAIT_MIN=20"
	@echo "  make eda GUI=verdi"
	@echo "  make eda GUI=dve"
