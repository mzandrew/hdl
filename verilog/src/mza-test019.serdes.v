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
	wire clock;
	reg [31:0] counter;
	assign led0 = counter[27];
	assign led1 = reset;
	assign led2 = 0;
	reg reset = 1;
	wire other_clock_p;
	wire other_clock_n;
	IBUFDS_DIFF_OUT wtf_xilinx (.I(clock_p), .IB(clock_n), .O(other_clock_p), .OB(other_clock_n));
	wire IOCLK0;
	wire IOCE;
	wire unbuffered_clock;
	BUFIO2_2CLK buffy (.I(other_clock_p), .IB(other_clock_n), .DIVCLK(unbuffered_clock), .IOCLK(IOCLK0), .SERDESSTROBE(IOCE));
	BUFG asdf (.I(unbuffered_clock), .O(clock));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(4),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus
	         (.OQ(ttl_trig_output), .CLK0(IOCLK0), .CLK1(1'b0), .CLKDIV(clock),
	         .D1(1'b1), .D2(1'b0), .D3(1'b1), .D4(1'b1), .IOCE(IOCE), .OCE(1'b1), .RST(reset), .TCE(1'b1), .TRAIN(1'b0));
	always @(posedge clock) begin
		if (reset) begin
			if (counter[10]) begin
				reset = 0;
			end
		end
		counter <= counter + 1;
	end
endmodule
