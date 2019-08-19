`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2019-08-19 by mza

module ocyrus_single8 #(
	parameter WIDTH = 8,
	PERIOD = 20.0,
	DIVIDE = 2,
	MULTIPLY = 40
) (
	input clock_in,
	output word_clock_out,
	input reset,
	input [WIDTH-1:0] word_in,
	output D_out,
	output T_out,
	output locked
);
	wire ioclk_T; // 1000 MHz
	wire ioclk_D; // 1000 MHz
	wire ioce_T;
	wire ioce_D;
	// with some help from https://vjordan.info/log/fpga/high-speed-serial-bus-generation-using-spartan-6.html and/or XAPP1064 source code
	wire cascade_do1;
	wire cascade_to1;
	wire cascade_di1;
	wire cascade_ti1;
	wire cascade_do2;
	wire cascade_to2;
	wire cascade_di2;
	wire cascade_ti2;
	// want MSB of word to come out first
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_T
	         (.OQ(T_out), .TQ(), .CLK0(ioclk_T), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word_in[3]), .D2(word_in[2]), .D3(word_in[1]), .D4(word_in[0]),
	         .IOCE(ioce_T), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do1), .SHIFTIN4(cascade_to1), 
	         .SHIFTOUT1(cascade_di1), .SHIFTOUT2(cascade_ti1), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_T
	         (.OQ(), .TQ(), .CLK0(ioclk_T), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word_in[7]), .D2(word_in[6]), .D3(word_in[5]), .D4(word_in[4]),
	         .IOCE(ioce_T), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_di1), .SHIFTIN2(cascade_ti1), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_do1), .SHIFTOUT4(cascade_to1),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_D
	         (.OQ(D_out), .TQ(), .CLK0(ioclk_D), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word_in[3]), .D2(word_in[2]), .D3(word_in[1]), .D4(word_in[0]),
	         .IOCE(ioce_D), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do2), .SHIFTIN4(cascade_to2), 
	         .SHIFTOUT1(cascade_di2), .SHIFTOUT2(cascade_ti2), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_D
	         (.OQ(), .TQ(), .CLK0(ioclk_D), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word_in[7]), .D2(word_in[6]), .D3(word_in[5]), .D4(word_in[4]),
	         .IOCE(ioce_D), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_di2), .SHIFTIN2(cascade_ti2), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_do2), .SHIFTOUT4(cascade_to2),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	wire locked_T;
	wire locked_D;
	oserdes_pll #(.WIDTH(WIDTH), .CLKIN_PERIOD(PERIOD), .PLLD(DIVIDE), .PLLX(MULTIPLY)) difficult_pll_TR (
		.reset(reset), .clock_in(clock_in), .fabric_clock_out(word_clock_out), 
		.serializer_clock_out_1(ioclk_T), .serializer_strobe_out_1(ioce_T), .locked_1(locked_T),
		.serializer_clock_out_2(ioclk_D), .serializer_strobe_out_2(ioce_D), .locked_2(locked_D)
	);
	assign locked = locked_T & locked_D;
endmodule

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
	wire word_clock; // 125 MHz
	reg [31:0] counter = 0;
	reg sync;
	wire other_clock; // 50.0 MHz
	IBUFGDS coolcool (.I(clock_p), .IB(clock_n), .O(other_clock)); // 50.0 MHz
	wire D;
	wire lvds_trig_output_D;
//	assign lvds_trig_output_D = sync;
	assign lvds_trig_output_D = D;
	OBUFDS catcat1 (.I(lvds_trig_output_D), .O(lvds_trig_output_1_p), .OB(lvds_trig_output_1_n));
	wire T;
	wire lvds_trig_output_T;
	OBUFDS catcat2 (.I(lvds_trig_output_T), .O(lvds_trig_output_2_p), .OB(lvds_trig_output_2_n));
	//assign lvds_trig_output_T = sync;
	assign lvds_trig_output_T = T;
	assign lemo_output = sync;
//	assign lemo_output = D;
	reg [WIDTH-1:0] word;
	wire [7:0] led_byte;
	assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = led_byte;
	reg [7:0] led_reg;
	assign led_byte = led_reg;
	//assign led_byte = ~ word;
	ocyrus_single8 #(.WIDTH(WIDTH), .PERIOD(20.0), .DIVIDE(2), .MULTIPLY(40)) mylei (.clock_in(other_clock), .reset(reset1), .word_clock_out(word_clock), .word_in(word), .D_out(D), .T_out(T), .locked());
	reg [12:0] reset1_counter = 0;
	always @(posedge other_clock) begin // 50.0 MHz
		if (reset1) begin
			if (reset1_counter[10]) begin
				reset1 <= 0;
			end
		end
		reset1_counter <= reset1_counter + 1'b1;
	end
	wire trigger_input;
	IBUFDS angel (.I(lvds_trig_input_p), .IB(lvds_trig_input_n), .O(trigger_input));
	reg [1:0] token;
	reg [2:0] trigger_stream;
	localparam first  = ~ 8'b11111111;
	localparam second = ~ 8'b11110001;
	localparam third  = ~ 8'b10001000;
	localparam forth  = ~ 8'b10101010;
	localparam pickoff = 24;
	always @(posedge word_clock) begin // 125.0 MHz
		if (reset2) begin
			token <= 2'b00;
			trigger_stream <= 0;
			if (counter[10]) begin
				reset2 <= 0;
			end
			led_reg <= 0;
		end
		word <= ~ 8'b00000000;
		if (self_triggered_mode_switch) begin
			if (counter[pickoff:0]==0) begin
				         if (counter[pickoff+2:pickoff+1]==2'b00) begin
					sync <= 1;
					word <= first;
					led_reg <= first;
				end else if (counter[pickoff+2:pickoff+1]==2'b01) begin
					sync <= 0;
					word <= second;
					led_reg <= second;
				end else if (counter[pickoff+2:pickoff+1]==2'b10) begin
					word <= third;
					led_reg <= third;
				end else if (counter[pickoff+2:pickoff+1]==2'b11) begin
					word <= forth;
					led_reg <= forth;
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
		counter <= counter + 1'b1;
	end
endmodule

