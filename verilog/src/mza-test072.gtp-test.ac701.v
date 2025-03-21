`timescale 1ns / 1ps

// written 2025-03-20 by mza
// based on mza-test071.prbs-lfsr.ac701.v
// last updated 2025-03-20 by mza

// cd /opt/Xilinx/Vivado/2023.2/data/xicom/cable_drivers/lin64/install_script/install_drivers; sudo ./install_drivers

`include "lib/generic.v"
`include "lib/plldcm.v"
`include "lib/serdes_pll.v"

module GTP_TEST #(
	parameter OSERDES_WIDTH = 8,
	parameter PRBSLFSR_WIDTH = OSERDES_WIDTH + OSERDES_WIDTH,
	parameter COUNTER_PICKOFF_RESET1 = 14,
	parameter COUNTER_PICKOFF_RESET2 = COUNTER_PICKOFF_RESET1 + 1,
	parameter COUNTER_PICKOFF_RESET3 = COUNTER_PICKOFF_RESET2 + 1,
	parameter COUNTER_PICKOFF_RESET4 = COUNTER_PICKOFF_RESET3 + 1
) (
	input SYSCLK_P, SYSCLK_N, // 200 MHz
	output GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0
);
	wire sysclk;
	IBUFDS iclk (.I(SYSCLK_P), .IB(SYSCLK_N), .O(sysclk));
	wire raw_bit_clock, bit_clock, word_clock, sysclk_pll_locked;
	reg reset1_sysclk = 1'b1, reset2_sysclk = 1'b1, reset3_sysclk = 1'b1, reset4_sysclk = 1'b1;
	reg reset2_copy1_on_raw_bit_clock = 1'b1, reset3_copy1_on_raw_bit_clock = 1'b1, reset4_copy1_on_word_clock = 1'b1;
	reg reset2_copy2_on_raw_bit_clock = 1'b1, reset3_copy2_on_raw_bit_clock = 1'b1, reset4_copy2_on_word_clock = 1'b1;
	reg [COUNTER_PICKOFF_RESET4:0] counter = 0;
	always @(posedge sysclk) begin
		counter <= counter + 1'b1;
		if (counter[COUNTER_PICKOFF_RESET1]) begin reset1_sysclk <= 0; end
		if (counter[COUNTER_PICKOFF_RESET2]) begin reset2_sysclk <= 0; end
		if (counter[COUNTER_PICKOFF_RESET3]) begin reset3_sysclk <= 0; end
		if (counter[COUNTER_PICKOFF_RESET4]) begin reset4_sysclk <= 0; end
	end
	always @(posedge raw_bit_clock) begin
		reset2_copy2_on_raw_bit_clock <= reset2_copy1_on_raw_bit_clock;
		reset2_copy1_on_raw_bit_clock <= reset2_sysclk;
		reset3_copy2_on_raw_bit_clock <= reset3_copy1_on_raw_bit_clock;
		reset3_copy1_on_raw_bit_clock <= reset3_sysclk;
	end
	always @(posedge word_clock) begin
		reset4_copy2_on_word_clock <= reset4_copy1_on_word_clock;
		reset4_copy1_on_word_clock <= reset4_sysclk;
	end
	MMCM_advanced #(
		.CLOCK1_PERIOD_NS(5.0), .D(4), .M(25), // Fvco = [600, 1440] MHz
		.CLKOUT0_DIVIDE(2), // 625 MHz (DDR yields 1250 MHz)
		.CLKOUT1_DIVIDE(8), //
		.CLKOUT2_DIVIDE(1), //
		.CLKOUT3_DIVIDE(1), //
		.CLKOUT4_DIVIDE(1), //
		.CLKOUT5_DIVIDE(1), //
		.CLKOUT6_DIVIDE(1)  //
			) mymmcm0 (
		.clock_in(sysclk), .reset(reset1_sysclk), .locked(sysclk_pll_locked),
		.clock0_out_p(raw_bit_clock), .clock0_out_n(), .clock1_out_p(word_clock), .clock1_out_n(),
		.clock2_out_p(), .clock2_out_n(), .clock3_out_p(), .clock3_out_n(),
		.clock4_out(), .clock5_out(), .clock6_out());
	if (1) begin
		reg [26:0] counter = 0;
		always @(posedge word_clock) begin
			counter <= counter + 1'b1;
		end
		assign { GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = counter[26:23];
		x0y3_sma_exdes mygtp (.Q0_CLK0_GTREFCLK_PAD_N_IN(), .Q0_CLK0_GTREFCLK_PAD_P_IN(), .DRP_CLK_IN_P(), .DRP_CLK_IN_N(), .GTTX_RESET_IN(), .GTRX_RESET_IN(), .PLL0_RESET_IN(), .PLL1_RESET_IN(), .TXN_OUT(), .TXP_OUT());
	end
endmodule

