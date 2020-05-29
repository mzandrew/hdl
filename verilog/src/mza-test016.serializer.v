// written 2018-09-06 by mza
// to drive a SN65LV1023 serializer IC
// based on mza-test014.duration-timer.uart.v
// last updated 2020-05-29 by mza

`define icestick
`include "lib/easypll.v"
`include "lib/prbs.v"

module mytop (
	input clock,
	output [5:1] LED,
	output [7:0] J1,
	inout [7:0] J2,
	output [7:0] J3
);
	reg reset = 1;
	wire fast_clock;
	wire pll_is_locked;
	easypll #(.DIVR(0), .DIVF(56), .DIVQ(4), .FILTER_RANGE(1)) my_42MHz_pll_instance (.clock_input(clock), .reset_active_low(~reset), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 42.750 MHz
	reg [31:0] fast_clock_counter = 0;
	localparam pickoff = 4;
	reg sync = 0;
	reg [9:0] data_bus = 0;
	always @(posedge fast_clock) begin
		sync <= 0;
		if (reset) begin
			fast_clock_counter <= 0;
		end else if (pll_is_locked) begin
			fast_clock_counter++;
			if (fast_clock_counter[pickoff:0]==0) begin
				sync <= 1;
				data_bus <= 10'b1111111111;
			end else if (fast_clock_counter[pickoff:0]==1) begin
				data_bus <= 10'b0111111111;
			end else if (fast_clock_counter[pickoff:0]==2) begin
				data_bus <= 10'b0011111111;
			end else if (fast_clock_counter[pickoff:0]==3) begin
				data_bus <= 10'b0001111111;
			end else if (fast_clock_counter[pickoff:0]==4) begin
				data_bus <= 10'b0000111111;
			end else if (fast_clock_counter[pickoff:0]==5) begin
				data_bus <= 10'b0000011111;
			end else if (fast_clock_counter[pickoff:0]==6) begin
				data_bus <= 10'b0000001111;
			end else if (fast_clock_counter[pickoff:0]==7) begin
				data_bus <= 10'b0000000111;
			end else if (fast_clock_counter[pickoff:0]==8) begin
				data_bus <= 10'b0000000011;
			end else if (fast_clock_counter[pickoff:0]==9) begin
				data_bus <= 10'b0000000001;
			end else if (fast_clock_counter[pickoff:0]==10) begin
				data_bus <= 10'b0000000000;
			end else if (fast_clock_counter[pickoff:0]==11) begin
				data_bus <= 10'b0101010101;
			end else if (fast_clock_counter[pickoff:0]==12) begin
				data_bus <= buffered_rand[9:0];
			end else begin
				buffered_rand <= rand;
				data_bus <= 10'b1111111111;
			end
		end
	end
	reg [31:0] counter = 0;
	always @(posedge clock) begin
		if (reset) begin
			if (counter[10]) begin
				reset <= 0;
			end
		end
		counter++;
	end
	assign J1[7] = 1; // vcc
	assign J1[3] = 1; // vcc
	assign J2[6] = 1; // powerdown_active_low
	assign J1[1] = 1; // data_enable
	assign J1[5] = 0; // gnd
	assign J1[4] = 0; // gnd
	assign J1[2] = 0; // gnd
	assign J1[0] = 0; // gnd
	assign J2[2] = 0; // gnd
	assign J1[6] = 0; // gnd
	assign J3[4] = 0; // use_tclk_rising_edge
	assign J2[3] = serial_stream_p; // 
	assign J2[7] = serial_stream_n; // 
	assign J3[5] = fast_clock; // tclk
	wire serial_stream_p;
	wire serial_stream_n;
	assign { J3[3], J3[2],
	         J3[1], J3[0], J2[0], J2[4],
	         J2[1], J2[5], J3[6], J3[7] } = data_bus;
	assign LED[5] = sync;
	assign LED[4] = 0;
	assign LED[3] = 0;
	assign LED[2] = 0;
	assign LED[1] = 0;
	localparam PRBSWIDTH = 128;
	wire [PRBSWIDTH-1:0] rand;
	reg [PRBSWIDTH-1:0] buffered_rand = 0;
	prbs #(.WIDTH(PRBSWIDTH)) myprbs (.clock(clock), .reset(reset), .word(rand));
endmodule // mytop

module top (
	input CLK,
	output LED1, LED2, LED3, LED4, LED5,
	output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
	//output J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
	output J2_1, J2_2, J2_3, J2_7, J2_8, J2_9,
	input J2_4, J2_10,
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
	assign TX = 0;
	mytop mytop_instance (.clock(CLK), .LED(LED), .J1(J1), .J2(J2), .J3(J3));
endmodule // icestick

