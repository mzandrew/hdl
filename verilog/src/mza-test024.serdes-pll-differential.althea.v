`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2018-11-16 by mza

module mza_test024_serdes_pll_differential_althea (
	input clock_p,
	input clock_n,
	input self_triggered_mode_switch,
	output lemo_output,
	input lvds_trig_input_p,
	input lvds_trig_input_n,
	output lvds_trig_output_1_p,
	output lvds_trig_output_1_n,
	output lvds_trig_output_2_p,
	output lvds_trig_output_2_n,
	output led_0,
	output led_1,
	output led_2,
	output led_3,
	output led_4,
	output led_5,
	output led_6,
	output led_7
);
	localparam WIDTH = 8;
	reg reset1 = 1;
	reg reset2 = 1;
	wire clock; // 125 MHz
	reg [31:0] counter = 0;
	reg sync;
	wire other_clock; // 50.0 MHz
	IBUFGDS coolcool (.I(clock_p), .IB(clock_n), .O(other_clock)); // 50.0 MHz
	wire lvds_trig_output_R;
//	OBUFDS catcat1 (.I(lvds_trig_output_R), .O(lvds_trig_output_1_p), .OB(lvds_trig_output_1_n));
	wire lvds_trig_output_T;
	OBUFDS catcat2 (.I(lvds_trig_output_T), .O(lvds_trig_output_2_p), .OB(lvds_trig_output_2_n));
//	assign lemo_output = sync;
	assign lemo_output = lvds_trig_output_R;
	wire ioclk_T; // 1000 MHz
	wire ioclk_R; // 1000 MHz
	wire ioce_T;
	wire ioce_R;
	// with some help from https://vjordan.info/log/fpga/high-speed-serial-bus-generation-using-spartan-6.html and/or XAPP1064 source code
	wire cascade_do1;
	wire cascade_to1;
	wire cascade_di1;
	wire cascade_ti1;
	wire cascade_do2;
	wire cascade_to2;
	wire cascade_di2;
	wire cascade_ti2;
	reg [WIDTH-1:0] word;
	localparam pickoff = 24;
	wire [7:0] led_byte;
	assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = led_byte;
	assign led_byte = ~ word;
	// want MSB of word to come out first
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_T
	         (.OQ(lvds_trig_output_T), .TQ(), .CLK0(ioclk_T), .CLK1(1'b0), .CLKDIV(clock),
	         .D1(word[3]), .D2(word[2]), .D3(word[1]), .D4(word[0]),
	         .IOCE(ioce_T), .OCE(1'b1), .RST(reset1), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do1), .SHIFTIN4(cascade_to1), 
	         .SHIFTOUT1(cascade_di1), .SHIFTOUT2(cascade_ti1), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_T
	         (.OQ(), .TQ(), .CLK0(ioclk_T), .CLK1(1'b0), .CLKDIV(clock),
	         .D1(word[7]), .D2(word[6]), .D3(word[5]), .D4(word[4]),
	         .IOCE(ioce_T), .OCE(1'b1), .RST(reset1), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_di1), .SHIFTIN2(cascade_ti1), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_do1), .SHIFTOUT4(cascade_to1),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_R
	         (.OQ(lvds_trig_output_R), .TQ(), .CLK0(ioclk_R), .CLK1(1'b0), .CLKDIV(clock),
	         .D1(word[3]), .D2(word[2]), .D3(word[1]), .D4(word[0]),
	         .IOCE(ioce_R), .OCE(1'b1), .RST(reset1), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do2), .SHIFTIN4(cascade_to2), 
	         .SHIFTOUT1(cascade_di2), .SHIFTOUT2(cascade_ti2), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_R
	         (.OQ(), .TQ(), .CLK0(ioclk_R), .CLK1(1'b0), .CLKDIV(clock),
	         .D1(word[7]), .D2(word[6]), .D3(word[5]), .D4(word[4]),
	         .IOCE(ioce_R), .OCE(1'b1), .RST(reset1), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_di2), .SHIFTIN2(cascade_ti2), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_do2), .SHIFTOUT4(cascade_to2),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	reg [12:0] reset1_counter = 0;
	always @(posedge other_clock) begin // 50.0 MHz
		if (reset1) begin
			if (reset1_counter[10]) begin
				reset1 <= 0;
			end
		end
		reset1_counter <= reset1_counter + 1;
	end
	wire trigger_input;
	IBUFDS angel (.I(lvds_trig_input_p), .IB(lvds_trig_input_n), .O(trigger_input));
	reg [1:0] token;
	reg [2:0] trigger_stream;
	localparam first  = ~ 8'b11110000;
	localparam second = ~ 8'b10000001;
	localparam third  = ~ 8'b10001000;
	localparam forth  = ~ 8'b10101010;
	always @(posedge clock) begin // 125.0 MHz
		if (reset2) begin
			token <= 2'b00;
			trigger_stream <= 0;
			if (counter[10]) begin
				reset2 <= 0;
			end
		end
		word <= ~ 8'b00000000;
		if (self_triggered_mode_switch) begin
			if (counter[pickoff:0]==0) begin
				         if (counter[pickoff+2:pickoff+1]==2'b00) begin
					sync <= 1;
					word <= first;
				end else if (counter[pickoff+2:pickoff+1]==2'b01) begin
					sync <= 0;
					word <= second;
				end else if (counter[pickoff+2:pickoff+1]==2'b10) begin
					word <= third;
				end else if (counter[pickoff+2:pickoff+1]==2'b11) begin
					word <= forth;
				end
			end
		end else if (trigger_stream==3'b001) begin
			if (token==2'b00) begin
				sync <= 1;
				word <= first;
				token <= 2'b01;
			end else if (token==2'b01) begin
				sync <= 0;
				word <= second;
				token <= 2'b10;
			end else if (token==2'b10) begin
				word <= third;
				token <= 2'b11;
			//end else if (token==2'b11) begin
			end else begin
				word <= forth;
				token <= 2'b00;
			end
		end
		trigger_stream <= { trigger_stream[1:0], trigger_input };
		counter <= counter + 1;
	end
	oserdes_pll #(.WIDTH(WIDTH), .CLKIN_PERIOD(20.0), .PLLD(2), .PLLX(40)) difficult_pll_TR (
		.reset(reset1), .clock_in(other_clock), .fabric_clock_out(clock), 
		.serializer_clock_out_1(ioclk_T), .serializer_strobe_out_1(ioce_T), .locked_1(),
		.serializer_clock_out_2(ioclk_R), .serializer_strobe_out_2(ioce_R), .locked_2()
	);
endmodule
