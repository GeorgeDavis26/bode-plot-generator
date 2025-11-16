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
    parameter        LUT_FILE = "dds_lut.txt"       // ROM for LUT
) (
    input logic                   clk,
    input logic                   reset,            // active low reset
    input logic [PHASE_WIDTH-1:0] phase_inc,
    output logic [DAC_WIDTH-1:0]  dac_data,
    output logic                  dac_wr            // active low WR for DAC
);

// Connecting DDS output to dac_data
wire [DAC_WIDTH-1:0] dac_out;

dds #(
    .DAC_WIDTH(DAC_WIDTH),
    .PHASE_WIDTH(PHASE_WIDTH),
    .FULL_WAVE(FULL_WAVE),
    .LUT_FILE(LUT_FILE)
) dds_inst (
    .clk(clk),
    .reset(reset),
    .phase_inc(phase_inc),
    .dac_out(dac_out)
)

// Connecting DDS output to dac_data
assign dac_data = dac_out;

// DAC Control signal
logic dac_wr_reg = 1'b1;
always_ff @(posedge clk) begin
    if (~reset) begin
        dac_wr_reg <= 1'b1;
    end else begin
        dac_wr_reg <= ~dac_wr_reg
    end
end

assign dac_wr = dac_wr_reg;

endmodule