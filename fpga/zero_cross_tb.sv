// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/23/2025

// zero_cross_tb.sv

/////////////////////////////////////////////
// testbench for zero cross detection
/////////////////////////////////////////////

module zero_cross_tb;

    // Parameters
    localparam DAC_WIDTH = 8;
    localparam DAC_MIDPOINT = 8'h80;  // midpoint is 128
    localparam PHASE_WIDTH = 32;
    localparam FULL_WAVE = 256;
    localparam LUT_FILE = "dds_lut.txt";

    // Use faster parameters for simulation
    localparam SAMPLES_PER_FREQ = 64;
    localparam PHASE_INC_MIN = 8947; 
    localparam PHASE_INC_MAX = 89478;  
    localparam PHASE_INC_STEP = 8947;

    logic clk, reset;
    logic [DAC_WIDTH-1:0] dac_out;
    logic zero_cross;
    logic sweep_done;

    logic [31:0] zero_cross_count;
    logic [31:0] cycle_count;
    logic zero_cross_prev;

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
    ) sweep_ctrl (
        .clk(clk),
        .reset(reset),
        .dac_out(dac_out),
        .sweep_done(sweep_done)
    );

    // Instantiate zero cross detection
    zero_cross #(
        .DAC_WIDTH(DAC_WIDTH),
        .DAC_MIDPOINT(DAC_MIDPOINT)
        ) dut (
        .clk(clk),
        .reset(reset),
        .dac_out(dac_out),
        .zero_cross(zero_cross)
    );
    
    // Generate clock
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // Monitor zero crossings
    always @(posedge clk) begin
        if (reset) begin
            zero_cross_prev <= zero_cross;
            if (zero_cross && !zero_cross_prev) begin
                zero_cross_count <= zero_cross_count + 1;
            end
            cycle_count <= cycle_count + 1;
        end
    end

    // Start of tests
    initial begin

        //waveform dumping
        $dumpfile("zero_cross.vcd");
        $dumpvars(0, zero_cross_tb);

        // Initialize Inputs
        clk = 0;
        reset = 0;
        zero_cross_count = 0;
        cycle_count = 0;
        zero_cross_prev = 0;

        #30;
        reset = 1;  // Active low reset
        #10;

         // Wait for multiple zero crossings
        repeat(5) begin
            wait(zero_cross);
            #20;
            wait(!zero_cross);
        end

        // Force specific DAC values to test zero crossing detection
        force dac_out = 8'h7D;  // Below lower threshold
        #20;
        force dac_out = 8'h83;  // Above upper threshold
        #20;
        
        if (zero_cross) begin
            $display("PASS: Zero crossing detected");
        end else begin
            $display("FAIL: Zero crossing not detected");
        end

        // Test no crossing for small change
        force dac_out = 8'h7F;  // 127
        #20;
        force dac_out = 8'h81;  // 129
        #20;
        
        if (!zero_cross) begin
            $display("PASS: No false crossing for small change");
        end else begin
            $display("FAIL: False zero crossing for small change");
        end
        
        // Release forced values for dac out
        release dac_out;
        #50000;

        $display("Tests completed");
        $finish;
    end

endmodule