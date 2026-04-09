`timescale 1ns / 100ps

// simulate with:
// iverilog -m testbench example002.v -o example002.out
// vvp example002.out
// gtkwave # (open new tab with waveform example002.vcd)

// last updated 2020-06-01 by mza
`define icestick

`ifndef SYNTHESIS
module testbench;
	reg [31:0] counter = 0;
	wire [5:1] LED;
	reg CLK = 0;
	always
		#41.7 CLK = ~CLK;
	always @(posedge CLK) begin
		counter <= counter + 1;
	end
	initial begin
		#0
		$dumpfile("work/example002.vcd");
		$dumpvars(0, testbench);
		#100000 $finish;
	end
	top #(.LOG2DELAY(1)) my_top_instance (.CLK(CLK), .LED1(LED[1]), .LED2(LED[2]), .LED3(LED[3]), .LED4(LED[4]), .LED5(LED[5]));
endmodule // testbench
`endif

// https://github.com/cliffordwolf/icestorm/blob/master/examples/icestick/example.v
module top #(parameter LOG2DELAY=20) (
	input CLK,
	input DTRn, RTSn, RX, IR_RX,
	output DCDn, DSRn, CTSn, TX, IR_TX, IR_SD,
	output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
	output J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
	output J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10,
	output LED5, LED1, LED2, LED3, LED4
);
	localparam BITS = 5;
	reg [BITS+LOG2DELAY-1:0] counter = 0;
	reg [BITS-1:0] outcnt = 0;
	always @(posedge CLK) begin
		counter <= counter + 1;
		outcnt <= counter >> LOG2DELAY;
	end
	assign TX = RX; assign DCDn = 1'b1; assign DSRn = 1'b1; assign CTSn = 1'b1;
	assign IR_TX = IR_RX; assign IR_SD = 1'b1; // IR_SD = shut down
	assign J1_3 = 1'b0; assign J1_4 = 1'b0; assign J1_5 = 1'b0; assign J1_6 = 1'b0; assign J1_7 = 1'b0; assign J1_8 = 1'b0; assign J1_9 = 1'b0; assign J1_10 = 1'b0;
	assign J2_1 = 1'b0; assign J2_2 = 1'b0; assign J2_3 = 1'b0; assign J2_4 = 1'b0; assign J2_7 = 1'b0; assign J2_8 = 1'b0; assign J2_9 = 1'b0; assign J2_10 = 1'b0;
	assign J3_3 = 1'b0; assign J3_4 = 1'b0; assign J3_5 = 1'b0; assign J3_6 = 1'b0; assign J3_7 = 1'b0; assign J3_8 = 1'b0; assign J3_9 = 1'b0; assign J3_10 = 1'b0;
	assign {LED1, LED2, LED3, LED4, LED5} = outcnt ^ (outcnt >> 1);
endmodule // top

