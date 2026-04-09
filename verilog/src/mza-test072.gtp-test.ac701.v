`timescale 1ns / 1ps

// written 2025-03-20 by mza
// based on mza-test071.prbs-lfsr.ac701.v
// last updated 2025-03-22 by mza

// cd /opt/Xilinx/Vivado/2023.2/data/xicom/cable_drivers/lin64/install_script/install_drivers; sudo ./install_drivers

//when it complains that you didn't save a dcp file, you must do this from the tcl_console:  "synth_ip [get_ips x0y3_sma] -force"
//mkdir -p ~/build/hdl/vivado-projects/ac701-gtp-try10/ac701-gtp-try10.srcs/utils_1/imports/synth_1
//cp -a ~/ac701-try9.gen/sources_1/ip/x0y3_sma/x0y3_sma.dcp ~/build/hdl/vivado-projects/ac701-gtp-try10/ac701-gtp-try10.srcs/utils_1/imports/synth_1/GTP_TEST.dcp
// but then it dumps files in ~/ac701-try9.gen and relies on them and regenerates them automatically if they're removed so you have to manually edit the xci file and get rid of all the "../../../../" in get_directory and OUTPUTDIR
//cp -a ./ac701-gtp-try10.cache/ip/2023.1/a/c/ac24d87c486f3a68/x0y3_sma.dcp ~/build/hdl/vivado-projects/ac701-gtp-try10/ac701-gtp-try10.srcs/utils_1/imports/synth_1/GTP_TEST.dcp
//cp -a ./ac701-gtp-try10/ac701-try9.gen/sources_1/ip/x0y3_sma/x0y3_sma.dcp ~/build/hdl/vivado-projects/ac701-gtp-try10/ac701-gtp-try10.srcs/utils_1/imports/synth_1/GTP_TEST.dcp

`include "lib/generic.v"
`include "lib/plldcm.v"
`include "lib/prbs.v"
`include "lib/serdes_pll.v"

module GTP_TEST #(
	parameter GTP_WIDTH = 16,
	parameter COUNTER_PICKOFF_RESET1 = 14,
	parameter COUNTER_PICKOFF_RESET2 = COUNTER_PICKOFF_RESET1 + 1,
	parameter COUNTER_PICKOFF_RESET3 = COUNTER_PICKOFF_RESET2 + 1,
	parameter COUNTER_PICKOFF_RESET4 = COUNTER_PICKOFF_RESET3 + 1
) (
	input SYSCLK_P, SYSCLK_N, // 200 MHz
	input Q0_CLK0_GTREFCLK_PAD_N_IN, Q0_CLK0_GTREFCLK_PAD_P_IN, // 125 MHz
	output SMA_MGT_TX_P, SMA_MGT_TX_N,
	output SFP_MGT_TX_P, SFP_MGT_TX_N,
	output GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0
);
	wire sysclk;
	IBUFDS iclk (.I(SYSCLK_P), .IB(SYSCLK_N), .O(sysclk));
	wire word_clock, sysclk_pll_locked;
	reg reset1_sysclk = 1'b1, reset4_sysclk = 1'b1;
	reg [COUNTER_PICKOFF_RESET4:0] counter = 0;
	always @(posedge sysclk) begin
		counter <= counter + 1'b1;
		if (counter[COUNTER_PICKOFF_RESET1]) begin reset1_sysclk <= 0; end
		if (counter[COUNTER_PICKOFF_RESET4]) begin reset4_sysclk <= 0; end
	end
	reg	reset4_copy1_on_word_clock = 1'b1, reset4_copy2_on_word_clock = 1'b1;
	always @(posedge word_clock) begin
		reset4_copy2_on_word_clock <= reset4_copy1_on_word_clock;
		reset4_copy1_on_word_clock <= reset4_sysclk;
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
		.clock0_out_p(), .clock0_out_n(), .clock1_out_p(), .clock1_out_n(),
		.clock2_out_p(drp_clock_raw), .clock2_out_n(), .clock3_out_p(), .clock3_out_n(),
		.clock4_out(), .clock5_out(), .clock6_out());
	wire [15:0] sma_txdata, sfp_txdata;
	if (0) begin
		reg [26:0] counter = 0;
		always @(posedge word_clock) begin
			counter <= counter + 1'b1;
		end
		assign { GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = counter[26:23];
		assign sma_txdata = counter[15:0];
	end else if (1) begin
		wire [2*GTP_WIDTH-1:0] rand;
		prbs_wide #(.OUTPUT_WIDTH(2*GTP_WIDTH)) pw (.clock(word_clock), .reset(reset4_copy2_on_word_clock), .rand(rand));
		assign sfp_txdata = rand[2*GTP_WIDTH-1:GTP_WIDTH];
		assign sma_txdata = rand[GTP_WIDTH-1:0];
		assign { GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = rand[3:0];
	end
	x0y3_sma_exdes mygtp (.Q0_CLK0_GTREFCLK_PAD_N_IN(Q0_CLK0_GTREFCLK_PAD_N_IN), .Q0_CLK0_GTREFCLK_PAD_P_IN(Q0_CLK0_GTREFCLK_PAD_P_IN), .DRPCLK_IN(drp_clock_raw), .sma_txdata(sma_txdata), .sma_txusrclk2(word_clock), .sfp_txdata(sfp_txdata), .sfp_txusrclk2(), .SMA_TX_P(SMA_MGT_TX_P), .SMA_TX_N(SMA_MGT_TX_N), .SFP_TX_P(SFP_MGT_TX_P), .SFP_TX_N(SFP_MGT_TX_N));
endmodule

