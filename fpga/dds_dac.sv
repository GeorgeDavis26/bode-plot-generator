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
    parameter        LUT_FILE = "dds_lut.txt",      // ROM for LUT
    parameter        DAC_MIDPOINT = 8'h80,          // DAC midpoint

    parameter int    SAMPLES_PER_FREQ = 1024,       // Number of samples per frequency
    parameter int    PHASE_INC_MIN = 35791,         // Minimum phase increment (~100 Hz)
    parameter int    PHASE_INC_MAX = 35791394,      // Maximum phase increment (~100 kHz)
    parameter int    PHASE_INC_STEP = 35791         // Step size for phase increment (~100 Hz steps)
) (
    input logic                   clk,
    input logic                   reset,            // active low reset
    input logic                   mcu_ready,        // MCU ready for next frequency
    output logic [DAC_WIDTH-1:0]  dac_data,
    output logic                  dac_wr,           // active low WR for DAC
    output logic                  sweep_done,
    output logic [DAC_WIDTH-1:0]  dac_out,         // Raw DDS output for monitoring
    output logic [PHASE_WIDTH-1:0] current_phase_inc  // Current phase increment for monitoring
);

    // Sweep controller with integrated DDS
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
        .clk(clk),
        .reset(reset),
        .mcu_ready(mcu_ready),
        .dac_out(dac_out),
        .sweep_done(sweep_done),
        .phase_inc_reg(current_phase_inc)
    );

    // Connect DDS output to DAC data
    assign dac_data = dac_out;

    // DAC Write signal - toggle every clock for continuous updates
    logic dac_wr_reg = 1'b1;
    always_ff @(posedge clk) begin
        if (~reset) begin
            dac_wr_reg <= 1'b1;
        end else begin
            dac_wr_reg <= ~dac_wr_reg;
        end
    end

    assign dac_wr = dac_wr_reg;

endmodule