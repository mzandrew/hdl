// written 2018-08-06 by mza
// based on mza-test013.i2c.v
// last updated 2018-08-16 by mza

//module i2c_send_single_byte #(parameter number_of_bytes=1, ) (input [6:0] address);
//input read_not_write, 
module i2c_send_one_byte_and_read_one_plus_four_bytes_back (
	input clock,
	input [6:0] address,
	output reg scl,
	output reg sda_out,
	output reg sda_dir,
	input sda_in,
	input start_transfer,
	output reg busy,
	output reg ack,
	output reg error,
	output [7:0] byte_a,
	output [7:0] byte_b,
	output [7:0] byte_c,
	output [7:0] byte_d
);
	reg [8:0] bit_counter;
	reg [7:0] byte [3:0];
	reg [7:0] data;
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
					scl <= 1;
					sda_out <= 1;
				end
				default : ;
			endcase
			bit_counter--;
		end else begin
			busy <= 0;
			if (start_transfer==1) begin
				bit_counter <= 300;
				busy <= 1;
			end
		end
	end
endmodule

