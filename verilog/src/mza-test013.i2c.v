// written 2018-08-06 by mza
// last updated 2018-08-14 by mza

`include "lib/hex2bcd.v"
`include "lib/uart.v"

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
				//144 : immediate_humidity[13:8] <= data[6:0];
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
				//104 : immediate_humidity[7:0] <= data;
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
				//064 : immediate_temperature[13:6] <= data;
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
				//024 : immediate_temperature[5:0] <= data[7:2];
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
					//byte_a <= byte[0];
					//byte_b <= byte[1];
					//byte_c <= byte[2];
					//byte_d <= byte[3];
				end
				default : ;
			endcase
			bit_counter--;
		end else begin
			busy <= 0;
			if (start_transfer==1) begin
				bit_counter <= 300;
				busy <= 1;
				//byte_a <= 8'h01;
				//byte_b <= 8'h23;
				//byte_c <= 8'h45;
				//byte_d <= 8'h67;
			end
		end
	end
endmodule

module mytop (input clock, output [5:1] LED, 
output [7:0] J1,
output [7:0] J2,
output [7:0] J3,
output sda_out,
output reg sda_dir,
input sda_in,
input RX,
output TX
);
	wire [6:0] i2c_address = 7'h27; // honeywell HIH6121 i2c humidity sensor
//	assign J2[7] = sda_dir ? sda_out : 1'bz; // Warning: Yosys has only limited support for tri-state logic at the moment.
	wire ack;
	wire error;
	reg start_i2c_transfer;
	wire busy;
	assign J1 = 0;
	assign J2[2] = scl;
	assign J2[7:4] = 0;
	assign J2[1:0] = 0;
	assign LED[5] = ~error;
	assign LED[4] = ack;
	assign LED[3] = uart_busy;
	assign LED[2] = busy;
	assign LED[1] = start_i2c_transfer;
	assign J3[7:4] = 0;
	assign J3[3] = sda_dir;
	assign J3[2] = sda_in;
	assign J3[1] = sda_out;
	wire scl;
	assign J3[0] = scl;
	reg [31:0] counter;
	localparam length_of_line = 6+6+6+2;
	reg [7:0] uart_character_counter = length_of_line - 1;
	reg uart_transfers_are_allowed;
	localparam i2c_clock_pickoff = 5; // yields 187.5 kHz
	localparam uart_character_pickoff = 11; // this is already close to the limit for 115200
	localparam uart_line_pickoff = 22;
	localparam slow_clock_pickoff = uart_line_pickoff;
	reg [15:0] uart_line_counter;
	reg uart_resetb = 0;
	reg [7:0] relative_humidity;
	always @(posedge clock) begin
		counter++;
		if (~uart_resetb) begin
			if (counter[31:15]==0) begin
				uart_line_counter <= 0;
				uart_resetb <= 0;
				uart_character_counter <= 0;
				uart_transfers_are_allowed <= 0;
			end else begin
				uart_resetb <= 1;
			end
		end
		if (counter[slow_clock_pickoff:0]==0) begin
			buffered_bcd1 <= bcd1;
			buffered_bcd2 <= bcd2;
			buffered_bcd3 <= bcd3;
		end else if (counter[slow_clock_pickoff:0]==1) begin
			immediate_humidity[13:8] <= byte_a[5:0];
			immediate_humidity[7:0] <= byte_b;
			immediate_temperature[13:6] <= byte_c;
			immediate_temperature[5:0] <= byte_d[7:2];
		end else if (counter[slow_clock_pickoff:0]==2) begin
			// datasheet says to divide the raw number by (2^14-2)
			// to get the % relative humidity
			// but to get just the ##% value, can just divide by
			// 163.82, but a fair approximation to this is to
			// multiply by 100
			// (shift-left-by-2+shift-left-by-5+shift-left-by-6)
			// and then divide by 2^14 (shift-right-by-14)
			relative_humidity = immediate_humidity[13:8] + immediate_humidity[13:9];
		end else if (counter[slow_clock_pickoff:0]==3) begin
			value1 <= uart_line_counter;
			//value2 <= { byte_b, byte_a };
			//value3 <= { byte_d, byte_c };
			value2 <= { 2'b00, immediate_humidity };
			value3 <= { 8'h00, relative_humidity };
			//value3 <= { 2'b00, immediate_temperature };
			//value2 <= 16'd054321;
			//value3 <= 16'd012345;
		end else begin
			if (busy==1) begin
				start_i2c_transfer <= 0;
			end else begin
				start_i2c_transfer <= 1;
			end
		end
		if (counter[uart_line_pickoff:0]==0) begin // less frequent
			uart_transfers_are_allowed <= 1;
			uart_line_counter++;
		end
		if (counter[uart_character_pickoff:0]==1) begin // more frequent
			if (uart_transfers_are_allowed==1) begin
				if (uart_character_counter<=length_of_line) begin
					start_uart_transfer <= 1;
					uart_character_counter++;
				end else begin
					uart_transfers_are_allowed <= 0;
					uart_character_counter = 0;
				end
			end
		end else begin
			start_uart_transfer <= 0;
		end
		if (uart_character_counter==length_of_line) begin
			byte_to_send <= 8'h0d; // cr
		end else if (uart_character_counter==length_of_line+1) begin
			byte_to_send <= 8'h0a; // nl
		end else if (uart_character_counter==1) begin
			byte_to_send <= { 4'h3, buffered_bcd1[23:20] };
		end else if (uart_character_counter==2) begin
			byte_to_send <= { 4'h3, buffered_bcd1[19:16] };
		end else if (uart_character_counter==3) begin
			byte_to_send <= { 4'h3, buffered_bcd1[15:12] };
		end else if (uart_character_counter==4) begin
			byte_to_send <= { 4'h3, buffered_bcd1[11:08] };
		end else if (uart_character_counter==5) begin
			byte_to_send <= { 4'h3, buffered_bcd1[07:04] };
		end else if (uart_character_counter==6) begin
			byte_to_send <= { 4'h3, buffered_bcd1[03:00] };
		end else if (uart_character_counter==7) begin
			byte_to_send <= 8'h20;
		end else if (uart_character_counter==8) begin
			byte_to_send <= { 4'h3, buffered_bcd2[23:20] };
		end else if (uart_character_counter==9) begin
			byte_to_send <= { 4'h3, buffered_bcd2[19:16] };
		end else if (uart_character_counter==10) begin
			byte_to_send <= { 4'h3, buffered_bcd2[15:12] };
		end else if (uart_character_counter==11) begin
			byte_to_send <= { 4'h3, buffered_bcd2[11:08] };
		end else if (uart_character_counter==12) begin
			byte_to_send <= { 4'h3, buffered_bcd2[07:04] };
		end else if (uart_character_counter==13) begin
			byte_to_send <= { 4'h3, buffered_bcd2[03:00] };
		end else if (uart_character_counter==14) begin
			byte_to_send <= 8'h20;
//		end else if (uart_character_counter==15) begin
//			byte_to_send <= { 4'h3, buffered_bcd3[23:20] };
//		end else if (uart_character_counter==16) begin
//			byte_to_send <= { 4'h3, buffered_bcd3[19:16] };
//		end else if (uart_character_counter==17) begin
//			byte_to_send <= { 4'h3, buffered_bcd3[15:12] };
		end else if (uart_character_counter==15) begin
			byte_to_send <= { 4'h3, buffered_bcd3[11:08] };
		end else if (uart_character_counter==16) begin
			byte_to_send <= { 4'h3, buffered_bcd3[07:04] };
		end else if (uart_character_counter==17) begin
			byte_to_send <= { 4'h3, buffered_bcd3[03:00] };
		end else begin
			byte_to_send <= 8'h20;
		end
	end
	reg [23:0] bcd1;
	reg [23:0] bcd2;
	reg [11:0] bcd3;
	reg [23:0] buffered_bcd1;
	reg [23:0] buffered_bcd2;
	reg [11:0] buffered_bcd3;
	reg [15:0] value1;
	reg [15:0] value2;
	reg [7:0] value3;
	//assign value1 = 16'h1234;
	//assign value2 = 16'h5678;
	//assign value1 = { byte[1], byte[0] };
	//assign value2 = { byte[3], byte[2] };
	//assign value1 = { byte_b, byte_a };
	//assign value2 = { byte_d, byte_c };
	hex2bcd #(.input_size_in_nybbles(4)) h2binst1 ( .clock(clock), .reset(~uart_resetb), .hex_in(value1), .bcd_out(bcd1) );
	hex2bcd #(.input_size_in_nybbles(4)) h2binst2 ( .clock(clock), .reset(~uart_resetb), .hex_in(value2), .bcd_out(bcd2) );
	hex2bcd #(.input_size_in_nybbles(2)) h2binst3 ( .clock(clock), .reset(~uart_resetb), .hex_in(value3), .bcd_out(bcd3) );
	wire i2c_clock;
	assign i2c_clock = counter[i2c_clock_pickoff];
//	wire slow_clock;
	reg [13:0] immediate_humidity;
	reg [13:0] immediate_temperature;
//	reg [13:0] previous_humidity;
//	reg [13:0] previous_temperature;
//	localparam number_of_samples_to_accumulate = 8;
//	localparam log2_of_number_of_samples_to_accumulate = $clog2(number_of_samples_to_accumulate);
//	reg [13+log2_of_number_of_samples_to_accumulate:0] accumulated_humidity;
//	reg [13+log2_of_number_of_samples_to_accumulate:0] accumulated_temperature;
//	reg [log2_of_number_of_samples_to_accumulate-1:0] counter_for_accumulating;
//	localparam accumulation_clock_pickoff = i2c_clock_pickoff + log2_of_number_of_samples_to_accumulate + 1;
//	assign counter_for_accumulating = counter[accumulation_clock_pickoff];
//	wire accumulation_clock = counter[accumulation_clock_pickoff-1];
//	always @(posedge accumulation_clock) begin
		//immediate_humidity[13:8] <= byte[0][5:0];
		//immediate_humidity[7:0] <= byte[1];
		//immediate_temperature[13:6] <= byte[2];
		//immediate_temperature[5:0] <= byte[3][7:2];
//		if (counter_for_accumulating==0) begin
//			accumulated_humidity = 0;
//			accumulated_temperature = 0;
//		end else begin
//			accumulated_humidity = accumulated_humidity + previous_humidity;
//			accumulated_temperature = accumulated_temperature + previous_temperature;
//		end
//	end
	//reg [7:0] byte [3:0];
	reg [7:0] byte_a;
	reg [7:0] byte_b;
	reg [7:0] byte_c;
	reg [7:0] byte_d;
	wire i2c_busy;
	reg start_i2c_transfer;
	i2c_send_one_byte_and_read_one_plus_four_bytes_back myinstance(
		.clock(i2c_clock),
		.address(i2c_address),
		.scl(scl),
		.sda_out(sda_out),
		.sda_dir(sda_dir),
		.sda_in(sda_in),
		.start_transfer(start_i2c_transfer),
		.busy(busy),
		.ack(ack),
		.error(error),
		.byte_a(byte_a),
		.byte_b(byte_b),
		.byte_c(byte_c),
		.byte_d(byte_d)
	);
	reg uart_busy;
	reg start_uart_transfer;
	reg [7:0] byte_to_send;
	wire uart_character_clock;
	assign uart_character_clock = counter[uart_character_pickoff];
	//assign byte_to_send = immediate_humidity[13:6];
	uart my_uart_instance (.clk(clock), .resetq(uart_resetb), .uart_busy(uart_busy), .uart_tx(TX), .uart_wr_i(start_uart_transfer), .uart_dat_i(byte_to_send));
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
	//wire sda_dir_fake;
	//assign sda_dir_fake = 1;
	wire sda_dir;
	wire sda_in;
	wire sda_out;
	mytop mytop_instance (.clock(CLK), .LED(LED), .J1(J1), .J2(J2), .J3(J3),
		.sda_out(sda_out), .sda_in(sda_in), .sda_dir(sda_dir), .TX(TX), .RX(RX));
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

