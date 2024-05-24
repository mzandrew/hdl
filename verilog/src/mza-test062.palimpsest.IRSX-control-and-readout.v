// written 2023-10-09 by mza
// based on mza-test058.palimpsest.protodune-LBLS-DAQ.althea.revBLM.v
// last updated 2024-05-22 by mza

`define althea_revBLM
`include "lib/generic.v"
//`include "lib/RAM8.v"
//`include "lib/fifo.v"
//`include "lib/RAM.sv" // ise does not and will not support systemverilog
`include "lib/plldcm.v"
//`include "lib/serdes_pll.v"
`include "lib/half_duplex_rpi_bus.v"
//`include "lib/sequencer.v"
`include "lib/reset.v"
//`include "lib/edge_to_pulse.v"
//`include "lib/frequency_counter.v"
`include "lib/irsx.v"

module IRSXtest #(
	parameter BUS_WIDTH = 16,
	parameter LOG2_OF_BUS_WIDTH = $clog2(BUS_WIDTH),
	parameter TRANSACTIONS_PER_DATA_WORD = 2,
	parameter LOG2_OF_TRANSACTIONS_PER_DATA_WORD = $clog2(TRANSACTIONS_PER_DATA_WORD),
	parameter OSERDES_DATA_WIDTH = 8,
	parameter TRANSACTIONS_PER_ADDRESS_WORD = 1,
	parameter BANK_ADDRESS_DEPTH = 13,
	parameter LOG2_OF_NUMBER_OF_BANKS = BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD - BANK_ADDRESS_DEPTH, // 3
	parameter NUMBER_OF_BANKS = 1<<LOG2_OF_NUMBER_OF_BANKS, // 2^3 = 8
	parameter LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH = $clog2(64),
	parameter ADDRESS_DEPTH_OSERDES = BANK_ADDRESS_DEPTH + LOG2_OF_BUS_WIDTH + LOG2_OF_TRANSACTIONS_PER_DATA_WORD - LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH, // 13 - 4 + 1 - 6 = 4
	parameter ADDRESS_AUTOINCREMENT_MODE = 1,
	parameter TESTBENCH = 0,
	parameter COUNTER127_BIT_PICKOFF = TESTBENCH ? 5 : 23,
	parameter COUNTERWORD_BIT_PICKOFF = TESTBENCH ? 5 : 23
) (
	input clock127_p, clock127_n,
	input button,
	inout [5:0] coax,
//	input [2:0] rot,
	inout [23:4] rpi_gpio,
	output sin, sclk, pclk, regclr, convert, ss_incr, spgin,
	output sstclk_p, sstclk_n, hs_clk_p, hs_clk_n, gcc_clk_p, gcc_clk_n, wr_clk_p, wr_clk_n, wr_dat_p, wr_dat_n,
	input shout, done_out, wr_syncmon, montiming2,
	input data_p, data_n, trg01_p, trg01_n, trg23_p, trg23_n, trg45_p, trg45_n, trg67_p, trg67_n, montiming1_p, montiming1_n,
//	output other,
	output [7:0] led,
	output [3:0] coax_led
);
	wire reset;
	assign reset = ~button;
	// PLL_ADV VCO range is 400 MHz to 1080 MHz
	localparam PERIOD = 7.8;
	localparam MULTIPLY = 8;
	localparam DIVIDE = 2;
	localparam EXTRA_DIVIDE = 16;
	localparam SCOPE = "GLOBAL"; // "GLOBAL" (400 MHz), "BUFIO2" (525 MHz), "BUFPLL" (1080 MHz)
	localparam ERROR_COUNT_PICKOFF = 7;
	wire [3:0] status4;
	wire [7:0] status8;
	genvar i;
	// ----------------------------------------------------------------------
	wire hs_data;
	IBUFDS hs_data_buf (.I(data_p), .IB(data_n), .O(hs_data));
	// ----------------------------------------------------------------------
	wire montiming1;
	IBUFDS montiming1_buf (.I(montiming1_p), .IB(montiming1_n), .O(montiming1));
	// ----------------------------------------------------------------------
	wire trg01, trg23, trg45, trg67;
	IBUFDS trg01_buf (.I(trg01_p), .IB(trg01_n), .O(trg01));
	IBUFDS trg23_buf (.I(trg23_p), .IB(trg23_n), .O(trg23));
	IBUFDS trg45_buf (.I(trg45_p), .IB(trg45_n), .O(trg45)); // pins swapped on PCB
	IBUFDS trg67_buf (.I(trg67_p), .IB(trg67_n), .O(trg67)); // pins swapped on PCB
	// ----------------------------------------------------------------------
	OBUFDS wr_dat_dummy (.I(1'b0), .O(wr_dat_p), .OB(wr_dat_n));
	// ----------------------------------------------------------------------
	wire clock127;
	wire reset127;
	IBUFGDS mybuf0 (.I(clock127_p), .IB(clock127_n), .O(clock127));
	reset_wait4pll_synchronized #(.COUNTER_BIT_PICKOFF(COUNTER127_BIT_PICKOFF)) reset127_wait4pll (.reset1_input(reset), .pll_locked1_input(1'b1), .clock1_input(clock127), .clock2_input(clock127), .reset2_output(reset127));
	wire word_clock_raw, word_clock;
	// ----------------------------------------------------------------------
	wire first_pll_locked, second_pll_locked, third_pll_locked, all_plls_locked;
	assign all_plls_locked = first_pll_locked && second_pll_locked && third_pll_locked;
	wire reset_word;
	reset_wait4pll_synchronized #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword_wait4pll (.reset1_input(reset127), .pll_locked1_input(all_plls_locked), .clock1_input(clock127), .clock2_input(word_clock), .reset2_output(reset_word));
	wire wr_clk_raw, wr_clk180_raw, sstclk_raw, sstclk180_raw, gcc_clk_raw, gcc_clk180_raw, hs_clk_raw, hs_clk180_raw;
	wire wr_clk, wr_clk180, sstclk, sstclk180, gcc_clk, gcc_clk180, hs_clk, hs_clk180;
	dcm_pll_pll #(
		.DCM_PERIOD(7.861), .DCM_MULTIPLY(4), .DCM_DIVIDE(4), // 127.221875 MHz
		.PLL_PERIOD(7.861), .PLL_MULTIPLY(8), .PLL_OVERALL_DIVIDE(1), // 1017.775 MHz
		.PLL_DIVIDE0(48), .PLL_DIVIDE1(48), .PLL_DIVIDE2(48), .PLL_DIVIDE3(48), .PLL_DIVIDE4(5), .PLL_DIVIDE5(8), // /48 -> 21.20 MHz; /8 -> 127.221875 MHz
		.PLL_DIVIDE6(48), .PLL_DIVIDE7(48), .PLL_DIVIDE8(48), .PLL_DIVIDE9(48), .PLL_DIVIDE10(8), .PLL_DIVIDE11(8), // /48 -> 21.20 MHz; /8 -> 127.221875 MHz
		.PLL_PHASE0(0.0), .PLL_PHASE1(180.0), .PLL_PHASE2(0.0), .PLL_PHASE3(180.0), .PLL_PHASE4(0.0), .PLL_PHASE5(0.0),
		.PLL_PHASE6(0.0), .PLL_PHASE7(180.0), .PLL_PHASE8(0.0), .PLL_PHASE9(180.0), .PLL_PHASE10(0.0), .PLL_PHASE11(0.0)
	) my_dcm_pll (
		.clockin(clock127), .reset(reset127), .clockintermediate(), .dcm_locked(first_pll_locked), .pll1_locked(second_pll_locked), .pll2_locked(third_pll_locked),
		.clock0out(sstclk_raw), .clock1out(sstclk180_raw), .clock2out(wr_clk_raw), .clock3out(wr_clk180_raw), .clock4out(word_clock_raw), .clock5out(),
		.clock6out(gcc_clk_raw), .clock7out(gcc_clk180_raw), .clock8out(hs_clk_raw), .clock9out(hs_clk180_raw), .clock10out(), .clock11out()
	);
	BUFG wordraw (.I(word_clock_raw), .O(word_clock));
	BUFG sstraw (.I(sstclk_raw), .O(sstclk));
	BUFG sst180 (.I(sstclk180_raw), .O(sstclk180));
	BUFG wr_raw (.I(wr_clk_raw), .O(wr_clk));
	BUFG wr_180 (.I(wr_clk180_raw), .O(wr_clk180));
	BUFG gccraw (.I(gcc_clk_raw), .O(gcc_clk));
	BUFG gcc180 (.I(gcc_clk180_raw), .O(gcc_clk180));
	BUFG hsraw (.I(hs_clk_raw), .O(hs_clk));
	BUFG hs180 (.I(hs_clk180_raw), .O(hs_clk180));
	clock_ODDR_out_diff sstclk_ODDR  (.clock_in_p(sstclk),  .clock_in_n(sstclk180),  .reset(reset), .clock_out_p(sstclk_p),  .clock_out_n(sstclk_n));
	clock_ODDR_out_diff wr_clk_ODDR  (.clock_in_p(wr_clk),  .clock_in_n(wr_clk180),  .reset(reset), .clock_out_p(wr_clk_p),  .clock_out_n(wr_clk_n));
	clock_ODDR_out_diff gcc_clk_ODDR (.clock_in_p(gcc_clk), .clock_in_n(gcc_clk180), .reset(reset), .clock_out_p(gcc_clk_p), .clock_out_n(gcc_clk_n));
	clock_ODDR_out_diff hs_clk_ODDR  (.clock_in_p(hs_clk),  .clock_in_n(hs_clk180),  .reset(reset), .clock_out_p(hs_clk_p),  .clock_out_n(hs_clk_n));
	// ----------------------------------------------------------------------
	wire [7:0] status8_copy_on_word_clock_domain;
	ssynchronizer #(.WIDTH(8)) status8_copy (.clock1(clock127), .clock2(word_clock), .reset1(reset127), .reset2(reset_word), .in1(status8), .out2(status8_copy_on_word_clock_domain));
	// ----------------------------------------------------------------------
	wire [BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD-1:0] address_word_full;
	wire [BANK_ADDRESS_DEPTH-1:0] address_word_narrow = address_word_full[BANK_ADDRESS_DEPTH-1:0];
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] write_data_word;
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] read_data_word [NUMBER_OF_BANKS-1:0];
	wire [LOG2_OF_NUMBER_OF_BANKS-1:0] bank;
	wire [NUMBER_OF_BANKS-1:0] write_strobe;
	wire [NUMBER_OF_BANKS-1:0] read_strobe;
	wire [ERROR_COUNT_PICKOFF:0] hdrb_read_errors;
	wire [ERROR_COUNT_PICKOFF:0] hdrb_write_errors;
	wire [ERROR_COUNT_PICKOFF:0] hdrb_address_errors;
	half_duplex_rpi_bus #(
		.BUS_WIDTH(BUS_WIDTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE)
	) hdrb (
		.register_select(rpi_gpio[23]), // 0=address;  1=data
		      .ack_valid(rpi_gpio[22]),
		            .bus(rpi_gpio[21:6]),
		           .read(rpi_gpio[5]),  // 0=write;    1=read
		         .enable(rpi_gpio[4]),  // 0=inactive; 1=active
		.write_strobe(write_strobe), .read_strobe(read_strobe), .bank(bank), .clock(word_clock), .reset(reset_word),
		.write_data_word(write_data_word), .read_data_word(read_data_word[bank]), .address_word_reg(address_word_full),
		.read_errors(hdrb_read_errors), .write_errors(hdrb_write_errors), .address_errors(hdrb_address_errors)
	);
//	wire [ADDRESS_DEPTH_OSERDES-1:0] read_address; // in 8-bit words
	// ----------------------------------------------------------------------
	wire [31:0] bank0 [15:0]; // general settings
	RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank0 (.clock(word_clock), .reset(reset_word),
		.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[0]),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[0]),
		.data_out_b_0(bank0[0]),  .data_out_b_1(bank0[1]),  .data_out_b_2(bank0[2]),  .data_out_b_3(bank0[3]),
		.data_out_b_4(bank0[4]),  .data_out_b_5(bank0[5]),  .data_out_b_6(bank0[6]),  .data_out_b_7(bank0[7]),
		.data_out_b_8(bank0[8]),  .data_out_b_9(bank0[9]),  .data_out_b_a(bank0[10]), .data_out_b_b(bank0[11]),
		.data_out_b_c(bank0[12]), .data_out_b_d(bank0[13]), .data_out_b_e(bank0[14]), .data_out_b_f(bank0[15]));
	wire [7:0] clock_divider_initial_value_for_register_transactions = bank0[0][7:0];
	// ----------------------------------------------------------------------
	wire [31:0] bank1 [15:0]; // status
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank1 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[1]),
		.data_in_b_0(bank1[0]),  .data_in_b_1(bank1[1]),  .data_in_b_2(bank1[2]),  .data_in_b_3(bank1[3]),
		.data_in_b_4(bank1[4]),  .data_in_b_5(bank1[5]),  .data_in_b_6(bank1[6]),  .data_in_b_7(bank1[7]),
		.data_in_b_8(bank1[8]),  .data_in_b_9(bank1[9]),  .data_in_b_a(bank1[10]), .data_in_b_b(bank1[11]),
		.data_in_b_c(bank1[12]), .data_in_b_d(bank1[13]), .data_in_b_e(bank1[14]), .data_in_b_f(bank1[15]),
		.write_strobe_b(1'b1));
	wire [31:0] number_of_register_transactions;
	wire [31:0] number_of_readback_errors;
//	reg [7:0] number_of_triggers_since_reset = 0;
	wire fifo_empty;
//	wire [:] fifo_pending;
	wire [23:0] fifo_error_count;
	wire [31:0] asic_output_strobe_counter;
	wire [31:0] fifo_output_strobe_counter;
//	wire [31:0] alfa_counter;
//	wire [31:0] omga_counter;
	assign bank1[0] = { hdrb_read_errors[ERROR_COUNT_PICKOFF:0], hdrb_write_errors[ERROR_COUNT_PICKOFF:0], hdrb_address_errors[ERROR_COUNT_PICKOFF:0], status8_copy_on_word_clock_domain };
	assign bank1[1] = number_of_register_transactions;
	assign bank1[2] = number_of_readback_errors;
//	assign bank1[1][7:0] = number_of_triggers_since_reset;
//	assign bank1[2][0] = fifo_empty;
//	assign bank1[3][:] = fifo_pending;
	assign bank1[4][23:0] = fifo_error_count;
	assign bank1[5] = asic_output_strobe_counter;
	assign bank1[6] = fifo_output_strobe_counter;
//	assign bank1[7] = alfa_counter;
//	assign bank1[8] = omga_counter;
	// ----------------------------------------------------------------------
	wire [15:0] bank2; // things that just need a pulse for 1 clock cycle
	memory_bank_interface_with_pulse_outputs #(.ADDR_WIDTH(4)) pulsed_things_bank2 (.clock(word_clock),
		.address(address_word_full[3:0]), .strobe(write_strobe[2]), .pulse_out(bank2));
//	wire should_initiate_dreset_sequence        = bank2[0];
	wire should_initiate_legacy_serial_sequence = bank2[1];
//	wire should_initiate_i2c_transfer           = bank2[2];
	wire should_trigger                         = bank2[3];
	// ----------------------------------------------------------------------
	wire [31:0] bank3 [15:0]; // i2c registers
	RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank3 (.clock(word_clock), .reset(reset_word),
		.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[3]),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[3]),
		.data_out_b_0(bank3[0]),  .data_out_b_1(bank3[1]),  .data_out_b_2(bank3[2]),  .data_out_b_3(bank3[3]),
		.data_out_b_4(bank3[4]),  .data_out_b_5(bank3[5]),  .data_out_b_6(bank3[6]),  .data_out_b_7(bank3[7]),
		.data_out_b_8(bank3[8]),  .data_out_b_9(bank3[9]),  .data_out_b_a(bank3[10]), .data_out_b_b(bank3[11]),
		.data_out_b_c(bank3[12]), .data_out_b_d(bank3[13]), .data_out_b_e(bank3[14]), .data_out_b_f(bank3[15]));
//	wire [4:0] I2CupAddr             = bank3[1][7:3];
//	wire LVDSB_pwr                   = bank3[1][2];
//	wire LVDSA_pwr                   = bank3[1][1];
//	wire SRCsel                      = bank3[1][0]; // set this to zero or the data will come from data_b (you probably don't want that)
//	wire TMReg_Reset                 = bank3[2][0];
//	wire [7:0] samples_after_trigger = bank3[3][7:0];
//	wire [7:0] lookback_windows      = bank3[4][7:0];
//	wire [7:0] number_of_samples     = bank3[5][7:0];
	// ----------------------------------------------------------------------
	wire [31:0] bank4 [15:0]; // legacy serial registers
	RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank4 (.clock(word_clock), .reset(reset_word),
		.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[4]),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[4]),
		.data_out_b_0(bank4[0]),  .data_out_b_1(bank4[1]),  .data_out_b_2(bank4[2]),  .data_out_b_3(bank4[3]),
		.data_out_b_4(bank4[4]),  .data_out_b_5(bank4[5]),  .data_out_b_6(bank4[6]),  .data_out_b_7(bank4[7]),
		.data_out_b_8(bank4[8]),  .data_out_b_9(bank4[9]),  .data_out_b_a(bank4[10]), .data_out_b_b(bank4[11]),
		.data_out_b_c(bank4[12]), .data_out_b_d(bank4[13]), .data_out_b_e(bank4[14]), .data_out_b_f(bank4[15]));
//	wire [11:0] CMPbias = bank4[0][11:0]; // 1000
//	wire [11:0] ISEL    = bank4[1][11:0]; // 0xa80
//	wire [11:0] SBbias  = bank4[2][11:0]; // 1300
//	wire [11:0] DBbias  = bank4[3][11:0]; // 1300
	// ----------------------------------------------------------------------
	// bank5 asic fifo data
	wire [15:0] asic_data_from_fifo;
	assign read_data_word[5] = { 16'd0, asic_data_from_fifo };
	wire fifo_read_strobe = read_strobe[5];
	// ----------------------------------------------------------------------
	wire [31:0] bank6 [15:0]; // status
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank6 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[6]),
		.data_in_b_0(bank6[0]),  .data_in_b_1(bank6[1]),  .data_in_b_2(bank6[2]),  .data_in_b_3(bank6[3]),
		.data_in_b_4(bank6[4]),  .data_in_b_5(bank6[5]),  .data_in_b_6(bank6[6]),  .data_in_b_7(bank6[7]),
		.data_in_b_8(bank6[8]),  .data_in_b_9(bank6[9]),  .data_in_b_a(bank6[10]), .data_in_b_b(bank6[11]),
		.data_in_b_c(bank6[12]), .data_in_b_d(bank6[13]), .data_in_b_e(bank6[14]), .data_in_b_f(bank6[15]),
		.write_strobe_b(1'b1));
//	assign bank6[0] = bank_r_strobe_counter[0];
//	assign bank6[1] = bank_r_strobe_counter[1];
//	assign bank6[2] = bank_r_strobe_counter[2];
//	assign bank6[3] = bank_r_strobe_counter[3];
//	assign bank6[4] = bank_r_strobe_counter[4];
//	assign bank6[5] = bank_r_strobe_counter[5];
//	assign bank6[6] = bank_r_strobe_counter[6];
//	assign bank6[7] = bank_r_strobe_counter[7];
//	assign bank6[8]  = bank_w_strobe_counter[0];
//	assign bank6[9]  = bank_w_strobe_counter[1];
//	assign bank6[10] = bank_w_strobe_counter[2];
//	assign bank6[11] = bank_w_strobe_counter[3];
//	assign bank6[12] = bank_w_strobe_counter[4];
//	assign bank6[13] = bank_w_strobe_counter[5];
//	assign bank6[14] = bank_w_strobe_counter[6];
//	assign bank6[15] = bank_w_strobe_counter[7];
	// ----------------------------------------------------------------------
	assign convert = 0;
	assign ss_incr = 0;
	assign spgin = 0;
//	assign sin = 0;
//	assign sclk = 0;
//	assign pclk = 0;
//	assign regclr = 0;
	irsx_register_interface irsx_reg (.clock(word_clock), .reset(reset_word),
		.intended_data_in(write_data_word[11:0]), .intended_data_out(read_data_word[7][11:0]),
		.readback_data_out(read_data_word[7][23:12]),
		.number_of_transactions(number_of_register_transactions),
		.number_of_readback_errors(number_of_readback_errors),
		.clock_divider_initial_value_for_register_transactions(clock_divider_initial_value_for_register_transactions),
		.address(address_word_full[7:0]), .write_enable(write_strobe[7]),
		.sin(sin), .sclk(sclk), .pclk(pclk), .regclr(regclr), .shout(shout));
	assign read_data_word[7][31:24] = 0;
	// ----------------------------------------------------------------------
	assign coax[5] = 0;
	assign coax[4] = 0;
	assign coax[3] = sin;
	assign coax[2] = sclk;
	assign coax[1] = pclk;
	assign coax[0] = shout;
	// ----------------------------------------------------------------------
	wire should_allow_legacy_serial_sequence = 1;
	wire should_allow_trigger = 1;
	reg initiate_legacy_serial_sequence = 0;
	reg initiate_trigger = 0;
	reg legacy_serial_sequence_has_occurred = 0;
	reg trigger_has_occurred = 0;
	// ----------------------------------------------------------------------
	assign status8[7] = ~first_pll_locked;
	assign status8[6] = ~second_pll_locked;
	assign status8[5] = ~third_pll_locked;
	assign status8[4] = ~all_plls_locked;
	assign status8[3] = reset127;
	assign status8[2] = reset_word;
	assign status8[1] = legacy_serial_sequence_has_occurred;
	assign status8[0] = trigger_has_occurred;
	// ----------------------------------------------------------------------
	assign status4[3] = ~first_pll_locked;
	assign status4[2] = ~second_pll_locked;
	assign status4[1] = ~reset127;
	assign status4[0] = ~reset_word;
	// -------------------------------------
	assign coax_led = status4;
	assign led = status8;
	initial begin
		#100;
		$display("%d = %d + %d + %d - %d", ADDRESS_DEPTH_OSERDES, BANK_ADDRESS_DEPTH, LOG2_OF_BUS_WIDTH, LOG2_OF_TRANSACTIONS_PER_DATA_WORD, LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH);
		$display("BUS_WIDTH=%d, TRANSACTIONS_PER_DATA_WORD=%d, TRANSACTIONS_PER_ADDRESS_WORD=%d", BUS_WIDTH, TRANSACTIONS_PER_DATA_WORD, TRANSACTIONS_PER_ADDRESS_WORD);
		$display("%d banks", NUMBER_OF_BANKS);
	end
endmodule

module TESTBENCH_IRSXtest_tb;
	localparam HALF_PERIOD_OF_CONTROLLER = 1;
	localparam HALF_PERIOD_OF_PERIPHERAL = 10;
	localparam NUMBER_OF_PERIODS_OF_CONTROLLER_IN_A_DELAY = 1;
	localparam NUMBER_OF_PERIODS_OF_CONTROLLER_WHILE_WAITING_FOR_ACK = 2000;
	reg clock = 0;
	localparam BUS_WIDTH = 16;
	localparam ADDRESS_DEPTH = 13;
	localparam TRANSACTIONS_PER_DATA_WORD = 2;
	localparam TRANSACTIONS_PER_ADDRESS_WORD = 1;
	localparam ADDRESS_AUTOINCREMENT_MODE = 1;
	reg clock127_p = 0;
	reg clock127_n = 1;
	reg button = 1;
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
	IRSXtest #(.BUS_WIDTH(BUS_WIDTH), .ADDRESS_DEPTH(ADDRESS_DEPTH), .TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD), .TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD), .ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE), .TESTBENCH(1)) tbIRSXtest (
		.clock127_p(clock127_p), .clock127_n(clock127_n),
		// .button(button),
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
		#300; button <= 0; #300; button <= 1;
		#512; // wait for reset127
		#512; // wait for reset125
		//#300; button <= 0; #300; button <= 1;
		//#512; // wait for reset127
		//#512; // wait for reset125
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
		#300; button <= 0; #300; button <= 1;
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
		clock127_p <= #1.5 ~clock127_p;
		clock127_n <= #2.5 ~clock127_n;
	end
	always begin
		#HALF_PERIOD_OF_CONTROLLER;
		clock <= #0.625 ~clock;
	end
endmodule

module altheaIRSXtest #(
	parameter NOTHING = 0
) (
	input clock127_p, clock127_n,
	inout [5:0] coax,
	// other IOs:
	inout [23:4] rpi_gpio,
	// toupee connectors:
	input
	a_p, b_p, g_p, j_p, k_p, m_p,
	a_n, b_n, g_n, j_n, k_n, m_n, 
	n, p, q, w,
	output
	c_p, c_n, d_p, d_n, e_p, e_n, f_p, f_n, h_p, h_n, l_p, l_n,
	r, s, t, x, y,
	z, v, u, // not wired to anything on the PCB
	//input [2:0] rot
	input button, // reset
//	output other, // goes to PMOD connector
	output [7:0] led,
	output [3:0] coax_led
);
	localparam BUS_WIDTH = 16;
	localparam BANK_ADDRESS_DEPTH = 13;
	localparam TRANSACTIONS_PER_DATA_WORD = 2;
	localparam TRANSACTIONS_PER_ADDRESS_WORD = 1;
	localparam ADDRESS_AUTOINCREMENT_MODE = 1;
	// irsx pin names:
	wire sclk, sin, pclk, shout, regclr;
	wire montiming2, done_out, wr_syncmon, spgin, ss_incr, convert;
	// irsx pin mapping:
	assign y = sclk;
	assign x = regclr;
	assign shout = w;
	assign c_n = sin;
	assign c_p = pclk;
	assign montiming2 = n;
	assign done_out = p;
	assign wr_syncmon = q;
	assign r = spgin;
	assign s = ss_incr;
	assign t = convert;
	assign u = 0; // not wired to anything on the PCB
	assign v = 0; // not wired to anything on the PCB
	assign z = 0; // not wired to anything on the PCB
	IRSXtest #(
		.TESTBENCH(0),
		.BUS_WIDTH(BUS_WIDTH), .BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE)
	) IRSXtest (
		.clock127_p(clock127_p), .clock127_n(clock127_n),
		.button(button),
		.coax(coax),
		.sin(sin), .sclk(sclk), .pclk(pclk), .regclr(regclr), .shout(shout),
		.sstclk_p(l_p), .hs_clk_p(h_p), .gcc_clk_p(f_p), .wr_clk_p(d_p), .wr_dat_p(e_p),
		.sstclk_n(l_n), .hs_clk_n(h_n), .gcc_clk_n(f_n), .wr_clk_n(d_n), .wr_dat_n(e_n),
		.data_p(g_p), .trg01_p(m_p), .trg23_p(k_p), .trg45_p(a_p), .trg67_p(b_p), // pins are swapped on PCB for trg45 and trg67
		.data_n(g_n), .trg01_n(m_n), .trg23_n(k_n), .trg45_n(a_n), .trg67_n(b_n), // pins are swapped on PCB for trg45 and trg67
		.convert(convert), .done_out(done_out), .ss_incr(ss_incr), .wr_syncmon(wr_syncmon), .spgin(spgin),
		.montiming1_p(j_p), .montiming1_n(j_n), .montiming2(montiming2), 
		.rpi_gpio(rpi_gpio[23:4]),
//		.rot(rot),
//		.other(other),
		.led(led),
		.coax_led(coax_led)
	);
endmodule

