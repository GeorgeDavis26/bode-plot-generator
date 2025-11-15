// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/11/2025

// dds_tb.sv

/////////////////////////////////////////////
// Direct Digital Synthesis testbench
/////////////////////////////////////////////

`timescale 1ns/1ps

module dds_tb;

    // Parameters
    localparam DAC_WIDTH   = 8;
    localparam PHASE_WIDTH = 32;
    localparam FULL_WAVE   = 256;
    localparam LUT_FILE    = "dds_lut.txt";
    
    // Signals
    logic                   clk;
    logic                   reset;
    logic [PHASE_WIDTH-1:0] phase_inc;
    logic [DAC_WIDTH-1:0]   dac_out;

    logic [31:0]            error_count;
    logic [DAC_WIDTH-1:0]   expected_val;


    // Instantiate DDS
    dds #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .FULL_WAVE(FULL_WAVE),
        .LUT_FILE(LUT_FILE)
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

    // Start of test
    initial begin

        //waveform dumping
        $dumpfile("dds.vcd");
        $dumpvars(0, dds_tb);

        // Initialize INputs
        clk = 0;
        reset = 0;
        phase_inc = '0;
        error_count = 0;
        expected_val = 0;


        #30;
        reset = 1;  // Active low reset
        #10;

        // Set phase_inc to produce one full sine wave over 256 clock cycles
        phase_inc = (1 << (PHASE_WIDTH - $clog2(FULL_WAVE)));
        #10;
        
        // checking outputs
        for (int i = 0; i < FULL_WAVE; i = i + 1) begin
            #10;
            
            // Check the value that was calculated in the previous cycle
            case (i)
                // At 0 degrees, sin(0) = 0 and output should be midpoint (128)
                0: begin
                    expected_val = 8'h7F;
                    if (dac_out !== expected_val) begin
                        $display("ERROR at 0 degrees (sample %0d): got %h, expected %h", i, dac_out, expected_val);
                        error_count++;
                    end
                end
                
                // At 90 degrees, sin(pi/2) = 1 and output should be the peak
                (FULL_WAVE/4): begin
                    expected_val = 8'hFE;
                    if (dac_out !== expected_val) begin
                        $display("ERROR at 90 degrees (sample %0d): got %h, expected %h", i, dac_out, expected_val);
                        error_count++;
                    end
                end

                // At 180 degrees, sin(pi) = 0 and output should be midpoint (128)
                (FULL_WAVE/2): begin
                    expected_val = 8'h7F;
                    if (dac_out !== expected_val) begin
                        $display("ERROR at 180 degrees (sample %0d): got %h, expected %h", i, dac_out, expected_val);
                        error_count++;
                    end
                end

                // At 270 degrees, sin(3pi/2) = -1 and output should be min value
                (3*FULL_WAVE/4): begin
                    expected_val = 8'h00;
                    if (dac_out !== expected_val) begin
                        $display("ERROR at 270 degrees (sample %0d): got %h, expected %h", i, dac_out, expected_val);
                        error_count++;
                    end
                end
            endcase
        end

        if (error_count == 0) begin
            $display("All key points passed");
        end else begin
            $display("%0d key points failed", error_count);
        end

        $display("Test completed");
        $finish;
    end

endmodule