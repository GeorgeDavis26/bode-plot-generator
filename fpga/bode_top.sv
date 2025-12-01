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
    parameter int    PHASE_INC_MIN = 35791,         // Minimum phase increment (~100 Hz at 12MHz)
    parameter int    PHASE_INC_MAX = 35791394,      // Maximum phase increment (~100 kHz at 12MHz)
    parameter int    PHASE_INC_STEP = 35791         // Step size for phase increment (~100 Hz steps)
) (
    input  logic clk,                               // External clock (if needed)
    input  logic reset,                             // Active low reset

    // MCU Interface
    input  logic mcu_ready,                         // MCU ready for next frequency
    input  logic half_flag,                         // Half amplitude request from MCU
    input  logic quarter_flag,                      // Quarter amplitude request from MCU

    // DAC Interface
    output logic [DAC_WIDTH-1:0] dac_data,         // Data to DAC
    output logic dac_wr,                            // Write strobe to DAC (active low)

    // GPIO outputs to MCU
    output logic zero_cross_gpio,                   // Zero crossing detected
    output logic freq_change_gpio,                  // Frequency change notification
    output logic sweep_done_gpio,                   // Sweep completion flag
    output logic amp_gpio1,                         // Amplitude control GPIO 1
    output logic amp_gpio2                          // Amplitude control GPIO 2
);

    // Internal signals
    logic int_osc;                                  // Internal 12MHz oscillator
    logic [DAC_WIDTH-1:0] dac_out;                  // DDS output
    logic sweep_done;                               // Sweep completion from sweep controller
    logic zero_detected;                            // Zero crossing detection
    logic [PHASE_WIDTH-1:0] current_phase_inc;     // Current phase increment for monitoring

    // high frequency oscillator at 12 MHz, suitable for DAC update rate
    HSOSC #(.CLKHF_DIV ("0b10")) hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));

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
        .PHASE_INC_STEP(PHASE_INC_STEP)
    ) dds_dac_inst (
        .clk(int_osc),
        .reset(reset),
        .mcu_ready(mcu_ready),
        .dac_data(dac_data),
        .dac_wr(dac_wr),
        .sweep_done(sweep_done),
        .dac_out(dac_out),
        .current_phase_inc(current_phase_inc)
    );

    // Interface module for MCU communication
    bode_interface #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .DAC_MIDPOINT(DAC_MIDPOINT)
    ) mcu_interface (
        .clk(int_osc),
        .reset(reset),
        .dac_out(dac_out),
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