`timescale 1ns / 1ps

// written 2022-11-16 by mza
// last updated 2022-12-12 by mza

module icyrus7series10bit (
	input bit_clock, bit_clock_inverted,
	output word_clock,
	input reset,
	output [9:0] output_word,
	input input_bit
);
	wire the_bit_clock;
//	wire the_bit_clock_inverted;
	BUFIO mediate (.I(bit_clock), .O(the_bit_clock));
	BUFR #(.BUFR_DIVIDE("5"), .SIM_DEVICE("7SERIES")) deviate (.I(bit_clock), .O(word_clock), .CLR(reset), .CE(1'b1));
	// ISERDESE2: Input SERial/DESerializer with Bitslip
	// 7 Series Xilinx HDL Language Template, version 2018.3
	// from UG953 (v2018.3) December 5, 2018
	wire shiftout1, shiftout2;
	ISERDESE2 #(
		.DATA_RATE("DDR"), // DDR, SDR
		.DATA_WIDTH(10), // Parallel data width (2-8,10,14)
		.DYN_CLKDIV_INV_EN("FALSE"), // Enable DYNCLKDIVINVSEL inversion (FALSE, TRUE)
		.DYN_CLK_INV_EN("FALSE"), // Enable DYNCLKINVSEL inversion (FALSE, TRUE)
		.INIT_Q1(1'b0), .INIT_Q2(1'b0), .INIT_Q3(1'b0), .INIT_Q4(1'b0), // INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
		.INTERFACE_TYPE("NETWORKING"), // MEMORY, MEMORY_DDR3, MEMORY_QDR, NETWORKING, OVERSAMPLE
		.IOBDELAY("NONE"), // NONE, BOTH, IBUF, IFD
		.NUM_CE(1), // Number of clock enables (1,2)
		.OFB_USED("FALSE"), // Select OFB path (FALSE, TRUE)
		.SERDES_MODE("MASTER"), // M*****, S****
		// SRVAL_Q1 - SRVAL_Q4: Q output values when SR is used (0/1)
		.SRVAL_Q1(1'b0), .SRVAL_Q2(1'b0), .SRVAL_Q3(1'b0), .SRVAL_Q4(1'b0)
	) ISERDESE2_a (
		.O(), // 1-bit output: Combinatorial output
		// Q1 - Q8: 1-bit (each) output: Registered data outputs
		.Q1(output_word[0]), .Q2(output_word[1]), .Q3(output_word[2]), .Q4(output_word[3]),
		.Q5(output_word[4]), .Q6(output_word[5]), .Q7(output_word[6]), .Q8(output_word[7]),
		.SHIFTOUT1(shiftout1), .SHIFTOUT2(shiftout2), // SHIFTOUT1, SHIFTOUT2: 1-bit (each) output: Data width expansion output ports
		.BITSLIP(1'b0), // 1-bit input: The BITSLIP pin performs a Bitslip operation synchronous to CLKDIV when asserted (active High). Subsequently, the data seen on the Q1 to Q8 output ports will shift, as in a barrel-shifter operation, one position every time Bitslip is invoked (DDR operation is different from SDR).
		.CE1(1'b1), .CE2(1'b1), // CE1, CE2: 1-bit (each) input: Data register clock enable inputs
		.CLKDIVP(1'b0), // 1-bit input: MIG only; all others connect to GND
		// Clocks: 1-bit (each) input: ISERDESE2 clock input ports
		.CLK(the_bit_clock), // 1-bit input: High-speed clock
		.CLKB(bit_clock_inverted), // 1-bit input: High-speed secondary clock
		.CLKDIV(word_clock), // 1-bit input: Divided clock
		.OCLK(1'b0), // 1-bit input: High speed output clock used when INTERFACE_TYPE="MEMORY"; all others connect to GND
		// Dynamic Clock Inversions: 1-bit (each) input: Dynamic clock inversion pins to switch clock polarity
		.DYNCLKDIVSEL(1'b0), // 1-bit input: Dynamic CLKDIV inversion
		.DYNCLKSEL(1'b0), // 1-bit input: Dynamic CLK/CLKB inversion
		// Input Data: 1-bit (each) input: ISERDESE2 data input ports
		.D(input_bit), // 1-bit input: Data input
		.DDLY(1'b0), // 1-bit input: Serial data from IDELAYE2
		.OFB(1'b0), // 1-bit input: Data feedback from OSERDESE2
		.OCLKB(1'b0), // 1-bit input: High speed negative edge output clock
		.RST(reset), // 1-bit input: Active high asynchronous reset
		.SHIFTIN1(1'b0), .SHIFTIN2(1'b0) // SHIFTIN1, SHIFTIN2: 1-bit (each) input: Data width expansion input ports; all others connect to GND
	);
	ISERDESE2 #(
		.DATA_RATE("DDR"), // DDR, SDR
		.DATA_WIDTH(10), // Parallel data width (2-8,10,14)
		.DYN_CLKDIV_INV_EN("FALSE"), // Enable DYNCLKDIVINVSEL inversion (FALSE, TRUE)
		.DYN_CLK_INV_EN("FALSE"), // Enable DYNCLKINVSEL inversion (FALSE, TRUE)
		.INIT_Q1(1'b0), .INIT_Q2(1'b0), .INIT_Q3(1'b0), .INIT_Q4(1'b0), // INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
		.INTERFACE_TYPE("NETWORKING"), // MEMORY, MEMORY_DDR3, MEMORY_QDR, NETWORKING, OVERSAMPLE
		.IOBDELAY("NONE"), // NONE, BOTH, IBUF, IFD
		.NUM_CE(1), // Number of clock enables (1,2)
		.OFB_USED("FALSE"), // Select OFB path (FALSE, TRUE)
		.SERDES_MODE("SLAVE"), // M*****, S****
		// SRVAL_Q1 - SRVAL_Q4: Q output values when SR is used (0/1)
		.SRVAL_Q1(1'b0), .SRVAL_Q2(1'b0), .SRVAL_Q3(1'b0), .SRVAL_Q4(1'b0)
	) ISERDESE2_1 (
		.O(), // 1-bit output: Combinatorial output
		// Q1 - Q8: 1-bit (each) output: Registered data outputs
		.Q1(), .Q2(), .Q3(output_word[8]), .Q4(output_word[9]),
		.Q5(), .Q6(), .Q7(), .Q8(),
		.SHIFTOUT1(), .SHIFTOUT2(), // SHIFTOUT1, SHIFTOUT2: 1-bit (each) output: Data width expansion output ports
		.BITSLIP(1'b0), // 1-bit input: The BITSLIP pin performs a Bitslip operation synchronous to CLKDIV when asserted (active High). Subsequently, the data seen on the Q1 to Q8 output ports will shift, as in a barrel-shifter operation, one position every time Bitslip is invoked (DDR operation is different from SDR).
		.CE1(1'b1), .CE2(1'b1), // CE1, CE2: 1-bit (each) input: Data register clock enable inputs
		.CLKDIVP(1'b0), // 1-bit input: MIG only; all others connect to GND
		// Clocks: 1-bit (each) input: ISERDESE2 clock input ports
		.CLK(the_bit_clock), // 1-bit input: High-speed clock
		.CLKB(bit_clock_inverted), // 1-bit input: High-speed secondary clock
		.CLKDIV(word_clock), // 1-bit input: Divided clock
		.OCLK(1'b0), // 1-bit input: High speed output clock used when INTERFACE_TYPE="MEMORY"; all others connect to GND
		// Dynamic Clock Inversions: 1-bit (each) input: Dynamic clock inversion pins to switch clock polarity
		.DYNCLKDIVSEL(1'b0), // 1-bit input: Dynamic CLKDIV inversion
		.DYNCLKSEL(1'b0), // 1-bit input: Dynamic CLK/CLKB inversion
		// Input Data: 1-bit (each) input: ISERDESE2 data input ports
		.D(), // 1-bit input: Data input
		.DDLY(1'b0), // 1-bit input: Serial data from IDELAYE2
		.OFB(1'b0), // 1-bit input: Data feedback from OSERDESE2
		.OCLKB(1'b0), // 1-bit input: High speed negative edge output clock
		.RST(reset), // 1-bit input: Active high asynchronous reset
		.SHIFTIN1(shiftout1), .SHIFTIN2(shiftout2) // SHIFTIN1, SHIFTIN2: 1-bit (each) input: Data width expansion input ports; all others connect to GND
	);
endmodule

module clock_out_test #(
	parameter clock_select = 0
) (
//	input sysclk, // 125 MHz, comes from RTL8211 (ethernet) via 50 MHz osc
	output [7:0] jb, // pmodB
	input [5:4] ja, // 127.216 MHz, comes from PMODA
//	input [7:6] ja, // 42.3724 MHz, comes from PMODA
	input [1:0] sw,
//	input hdmi_rx_clk_p, // dummy for 1.27216 GHz clock from gulfstream
//	output hdmi_rx_cec, // dummy data
	output hdmi_tx_cec, // dummy data
	output rpio_02_r, // clock out
//	output rpio_03_r, // dummy output
	output rpio_04_r, // source word_clock out
	output rpio_08_r, // output_word[0]
	output rpio_09_r, // output_word[1]
	output rpio_10_r, // output_word[2]
	output rpio_11_r, // output_word[3]
	output rpio_12_r, // output_word[4]
	output rpio_13_r, // output_word[5]
	output rpio_14_r, // output_word[6]
	output rpio_15_r, // output_word[7]
	output rpio_16_r, // output_word[8]
	output rpio_17_r, // output_word[9]
	output hdmi_tx_clk_p, // system word_clock out
	output hdmi_tx_clk_n,
	inout hdmi_rx_clk_p, // bit_clock in
	inout hdmi_rx_clk_n,
	//input [2:0] hdmi_rx_d_p, // input_bit
	//input [2:0] hdmi_rx_d_n,
	input [2:0] hdmi_rx_d_p, // input_bit
	input [2:0] hdmi_rx_d_n,
	inout hdmi_rx_scl,
	output hdmi_rx_sda
);
	wire reset = 0;
	assign hdmi_rx_scl = 0;
	assign hdmi_rx_sda = 0;
	wire clock;
	if (clock_select) begin
//		IBUFG clock_in (.I(sysclk), .O(clock));
	end else begin
		IBUFGDS clock_in_diff (.I(ja[4]), .IB(ja[5]), .O(clock));
		//IBUFG clock_in_se (.I(ja[7]), .O(clock));
	end
//	OBUFDS (.I(clock), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	wire clock_enable;
	assign clock_enable = sw[0];
	wire clock_oddr1;
	wire clock_oddr2;
	wire clock_oddr3;
	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_inst1 (.C(clock), .CE(clock_enable), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(clock_oddr1));
	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_inst2 (.C(clock), .CE(clock_enable), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(clock_oddr2));
	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_inst3 (.C(clock), .CE(clock_enable), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(clock_oddr3));
	OBUFDS (.I(clock_oddr1), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	assign rpio_02_r = clock_oddr2;
	assign hdmi_tx_cec = clock_oddr3;
//	reg thing = 0;
//	always @(posedge hdmi_rx_clk_p) begin
//		thing <= hdmi_rx_cec;
//	end
//	assign rpio_03_r = thing;
//	assign rpio_03_r = clock;
	wire bit_clock;
	wire bit_clock_inverted;
	IOBUFDS_DIFF_OUT clock_in (.IO(hdmi_rx_clk_p), .IOB(hdmi_rx_clk_n), .TM(1'b1), .TS(1'b1), .I(1'b0), .O(bit_clock), .OB(bit_clock_inverted));
	wire input_bit;
	IBUFDS data_in (.I(hdmi_rx_d_p[1]), .IB(hdmi_rx_d_n[1]), .O(input_bit));
	wire word_clock;
	assign rpio_04_r = word_clock;
	wire [9:0] output_word;
	assign { rpio_17_r, rpio_16_r, rpio_15_r, rpio_14_r, rpio_13_r, rpio_12_r, rpio_11_r, rpio_10_r, rpio_09_r, rpio_08_r } = output_word;
	assign jb = output_word[9:2];
	icyrus7series10bit (.bit_clock(bit_clock), .bit_clock_inverted(bit_clock_inverted), .word_clock(word_clock), .reset(reset), .output_word(output_word), .input_bit(input_bit));
endmodule

