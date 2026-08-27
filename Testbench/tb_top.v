// File: tb_top.v
// Description: Final verified testbench with the correct simulation duration.

`timescale 1ns / 1ps

module tb_top;

    // ## Testbench Parameters ##
    parameter DATA_BUFFER_SIZE   = 1024;    // Must match ffa_engine.DATA_BUFFER_SIZE
    parameter CLK_PERIOD         = 20;      // ns, for 50 MHz clock
    parameter PULSAR_PERIOD_US   = 1600;    // us, the period we are simulating (adjusted for test)
    parameter PULSE_WIDTH_US     = 80;      // us

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

        // 1. Apply Reset - FIX: Ensure reset is held before any activity
        rst = 1'b1;
        adc_data_in = 8'h00;
        
        // Wait for 20 clock cycles to ensure stable reset
        repeat(20) @(posedge clk_50mhz);
        
        $display("TB INFO: Releasing reset at %0t ns.", $time);
        rst = 1'b0;
        
        // Small delay after reset release
        repeat(5) @(posedge clk_50mhz);
        
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
        // The FFA engine needs time for folding (2048 periods * 256 bins) and peak detection
        #500_000_000; // Wait 500ms to allow full processing

        $display("-----------------------------------------");
        $display("--- Simulation Finished ---");
        $finish;
    end

    // ## UART Output Monitor ##
    reg [31:0] uart_bit_count;
    reg [7:0] uart_byte;
    integer bit_idx;
    
    always @(negedge uart_tx_pin) begin
        if (rst === 1'b0) begin
            $display(" UART START BIT DETECTED at %0t ns!", $time);
            
            // Bit time = 5208 clocks * 20ns = 104160 ns
            // Wait half bit time to sample in middle of start bit
            #52080;
            
            // Sample 8 bits of start byte (0xAA LSB-first)
            uart_byte = 8'h00;
            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                #104160;  // One full bit period
                uart_byte[bit_idx] = uart_tx_pin;
            end
            
            if (uart_byte == 8'hAA) begin
                $display("   --> Start byte 0xAA confirmed (received: 0x%02H)", uart_byte);
                
                // Skip stop bit (sample in middle)
                #52080;
                
                // Skip start bit of data frame
                #104160;
                
                // Sample 32-bit period data
                uart_bit_count = 32'd0;
                for (bit_idx = 0; bit_idx < 32; bit_idx = bit_idx + 1) begin
                    #104160;
                    uart_bit_count[bit_idx] = uart_tx_pin;
                end
                
                $display("   --> Received period value: %d", uart_bit_count);
            end else begin
                $display("   --> Start byte received: 0x%02H (expected 0xAA)", uart_byte);
                #52080;  // Middle of stop bit
                #104160; // Skip to start bit of data
                #104160; // Skip start bit
                
                uart_bit_count = 32'd0;
                for (bit_idx = 0; bit_idx < 32; bit_idx = bit_idx + 1) begin
                    #104160;
                    uart_bit_count[bit_idx] = uart_tx_pin;
                end
                $display("   --> Received period value: %d", uart_bit_count);
            end
        end
    end

endmodule

