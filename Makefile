# ==============================================================================
# Root Makefile: FPGA-Based Fast Folding Algorithm (FFA) Pulsar Decoder
# ==============================================================================

.PHONY: all verify wave cov regression clean help

all: verify

help:
	@echo "========================================================================"
	@echo " FPGA-Based FFA Pulsar Decoder — Command Reference"
	@echo "========================================================================"
	@echo "  make verify   : [SINGLE COMMAND] Run full UVM verification architecture"
	@echo "                  (Stimulus, SVA, Scoreboard, ATNF Matches, Coverage)"
	@echo "  make wave     : [WAVEFORM] Run and launch SimVision / GTKWave"
	@echo "  make cov      : [COVERAGE] Open Cadence IMC Coverage GUI"
	@echo "  make clean    : Clean all simulation and coverage directories"
	@echo "========================================================================"

verify:
	@$(MAKE) -C uvm/sim verify

wave:
	@$(MAKE) -C uvm/sim wave

cov:
	@$(MAKE) -C uvm/sim cov

regression:
	@$(MAKE) -C uvm/sim regression

clean:
	@$(MAKE) -C uvm/sim clean
	rm -rf *.vvp *.vcd Output/*.vcd Output/*.txt
