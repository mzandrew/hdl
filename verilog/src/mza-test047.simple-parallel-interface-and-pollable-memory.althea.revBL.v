// written 2020-10-05 by mza
// based on mza-test046.simple-parallel-interface-and-pollable-memory.althea.revB.v
// last updated 2020-10-07 by mza

`define althea_revBL
`include "lib/generic.v"
`include "lib/RAM8.v"
`include "lib/dcm.v"
//`include "lib/spi.v"
`include "lib/serdes_pll.v"
//`include "lib/reset.v"
//`include "lib/frequency_counter.v"
//`include "lib/axi4lite.v"
//`include "lib/segmented_display_driver.v"
//`include "lib/synchronizer.v"

//`define USE_INFERRED_RAM_16
//`define USE_BRAM_512
//`define USE_BRAM_4K

module top #(
	parameter BUS_WIDTH = 16,
	parameter LOG2_OF_BUS_WIDTH = $clog2(BUS_WIDTH),
	parameter TRANSACTIONS_PER_DATA_WORD = 2,
	parameter LOG2_OF_TRANSACTIONS_PER_DATA_WORD = $clog2(TRANSACTIONS_PER_DATA_WORD),
	parameter BUS_WIDTH_OSERDES = 8,
	parameter TRANSACTIONS_PER_ADDRESS_WORD = 1,
	parameter LOG2_OF_TRANSACTIONS_PER_ADDRESS_WORD = $clog2(TRANSACTIONS_PER_ADDRESS_WORD),
	parameter ADDRESS_DEPTH = 14,
	parameter OSERDES_DATA_WIDTH = 8,
	parameter LOG2_OF_OSERDES_DATA_WIDTH = $clog2(OSERDES_DATA_WIDTH),
	parameter ADDRESS_DEPTH_OSERDES = ADDRESS_DEPTH + LOG2_OF_BUS_WIDTH + LOG2_OF_TRANSACTIONS_PER_DATA_WORD - LOG2_OF_OSERDES_DATA_WIDTH,
	parameter ADDRESS_AUTOINCREMENT_MODE = 1,
	parameter TESTBENCH = 0,
	parameter COUNTER125_BIT_PICKOFF = TESTBENCH ? 4 : 10
) (
	input clock50_p, clock50_n,
	input clock10,
	input reset,
	inout [5:0] coax,
	inout [BUS_WIDTH-1:0] bus,
	input read, // 0=write; 1=read
	input register_select, // 0=address; 1=data
	input enable, // 1=active; 0=inactive
	output ack_valid,
	output [11:0] diff_pair_left,
	output [11:0] diff_pair_right,
	output [5:0] single_ended_left,
	output [5:0] single_ended_right,
	output [3:0] coax_led,
	output [7:0] led
);
	genvar i;
	for (i=0; i<4; i=i+1) begin : diff_pair_array
		assign diff_pair_left[i] = 0;
		assign diff_pair_right[i] = 0;
	end
	assign diff_pair_left[11:4] = bus[15:8];
	assign diff_pair_right[11:4] = bus[7:0];
	for (i=0; i<6; i=i+1) begin : single_ended_array
		assign single_ended_left[i] = 0;
		assign single_ended_right[i] = 0;
	end
	localparam OTHER_PICKOFF                    = 10;
	localparam ENABLE_PIPELINE_PICKOFF          = OTHER_PICKOFF + 10;
	localparam ACK_VALID_PIPELINE_PICKOFF       = 30;
	localparam REGISTER_SELECT_PIPELINE_PICKOFF = OTHER_PICKOFF;
	localparam READ_PIPELINE_PICKOFF            = OTHER_PICKOFF;
	localparam BUS_PIPELINE_PICKOFF             = OTHER_PICKOFF;
	reg [ACK_VALID_PIPELINE_PICKOFF:0] ack_valid_pipeline = 0;
	reg [REGISTER_SELECT_PIPELINE_PICKOFF:0] register_select_pipeline = 0;
	reg [READ_PIPELINE_PICKOFF:0] read_pipeline = 0;
	reg [ENABLE_PIPELINE_PICKOFF:0] enable_pipeline = 0;
	reg [BUS_WIDTH-1:0] bus_pipeline [BUS_PIPELINE_PICKOFF:0];
//	reg checksum = 0;
	// ----------------------------------------------------------------------
	reg [3:0] reset_counter = 0; // this counts how many times the reset input gets pulsed
	localparam RESET_PIPELINE_PICKOFF = 5;
	reg [RESET_PIPELINE_PICKOFF:0] reset_pipeline50 = 0;
	reg [RESET_PIPELINE_PICKOFF:0] reset_pipeline125 = 0;
	reg reset50 = 1;
	wire clock50;
	IBUFGDS mybuf0 (.I(clock50_p), .IB(clock50_n), .O(clock50));
	reg reset125 = 1;
	wire rawclock125;
	wire clock125;
	wire pll_locked;
	simpledcm_CLKGEN #(.multiply(10), .divide(4), .period(20.0)) mydcm_125 (.clockin(clock50), .reset(reset50), .clockout(rawclock125), .clockout180(), .locked(pll_locked)); // 50->125
	BUFG mrt (.I(rawclock125), .O(clock125));
	wire clock = clock125;
	// ----------------------------------------------------------------------
	reg [1:0] astate = 0;
	wire [TRANSACTIONS_PER_ADDRESS_WORD*BUS_WIDTH-1:0] address_word;
	reg [ADDRESS_DEPTH-1:0] address_word_reg = 0;
	reg [BUS_WIDTH-1:0] address [TRANSACTIONS_PER_ADDRESS_WORD-1:0];
	for (i=0; i<TRANSACTIONS_PER_ADDRESS_WORD; i=i+1) begin : address_array
		assign address_word[(i+1)*BUS_WIDTH-1:i*BUS_WIDTH] = address[i];
	end
	reg [LOG2_OF_TRANSACTIONS_PER_ADDRESS_WORD-1:0] aword = TRANSACTIONS_PER_ADDRESS_WORD-1; // most significant halfword first
	reg [1:0] wstate = 0;
	reg write_strobe = 0;
	wire [TRANSACTIONS_PER_DATA_WORD*BUS_WIDTH-1:0] write_data_word;
	reg [BUS_WIDTH-1:0] write_data [TRANSACTIONS_PER_DATA_WORD-1:0];
	for (i=0; i<TRANSACTIONS_PER_DATA_WORD; i=i+1) begin : write_data_array
		assign write_data_word[(i+1)*BUS_WIDTH-1:i*BUS_WIDTH] = write_data[i];
	end
	reg [LOG2_OF_TRANSACTIONS_PER_DATA_WORD-1:0] wword = TRANSACTIONS_PER_DATA_WORD-1; // most significant halfword first
	wire [TRANSACTIONS_PER_DATA_WORD*BUS_WIDTH-1:0] read_data_word;
	wire [BUS_WIDTH-1:0] read_data [TRANSACTIONS_PER_DATA_WORD-1:0];
	for (i=0; i<TRANSACTIONS_PER_DATA_WORD; i=i+1) begin : read_data_array
		assign read_data[i] = read_data_word[(i+1)*BUS_WIDTH-1:i*BUS_WIDTH];
	end
	reg [1:0] rstate = 0;
	reg [LOG2_OF_TRANSACTIONS_PER_DATA_WORD-1:0] rword = TRANSACTIONS_PER_DATA_WORD-1; // most significant halfword first
	reg [31:0] read_errors = 0;
	reg [31:0] write_errors = 0;
	reg [31:0] address_errors = 0;
	reg [BUS_WIDTH-1:0] pre_bus = 0;
	reg pre_ack_valid = 0;
	localparam COUNTER50_BIT_PICKOFF = 4;
	reg [COUNTER50_BIT_PICKOFF:0] counter50 = 0;
	always @(posedge clock50) begin
		if (reset_pipeline50[RESET_PIPELINE_PICKOFF:RESET_PIPELINE_PICKOFF-3]==4'b0011) begin
			reset_counter <= reset_counter + 1'b1;
		end else if (reset_pipeline50[RESET_PIPELINE_PICKOFF]) begin
			counter50 <= 0;
			reset50 <= 1;
		end else if (reset50) begin
			if (counter50[COUNTER50_BIT_PICKOFF]) begin
				reset50 <= 0;
			end
			counter50 <= counter50 + 1'b1;
		end
		reset_pipeline50 <= { reset_pipeline50[RESET_PIPELINE_PICKOFF-1:0], reset };
	end
	reg [2:0] reset50_pipeline125 = 0;
	reg [COUNTER125_BIT_PICKOFF:0] counter125 = 0;
	localparam PLL_LOCKED_PIPELINE125_PICKOFF = 2;
	reg [PLL_LOCKED_PIPELINE125_PICKOFF:0] pll_locked_pipeline125 = 0;
	integer j;
	always @(posedge clock125) begin
		if (~pll_locked_pipeline125[PLL_LOCKED_PIPELINE125_PICKOFF]) begin
			reset50_pipeline125 <= 0;
			reset_pipeline125 <= 0;
		end else begin
			reset50_pipeline125 <= { reset50_pipeline125[1:0], reset50 };
			reset_pipeline125 <= { reset_pipeline125[RESET_PIPELINE_PICKOFF-1:0], reset };
		end
		pll_locked_pipeline125 <= { pll_locked_pipeline125[PLL_LOCKED_PIPELINE125_PICKOFF-1:0], pll_locked };
	end
	always @(posedge clock) begin
		pre_ack_valid <= 0;
		write_strobe <= 0;
		if (reset_pipeline125[RESET_PIPELINE_PICKOFF] || reset50_pipeline125[2] || ~pll_locked_pipeline125[PLL_LOCKED_PIPELINE125_PICKOFF]) begin
			counter125 <= 0;
			reset125 <= 1;
		end else if (reset125) begin
			if (counter125[COUNTER125_BIT_PICKOFF]) begin
				reset125 <= 0;
			end
			counter125 <= counter125 + 1'b1;
			register_select_pipeline <= 0;
			read_pipeline <= 0;
			enable_pipeline <= 0;
			bus_pipeline[0] <= 0;
//			checksum <= 0;
			astate <= 0;
			address_word_reg <= 0;
			for (j=0; j<TRANSACTIONS_PER_ADDRESS_WORD; j=j+1) begin : address_clear
				address[j] <= 0;
			end
			aword <= TRANSACTIONS_PER_ADDRESS_WORD-1; // most significant halfword first
			wstate <= 0;
			for (j=0; j<TRANSACTIONS_PER_DATA_WORD; j=j+1) begin : write_data_clear
				write_data[j] <= 0;
			end
			wword <= TRANSACTIONS_PER_DATA_WORD-1; // most significant halfword first
			rstate <= 0;
			rword <= TRANSACTIONS_PER_DATA_WORD-1; // most significant halfword first
			read_errors <= 0;
			write_errors <= 0;
			address_errors <= 0;
			pre_bus <= 0;
		end else begin
			if (enable_pipeline[ENABLE_PIPELINE_PICKOFF:ENABLE_PIPELINE_PICKOFF-1]==2'b11) begin
				if (read_pipeline[READ_PIPELINE_PICKOFF:READ_PIPELINE_PICKOFF-1]==2'b11) begin // read mode
					pre_ack_valid <= 1;
					if (rstate[1]==0) begin
						if (rstate[0]==0) begin
							rstate[0] <= 1;
							pre_bus <= read_data[rword];
						end
					end
				end else if (read_pipeline[READ_PIPELINE_PICKOFF:READ_PIPELINE_PICKOFF-1]==2'b00) begin // write mode
					if (register_select_pipeline[REGISTER_SELECT_PIPELINE_PICKOFF:REGISTER_SELECT_PIPELINE_PICKOFF-1]==2'b11) begin
						pre_ack_valid <= 1;
						if (wstate[1]==0) begin
							if (wstate[0]==0) begin
								wstate[0] <= 1;
								write_data[wword] <= bus_pipeline[BUS_PIPELINE_PICKOFF];
							end
						end
					end else if (register_select_pipeline[REGISTER_SELECT_PIPELINE_PICKOFF:REGISTER_SELECT_PIPELINE_PICKOFF-1]==2'b00) begin // register_select=0 means address
						pre_ack_valid <= 1;
						if (astate[1]==0) begin
							if (astate[0]==0) begin
								astate[0] <= 1;
								address[aword] <= bus_pipeline[BUS_PIPELINE_PICKOFF];
							end
						end
					end
				end
			end else if (enable_pipeline[ENABLE_PIPELINE_PICKOFF:ENABLE_PIPELINE_PICKOFF-1]==2'b00) begin // enable=0
				if (ADDRESS_AUTOINCREMENT_MODE) begin
					if (rstate[1] || wstate[1]) begin
						address_word_reg <= address_word_reg + 1'b1;
					end
				end
				if (wstate) begin
					if (rstate || rword!=TRANSACTIONS_PER_DATA_WORD-1) begin
						rstate <= 0;
						read_errors <= read_errors + 1'b1;
						rword <= TRANSACTIONS_PER_DATA_WORD-1; // most significant halfword first
					end
					if (astate || aword!=TRANSACTIONS_PER_ADDRESS_WORD-1) begin
						astate <= 0;
						address_errors <= address_errors + 1'b1;
						aword <= TRANSACTIONS_PER_ADDRESS_WORD-1; // most significant halfword first
					end
					if (wstate[1]) begin
						wstate <= 0;
						wword <= TRANSACTIONS_PER_DATA_WORD-1; // most significant halfword first
						//if (write_data_word==32'h31231507) begin
//						if (write_data_word[15:0]==16'h1507) begin
//							checksum <= 1;
//						end else begin
//							checksum <= 0;
//						end
					end else begin
						wstate[0] <= 0;
						if (|wword) begin
							wword <= wword - 1'b1;
						end else begin
							wstate[1] <= 1;
							write_strobe <= 1;
						end
					end
				end
				if (rstate) begin
					if (wstate || wword!=TRANSACTIONS_PER_DATA_WORD-1) begin
						wstate <= 0;
						write_errors <= write_errors + 1'b1;
						wword <= TRANSACTIONS_PER_DATA_WORD-1; // most significant halfword first
					end
					if (astate || aword!=TRANSACTIONS_PER_ADDRESS_WORD-1) begin
						astate <= 0;
						address_errors <= address_errors + 1'b1;
						aword <= TRANSACTIONS_PER_ADDRESS_WORD-1; // most significant halfword first
					end
					if (rstate[1]) begin
						rstate <= 0;
						rword <= TRANSACTIONS_PER_DATA_WORD-1; // most significant halfword first
					end else begin
						rstate[0] <= 0;
						if (|rword) begin
							rword <= rword - 1'b1;
						end else begin
							rstate[1] <= 1;
						end
					end
				end
				if (astate) begin
					if (wstate || wword!=TRANSACTIONS_PER_DATA_WORD-1) begin
						wstate <= 0;
						write_errors <= write_errors + 1'b1;
						wword <= TRANSACTIONS_PER_DATA_WORD-1; // most significant halfword first
					end
					if (rstate || rword!=TRANSACTIONS_PER_DATA_WORD-1) begin
						rstate <= 0;
						read_errors <= read_errors + 1'b1;
						rword <= TRANSACTIONS_PER_DATA_WORD-1; // most significant halfword first
					end
					if (astate[1]) begin
						astate <= 0;
						aword <= TRANSACTIONS_PER_ADDRESS_WORD-1; // most significant halfword first
						address_word_reg <= address_word[ADDRESS_DEPTH-1:0];
					end else begin
						astate[0] <= 0;
						if (|aword) begin
							aword <= aword - 1'b1;
						end else begin
							astate[1] <= 1;
						end
					end
				end
			end
			ack_valid_pipeline <= { ack_valid_pipeline[ACK_VALID_PIPELINE_PICKOFF-1:0], pre_ack_valid };
			register_select_pipeline <= { register_select_pipeline[REGISTER_SELECT_PIPELINE_PICKOFF-1:0], register_select };
			read_pipeline            <= {                       read_pipeline[READ_PIPELINE_PICKOFF-1:0], read };
			enable_pipeline          <= {                   enable_pipeline[ENABLE_PIPELINE_PICKOFF-1:0], enable };
			bus_pipeline[0] <= bus;
		end
	end
	for (i=1; i<BUS_PIPELINE_PICKOFF+1; i=i+1) begin : bus_pipeline_thing
		always @(posedge clock) begin
			if (reset50) begin
				bus_pipeline[i] <= 0;
			end else begin
				bus_pipeline[i] <= bus_pipeline[i-1];
			end
		end
	end
	assign ack_valid = ack_valid_pipeline[ACK_VALID_PIPELINE_PICKOFF];
	bus_entry_3state #(.WIDTH(BUS_WIDTH)) my3sbe (.I(pre_bus), .O(bus), .T(read)); // we are slave
	assign bus = {BUS_WIDTH{1'bz}};
	// ----------------------------------------------------------------------
	wire word_clock;
	wire [BUS_WIDTH_OSERDES-1:0] oserdes_word;
	reg [ADDRESS_DEPTH_OSERDES-1:0] read_address = 0; // in 8-bit words
//	wire [13:0] read_address14 = read_address[13:0]; // in 8-bit words
//	wire [11:0] address12 = address_word_reg[11:0]; // in 32-bit words
	if (0) begin
		RAM_inferred #(.addr_width(ADDRESS_DEPTH), .data_width(TRANSACTIONS_PER_DATA_WORD*BUS_WIDTH)) myram (.reset(reset125),
			.wclk(clock), .waddr(address_word_reg), .din(write_data_word), .write_en(write_strobe),
			.rclk(clock), .raddr(address_word_reg), .dout(read_data_word));
		assign oserdes_word = 8'b11100100;
	end else if (1) begin
		RAM_inferred_dual_port_gearbox #(
			.ADDR_WIDTH_A(ADDRESS_DEPTH), .ADDR_WIDTH_B(ADDRESS_DEPTH_OSERDES),
			.DATA_WIDTH_A(TRANSACTIONS_PER_DATA_WORD*BUS_WIDTH), .DATA_WIDTH_B(BUS_WIDTH_OSERDES)
		) myram (
			.clk_a(clock), .addr_a(address_word_reg), .din_a(write_data_word), .write_en_a(write_strobe), .dout_a(read_data_word),
			.clk_b(word_clock), .addr_b(read_address), .dout_b(oserdes_word));
	end else if (1) begin
		RAM_inferred_dual #(
			.addr_width_a(ADDRESS_DEPTH), .addr_width_b(ADDRESS_DEPTH_OSERDES),
			.data_width_a(TRANSACTIONS_PER_DATA_WORD*BUS_WIDTH), .data_width_b(BUS_WIDTH_OSERDES)
		) myram (
			.reset(reset125),
			.clk_a(clock), .addr_a(address_word_reg), .din_a(write_data_word), .write_en_a(write_strobe), .dout_a(read_data_word),
			.clk_b(word_clock), .addr_b(read_address), .dout_b());
		assign oserdes_word = 8'b11100000;
	end else begin
		RAM_s6_4k_32bit_8bit mem (.reset(reset125),
			.clock_a(clock), .address_a(address_word_reg), .data_in_a(write_data_word), .write_enable_a(write_strobe), .data_out_a(read_data_word),
			.clock_b(word_clock), .address_b(read_address), .data_out_b(oserdes_word));
	end
//	wire pll_oserdes_locked;
//		assign pll_oserdes_locked = pll_oserdes_locked_1 && pll_oserdes_locked_2;
	wire pll_oserdes_locked_1;
	wire pll_oserdes_locked_2;
	wire sync_read_address;
	ocyrus_quad8 #(.BIT_DEPTH(8), .PERIOD(8.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL")) mylei4 (
		.clock_in(clock125), .reset(reset125), .word_clock_out(word_clock), .locked(pll_oserdes_locked_1),
		.word3_in(oserdes_word), .word2_in(oserdes_word), .word1_in(oserdes_word), .word0_in(oserdes_word),
		.D3_out(coax[3]), .D2_out(coax[2]), .D1_out(coax[1]), .D0_out(coax[0]));
	assign coax_led = 4'b1111;
	if (0) begin
		ocyrus_double8 #(.BIT_DEPTH(8), .PERIOD(8.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL")) mylei2 (
			.clock_in(clock125), .reset(reset125), .word_clock_out(),
			.word1_in(oserdes_word), .D1_out(coax[5]),
			.word0_in(oserdes_word), .D0_out(coax[4]),
			.locked(pll_oserdes_locked_2));
		assign sync_read_address = 0;
	end else begin
		assign pll_oserdes_locked_2 = 0;
		assign sync_read_address = coax[5];
		assign coax[4] = sync_out_stream[2]; // scope trigger
	end
	wire [31:0] start_read_address = 32'd0; // in 2-bit words
	wire [31:0] end_read_address = 32'd46080; // in 2-bit words; 23040 = 5120 (buckets/revo) * 9 (revos) / 2 (bits per RF-bucket period)
	reg [ADDRESS_DEPTH_OSERDES-1:0] last_read_address = 14'd4095; // in 8-bit words
	reg sync_out_raw = 0;
	reg [3:0] sync_out_stream = 0;
	always @(posedge word_clock) begin
		sync_out_raw <= 0;
		if (reset125) begin
			read_address <= start_read_address[ADDRESS_DEPTH_OSERDES-1:ADDRESS_DEPTH_OSERDES-ADDRESS_DEPTH];
			last_read_address <= end_read_address[ADDRESS_DEPTH_OSERDES-1:ADDRESS_DEPTH_OSERDES-ADDRESS_DEPTH] - 1'b1;
		end else begin
			if (read_address==last_read_address || sync_read_address) begin
				read_address <= start_read_address[ADDRESS_DEPTH_OSERDES-1:ADDRESS_DEPTH_OSERDES-ADDRESS_DEPTH];
				last_read_address <= end_read_address[ADDRESS_DEPTH_OSERDES-1:ADDRESS_DEPTH_OSERDES-ADDRESS_DEPTH] - 1'b1;
				sync_out_raw <= 1;
			end else begin
				read_address <= read_address + 1'b1;
			end
		end
		sync_out_stream <= { sync_out_stream[2:0], sync_out_raw };
	end
	// ----------------------------------------------------------------------
	if (0) begin
		assign led[7] = reset;
		assign led[6] = reset50;
		assign led[5] = reset125;
		assign led[4] = ~pll_locked;
		assign led[3] = ~pll_oserdes_locked_1;
		assign led[2] = ~pll_oserdes_locked_2;
		assign led[1] = 0;
		assign led[0] = 0;
	end else if (1) begin
		assign led[7] = ~pll_locked;
		assign led[6] = ~pll_oserdes_locked_1;
		assign led[5] = ~pll_oserdes_locked_2;
		//assign led[5] = checksum;
		//assign led[5] = |all_errors;
		//assign led[5] = |read_errors;
		assign led[4] = ack_valid;
		assign led[3] = write_strobe;
		assign led[2] = read;
		assign led[1] = enable;
		assign led[0] = register_select;
	end else begin
		assign led[7:6] = address_errors[1:0];
		assign led[5:4] = write_errors[1:0];
		assign led[3:2] = read_errors[1:0];
		assign led[1:0] = reset_counter[1:0];
		//assign led[7] = |all_errors[31:7];
		//assign led[6:0] = all_errors[6:0];
		//assign led = address[1];
		//assign led = address[0];
		//assign led = write_data[1];
		//assign led = write_data[0];
	end
endmodule

module myalthea (
	input clock50_p, clock50_n,
	inout [5:0] coax,
	// other IOs:
	output rpi_gpio2_i2c1_sda, // ack_valid
	input rpi_gpio3_i2c1_scl, // register_select
	input rpi_gpio4_gpclk0, // enable
	input rpi_gpio5, // read
	input rpi_gpio26, // spare
	// 16 bit bus:
	inout rpi_gpio6_gpclk2, rpi_gpio7_spi_ce1, rpi_gpio8_spi_ce0, rpi_gpio9_spi_miso,
	inout rpi_gpio10_spi_mosi, rpi_gpio11_spi_sclk, rpi_gpio12, rpi_gpio13,
	inout rpi_gpio14, rpi_gpio15, rpi_gpio16, rpi_gpio17,
	inout rpi_gpio18, rpi_gpio19, rpi_gpio20, rpi_gpio21,
	// diff-pair IOs (toupee connectors):
	a_p, a_n, b_p, b_n, c_p, c_n,
	d_p, d_n, e_p, e_n, f_p, f_n,
	g_p, g_n, h_p, h_n, j_p, j_n,
	k_p, k_n, l_p, l_n, m_p, m_n,
	// single-ended IOs (toupee connectors):
	n, p, q, r, s, t,
	u, v, w, x, y, z,
	// other IOs:
	input button, // reset
	output [3:0] coax_led,
	output [7:0] led
);
	localparam BUS_WIDTH = 16;
	localparam ADDRESS_DEPTH = 14;
	localparam TRANSACTIONS_PER_DATA_WORD = 2;
	localparam TRANSACTIONS_PER_ADDRESS_WORD = 1;
	localparam ADDRESS_AUTOINCREMENT_MODE = 1;
	wire clock10 = 0;
	top #(
		.BUS_WIDTH(BUS_WIDTH), .ADDRESS_DEPTH(ADDRESS_DEPTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE)
	) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n), .clock10(clock10), .reset(~button),
		.coax(coax),
		.bus({
			rpi_gpio21, rpi_gpio20, rpi_gpio19, rpi_gpio18,
			rpi_gpio17, rpi_gpio16, rpi_gpio15, rpi_gpio14,
			rpi_gpio13, rpi_gpio12, rpi_gpio11_spi_sclk, rpi_gpio10_spi_mosi,
			rpi_gpio9_spi_miso, rpi_gpio8_spi_ce0, rpi_gpio7_spi_ce1, rpi_gpio6_gpclk2
		}),
		.diff_pair_left({ a_n, a_p, c_n, c_p, d_n, d_p, f_n, f_p, b_n, b_p, e_n, e_p }),
		.diff_pair_right({ m_p, m_n, l_p, l_n, j_p, j_n, g_p, g_n, k_p, k_n, h_p, h_n }),
		.single_ended_left({ z, y, x, w, v, u }),
		.single_ended_right({ n, p, q, r, s, t }),
		.register_select(rpi_gpio3_i2c1_scl), .read(rpi_gpio5),
		.enable(rpi_gpio4_gpclk0), .ack_valid(rpi_gpio2_i2c1_sda),
		.coax_led(coax_led),
		.led(led)
	);
endmodule
