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
    input  logic quarter_flag,

    // GPIO Outputs
    output logic zero_cross_gpio,      // Zero crossing detected
    output logic freq_change_gpio,     // Frequency just changed
    output logic sweep_done_gpio,      // Sweep completed
    output logic amp_gpio1,            // gpio pin for half amplitude
    output logic amp_gpio2             // gpio pin for 3/4 amplitude
);

    // Zero crossing detection
    logic zero_detected;
    
    // Frequency change detection
    logic [PHASE_WIDTH-1:0] phase_inc_prev;
    logic freq_changed;

    // FSM States
    typedef enum logic [1:0] {UNATTENUATED, HALF_ATTENUATED, QUARTER_ATTENUATED} statetype;
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

    // Frequency change detection
    always_ff @(posedge clk) begin
        if (!reset) begin
            phase_inc_prev <= 0;
            freq_changed <= 0;
        end else begin
            phase_inc_prev <= phase_inc;
            if (phase_inc != phase_inc_prev) begin
                freq_changed <= 1;
            end else begin
                freq_changed <= 0;
            end
        end
    end

    // State register
    always_ff @(posedge clk) begin
        if (!reset) begin
			state <= UNATTENUATED;
        end else begin
			state <= nextstate;	
		end
	end

    // Next state logic
    always_comb begin
        case (state)
            UNATTENUATED: begin
                if (half_flag) begin
                    nextstate = HALF_ATTENUATED;
                end else if (quarter_flag) begin
                    nextstate = QUARTER_ATTENUATED;
                end else if (~half_flag && ~quarter_flag) begin 
                    nextstate = UNATTENUATED;
                end
            end
            HALF_ATTENUATED: begin
                if (~half_flag) begin
                    nextstate = HALF_ATTENUATED;
                end else if (~quarter_flag) begin
                    nextstate = QUARTER_ATTENUATED;
                end else if (half_flag && quarter_flag) begin 
                    nextstate = UNATTENUATED;
                end
            end
            QUARTER_ATTENUATED: begin 
                if (~half_flag) begin
                    nextstate = HALF_ATTENUATED;
                end else if (~quarter_flag) begin
                    nextstate = QUARTER_ATTENUATED;
                end else if (half_flag && quarter_flag) begin 
                    nextstate = UNATTENUATED;
                end
            end
            default: nextstate = UNATTENUATED;
        endcase
    end
               
    // Outputs
    assign zero_cross_gpio = zero_detected;
    assign freq_change_gpio = freq_changed;
    assign sweep_done_gpio = sweep_done;
    assign amp_gpio1 = (state == HALF_ATTENUATED);
    assign amp_gpio2 = (state == QUARTER_ATTENUATED);

endmodule