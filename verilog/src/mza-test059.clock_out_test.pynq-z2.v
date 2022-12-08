`timescale 1ns / 1ps

// written 2022-11-16 by mza
// last updated 2022-12-08 by mza

module icyrus7series5bit (
	input bit_clock,
	output word_clock,
	input reset,
	output [4:0] output_word,
	input input_bit
);
	BUFR #(.BUFR_DIVIDE("5"), .SIM_DEVICE("7SERIES")) deviate (.I(bit_clock), .O(word_clock), .CLR(reset), .CE(1'b1));
	// ISERDESE2: Input SERial/DESerializer with Bitslip
	// 7 Series Xilinx HDL Language Template, version 2018.3
	// from UG953 (v2018.3) December 5, 2018
	ISERDESE2 #(
		.DATA_RATE("SDR"), // DDR, SDR
		.DATA_WIDTH(5), // Parallel data width (2-8,10,14)
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
	) ISERDESE2_inst (
		.O(), // 1-bit output: Combinatorial output
		// Q1 - Q8: 1-bit (each) output: Registered data outputs
		.Q1(output_word[4]), .Q2(output_word[3]), .Q3(output_word[2]), .Q4(output_word[1]),
		.Q5(output_word[0]), .Q6(), .Q7(), .Q8(),
		.SHIFTOUT1(), .SHIFTOUT2(), // SHIFTOUT1, SHIFTOUT2: 1-bit (each) output: Data width expansion output ports
		.BITSLIP(1'b0), // 1-bit input: The BITSLIP pin performs a Bitslip operation synchronous to CLKDIV when asserted (active High). Subsequently, the data seen on the Q1 to Q8 output ports will shift, as in a barrel-shifter operation, one position every time Bitslip is invoked (DDR operation is different from SDR).
		.CE1(1'b1), .CE2(1'b1), // CE1, CE2: 1-bit (each) input: Data register clock enable inputs
		.CLKDIVP(1'b0), // 1-bit input: MIG only; all others connect to GND
		// Clocks: 1-bit (each) input: ISERDESE2 clock input ports
		.CLK(bit_clock), // 1-bit input: High-speed clock
		.CLKB(1'b0), // 1-bit input: High-speed secondary clock
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
endmodule

module clock_out_test #(
	parameter clock_select = 0
) (
//	input sysclk, // 125 MHz, comes from RTL8211 (ethernet) via 50 MHz osc
	input [5:4] ja, // 127.216 MHz, comes from PMODA
//	input hdmi_rx_clk_p, // dummy for 1.27216 GHz clock from gulfstream
//	input hdmi_rx_cec, // dummy data
	output rpio_02_r, // clock out
//	output rpio_03_r, // dummy output
	output rpio_04_r, // source word_clock out
	output rpio_08_r, // output_word[0]
	output rpio_09_r, // output_word[1]
	output rpio_10_r, // output_word[2]
	output rpio_11_r, // output_word[3]
	output rpio_12_r, // output_word[4]
	output hdmi_tx_clk_p, // system word_clock out
	output hdmi_tx_clk_n,
	input hdmi_rx_clk_p, // bit_clock in
	input hdmi_rx_clk_n,
	//input [2:0] hdmi_rx_d_p, // input_bit
	//input [2:0] hdmi_rx_d_n,
	input hdmi_rx_d_p, // input_bit
	input hdmi_rx_d_n,
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
		IBUFGDS clock_in (.I(ja[4]), .IB(ja[5]), .O(clock));
	end
	OBUFDS (.I(clock), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	assign rpio_02_r = clock;
//	reg thing = 0;
//	always @(posedge hdmi_rx_clk_p) begin
//		thing <= hdmi_rx_cec;
//	end
//	assign rpio_03_r = thing;
	wire bit_clock;
	IBUFGDS clock_in (.I(hdmi_rx_clk_p), .IB(hdmi_rx_clk_n), .O(bit_clock));
	wire input_bit;
	IBUFGDS data_in (.I(hdmi_rx_d_p), .IB(hdmi_rx_d_n), .O(input_bit));
	wire word_clock;
	assign rpio_04_r = word_clock;
	wire [4:0] output_word;
	assign { rpio_12_r, rpio_11_r, rpio_10_r, rpio_09_r, rpio_08_r } = output_word;
	icyrus7series5bit (.bit_clock(bit_clock), .word_clock(word_clock), .reset(reset), .output_word(output_word), .input_bit(input_bit));
endmodule

