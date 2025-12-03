// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/22/2025

// bode_interface.sv

/////////////////////////////////////////////
// Bode Plot Generator Interface
// Interface between the FPGA and MCU
/////////////////////////////////////////////

module bode_interface #(
    parameter DAC_WIDTH = 8,
    parameter PHASE_WIDTH = 32,
    parameter DAC_MIDPOINT = 8'h80
)(
    input  logic clk,
    input  logic reset,
    input  logic [DAC_WIDTH-1:0] dac_out,
    input  logic [PHASE_WIDTH-1:0] phase_inc,
    input  logic sweep_done,
    input  logic half_flag,
    input  logic full_flag,

    // GPIO Outputs
    output logic zero_cross_gpio,      // Zero crossing detected
    output logic sweep_done_gpio,      // Sweep completed
    output logic amp_gpio1,            // gpio pin for half amplitude
    output logic amp_gpio2             // gpio pin for full amplitude
);

    // Zero crossing detection
    logic zero_detected;

    // FSM States
    typedef enum logic [1:0] {IDLE, HALF_ATTENUATED, FULL} statetype;
    statetype state, nextstate;

    // Zero cross detection
    zero_cross #(
        .DAC_WIDTH(DAC_WIDTH),
        .DAC_MIDPOINT(DAC_MIDPOINT)
    ) zero_cross_detect (
        .clk(clk),
        .reset(reset),
        .dac_out(dac_out),
        .zero_cross(zero_detected)
    );

    // State register
    always_ff @(posedge clk) begin
        if (!reset) begin
			state <= IDLE;
        end else begin
			state <= nextstate;	
		end
	end

    // Next state logic
    always_comb begin
        case (state)
            IDLE: begin
                if (~half_flag && full_flag) begin
                    nextstate = HALF_ATTENUATED;
                end else if (~full_flag && half_flag) begin
                    nextstate = FULL;
                end else begin
                    nextstate = IDLE;
                end
            end
            HALF_ATTENUATED: begin
                nextstate = HALF_ATTENUATED;
            end
            FULL: begin 
                nextstate = FULL;
            end
            default: nextstate = IDLE;
        endcase
    end
               
    // Outputs
    assign zero_cross_gpio = zero_detected;
    assign sweep_done_gpio = sweep_done;
    assign amp_gpio1 = (state == HALF_ATTENUATED);
    assign amp_gpio2 = (state == FULL);

endmodule