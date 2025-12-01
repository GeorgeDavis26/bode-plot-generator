// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/20/2025

// sweep_controller.sv

/////////////////////////////////////////////
// Sweep Controller module -

// Generates a time varying phase increments
// which will allow for a frequency sweep
/////////////////////////////////////////////

module sweep_controller # (
    // DDS paramters
    parameter int    DAC_WIDTH = 8,                 // Bit width for external DAC
    parameter int    PHASE_WIDTH = 32,             // Width phase accumulator
    parameter int    FULL_WAVE = 256,              // Size of full sine wave
    parameter        LUT_FILE = "dds_lut.txt",     // ROM for LUT

    // Sweep Controller Parameters
    // f_out = (phase_inc * f_clk) / (2^PHASE_WIDTH-1)
    parameter int    SAMPLES_PER_FREQ = 1024,       // Number of samples per frequency
    parameter int    PHASE_INC_MIN = 35791,         // Minimum phase increment (~100 Hz)
    parameter int    PHASE_INC_MAX = 35791394,     // Maximum phase increment (~100 kHz)
    parameter int    PHASE_INC_STEP = 35791         // Step size for phase increment (~100 Hz steps)
) (
    input logic                   clk,
    input logic                   reset,            // Active low reset
    input logic                   mcu_ready,
    output logic [DAC_WIDTH-1:0]  dac_out,
    output logic                  sweep_done
);

    // FSM States
    typedef enum logic [2:0] {IDLE, WAIT_MCU, SET_FREQ, COUNT_SAMPLES, NEXT_FREQ, DONE} statetype;
    statetype state, nextstate;

    logic [PHASE_WIDTH-1:0] phase_inc_reg;         // Current phase increment
    logic [31:0] sample_counter;                   // Counter for samples per frequency

    // DDS output registers
    logic [DAC_WIDTH-1:0] dac_out_reg;
    logic [DAC_WIDTH-1:0] dds_out_reg;

    // DDS Instance
    dds #(
        .DAC_WIDTH(DAC_WIDTH),
        .PHASE_WIDTH(PHASE_WIDTH),
        .FULL_WAVE(FULL_WAVE),
        .LUT_FILE(LUT_FILE)
    ) dds (
        .clk(clk),
        .reset(reset),
        .phase_inc(phase_inc_reg),
        .dac_out(dds_out_reg)
    );

    // State register
    always_ff @(posedge clk) begin
        if (!reset) begin
			state <= IDLE;
        end else begin
			state <= nextstate;	
		end
	end
	
	// logic for control signals
    always_ff @(posedge clk) begin
        if (!reset) begin
            phase_inc_reg <= PHASE_INC_MIN;
            sample_counter <= 0;
            dac_out_reg <= 8'h80;
        end else begin
            case (state)
                IDLE: begin
                    phase_inc_reg <= PHASE_INC_MIN;
                    sample_counter <= 0;
                end
                WAIT_MCU: begin 
                    // Waiting for MCU ready flag
                end
                SET_FREQ: begin
                end
                COUNT_SAMPLES: begin
                    sample_counter <= sample_counter + 1;
                end
                NEXT_FREQ: begin
                    if (phase_inc_reg + PHASE_INC_STEP <= PHASE_INC_MAX) begin
                        phase_inc_reg <= phase_inc_reg + PHASE_INC_STEP;
                    end
                    sample_counter <= 0;
                end
                DONE: begin
                    // Stay in DONE and stop the sweep
                    dac_out_reg <= 8'h80;
                end
            endcase
        end
    end

    // Next state logic
    always_comb begin
        case (state)
            IDLE: begin
                nextstate = SET_FREQ;
            end
            WAIT_MCU: begin
                if (mcu_ready) begin
                    nextstate = SET_FREQ;
                end else begin
                    nextstate = WAIT_MCU;  // Stay and wait for MCU
                end
            end
            SET_FREQ: begin
                nextstate = COUNT_SAMPLES;
            end
            COUNT_SAMPLES: begin
                if (sample_counter >= SAMPLES_PER_FREQ) begin
                    nextstate = NEXT_FREQ;
                end else begin
                    nextstate = COUNT_SAMPLES;
                end
            end
            NEXT_FREQ: begin
                if (phase_inc_reg + PHASE_INC_STEP <= PHASE_INC_MAX) begin
                    nextstate = SET_FREQ;
                end else begin
                    nextstate = DONE;
                end
            end
            DONE: begin
                nextstate = DONE;  // Stay in DONE until reset
            end
            default: begin
                nextstate = state;
            end
        endcase
    end

    // Output Logic
    assign dac_out = sweep_done ? dac_out_reg : dds_out_reg;
    assign sweep_done = (state == DONE);

endmodule