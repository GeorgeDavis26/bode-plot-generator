// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/22/2025

// bode_top.sv

/////////////////////////////////////////////
// Bode Plot Generator Top Module
/////////////////////////////////////////////

module bode_top #(
    // DDS Parameters
    parameter int    DAC_WIDTH = 8,                 // Bit width for external DAC
    parameter int    PHASE_WIDTH = 32,              // Width phase accumulator
    parameter int    FULL_WAVE = 256,               // Size of full sine wave
    parameter        LUT_FILE = "dds_lut.txt",      // ROM for LUT
    parameter        DAC_MIDPOINT = 8'h80,          // DAC midpoint (128 for 8-bit)

    // Sweep Controller Parameters
    parameter int    SAMPLES_PER_FREQ = 1024,       // Number of samples per frequency
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
    input  logic clk,                               // External clock (PIN B3 : 21)
    input  logic reset,                             // Active low reset (PIN 9)

    // MCU Interface
    input  logic mcu_ready,                         // MCU ready for next frequency (PIN A10 : 23)
    input  logic half_flag,                         // Half amplitude request from MCU (PIN A9 : 25)
    input  logic quarter_flag,                      // Quarter amplitude request from MCU (PIN A5 : 26)

    // DAC Interface
    output logic [DAC_WIDTH-1:0] dac_data,          // Data to DAC
    output logic dac_wr,                            // Write strobe to DAC (active low)

    // GPIO outputs to MCU
    output logic zero_cross_gpio,                   // Zero crossing detected (PIN A6 : 27)
    output logic freq_change_gpio,                  // Frequency change notification (PIN A11 : 20)
    output logic sweep_done_gpio,                   // Sweep completion flag (PIN B5 : 10)
    output logic amp_gpio1,                         // Amplitude control GPIO 1 (PIN B4 : 12)
    output logic amp_gpio2                          // Amplitude control GPIO 2 (PIN B7 : 11) 
);

    // Internal signals
    logic sweep_done;                               // Sweep completion from sweep controller
    logic [PHASE_WIDTH-1:0] current_phase_inc;     // Current phase increment for monitoring

    // Main DDS and DAC controller with sweep functionality
    dds_dac #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .FULL_WAVE(FULL_WAVE),
        .LUT_FILE(LUT_FILE),
        .DAC_MIDPOINT(DAC_MIDPOINT),
        .SAMPLES_PER_FREQ(SAMPLES_PER_FREQ),
        .PHASE_INC_MIN(PHASE_INC_MIN),
        .PHASE_INC_MAX(PHASE_INC_MAX),
        .PHASE_INC_1KHZ(PHASE_INC_1KHZ),
        .PHASE_INC_10KHZ(PHASE_INC_10KHZ),
        .PHASE_INC_STEP_100HZ(PHASE_INC_STEP_100HZ),
        .PHASE_INC_STEP_1KHZ(PHASE_INC_STEP_1KHZ),
        .PHASE_INC_STEP_10KHZ(PHASE_INC_STEP_10KHZ)
    ) dds_dac_inst (
        .clk(clk),
        .reset(reset),
        .mcu_ready(mcu_ready),
        .dac_data(dac_data),
        .dac_wr(dac_wr),
        .sweep_done(sweep_done),
        .current_phase_inc(current_phase_inc)
    );

    // Interface module for MCU communication
    bode_interface #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .DAC_MIDPOINT(DAC_MIDPOINT)
    ) mcu_interface (
        .clk(clk),
        .reset(reset),
        .dac_out(dac_data),
        .phase_inc(current_phase_inc),
        .sweep_done(sweep_done),
        .half_flag(half_flag),
        .quarter_flag(quarter_flag),
        .zero_cross_gpio(zero_cross_gpio),
        .freq_change_gpio(freq_change_gpio),
        .sweep_done_gpio(sweep_done_gpio),
        .amp_gpio1(amp_gpio1),
        .amp_gpio2(amp_gpio2)
    );

endmodule