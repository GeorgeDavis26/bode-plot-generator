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
    parameter int    SAMPLES_PER_FREQ = 1024,      // Number of samples per frequency
    parameter int    PHASE_INC_MIN = 1,            // Minimum phase increment
    parameter int    PHASE_INC_MAX = 1,            // Maximum phase increment
    parameter int    PHASE_INC_STEP = 1            // Step size for phase increment
) (
    input logic                   clk,
    input logic                   reset,            // Active low reset
    output logic [PHASE_WIDTH-1:0] phase_inc,
    output logic [DAC_WIDTH-1:0]  dac_out
);

    // FSM States
    typedef enum logic [2:0] {IDLE, SET_FREQ, COUNT_SAMPLES, NEXT_FREQ, DONE} statetype;
    statetype state, nextstate;

    logic [PHASE_WIDTH-1:0] phase_inc_reg;         // Current phase increment
    logic [31:0] sample_counter;                   // Counter for samples per frequency

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
        .dac_out(dac_out)
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
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            phase_inc_reg <= PHASE_INC_MIN;
            sample_counter <= 0;
        end else begin
            case (state)
                IDLE: begin
                    phase_inc_reg <= PHASE_INC_MIN;
                    sample_counter <= 0;
                end
                SET_FREQ:
                COUNT_SAMPLES: begin
                    sample_counter <= sample_counter + 1;
                end
                NEXT_FREQ: begin
                    if (phase_inc_reg + PHASE_INC_STEP <= PHASE_INC_MAX) begin
                        phase_inc_reg <= phase_inc_reg + PHASE_INC_STEP;
                    end else begin
                        phase_inc_reg <= PHASE_INC_MIN; // Start Again
                    end
                    sample_counter <= 0;
                end
            endcase
        end
    end

    // Next state logic
    always_comb begin
        case (current_state)
            IDLE: begin
                if (reset) begin
                    next_state = SET_FREQ;
                end
            end
            SET_FREQ: begin
                next_state = COUNT_SAMPLES;
            end
            COUNT_SAMPLES: begin
                if (sample_counter >= SAMPLES_PER_FREQ) begin
                    next_state = NEXT_FREQ;
                end
            end
            NEXT_FREQ: begin
                if() begin
                    next_state = DONE
                end else begin
                    next_state = SET_FREQ;
            end
        endcase
    end

    // Output Logic
    assign phase_inc = phase_inc_reg;

endmodule