// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/20/2025

// sweep_controller_tb.sv

/////////////////////////////////////////////
// Sweep Controller testbench
/////////////////////////////////////////////

`timescale 1ns/1ps

module sweep_controller_tb;

    // Parameters
    localparam DAC_WIDTH   = 8;
    localparam PHASE_WIDTH = 32;
    localparam FULL_WAVE   = 256;
    localparam LUT_FILE    = "dds_lut.txt";

    localparam SAMPLES_PER_FREQ = 1024;      // Number of samples per frequency
    localparam PHASE_INC_MIN = 8947;         // Minimum phase increment (~100 Hz)
    localparam PHASE_INC_MAX = 89478485;     // Maximum phase increment (~1 MHz)
    localparam PHASE_INC_STEP = 8947;        // Step size for phase increment (~100 Hz steps)
    
    // Signals
    logic                   clk;
    logic                   reset;
    logic [PHASE_WIDTH-1:0] phase_inc;
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
        .phase_inc(phase_inc),
        .dac_out(dac_out)
    );

    // Generate clock
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // Start of tests
    initial begin

        //waveform dumping
        $dumpfile("sweep_controller.vcd");
        $dumpvars(0, sweep_controller_tb);

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