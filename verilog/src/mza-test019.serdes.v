`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2018-09-18 by mza

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
	reg trigout;
	//assign ttl_trig_output = trigout;
	wire clock;
	reg [31:0] counter;
	assign led0 = counter[27];
	assign led1 = reset;
	assign led2 = 0;
	reg reset = 1;
//	wire clock_inverted;
//	assign clock_inverted = ~ clock;
//	IBUFDS clockbuf (.I(clock_p), .IB(clock_n), .O(clock)); // 250 MHz
//	wire another_clock;
//	ODDR2 ogre (.Q(another_clock), .C0(clock), .C1(~clock), .D0(0), .D1(1), .S(0), .R(0));
//	wire tog;
//	FDCE fargo (.D(~tog), .CE(1'b1), .C(clock), .CLR(0), .Q(tog));
	wire other_clock_p;
	wire other_clock_n;
	IBUFDS_DIFF_OUT wtf_xilinx (.I(clock_p), .IB(clock_n), .O(other_clock_p), .OB(other_clock_n));
//	wire DIVCLK;
//	wire CLKDIV;
	wire CLK0;
	wire IOCE;
	wire unbuffered_clock;
//	BUFIO2 #(.USE_DOUBLER("FALSE")) buffy (.I(tog), .DIVCLK(DIVCLK), .IOCLK(CLK0), .SERDESSTROBE(IOCE));
	BUFIO2_2CLK buffy (.I(other_clock_p), .IB(other_clock_n), .DIVCLK(unbuffered_clock), .IOCLK(CLK0), .SERDESSTROBE(IOCE));
//	BUFIO2_2CLK buffy (.I(clock_p), .IB(clock_n), .DIVCLK(clock), .IOCLK(CLK0), .SERDESSTROBE(IOCE));
//	BUFG asdf (.I(DIVCLK), .O(CLKDIV));
	BUFG asdf (.I(unbuffered_clock), .O(clock));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(4),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus
	         (.OQ(ttl_trig_output), .CLK0(CLK0), .CLK1(0), .CLKDIV(clock),
	         .D1(1), .D2(0), .D3(1), .D4(1), .IOCE(IOCE), .OCE(1), .RST(reset), .TCE(1), .TRAIN(0));
	always @(posedge clock) begin
		if (reset) begin
			if (counter[10]) begin
				reset = 0;
			end
		end
		trigout <= ~ trigout;
		counter <= counter + 1;
	end
endmodule
