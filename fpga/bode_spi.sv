// authors: George Davis and Matthew Molinar
// emails: gdavis@hmc.edu and mmolinar@hmc.edu
// date created: 11/22/2025

// bode_spi.sv

/////////////////////////////////////////////
// Bode Plot Generator SPI
// SPI interface between the FPGA and MCU
// that sends amplitude data to the MCU
/////////////////////////////////////////////

module bode_spi #(
    parameter DAC_WIDTH = 8,
    parameter PHASE_WIDTH = 32,
    parameter DAC_MIDPOINT = 8'h80
)(
    input  logic clk,
    input  logic reset,
    input  logic [DAC_WIDTH-1:0] dac_out,
    input  logic [PHASE_WIDTH-1:0] phase_inc,
    input  logic sweep_done,

    // SPI
    input  logic sck, 
    input  logic cs,
    input  logic sdi,
    output logic sdo,

    // GPIO Outputs
    output logic zero_cross_gpio,      // Zero crossing detected
    output logic freq_change_gpio,     // Frequency just changed
    output logic sweep_done_gpio       // Sweep completed
);

    // Zero crossing detection
    logic zero_detected;
    
    // Frequency change detection
    logic [PHASE_WIDTH-1:0] phase_inc_prev;
    logic freq_changed;
    
    // SPI
    logic [7:0] spi_rx_data;
    logic [7:0] spi_shift_reg;

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

    // SPI RX
    always_ff @(posedge sck) begin
        if (!reset) begin  // spi active when chip select is low
            spi_rx_data <= 0;
        end else if (!cs) begin
        spi_rx_data <= {spi_rx_data[6:0], sdi};
        end
    end

    // SPI TX
    // SPI mode is equivalent to cpol = 0, cpha = 0 since data is sampled on first edge and the first
    // edge is a rising edge (clock going from low in the idle state to high).
    always_ff @(negedge sck) begin
        if (!reset) begin
            spi_shift_reg <= 0;
        end else if (cs) begin
            spi_shift_reg <= dac_out;
        end else begin
            // shift out data when CS is active
            spi_shift_reg <= {spi_shift_reg[6:0], 1'b0};
        end
    end

    // SDO: if cs is active get MSB of spi_shift_reg
    // else output 0
    assign sdo = (!cs) ? spi_shift_reg[7] : 1'b0;

    // Outputs
    assign zero_cross_gpio = zero_detected;
    assign freq_change_gpio = freq_changed;
    assign sweep_done_gpio = sweep_done;

endmodule