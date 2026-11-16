# Cadence Xcelium (xrun) Master Argument File for FFA Accelerator UVM 1.2
-64bit
-uvm
-uvmhome CDNS-1.2
-sv
-timescale 1ns/1ps
-access +rwc
-licqueue
-nowarn DSEMEL
-nowarn SPDUSD

# Include Directories
+incdir+../../Design
+incdir+..
+incdir+../src
+incdir+../src/tests

# RTL Design Files
../../Design/ffa_engine.v
../../Design/uart_tx.v
../../Design/top.v

# UVM Testbench & Interface Files (Inside uvm/)
../ffa_if.sv
../ffa_sva.sv
../src/ffa_types.sv
../src/ffa_pkg.sv
../tb_top.sv

# Coverage Instrumentation (Code + Functional Coverage)
-coverage all
-covoverwrite
-covworkdir cov_work

# Default Simulation Controls
+UVM_TESTNAME=ffa_master_verification_test
+UVM_VERBOSITY=UVM_LOW
