`timescale 1ns / 1ps

// written 2022-11-16 by mza
// last updated 2022-12-08 by mza

module clock_out_test #(
	parameter clock_select = 0
) (
//	input sysclk, // 125 MHz, comes from RTL8211 (ethernet) via 50 MHz osc
	input [5:4] ja, // 127.216 MHz, comes from PMODA
	input hdmi_rx_clk_p, // dummy for 1.27216 GHz clock from gulfstream
	input hdmi_rx_cec, // dummy data
	output rpio_03_r, // dummy output
	output hdmi_tx_clk_p,
	output hdmi_tx_clk_n,
	output rpio_02_r,
	inout hdmi_rx_scl,
	output hdmi_rx_sda
);
	assign hdmi_rx_scl = 0;
	assign hdmi_rx_sda = 0;
	wire clock;
	if (clock_select) begin
		IBUFG clock_in (.I(sysclk), .O(clock));
	end else begin
		IBUFGDS clock_in (.I(ja[4]), .IB(ja[5]), .O(clock));
	end
	OBUFDS (.I(clock), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	assign rpio_02_r = clock;
	reg thing = 0;
	always @(posedge hdmi_rx_clk_p) begin
		thing <= hdmi_rx_cec;
	end
	assign rpio_03_r = thing;
endmodule

