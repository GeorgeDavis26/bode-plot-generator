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
    // localparam PHASE_INC_MIN = 8947; 
    // localparam PHASE_INC_MAX = 89478;  
    // localparam PHASE_INC_STEP = 8947;
    localparam PHASE_INC_MIN = 10000000; 
    localparam PHASE_INC_MAX = 100000000;  
    localparam PHASE_INC_STEP = 100000;

    logic clk, reset;
    logic [DAC_WIDTH-1:0] dac_out;
    logic zero_cross;
    logic sweep_done;

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

    always @(posedge clk) begin
    $display("dac_out: %h, zero_cross: %b", dac_out, zero_cross);
    end
    // Start of tests
    initial begin

        //waveform dumping
        $dumpfile("zero_cross.vcd");
        $dumpvars(0, zero_cross_tb);

        // Initialize Inputs
        clk = 0;
        reset = 0;

        #30;
        reset = 1;  // Active low reset
        #10;

        // Wait for multiple zero crossings
        repeat(2) begin
            wait(zero_cross);
            #10;
            wait(!zero_cross);
        end
        
        if (!zero_cross) begin
            $display("PASS: No false crossing for small change");
        end else begin
            $display("FAIL: False zero crossing for small change");
        end
        
        // Release forced values for dac out
        release dac_out;
        #100;

        $display("Tests completed");
        $finish;
    end

endmodule