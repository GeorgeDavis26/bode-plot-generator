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

    parameter int    SAMPLES_PER_FREQ = 1024,      // Number of samples per frequency
    parameter int    PHASE_INC_MIN = 8947,         // Minimum phase increment (~100 Hz)
    parameter int    PHASE_INC_MAX = 89478485,     // Maximum phase increment (~1 MHz)
    parameter int    PHASE_INC_STEP = 8947         // Step size for phase increment (~100 Hz steps)
) (
    input logic                   clk,
    input logic                   reset,            // active low reset
    output logic [DAC_WIDTH-1:0]  dac_data,
    output logic                  dac_wr            // active low WR for DAC
);

// Connecting DDS output to dac_data
wire [DAC_WIDTH-1:0] dac_out;

// high frequency oscillator defaults to 48 MHz
HSOSC hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));

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