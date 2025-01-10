// from https://www.reddit.com/r/yosys/comments/7iue1l/estimating_critical_path_with_icetime/
// last updated 2025-01-09 by mza

// ddr_io.v
// Read DDR Input to a register and write to DDR output

`define icestick

module mytop (
	input clock,
	input ddr_in,
	output ddr_out
);
    reg [1:0] in_buffer;
    reg [1:0] out_buffer;
    initial begin
        in_buffer = 0;
        out_buffer = 0;
    end
    // Differential input, DDR data
    defparam differential_input.PIN_TYPE = 6'b000000 ; // {NO_OUTPUT, PIN_INPUT_DDR}
    defparam differential_input.IO_STANDARD = "SB_LVDS_INPUT" ;
    SB_IO differential_input (
        .PACKAGE_PIN(ddr_in),
        .LATCH_INPUT_VALUE ( ),
        .CLOCK_ENABLE (1'b1),
        .INPUT_CLK (clock),
        .OUTPUT_CLK ( ),
        .OUTPUT_ENABLE ( ),
        .D_OUT_0 ( ),
        .D_OUT_1 ( ),
        .D_IN_0 (in_buffer[0]),
        .D_IN_1 (in_buffer[1])
    );
    // Differential output, DDR data
    defparam differential_output.PIN_TYPE = 6'b010000 ; // {PIN_OUTPUT_DDR}
    defparam differential_output.IO_STANDARD = "SB_LVCMOS" ;
    SB_IO differential_output (
        .PACKAGE_PIN(ddr_out),
        .LATCH_INPUT_VALUE ( ),
        .CLOCK_ENABLE (1'b1),
        .INPUT_CLK (clock),
        .OUTPUT_CLK ( ),
        .OUTPUT_ENABLE ( ),
        .D_OUT_0 (out_buffer[0]),
        .D_OUT_1 (out_buffer[1]),
        .D_IN_0 ( ),
        .D_IN_1 ( )
    );
    always @(posedge clock) begin
        out_buffer <= in_buffer;
    end
endmodule

module top (
	input CLK,
	input DTRn, RTSn, RX, IR_RX,
	output DCDn, DSRn, CTSn, TX, IR_TX, IR_SD,
	output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
	output J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
	output J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10,
	output LED5, LED1, LED2, LED3, LED4
);
	assign DCDn = 1'b1; assign DSRn = 1'b1; assign CTSn = 1'b1;
	assign IR_TX = IR_RX; assign IR_SD = 1'b1; // IR_SD = shut down
	assign J1_3 = 1'b0; assign J1_4 = 1'b0; assign J1_5 = 1'b0; assign J1_6 = 1'b0; assign J1_7 = 1'b0; assign J1_8 = 1'b0; assign J1_9 = 1'b0; assign J1_10 = 1'b0;
	assign J2_1 = 1'b0; assign J2_2 = 1'b0; assign J2_3 = 1'b0; assign J2_4 = 1'b0; assign J2_7 = 1'b0; assign J2_8 = 1'b0; assign J2_9 = 1'b0; assign J2_10 = 1'b0;
	assign J3_3 = 1'b0; assign J3_4 = 1'b0; assign J3_5 = 1'b0; assign J3_6 = 1'b0; assign J3_7 = 1'b0; assign J3_8 = 1'b0; assign J3_9 = 1'b0; assign J3_10 = 1'b0;
	assign LED5 = 1'b0; assign LED4 = 1'b0; assign LED3 = 1'b0; assign LED2 = 1'b0; assign LED1 = 1'b0;
	mytop my_top_instance (.clock(CLK), .ddr_in(RX), .ddr_out(TX));
endmodule

