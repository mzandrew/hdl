`timescale 1ns / 1ps

// written 2022-11-16 by mza
// last updated 2022-11-22 by mza

module clock_out_test(
	input sysclk, // 125 MHz, comes from RTL8211 (ethernet) via 50 MHz osc
	output hdmi_tx_clk_p,
	output hdmi_tx_clk_n,
	inout hdmi_rx_scl,
	output hdmi_rx_sda
);
	assign hdmi_rx_scl = 0;
	assign hdmi_rx_sda = 0;
	wire clock;
	IBUFG clock_in (.I(sysclk), .O(clock));
	OBUFDS (.I(clock), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
endmodule

