`timescale 1ns / 100ps
// written 2020-04-01 by mza
// content borrowed from mza-test017.serializer-ram.v
// content borrowed from mza-test031.clock509_and_revo_generator.althea.v
// content borrowed from mza-test032.pll_509divider_and_revo_encoder_plus_calibration_serdes.althea.v
// grabs output from XRM.py corresponding to an array from the bunch current monitor
// last updated 2021-07-02 by mza

// todo:
// implement A/B so we can write into an array while playing back the other
// implement full scatter-gather
// implement slowly rising intensity of a fixed pattern

`define RF_BUCKETS 5120 // set by accelerator geometry/parameters
`define REVOLUTIONS 9 // set by FTSW/TOP firmware
`define BITS_PER_WORD 8 // matches oserdes input width
`define SCALING 2 // off-between-on functionality (@1GHz)

module function_generator_althea #(
	parameter DATA_BUS_WIDTH = 8, // should correspond to corresponding oserdes input width
	parameter ADDRESS_BUS_DEPTH = 14,
	parameter NUMBER_OF_CHANNELS = 1
) (
	input local_clock50_in_p, local_clock50_in_n,
	output bit_out,
	output led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0
);
	wire clock50;
	IBUFGDS clocky (.I(local_clock50_in_p), .IB(local_clock50_in_n), .O(clock50));
	reg reset1 = 1;
	reg reset2 = 1;
	reg reset3 = 1;
	wire rawclock125;
	wire pll_locked;
	simplepll_BASE #(.OVERALL_DIVIDE(1), .MULTIPLY(10), .DIVIDE0(4), .PHASE0(0.0), .PERIOD(20.0)) kronos (.clockin(clock50), .reset(reset1), .clock0out(rawclock125), .clock1out(), .clock2out(), .clock3out(), .clock4out(), .clock5out(), .locked(pll_locked)); // 50->125
	wire clock; // 125 MHz
//	wire clock10;
	BUFG mrt (.I(rawclock125), .O(clock));
//	BUFG mrst (.I(rawclock10), .O(clock10));
	//reg [9:0] bunch_counter = 795;
	//reg [3:0] bucket_counter = 12;
//	reg [9:0] outer_loop_counter = 265;
//	reg [1:0] inner_loop_counter = 2;
//	localparam PRBSWIDTH = 128;
//	wire [PRBSWIDTH-1:0] rand;
//	reg [PRBSWIDTH-1:0] buffered_rand = 0;
//	prbs #(.WIDTH(PRBSWIDTH)) mrpibs (.clock(clock), .reset(reset2), .word(rand));
//	localparam ADDRESS_MAX = (2**ADDRESS_BUS_DEPTH)-1;
	reg [7:0] reset1_counter = 0;
	always @(posedge clock50) begin
		sync <= 0;
		if (reset1) begin
			if (reset1_counter[7]) begin
				reset1 <= 0;
			end
			reset1_counter = reset1_counter + 1'b1;
		end else if (reset2) begin
			if (pll_locked) begin
				reset2 <= 0;
			end
		end else if (reset3) begin
			if (bcm_init_done) begin
				reset3 <= 0;
				sync <= 1;
			end
		end
	end
	wire [ADDRESS_BUS_DEPTH-1:0] write_address;
	wire write_enable;
	wire [DATA_BUS_WIDTH-1:0] data;
	wire bcm_init_done;
	bcm_init bcmi (.clock(clock50), .reset(reset2), .write_address(write_address), .write_enable(write_enable), .data_out(data), .done(bcm_init_done));
//	if (0) begin
//	always @(posedge clock) begin
//		if (reset) begin
//			counter <= 0;
//			data_in <= 0;
//			write_address <= 0;
//			write_enable <= 0;
//			initialized <= 0;
//		end else begin
//			if ((!initialized) && (4==initializing_stage)) begin
//				write_enable <= 1;
//				if (0) begin
//					data_in <= counter;
//				end else if (0) begin
////						data_in <= { counter[9:6], 4'b0000 };
//					if (counter[4:0]==0) begin
//						data_in <= 8'hff;
//					end else if (counter[4:0]==1) begin
//						data_in <= { counter[ADDRESS_BUS_DEPTH-1:ADDRESS_BUS_DEPTH-8] }; // 9:2 or 10:3
//					end else if (counter[4:0]==2) begin
//						data_in[7:ADDRESS_BUS_DEPTH-8] <= 0;
//						data_in[ADDRESS_BUS_DEPTH-9:0] <= counter[ADDRESS_BUS_DEPTH-9:0]; // 1:0 or 2:0
//						//data_in <= { (ADDRESS_BUS_DEPTH-8)'d0, counter[ADDRESS_BUS_DEPTH-9:0] }; // 1:0 or 2:0
//						//data_in <= { 0, counter[ADDRESS_BUS_DEPTH-9:0] }; // 1:0 or 2:0
//					end else if (counter[4:0]==3) begin
//						data_in <= 8'hff;
//					end else begin
//						data_in <= 0;
//					end
//				end else if (0) begin
//					// this mode helps show that there's no shenanigans between BRAM boundaries when using an array of them
//					if (counter[5:0]==0) begin
////						data_in <= 8'h80;
////					end else if (counter[7:0]==1) begin
//						data_in <= counter[ADDRESS_BUS_DEPTH-1:ADDRESS_BUS_DEPTH-8]; // 9:2 or 10:3 or 13:6
////					end else if (counter[4:0]==2) begin
////						data_in[7:ADDRESS_BUS_DEPTH-8] <= 0;
////					end else begin
////						data_in <= 0;
//					end
//				end else if (0) begin
//					// this mode pulses the laser once per microsecond with a pulse width proportional to the location in ram
//					data_in <= 8'h00;
//					if (counter[6:0]==0) begin
//						case (counter[ADDRESS_BUS_DEPTH-1:ADDRESS_BUS_DEPTH-3])
//							3'd0:    data_in <= 8'b10000000;
//							3'd1:    data_in <= 8'b11000000;
//							3'd2:    data_in <= 8'b11100000;
//							3'd3:    data_in <= 8'b11110000;
//							3'd4:    data_in <= 8'b11111000;
//							3'd5:    data_in <= 8'b11111100;
//							3'd6:    data_in <= 8'b11111110;
//							default: data_in <= 8'b11111111;
//						endcase
//					end
//				end else if (0) begin
//					// this mode drives out something like a signal that would come from the bunch current monitor
//					// from 2019-11-15.075530 HER (but simplified/compressed)
//					data_in <= 8'h00;
//					if (outer_loop_counter) begin
//						if (inner_loop_counter==2) begin
//							inner_loop_counter <= inner_loop_counter - 1'b1;
//							data_in <= 8'b10000000;
//						end else if (inner_loop_counter==1) begin
//							inner_loop_counter <= inner_loop_counter - 1'b1;
//							data_in <= 8'b00001000;
//						end else begin
//							data_in <= 8'b00000000;
//							inner_loop_counter <= 2'd2;
//							outer_loop_counter <= outer_loop_counter - 1'b1;
//						end
//					end
//				end else if (1) begin
//					data_in <= 8'h00;
//				end else if (0) begin
//					// this mode drives out something like a single pilot bunch
//					// from 2019-11-15.072853 HER
//					data_in <= 8'h00;
//					if (counter==9989) begin
//						data_in <= 8'b11111111;
//					end
//				end else if (0) begin
//					// this mode drives out only something during the abort gaps
//				end else begin
//					data_in <= buffered_rand[7:0];
//					buffered_rand <= rand;
//				end
//				if (ADDRESS_MAX==counter) begin
//					initialized <= 1;
//				end
//				write_address <= counter;
//				counter <= counter + 1'b1;
//			end else begin
//				data_in <= 0;
//				write_address <= 0;
//				write_enable <= 0;
//			end
//		end
//	end
//	end
	wire [7:0] data_out;
//	assign leds = data_out;
	wire [ADDRESS_BUS_DEPTH-1:0] START_READ_ADDRESS = `RF_BUCKETS * 0 * `SCALING / `BITS_PER_WORD;
	//wire [ADDRESS_BUS_DEPTH-1:0] START_READ_ADDRESS = 0;
	wire [ADDRESS_BUS_DEPTH-1:0] END_READ_ADDRESS = `RF_BUCKETS * 1 * `SCALING / `BITS_PER_WORD;
	//wire [ADDRESS_BUS_DEPTH-1:0] END_READ_ADDRESS = `RF_BUCKETS * REVOLUTIONS * `SCALING / `BITS_PER_WORD; // 11520
	reg sync = 0;
	function_generator #(
		.DATA_BUS_WIDTH(DATA_BUS_WIDTH),
		.ADDRESS_BUS_DEPTH(ADDRESS_BUS_DEPTH),
		.NUMBER_OF_CHANNELS(NUMBER_OF_CHANNELS)
	) fg (
		.write_clock(clock50),
		.read_clock(clock),
		.reset(reset2),
		.channel(2'd1),
		.write_address(write_address),
		.data_in(data),
		.sync_read_address(sync),
		.write_enable(write_enable),
		.start_read_address(START_READ_ADDRESS),
		.end_read_address(END_READ_ADDRESS),
		.data_out(data_out)
//		.output_0(led_0), .output_1(led_1), .output_2(led_2), .output_3(led_3),
//		.output_4(led_4), .output_5(led_5), .output_6(led_6), .output_7(led_7)
	);
	wire oserdes_pll_locked;
	ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(8.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL"), .MODE("WORD_CLOCK_IN"), .PHASE(0.0)) single (.clock_in(clock), .reset(reset3), .word_clock_out(), .word_in(data_out), .D_out(bit_out), .locked(oserdes_pll_locked));
	wire [7:0] leds;
	assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = leds;
	assign leds[7:6] = 0;
	assign leds[5] = ~ oserdes_pll_locked;
	assign leds[4] = reset3;
	assign leds[3] = ~ bcm_init_done;
	assign leds[2] = reset2;
	assign leds[1] = ~ pll_locked;
	assign leds[0] = reset1;
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

