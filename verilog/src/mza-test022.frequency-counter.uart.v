// written 2018-09-27 by mza
// based on mza-test014.duration-timer.uart.v
// last updated 2018-10-04 by mza

`include "lib/hex2bcd.v"
`include "lib/segmented_display_driver.v"
//`include "lib/uart.v"
//`include "lib/fifo.v"

module mytop (
	input clock,
	output [5:1] LED, 
	input [7:0] J1,
	inout [7:0] J2,
	input [7:0] J3,
	input RX,
	output TX
);
	wire external_reference_clock;
	wire external_clock_to_measure;
	wire reference_clock;
	wire trigger_active;
	wire signal_output;
	localparam msb_of_counters = 27;
	reg [msb_of_counters:0] reference_clock_counter;
	reg [msb_of_counters:0] trigger_duration = 0; // live
	reg [msb_of_counters:0] previous_trigger_duration = 0; // updated after pulse ends
	reg [2:0] trigger_stream = 0;
	localparam maximum_expected_frequency = 250000000;
	localparam log2_of_maximum_expected_frequency = $clog2(maximum_expected_frequency); // ~28
	assign J2[1] = signal_output; // 1,2 pair (ACK)
	assign J2[2] = signal_output; // 5,4 pair (RSV)
	assign external_reference_clock = J2[0]; // 3,6 pair (TRG)
	assign external_clock_to_measure = J2[3]; // 7,8 pair (CLK)
//	assign reference_clock = external_clock_to_measure; // 1272160 * 100Hz or unknown
	assign reference_clock = external_reference_clock; // 100000 * 100Hz
	localparam frequency_of_reference_clock_in_100Hz = 1000000;
//	assign reference_clock = clock; // 120000 * 100Hz
//	localparam frequency_of_reference_clock_in_100Hz = 120000;
	localparam log2_of_frequency_of_reference_clock_in_100Hz = $clog2(frequency_of_reference_clock_in_100Hz); // ~17
	localparam msb_of_accumulator = log2_of_maximum_expected_frequency + log2_of_frequency_of_reference_clock_in_100Hz; // ~45
	localparam log2_of_divide_ratio = 20;
	localparam msb_of_result = msb_of_accumulator - log2_of_divide_ratio; // ~25
	reg [msb_of_accumulator:0] accumulator;
	reg [msb_of_accumulator:0] previous_accumulator;
	reg [msb_of_result:0] result;
	assign J1[6] = 0;
	assign J1[7] = 0;
	assign trigger_active = reference_clock_counter[log2_of_divide_ratio];
	assign signal_output = trigger_active;
	assign J1[0] = signal_output; // trigger_out on PCB
	always @(posedge reference_clock) begin
		reference_clock_counter++;
	end
	always @(posedge external_clock_to_measure) begin
		if (trigger_active==1) begin
			trigger_duration++;
			accumulator <= accumulator + frequency_of_reference_clock_in_100Hz;
		end else begin
			if (trigger_stream==3'b110) begin
//				number_of_pulses++;
				previous_trigger_duration <= trigger_duration;
				trigger_duration <= 0;
				previous_accumulator <= accumulator;
				accumulator <= 0;
			end
		end
		trigger_stream <= { trigger_stream[1:0], trigger_active }; // 110, 100, 000 or 001, 011, 111
	end
	// for a pair of 4-digit 7-segment(+dp) TCMG1050M displays on a "icestick frequency counter revA" board
	wire [6:0] segment;
	assign { J1[4], J1[1], J3[4], J3[5], J1[2], J1[5], J1[3] } = segment; // segments dp,g,f,e,d,c,b,a , J3[2]
	assign J3[2] = 1;
	wire [7:0] anode;
	assign { J2[7], J2[4], J2[5], J2[6], J3[6], J3[7], J3[3], J3[1] } = anode; // anodes 7,6,5,4,3,2,1,0
	segmented_display_driver #(.number_of_segments(7), .number_of_nybbles(8)) my_segmented_display_driver (.clock(clock), .data(buffered_bcd2[31:0]), .cathode(segment), .anode(anode));
	assign LED[5] = 0;
	assign LED[4] = signal_output;
	assign LED[3] = trigger_stream[2];
	assign LED[2] = trigger_stream[1];
	assign LED[1] = trigger_stream[0];
	reg [msb_of_counters:0] counter;
//	localparam length_of_line = 6+6+2;
//	reg [7:0] uart_character_counter;
//	reg uart_transfers_are_allowed;
//	localparam uart_character_pickoff = 11; // this is already close to the limit for 115200
	localparam uart_line_pickoff = 22;
	localparam slow_clock_pickoff = uart_line_pickoff;
//	reg [15:0] uart_line_counter;
	wire uart_resetb;
	reg reset = 1;
	assign uart_resetb = ~reset;
//	localparam log2_of_function_generator_period = uart_line_pickoff;
//	localparam function_generator_start = 0;
//	reg [9:0] pulse_duration;
//	reg [msb_of_counters:0] previous_number_of_pulses = 0;
//	reg [msb_of_counters:0] number_of_pulses = 0;
	always @(posedge clock) begin
		counter++;
		if (reset) begin
//			uart_line_counter <= 0;
//			uart_character_counter <= length_of_line - 1;
//			uart_transfers_are_allowed <= 0;
//			signal_output <= 0;
			if (counter[10]==1) begin
				reset <= 0;
			end
//		end else begin
//			//if (counter[31:0]>1500 & counter[31:0]<2000) begin
//			if (counter[log2_of_function_generator_period:0]>function_generator_start) begin
//				if (counter[log2_of_function_generator_period:0]<function_generator_start+pulse_duration) begin
//					signal_output <= 1;
//				end else begin
//					signal_output <= 0;
//				end
//			end else begin
//				signal_output <= 0;
//			end
		end
		if (counter[slow_clock_pickoff:0]==0) begin
//			buffered_bcd1 <= bcd1;
			buffered_bcd2 <= bcd2;
		end else if (counter[slow_clock_pickoff:0]==1) begin
//			accumulator = previous_trigger_duration * frequency_of_reference_clock_in_100Hz;
		end else if (counter[slow_clock_pickoff:0]==2) begin
			result = { 0, previous_accumulator[msb_of_accumulator:log2_of_divide_ratio] };
		end else if (counter[slow_clock_pickoff:0]==3) begin
			//value1 <= uart_line_counter;
//			value1 <= reference_clock_counter[23:0];
//			value2 <= previous_trigger_duration; // TDC mode
//			value2 <= accumulator[msb_of_accumulator:log2_of_divide_ratio]; // frequency counter mode
//			value2 <= accumulator[23:0]; // frequency counter mode
			value2 <= result; // frequency counter mode
//			value1 <= number_of_pulses; // scaler mode
		end
//		if (counter[uart_line_pickoff:0]==0) begin // less frequent
//			if (previous_number_of_pulses!=number_of_pulses) begin
//				uart_transfers_are_allowed <= 1;
//				uart_line_counter++;
//				previous_number_of_pulses <= number_of_pulses;
//			end
//		end
//		if (counter[uart_character_pickoff:0]==1) begin // more frequent
//			if (uart_transfers_are_allowed==1) begin
//				if (uart_character_counter<=length_of_line) begin
//					start_uart_transfer <= 1;
//					uart_character_counter++;
//				end else begin
//					uart_transfers_are_allowed <= 0;
//					uart_character_counter = 0;
//				end
//			end
//		end else begin
//			start_uart_transfer <= 0;
//		end
//		if (uart_character_counter==length_of_line) begin
//			byte_to_send <= 8'h0d; // cr
//		end else if (uart_character_counter==length_of_line+1) begin
//			byte_to_send <= 8'h0a; // nl
//		end else if (uart_character_counter==1) begin
//			byte_to_send <= { 4'h3, buffered_bcd1[23:20] };
//		end else if (uart_character_counter==2) begin
//			byte_to_send <= { 4'h3, buffered_bcd1[19:16] };
//		end else if (uart_character_counter==3) begin
//			byte_to_send <= { 4'h3, buffered_bcd1[15:12] };
//		end else if (uart_character_counter==4) begin
//			byte_to_send <= { 4'h3, buffered_bcd1[11:08] };
//		end else if (uart_character_counter==5) begin
//			byte_to_send <= { 4'h3, buffered_bcd1[07:04] };
//		end else if (uart_character_counter==6) begin
//			byte_to_send <= { 4'h3, buffered_bcd1[03:00] };
//		end else if (uart_character_counter==7) begin
//			byte_to_send <= 8'h20;
//		end else if (uart_character_counter==8) begin
//			byte_to_send <= { 4'h3, buffered_bcd2[23:20] };
//		end else if (uart_character_counter==9) begin
//			byte_to_send <= { 4'h3, buffered_bcd2[19:16] };
//		end else if (uart_character_counter==10) begin
//			byte_to_send <= { 4'h3, buffered_bcd2[15:12] };
//		end else if (uart_character_counter==11) begin
//			byte_to_send <= { 4'h3, buffered_bcd2[11:08] };
//		end else if (uart_character_counter==12) begin
//			byte_to_send <= { 4'h3, buffered_bcd2[07:04] };
//		end else if (uart_character_counter==13) begin
//			byte_to_send <= { 4'h3, buffered_bcd2[03:00] };
//		end else begin
//			byte_to_send <= 8'h20;
//		end
	end
//	reg [35:0] bcd1;
	reg [35:0] bcd2;
//	reg [35:0] buffered_bcd1;
	reg [35:0] buffered_bcd2;
//	reg [23:0] value1;
	reg [23:0] value2;
//	hex2bcd #(.input_size_in_nybbles(6)) h2binst1 ( .clock(clock), .reset(~uart_resetb), .hex_in(value1), .bcd_out(bcd1) );
	hex2bcd #(.input_size_in_nybbles(6)) h2binst2 ( .clock(clock), .reset(~uart_resetb), .hex_in(value2), .bcd_out(bcd2) );
//	assign bcd2 = { 0, value2 };
//	reg uart_busy;
//	reg start_uart_transfer;
//	reg [7:0] byte_to_send;
//	syn_fifo myfifo (.clk(clock), .rst(reset), .empty(), .full(),
//		.wr_cs(), .wr_en(), .data_in(),
//		.rd_cs(), .rd_en(), .data_out()
//	);
//	reg [7:0] byte_we_are_sending;
//	assign byte_we_are_sending = byte_to_send;
//	wire uart_character_clock;
//	assign uart_character_clock = counter[uart_character_pickoff];
//	uart my_uart_instance (.clk(clock), .resetq(uart_resetb), .uart_busy(uart_busy), .uart_tx(TX), .uart_wr_i(start_uart_transfer), .uart_dat_i(byte_we_are_sending));
	assign TX = 0;
endmodule // mytop

module icestick (
input CLK,
output LED1, LED2, LED3, LED4, LED5,
output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
output       J2_2, J2_3,       J2_7, J2_8, J2_9, J2_10,
output       J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10,
input J3_3, J2_4, J2_1,
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

