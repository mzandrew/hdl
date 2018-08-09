// written 2018-08-06 by mza
// last updated 2018-08-08 by mza

module mytop (input clock, output [5:1] LED, 
output [7:0] J1,
output [7:0] J2,
output [7:0] J3,
output sda_out,
output reg sda_dir,
input sda_in
);
	wire [6:0] i2c_address = 7'h27; // honeywell HIH6121 i2c humidity sensor
	reg scl;
//	assign J2[7] = sda_dir ? sda_out : 1'bz; // Warning: Yosys has only limited support for tri-state logic at the moment.
	assign J1 = data;
	assign J2[2] = scl;
	assign J2[7:4] = 0;
	assign J2[1:0] = 0;
	assign LED[5] = ~ack;
	assign LED[4] = error;
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
	reg error;
	reg [7:0] data;
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

				// send address word
				228 : sda_out <= i2c_address[6]; // byte[7]
				227 : scl <= 1;
				226 : scl <= 0;
				225 : sda_out <= i2c_address[5]; // byte[6]
				224 : scl <= 1;
				223 : scl <= 0;
				222 : sda_out <= i2c_address[4]; // byte[5]
				221 : scl <= 1;
				220 : scl <= 0;
				219 : sda_out <= i2c_address[3]; // byte[4]
				218 : scl <= 1;
				217 : scl <= 0;
				216 : sda_out <= i2c_address[2]; // byte[3]
				215 : scl <= 1;
				214 : scl <= 0;
				213 : sda_out <= i2c_address[1]; // byte[2]
				212 : scl <= 1;
				211 : scl <= 0;
				210 : sda_out <= i2c_address[0]; // byte[1]
				209 : scl <= 1;
				208 : scl <= 0;
				207 : sda_out <= 0; // byte[0] = 0; write
				206 : scl <= 1;
				205 : scl <= 0;

				// get ack
				199 : sda_dir <= 0; // input
				198 : scl <= 1;
				197 : ack <= sda_in; // ack
				196 : scl <= 0;
				195 : sda_dir <= 1; // output
				194 : if (ack==1) begin bit_counter <= 10; error <= 1; end

				// send stop
				190 : sda_out <= 1;
				189 : sda_out <= 0;
				188 : scl <= 1;
				187 : sda_out <= 1;

				// send start or repeated start
				179 : sda_out <= 1;
				178 : scl <= 1;
				177 : sda_out <= 0; // start condition
				176 : scl <= 0;

				// send address word
				169 : sda_out <= i2c_address[6]; // byte[7]
				168 : scl <= 1;
				167 : scl <= 0;
				166 : sda_out <= i2c_address[5]; // byte[6]
				165 : scl <= 1;
				164 : scl <= 0;
				163 : sda_out <= i2c_address[4]; // byte[5]
				162 : scl <= 1;
				161 : scl <= 0;
				160 : sda_out <= i2c_address[3]; // byte[4]
				159 : scl <= 1;
				158 : scl <= 0;
				157 : sda_out <= i2c_address[2]; // byte[3]
				156 : scl <= 1;
				155 : scl <= 0;
				154 : sda_out <= i2c_address[1]; // byte[2]
				153 : scl <= 1;
				152 : scl <= 0;
				151 : sda_out <= i2c_address[0]; // byte[1]
				150 : scl <= 1;
				149 : scl <= 0;
				148 : sda_out <= 1; // byte[0] = 1; read
				147 : scl <= 1;
				146 : scl <= 0;

				// get ack
				139 : sda_dir <= 0; // input
				138 : scl <= 1;
				137 : ack <= sda_in; // ack
				136 : scl <= 0;
				135 : sda_dir <= 1; // output
				134 : if (ack==1) begin bit_counter <= 10; error <= 1; end

				129 : sda_out <= 1;
				128 : sda_out <= 0;

				// get data word
				119 : sda_dir <= 0; // input
				119 : scl <= 1;
				118 : data[7] <= sda_in;
				117 : scl <= 0;
				116 : scl <= 1;
				115 : data[6] <= sda_in;
				114 : scl <= 0;
				113 : scl <= 1;
				112 : data[5] <= sda_in;
				111 : scl <= 0;
				110 : scl <= 1;
				109 : data[4] <= sda_in;
				108 : scl <= 0;
				107 : scl <= 1;
				106 : data[3] <= sda_in;
				105 : scl <= 0;
				104 : scl <= 1;
				103 : data[2] <= sda_in;
				102 : scl <= 0;
				101 : scl <= 1;
				100 : data[1] <= sda_in;
				099 : scl <= 0;
				098 : scl <= 1;
				097 : data[0] <= sda_in;
				096 : scl <= 0;
				// end of data word

				// send ack
				089 : sda_dir <= 1; // output
				088 : scl <= 1;
				087 : sda_out <= 0; // ack
				086 : scl <= 0;
				085 : sda_dir <= 0; // input

				// send stop
				009 : sda_out <= 1;
				008 : sda_out <= 0;
				007 : scl <= 1;
				006 : sda_out <= 1;

				001 : begin
					sda_dir <= 1;
					scl <= 1;
					sda_out <= 1;
				end
				default : ;
			endcase
			bit_counter--;
		end else begin
			bit_counter <= 250;
			error <= 0;
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
	assign TX = 1;
	//wire sda_dir_fake;
	//assign sda_dir_fake = 1;
	wire sda_dir;
	wire sda_in;
	wire sda_out;
	mytop mytop_instance (.clock(CLK), .LED(LED), .J1(J1), .J2(J2), .J3(J3),
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

