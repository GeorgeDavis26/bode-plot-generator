// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/22/2025

// bode_top.sv

/////////////////////////////////////////////
// Bode Plot Generator Top Module
/////////////////////////////////////////////

module bode_top # (
    parameter int    DAC_WIDTH = 8,                // Bit width for external DAC
    parameter int    PHASE_WIDTH = 32,             // Width phase accumulator
    parameter int    FULL_WAVE = 256,              // Size of full sine wave
    parameter        LUT_FILE = "dds_lut.txt"      // ROM for LUT

    parameter int    SAMPLES_PER_FREQ = 1024,       // Number of samples per frequency
    parameter int    PHASE_INC_MIN = 35791,         // Minimum phase increment (~100 Hz)
    parameter int    PHASE_INC_MAX = 357913941,     // Maximum phase increment (~1 MHz)
    parameter int    PHASE_INC_STEP = 35791         // Step size for phase increment (~100 Hz steps)

    parameter DAC_MIDPOINT = 8'h80                 // midpoint is 128
) (
    input  logic clk,
    input  logic reset,                            // active low reset
    input  logic sck, 
    input  logic sdi,
    input  logic load,
    output logic sdo,
    output logic done

);

    logic dac_wr;      // active low WR for DAC
    logic zero_cross;  // flag for whenever there's a zero-crossing
    logic int_osc;
    logic [PHASE_WIDTH-1:0] phase_inc;
    logic [DAC_WIDTH-1:0]   dac_data;

    // high frequency oscillator defaults to 48 MHz
    HSOSC hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));

    bode_spi #(
        .DAC_WIDTH(DAC_WIDTH),
        .DAC_MIDPOINT(DAC_MIDPOINT)
    ) spi (
        .clk(clk),
        .reset(reset),
        .dac_out(dac_data),
        .sck(sck),
        .sdi(sdi),
        .done(done),
        .sdo(sdo),
        .zero_cross(zero_cross)
    );
    
    dds_dac #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .FULL_WAVE(FULL_WAVE),
        .LUT_FILE(LUT_FILE),
        .SAMPLES_PER_FREQ(SAMPLES_PER_FREQ),
        .PHASE_INC_MIN(PHASE_INC_MIN),
        .PHASE_INC_MAX(PHASE_INC_MAX),
        .PHASE_INC_STEP(PHASE_INC_STEP)
    ) dds (
        .clk(clk),
        .reset(reset),
        .phase_inc(phase_inc),
        .dac_out(dac_out)
        .dac_data(dac_data),
        .dac_wr(dac_wr)
    );

endmodule