// written 2020-10-01 by mza
// based on mza-test043.spi-pollable-memories-and-multiple-oserdes-function-generator-outputs.althea.v
// based on mza-test044.simple-parallel-interface-and-pollable-memory.althea.v
// last updated 2021-02-28 by mza

`define althea_revB
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
		assign diff_pair_left[i]  = 0; // b_n, b_p, e_n, e_p
//		assign diff_pair_right[i] = 0; // h_n, h_p, k_n, k_p
	end
	reg pre_ack_valid = 0;
	assign diff_pair_right[0] = read;            // k_p
	assign diff_pair_right[1] = register_select; // k_n
	assign diff_pair_right[3] = pre_ack_valid;   // h_n
	assign diff_pair_right[2] = enable;          // h_p
	assign diff_pair_left[11:4] = bus[15:8]; // a_n, a_p, c_n, c_p, d_n, d_p, f_n, f_p
	assign diff_pair_right[11:4] = bus[7:0]; // g_n, g_p, j_n, j_p, l_n, l_p, m_n, m_p
	for (i=0; i<6; i=i+1) begin : single_ended_array
		assign single_ended_left[i] = 0;
		assign single_ended_right[i] = 0;
	end
	localparam GAP = 0;
	localparam OTHER_PICKOFF                    = 2;
	localparam ENABLE_PIPELINE_PICKOFF          = OTHER_PICKOFF + GAP;
	localparam ACK_VALID_PIPELINE_PICKOFF       = OTHER_PICKOFF;
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
			ack_valid_pipeline       <= {             ack_valid_pipeline[ACK_VALID_PIPELINE_PICKOFF-1:0], pre_ack_valid };
			register_select_pipeline <= { register_select_pipeline[REGISTER_SELECT_PIPELINE_PICKOFF-1:0], register_select };
			read_pipeline            <= {                       read_pipeline[READ_PIPELINE_PICKOFF-1:0], read };
			enable_pipeline          <= {                   enable_pipeline[ENABLE_PIPELINE_PICKOFF-1:0], enable };
			bus_pipeline[0] <= bus;
		end
	end
	for (i=1; i<BUS_PIPELINE_PICKOFF+1; i=i+1) begin : bus_pipeline_thing
		always @(posedge clock) begin
			if (reset125) begin
				bus_pipeline[i] <= 0;
			end else begin
				bus_pipeline[i] <= bus_pipeline[i-1];
			end
		end
	end
	assign ack_valid = ack_valid_pipeline[ACK_VALID_PIPELINE_PICKOFF];
	bus_entry_3state #(.WIDTH(BUS_WIDTH)) my3sbe (.I(pre_bus), .O(bus), .T(read)); // we are peripheral
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
	end else if (0) begin
		RAM_inferred_dual_port_gearbox #(
			.GEARBOX_RATIO(4),
			.ADDR_WIDTH_A(ADDRESS_DEPTH), .ADDR_WIDTH_B(ADDRESS_DEPTH_OSERDES),
			.DATA_WIDTH_A(TRANSACTIONS_PER_DATA_WORD*BUS_WIDTH), .DATA_WIDTH_B(BUS_WIDTH_OSERDES)
		) myram (
			.clk_a(clock), .addr_a(address_word_reg), .din_a(write_data_word), .write_en_a(write_strobe), .dout_a(read_data_word),
			.clk_b(word_clock), .addr_b(read_address), .dout_b(oserdes_word));
	end else if (0) begin
		RAM_inferred_dual_port #(
			.addr_width_a(ADDRESS_DEPTH), .addr_width_b(ADDRESS_DEPTH_OSERDES),
			.data_width_a(TRANSACTIONS_PER_DATA_WORD*BUS_WIDTH), .data_width_b(BUS_WIDTH_OSERDES)
		) myram (
			.clk_a(clock), .addr_a(address_word_reg), .din_a(write_data_word), .write_en_a(write_strobe), .dout_a(read_data_word),
			.clk_b(word_clock), .addr_b(read_address), .din_b({BUS_WIDTH_OSERDES{1'b0}}), .write_en_b(1'b0), .dout_b());
		assign oserdes_word = 8'b11100000;
	end else if (0) begin
		RAM_s6_8k_16bit_8bit mem (.reset(reset125),
			.clock_a(clock), .address_a(address_word_reg), .data_in_a(write_data_word), .write_enable_a(write_strobe), .data_out_a(read_data_word),
			.clock_b(word_clock), .address_b(read_address), .data_out_b(oserdes_word));
	end else if (0) begin
		RAM_s6_4k_32bit_8bit mem (.reset(reset125),
			.clock_a(clock), .address_a(address_word_reg), .data_in_a(write_data_word), .write_enable_a(write_strobe), .data_out_a(read_data_word),
			.clock_b(word_clock), .address_b(read_address), .data_out_b(oserdes_word));
	end else begin
		RAM_s6_16k_32bit_8bit mem (.reset(reset125),
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
		.D3_out(coax[3]), .D2_out(), .D1_out(), .D0_out(coax[0]));
	assign coax_led = 4'b1001;
	assign coax[1] = enable;
	assign coax[2] = 0;
	if (0) begin
		ocyrus_double8 #(.BIT_DEPTH(8), .PERIOD(8.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL"), .PINTYPE1("n")) mylei2 (
			.clock_in(clock125), .reset(reset125), .word_clock_out(),
			.word1_in(oserdes_word), .D1_out(coax[5]),
			.word0_in(oserdes_word), .D0_out(coax[4]),
			.locked(pll_oserdes_locked_2));
		assign sync_read_address = 0;
	end else if (0) begin
		ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(8.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL"), .PINTYPE("n")) mylei (.clock_in(clock125), .reset(reset125), .word_clock_out(), .word_in(oserdes_word), .D_out(coax[5]), .locked(pll_oserdes_locked_2));
		assign coax[4] = sync_out_stream[2]; // scope trigger
		assign sync_read_address = 0;
	end else if (0) begin
		ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(8.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL")) mylei (.clock_in(clock125), .reset(reset125), .word_clock_out(), .word_in(oserdes_word), .D_out(coax[4]), .locked(pll_oserdes_locked_2));
		assign sync_read_address = coax[5];
	end else begin
		assign pll_oserdes_locked_2 = 1;
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
	initial begin
		#100;
		$display("%d = %d + %d + %d - %d", ADDRESS_DEPTH_OSERDES, ADDRESS_DEPTH, LOG2_OF_BUS_WIDTH, LOG2_OF_TRANSACTIONS_PER_DATA_WORD, LOG2_OF_OSERDES_DATA_WIDTH);
		$display("%d, %d, %d", BUS_WIDTH, TRANSACTIONS_PER_DATA_WORD, TRANSACTIONS_PER_ADDRESS_WORD);
	end
endmodule

module top_tb;
	localparam HALF_PERIOD_OF_CONTROLLER = 1;
	localparam HALF_PERIOD_OF_PERIPHERAL = 10;
	localparam NUMBER_OF_PERIODS_OF_CONTROLLER_IN_A_DELAY = 1;
	localparam NUMBER_OF_PERIODS_OF_CONTROLLER_WHILE_WAITING_FOR_ACK = 2000;
	reg clock = 0;
	localparam BUS_WIDTH = 16;
	localparam ADDRESS_DEPTH = 14;
	localparam TRANSACTIONS_PER_DATA_WORD = 2;
	localparam TRANSACTIONS_PER_ADDRESS_WORD = 1;
	localparam ADDRESS_AUTOINCREMENT_MODE = 1;
	reg clock50_p = 0;
	reg clock50_n = 1;
	reg clock10 = 0;
	reg reset = 0;
	wire [5:0] coax;
	wire [3:0] coax_led;
	wire [7:0] led;
	reg pre_register_select = 0;
	reg register_select = 0;
	reg pre_read = 0;
	reg read = 0;
	reg [BUS_WIDTH-1:0] pre_bus = 0;
	wire [BUS_WIDTH-1:0] bus;
	reg [BUS_WIDTH-1:0] eye_center = 0;
	reg pre_enable = 0;
	reg enable = 0;
	wire a_n, a_p, c_n, c_p, d_n, d_p, f_n, f_p, b_n, b_p, e_n, e_p;
	wire m_p, m_n, l_p, l_n, j_p, j_n, g_p, g_n, k_p, k_n, h_p, h_n;
	wire z, y, x, w, v, u;
	wire n, p, q, r, s, t;
	reg [TRANSACTIONS_PER_DATA_WORD*BUS_WIDTH-1:0] wdata = 0;
	reg [TRANSACTIONS_PER_DATA_WORD*BUS_WIDTH-1:0] rdata = 0;
	bus_entry_3state #(.WIDTH(BUS_WIDTH)) my3sbe (.I(pre_bus), .O(bus), .T(~read)); // we are controller
	top #(.BUS_WIDTH(BUS_WIDTH), .ADDRESS_DEPTH(ADDRESS_DEPTH), .TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD), .TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD), .ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE), .TESTBENCH(1)) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n), .clock10(clock10), .reset(reset),
		.coax(coax),
		.diff_pair_left({ a_n, a_p, c_n, c_p, d_n, d_p, f_n, f_p, b_n, b_p, e_n, e_p }),
		.diff_pair_right({ m_p, m_n, l_p, l_n, j_p, j_n, g_p, g_n, k_p, k_n, h_p, h_n }),
		.single_ended_left({ z, y, x, w, v, u }),
		.single_ended_right({ n, p, q, r, s, t }),
		.bus(bus), .register_select(register_select), .read(read), .enable(enable), .ack_valid(ack_valid),
		.led(led), .coax_led(coax_led)
	);
	task automatic peripheral_clock_delay;
		input integer number_of_cycles;
		integer j;
		begin
			for (j=0; j<2*number_of_cycles; j=j+1) begin : delay_thing_s
				#HALF_PERIOD_OF_PERIPHERAL;
			end
		end
	endtask
	task automatic controller_clock_delay;
		input integer number_of_cycles;
		integer j;
		begin
			for (j=0; j<2*number_of_cycles; j=j+1) begin : delay_thing_m
				#HALF_PERIOD_OF_CONTROLLER;
			end
		end
	endtask
	task automatic delay;
		controller_clock_delay(NUMBER_OF_PERIODS_OF_CONTROLLER_IN_A_DELAY);
	endtask
	task automatic pulse_enable;
		integer i;
		integer j;
		begin
			i = 0;
			//delay();
			//eye_center <= 0;
			pre_enable <= 1;
			for (j=0; j<2*NUMBER_OF_PERIODS_OF_CONTROLLER_WHILE_WAITING_FOR_ACK; j=j+1) begin : delay_thing_1
				if (ack_valid) begin
					//if (0==i) begin
					//	$display("ack_valid seen after %d half-periods", j); // 421, 423, 427
					//end
					if (2==i) begin
						eye_center <= bus;
						//$display("%t bus=%08x", $time, bus);
					end
					i = i + 1;
					j = 2*NUMBER_OF_PERIODS_OF_CONTROLLER_WHILE_WAITING_FOR_ACK - 100;
				end
				if (64<i) begin
					pre_enable <= 0;
				end
				#HALF_PERIOD_OF_CONTROLLER;
			end
			//$display("ending i: %d", i); // 480
			if (pre_enable==1) begin
				//$display(“pre_enable is still 1”);
				$finish;
			end
		end
	endtask
	task automatic a16_d32_controller_write_transaction;
		input [15:0] address16;
		input [31:0] data32;
		begin
			controller_set_address16(address16);
			controller_write_data32(data32);
		end
	endtask
	task automatic a16_controller_read_transaction;
		input [15:0] address16;
		integer j;
		begin
			controller_set_address16(address16);
		end
	endtask
	task automatic controller_set_address16;
		input [15:0] address16;
		integer j;
		begin
			delay();
			// set each part of address
			pre_read <= 0;
			pre_register_select <= 0; // register_select=0 is address
//			if (1<TRANSACTIONS_PER_ADDRESS_WORD) begin : set_address_multiple
//				pre_bus <= address16[2*BUS_WIDTH-1:BUS_WIDTH];
//				pulse_enable();
//			end
			pre_bus <= address16[BUS_WIDTH-1:0];
			pulse_enable();
			delay();
			$display("%t address: %04x", $time, address16);
		end
	endtask
	task automatic controller_write_data32;
		input [31:0] data32;
		integer j;
		begin
			//wdata <= 0;
			delay();
			//wdata <= data32;
			// write each part of data
			pre_read <= 0;
			pre_register_select <= 1; // register_select=1 is data
			if (3<TRANSACTIONS_PER_DATA_WORD) begin
				pre_bus <= data32[4*BUS_WIDTH-1:3*BUS_WIDTH];
				pulse_enable();
				wdata[4*BUS_WIDTH-1:3*BUS_WIDTH] <= eye_center;
			end
			if (2<TRANSACTIONS_PER_DATA_WORD) begin
				pre_bus <= data32[3*BUS_WIDTH-1:2*BUS_WIDTH];
				pulse_enable();
				wdata[3*BUS_WIDTH-1:2*BUS_WIDTH] <= eye_center;
			end
			if (1<TRANSACTIONS_PER_DATA_WORD) begin
				pre_bus <= data32[2*BUS_WIDTH-1:BUS_WIDTH];
				pulse_enable();
				wdata[2*BUS_WIDTH-1:BUS_WIDTH] <= eye_center;
			end
			pre_bus <= data32[BUS_WIDTH-1:0];
			pulse_enable();
			wdata[BUS_WIDTH-1:0] <= eye_center;
			delay();
			$display("%t wdata: %08x", $time, wdata);
		end
	endtask
	task automatic controller_read_data32;
		integer j;
		begin
			//rdata <= 0;
			delay();
			// read each part of data
			pre_read <= 1;
			pre_register_select <= 1; // register_select=1 is data
			for (j=TRANSACTIONS_PER_DATA_WORD-1; j>=0; j=j-1) begin : read_data_multiple_2
				pulse_enable();
				if (3==j) begin
					rdata[4*BUS_WIDTH-1:3*BUS_WIDTH] <= eye_center;
					//$display("%d %08x %08x", j, eye_center, rdata);
				end else if (2==j) begin
					rdata[3*BUS_WIDTH-1:2*BUS_WIDTH] <= eye_center;
					//$display("%d %08x %08x", j, eye_center, rdata);
				end else if (1==j) begin
					rdata[2*BUS_WIDTH-1:BUS_WIDTH] <= eye_center;
					//$display("%d %08x %08x", j, eye_center, rdata);
				end else begin
					rdata[BUS_WIDTH-1:0] <= eye_center;
					//$display("%d %08x %08x", j, eye_center, rdata);
				end
			end
			delay();
			//pre_read <= 0;
			$display("%t rdata: %08x", $time, rdata);
		end
	endtask
	initial begin
		// inject global reset
		#300; reset <= 1; #300; reset <= 0;
		#512; // wait for reset50
		#512; // wait for reset125
		// test the interface
		if (ADDRESS_AUTOINCREMENT_MODE) begin
			// write some data to some addresses
			controller_clock_delay(64);
			peripheral_clock_delay(64);
			controller_set_address16(16'h_2b4c);
			controller_write_data32(32'h_3123_1507);
			controller_write_data32(32'h_3123_1508);
			controller_write_data32(32'h_3123_1509);
			controller_write_data32(32'h_3123_150a);
			// read back from those addresses
			controller_clock_delay(64);
			peripheral_clock_delay(64);
			controller_set_address16(16'h_2b4c);
			controller_read_data32();
			controller_read_data32();
			controller_read_data32();
			controller_read_data32();
		end else begin
			// write some data to some addresses
			controller_clock_delay(64);
			peripheral_clock_delay(64);
			a16_d32_controller_write_transaction(.address16(16'h2b4c), .data32(32'h3123_1507));
			controller_read_data32();
			a16_d32_controller_write_transaction(.address16(16'h2b4d), .data32(32'h3123_1508));
			controller_read_data32();
			a16_d32_controller_write_transaction(.address16(16'h2b4e), .data32(32'h3123_1509));
			controller_read_data32();
			a16_d32_controller_write_transaction(.address16(16'h2b4f), .data32(32'h3123_150a));
			controller_read_data32();
			// read back from those addresses
			controller_clock_delay(64);
			peripheral_clock_delay(64);
			a16_controller_read_transaction(.address16(16'h2b4c));
			a16_controller_read_transaction(.address16(16'h2b4d));
			a16_controller_read_transaction(.address16(16'h2b4e));
			a16_controller_read_transaction(.address16(16'h2b4f));
		end
		// write the two checksum words to the memory
		//controller_clock_delay(64);
		//peripheral_clock_delay(64);
		//a16_d32_controller_write_transaction(.address16(16'h1234), .data32(32'h3123_1507));
		//controller_read_data32();
		//a16_d32_controller_write_transaction(.address16(16'h3412), .data32(32'h0000_1507));
		//controller_read_data32();
		//pre_register_select <= 0;
		// now mess things up
		// inject read error:
		controller_clock_delay(64);
		peripheral_clock_delay(64);
		pre_register_select <= 1;
		pre_read <= 1;
		pre_bus <= 8'h33;
		pulse_enable();
		controller_set_address16(16'h1b4f);
		controller_read_data32();
		// inject write error:
		controller_clock_delay(64);
		peripheral_clock_delay(64);
		pre_register_select <= 1;
		pre_read <= 0;
		pre_bus <= 8'h66;
		pulse_enable();
		controller_set_address16(16'h4f1b);
		controller_write_data32(32'h3123_2d78);
		// inject address error:
		controller_clock_delay(64);
		peripheral_clock_delay(64);
		pre_register_select <= 0; // register_select=0 is address
		pre_read <= 0;
		pre_bus <= 8'h99;
		pulse_enable();
		controller_set_address16(16'h1b4f);
		controller_read_data32();
		// clear all signals
		pre_register_select <= 0;
		pre_read <= 0;
		pre_enable <= 0;
		// inject global reset
		controller_clock_delay(64);
		peripheral_clock_delay(64);
		#300; reset <= 1; #300; reset <= 0;
		#300;
		//$finish;
	end
	always @(posedge clock) begin
		register_select <= #1 pre_register_select;
		read <= #1 pre_read;
		enable <= #1 pre_enable;
	end
	always begin
		#HALF_PERIOD_OF_PERIPHERAL;
		clock50_p <= #1.5 ~clock50_p;
		clock50_n <= #2.5 ~clock50_n;
	end
	always begin
		#HALF_PERIOD_OF_CONTROLLER;
		clock <= #0.625 ~clock;
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
		.diff_pair_right({ g_n, g_p, j_n, j_p, l_n, l_p, m_n, m_p, h_n, h_p, k_n, k_p }),
		.single_ended_left({ z, y, x, w, v, u }),
		.single_ended_right({ n, p, q, r, s, t }),
		.register_select(rpi_gpio3_i2c1_scl), .read(rpi_gpio5),
		.enable(rpi_gpio4_gpclk0), .ack_valid(rpi_gpio2_i2c1_sda),
		.coax_led(coax_led),
		.led(led)
	);
endmodule

