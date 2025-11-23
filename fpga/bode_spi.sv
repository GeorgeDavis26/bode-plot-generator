// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/22/2025

// bode_spi.sv

/////////////////////////////////////////////
// Bode Plot Generator SPI
// SPI interface between the FPGA and MCU
// that sends amplitude data to the MCU
/////////////////////////////////////////////

module bode_spi (
    input  logic clk,
    input  logic reset,

    // SPI
    input  logic sck, 
    input  logic sdi,
    input  logic done,
    output logic sdo,

    output logic zero_cross  // flag for whenever there's a zero-crossing 
);

    logic         sdodelayed, wasdone;

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

endmodule