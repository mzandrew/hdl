`timescale 1ns / 1ps
// written 2020-04-01 by mza
// last updated 2020-04-01 by mza

module function_generator_althea #(
	parameter DATA_BUS_WIDTH = 8, // should correspond to corresponding oserdes input width
	parameter ADDRESS_BUS_DEPTH = 10,
	parameter NUMBER_OF_CHANNELS = 1
) (
	input local_clock50_in_p, local_clock50_in_n,
	output led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7
);
	wire clock;
	wire [7:0] leds;
	assign { led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7 } = leds;
	IBUFDS clocky (.I(local_clock50_in_p), .IB(local_clock50_in_n), .O(clock));
	reg [DATA_BUS_WIDTH-1:0] data_in = 8'h5a;
	reg [ADDRESS_BUS_DEPTH-1:0] write_address = 10'b000001000;
	reg write_enable = 1;
	wire reset;
	assign reset = 0;
	always @(posedge clock) begin
		if (reset) begin
			data_in <= 8'ha5;
			write_address <= 10'b0010000000;
			write_enable <= 0;
		end else begin
		end
	end
	function_generator #(
		.DATA_BUS_WIDTH(DATA_BUS_WIDTH),
		.ADDRESS_BUS_DEPTH(ADDRESS_BUS_DEPTH),
		.NUMBER_OF_CHANNELS(NUMBER_OF_CHANNELS)
	) fg (
		.clock(clock),
		.reset(reset),
		.channel(2'd1),
		.write_address(write_address),
		.data_in(data_in),
		.write_enable(write_enable),
		.data_out(leds)
//		.output_0(led_0), .output_1(led_1), .output_2(led_2), .output_3(led_3),
//		.output_4(led_4), .output_5(led_5), .output_6(led_6), .output_7(led_7)
	);
endmodule

//module mza_test036_function_generator_althea (
module althea (
	input clock50_p, clock50_n,
//	input a_p, a_n,
//	output b_p, b_n,
//	input c_p, c_n,
//	output d_p, d_n,
//	output e_p, e_n,
//	output f_p, f_n,
//	input g_p, g_n,
//	input h_p, h_n,
//	input j_p, j_n,
//	input k_p, k_n,
//	output l_p, l_n,
//	output lemo,
	output led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7
);
	function_generator_althea #(
		.DATA_BUS_WIDTH(8), // should correspond to corresponding oserdes input width
		.ADDRESS_BUS_DEPTH(10),
		.NUMBER_OF_CHANNELS(1)
	) fga (
		.local_clock50_in_p(clock50_p), .local_clock50_in_n(clock50_n),
//		.local_clock509_in_p(j_p), .local_clock509_in_n(j_n),
//		.remote_clock509_in_p(k_p), .remote_clock509_in_n(k_n),
//		.remote_revo_in_p(h_p), .remote_revo_in_n(h_n),
//		.ack12_p(a_p), .ack12_n(a_n),
//		.trg36_p(f_p), .trg36_n(f_n),
//		.rsv54_p(c_p), .rsv54_n(c_n),
//		.clk78_p(d_p), .clk78_n(d_n),
//		.out1_p(e_p), .out1_n(e_n),
//		.outa_p(b_p), .outa_n(b_n),
//		.lemo(lemo),
//		.led_revo(l_n),
//		.led_rfclock(l_p),
//		.driven_high(g_p), .clock_select(g_n),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
endmodule

