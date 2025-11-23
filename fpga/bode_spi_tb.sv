// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/22/2025

// bode_spi_tb.sv

/////////////////////////////////////////////
// Bode Plot Generator spi testbench 
// tests the SPI interface between the FPGA 
// and MCU
// and zero crossing detection
/////////////////////////////////////////////

`timescale 1ns/1ps

module bode_spi_tb;

    // Parameters

    
    // Signals
    logic                   clk;
    logic                   reset;
    logic [DAC_WIDTH-1:0]   dac_out;

    // Instantiate sweep controller
    bode_spi #(

        ) dut (
      
    );

    // Generate clock
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // Start of tests
    initial begin

        //waveform dumping
        $dumpfile("spi.vcd");
        $dumpvars(0, spi_tb);

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