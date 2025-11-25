// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/16/2025

// dds_dac.sv

/////////////////////////////////////////////
// DDS and DAC interface module -

// Outputs will be fed into an external DAC
// which will be used to generate analog
// waveforms
/////////////////////////////////////////////

module dds_dac # (
    parameter int    DAC_WIDTH = 8,                 // Bit width for external DAC
    parameter int    PHASE_WIDTH = 32,              // Width phase accumulator
    parameter int    FULL_WAVE = 256,               // Size of full sine wave
    parameter        LUT_FILE = "dds_lut.txt",       // ROM for LUT
	parameter DAC_MIDPOINT = 8'h80,


    parameter int    SAMPLES_PER_FREQ = 1024,       // Number of samples per frequency
    // parameter int    PHASE_INC_MIN = 35791,         // Minimum phase increment (~100 Hz)
    // parameter int    PHASE_INC_MAX = 357913941,     // Maximum phase increment (~1 MHz)
    // parameter int    PHASE_INC_STEP = 35791         // Step size for phase increment (~100 Hz steps)
    parameter int    PHASE_INC_MIN = 35791,         // Minimum phase increment 100
    parameter int    PHASE_INC_MAX = 35791,     // Maximum phase increment 100 Hz
    parameter int    PHASE_INC_STEP = 0         // Step size for phase increment 
) (
    input logic                   clk,
    input logic                   reset,            // active low reset
    output logic [DAC_WIDTH-1:0]  dac_data,
    output logic                  dac_wr,            // active low WR for DAC
	output logic                  zero_detected,
	output logic 				  int_osc
);

// Connecting DDS output to dac_data
wire [DAC_WIDTH-1:0] dac_out;

// high frequency oscillator at 12 MHz, suitable for DAC update rate
HSOSC #(.CLKHF_DIV ("0b10")) hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));

sweep_controller #(
    .DAC_WIDTH(DAC_WIDTH),
    .PHASE_WIDTH(PHASE_WIDTH),
    .FULL_WAVE(FULL_WAVE),
    .LUT_FILE(LUT_FILE),
    .SAMPLES_PER_FREQ(SAMPLES_PER_FREQ),
    .PHASE_INC_MIN(PHASE_INC_MIN),
    .PHASE_INC_MAX(PHASE_INC_MAX),
    .PHASE_INC_STEP(PHASE_INC_STEP)
) sweep_control (
    .clk(int_osc),
    .reset(reset),
    .dac_out(dac_out),
    .sweep_done(sweep_done)
);

// Zero cross detection
    zero_cross #(
        .DAC_WIDTH(DAC_WIDTH),
        .DAC_MIDPOINT(DAC_MIDPOINT)
    ) zero_cross_detect (
        .clk(int_osc),
        .reset(reset),
        .dac_out(dac_out),
        .zero_cross(zero_detected)
    );

// Connecting DDS output to dac_data
assign dac_data = dac_out;

// DAC Control signal
logic dac_wr_reg = 1'b1;
always_ff @(posedge int_osc) begin
    if (~reset) begin
        dac_wr_reg <= 1'b1;
    end else begin
        dac_wr_reg <= ~dac_wr_reg;
    end
end

assign dac_wr = dac_wr_reg;

endmodule