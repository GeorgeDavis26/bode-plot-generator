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
    
    // Signals


    // Instantiate DDS
    sweep_controller dut ();

    // Generate clock
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // Start of test
    initial begin

        //waveform dumping
        $dumpfile("sweep_controller.vcd");
        $dumpvars(0, sweep_controller);

        // Initialize Inputs
    

        if (error_count == 0) begin
            $display("All key points passed");
        end else begin
            $display("%0d key points failed", error_count);
        end

        $display("Test completed");
        $finish;
    end

endmodule