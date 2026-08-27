// File: tb_top.v
// Description: Final verified testbench with the correct simulation duration.

`timescale 1ns / 1ps

module tb_top;

    // ## Testbench Parameters ##
    parameter DATA_BUFFER_SIZE   = 16384;   // Must match your ffa_engine
    parameter CLK_PERIOD         = 20;      // ns, for 50 MHz clock
    parameter PULSAR_PERIOD_US   = 1590;    // us, the period we are simulating
    parameter PULSE_WIDTH_US     = 50;      // us

      integer i;
        integer period_cycles      = (PULSAR_PERIOD_US * 1000) / CLK_PERIOD;
        integer pulse_width_cycles = (PULSE_WIDTH_US * 1000) / CLK_PERIOD;

    // ## Signals to connect to the DUT ##
    reg         clk_50mhz;
    reg         rst;
    reg  [7:0]  adc_data_in;
    wire        uart_tx_pin;

    // ## Instantiate the Device Under Test (DUT) ##
    top dut (
        .clk_50mhz   (clk_50mhz),
        .rst         (rst),
        .adc_data_in (adc_data_in),
        .uart_tx_pin (uart_tx_pin)
    );

    // ## Clock Generator ##
    initial begin
        clk_50mhz = 1'b0;
        forever #((CLK_PERIOD / 2)) clk_50mhz = ~clk_50mhz;
    end

    // ## Main Simulation Sequence ##
    initial begin
      
        $display("-----------------------------------------");
        $display("--- Simulation Starting ---");
        $display("TB INFO: Resetting the design...");

        // 1. Apply Reset
        rst = 1'b1;
        adc_data_in = 8'h00;
        #200; // Hold reset for 200 ns
        rst = 1'b0;
        $display("TB INFO: Reset released at %0t ns.", $time);
        $display("TB INFO: Starting stimulus generation to fill the FFA buffer (%0d samples)...", DATA_BUFFER_SIZE);

        // 2. Generate a finite stream of data to fill the buffer
        for (i = 0; i < DATA_BUFFER_SIZE; i = i + 1) begin
            if ((i % period_cycles) < pulse_width_cycles) begin
                adc_data_in = 8'hA0 + $urandom_range(0, 15); // Pulse data
            end else begin
                adc_data_in = 8'h10 + $urandom_range(0, 31); // Noise data
            end
            @(posedge clk_50mhz);
        end

        $display("TB INFO: Stimulus generation finished at %0t ns.", $time);
        $display("TB INFO: Waiting for DUT to process and transmit via UART...");

        // 3. Wait long enough for processing and transmission
        //    **THIS IS THE CRITICAL CORRECTION**
        #1_000_000; // Wait 1 ms. This is longer than the ~328us needed.

        $display("-----------------------------------------");
        $display("--- Simulation Finished ---");
        $finish;
    end

    // ## UART Output Monitor ##
    always @(negedge uart_tx_pin) begin
        if (rst === 1'b0) begin
            $display(" UART START BIT DETECTED at %0t ns!", $time);
            #10; // Small delay to stabilize
            $display("   --> DUT is transmitting data");
        end
    end

endmodule

