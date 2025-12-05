// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 12/2/2025

// dds_dac_tb.sv

/////////////////////////////////////////////
// DDS and DAC interface testbench
// Tests full amplitude and half amplitude sweeps
/////////////////////////////////////////////

`timescale 1ns/1ps

module dds_dac_tb;

    // Parameters
    localparam DAC_WIDTH   = 8;
    localparam PHASE_WIDTH = 32;
    localparam FULL_WAVE   = 256;
    localparam LUT_FILE    = "dds_lut.txt";
    localparam DAC_MIDPOINT = 8'h80;

    // Smaller numbers for tb
    localparam PHASE_INC_MIN = 1000;          // Minimum phase increment 
    localparam PHASE_INC_MAX = 100000;        // Maximum phase increment 

    // Decade boundaries for phase increments
    localparam PHASE_INC_1KHZ = 1000;         // 1 kHz boundary
    localparam PHASE_INC_10KHZ = 10000;       // 10 kHz boundary
    
    // Step sizes for each decade
    localparam PHASE_INC_STEP_100HZ = 1000;   // Small steps in first decade
    localparam PHASE_INC_STEP_1KHZ = 10000;   // Medium steps in second decade
    localparam PHASE_INC_STEP_10KHZ = 100000; // Large steps in third decade
    
    // Signals
    logic                   clk;
    logic                   reset;
    logic                   mcu_ready;
    logic                   mcu_done;
    logic                   full_flag;
    logic                   half_flag;
    logic [DAC_WIDTH-1:0]   dac_data;
    logic                   dac_wr;
    logic                   sweep_done;
    logic [PHASE_WIDTH-1:0] current_phase_inc;

    // Instantiate dds_dac
    dds_dac #(
        . DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .FULL_WAVE(FULL_WAVE),
        .LUT_FILE(LUT_FILE),
        .DAC_MIDPOINT(DAC_MIDPOINT),
        .PHASE_INC_MIN(PHASE_INC_MIN),
        .PHASE_INC_MAX(PHASE_INC_MAX),
        .PHASE_INC_1KHZ(PHASE_INC_1KHZ),
        .PHASE_INC_10KHZ(PHASE_INC_10KHZ),
        .PHASE_INC_STEP_100HZ(PHASE_INC_STEP_100HZ),
        . PHASE_INC_STEP_1KHZ(PHASE_INC_STEP_1KHZ),
        . PHASE_INC_STEP_10KHZ(PHASE_INC_STEP_10KHZ)
    ) dut (
        .clk(clk),
        .reset(reset),
        .mcu_ready(mcu_ready),
        .mcu_done(mcu_done),
        .full_flag(full_flag),
        .half_flag(half_flag),
        .dac_data(dac_data),
        .dac_wr(dac_wr),
        . sweep_done(sweep_done),
        .current_phase_inc(current_phase_inc)
    );

    // Generate clock
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // Task to simulate one frequency step
    task simulate_frequency_step();
        begin
            // MCU is ready
            #10;
            mcu_ready = 1;
            #10;
            mcu_ready = 0;

            // Wait for MCU to collect data
            #10000000;
            mcu_done = 1;
            #10;
            mcu_done = 0;

            // Display current phase increment and DAC output
            $display("Time: %0t | Phase Inc: %0d | DAC Output: %h", $time, current_phase_inc, dac_data);
        end
    endtask

    // Start of tests
    initial begin

        // Waveform dumping
        $dumpfile("dds_dac.vcd");
        $dumpvars(0, dds_dac_tb);

        // Initialize Inputs
        clk = 0;
        mcu_ready = 0;
        mcu_done = 0;
        reset = 0;
        full_flag = 0;
        half_flag = 0;

        #20;

        // ===== FULL AMPLITUDE SWEEP =====
        $display("\n=== Starting FULL Amplitude Sweep ===");
        full_flag = 1;
        half_flag = 0;
        
        reset = 1;  // Active low reset
        #20;

        // Simulate all frequency steps
        repeat (30) begin
            simulate_frequency_step();
        end

        // Wait for sweep_done
        wait(sweep_done);
        $display("Full amplitude sweep done\n");

        #1000;

        // ===== HALF AMPLITUDE SWEEP =====
        $display("=== Starting HALF Amplitude Sweep ===");
        full_flag = 0;
        half_flag = 1;
        
        reset = 0;
        #20;
        reset = 1;
        #20;

        // Simulate all frequency steps
        repeat (30) begin
            simulate_frequency_step();
        end

        // Wait for sweep_done
        wait(sweep_done);
        $display("Half amplitude sweep done\n");

        if (current_phase_inc == PHASE_INC_MAX) begin
            $display("PASS: Final phase increment matches expected value");
        end else begin
            $display("FAIL: Final phase increment does not match expected value");
        end

        $display("Test completed");
        $finish;
    end

endmodule