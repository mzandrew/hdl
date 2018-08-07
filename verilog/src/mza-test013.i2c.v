// written 2018-08-06 by mza
// last updated 2018-08-06 by mza

module mytop (input clock, output [5:1] LED, 
output [7:0] J2,
output [7:0] J3,
output sda_out,
output reg sda_dir,
input sda_in
);
	wire [6:0] i2c_address = 7'd27; // honeywell HIH6121 i2c humidity sensor
	reg scl;
//	assign J2[7] = sda_dir ? sda_out : 1'bz; // Warning: Yosys has only limited support for tri-state logic at the moment.
	assign J2[6] = 0;
	assign J2[5] = scl;
	assign J2[4:0] = 0;
	assign LED[5] = scl;
	assign LED[4] = nack;
	assign LED[3] = sda_dir;
	assign LED[2] = sda_in;
	assign LED[1] = sda_out;
	assign J3[7:4] = 0;
	assign J3[3] = sda_dir;
	assign J3[2] = sda_in;
	assign J3[1] = sda_out;
	assign J3[0] = scl;
	reg [31:0] counter;
	always @(posedge clock) begin
		counter++;
	end
	wire i2c_clock;
	assign i2c_clock = counter[5];
//	assign scl = i2c_clock;
	reg [7:0] bit_counter;
	reg nack;
	always @(posedge i2c_clock) begin
		if (bit_counter>0) begin
			case(bit_counter)
				31 : begin
					sda_out <= 0;
				end
				29 : begin
					scl <= 0;
				end
				28 : begin
					sda_out <= i2c_address[6];
				end
				27 : begin
					scl <= 1;
				end
				26 : begin
					scl <= 0;
				end
				25 : begin
					sda_out <= i2c_address[5];
				end
				24 : begin
					scl <= 1;
				end
				23 : begin
					scl <= 0;
				end
				22 : begin
					sda_out <= i2c_address[4];
				end
				21 : begin
					scl <= 1;
				end
				20 : begin
					scl <= 0;
				end
				19 : begin
					sda_out <= i2c_address[3];
				end
				18 : begin
					scl <= 1;
				end
				17 : begin
					scl <= 0;
				end
				16 : begin
					sda_out <= i2c_address[2];
				end
				15 : begin
					scl <= 1;
				end
				14 : begin
					scl <= 0;
				end
				13 : begin
					sda_out <= i2c_address[1];
				end
				12 : begin
					scl <= 1;
				end
				11 : begin
					scl <= 0;
				end
				10 : begin
					sda_out <= i2c_address[0];
				end
				09 : begin
					scl <= 1;
				end
				08 : begin
					scl <= 0;
				end
				07 : begin
					sda_dir <= 0;
				end
				06 : begin
					scl <= 1;
				end
				05 : begin
					sda_out <= 0;
					nack <= sda_in;
				end
				04 : begin
					sda_dir <= 1;
				end
				03 : begin
					scl <= 1;
				end
				02 : begin
					scl <= 0;
				end
				01 : begin
					sda_out <= 1;
				end
				default : begin
					sda_dir <= 1;
					scl <= 1;
					sda_out <= 1;
				end
			endcase
			bit_counter--;
		end else begin
			bit_counter <= 32;
		end
	end
endmodule // mytop

module icestick (
input CLK,
output LED1, LED2, LED3, LED4, LED5,
output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
//inout J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
inout J2_10,
output J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9,
output J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10,
output DCDn, DSRn, CTSn, TX, IR_TX, IR_SD,
input DTRn, RTSn, RX, IR_RX
);
	wire [7:0] J1 = { J1_10, J1_9, J1_8, J1_7, J1_6, J1_5, J1_4, J1_3 };
	wire [7:0] J2 = { J2_10, J2_9, J2_8, J2_7, J2_4, J2_3, J2_2, J2_1 };
	wire [7:0] J3 = { J3_10, J3_9, J3_8, J3_7, J3_6, J3_5, J3_4, J3_3 };
	wire [5:1] LED = { LED5, LED4, LED3, LED2, LED1 };
	assign { DCDn, DSRn, CTSn } = 1;
	assign { IR_TX, IR_SD } = 0;
	assign J1 = 0;
	assign TX = 1;
	wire sda_dir;
	wire sda_in;
	wire sda_out;
	mytop mytop_instance (.clock(CLK), .LED(LED), .J2(J2), .J3(J3),
		.sda_out(sda_out), .sda_in(sda_in), .sda_dir(sda_dir));
	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) my_i2c_data_pin (
		.PACKAGE_PIN(J2[7]),
		.OUTPUT_ENABLE(sda_dir),
		.D_OUT_0(sda_out),
		.D_IN_0(sda_in)
	);
endmodule // icestick

