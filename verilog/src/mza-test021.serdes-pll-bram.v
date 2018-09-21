`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2018-09-20 by mza

module mza_test021_serdes_pll_bram (
	input clock_p,
	input clock_n,
	output ttl_trig_output,
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
	//output lvds_trig_output_p,
	//output lvds_trig_output_n
);
	localparam WIDTH = 8;
	reg reset1 = 1;
	reg reset2 = 1;
	wire clock; // 125 MHz
	reg [31:0] counter = 0;
	assign led_8 = counter[27-$clog2(WIDTH)]; // ~ 1 Hz
	assign led_9 = reset1;
	assign led_a = reset2;
	wire other_clock;
	IBUFGDS coolcool (.I(clock_p), .IB(clock_n), .O(other_clock)); // 156.25 MHz
	wire IOCLK0;
	wire IOCE;
//	wire unbuffered_clock;
//	BUFIO2 #(.DIVIDE(WIDTH), .USE_DOUBLER("FALSE"), .I_INVERT("FALSE"), .DIVIDE_BYPASS("FALSE")) buffy (.I(other_clock), .DIVCLK(unbuffered_clock), .IOCLK(IOCLK0), .SERDESSTROBE(IOCE));
//	BUFG asdf (.I(unbuffered_clock), .O(clock)); // 156.25 MHz divided by WIDTH
	// with some help from https://vjordan.info/log/fpga/high-speed-serial-bus-generation-using-spartan-6.html and/or XAPP1064 source code
	wire cascade_do;
	wire cascade_to;
	wire cascade_di;
	wire cascade_ti;
	reg [WIDTH-1:0] word;
	localparam pickoff = 27;
//	assign word = { 6'b0, counter[WIDTH-7]&counter[pickoff], counter[WIDTH-8]&counter[pickoff] };
	wire [7:0] led_byte;
	assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = led_byte;
	assign led_byte = word;
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master
	         (.OQ(ttl_trig_output), .TQ(), .CLK0(IOCLK0), .CLK1(1'b0), .CLKDIV(clock),
	         .D1(word[7]), .D2(word[6]), .D3(word[5]), .D4(word[4]),
	         .IOCE(IOCE), .OCE(1'b1), .RST(reset1), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do), .SHIFTIN4(cascade_to), 
	         .SHIFTOUT1(cascade_di), .SHIFTOUT2(cascade_ti), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave
	         (.OQ(), .TQ(), .CLK0(IOCLK0), .CLK1(1'b0), .CLKDIV(clock),
	         .D1(word[3]), .D2(word[2]), .D3(word[1]), .D4(word[0]),
	         .IOCE(IOCE), .OCE(1'b1), .RST(reset1), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_di), .SHIFTIN2(cascade_ti), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_do), .SHIFTOUT4(cascade_to),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	reg [12:0] reset1_counter = 0;
	always @(posedge other_clock) begin
		if (reset1) begin
			if (reset1_counter[10]) begin
				reset1 <= 0;
			end
		end
		reset1_counter <= reset1_counter + 1;
	end
	always @(posedge clock) begin
		if (reset2) begin
			if (counter[10]) begin
				reset2 <= 0;
			end
		end
		word <= 8'b00000000;
		if (counter[pickoff:0]==0) begin
			if (counter[pickoff+2:pickoff+1]==2'b00) begin
				word <= 8'b00000001;
			end else if (counter[pickoff+2:pickoff+1]==2'b01) begin
				word <= 8'b00000011;
			end else if (counter[pickoff+2:pickoff+1]==2'b10) begin
				word <= 8'b00000111;
			end else if (counter[pickoff+2:pickoff+1]==2'b11) begin
				word <= 8'b00001111;
			end
		end
		counter <= counter + 1;
	end
//	assign ttl_trig_output = counter[0];
	oserdes_pll difficult_pll (.reset(reset1), .clock_in(other_clock), .fabric_clock_out(clock), .serializer_clock_out(IOCLK0), .serializer_strobe_output(IOCE), .locked(led_b));
endmodule

// 156.25 / 8.0 * 61.875 / 2.375 = 508.840461
module oserdes_pll (input clock_in, input reset, output fabric_clock_out, output serializer_clock_out, output serializer_strobe_output, output locked);
// from clock_generator_pll_s8_diff.v from XAPP1064 example code
parameter integer PLLD = 5; // 1 to 52 on a spartan6
parameter integer PLLX = 32; // 1 to 64 on a spartan6
// frequency of VCO after div and mult must be in range [400,1080] MHz
parameter integer S = 8; // 1 to 128 on a spartan6
parameter real CLKIN_PERIOD = 6.4; // clock period (ns) of input clock on clkin_p
wire pllout_x1; // pll generated x1 clock
wire pllout_xn; // pll generated xn clock
wire dummy; // feedback net
wire pll_is_locked; // Locked output from PLL
wire buffered_pll_is_locked_and_strobe_is_aligned;
assign locked = pll_is_locked & buffered_pll_is_locked_and_strobe_is_aligned;
PLL_ADV #(
	.SIM_DEVICE("SPARTAN6"),
	.BANDWIDTH("OPTIMIZED"), // "high", "low" or "optimized"
	.CLKFBOUT_PHASE(0.0), // phase shift (degrees) of all output clocks
	.CLKIN1_PERIOD(CLKIN_PERIOD), // clock period (ns) of input clock on clkin1
	.CLKIN2_PERIOD(CLKIN_PERIOD), // clock period (ns) of input clock on clkin2
	.DIVCLK_DIVIDE(PLLD), // division factor for all clocks (1 to 52)
	.CLKFBOUT_MULT(PLLX), // multiplication factor for all output clocks
	.CLKOUT0_DIVIDE(1), // division factor for clkout0 (1 to 128)
	.CLKOUT0_DUTY_CYCLE(0.5), // duty cycle for clkout0 (0.01 to 0.99)
	.CLKOUT0_PHASE(0.0), // phase shift (degrees) for clkout0 (0.0 to 360.0)
	.CLKOUT1_DIVIDE(1), // division factor for clkout1 (1 to 128)
	.CLKOUT1_DUTY_CYCLE(0.5), // duty cycle for clkout1 (0.01 to 0.99)
	.CLKOUT1_PHASE(0.0), // phase shift (degrees) for clkout1 (0.0 to 360.0)
	.CLKOUT2_DIVIDE(S), // division factor for clkout2 (1 to 128)
	.CLKOUT2_DUTY_CYCLE(0.5), // duty cycle for clkout2 (0.01 to 0.99)
	.CLKOUT2_PHASE(0.0), // phase shift (degrees) for clkout2 (0.0 to 360.0)
	.CLKOUT3_DIVIDE(8), // division factor for clkout3 (1 to 128)
	.CLKOUT3_DUTY_CYCLE(0.5), // duty cycle for clkout3 (0.01 to 0.99)
	.CLKOUT3_PHASE(0.0), // phase shift (degrees) for clkout3 (0.0 to 360.0)
	.CLKOUT4_DIVIDE(8), // division factor for clkout4 (1 to 128)
	.CLKOUT4_DUTY_CYCLE(0.5), // duty cycle for clkout4 (0.01 to 0.99)
	.CLKOUT4_PHASE(0.0), // phase shift (degrees) for clkout4 (0.0 to 360.0)
	.CLKOUT5_DIVIDE(8), // division factor for clkout5 (1 to 128)
	.CLKOUT5_DUTY_CYCLE(0.5), // duty cycle for clkout5 (0.01 to 0.99)
	.CLKOUT5_PHASE(0.0), // phase shift (degrees) for clkout5 (0.0 to 360.0)
	.COMPENSATION("INTERNAL"), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL", "DCM2PLL", "PLL2DCM"
	.REF_JITTER(0.100) // input reference jitter (0.000 to 0.999 ui%)
	) tx_pll_adv_inst (
	.RST(reset), // asynchronous pll reset
	.LOCKED(pll_is_locked), // active high pll lock signal
	.CLKFBIN(dummy), // clock feedback input
	.CLKFBOUT(dummy), // general output feedback signal
	.CLKIN1(clock_in), // primary clock input
	.CLKOUT0(pllout_xn), // *n clock for transmitter
	.CLKOUT1(), //
	.CLKOUT2(pllout_x1), // *1 clock for BUFG
	.CLKOUT3(), // one of six general clock output signals
	.CLKOUT4(), // one of six general clock output signals
	.CLKOUT5(), // one of six general clock output signals
	.CLKFBDCM(), // output feedback signal used when pll feeds a dcm
	.CLKOUTDCM0(), // one of six clock outputs to connect to the dcm
	.CLKOUTDCM1(), // one of six clock outputs to connect to the dcm
	.CLKOUTDCM2(), // one of six clock outputs to connect to the dcm
	.CLKOUTDCM3(), // one of six clock outputs to connect to the dcm
	.CLKOUTDCM4(), // one of six clock outputs to connect to the dcm
	.CLKOUTDCM5(), // one of six clock outputs to connect to the dcm
	.DO(), // dynamic reconfig data output (16-bits)
	.DRDY(), // dynamic reconfig ready output
	.CLKIN2(1'b0), // secondary clock input
	.CLKINSEL(1'b1), // selects '1' = clkin1, '0' = clkin2
	.DADDR(5'b00000), // dynamic reconfig address input (5-bits)
	.DCLK(1'b0), // dynamic reconfig clock input
	.DEN(1'b0), // dynamic reconfig enable input
	.DI(16'h0000), // dynamic reconfig data input (16-bits)
	.DWE(1'b0), // dynamic reconfig write enable input
	.REL(1'b0) // used to force the state of the PFD outputs (test only)
	);

BUFG bufg_tx (.I(pllout_x1), .O(fabric_clock_out));

BUFPLL #(
	.DIVIDE(S) // PLLIN0 divide-by value to produce SERDESSTROBE (1 to 8); default 1
	) tx_bufpll_inst (
	.PLLIN(pllout_xn), // PLL Clock input
	.GCLK(fabric_clock_out), // Global Clock input
	.LOCKED(pll_is_locked), // Clock0 locked input
	.IOCLK(serializer_clock_out), // Output PLL Clock
	.LOCK(buffered_pll_is_locked_and_strobe_is_aligned), // BUFPLL Clock and strobe locked
	.SERDESSTROBE(serializer_strobe_output) // Output SERDES strobe
	);

endmodule

