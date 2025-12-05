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

    // Smaller numbers for tb
    localparam    PHASE_INC_MIN = 1000;          // Minimum phase increment (~100 Hz at 80MHz)
    localparam    PHASE_INC_MAX = 100000;       // Maximum phase increment (~100 kHz at 80MHz)

    // Decade boundaries for phase increments
    localparam     PHASE_INC_1KHZ = 1000;        // 1 kHz boundary
    localparam     PHASE_INC_10KHZ = 10000;      // 10 kHz boundary
    
    // Step sizes for each decade
    localparam     PHASE_INC_STEP_100HZ = 1000;   // 100 Hz steps (100Hz to 1kHz)
    localparam     PHASE_INC_STEP_1KHZ = 10000;   // 1 kHz steps (1kHz to 10kHz)
    localparam     PHASE_INC_STEP_10KHZ = 100000;  // 10 kHz steps (10kHz to 100kHz)
    
    // Signals
    logic                   clk;
    logic                   reset;
    logic                   mcu_ready;
    logic                   mcu_done;
    logic [DAC_WIDTH-1:0]   dac_out;
    logic                   sweep_done;
    logic [PHASE_WIDTH-1:0] phase_inc_reg;

    // Instantiate sweep controller
    sweep_controller #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .FULL_WAVE(FULL_WAVE),
        .LUT_FILE(LUT_FILE),
        .PHASE_INC_MIN(PHASE_INC_MIN),
        .PHASE_INC_MAX(PHASE_INC_MAX),
        .PHASE_INC_1KHZ(PHASE_INC_1KHZ),
        .PHASE_INC_10KHZ(PHASE_INC_10KHZ),
        .PHASE_INC_STEP_100HZ(PHASE_INC_STEP_100HZ),
        .PHASE_INC_STEP_1KHZ(PHASE_INC_STEP_1KHZ),
        .PHASE_INC_STEP_10KHZ(PHASE_INC_STEP_10KHZ)
        ) dut (
        .clk(clk),
        .reset(reset),
        .mcu_ready(mcu_ready),
        .mcu_done(mcu_done),
        .dac_out(dac_out),
        .sweep_done(sweep_done),
        .phase_inc_reg(phase_inc_reg)
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
            $display("Time: %0t | DAC Output: %h", $time, dac_out);
        end
    endtask

    // Start of tests
    initial begin

        // Waveform dumping
        $dumpfile("sweep_controller.vcd");
        $dumpvars(0, sweep_controller_tb);

        // Initialize Inputs
        clk = 0;
        mcu_ready = 0;
        mcu_done = 0;
        reset = 0;

        #20;
        reset = 1;  // Active low reset
        #20;

        // Simulate all 30 frequency steps
        repeat (30) begin
            simulate_frequency_step();
        end

        // Wait for sweep_done
        wait(sweep_done);
        $display("Sweep done");

        if (phase_inc_reg == PHASE_INC_MAX) begin
            $display("PASS: Final phase increment matches expected value");
        end else begin
            $display("FAIL: Final phase increment does not match expected value");
        end

        $display("Test completed");
        $finish;
    end

endmodule