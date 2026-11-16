# ==============================================================================
# Makefile: FFA Accelerator UVM 1.2 Verification Architecture
# Single Command Execution for Cadence Xcelium & Unified Verification Suite
# ==============================================================================

TEST        ?= ffa_master_verification_test
VERBOSITY   ?= UVM_LOW
SEED        ?= 1

# Cadence Tool Executables
XRUN        = xrun
SIMVISION   = simvision
GTKWAVE     = gtkwave

.PHONY: all help verify re rebuild wave clean regression

all: verify

help:
	@echo "========================================================================"
	@echo " FFA Accelerator UVM 1.2 Verification Commands"
	@echo "========================================================================"
	@echo "  make verify   : [SINGLE COMMAND] Runs the entire verification architecture"
	@echo "                  (Pre-cleans, compiles, runs SVA + Scoreboard + ATNF DB)"
	@echo "  make clean    : Cleans all previous simulation artifacts, databases, and logs"
	@echo "  make re       : Clean rebuild & verify from scratch"
	@echo "  make wave     : [WAVEFORM] Runs with waveform dumping & opens GUI"
	@echo "========================================================================"

# ------------------------------------------------------------------------------
# 1. Single Command: Run Full Verification Architecture + ATNF Matching
# ------------------------------------------------------------------------------
verify: clean
	@echo "========================================================================"
	@echo " Launching Full FFA Accelerator Verification Architecture (Cadence Xcelium)"
	@echo " Test: $(TEST) | Seed: $(SEED)"
	@echo "========================================================================"
	$(XRUN) -f xrun_args.f \
		+UVM_TESTNAME=$(TEST) \
		+UVM_VERBOSITY=$(VERBOSITY) \
		-svseed $(SEED) \
		-l xrun_verify.log
	@echo "========================================================================"
	@echo " Verification Complete. Full log: xrun_verify.log"
	@echo "========================================================================"

# Clean Rebuild
re: clean verify
rebuild: clean verify

# ------------------------------------------------------------------------------
# 2. Separate Command: Waveform Generation & Viewer
# ------------------------------------------------------------------------------
wave:
	@echo "========================================================================"
	@echo " Running Simulation with Waveform Dumping..."
	@echo "========================================================================"
	$(XRUN) -f xrun_args.f \
		+UVM_TESTNAME=$(TEST) \
		+define+DUMP_WAVES \
		-access +rwc \
		-linedebug \
		-l xrun_wave.log
	@echo "========================================================================"
	@echo " Opening Waveform in Cadence SimVision / GTKWave..."
	@echo "========================================================================"
	@if command -v $(SIMVISION) >/dev/null 2>&1; then \
		$(SIMVISION) waves.shm & \
	elif command -v $(GTKWAVE) >/dev/null 2>&1; then \
		$(GTKWAVE) ffa_waves.vcd & \
	else \
		echo "[INFO] Waveform generated: ffa_waves.vcd and waves.shm"; \
		echo "Open with: simvision waves.shm OR gtkwave ffa_waves.vcd"; \
	fi

# ------------------------------------------------------------------------------
# 3. Thorough Clean: Wipes all simulation databases, locks, and history
# ------------------------------------------------------------------------------
clean:
	@echo "[CLEAN] Purging all previous simulation artifacts, databases, and logs..."
	rm -rf INCA_libs xcelium.d cov_work *.log *.history *.key *.shm *.vcd waves* cov_summary.txt .simvision* .bpad* *.diag *.dsn *.trn *.so
	@echo "[CLEAN] Workspace is pristine."
