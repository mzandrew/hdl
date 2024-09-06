// written 2018-08-06 by mza
// based on mza-test013.i2c.v
// last updated 2024-09-06 by mza

`ifndef I2C_LIB
`define I2C_LIB

module i2c_write_value_to_address #(
	parameter CLOCK_FREQUENCY_IN_HZ = 100000000,
	parameter DESIRED_I2C_FREQUENCY_IN_HZ = 100000,
	parameter CLOCK_DIVIDE_RATIO = CLOCK_FREQUENCY_IN_HZ/DESIRED_I2C_FREQUENCY_IN_HZ, // 1000
	parameter DIVIDE_COUNTER_PICKOFF = $clog2(CLOCK_DIVIDE_RATIO) // 10
) (
	input clock,
	input [6:0] address,
	input [7:0] value,
	output reg scl = 1'bz,
	output reg sda_out = 1,
	output reg sda_dir = 0,
	input sda_in,
	input start_transfer,
	output reg busy = 0,
	output reg nack = 0,
	output reg error = 0,
	output reg transfer_complete = 1
);
	reg i2c_strobe = 0;
	reg [7:0] bit_counter = 0;
	reg [DIVIDE_COUNTER_PICKOFF:0] divide_counter = 1;
	always @(posedge clock) begin
		i2c_strobe <= 0;
		if (divide_counter==CLOCK_DIVIDE_RATIO) begin
			divide_counter <= 1;
			i2c_strobe <= 1;
		end else begin
			divide_counter <= divide_counter + 1'b1;
		end
	end
	localparam SHORT_GAP = 5;
	localparam MEDIUM_GAP = 10;
	localparam LONG_GAP = 20;
	localparam ENDING = 1 + LONG_GAP; // duration 1; was 1
	localparam SEND_STOP = ENDING + 5 + MEDIUM_GAP; // duration 5; was 9
	localparam GET_SECOND_NACK = SEND_STOP + 12 + SHORT_GAP; // duration 12; was 27
	localparam PUT_OUT_8BIT_DATA = GET_SECOND_NACK + 24 + SHORT_GAP; // duration 24; was 51
	localparam GET_FIRST_NACK = PUT_OUT_8BIT_DATA + 12 + LONG_GAP; // duration 12; was 124
	localparam PUT_OUT_WRITE_OR_READ = GET_FIRST_NACK + 6 + SHORT_GAP; // duration 6; was 130
	localparam PUT_OUT_7BIT_ADDRESS = PUT_OUT_WRITE_OR_READ + 21 + SHORT_GAP; // duration 21; was 151
	localparam SEND_START = PUT_OUT_7BIT_ADDRESS + 2 + MEDIUM_GAP; // duration 2; was 157
	localparam BEGINNING = SEND_START + 5 + LONG_GAP; // duration 5; was 160
	always @(posedge clock) begin
		if (bit_counter>0) begin
			if (i2c_strobe) begin
				bit_counter <= bit_counter - 1'b1;
				case(bit_counter)
					BEGINNING - 0 : begin sda_dir <= 1; scl <= 1'bz; sda_out <= 1; end
					// send start or repeated start
					SEND_START - 0 : sda_out <= 0; // this 1->0 transition of sda (while scl=1'bz) is the start condition
					SEND_START - 1 : scl <= 0;
					// send address word
					PUT_OUT_7BIT_ADDRESS -  0 : sda_out <= address[6]; // byte[7]
					PUT_OUT_7BIT_ADDRESS -  1 : scl <= 1'bz;
					PUT_OUT_7BIT_ADDRESS -  2 : scl <= 0;
					PUT_OUT_7BIT_ADDRESS -  3 : sda_out <= address[5]; // byte[6]
					PUT_OUT_7BIT_ADDRESS -  4 : scl <= 1'bz;
					PUT_OUT_7BIT_ADDRESS -  5 : scl <= 0;
					PUT_OUT_7BIT_ADDRESS -  6 : sda_out <= address[4]; // byte[5]
					PUT_OUT_7BIT_ADDRESS -  7 : scl <= 1'bz;
					PUT_OUT_7BIT_ADDRESS -  8 : scl <= 0;
					PUT_OUT_7BIT_ADDRESS -  9 : sda_out <= address[3]; // byte[4]
					PUT_OUT_7BIT_ADDRESS - 10 : scl <= 1'bz;
					PUT_OUT_7BIT_ADDRESS - 11 : scl <= 0;
					PUT_OUT_7BIT_ADDRESS - 12 : sda_out <= address[2]; // byte[3]
					PUT_OUT_7BIT_ADDRESS - 13 : scl <= 1'bz;
					PUT_OUT_7BIT_ADDRESS - 14 : scl <= 0;
					PUT_OUT_7BIT_ADDRESS - 15 : sda_out <= address[1]; // byte[2]
					PUT_OUT_7BIT_ADDRESS - 16 : scl <= 1'bz;
					PUT_OUT_7BIT_ADDRESS - 17 : scl <= 0;
					PUT_OUT_7BIT_ADDRESS - 18 : sda_out <= address[0]; // byte[1]
					PUT_OUT_7BIT_ADDRESS - 19 : scl <= 1'bz;
					PUT_OUT_7BIT_ADDRESS - 20 : scl <= 0;
					// send write command
					PUT_OUT_WRITE_OR_READ - 0 : sda_out <= 0; // byte[0] = 0; write
					PUT_OUT_WRITE_OR_READ - 4 : scl <= 1'bz;
					PUT_OUT_WRITE_OR_READ - 5 : scl <= 0;
					// get nack
					GET_FIRST_NACK -  0 : sda_dir <= 0; // input
					GET_FIRST_NACK -  1 : sda_out <= 0; // set neutral value for after we change sda direction again
					GET_FIRST_NACK -  6 : scl <= 1'bz;
					GET_FIRST_NACK -  7 : nack <= sda_in; // nack
					GET_FIRST_NACK -  8 : begin scl <= 0; sda_dir <= 1; end // drop scl and change sda direction at same time
					GET_FIRST_NACK - 11 : if (nack) begin error <= 1; bit_counter <= SEND_STOP; end
					// send value
					PUT_OUT_8BIT_DATA -  0 : sda_out <= value[7]; // byte[7]
					PUT_OUT_8BIT_DATA -  1 : scl <= 1'bz;
					PUT_OUT_8BIT_DATA -  2 : scl <= 0;
					PUT_OUT_8BIT_DATA -  3 : sda_out <= value[6]; // byte[6]
					PUT_OUT_8BIT_DATA -  4 : scl <= 1'bz;
					PUT_OUT_8BIT_DATA -  5 : scl <= 0;
					PUT_OUT_8BIT_DATA -  6 : sda_out <= value[5]; // byte[5]
					PUT_OUT_8BIT_DATA -  7 : scl <= 1'bz;
					PUT_OUT_8BIT_DATA -  8 : scl <= 0;
					PUT_OUT_8BIT_DATA -  9 : sda_out <= value[4]; // byte[4]
					PUT_OUT_8BIT_DATA - 10 : scl <= 1'bz;
					PUT_OUT_8BIT_DATA - 11 : scl <= 0;
					PUT_OUT_8BIT_DATA - 12 : sda_out <= value[3]; // byte[3]
					PUT_OUT_8BIT_DATA - 13 : scl <= 1'bz;
					PUT_OUT_8BIT_DATA - 14 : scl <= 0;
					PUT_OUT_8BIT_DATA - 15 : sda_out <= value[2]; // byte[2]
					PUT_OUT_8BIT_DATA - 16 : scl <= 1'bz;
					PUT_OUT_8BIT_DATA - 17 : scl <= 0;
					PUT_OUT_8BIT_DATA - 18 : sda_out <= value[1]; // byte[1]
					PUT_OUT_8BIT_DATA - 19 : scl <= 1'bz;
					PUT_OUT_8BIT_DATA - 20 : scl <= 0;
					PUT_OUT_8BIT_DATA - 21 : sda_out <= value[0]; // byte[0]
					PUT_OUT_8BIT_DATA - 22 : scl <= 1'bz;
					PUT_OUT_8BIT_DATA - 23 : scl <= 0;
					// get nack
					GET_SECOND_NACK -  0 : sda_dir <= 0; // input
					GET_SECOND_NACK -  1 : sda_out <= 0; // set neutral value for after we change sda direction again
					GET_SECOND_NACK -  6 : scl <= 1'bz;
					GET_SECOND_NACK -  7 : nack <= sda_in; // nack
					GET_SECOND_NACK -  8 : begin scl <= 0; sda_dir <= 1; end // drop scl and change sda direction at same time
					GET_SECOND_NACK - 11 : if (nack) begin error <= 1; bit_counter <= SEND_STOP; end
					// send stop
					SEND_STOP - 0 : begin sda_out <= 0; sda_dir <= 1; end // output
					SEND_STOP - 3 : scl <= 1'bz;
					SEND_STOP - 4 : sda_out <= 1; // this 0->1 transition of sda (while scl=1'bz) is the stop condition
					ENDING - 0 : begin sda_dir <= 1; scl <= 1'bz; sda_out <= 1; error <= 0; end
					default : ; // this must remain empty as there are gaps in the above bit_counter cases
				endcase
			end
		end else begin
			if (start_transfer) begin
				bit_counter <= BEGINNING;
				busy <= 1;
				transfer_complete <= 0;
			end else begin
				busy <= 0;
				transfer_complete <= 1;
			end
		end
	end
endmodule

module i2c_write_value_to_address_tb;
	reg clock = 0;
	reg [6:0] address = 7'h01; // { 3pins=3'b000, SRCregister=4'd1 }
	wire scl, sda_out, sda_dir, busy, nack, error;
	reg sda_in = 1;
	reg start_transfer = 0;
	wire transfer_complete;
	reg [7:0] value = 0;
	i2c_write_value_to_address #(.CLOCK_DIVIDE_RATIO(4)) thing (.clock(clock), .address(address), .value(value), .scl(scl), .sda_out(sda_out), .sda_dir(sda_dir), .busy(busy), .nack(nack), .error(error), .sda_in(sda_in), .start_transfer(start_transfer), .transfer_complete(transfer_complete));
	initial begin
		#100;
		sda_in <= 1;
		start_transfer <= 1; #4; start_transfer <= 0;
		#2000;
		sda_in <= 0;
		start_transfer <= 1; #4; start_transfer <= 0;
		#2000;
		sda_in <= 0;
		value = 8'ha5;
		start_transfer <= 1; #4; start_transfer <= 0;
		#4000;
		$finish;
	end
	always begin
		clock <= ~clock;
		#2;
	end
endmodule

//i2c_poll_address_for_nack #(.CLOCK_FREQUENCY_IN_HZ(250000000), .DESIRED_I2C_FREQUENCY_IN_HZ(100000)) thing (.clock(clock), .address(address), .scl(scl), .sda_out(sda_out), .sda_dir(sda_dir), .busy(busy), .nack(nack), .error(error), .sda_in(sda_in), .start_transfer(start_transfer), .transfer_complete(transfer_complete));
module i2c_poll_address_for_nack #(
	parameter CLOCK_FREQUENCY_IN_HZ = 100000000,
	parameter DESIRED_I2C_FREQUENCY_IN_HZ = 100000,
	parameter CLOCK_DIVIDE_RATIO = CLOCK_FREQUENCY_IN_HZ/DESIRED_I2C_FREQUENCY_IN_HZ, // 1000
	parameter DIVIDE_COUNTER_PICKOFF = $clog2(CLOCK_DIVIDE_RATIO) // 10
) (
	input clock,
	input [6:0] address,
	output reg scl = 0,
	output reg sda_out = 0,
	output reg sda_dir = 0,
	input sda_in,
	input start_transfer,
	output reg busy = 0,
	output reg nack = 0,
	output reg error = 0,
	output reg transfer_complete = 0
);
	reg i2c_strobe = 0;
	reg [5:0] bit_counter = 0;
	reg [DIVIDE_COUNTER_PICKOFF:0] divide_counter = 1;
	always @(posedge clock) begin
		i2c_strobe <= 0;
		if (divide_counter==CLOCK_DIVIDE_RATIO) begin
			divide_counter <= 1;
			i2c_strobe <= 1;
		end else begin
			divide_counter <= divide_counter + 1'b1;
		end
	end
	always @(posedge clock) begin
		if (bit_counter>0) begin
			if (i2c_strobe) begin
				case(bit_counter)
					060 : begin
						sda_dir <= 1;
						scl <= 1;
						sda_out <= 1;
					end
					// send start or repeated start
					057 : sda_out <= 0; // start condition
					056 : scl <= 0;
					// send address word
					051 : sda_out <= address[6]; // byte[7]
					050 : scl <= 1;
					049 : scl <= 0;
					048 : sda_out <= address[5]; // byte[6]
					047 : scl <= 1;
					046 : scl <= 0;
					045 : sda_out <= address[4]; // byte[5]
					044 : scl <= 1;
					043 : scl <= 0;
					042 : sda_out <= address[3]; // byte[4]
					041 : scl <= 1;
					040 : scl <= 0;
					039 : sda_out <= address[2]; // byte[3]
					038 : scl <= 1;
					037 : scl <= 0;
					036 : sda_out <= address[1]; // byte[2]
					035 : scl <= 1;
					034 : scl <= 0;
					033 : sda_out <= address[0]; // byte[1]
					032 : scl <= 1;
					031 : scl <= 0;
					// send write command
					030 : sda_out <= 0; // byte[0] = 0; write
					026 : scl <= 1;
					025 : scl <= 0;
					// get nack
					020 : sda_dir <= 0; // input
					018 : scl <= 1;
					017 : nack <= sda_in; // nack
					016 : scl <= 0;
					014 : sda_dir <= 1; // output
					013 : if (nack) begin error <= 1; bit_counter <= 10; end else begin error <= 0; end
					// send stop
					009 : sda_dir <= 1; // output
					008 : sda_out <= 1;
					007 : sda_out <= 0;
					006 : scl <= 1;
					005 : sda_out <= 1;
					001 : begin
						sda_dir <= 1;
						scl <= 1;
						sda_out <= 1;
					end
					default : ;
				endcase
				bit_counter <= bit_counter - 1'b1;
			end
		end else begin
			if (start_transfer) begin
				bit_counter <= 60;
				busy <= 1;
				transfer_complete <= 0;
			end else begin
				busy <= 0;
				transfer_complete <= 1;
			end
		end
	end
endmodule

module i2c_poll_address_for_nack_tb;
	reg clock = 0;
	reg [6:0] address = 7'h01; // { 3pins=3'b000, SRCregister=4'd1 }
	wire scl, sda_out, sda_dir, busy, nack, error;
	reg sda_in = 1;
	reg start_transfer = 0;
	wire transfer_complete;
	i2c_poll_address_for_nack #(.CLOCK_DIVIDE_RATIO(4)) thing (.clock(clock), .address(address), .scl(scl), .sda_out(sda_out), .sda_dir(sda_dir), .busy(busy), .nack(nack), .error(error), .sda_in(sda_in), .start_transfer(start_transfer), .transfer_complete(transfer_complete));
	initial begin
		#100;
		sda_in <= 1;
		start_transfer <= 1; #4; start_transfer <= 0;
		#2000;
		sda_in <= 0;
		start_transfer <= 1; #4; start_transfer <= 0;
		#2000;
		$finish;
	end
	always begin
		clock <= ~clock;
		#2;
	end
endmodule

//module i2c_send_single_byte #(parameter number_of_bytes=1, ) (input [6:0] address);
//input read_not_write, 
module i2c_send_one_byte_and_read_one_plus_four_bytes_back (
	input clock,
	input [6:0] address,
	output reg scl = 0,
	output reg sda_out = 0,
	output reg sda_dir = 0,
	input sda_in,
	input start_transfer,
	output reg busy = 0,
	output reg ack = 0,
	output reg error = 0,
	output reg [7:0] byte_a = 0,
	output reg [7:0] byte_b = 0,
	output reg [7:0] byte_c = 0,
	output reg [7:0] byte_d = 0
);
	reg [8:0] bit_counter = 0;
	reg [7:0] byte [3:0];
	reg [7:0] data = 0;
	always @(posedge clock) begin
		if (bit_counter>0) begin
			case(bit_counter)
				300 : begin
					sda_dir <= 1;
					scl <= 1;
					sda_out <= 1;
				end

				// send start or repeated start
				289 : sda_out <= 1;
				288 : scl <= 1;
				287 : sda_out <= 0; // start condition
				286 : scl <= 0;

				// send address word
				278 : sda_out <= address[6]; // byte[7]
				277 : scl <= 1;
				276 : scl <= 0;
				275 : sda_out <= address[5]; // byte[6]
				274 : scl <= 1;
				273 : scl <= 0;
				272 : sda_out <= address[4]; // byte[5]
				271 : scl <= 1;
				270 : scl <= 0;
				269 : sda_out <= address[3]; // byte[4]
				268 : scl <= 1;
				267 : scl <= 0;
				266 : sda_out <= address[2]; // byte[3]
				265 : scl <= 1;
				264 : scl <= 0;
				263 : sda_out <= address[1]; // byte[2]
				262 : scl <= 1;
				261 : scl <= 0;
				260 : sda_out <= address[0]; // byte[1]
				259 : scl <= 1;
				258 : scl <= 0;
				257 : sda_out <= 0; // byte[0] = 0; write
				256 : scl <= 1;
				255 : scl <= 0;

				// get ack
				249 : sda_dir <= 0; // input
				248 : scl <= 1;
				247 : ack <= sda_in; // ack
				246 : scl <= 0;
				245 : sda_dir <= 1; // output
				244 : if (ack==1) begin bit_counter <= 10; error <= 1; end else begin error <= 0; end

				// send stop
				230 : sda_out <= 1;
				239 : sda_out <= 0;
				238 : scl <= 1;
				237 : sda_out <= 1;

				// send start or repeated start
				229 : sda_out <= 1;
				228 : scl <= 1;
				227 : sda_out <= 0; // start condition
				226 : scl <= 0;

				// send address word
				219 : sda_out <= address[6]; // byte[7]
				218 : scl <= 1;
				217 : scl <= 0;
				216 : sda_out <= address[5]; // byte[6]
				215 : scl <= 1;
				214 : scl <= 0;
				213 : sda_out <= address[4]; // byte[5]
				212 : scl <= 1;
				211 : scl <= 0;
				210 : sda_out <= address[3]; // byte[4]
				209 : scl <= 1;
				208 : scl <= 0;
				207 : sda_out <= address[2]; // byte[3]
				206 : scl <= 1;
				205 : scl <= 0;
				204 : sda_out <= address[1]; // byte[2]
				203 : scl <= 1;
				202 : scl <= 0;
				201 : sda_out <= address[0]; // byte[1]
				200 : scl <= 1;
				199 : scl <= 0;
				198 : sda_out <= 1; // byte[0] = 1; read
				197 : scl <= 1;
				196 : scl <= 0;

				// get ack
				189 : sda_dir <= 0; // input
				188 : scl <= 1;
				187 : ack <= sda_in; // ack
				186 : scl <= 0;
				185 : sda_dir <= 1; // output
				184 : if (ack==1) begin bit_counter <= 10; error <= 1; end else begin error <= 0; end

				179 : sda_out <= 1;
				178 : sda_out <= 0;

				// get data word
				169 : sda_dir <= 0; // input
				168 : scl <= 1;
				167 : data[7] <= sda_in;
				166 : scl <= 0;
				165 : scl <= 1;
				164 : data[6] <= sda_in;
				163 : scl <= 0;
				162 : scl <= 1;
				161 : data[5] <= sda_in;
				160 : scl <= 0;
				159 : scl <= 1;
				158 : data[4] <= sda_in;
				157 : scl <= 0;
				156 : scl <= 1;
				155 : data[3] <= sda_in;
				154 : scl <= 0;
				153 : scl <= 1;
				152 : data[2] <= sda_in;
				151 : scl <= 0;
				150 : scl <= 1;
				149 : data[1] <= sda_in;
				148 : scl <= 0;
				147 : scl <= 1;
				146 : data[0] <= sda_in;
				145 : scl <= 0;
				// end of data word
				144 : byte_a <= data;

				// send ack
				139 : sda_dir <= 1; // output
				138 : sda_out <= 0; // ack
				137 : scl <= 1;
				136 : scl <= 0;

				// get data word
				129 : sda_dir <= 0; // input
				128 : scl <= 1;
				127 : data[7] <= sda_in;
				126 : scl <= 0;
				125 : scl <= 1;
				124 : data[6] <= sda_in;
				123 : scl <= 0;
				122 : scl <= 1;
				121 : data[5] <= sda_in;
				120 : scl <= 0;
				119 : scl <= 1;
				118 : data[4] <= sda_in;
				117 : scl <= 0;
				116 : scl <= 1;
				115 : data[3] <= sda_in;
				114 : scl <= 0;
				113 : scl <= 1;
				112 : data[2] <= sda_in;
				111 : scl <= 0;
				110 : scl <= 1;
				109 : data[1] <= sda_in;
				108 : scl <= 0;
				107 : scl <= 1;
				106 : data[0] <= sda_in;
				105 : scl <= 0;
				// end of data word
				104 : byte_b <= data;

				// send ack
				099 : sda_dir <= 1; // output
				098 : sda_out <= 0; // ack
				097 : scl <= 1;
				096 : scl <= 0;

				// get data word
				089 : sda_dir <= 0; // input
				088 : scl <= 1;
				087 : data[7] <= sda_in;
				086 : scl <= 0;
				085 : scl <= 1;
				084 : data[6] <= sda_in;
				083 : scl <= 0;
				082 : scl <= 1;
				081 : data[5] <= sda_in;
				080 : scl <= 0;
				079 : scl <= 1;
				078 : data[4] <= sda_in;
				077 : scl <= 0;
				076 : scl <= 1;
				075 : data[3] <= sda_in;
				074 : scl <= 0;
				073 : scl <= 1;
				072 : data[2] <= sda_in;
				071 : scl <= 0;
				070 : scl <= 1;
				069 : data[1] <= sda_in;
				068 : scl <= 0;
				067 : scl <= 1;
				066 : data[0] <= sda_in;
				065 : scl <= 0;
				// end of data word
				064 : byte_c <= data;

				// send ack
				059 : sda_dir <= 1; // output
				058 : sda_out <= 0; // ack
				057 : scl <= 1;
				056 : scl <= 0;

				// get data word
				049 : sda_dir <= 0; // input
				048 : scl <= 1;
				047 : data[7] <= sda_in;
				046 : scl <= 0;
				045 : scl <= 1;
				044 : data[6] <= sda_in;
				043 : scl <= 0;
				042 : scl <= 1;
				041 : data[5] <= sda_in;
				040 : scl <= 0;
				039 : scl <= 1;
				038 : data[4] <= sda_in;
				037 : scl <= 0;
				036 : scl <= 1;
				035 : data[3] <= sda_in;
				034 : scl <= 0;
				033 : scl <= 1;
				032 : data[2] <= sda_in;
				031 : scl <= 0;
				030 : scl <= 1;
				029 : data[1] <= sda_in;
				028 : scl <= 0;
				027 : scl <= 1;
				026 : data[0] <= sda_in;
				025 : scl <= 0;
				// end of data word
				024 : byte_d <= data;

				// send ack
				019 : sda_dir <= 1; // output
				018 : sda_out <= 1; // nack
				017 : scl <= 1;
				016 : scl <= 0;

				// send stop
				009 : sda_dir <= 1; // output
				008 : sda_out <= 1;
				007 : sda_out <= 0;
				006 : scl <= 1;
				005 : sda_out <= 1;

				001 : begin
					sda_dir <= 1;
					scl <= 1'bz;
					sda_out <= 1;
				end
				default : ;
			endcase
			bit_counter <= bit_counter - 1'b1;
		end else begin
			busy <= 0;
			if (start_transfer==1) begin
				bit_counter <= 300;
				busy <= 1;
			end
		end
	end
endmodule

`endif

