# ==============================================================================
# Root Makefile: FPGA-Based Fast Folding Algorithm (FFA) Pulsar Decoder
# ==============================================================================

.PHONY: all verify wave dashboard regression clean clean_all re help

all: verify

help:
	@echo "========================================================================"
	@echo " FPGA-Based FFA Pulsar Decoder — Command Reference"
	@echo "========================================================================"
	@echo "  make verify   : [SINGLE COMMAND] Run full UVM verification architecture"
	@echo "                  (Pre-cleans stale runs, compiles, runs SVA + ATNF + Dashboard)"
	@echo "  make dashboard: Re-generate and launch HTML dashboard in browser"
	@echo "  make clean    : Wipe all previous simulation artifacts, databases & logs"
	@echo "  make re       : Clean rebuild from scratch"
	@echo "  make wave     : [WAVEFORM] Run and launch SimVision / GTKWave"
	@echo "========================================================================"

verify:
	@$(MAKE) -C uvm/sim verify

dashboard:
	@$(MAKE) -C uvm/sim dashboard

re: clean verify

wave:
	@$(MAKE) -C uvm/sim wave

regression:
	@$(MAKE) -C uvm/sim regression

clean:
	@echo "[CLEAN] Purging simulation artifacts and databases..."
	@$(MAKE) -C uvm/sim clean
	rm -rf *.vvp *.vcd Output/*.vcd Output/*.txt waves* INCA_libs xcelium.d cov_work *.log *.history *.key .simvision*
	@echo "[CLEAN] Complete."

clean_all: clean
