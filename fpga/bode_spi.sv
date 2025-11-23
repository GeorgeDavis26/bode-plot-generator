// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/22/2025

// bode_spi.sv

/////////////////////////////////////////////
// Bode Plot Generator SPI
// SPI interface between the FPGA and MCU
// and detects zero crossings from the DDS
/////////////////////////////////////////////

module bode_spi #(
    parameter DAC_WIDTH = 8,
    parameter DAC_MIDPOINT = 8'h80  // midpoint is 128
) (
    input  logic clk,
    input  logic reset,
    input  logic [DAC_WIDTH-1:0] dac_out,

    // SPI
    input  logic sck, 
    input  logic sdi,
    input  logic done,
    output logic sdo,

    output logic zero_cross  // flag for whenever there's a zero-crossing 
);

    logic         sdodelayed, wasdone;

    // Zero crossing detection
    logic [DAC_WIDTH-1:0] dac_prev;
    logic zero_crossing;
    logic zero_detected;

    // Zero crossing detection
    always_ff @(posedge clk) begin
        if (!reset) begin
            dac_prev <= DAC_MIDPOINT;
            zero_crossing <= 0;
            zero_detected <= 0;
        end else begin
            dac_prev <= dac_out;
            
            // Detect rising zero crossing
            if (dac_prev < DAC_MIDPOINT && dac_out >= DAC_MIDPOINT) begin
                zero_crossing <= 1;
                zero_detected <= 1;
            end else begin
                zero_crossing <= 0;
            end
        end
    end

    // assert load
    // SPI mode is equivalent to cpol = 0, cpha = 0 since data is sampled on first edge and the first
    // edge is a rising edge (clock going from low in the idle state to high).
    always_ff @(posedge sck)
        if (!wasdone)  {zero_detected, zero_cross} = {dac_prev[6:0], sdi};
        else           {zero_detected, zero_cross} = {dac_out[6:0], sdi};

    // sdo should change on the negative edge of sck
    always_ff @(negedge sck) begin
        wasdone = done;
        sdodelayed = dac_out[7];
    end
    
    // when done is first asserted, shift out msb before clock edge
    assign sdo = (done & !wasdone) ? dac_out[7] : sdodelayed;

    // Output
    assign zero_cross = zero_crossing;

endmodule