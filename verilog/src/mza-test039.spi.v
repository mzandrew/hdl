// to run on an icezero

// written 2020-05-05 by mza
// last updated 2020-05-06 by mza

//`include "lib/synchronizer.v"
//`include "lib/easypll.v"
`include "lib/spi.v"

module top (
	input clock100,
	input rpi_spi_sclk,
	input rpi_spi_mosi,
	output rpi_spi_miso,
	input rpi_spi_ce0,
	input rpi_spi_ce1,
	output pmod4_5,
	output pmod4_6,
	output pmod4_7,
	output pmod4_8,
	output led1,
	output led2,
	output led3
);
	reg reset = 1;
	reg [7:0] reset_counter = 0;
	always @(posedge clock100) begin
		if (reset) begin
			if (reset_counter[7]) begin
				reset <= 0;
			end else begin
				reset_counter <= reset_counter + 1'b1;
			end
		end
	end
	wire [7:0] data_from_master;
	wire [7:0] data_to_master;
	wire data_valid;
	SPI_slave spis (.clk(clock100), .SCK(rpi_spi_sclk), .MOSI(rpi_spi_mosi), .MISO(rpi_spi_miso), .SSEL(rpi_spi_ce0), .LED(), .data_to_master(data_to_master), .data_from_master(data_from_master), .data_valid(data_valid));
	reg [7:0] previous_data_from_master = 0;
	always @(posedge clock100) begin
		if (data_valid) begin
			previous_data_from_master <= data_from_master;
		end
	end
	assign data_to_master = previous_data_from_master;
//	assign led1 = reset;
//	assign led2 = ~rpi_spi_ce0;
	wire [2:0] leds = { led1, led2, led3 };
	assign leds = data_from_master[2:0];
	assign pmod4_5 = rpi_spi_sclk;
	assign pmod4_6 = rpi_spi_mosi;
	assign pmod4_7 = rpi_spi_ce0;
	assign pmod4_8 = rpi_spi_ce1;
//	assign rpi_spi_miso = 0;
endmodule

