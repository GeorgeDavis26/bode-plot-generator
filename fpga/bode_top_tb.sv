// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 12/2/2025

// bode_top_tb.sv

/////////////////////////////////////////////
// Bode Plot Generator Top module testbench
// Tests full system integration with one complete sweep
/////////////////////////////////////////////

`timescale 1ns/1ps

module bode_top_tb;
   
    // Parameters
    localparam DAC_WIDTH   = 8;
    localparam PHASE_WIDTH = 32;
    localparam FULL_WAVE   = 256;
    localparam LUT_FILE    = "dds_lut.txt";
    localparam DAC_MIDPOINT = 8'h80;

    // Smaller numbers for testbench
    localparam PHASE_INC_MIN = 1000000;      // Much larger for visible sine waves
    localparam PHASE_INC_MAX = 10000000;     // Still reasonable range
    localparam PHASE_INC_1KHZ = 2000000;     
    localparam PHASE_INC_10KHZ = 5000000;    
    localparam PHASE_INC_STEP_100HZ = 1000000;
    localparam PHASE_INC_STEP_1KHZ = 2000000;
    localparam PHASE_INC_STEP_10KHZ = 5000000;
    
    // Signals for bode_top
    logic                   clk;
    logic                   reset;
    logic                   mcu_ready;
    logic                   mcu_done;
    logic                   half_flag;           // Half amplitude button: active low
    logic                   full_flag;           // Full amplitude button: active low
    
    // DAC Interface
    logic [DAC_WIDTH-1:0]   dac_data;
    logic                   dac_wr;
    
    // GPIO outputs
    logic                   zero_cross_gpio;
    logic                   sweep_done_gpio;
    logic                   amp_gpio1;
    logic                   amp_gpio2;

    // Test tracking variables
    integer step_count = 0;
    integer button_press_count = 0;
    logic test_started = 0;

    // Instantiate bode_top
    bode_top #(
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
    ) dut (
        .clk(clk),
        .reset(reset),
        .mcu_ready(mcu_ready),
        .mcu_done(mcu_done),
        .half_flag(half_flag),
        .full_flag(full_flag),
        .dac_data(dac_data),
        .dac_wr(dac_wr),
        .zero_cross_gpio(zero_cross_gpio),
        .sweep_done_gpio(sweep_done_gpio),
        .amp_gpio1(amp_gpio1),
        .amp_gpio2(amp_gpio2)
    );

    // Generate clock
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // Task to simulate button press
    task press_full_amplitude_button();
        begin
            $display("Time: %0t | Pressing FULL amp button", $time);
            full_flag = 0;  // Active low press
            #100;           // Hold for 10 clock cycles
            full_flag = 1;  // Release
            #50;            // Wait a bit after release
            button_press_count++;
        end
    endtask

    // Task to simulate one complete frequency measurement cycle
    task simulate_frequency_step();
    begin
        // Wait for WAIT_MCU state
        wait(dut.dds_dac_inst.sweep_control.state == dut.dds_dac_inst.sweep_control.WAIT_MCU);
        $display("Time: %0t | Step %0d: In WAIT_MCU state", $time, step_count);
        
        // Give a few clock cycles for state to stabilize
        repeat(5) @(posedge clk);
        
        // MCU signals ready immediately
        $display("Time: %0t | Step %0d: Sending MCU ready signal", $time, step_count);
        mcu_ready = 1;
        repeat(2) @(posedge clk);  // Hold for 2 clocks
        mcu_ready = 0;
        
        // Wait for SET_FREQ state
        wait(dut.dds_dac_inst.sweep_control.state == dut.dds_dac_inst.sweep_control.SET_FREQ);
        $display("Time: %0t | Step %0d: Frequency set - Phase Inc: %0d | DAC: %0h", 
                 $time, step_count, 
                 dut.dds_dac_inst.current_phase_inc, dac_data);
        
        // Wait for MCU_DONE state
        wait(dut.dds_dac_inst.sweep_control.state == dut.dds_dac_inst.sweep_control.MCU_DONE);
        $display("Time: %0t | Step %0d: In MCU_DONE state", $time, step_count);
        
        // Short data collection time
        repeat(20) @(posedge clk);
        
        // MCU signals done
        $display("Time: %0t | Step %0d: Sending MCU done signal", $time, step_count);
        mcu_done = 1;
        repeat(2) @(posedge clk);  // Hold for 2 clocks
        mcu_done = 0;
        
        // Wait for NEXT_FREQ state
        wait(dut.dds_dac_inst.sweep_control.state == dut.dds_dac_inst.sweep_control.NEXT_FREQ);
        $display("Time: %0t | Step %0d: In NEXT_FREQ state", $time, step_count);
        
        // Wait for state to complete
        repeat(5) @(posedge clk);
        
        step_count++;
    end
endtask

    // Task to perform complete sweep
    task perform_full_sweep();
        begin
            $display("\n=== Starting Full Amplitude Sweep ===");
            step_count = 0;
            
            // Wait for system to reach WAIT_AMP state
            wait(dut.dds_dac_inst.sweep_control.state == dut.dds_dac_inst.sweep_control.WAIT_AMP);
            $display("Time: %0t | System ready - waiting for amplitude selection", $time);
            
            // Press full amplitude button
            press_full_amplitude_button();
            
            // Wait a bit for the system to process the button press
            #200;
            
            // Verify amplitude was selected
            if (amp_gpio2) begin
                $display("PASS: Full amplitude selected (amp_gpio2 = %b)", amp_gpio2);
            end else begin
                $display("FAIL: Full amplitude not selected (amp_gpio2 = %b)", amp_gpio2);
            end
            
            // Perform sweep until done
            test_started = 1;
            while (!sweep_done_gpio && step_count < 20) begin  // Safety limit
                simulate_frequency_step();
            end
            
            $display("\n=== Full Amplitude Sweep Complete ===");
            $display("Total frequency steps: %0d", step_count);
            
            // Final verification
            if (sweep_done_gpio) begin
                $display("PASS: Sweep completed successfully");
            end else begin
                $display("FAIL: Sweep did not complete");
            end
            
            if (dac_data == DAC_MIDPOINT) begin
                $display("PASS: DAC output at midpoint after sweep (%0h)", dac_data);
            end else begin
                $display("FAIL: DAC output not at midpoint after sweep (%0h != %0h)", 
                         dac_data, DAC_MIDPOINT);
            end
        end
    endtask

    // Main test sequence
    initial begin
        // Waveform dumping

        $display("=== Bode Top Testbench Starting ===");
        $display("Phase Inc Range: %0d to %0d", PHASE_INC_MIN, PHASE_INC_MAX);
        $display("DAC Width: %0d bits, Midpoint: %0h", DAC_WIDTH, DAC_MIDPOINT);

        // Initialize inputs
        clk = 0;
        mcu_ready = 0;
        mcu_done = 0;
        half_flag = 1;    // Active low - not pressed
        full_flag = 1;    // Active low - not pressed
        reset = 0;

        // Reset sequence
        #50;
        reset = 1;  // Release reset (active low)
        #100;

        $display("Time: %0t | Reset complete, starting test", $time);

        // Perform one complete sweep at full amplitude
        perform_full_sweep();

        $display("\n=== Test Summary ===");
        $display("Button presses: %0d", button_press_count);
        $display("Frequency steps: %0d", step_count);
        $display("Final DAC output: %0h", dac_data);
        $display("Amplitude GPIOs - Half: %b, Full: %b", amp_gpio1, amp_gpio2);

        #10;
        $display("\n=== Test Completed ===");
        $stop;
        //$finish;
    end
    endmodule