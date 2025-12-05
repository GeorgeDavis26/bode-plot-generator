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
    // f_out = (phase_inc * f_clk) / (2^PHASE_WIDTH)
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
    input logic                    clk,
    input logic                    reset,            // Active low reset
    input logic                    mcu_ready,        // MCU is ready to collect data
    input logic                    mcu_done,         // MCU is done collecting data
    input logic                    full_flag,        // Full amplitude selected
    input logic                    half_flag,        // Half amplitude selected
    output logic [DAC_WIDTH-1:0]   dac_out,
    output logic                   sweep_done,
    output logic [PHASE_WIDTH-1:0] phase_inc_reg     // Current phase increment
);

    // FSM States
    typedef enum logic [2:0] {IDLE, WAIT_AMP, WAIT_MCU, SET_FREQ, MCU_DONE, NEXT_FREQ, DONE} statetype;
    statetype state, nextstate;

    logic [PHASE_WIDTH-1:0] current_step_size;    // Current step size based on decade
    logic [PHASE_WIDTH-1:0] next_step_size;         // Next step size (combinational)

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

     // Calculate next step size based on what the frequency will be
    always_comb begin
        logic [PHASE_WIDTH-1:0] next_phase_inc;
        next_phase_inc = phase_inc_reg + current_step_size;
        
        if (next_phase_inc < PHASE_INC_1KHZ) begin
            next_step_size = PHASE_INC_STEP_100HZ;
        end else if (next_phase_inc < PHASE_INC_10KHZ) begin
            next_step_size = PHASE_INC_STEP_1KHZ;
        end else begin
            next_step_size = PHASE_INC_STEP_10KHZ;
        end
    end

    // State register
    always_ff @(posedge clk) begin
        if (! reset) begin
			state <= IDLE;
        end else begin
			state <= nextstate;	
		end
	end
	
	// logic for control signals
    always_ff @(posedge clk) begin
        if (!reset) begin
            phase_inc_reg <= PHASE_INC_MIN;
            dac_out_reg <= 8'h80;
        end else begin
            case (state)
                IDLE: begin
                    phase_inc_reg <= PHASE_INC_MIN;
                    current_step_size <= PHASE_INC_STEP_100HZ;  // reset to first decade
                    dac_out_reg <= 8'h80;  // Hold at midpoint until amplitude selected
                end

                WAIT_AMP: begin
                    phase_inc_reg <= PHASE_INC_MIN;
                    current_step_size <= PHASE_INC_STEP_100HZ;  // reset to first decade
                    dac_out_reg <= 8'h80;  // Hold at midpoint until amplitude selected
                end

                WAIT_MCU: begin 
                    // Waiting for MCU ready flag
                    // Update step size for the current frequency
                    if (phase_inc_reg < PHASE_INC_1KHZ) begin
                        current_step_size <= PHASE_INC_STEP_100HZ;
                    end else if (phase_inc_reg < PHASE_INC_10KHZ) begin
                        current_step_size <= PHASE_INC_STEP_1KHZ;
                    end else begin
                        current_step_size <= PHASE_INC_STEP_10KHZ;
                    end
                end

                SET_FREQ: begin
                    // frequency is set
                end

                MCU_DONE: begin
                    // wait until the MCU is done collecting data
                end

                NEXT_FREQ: begin
                    if (phase_inc_reg + current_step_size >= PHASE_INC_MAX) begin
                        phase_inc_reg <= PHASE_INC_MAX;  // Clamp to max
                    end else begin
                        phase_inc_reg <= phase_inc_reg + current_step_size;
                    end
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
                nextstate = WAIT_AMP;
            end

            WAIT_AMP: begin
                // Stay here until an amplitude setting is selected
                if ((~full_flag && half_flag) || (full_flag && ~half_flag) ) begin
                    nextstate = WAIT_MCU;  // Amplitude selected, now wait for MCU
                end else begin
                    nextstate = WAIT_AMP;  // Stay and wait for amplitude selection
                end
            end

            WAIT_MCU: begin
                if (mcu_ready) begin
                    nextstate = SET_FREQ;
                end else begin
                    nextstate = WAIT_MCU;
                end
            end

            SET_FREQ: begin
                nextstate = MCU_DONE;
            end

            MCU_DONE: begin  // MCU is done collecting data
                if (mcu_done) begin
                    nextstate = NEXT_FREQ;
                end else begin
                    nextstate = MCU_DONE;
                end
            end

            NEXT_FREQ: begin
                if (phase_inc_reg >= PHASE_INC_MAX) begin
                    nextstate = DONE;
                end else begin
                    nextstate = WAIT_MCU;
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