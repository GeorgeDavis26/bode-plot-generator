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

    // Instantiate sweep controller
    sweep_controller #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .FULL_WAVE(FULL_WAVE),
        .LUT_FILE(LUT_FILE),
        .SAMPLES_PER_FREQ(SAMPLES_PER_FREQ),
        .PHASE_INC_MIN(PHASE_INC_MIN),
        .PHASE_INC_MAX(PHASE_INC_MAX),
        .PHASE_INC_STEP(PHASE_INC_STEP)
        ) dut (
        .clk(clk),
        .reset(reset),
        .mcu_ready(mcu_ready),
        .dac_out(dac_out),
        .sweep_done(sweep_done)
    );

    // Instantiate interface module
    bode_interface #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .DAC_MIDPOINT(DAC_MIDPOINT)
        ) dut (
        .clk(clk),
        .reset(reset),
        .dac_out(dac_out),
        .phase_inc(phase_inc),
        .sweep_done(done),
        .zero_cross_gpio(zero_cross_gpio),
        .freq_change_gpio(freq_change_gpio),
        .sweep_done_gpio(sweep_done_gpio)
    );

    // Generate clock
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // Start of tests
    initial begin

        //waveform dumping
        $dumpfile("bode_interface.vcd");
        $dumpvars(0, bode_interface_tb);

        // Initialize Inputs
        clk = 0;
        reset = 0;

        #30;
        reset = 1;  // Active low reset
        #100000000; // Run for a long time to see the frequency sweep

        reset = 0;
        #30;
        reset = 1;
        #100000000; // Run for a long time to see the frequency sweep again

        $display("Test completed");
        $finish;
    end

endmodule