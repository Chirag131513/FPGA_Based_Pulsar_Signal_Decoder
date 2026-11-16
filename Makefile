# ==============================================================================
# Root Makefile: FPGA-Based Fast Folding Algorithm (FFA) Pulsar Decoder
# ==============================================================================

.PHONY: all verify wave cov regression clean clean_all re help

all: verify

help:
	@echo "========================================================================"
	@echo " FPGA-Based FFA Pulsar Decoder — Command Reference"
	@echo "========================================================================"
	@echo "  make verify   : [SINGLE COMMAND] Run full UVM verification architecture"
	@echo "                  (Pre-cleans stale runs, compiles, runs SVA + ATNF + Cov)"
	@echo "  make clean    : Wipe all previous simulation artifacts, databases & logs"
	@echo "  make re       : Clean rebuild from scratch"
	@echo "  make wave     : [WAVEFORM] Run and launch SimVision / GTKWave"
	@echo "  make cov      : [COVERAGE] Open Cadence IMC Coverage GUI"
	@echo "========================================================================"

verify:
	@$(MAKE) -C uvm/sim verify

re: clean verify

wave:
	@$(MAKE) -C uvm/sim wave

cov:
	@$(MAKE) -C uvm/sim cov

regression:
	@$(MAKE) -C uvm/sim regression

clean:
	@echo "[CLEAN] Purging simulation artifacts and databases..."
	@$(MAKE) -C uvm/sim clean
	rm -rf *.vvp *.vcd Output/*.vcd Output/*.txt waves* INCA_libs xcelium.d cov_work *.log *.history *.key .simvision*
	@echo "[CLEAN] Complete."

clean_all: clean
