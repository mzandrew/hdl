`timescale 1ns / 1ps

// written 2025-03-21 by mza
// based on mza-test072.gtp-test.ac701.v
// last updated 2025-03-21 by mza

// cd /opt/Xilinx/Vivado/2023.2/data/xicom/cable_drivers/lin64/install_script/install_drivers; sudo ./install_drivers

`include "lib/generic.v"
`include "lib/plldcm.v"
`include "lib/prbs.v"
`include "lib/serdes_pll.v"

module GTP_BIDIRECTIONAL_TEST #(
	parameter OSERDES_WIDTH = 8,
	parameter PRBSLFSR_WIDTH = OSERDES_WIDTH,
	parameter GTP_WIDTH = 16,
	parameter COUNTER_PICKOFF_RESET1 = 14,
	parameter COUNTER_PICKOFF_RESET2 = COUNTER_PICKOFF_RESET1 + 1,
	parameter COUNTER_PICKOFF_RESET3 = COUNTER_PICKOFF_RESET2 + 1,
	parameter COUNTER_PICKOFF_RESET4 = COUNTER_PICKOFF_RESET3 + 1
) (
	input SYSCLK_P, SYSCLK_N, // 200 MHz
	input Q0_CLK0_GTREFCLK_PAD_N_IN, Q0_CLK0_GTREFCLK_PAD_P_IN, // 125 MHz
	input SMA_MGT_RX_P, SMA_MGT_RX_N, SFP_MGT_RX_P, SFP_MGT_RX_N,
	output SMA_MGT_TX_P, SMA_MGT_TX_N, SFP_MGT_TX_P, SFP_MGT_TX_N,
	output USER_SMA_CLOCK_P, USER_SMA_CLOCK_N,
	output GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0
);
	wire sysclk;
	IBUFDS iclk (.I(SYSCLK_P), .IB(SYSCLK_N), .O(sysclk));
	wire raw_bit_clock, bit_clock, word_clock, sysclk_pll_locked;
	reg reset1_sysclk = 1'b1, reset2_sysclk = 1'b1, reset3_sysclk = 1'b1, reset4_sysclk = 1'b1;
	reg reset2_copy1_on_raw_bit_clock = 1'b1, reset3_copy1_on_raw_bit_clock = 1'b1, reset4_copy1_on_other_word_clock = 1'b1;
	reg reset2_copy2_on_raw_bit_clock = 1'b1, reset3_copy2_on_raw_bit_clock = 1'b1, reset4_copy2_on_other_word_clock = 1'b1;
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
	always @(posedge other_word_clock) begin
		reset4_copy2_on_other_word_clock <= reset4_copy1_on_other_word_clock;
		reset4_copy1_on_other_word_clock <= reset4_sysclk;
	end
	wire drp_clock_raw;
	MMCM_advanced #(
		.CLOCK1_PERIOD_NS(5.0), .D(4), .M(25), // Fvco = [600, 1440] MHz
		.CLKOUT0_DIVIDE(2), // 625 MHz (DDR yields 1250 MHz)
		.CLKOUT1_DIVIDE(8), //
		.CLKOUT2_DIVIDE(10), // 125 MHz for DRP clock for GTP
		.CLKOUT3_DIVIDE(1), //
		.CLKOUT4_DIVIDE(1), //
		.CLKOUT5_DIVIDE(1), //
		.CLKOUT6_DIVIDE(1)  //
			) mymmcm0 (
		.clock_in(sysclk), .reset(reset1_sysclk), .locked(sysclk_pll_locked),
		.clock0_out_p(raw_bit_clock), .clock0_out_n(), .clock1_out_p(), .clock1_out_n(),
		.clock2_out_p(drp_clock_raw), .clock2_out_n(), .clock3_out_p(), .clock3_out_n(),
		.clock4_out(), .clock5_out(), .clock6_out());
	wire [15:0] sma_txdata, sfp_txdata;
	wire [15:0] sma_rxdata, sfp_rxdata;
	wire other_word_clock;
	if (0) begin
		reg [26:0] counter = 0;
		always @(posedge word_clock) begin
			counter <= counter + 1'b1;
		end
		assign { GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = counter[26:23];
		assign sma_txdata = counter[15:0];
	end else if (0) begin
		wire [2*GTP_WIDTH-1:0] rand;
		prbs_wide #(.OUTPUT_WIDTH(2*GTP_WIDTH)) pw (.clock(word_clock), .reset(reset4_copy2_on_word_clock), .rand(rand));
		assign sfp_txdata = rand[2*GTP_WIDTH-1:GTP_WIDTH];
		assign sma_txdata = rand[GTP_WIDTH-1:0];
		assign { GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = rand[3:0];
	end else if (1) begin
		BUFMRCE #(.CE_TYPE("ASYNC")) mr (.I(raw_bit_clock), .CE(~reset3_copy2_on_raw_bit_clock), .O(bit_clock));
		wire [PRBSLFSR_WIDTH-1:0] rand;
		prbs_wide #(.OUTPUT_WIDTH(PRBSLFSR_WIDTH)) pw (.clock(other_word_clock), .reset(reset4_copy2_on_other_word_clock), .rand(rand));
		assign { GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = rand[3:0];
		wire bit;
		ocyrus_7series #(.DATA_WIDTH(OSERDES_WIDTH), .DDRSDR("DDR")) o7s (.bit_clock(bit_clock), .word_clock(other_word_clock), .reset(reset2_copy2_on_raw_bit_clock), .input_word(rand[7:0]), .output_bit(bit));
		OBUFDS olebuffy (.I(bit), .O(USER_SMA_CLOCK_P), .OB(USER_SMA_CLOCK_N));
		assign sfp_txdata = sma_rxdata;
		assign sma_txdata = sfp_rxdata;
	end
	gtp_pair mygtppair (.Q0_CLK0_GTREFCLK_PAD_N_IN(Q0_CLK0_GTREFCLK_PAD_N_IN), .Q0_CLK0_GTREFCLK_PAD_P_IN(Q0_CLK0_GTREFCLK_PAD_P_IN), .DRPCLK_IN(drp_clock_raw), .word_clock(word_clock), .sma_txdata(sma_txdata), .sfp_txdata(sfp_txdata), .sma_rxdata(sma_rxdata), .sfp_rxdata(sfp_rxdata), .sma_tx_p(SMA_MGT_TX_P), .sma_tx_n(SMA_MGT_TX_N), .sfp_tx_p(SFP_MGT_TX_P), .sfp_tx_n(SFP_MGT_TX_N), .sma_rx_p(SMA_MGT_RX_P), .sma_rx_n(SMA_MGT_RX_N), .sfp_rx_p(SFP_MGT_RX_P), .sfp_rx_n(SFP_MGT_RX_N));
endmodule

