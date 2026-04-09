// from https://stackoverflow.com/questions/37431914/ice40-icestorm-fpga-flow-bi-directional-io-pins
// last updated 2025-01-09 by mza

`define icestick

module top(
	input CLK,
	input DTRn, RTSn, RX, IR_RX,
	output DCDn, DSRn, CTSn, TX, IR_TX, IR_SD,
	output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
	output J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
	output J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10,
	output LED5, LED4, LED3, LED2,
	output reg LED1
);
	assign TX = RX; assign DCDn = 1'b1; assign DSRn = 1'b1; assign CTSn = 1'b1;
	assign IR_TX = IR_RX; assign IR_SD = 1'b1; // IR_SD = shut down
	assign J1_4 = 1'b0; assign J1_5 = 1'b0; assign J1_6 = 1'b0; assign J1_7 = 1'b0; assign J1_8 = 1'b0; assign J1_9 = 1'b0; assign J1_10 = 1'b0;
	assign J2_1 = 1'b0; assign J2_2 = 1'b0; assign J2_3 = 1'b0; assign J2_4 = 1'b0; assign J2_7 = 1'b0; assign J2_8 = 1'b0; assign J2_9 = 1'b0; assign J2_10 = 1'b0;
	assign J3_3 = 1'b0; assign J3_4 = 1'b0; assign J3_5 = 1'b0; assign J3_6 = 1'b0; assign J3_7 = 1'b0; assign J3_8 = 1'b0; assign J3_9 = 1'b0; assign J3_10 = 1'b0;
	assign LED4 = 1'b0; assign LED3 = 1'b0; assign LED2 = 1'b0; assign LED5 = 1'b0;
	wire din;
	reg dout = 0;
	reg dout_en = 0;
	SB_IO #(
	    .PIN_TYPE(6'b 1010_01),
	    .PULLUP(1'b 0)
	) my_inout (
	    .PACKAGE_PIN(J1_3),
	    .OUTPUT_ENABLE(dout_en),
	    .D_OUT_0(dout),
	    .D_IN_0(din)
	);
	always @(posedge CLK) begin
		if (din) begin
			LED1 <= 1;
			dout <= 1;
			dout_en <= 1;
		end else begin
			LED1 <= 0;
		end
	end
endmodule // top

