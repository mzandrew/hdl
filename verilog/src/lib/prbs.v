// written 2018-08-22 by mza
// idea stolen from http://fpgasrus.com/prbs.html
// last updated 2025-03-06 by mza

`ifndef PRBS_LFSR_LIB
`define PRBS_LFSR_LIB

`timescale 1ns / 1ps

// pseudo-random bitstream (prbs) / linear-feedback shift-register (lfsr)
// prbs #(.WIDTH(128)) myprbs (.clock(clock), .reset(reset), .word(rand));
module prbs #(
	parameter WIDTH = 128,
	parameter TAPA = 27,
	parameter TAPB = 30,
	parameter [WIDTH-1:0] INIT = 1
	//parameter INIT = WIDTH'(1)
) (
	input clock,
	input reset,
	output reg [WIDTH-1:0] word = INIT
);
	always @(posedge clock) begin
		if (reset) begin
			word <= INIT;
		end else begin
			word <= { word[WIDTH-2:0], word[TAPA]^word[TAPB] };
		end
	end
endmodule // prbs

module prbs_tb #(
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2.0
) ();
	reg clock = 0, reset = 1'b1;
	always begin
		#HALF_CLOCK_PERIOD; clock <= ~clock;
	end
	wire [7:0]  rand8;  prbs #(.WIDTH(8),  .TAPA(6), .TAPB(7))   lfsr8  (.clock(clock), .reset(reset), .word(rand8));
	wire [9:0]  rand10; prbs #(.WIDTH(10), .TAPA(5), .TAPB(9))   lfsr10 (.clock(clock), .reset(reset), .word(rand10));
	wire [11:0] rand12; prbs #(.WIDTH(12), .TAPA(9), .TAPB(11))  lfsr12 (.clock(clock), .reset(reset), .word(rand12));
	//wire [13:0] rand14; prbs #(.WIDTH(14), .TAPA(1), .TAPB(2), .TAPC(12), .TAPD(13)) lfsr14  (.clock(clock), .reset(reset), .word(rand14));
	wire [15:0] rand16; prbs #(.WIDTH(16), .TAPA(14), .TAPB(15)) lfsr16 (.clock(clock), .reset(reset), .word(rand16));
	wire [20:0] rand21; prbs #(.WIDTH(21), .TAPA(3), .TAPB(20))  lfsr21 (.clock(clock), .reset(reset), .word(rand21));
	wire [23:0] rand24; prbs #(.WIDTH(24), .TAPA(18), .TAPB(23)) lfsr24 (.clock(clock), .reset(reset), .word(rand24));
	wire [31:0] rand32; prbs #(.WIDTH(32), .TAPA(28), .TAPB(31)) lfsr32 (.clock(clock), .reset(reset), .word(rand32));
	initial begin
		#(2*CLOCK_PERIOD+HALF_CLOCK_PERIOD); reset <= 0;
		#(4096*CLOCK_PERIOD); $finish;
	end
endmodule

module prbs_wide #(
	parameter OUTPUT_WIDTH = 8,
	parameter PICKOFF_BIT = 31
) (
	input clock, reset,
	output [OUTPUT_WIDTH-1:0] rand
);
	wire [31:0] word [OUTPUT_WIDTH-1:0];
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'habcd1234)) lfsr32_0  (.clock(clock), .reset(reset), .word(word[0]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h4321dcba)) lfsr32_1  (.clock(clock), .reset(reset), .word(word[1]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h18293056)) lfsr32_2  (.clock(clock), .reset(reset), .word(word[2]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hfdebcafd)) lfsr32_3  (.clock(clock), .reset(reset), .word(word[3]));
	if (OUTPUT_WIDTH>4) begin
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hf0a505af)) lfsr32_4  (.clock(clock), .reset(reset), .word(word[4]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h2389bade)) lfsr32_5  (.clock(clock), .reset(reset), .word(word[5]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hb0a85e6d)) lfsr32_6  (.clock(clock), .reset(reset), .word(word[6]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hdeadbeef)) lfsr32_7  (.clock(clock), .reset(reset), .word(word[7]));
	end
	if (OUTPUT_WIDTH>8) begin
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hcd12ab34)) lfsr32_8  (.clock(clock), .reset(reset), .word(word[8]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h21dc43ba)) lfsr32_9  (.clock(clock), .reset(reset), .word(word[9]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h29301856)) lfsr32_10 (.clock(clock), .reset(reset), .word(word[10]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hebcafdfd)) lfsr32_11 (.clock(clock), .reset(reset), .word(word[11]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'ha505f0af)) lfsr32_12 (.clock(clock), .reset(reset), .word(word[12]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h89ba24de)) lfsr32_13 (.clock(clock), .reset(reset), .word(word[13]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'ha85eb06d)) lfsr32_14 (.clock(clock), .reset(reset), .word(word[14]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hadbedeef)) lfsr32_15 (.clock(clock), .reset(reset), .word(word[15]));
	end
	if (OUTPUT_WIDTH>16) begin
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h1234abcd)) lfsr32_16 (.clock(clock), .reset(reset), .word(word[16]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hdcba4321)) lfsr32_17 (.clock(clock), .reset(reset), .word(word[17]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h30561829)) lfsr32_18 (.clock(clock), .reset(reset), .word(word[18]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hcafdfdeb)) lfsr32_19 (.clock(clock), .reset(reset), .word(word[19]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h05aff0a5)) lfsr32_20 (.clock(clock), .reset(reset), .word(word[20]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hbade2389)) lfsr32_21 (.clock(clock), .reset(reset), .word(word[21]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h5e6db0a8)) lfsr32_22 (.clock(clock), .reset(reset), .word(word[22]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hbeefdead)) lfsr32_23 (.clock(clock), .reset(reset), .word(word[23]));
	end
	if (OUTPUT_WIDTH>24) begin
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hab34cd12)) lfsr32_24 (.clock(clock), .reset(reset), .word(word[24]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h43ba21dc)) lfsr32_25 (.clock(clock), .reset(reset), .word(word[25]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h18562930)) lfsr32_26 (.clock(clock), .reset(reset), .word(word[26]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hfdfdebca)) lfsr32_27 (.clock(clock), .reset(reset), .word(word[27]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hf0afa505)) lfsr32_28 (.clock(clock), .reset(reset), .word(word[28]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'h23de89ba)) lfsr32_29 (.clock(clock), .reset(reset), .word(word[29]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hb06da85e)) lfsr32_30 (.clock(clock), .reset(reset), .word(word[30]));
	prbs #(.WIDTH(32), .TAPA(28), .TAPB(31), .INIT(32'hdeefadbe)) lfsr32_31 (.clock(clock), .reset(reset), .word(word[31]));
	end
	genvar i;
	for (i=0; i<OUTPUT_WIDTH; i=i+1) begin
		assign rand[i] = word[i][PICKOFF_BIT];
	end
endmodule

module prbs_tb2 #(
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2.0,
	parameter OUTPUT_WIDTH = 8
) ();
	reg clock = 0, reset = 1'b1;
	always begin
		#HALF_CLOCK_PERIOD; clock <= ~clock;
	end
	reg [31:0] counter = 0;
	reg [OUTPUT_WIDTH-1:0] start = 0;
	wire [OUTPUT_WIDTH-1:0] rand;
	prbs_wide #(.OUTPUT_WIDTH(OUTPUT_WIDTH)) pw (.clock(clock), .reset(reset), .rand(rand));
	initial begin
		#(2*CLOCK_PERIOD+HALF_CLOCK_PERIOD); reset <= 0;
		start <= rand; #CLOCK_PERIOD; $display("initial value is %d", start);
		for (counter=0; ; counter=counter+1'b1) begin
			#CLOCK_PERIOD;
			if (rand==start) begin
				$display("duplication at count %d", counter);
			end
		end
		#(17000*CLOCK_PERIOD); $finish;
	end
endmodule

`endif

