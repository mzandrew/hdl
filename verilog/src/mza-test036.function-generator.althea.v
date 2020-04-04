`timescale 1ns / 1ps
// written 2020-04-01 by mza
// content borrowed from mza-test017.serializer-ram.v
// content borrowed from mza-test031.clock509_and_revo_generator.althea.v
// content borrowed from mza-test032.pll_509divider_and_revo_encoder_plus_calibration_serdes.althea.v
// last updated 2020-04-04 by mza

module function_generator_althea #(
	parameter DATA_BUS_WIDTH = 8, // should correspond to corresponding oserdes input width
	parameter ADDRESS_BUS_DEPTH = 14,
	parameter NUMBER_OF_CHANNELS = 1
) (
	input local_clock50_in_p, local_clock50_in_n,
	output bit_out,
	output led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0
);
	wire [7:0] leds;
	assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = leds;
	wire clock50;
	IBUFDS clocky (.I(local_clock50_in_p), .IB(local_clock50_in_n), .O(clock50));
	reg reset = 1;
	wire rawclock125;
	wire pll_locked;
	simplepll_BASE #(.overall_divide(1), .multiply(10), .divide0(4), .phase0(0.0), .period(20.0)) kronos (.clockin(clock50), .reset(reset), .clock0out(rawclock125), .locked(pll_locked)); // 50->125
	assign leds[0] = pll_locked;
	wire clock; // 125 MHz
	BUFG mrt (.I(rawclock125), .O(clock));
	reg [DATA_BUS_WIDTH-1:0] data_in = 0;
	reg [ADDRESS_BUS_DEPTH-1:0] write_address = 0;
	reg write_enable = 1;
	reg initialized = 0;
	reg [7:0] reset_counter = 0;
	localparam PRBSWIDTH = 128;
	wire [PRBSWIDTH-1:0] rand;
	reg [PRBSWIDTH-1:0] buffered_rand = 0;
	prbs #(.WIDTH(PRBSWIDTH)) mrpibs (.clock(clock), .reset(reset), .word(rand));
	localparam ADDRESS_MAX = (2**ADDRESS_BUS_DEPTH)-1;
	always @(posedge clock50) begin
		if (reset) begin
			if (reset_counter[7]) begin
				reset <= 0;
			end
			reset_counter = { reset_counter + 1 }[7:0];
		end
	end
	reg [ADDRESS_BUS_DEPTH-1:0] counter = 0;
	always @(posedge clock) begin
		if (reset) begin
			counter <= 0;
			data_in <= 0;
			write_address <= 0;
			write_enable <= 0;
			initialized <= 0;
		end else begin
			if (!initialized) begin
				write_enable <= 1;
				if (0) begin
					data_in <= counter;
				end else if (0) begin
//						data_in <= { counter[9:6], 4'b0000 };
					if (counter[4:0]==0) begin
						data_in <= 8'hff;
					end else if (counter[4:0]==1) begin
						data_in <= { counter[ADDRESS_BUS_DEPTH-1:ADDRESS_BUS_DEPTH-8] }; // 9:2 or 10:3
					end else if (counter[4:0]==2) begin
						data_in[7:ADDRESS_BUS_DEPTH-8] <= 0;
						data_in[ADDRESS_BUS_DEPTH-9:0] <= counter[ADDRESS_BUS_DEPTH-9:0]; // 1:0 or 2:0
						//data_in <= { (ADDRESS_BUS_DEPTH-8)'d0, counter[ADDRESS_BUS_DEPTH-9:0] }; // 1:0 or 2:0
						//data_in <= { 0, counter[ADDRESS_BUS_DEPTH-9:0] }; // 1:0 or 2:0
					end else if (counter[4:0]==3) begin
						data_in <= 8'hff;
					end else begin
						data_in <= 0;
					end
				end else if (1) begin
					if (counter[5:0]==0) begin
//						data_in <= 8'h80;
//					end else if (counter[7:0]==1) begin
						data_in <= counter[ADDRESS_BUS_DEPTH-1:ADDRESS_BUS_DEPTH-8]; // 9:2 or 10:3 or 13:6
//					end else if (counter[4:0]==2) begin
//						data_in[7:ADDRESS_BUS_DEPTH-8] <= 0;
//					end else begin
//						data_in <= 0;
					end
				end else begin
					data_in <= buffered_rand[7:0];
					buffered_rand <= rand;
				end
				if (ADDRESS_MAX==counter) begin
					initialized <= 1;
				end
				write_address <= counter;
				counter <= { counter + 1 }[ADDRESS_BUS_DEPTH-1:0];
			end else begin
				data_in <= 0;
				write_address <= 0;
				write_enable <= 0;
			end
		end
	end
	wire [7:0] data_out;
//	assign leds = data_out;
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
		.data_out(data_out)
//		.output_0(led_0), .output_1(led_1), .output_2(led_2), .output_3(led_3),
//		.output_4(led_4), .output_5(led_5), .output_6(led_6), .output_7(led_7)
	);
	wire oserdes_pll_locked;
	ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(20.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL"), .MODE("WORD_CLOCK_IN"), .PHASE(0.0)) single (.clock_in(clock), .reset(reset), .word_clock_out(), .word_in(data_out), .D_out(bit_out), .locked(oserdes_pll_locked));
	assign leds[1] = oserdes_pll_locked;
	assign leds[7:2] = 5'd0;
endmodule

module function_generator_althea_tb;
	reg clock50_p = 0;
	reg clock50_n = 0;
	wire lemo;
	wire led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0;
	function_generator_althea #(
		.DATA_BUS_WIDTH(8), // should correspond to corresponding oserdes input width
		.ADDRESS_BUS_DEPTH(14),
		.NUMBER_OF_CHANNELS(1)
	) fga (
		.local_clock50_in_p(clock50_p), .local_clock50_in_n(clock50_n),
		.bit_out(lemo),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
	initial begin
		clock50_p <= 0; clock50_n <= 1;
	end
	always begin
		#10;
		clock50_p = ~clock50_p;
		clock50_n = ~clock50_n;
	end
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
	output lemo,
	output led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0
);
	function_generator_althea #(
		.DATA_BUS_WIDTH(8), // should correspond to corresponding oserdes input width
		.ADDRESS_BUS_DEPTH(14),
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
		.bit_out(lemo),
//		.led_revo(l_n),
//		.led_rfclock(l_p),
//		.driven_high(g_p), .clock_select(g_n),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
endmodule

