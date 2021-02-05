// written 2018-08-16 by mza
// based on mza-test013.i2c.v and mza-test003.double-dabble.v
// updated 2020-06-01 by mza
// last updated 2021-02-04 by mza

`define icestick
`include "lib/hex2bcd.v"
`include "lib/uart.v"
`include "lib/easypll.v"
`include "lib/segmented_display_driver.v"
`include "lib/prbs.v"
`include "lib/fifo.v"

module mytop (
	input clock,
	output [5:1] LED,
	output [7:0] J1,
	inout [7:0] J2,
	output [7:0] J3,
	input RX,
	output TX
);
	wire fast_clock;
	wire pll_is_locked;
	//easypll my_96MHz_pll_instance (.clock_input(clock), .reset_active_low(1), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 96 MHz
	easypll #(.DIVR(0), .DIVF(49), .DIVQ(2), .FILTER_RANGE(1)) my_162MHz_pll_instance (.clock_input(clock), .reset_active_low(1), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 150 MHz
	//easypll #(.DIVR(0), .DIVF(53), .DIVQ(2), .FILTER_RANGE(1)) my_162MHz_pll_instance (.clock_input(clock), .reset_active_low(1), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 162 MHz
	//easypll #(.DIVR(0), .DIVF(55), .DIVQ(2), .FILTER_RANGE(1)) my_162MHz_pll_instance (.clock_input(clock), .reset_active_low(1), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 168 MHz
	//easypll #(.DIVR(0), .DIVF(57), .DIVQ(2), .FILTER_RANGE(1)) my_162MHz_pll_instance (.clock_input(clock), .reset_active_low(1), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 174 MHz
	//easypll #(.DIVR(0), .DIVF(66), .DIVQ(2), .FILTER_RANGE(1)) my_162MHz_pll_instance (.clock_input(clock), .reset_active_low(1), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 201 MHz
	//easypll #(.DIVR(0), .DIVF(44), .DIVQ(1), .FILTER_RANGE(1)) my_162MHz_pll_instance (.clock_input(clock), .reset_active_low(1), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 270 MHz
	reg [31:0] fast_clock_counter = 0;
	always @(posedge fast_clock) begin
		if (reset) begin
			trigger_duration <= 0;
			trigger_stream <= 0;
			number_of_pulses <= 0;
			accumulated_trigger_duration <= 0;
			previous_trigger_duration <= 0;
		end else if (pll_is_locked) begin
			fast_clock_counter++;
			if (trigger_active==1) begin
				trigger_duration++;
			end else begin
				if (trigger_stream==3'b110) begin
					number_of_pulses++;
					previous_trigger_duration <= trigger_duration;
					accumulated_trigger_duration <= accumulated_trigger_duration + trigger_duration;
					trigger_duration <= 0;
//					//previous_trigger_duration <= { 13'h0, trigger_stream };
				end
			end
			trigger_stream <= { trigger_stream[1:0], trigger_active }; // 110, 100, 000 or 001, 011, 111
		end
	end
	// for an HDSP-B04E mounted pin7=pin14 justified on an icestick-test revA ZIF-socket board (IDL_18_027)
	wire [6:0] segment;
	assign { J3[3], J1[2], J2[0], J3[0], J3[2], J3[5], J1[1] } = segment;
	assign J3[1] = 1; // dp/colon
	wire [3:0] anode;
	assign { J1[0], J1[3], J1[4], J3[4] } = anode;
	segmented_display_driver #(.NUMBER_OF_SEGMENTS(7), .NUMBER_OF_NYBBLES(4)) my_instance_name (.clock(clock), .data(buffered_bcd2[15:0]), .cathode(segment), .anode(anode), sync_anode(), .sync_cathode());
//	reg trigger_active = 0;
	wire trigger_active;
	reg [2:0] trigger_stream = 0;
	reg [31:0] accumulated_trigger_duration = 0;
	reg [31:0] trigger_duration = 0; // live
	reg [31:0] previous_trigger_duration = 0; // updated after pulse ends
	assign J3[7] = 0;
	reg signal_output = 0;
	assign J3[6] = signal_output;
//	assign signal_output = trigger_active; // use this for internal loopback
	assign J2[7:6] = 0;
	assign J2[5] = trigger_active;
	assign J2[4:1] = 0;
	assign J1[7:5] = 0;
	assign LED[5] = uart_busy;
	assign LED[4] = signal_output;
	assign LED[3] = trigger_stream[2];
	assign LED[2] = trigger_stream[1];
	assign LED[1] = trigger_stream[0];
	reg [31:0] counter = 0;
	localparam length_of_line = 6+6+2;
	reg [7:0] uart_character_counter = 0;
	reg uart_transfers_are_allowed = 0;
	localparam uart_character_pickoff = 11; // this is already close to the limit for 115200
	localparam uart_line_pickoff = 22;
	localparam slow_clock_pickoff = uart_line_pickoff;
	reg [15:0] uart_line_counter = 0;
	wire uart_resetb;
	reg reset = 1;
	assign uart_resetb = ~reset;
	localparam log2_of_function_generator_period = uart_line_pickoff;
	//localparam function_generator_start = 2**(log2_of_function_generator_period-1);
	localparam function_generator_start = 0;
	reg [9:0] pulse_duration = 0;
	reg [31:0] previous_number_of_pulses = 0;
	reg [31:0] number_of_pulses = 0;
	always @(posedge clock) begin
		counter++;
		if (reset) begin
			uart_line_counter <= 0;
			uart_character_counter <= length_of_line - 1;
			uart_transfers_are_allowed <= 0;
			signal_output <= 0;
			if (counter[10]==1) begin
				reset <= 0;
			end
		end else begin
			//if (counter[31:0]>1500 & counter[31:0]<2000) begin
			if (counter[log2_of_function_generator_period:0]>function_generator_start) begin
				if (counter[log2_of_function_generator_period:0]<function_generator_start+pulse_duration) begin
					signal_output <= 1;
				end else begin
					signal_output <= 0;
				end
			end else begin
				signal_output <= 0;
			end
		end
		if (counter[slow_clock_pickoff:0]==0) begin
			buffered_bcd1 <= bcd1;
			buffered_bcd2 <= bcd2;
			buffered_rand <= rand;
		end else if (counter[slow_clock_pickoff:0]==1) begin
			//value1 <= uart_line_counter;
			value2 <= previous_trigger_duration; // TDC mode
			value1 <= number_of_pulses; // scaler mode
			pulse_duration <= buffered_rand[8:0]; // when doing loopback, this should depend on pll frequency
//		end else if (counter[slow_clock_pickoff:0]==2) begin
		end
		if (counter[uart_line_pickoff:0]==0) begin // less frequent
			if (previous_number_of_pulses!=number_of_pulses) begin
				uart_transfers_are_allowed <= 1;
				uart_line_counter++;
				previous_number_of_pulses <= number_of_pulses;
			end
		end
		if (counter[uart_character_pickoff:0]==1) begin // more frequent
			if (uart_transfers_are_allowed==1) begin
				if (uart_character_counter<=length_of_line) begin
					start_uart_transfer <= 1;
					uart_character_counter++;
				end else begin
					uart_transfers_are_allowed <= 0;
					uart_character_counter = 0;
				end
			end
		end else begin
			start_uart_transfer <= 0;
		end
		if (uart_character_counter==length_of_line) begin
			byte_to_send <= 8'h0d; // cr
		end else if (uart_character_counter==length_of_line+1) begin
			byte_to_send <= 8'h0a; // nl
		end else if (uart_character_counter==1) begin
			byte_to_send <= { 4'h3, buffered_bcd1[23:20] };
		end else if (uart_character_counter==2) begin
			byte_to_send <= { 4'h3, buffered_bcd1[19:16] };
		end else if (uart_character_counter==3) begin
			byte_to_send <= { 4'h3, buffered_bcd1[15:12] };
		end else if (uart_character_counter==4) begin
			byte_to_send <= { 4'h3, buffered_bcd1[11:08] };
		end else if (uart_character_counter==5) begin
			byte_to_send <= { 4'h3, buffered_bcd1[07:04] };
		end else if (uart_character_counter==6) begin
			byte_to_send <= { 4'h3, buffered_bcd1[03:00] };
		end else if (uart_character_counter==7) begin
			byte_to_send <= 8'h20;
		end else if (uart_character_counter==8) begin
			byte_to_send <= { 4'h3, buffered_bcd2[23:20] };
		end else if (uart_character_counter==9) begin
			byte_to_send <= { 4'h3, buffered_bcd2[19:16] };
		end else if (uart_character_counter==10) begin
			byte_to_send <= { 4'h3, buffered_bcd2[15:12] };
		end else if (uart_character_counter==11) begin
			byte_to_send <= { 4'h3, buffered_bcd2[11:08] };
		end else if (uart_character_counter==12) begin
			byte_to_send <= { 4'h3, buffered_bcd2[07:04] };
		end else if (uart_character_counter==13) begin
			byte_to_send <= { 4'h3, buffered_bcd2[03:00] };
		end else begin
			byte_to_send <= 8'h20;
		end
	end
	wire [23:0] bcd1;
	wire [23:0] bcd2;
	reg [23:0] buffered_bcd1 = 0;
	reg [23:0] buffered_bcd2 = 0;
	reg [15:0] value1 = 0;
	reg [15:0] value2 = 0;
	wire [127:0] rand;
	reg [127:0] buffered_rand = 0;
	prbs myprbs(.clock(clock), .reset(reset), .word(rand));
	hex2bcd #(.INPUT_SIZE_IN_NYBBLES(4)) h2binst1 ( .clock(clock), .reset(~uart_resetb), .hex_in(value1), .bcd_out(bcd1), .sync(), .sync() );
	hex2bcd #(.INPUT_SIZE_IN_NYBBLES(4)) h2binst2 ( .clock(clock), .reset(~uart_resetb), .hex_in(value2), .bcd_out(bcd2), .sync(), .sync() );
	wire uart_busy;
	reg start_uart_transfer = 0;
	reg [7:0] byte_to_send = 0;
//	syn_fifo myfifo (.clk(clock), .rst(reset), .empty(), .full(),
//		.wr_cs(), .wr_en(), .data_in(),
//		.rd_cs(), .rd_en(), .data_out()
//	);
	wire [7:0] byte_we_are_sending;
	assign byte_we_are_sending = byte_to_send;
	wire uart_character_clock;
	assign uart_character_clock = counter[uart_character_pickoff];
	uart my_uart_instance (.clk(clock), .resetq(uart_resetb), .uart_busy(uart_busy), .uart_tx(TX), .uart_wr_i(start_uart_transfer), .uart_dat_i(byte_we_are_sending));
endmodule // mytop

module top (
	input CLK,
	output LED1, LED2, LED3, LED4, LED5,
	output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
	//inout J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
	input J2_8,
	output J2_1, J2_2, J2_3, J2_4, J2_7, J2_9, J2_10,
	output J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10,
	output DCDn, DSRn, CTSn, TX, IR_TX, IR_SD,
	input DTRn, RTSn, RX, IR_RX
);
	wire [7:0] J1 = { J1_10, J1_9, J1_8, J1_7, J1_6, J1_5, J1_4, J1_3 };
	wire [7:0] J2 = { J2_10, J2_9, J2_8, J2_7, J2_4, J2_3, J2_2, J2_1 };
	wire [7:0] J3 = { J3_10, J3_9, J3_8, J3_7, J3_6, J3_5, J3_4, J3_3 };
	wire [5:1] LED = { LED5, LED4, LED3, LED2, LED1 };
	assign { DCDn, DSRn, CTSn } = 1;
	assign { IR_TX, IR_SD } = 0;
	mytop mytop_instance (.clock(CLK), .LED(LED), .J1(J1), .J2(J2), .J3(J3), .TX(TX), .RX(RX));
endmodule // icestick

