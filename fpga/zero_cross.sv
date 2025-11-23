// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/23/2025

// zero_cross.sv

/////////////////////////////////////////////
// Zero Cross Detection used for phase extraction
// Detects zero crossings from the DDS
/////////////////////////////////////////////

module zero_cross #(
    parameter DAC_WIDTH = 8,
    parameter DAC_MIDPOINT = 8'h80  // midpoint is 128
) (
    input  logic clk,
    input  logic reset,
    input  logic [DAC_WIDTH-1:0] dac_out,
    output logic zero_cross
);

    logic [DAC_WIDTH-1:0] dac_prev;
    logic [7:0] dac_lower, dac_upper;
    logic zero_detected;
    
    // add some range to avoid noise around the zero crossings
    assign dac_lower = DAC_MIDPOINT - 2;
    assign dac_upper = DAC_MIDPOINT + 2;

    // Zero crossing detection
    always_ff @(posedge clk) begin
        if (!reset) begin
            dac_prev <= DAC_MIDPOINT;
            zero_detected <= 0;
        end else begin
            dac_prev <= dac_out;
            
            // Detect rising zero crossing
            if (dac_prev < dac_lower && dac_out > dac_upper) begin
                zero_detected <= 1;
            end else begin
                zero_detected <= 0;
            end
        end
    end

    // Output
    assign zero_cross = zero_detected;

endmodule