# ==============================================================================
# Makefile: FFA Accelerator UVM 1.2 Verification Architecture
# Single Command Execution for Cadence Xcelium & Unified Verification Suite
# ==============================================================================

TEST        ?= ffa_master_verification_test
VERBOSITY   ?= UVM_LOW
SEED        ?= 1
COV_WORK    ?= cov_work

# Cadence Tool Executables
XRUN        = xrun
IMC         = imc
SIMVISION   = simvision
GTKWAVE     = gtkwave

.PHONY: all help verify re rebuild wave cov clean regression

all: verify

help:
	@echo "========================================================================"
	@echo " FFA Accelerator UVM 1.2 Verification Commands"
	@echo "========================================================================"
	@echo "  make verify   : [SINGLE COMMAND] Runs the entire verification architecture"
	@echo "                  (Pre-cleans, compiles, runs SVA + Scoreboard + ATNF DB + Coverage)"
	@echo "  make clean    : Cleans all previous simulation artifacts, databases, and logs"
	@echo "  make re       : Clean rebuild & verify from scratch"
	@echo "  make wave     : [WAVEFORM] Runs with waveform dumping & opens GUI"
	@echo "  make cov      : [COVERAGE GUI] Opens Cadence IMC coverage browser"
	@echo "========================================================================"

# ------------------------------------------------------------------------------
# 1. Single Command: Run Full Verification Architecture + ATNF Matching + Coverage
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
		-coverage all \
		-covoverwrite \
		-covworkdir $(COV_WORK) \
		-covtest $(TEST) \
		-l xrun_verify.log
	@echo "========================================================================"
	@echo " Generating Coverage Summary via Cadence IMC..."
	@echo "========================================================================"
	-$(IMC) -batch -exec "load $(COV_WORK)/scope/$(TEST); report -summary -metrics all -output cov_summary.txt; exit" || true
	@if [ -f cov_summary.txt ]; then \
		echo "--- Coverage Summary (cov_summary.txt) ---"; \
		cat cov_summary.txt | head -n 30; \
	fi
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
# 3. Interactive Coverage Browser
# ------------------------------------------------------------------------------
cov:
	@echo "Opening Cadence IMC Coverage GUI..."
	$(IMC) -load $(COV_WORK)/scope/$(TEST) &

# ------------------------------------------------------------------------------
# 4. Thorough Clean: Wipes all simulation databases, locks, and history
# ------------------------------------------------------------------------------
clean:
	@echo "[CLEAN] Purging all previous simulation artifacts, databases, and logs..."
	rm -rf INCA_libs xcelium.d $(COV_WORK) *.log *.history *.key *.shm *.vcd waves* cov_summary.txt .simvision* .bpad* *.diag *.dsn *.trn *.so
	@echo "[CLEAN] Workspace is pristine."
