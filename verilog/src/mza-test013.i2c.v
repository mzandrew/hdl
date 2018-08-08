// written 2018-08-06 by mza
// last updated 2018-08-06 by mza

module mytop (input clock, output [5:1] LED, 
output [7:0] J2,
output [7:0] J3,
output sda_out,
output reg sda_dir,
input sda_in
);
	wire [6:0] i2c_address = 7'h27; // honeywell HIH6121 i2c humidity sensor
	reg scl;
//	assign J2[7] = sda_dir ? sda_out : 1'bz; // Warning: Yosys has only limited support for tri-state logic at the moment.
	assign J2[2] = scl;
	assign J2[7:4] = 0;
	assign J2[1:0] = 0;
	assign LED[5] = scl;
	assign LED[4] = ~ack;
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
	reg ack;
	always @(posedge i2c_clock) begin
		if (bit_counter>0) begin
			case(bit_counter)
				250 : begin
					sda_dir <= 1;
					scl <= 1;
					sda_out <= 1;
				end
				// send start or repeated start
				239 : sda_out <= 1;
				238 : scl <= 1;
				237 : sda_out <= 0; // start condition
				236 : scl <= 0;
				// beginning of data word
				228 : sda_out <= i2c_address[6]; // data[7]
				227 : scl <= 1;
				226 : scl <= 0;
				225 : sda_out <= i2c_address[5]; // data[6]
				224 : scl <= 1;
				223 : scl <= 0;
				222 : sda_out <= i2c_address[4]; // data[5]
				221 : scl <= 1;
				220 : scl <= 0;
				219 : sda_out <= i2c_address[3]; // data[4]
				218 : scl <= 1;
				217 : scl <= 0;
				216 : sda_out <= i2c_address[2]; // data[3]
				215 : scl <= 1;
				214 : scl <= 0;
				213 : sda_out <= i2c_address[1]; // data[2]
				212 : scl <= 1;
				211 : scl <= 0;
				210 : sda_out <= i2c_address[0]; // data[1]
				209 : scl <= 1;
				208 : scl <= 0;
				207 : sda_out <= 0; // data[0] = 0; write
				//207 : sda_out <= 1; // data[0] = 1; read
				206 : scl <= 1;
				// end of data word
				// get ack
				199 : scl <= 0;
				198 : sda_dir <= 0; // input
				197 : scl <= 1;
				196 : ack <= sda_in; // ack
				195 : scl <= 0;
				194 : sda_dir <= 1; // output
				// send stop
				190 : sda_out <= 1;
				189 : sda_out <= 0;
				188 : scl <= 1;
				187 : sda_out <= 1;
				1 : begin
					sda_dir <= 1;
					scl <= 1;
					sda_out <= 1;
				end
				default : ;
			endcase
			bit_counter--;
		end else begin
			bit_counter <= 250;
		end
	end
endmodule // mytop

module icestick (
input CLK,
output LED1, LED2, LED3, LED4, LED5,
output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
//inout J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
inout J2_4,
output J2_1, J2_2, J2_3, J2_7, J2_8, J2_9, J2_10,
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
	//wire sda_dir_fake;
	//assign sda_dir_fake = 1;
	wire sda_dir;
	wire sda_in;
	wire sda_out;
	mytop mytop_instance (.clock(CLK), .LED(LED), .J2(J2), .J3(J3),
		.sda_out(sda_out), .sda_in(sda_in), .sda_dir(sda_dir));
	SB_IO #(
		.PIN_TYPE(6'b 1010_01), // 1010 = output is tristated; 01 = input is normal
		.PULLUP(1'b 0)
	) my_i2c_data_pin (
		.PACKAGE_PIN(J2[3]),
		.OUTPUT_ENABLE(sda_dir),
//		.D_OUT_0(sda_out ? 1'b1 : 1'bz),
		.D_OUT_0(sda_out),
		.D_IN_0(sda_in)
	);
endmodule // icestick

