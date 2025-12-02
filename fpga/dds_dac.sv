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

    parameter int    PHASE_INC_MIN = 5369,          // Minimum phase increment (~100 Hz at 80MHz)
    parameter int    PHASE_INC_MAX = 5368709,       // Maximum phase increment (~100 kHz at 80MHz)

    // Decade boundaries for phase increments
    parameter int    PHASE_INC_1KHZ = 53687,        // 1 kHz boundary
    parameter int    PHASE_INC_10KHZ = 536871,      // 10 kHz boundary
    
    // Step sizes for each decade
    parameter int    PHASE_INC_STEP_100HZ = 5369,   // 100 Hz steps (100Hz to 1kHz)
    parameter int    PHASE_INC_STEP_1KHZ = 53687,   // 1 kHz steps (1kHz to 10kHz)
    parameter int    PHASE_INC_STEP_10KHZ = 536871  // 10 kHz steps (10kHz to 100kHz)
) (
    input logic                   clk,
    input logic                   reset,            // active low reset
    input logic                   mcu_ready,        // MCU is ready to collect data
    input logic                   mcu_done,         // MCU is done collecting data
    input logic                   quarter_flag,
    input logic                   half_flag,
    output logic [DAC_WIDTH-1:0]  dac_data,
    output logic                  dac_wr,           // active low WR for DAC
    output logic                  sweep_done,
    output logic [PHASE_WIDTH-1:0] current_phase_inc  // Current phase increment for monitoring
);

    // Internal signals
    logic [DAC_WIDTH-1:0] dac_out;                  // Unattenuated DDS output
    logic [DAC_WIDTH-1:0] attenuated_dac_out;       // Attenuated DDS output

    // Sweep controller with integrated DDS
    sweep_controller #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .FULL_WAVE(FULL_WAVE),
        .LUT_FILE(LUT_FILE),
        .PHASE_INC_MIN(PHASE_INC_MIN),
        .PHASE_INC_MAX(PHASE_INC_MAX),
        .PHASE_INC_1KHZ(PHASE_INC_1KHZ),
        .PHASE_INC_10KHZ(PHASE_INC_10KHZ),
        .PHASE_INC_STEP_100HZ(PHASE_INC_STEP_100HZ),
        .PHASE_INC_STEP_1KHZ(PHASE_INC_STEP_1KHZ),
        .PHASE_INC_STEP_10KHZ(PHASE_INC_STEP_10KHZ)
    ) sweep_control (
        .clk(clk),
        .reset(reset),
        .mcu_ready(mcu_ready),
        .mcu_done(mcu_done),
        .dac_out(dac_out),
        .sweep_done(sweep_done),
        .phase_inc_reg(current_phase_inc)
    );

     // Amplitude control logic
    always_comb begin
        // Convert to signed for proper arithmetic around midpoint
        logic signed [DAC_WIDTH:0] signed_amplitude;
        logic signed [DAC_WIDTH:0] attenuated_amplitude;
        
        // Convert to signed relative to midpoint
        signed_amplitude = $signed({1'b0, dac_out}) - $signed({1'b0, DAC_MIDPOINT});
        
        // Apply attenuation based on control flags
        case ({quarter_flag, half_flag})
            2'b00: attenuated_amplitude = signed_amplitude;           // Full amplitude
            2'b01: attenuated_amplitude = signed_amplitude >>> 1;     // Half amplitude
            2'b10: attenuated_amplitude = signed_amplitude >>> 2;     // Quarter amplitude
            2'b11: attenuated_amplitude = signed_amplitude;           // Full amplitude
        endcase
        
        // Convert back to unsigned and add midpoint offset
        attenuated_dac_out = $unsigned(attenuated_amplitude + $signed({1'b0, DAC_MIDPOINT}));
    end

    // DAC Write signal - toggle every clock for continuous updates
    logic dac_wr_reg = 1'b1;
    always_ff @(posedge clk) begin
        if (~reset) begin
            dac_wr_reg <= 1'b1;
        end else begin
            dac_wr_reg <= ~dac_wr_reg;
        end
    end

    // Output Logic
    assign dac_wr = dac_wr_reg;
    assign dac_data = attenuated_dac_out;

endmodule