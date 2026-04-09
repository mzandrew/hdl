// borrowed/stolen from rot.v example project
// last updated 2025-01-09 by mza

// takes 31 seconds to compile on a raspberry pi
// takes 3 seconds to program

`define icestick

module top (
	input CLK,
	input DTRn, RTSn, RX, IR_RX,
	output DCDn, DSRn, CTSn, TX, IR_TX, IR_SD,
	output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
	output J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
	output J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10,
	output LED5, LED4, LED3, LED2, LED1
);
	assign TX = RX; assign DCDn = 1'b1; assign DSRn = 1'b1; assign CTSn = 1'b1;
	assign IR_TX = IR_RX; assign IR_SD = 1'b1; // IR_SD = shut down
	assign J1_3 = 1'b0; assign J1_4 = 1'b0; assign J1_5 = 1'b0; assign J1_6 = 1'b0; assign J1_7 = 1'b0; assign J1_8 = 1'b0; assign J1_9 = 1'b0; assign J1_10 = 1'b0;
	assign J2_1 = 1'b0; assign J2_2 = 1'b0; assign J2_3 = 1'b0; assign J2_4 = 1'b0; assign J2_7 = 1'b0; assign J2_8 = 1'b0; assign J2_9 = 1'b0; assign J2_10 = 1'b0;
	assign J3_3 = 1'b0; assign J3_4 = 1'b0; assign J3_5 = 1'b0; assign J3_6 = 1'b0; assign J3_7 = 1'b0; assign J3_8 = 1'b0; assign J3_9 = 1'b0; assign J3_10 = 1'b0;
   reg ready = 0;
   reg [23:0] divider = 0;
   reg [3:0] rot = 0;
   always @(posedge CLK) begin
      if (ready) begin
           if (divider == 0400000) begin
                divider <= 0;
                rot <= {rot[2:0], rot[3]};
             end
           else 
             divider <= divider + 1;
        end else begin
           ready <= 1;
           rot <= 4'b0001;
           divider <= 0;
        end
   end
   assign LED1 = rot[0];
   assign LED2 = rot[1];
   assign LED3 = rot[2];
   assign LED4 = rot[3];
   assign LED5 = 1;
endmodule // top

