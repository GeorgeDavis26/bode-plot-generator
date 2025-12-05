// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/22/2025

// bode_interface_tb.sv

/////////////////////////////////////////////
// Bode Plot Generator testbench 
// tests the interface between the FPGA and MCU
/////////////////////////////////////////////

`timescale 1ns/1ps

module bode_interface_tb;

    // Parameters
    parameter DAC_WIDTH = 8;
    parameter PHASE_WIDTH = 32;
    parameter DAC_MIDPOINT = 8'h80;

    // Signals
    logic                   clk;
    logic                   reset;
    logic [DAC_WIDTH-1:0]   dac_out;
    logic [PHASE_WIDTH-1:0] phase_inc;
    logic                   sweep_done;
    logic                   half_flag;
    logic                   quarter_flag;

    // Outputs
    logic zero_cross_gpio;
    logic freq_change_gpio;
    logic sweep_done_gpio;
    logic amp_gpio1;
    logic amp_gpio2;

    // Instantiate bode interface
    bode_interface #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .DAC_MIDPOINT(DAC_MIDPOINT)
    ) dut (
        .clk(clk),
        .reset(reset),
        .dac_out(dac_out),
        .phase_inc(phase_inc),
        .sweep_done(sweep_done),
        .half_flag(half_flag),
        .quarter_flag(quarter_flag),
        .zero_cross_gpio(zero_cross_gpio),
        .freq_change_gpio(freq_change_gpio),
        .sweep_done_gpio(sweep_done_gpio),
        .amp_gpio1(amp_gpio1),
        .amp_gpio2(amp_gpio2)
    );

    // Clock generation
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // Test procedure
    initial begin
        // Waveform dumping
        $dumpfile("bode_interface.vcd");
        $dumpvars(0, bode_interface_tb);

        // Initialize inputs
        reset = 0;
        dac_out = DAC_MIDPOINT;
        phase_inc = 0;
        sweep_done = 0;
        half_flag = 1;
        quarter_flag = 1;

        // Apply reset
        #20;
        reset = 1;
        #20;

        // Test zero crossing detection
        dac_out = DAC_MIDPOINT - 5;  // Below midpoint
        #10;
        dac_out = DAC_MIDPOINT + 5;  // Above midpoint
        #10;

        // Test frequency change detection
        phase_inc = 32'h0000_1000;  // Set phase increment
        #10;
        phase_inc = 32'h0000_2000;  // Change phase increment
        #10;

        // Test sweep done signal
        sweep_done = 1;
        #10;
        sweep_done = 0;
        #10;

        // Test amplitude half attenuation
        half_flag = 0;
        #20;
        half_flag = 1;
        #10;

        // Test amplitude coquarter attenuation
        quarter_flag = 0;
        #20;
        quarter_flag = 1;
        #50;

        // Test completed
        $display("Test completed");
        $finish;
    end

endmodule