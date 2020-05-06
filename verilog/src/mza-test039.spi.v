// to run on an icezero

// written 2020-05-05 by mza
// last updated 2020-05-06 by mza

//`include "lib/synchronizer.v"
//`include "lib/easypll.v"

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
	assign led1 = reset;
	assign led2 = ~rpi_spi_ce0;
	assign led3 = 0;
	assign pmod4_5 = rpi_spi_sclk;
	assign pmod4_6 = rpi_spi_mosi;
	assign pmod4_7 = rpi_spi_ce0;
	assign pmod4_8 = rpi_spi_ce1;
	assign rpi_spi_miso = 0;
endmodule

