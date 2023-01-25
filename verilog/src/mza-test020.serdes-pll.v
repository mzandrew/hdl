`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2021-09-06 by mza

`define SCROD_revA3

module mza_test020_serdes_pll (
	input clock_p,
	input clock_n,
	output ttl_trig_output,
	input self_triggered_mode_switch,
	input lvds_trig_input_p,
	input lvds_trig_input_n,
	//output lvds_tr1ig_output_n,
	//output lvds_trig_output_p,
	//output lvds_tr1ig_output_n,
	output led_0,
	output led_1,
	output led_2,
	output led_3,
	output led_4,
	output led_5,
	output led_6,
	output led_7,
	output led_8,
	output led_9,
	output led_a,
	output led_b
);
	localparam WIDTH = 8;
	reg reset1 = 1;
	reg reset2 = 1;
	reg sync = 0;
//	assign led_8 = counter[27-$clog2(WIDTH)]; // ~ 1 Hz
	assign led_8 = sync;
	assign led_9 = reset1;
	assign led_a = reset2;
	wire clock; // 125 MHz word_clock
	wire other_clock;
	IBUFGDS coolcool (.I(clock_p), .IB(clock_n), .O(other_clock)); // 156.25 MHz
	wire IOCLK0;
	wire IOCE;
	// with some help from https://vjordan.info/log/fpga/high-speed-serial-bus-generation-using-spartan-6.html and/or XAPP1064 source code
	wire cascade_do;
	wire cascade_to;
	wire cascade_di;
	wire cascade_ti;
	reg [WIDTH-1:0] word = 0;
	localparam RESET2_PICKOFF = 10;
	localparam PICKOFF = 24;
	reg [PICKOFF+3:0] counter = 0;
	wire [7:0] led_byte;
	assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = led_byte;
	assign led_byte = word;
	// want MSB of word to come out first
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_primary
	         (.OQ(ttl_trig_output), .TQ(), .CLK0(IOCLK0), .CLK1(1'b0), .CLKDIV(clock),
	         .D1(word[3]), .D2(word[2]), .D3(word[1]), .D4(word[0]),
	         .IOCE(IOCE), .OCE(1'b1), .RST(reset1), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do), .SHIFTIN4(cascade_to), 
	         .SHIFTOUT1(cascade_di), .SHIFTOUT2(cascade_ti), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_secondary
	         (.OQ(), .TQ(), .CLK0(IOCLK0), .CLK1(1'b0), .CLKDIV(clock),
	         .D1(word[7]), .D2(word[6]), .D3(word[5]), .D4(word[4]),
	         .IOCE(IOCE), .OCE(1'b1), .RST(reset1), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_di), .SHIFTIN2(cascade_ti), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_do), .SHIFTOUT4(cascade_to),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	localparam RESET1_PICKOFF = 10;
	reg [RESET1_PICKOFF:0] reset1_counter = 0;
	always @(posedge other_clock) begin
		if (reset1) begin
			if (reset1_counter[RESET1_PICKOFF]) begin
				reset1 <= 0;
			end
		end
		reset1_counter <= reset1_counter + 1'b1;
	end
	wire trigger_input;
	IBUFDS angel (.I(lvds_trig_input_p), .IB(lvds_trig_input_n), .O(trigger_input));
	reg [2:0] token = 0;
	reg [2:0] trigger_stream = 0;
	//localparam first  = 8'b11110000;
	//localparam second = 8'b10000001;
	//localparam third  = 8'b10001000;
	//localparam forth  = 8'b10101010;
	localparam all_ones = 8'b11111111;
	localparam all_zeroes = 8'b00000000;
	wire [7:0] pattern [7:0] = {
		8'b11111111, 8'b11111110, 8'b11111100, 8'b11111000,
		8'b11110000, 8'b11100000, 8'b11000000, 8'b10000000 };
	localparam long_mode = 1;
	always @(posedge clock) begin
		if (reset2) begin
			token <= 0;
			trigger_stream <= 0;
			if (counter[RESET2_PICKOFF]) begin
				reset2 <= 0;
			end
		end
		word <= all_zeroes;
		if (self_triggered_mode_switch) begin
			if (counter[PICKOFF:0]==0) begin
				         if (counter[PICKOFF+3:PICKOFF+1]==3'd0) begin
					sync <= 1;
					word <= pattern[0];
				end else if (counter[PICKOFF+3:PICKOFF+1]==3'd1) begin
					sync <= 0;
					word <= pattern[1];
				end else if (counter[PICKOFF+3:PICKOFF+1]==3'd2) begin
					word <= pattern[2];
				end else if (counter[PICKOFF+3:PICKOFF+1]==3'd3) begin
					word <= pattern[3];
				end else if (counter[PICKOFF+3:PICKOFF+1]==3'd4) begin
					word <= pattern[4];
				end else if (counter[PICKOFF+3:PICKOFF+1]==3'd5) begin
					word <= pattern[5];
				end else if (counter[PICKOFF+3:PICKOFF+1]==3'd6) begin
					word <= pattern[6];
				end else if (counter[PICKOFF+3:PICKOFF+1]==3'd7) begin
					word <= pattern[7];
				end
			end
		end else if (long_mode) begin
			if (counter[PICKOFF:0]==0) begin
				word <= all_ones;
			end else if (counter[PICKOFF:0]==1) begin
				word <= all_ones;
			end else if (counter[PICKOFF:0]==2) begin
				word <= all_ones;
			end else if (counter[PICKOFF:0]==3) begin
				word <= all_ones;
			end else if (counter[PICKOFF:0]==4) begin
				word <= all_ones;
			end else if (counter[PICKOFF:0]==5) begin
				word <= all_ones;
			end else if (counter[PICKOFF:0]==6) begin
				word <= all_ones;
			end else if (counter[PICKOFF:0]==7) begin
				word <= all_ones;
			end
		end else if (trigger_stream==3'b001) begin
			if (token==3'd0) begin
				sync <= 1;
				word <= pattern[0];
				token <= 3'd1;
			end else if (token==3'd1) begin
				sync <= 0;
				word <= pattern[1];
				token <= 3'd2;
			end else if (token==3'd2) begin
				word <= pattern[2];
				token <= 3'd3;
			end else if (token==3'd3) begin
				word <= pattern[3];
				token <= 3'd4;
			end else if (token==3'd4) begin
				word <= pattern[4];
				token <= 3'd5;
			end else if (token==3'd5) begin
				word <= pattern[5];
				token <= 3'd6;
			end else if (token==3'd6) begin
				word <= pattern[6];
				token <= 3'd7;
			end else begin
				word <= pattern[7];
				token <= 3'd0;
			end
		end
		trigger_stream <= { trigger_stream[1:0], trigger_input };
		counter <= counter + 1'b1;
	end
	oserdes_pll #(
		.BIT_DEPTH(WIDTH), .CLKIN_PERIOD(6.4), .PLLD(5), .PLLX(32) // 156.25 -> 1000
		) difficult_pll (
		.reset(reset1), .clock_in(other_clock), .word_clock_out(clock),
		.serializer_clock_out(IOCLK0), .serializer_strobe_out(IOCE), .locked(led_b)
		);
endmodule

