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
    localparam PHASE_INC_MIN = 100;          // Minimum phase increment 
    localparam PHASE_INC_MAX = 100000;       // Maximum phase increment 

    // Decade boundaries for phase increments
    localparam PHASE_INC_1KHZ = 1000;        // 1 kHz boundary
    localparam PHASE_INC_10KHZ = 10000;      // 10 kHz boundary
    
    // Step sizes for each decade
    localparam PHASE_INC_STEP_100HZ = 100;   // Small steps in first decade
    localparam PHASE_INC_STEP_1KHZ = 1000;   // Medium steps in second decade
    localparam PHASE_INC_STEP_10KHZ = 10000; // Large steps in third decade
    
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

    // Test tracking variables
    integer step_count = 0;
    integer test_phase = 0; // 0 = full amplitude, 1 = half amplitude
    logic [DAC_WIDTH-1:0] max_dac_value, min_dac_value;
    logic [DAC_WIDTH-1:0] expected_max_full, expected_min_full;
    logic [DAC_WIDTH-1:0] expected_max_half, expected_min_half;

    // Instantiate dds_dac
    dds_dac #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .FULL_WAVE(FULL_WAVE),
        .LUT_FILE(LUT_FILE),
        .DAC_MIDPOINT(DAC_MIDPOINT),
        .PHASE_INC_MIN(PHASE_INC_MIN),
        .PHASE_INC_MAX(PHASE_INC_MAX),
        .PHASE_INC_1KHZ(PHASE_INC_1KHZ),
        .PHASE_INC_10KHZ(PHASE_INC_10KHZ),
        .PHASE_INC_STEP_100HZ(PHASE_INC_STEP_100HZ),
        .PHASE_INC_STEP_1KHZ(PHASE_INC_STEP_1KHZ),
        .PHASE_INC_STEP_10KHZ(PHASE_INC_STEP_10KHZ)
    ) dds_dac_inst (
        .clk(clk),
        .reset(reset),
        .mcu_ready(mcu_ready),
        .mcu_done(mcu_done),
        .full_flag(full_flag),
        .half_flag(half_flag),
        .dac_data(dac_data),
        .dac_wr(dac_wr),
        .sweep_done(sweep_done),
        .current_phase_inc(current_phase_inc)
    );

    // Generate clock (10 ns period = 100 MHz)
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // Monitor DAC output
    always @(posedge clk) begin
        if (reset && !sweep_done) begin
            if (dac_data > max_dac_value) max_dac_value = dac_data;
            if (dac_data < min_dac_value) min_dac_value = dac_data;
        end
    end

    // Task to simulate one frequency step
    task simulate_frequency_step();
        begin
            // Wait for WAIT_MCU state
            wait(dds_dac_inst.sweep_control.state == dds_dac_inst.sweep_control.WAIT_MCU);
            
            // MCU ready
            #20;
            mcu_ready = 1;
            #20;
            mcu_ready = 0;
            
            // Wait for SET_FREQ state
            wait(dds_dac_inst.sweep_control.state == dds_dac_inst.sweep_control.SET_FREQ);
            step_count++;
            
            // Reset min/max for this frequency
            max_dac_value = 0;
            min_dac_value = 255;
            
            // Wait for MCU_DONE state
            wait(dds_dac_inst.sweep_control.state == dds_dac_inst.sweep_control.MCU_DONE);
            
            // Simulate data collection time
            repeat(500) @(posedge clk);
            
            // MCU done collecting data
            #20;
            mcu_done = 1;
            #20;
            mcu_done = 0;
            
            // Wait for NEXT_FREQ state to complete
            wait(dds_dac_inst.sweep_control.state == dds_dac_inst.sweep_control.NEXT_FREQ);
            #20;
        end
    endtask

    // Task to perform a complete sweep
    task perform_sweep(input string amplitude_mode);
        begin
            step_count = 0;
            max_dac_value = 0;
            min_dac_value = 255;
            
            // Reset the system
            reset = 0;
            #20;
            reset = 1;
            #20;
            
            // Wait for IDLE state to complete
            wait(dds_dac_inst.sweep_control.state == dds_dac_inst.sweep_control.WAIT_MCU);
            
            // Perform sweep until done
            while (!sweep_done) begin
                simulate_frequency_step();
            end
            
            // Verify final state
            if (sweep_done) begin
                $display("PASS: Sweep completed");
            end else begin
                $display("FAIL: Sweep did not complete");
            end
            
            if (current_phase_inc == PHASE_INC_MAX) begin
                $display("PASS: Final phase increment matches max");
            end else begin
                $display("FAIL: Final phase increment does not match max");
            end
            
            if (dac_data == DAC_MIDPOINT) begin
                $display("PASS: DAC output is at midpoint after sweep completion");
            end else begin
                $display("FAIL: DAC output is not at midpoint after sweep");
            end
        end
    endtask

    // Task to analyze amplitude during a frequency step
    task analyze_amplitude_at_frequency();
        begin
            logic [DAC_WIDTH-1:0] local_max = 0, local_min = 255;
            logic [DAC_WIDTH-1:0] amplitude_peak_to_peak;
            
            // Collect data for several sine wave cycles
            repeat(1000) begin
                @(posedge clk);
                if (dac_data > local_max) local_max = dac_data;
                if (dac_data < local_min) local_min = dac_data;
            end
            
            amplitude_peak_to_peak = local_max - local_min;
            
            // Verify amplitude is correct for current mode
            if (test_phase == 0) begin // Full amplitude
                if (amplitude_peak_to_peak >= expected_max_full) begin
                    $display("PASS: Full amplitude verified");
                end else begin
                    $display("FAIL: Full amplitude too small");
                end
            end else begin // Half amplitude
                if (amplitude_peak_to_peak <= expected_max_half && amplitude_peak_to_peak >= expected_min_half) begin
                    $display("PASS: Half amplitude verified");
                end else begin
                    $display("FAIL: Half amplitude incorrect ");
                end
            end
        end
    endtask

    // Main test sequence
    initial begin
        // Waveform dumping
        $dumpfile("dds_dac.vcd");
        $dumpvars(0, dds_dac_tb);

        // Calculate expected amplitude ranges
        expected_max_full = 255; // Full scale for 8-bit
        expected_min_full = 200; // Allow some margin
        expected_max_half = 130; // Half amplitude should be ~127
        expected_min_half = 100;  // Allow some margin

        // Initialize inputs
        clk = 0;
        mcu_ready = 0;
        mcu_done = 0;
        reset = 0;
        full_flag = 0;
        half_flag = 0;

        // Full Amplitude Sweep
        test_phase = 0;
        full_flag = 1;
        half_flag = 0;
        perform_sweep("FULL");

        #1000; // Wait between tests

        // Half Amplitude Sweep  
        test_phase = 1;
        full_flag = 0;
        half_flag = 1;
        perform_sweep("HALF");
        
        // Reset and set to a mid-range frequency
        reset = 0;
        #20;
        reset = 1;
        #20;
        
        // Wait for system to be ready
        wait(dds_dac_inst.sweep_control.state == dds_dac_inst.sweep_control.WAIT_MCU);
        
        // Test full amplitude
        full_flag = 1;
        half_flag = 0;
        mcu_ready = 1;
        #10;
        mcu_ready = 0;
        wait(dds_dac_inst.sweep_control.state == dds_dac_inst.sweep_control.SET_FREQ);
        $display("Testing FULL amplitude");
        analyze_amplitude_at_frequency();
        
        // Switch to half amplitude without changing frequency
        full_flag = 0;
        half_flag = 1;
        #100; // Let amplitude change settle
        $display("Testing HALF amplitude");
        analyze_amplitude_at_frequency();

        $display("Test completed");
        $finish;
    end

endmodule