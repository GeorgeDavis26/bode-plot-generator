// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/11/2025

// dds.sv

/////////////////////////////////////////////
// Direct Digital Synthesis module -

// Outputs will be fed into an external DAC
// which will be used to generate analog
// waveforms
/////////////////////////////////////////////

module dds # (
    parameter int    DAC_WIDTH = 8,                 // Bit width for external DAC
    parameter int    PHASE_WIDTH = 32,              // Width phase accumulator
    parameter int    FULL_WAVE = 256,               // Size of full sine wave
    parameter        LUT_FILE = "dds_lut.txt"   // ROM for LUT
) (
    input logic                   clk,
    input logic                   reset,  // active low reset
    input logic [PHASE_WIDTH-1:0] phase_inc,
    output logic [DAC_WIDTH-1:0]  dac_out
);

// Phase Accumulator
logic [PHASE_WIDTH-1:0] phase_acc = 0;

always_ff @(posedge clk) begin
    if(~reset) begin
        phase_acc <= 0;
    end else begin
        phase_acc <= phase_acc + phase_inc;
    end
end

// Quarter-wave sine LUT
localparam int QUARTER_LUT = FULL_WAVE / 4;     // size of quarter-wave LUT
localparam int LUT_BITS = $clog2(QUARTER_LUT);  // bits needed for LUT adder

// Using the first 2 bits for tracking quadrant
logic [1:0] quadrant;
assign quadrant = phase_acc[PHASE_WIDTH-1 -: 2];

// Remaining bits are use to pick values from the LUT
logic [LUT_BITS-1:0] lut_addr_base;
assign lut_addr_base = phase_acc[PHASE_WIDTH-3 -: LUT_BITS];

// ROM block for LUT
(* rom_style = "block" *)
logic [DAC_WIDTH-1:0] rom [0:QUARTER_LUT-1];

// Read LUT
initial begin
    $readmemh(LUT_FILE, rom);
end

// Assign LUT position based on the current quadrant
logic [LUT_BITS-1:0] lut_addr;
always_comb begin
        // read the table backwards for quadrants 1 and 3
        if (quadrant == 2'b01 || quadrant == 2'b11) begin
            lut_addr = ~lut_addr_base;
        end else begin
            lut_addr = lut_addr_base;
        end
    end

// Read ROM
logic [DAC_WIDTH-1:0] lut_out;
always_ff @(posedge clk) begin
    lut_out <= rom[lut_addr];
end

// Reconstruct the full sine wave from the amplitude LUT
logic [DAC_WIDTH-1:0] dac_out_reg;
always_ff @(posedge clk) begin
    if (~reset) begin
        dac_out_reg <= 8'h80; // Reset to the midpoint (128)
    end else begin
        // For quadrants 2 and 3, subtract amplitude from midpoint
        if (quadrant[1]) begin
            dac_out_reg <= 8'h80 - lut_out;
        // For quadrants 0 and 1, add amplitude to midpoint
        end else begin
            dac_out_reg <= 8'h80 + lut_out;
        end
    end
end

// Output Logic
assign dac_out = dac_out_reg;

endmodule