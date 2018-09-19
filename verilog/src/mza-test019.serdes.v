`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2018-09-19 by mza

module mza_test019_serdes (
	input clock_p,
	input clock_n,
	output ttl_trig_output,
	output led0,
	output led1,
	output led2
	//output lvds_trig_output_p,
	//output lvds_trig_output_n
);
	localparam WIDTH = 4;
	wire clock;
	reg [31:0] counter = 0;
	assign led0 = counter[27-$clog2(WIDTH)]; // ~ 1 Hz
	assign led1 = reset;
	assign led2 = 0;
	reg reset = 1;
	wire other_clock;
	IBUFDS coolcool (.I(clock_p), .IB(clock_n), .O(other_clock)); // 156.25 MHz
	wire IOCLK0;
	wire IOCE;
	wire unbuffered_clock;
	BUFIO2 #(.DIVIDE(WIDTH), .USE_DOUBLER("FALSE"), .I_INVERT("FALSE"), .DIVIDE_BYPASS("FALSE")) buffy (.I(other_clock), .DIVCLK(unbuffered_clock), .IOCLK(IOCLK0), .SERDESSTROBE(IOCE));
	BUFG asdf (.I(unbuffered_clock), .O(clock)); // 156.25 MHz divided by WIDTH
	// with some help from https://vjordan.info/log/fpga/high-speed-serial-bus-generation-using-spartan-6.html and/or XAPP1064 source code
	wire cascade_do;
	wire cascade_to;
	wire cascade_di;
	wire cascade_ti;
	assign cascade_do = 1'b1;
	assign cascade_to = 1'b1;
	wire [WIDTH-1:0] word;
//	assign word = counter[WIDTH-1:0];
	assign word = { 1'b0, counter[WIDTH-1:1] };
//	assign word = { 2'b0, counter[WIDTH-1:2] };
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("NONE"))
	         osirus_none
	         (.OQ(ttl_trig_output), .TQ(), .CLK0(IOCLK0), .CLK1(1'b0), .CLKDIV(clock),
	         .D1(word[3]), .D2(word[2]), .D3(word[1]), .D4(word[0]),
	         .IOCE(IOCE), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do), .SHIFTIN4(cascade_to), 
	         .SHIFTOUT1(cascade_di), .SHIFTOUT2(cascade_ti), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
//	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
//	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
//	         osirus_master
//	         (.OQ(ttl_trig_output), .TQ(), .CLK0(IOCLK0), .CLK1(1'b0), .CLKDIV(clock),
//	         .D1(word[7]), .D2(word[6]), .D3(word[5]), .D4(word[4]),
//	         .IOCE(IOCE), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
//	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do), .SHIFTIN4(cascade_to), 
//	         .SHIFTOUT1(cascade_di), .SHIFTOUT2(cascade_ti), .SHIFTOUT3(), .SHIFTOUT4(), 
//	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
//	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
//	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
//	         osirus_slave
//	         (.OQ(), .TQ(), .CLK0(IOCLK0), .CLK1(1'b0), .CLKDIV(clock),
//	         .D1(word[3]), .D2(word[2]), .D3(word[1]), .D4(word[0]),
//	         .IOCE(IOCE), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
//	         .SHIFTIN1(cascade_di), .SHIFTIN2(cascade_ti), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
//	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_do), .SHIFTOUT4(cascade_to),
//	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	always @(posedge clock) begin
		if (reset) begin
			if (counter[10]) begin
				reset = 0;
			end
		end
		counter <= counter + 1;
	end
//	ODDR2 ogre (.Q(ttl_trig_output), .C0(other_clock_p), .C1(other_clock_n), .D0(1'b0), .D1(1'b1), .S(1'b0), .R(reset), .CE(1'b1));
//	assign ttl_trig_output = counter[0];
endmodule
