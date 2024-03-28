// written 2022-11-16 by mza
// based on mza-test063.alphav2.pynqz2.v
// last updated 2024-03-18 by mza

`ifndef ALPHA_LIB
`define ALPHA_LIB

module alpha_control (
	input clock, reset, startup_sequence_1, startup_sequence_2, startup_sequence_3,
	input sda_in,
	input [11:0] CMPbias, ISEL, SBbias, DBbias,
	output reg sync, dreset, tok_a_in, scl, sda_out, sda_dir, sin, pclk, sclk, trig_top
);
	reg [31:0] counter1 = 0;
	reg [31:0] counter2 = 0;
	reg [31:0] counter3 = 0;
	reg mode3 = 0;
	reg mode2 = 0;
	reg mode1 = 0;
	localparam TIMING_CONSTANT = 100; // 20=bad; 70=bad; 100=good; 150=bad; 200=worse
	localparam ADC_CONVERSION_TIME = 2*4096;
	always @(posedge clock) begin
		if (reset) begin
			counter3 <= 0;
			sync <= 0;
			dreset <= 0;
			mode3 <= 0;
		end else begin
			counter3 <= counter3 + 1'b1;
			if (mode3==1'b1) begin
				if (1*TIMING_CONSTANT==counter3) begin
					dreset <= 1'b1;
				end else if (2*TIMING_CONSTANT==counter3) begin
					dreset <= 0;
				end else if (3*TIMING_CONSTANT==counter3) begin
					sync <= 1'b1;
				end else if (4*TIMING_CONSTANT==counter3) begin
					sync <= 0;
				end else if (5*TIMING_CONSTANT==counter3) begin
					mode3 <= 1'b0;
				end else begin
				end
			end
			if (startup_sequence_3) begin
				counter3 <= 0;
				sync <= 0;
				dreset <= 0;
				mode3 <= 1'b1;
			end
		end
	end
	always @(posedge clock) begin
		if (reset) begin
			counter1 <= 0;
			tok_a_in <= 0;
			trig_top <= 0;
			mode1 <= 0;
		end else begin
			counter1 <= counter1 + 1'b1;
			if (mode1==1'b1) begin
				if (1*TIMING_CONSTANT==counter1) begin
					trig_top <= 1'b1;
				end else if (2*TIMING_CONSTANT==counter1) begin
					trig_top <= 0;
				end else if (3*TIMING_CONSTANT+ADC_CONVERSION_TIME==counter1) begin
					tok_a_in <= 1'b1;
				end else if (4*TIMING_CONSTANT+ADC_CONVERSION_TIME==counter1) begin
					tok_a_in <= 0;
				end else if (5*TIMING_CONSTANT+ADC_CONVERSION_TIME==counter1) begin
					mode1 <= 1'b0;
				end else begin
				end
			end
			if (startup_sequence_1) begin
				counter1 <= 0;
				tok_a_in <= 0;
				trig_top <= 0;
				mode1 <= 1'b1;
			end
		end
	end
	localparam LEGACY_SERIAL_CONSTANT = 50;
	wire [1:0] CMPbias_address = 2'b00;
	wire [1:0] ISEL_address    = 2'b01;
	wire [1:0] SBbias_address  = 2'b10;
	wire [1:0] DBbias_address  = 2'b11;
	wire [15:0] data_word [3:0];
	assign data_word[0] = { 2'b00, CMPbias_address, CMPbias };
	assign data_word[1] = { 2'b00, ISEL_address,    ISEL };
	assign data_word[2] = { 2'b00, SBbias_address,  SBbias };
	assign data_word[3] = { 2'b00, DBbias_address,  DBbias };
	reg [3:0] bit_counter = 0;
	reg [1:0] word_counter = 0;
	always @(posedge clock) begin
		if (reset) begin
			counter2 <= 0;
			sin <= 0;
			sclk <= 0;
			pclk <= 0;
			bit_counter <= 15;
			word_counter <= 0;
			mode2 <= 0;
		end else begin
			counter2 <= counter2 + 1'b1;
			if (mode2==1'b1) begin
				if          (1*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (2*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (3*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (4*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (5*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (6*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (7*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (8*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (9*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (10*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (11*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (12*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (13*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (14*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (15*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (16*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (17*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (18*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (19*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (20*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (21*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (22*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (23*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (24*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (25*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (26*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (27*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (28*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (29*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (30*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (31*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (32*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (33*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (34*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (35*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (36*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (37*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (38*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (39*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (40*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (41*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (42*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (43*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (44*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (45*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (46*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (47*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (48*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
				end else if (49*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= 1'b0;
				end else if (50*LEGACY_SERIAL_CONSTANT==counter2) begin
					pclk <= 1'b1;
				end else if (63*LEGACY_SERIAL_CONSTANT==counter2) begin
					pclk <= 1'b0;
				end else if (64*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= 1'b1;
				end else if (65*LEGACY_SERIAL_CONSTANT==counter2) begin
					pclk <= 1'b1;
				end else if (78*LEGACY_SERIAL_CONSTANT==counter2) begin
					pclk <= 1'b0;
				end else if (79*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= 1'b0;
				end else if (81*LEGACY_SERIAL_CONSTANT==counter2) begin
					if (word_counter==2'b11) begin
						mode2 <= 1'b0;
					end else begin
						counter2 <= 0;
						sin <= 0;
						sclk <= 0;
						pclk <= 0;
						bit_counter <= 15;
						word_counter <= word_counter + 1'b1;
					end
				end else begin
					// no operation
				end
			end
			if (startup_sequence_2) begin
				counter2 <= 0;
				sin <= 0;
				sclk <= 0;
				pclk <= 0;
				bit_counter <= 15;
				word_counter <= 0;
				mode2 <= 1'b1;
			end
		end
	end
	reg [31:0] i2c_counter = 0;
	reg [6:0] i2c_address = 0;
	reg [7:0] i2c_data = 0;
	localparam I2C_GRANULARITY = 100;
	always @(posedge clock) begin
		if (reset) begin
			i2c_counter <= 0;
			i2c_address <= 0;
			i2c_data <= 0;
			scl <= 1'b1;
			sda_out <= 1'b0;
			sda_dir <= 1'b1;
		end else begin
//			if (2*I2C_GRANULARITY<counter & 3*I2C_GRANULARITY<counter) begin
//			end
		end
	end
endmodule

module alpha_control_tb;
	localparam half_clock_period = 4;
	localparam clock_period = 2*half_clock_period;
	reg clock = 0;
	reg reset = 1;
	reg startup_sequence_1 = 0;
	reg startup_sequence_2 = 0;
	reg startup_sequence_3 = 0;
	wire sync, dreset, tok_a_in;
	wire scl, sda_in, sda_out, sda_dir, sin, pclk, sclk, trig_top;
	initial begin
		reset <= 1; #101; reset <= 0;
		#100;
		startup_sequence_3 <= 1; #half_clock_period; startup_sequence_3 <= 0;
		#100;
		startup_sequence_2 <= 1; #half_clock_period; startup_sequence_2 <= 0;
		#5000;
		startup_sequence_1 <= 1; #half_clock_period; startup_sequence_1 <= 0;
		#400;
	end
	always begin
		clock <= ~clock;
		#half_clock_period;
	end
	alpha_control alpha_control (.clock(clock), .reset(reset), .startup_sequence_1(startup_sequence_1), .startup_sequence_2(startup_sequence_2), .startup_sequence_3(startup_sequence_3), .sync(sync), .dreset(dreset), .tok_a_in(tok_a_in), .scl(scl), .sda_in(sda_in), .sda_out(sda_out), .sin(sin), .pclk(pclk), .sclk(sclk), .trig_top(trig_top));
endmodule

module alpha_readout (
	input clock, reset, data_a,
	output [3:0] nybble,
	output reg header = 0,
	output msn,
	output [1:0] nybble_counter,
	output reg [15:0] data_word = 0
);
	localparam DATA_WIDTH = 16;
	localparam METASTABILITY_BUFFER_SIZE = 3;
	localparam EXTRA_WIDTH = 4;
	localparam SR_HIGH_BIT = DATA_WIDTH + METASTABILITY_BUFFER_SIZE + EXTRA_WIDTH;
	localparam SR_PICKOFF = SR_HIGH_BIT - 4;
	reg [SR_HIGH_BIT:0] data_sr = 0;
	reg [3:0] data_bit_counter = 0;
//	reg [12:0] data_word_counter = 15;
	wire [15:0] ALFA = 16'ha1fa;
	always @(posedge clock) begin
		if (reset) begin
			data_bit_counter <= 15;
//			data_word_counter <= 0;
			data_word <= 0;
			header <= 0;
			data_sr <= 0;
		end else begin
			data_sr <= { data_sr[SR_HIGH_BIT-1:0], data_a };
			if (data_bit_counter==0) begin
				data_bit_counter <= 15;
				data_word <= data_sr[SR_PICKOFF-1-:16];
//				data_word_counter <= data_word_counter + 1'b1;
				header <= 0;
			end else begin
				data_bit_counter <= data_bit_counter - 1'b1;
			end
			if (data_sr[SR_PICKOFF-1-:16]==ALFA) begin // WARNING: this might accidentally re-bitslip align on data 0x1fa from channel 0xa
				data_bit_counter <= 15;
//				data_word_counter <= 0;
				header <= 1;
				data_word <= data_sr[SR_PICKOFF-1-:16];
			end
		end
	end
	assign msn = nybble_counter==3 ? 1'b1 : 1'b0;
	assign nybble_counter = data_bit_counter[3:2];
	wire [3:0] nyb [3:0];
	assign nyb[0] = data_word[3:0];
	assign nyb[1] = data_word[7:4];
	assign nyb[2] = data_word[11:8];
	assign nyb[3] = data_word[15:12];
	assign nybble = nyb[nybble_counter];
endmodule

module alpha_readout_tb;
	localparam half_clock_period = 16;
	localparam clock_period = 2*half_clock_period;
	reg clock = 0;
	reg reset = 1;
	reg dat_a_t2f = 0;
	wire header;
	wire [3:0] nybble;
	wire [1:0] nybble_counter;
	wire [15:0] data_word;
	wire msn; // most significant nybble
	initial begin
		reset <= 1;
		#100;
		reset <= 0;
		#100;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period;
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period;
		dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period;
		dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period;
		// 0xa
		dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period;
		// 0x1
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period;
		// 0xf
		dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period;
		// 0xa
		dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
		// 0x3
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period;
		// 0x4
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
		// 0x5
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period;
		// 0x6
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
	end
	alpha_readout alpha_readout (.clock(clock), .reset(reset), .data_a(dat_a_t2f), .header(header), .msn(msn), .nybble(nybble), .nybble_counter(nybble_counter), .data_word(data_word));
	always begin
		clock <= ~clock;
		#half_clock_period;
	end
endmodule

`endif

