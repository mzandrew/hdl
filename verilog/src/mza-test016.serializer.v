// written 2018-09-06 by mza
// to drive a SN65LV1023 serializer IC
// based on mza-test014.duration-timer.uart.v
// last updated 2018-09-06 by mza

`include "lib/easypll.v"
`include "lib/prbs.v"

module mytop (input clock, output [5:1] LED, 
output [7:0] J1,
inout [7:0] J2,
output [7:0] J3
);
	reg reset = 1;
	wire fast_clock;
	wire pll_is_locked;
	easypll #(.DIVR(0), .DIVF(56), .DIVQ(4), .FILTER_RANGE(1)) my_42MHz_pll_instance (.clock_input(clock), .reset_active_low(~reset), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 42.750 MHz
	reg [31:0] fast_clock_counter;
	localparam pickoff = 4;
	always @(posedge fast_clock) begin
		if (reset) begin
			fast_clock_counter <= 0;
		end else if (pll_is_locked) begin
			fast_clock_counter++;
			if (fast_clock_counter[pickoff:0]==0) begin
				buffered_rand <= rand;
			end else if (fast_clock_counter[pickoff:0]==1) begin
				data_bus <= buffered_rand[7:0];
			end else begin
				data_bus <= 0;
			end
		end
	end
	reg [31:0] counter;
	always @(posedge clock) begin
		counter++;
		if (reset) begin
			if (counter[10]==1) begin
				reset <= 0;
			end
		end
	end
//	wire [28:1] DIP28 = { 1, 1, 
//	                      J1[7], J1[6], J2[6], J2[2],
//	                      J2[7], J2[3], J1[0], J1[1],
//	                      J1[2], J1[3], J1[4], J1[5],
//	                      0, J3[4], 0, 0,
//	                      0, 0, 0, 0,
//	                      0, 0
//	};
//	wire [28:1] DIP28 = { 1, 1, 
//	                      J1[7], J1[6], J2[6], J2[2], // 26,25,24,23
//	                      J2[7], J2[3], J1[0], J1[1], // 22,21,20,19
//	                      J1[2], J1[3], J1[4], J1[5], // 18,17,16,15
//	                      J3[5], J3[4], J3[3], J3[2], // 14,13,12,11
//	                      J3[1], J3[0], J2[0], J2[4], // 10,09,08,07
//	                      J2[1], J2[5], J3[6], J3[7], // 06,05,04,03
//	                      0, 0
//	};
//	assign DIP28[26] = 1; // vcc
//	assign DIP28[17] = 1; // vcc
//	assign DIP28[15] = 0; // gnd
//	assign DIP28[16] = 0; // gnd
//	assign DIP28[18] = 0; // gnd
//	assign DIP28[20] = 0; // gnd
//	assign DIP28[23] = 0; // gnd
//	assign DIP28[25] = 0; // gnd
//	assign DIP28[24] = 1; // powerdown_active_low
//	assign DIP28[13] = 1; // use_tclk_rising_edge
//	assign DIP28[19] = 1; // data_enable
//	assign DIP28[21] = serial_stream_p; // 
//	assign DIP28[22] = serial_stream_n; // 
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
	wire [9:0] data_bus;
	assign data_bus = { J3[3], J3[2],
	                    J3[1], J3[0], J2[0], J2[4],
	                    J2[1], J2[5], J3[6], J3[7] };
//	assign data_bus = { DIP28[12], DIP28[11], DIP28[10], DIP28[9],
//	                    DIP28[8], DIP28[7], DIP28[6], DIP28[5],
//	                    DIP28[4], DIP28[3] };
	assign LED[5] = 0;
	assign LED[4] = 0;
	assign LED[3] = 0;
	assign LED[2] = 0;
	assign LED[1] = 0;
	localparam PRBSWIDTH = 128;
	reg [PRBSWIDTH-1:0] rand;
	reg [PRBSWIDTH-1:0] buffered_rand;
	prbs #(.WIDTH(PRBSWIDTH)) myprbs (.clock(clock), .reset(reset), .word(rand));
endmodule // mytop

module icestick (
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

