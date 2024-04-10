`timescale 1ns / 1ps

// written 2022-11-16 by mza
// based on mza-test063.alphav2.pynqz2.v
// last updated 2024-04-09 by mza

`include "lib/reset.v"
`include "lib/debounce.v"
`include "lib/generic.v"
`include "lib/alpha.v"
`include "lib/plldcm.v"
`include "lib/i2c.v"
`include "lib/fifo.v"

module handshake_fifo #(
	parameter ACKNOWLEDGE_PICKOFF_EARLY = 3,
	parameter ACKNOWLEDGE_PICKOFF_LATE = ACKNOWLEDGE_PICKOFF_EARLY + 10
) (
	input clock, reset,
	input acknowledge,
	input fifo_empty,
	output reg fifo_read_strobe = 0,
	output reg output_strobe = 0
);
	reg [ACKNOWLEDGE_PICKOFF_LATE:0] acknowledge_pipeline = 0;
	always @(posedge clock) begin
		fifo_read_strobe <= 0;
		if (reset) begin
			output_strobe <= 0;
			acknowledge_pipeline <= 0;
		end else begin
			if (acknowledge_pipeline[ACKNOWLEDGE_PICKOFF_EARLY:ACKNOWLEDGE_PICKOFF_EARLY-1]==2'b01) begin
				output_strobe <= 0;
			end else if (acknowledge_pipeline[ACKNOWLEDGE_PICKOFF_LATE:ACKNOWLEDGE_PICKOFF_LATE-1]==2'b01) begin
				if (~fifo_empty) begin
					output_strobe <= 1'b1;
				end
			end else if (acknowledge_pipeline[ACKNOWLEDGE_PICKOFF_LATE:ACKNOWLEDGE_PICKOFF_LATE-1]==2'b10) begin
				output_strobe <= 0;
				if (~fifo_empty) begin
					fifo_read_strobe <= 1'b1;
				end
			end
			acknowledge_pipeline <= { acknowledge_pipeline[ACKNOWLEDGE_PICKOFF_LATE-1:0], acknowledge };
		end
	end
endmodule

module parcel_fifo_tb;
	localparam HALF_CLOCK_PERIOD = 2;
	localparam CLOCK_PERIOD = 2 * HALF_CLOCK_PERIOD;
	localparam EXTRA_WAIT = 8 * CLOCK_PERIOD;
	localparam DATA_WIDTH = 4;
	reg clock = 0;
	reg reset = 1;
	reg [DATA_WIDTH-1:0] nybble = 0;
	reg fifo_write_strobe = 0;
	wire [DATA_WIDTH-1:0] fifo_out_word;
	reg [DATA_WIDTH-1:0] data = 0;
	wire pmod_strobe;
	reg acknowledge = 0;
	wire fifo_read;
	wire fifo_empty;
	fifo_single_clock #(.DATA_WIDTH(DATA_WIDTH), .LOG2_OF_DEPTH(4)) fsc (.clock(clock), .reset(reset), .error_count(),
		.data_in(nybble), .write_enable(fifo_write_strobe), .full(), .almost_full(), .full_or_almost_full(),
		.data_out(fifo_out_word), .read_enable(fifo_read), .empty(fifo_empty), .almost_empty(), .empty_or_almost_empty());
	handshake_fifo pmod_fifo (.clock(clock), .reset(reset), .fifo_read_strobe(fifo_read), .fifo_empty(fifo_empty), .acknowledge(acknowledge), .output_strobe(pmod_strobe));
	initial begin
		#EXTRA_WAIT;
		reset <= 0;
		acknowledge <= 0;
		#EXTRA_WAIT;
		// initial read of an empty fifo, just to see what happens
		acknowledge <= 1'b1; #EXTRA_WAIT; acknowledge <= 0; #EXTRA_WAIT;
		#EXTRA_WAIT;
		// fill fifo
		nybble <= 4'hf; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'he; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'hd; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'hc; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'hb; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'ha; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h9; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h8; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h7; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h6; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h5; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h4; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h3; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h2; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h1; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h0; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		#EXTRA_WAIT;
		// read 'em out slowly
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		#EXTRA_WAIT;
		// one extra after the fifo should be empty, just to see what happens
		acknowledge <= 1'b1; #EXTRA_WAIT; acknowledge <= 0; #EXTRA_WAIT;
		#EXTRA_WAIT;
		// put some different values in fifo
		nybble <= 4'ha; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h1; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'hf; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'ha; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h0; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'he; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'h6; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		nybble <= 4'ha; fifo_write_strobe <= 1'b1; #CLOCK_PERIOD; fifo_write_strobe <= 0; #CLOCK_PERIOD;
		#EXTRA_WAIT;
		// read 'em out slowly
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		acknowledge <= 1'b1; @(posedge pmod_strobe) data <= fifo_out_word; #EXTRA_WAIT; acknowledge <= 0; #(4*EXTRA_WAIT);
		#EXTRA_WAIT;
		// one extra after the fifo should be empty, just to see what happens
		acknowledge <= 1'b1; #EXTRA_WAIT; acknowledge <= 0; #EXTRA_WAIT;
		#EXTRA_WAIT;
		// one extra after the fifo should be empty, just to see what happens
		acknowledge <= 1'b1; #EXTRA_WAIT; acknowledge <= 0; #EXTRA_WAIT;
		#EXTRA_WAIT;
		$finish;
	end
	always begin
		#HALF_CLOCK_PERIOD;
		clock <= ~clock;
	end
endmodule

module ALPHAtest #(
	parameter ALPHA_V = 2
) (
	// althea revBLM:
	input clock100_p, clock100_n,
	input button,
	output [5:0] coax,
	output [3:0] coax_led,
	output [7:0] led,
	input [3:0] rot,
	// alpha_eval revC:
	output sysclk_p, sysclk_n,
	output ls_i2c,
	input acknowledge,
	output [4:0] pmod,
	output scl,
	inout sda,
	output sin,
	output actual_sclk,
	output actual_pclk,
	input shout,
	output sstclk_p, sstclk_n,
	output tok_a_in,
	input tok_a_out,
	output actual_auxtrig,
	output sync,
	output trigin_p, trigin_n,
	input data_a_out_p, data_a_out_n
);
	wire clock100;
	IBUFGDS clock_in_diff (.I(clock100_p), .IB(clock100_n), .O(clock100));
	wire first_pll_locked;
	// ----------------------------------------------------------------------
	reg reset100 = 1;
	localparam RESET_COUNTER_PICKOFF = 9;
	reg [RESET_COUNTER_PICKOFF:0] reset_counter = 0;
	always @(posedge clock100) begin
		if (reset_counter[RESET_COUNTER_PICKOFF]) begin
			reset100 <= 0;
		end else begin
			reset100 <= 1;
			reset_counter <= reset_counter + 1'b1;
		end
	end
	wire reset;
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(RESET_COUNTER_PICKOFF)) reset100_wait4pll (.reset_input(reset100), .pll_locked_input(first_pll_locked), .clock_input(clock100), .reset_output(reset));
	// ----------------------------------------------------------------------
	wire sysclk_raw, sysclk180_raw, sstclk_raw, sstclk180_raw;
	wire sysclk, sysclk180, sstclk, sstclk180;
	simplepll_BASE #(.PERIOD(10.0), .OVERALL_DIVIDE(1), .MULTIPLY(4), .COMPENSATION("INTERNAL"),
		.DIVIDE0(4), .DIVIDE1(4), .DIVIDE2(4), .DIVIDE3(4), .DIVIDE4(4), .DIVIDE5(4),
		.PHASE0(0.0), .PHASE1(180.0), .PHASE2(0.0), .PHASE3(180.0), .PHASE4(0.0), .PHASE5(0.0)
	) pll_sys_sst (.clockin(clock100), .reset(reset100), .locked(first_pll_locked),
		.clock0out(sysclk_raw), .clock1out(sysclk180_raw),
		.clock2out(sstclk_raw), .clock3out(sstclk180_raw),
		.clock4out(), .clock5out()
	);
	BUFG sysraw (.I(sysclk_raw), .O(sysclk));
	BUFG sys180 (.I(sysclk180_raw), .O(sysclk180));
	BUFG sstraw (.I(sstclk_raw), .O(sstclk));
	BUFG sst180 (.I(sstclk180_raw), .O(sstclk180));
	clock_ODDR_out_diff sysclk_ODDR (.clock_in_p(sysclk), .clock_in_n(sysclk180), .reset(reset), .clock_out_p(sysclk_p), .clock_out_n(sysclk_n));
	clock_ODDR_out_diff sstclk_ODDR (.clock_in_p(sstclk), .clock_in_n(sstclk180), .reset(reset), .clock_out_p(sstclk_p), .clock_out_n(sstclk_n));
//	ODDR2 #(.DDR_ALIGNMENT("NONE")) oddr2_clock (.C0(sysclk), .C1(sysclk180), .CE(1'b1), .D0(1'b1), .D1(1'b0), .R(reset), .S(1'b0), .Q(coax[3]));
	// ----------------------------------------------------------------------
	wire trigin;
	OBUFDS obuf_trigin (.I(trigin), .O(trigin_p), .OB(trigin_n));
	wire auxtrig, pclk, sclk;
	wire dreset; // auxtrig, pclk, sclk;
	// defaults ---------------------------------
	assign auxtrig = 0;
	assign actual_pclk = pclk | dreset;
	assign actual_sclk = sclk | dreset;
	assign actual_auxtrig = auxtrig | dreset;
	assign ls_i2c = 1'b1; // 0=i2c; 1=ls
	//assign ls_i2c = 1'b0; // 0=i2c; 1=ls
	// ----------------------------------------------------------------------
	assign led[0] = ~first_pll_locked;
	assign led[1] = startup_sequence_1_has_occurred;
	assign led[2] = startup_sequence_2_has_occurred;
	assign led[3] = startup_sequence_3_has_occurred;
	assign led[4] = i2c_transfer_has_occurred;
	assign led[7:5] = { 1'b0, 1'b0, 1'b0 };
//	wire debounced_button_going_inactive;
	wire should_do_i2c_transfer = 1;
	wire should_do_startup_sequence_3 = 1;
	wire should_do_startup_sequence_2 = 1;
	wire should_do_startup_sequence_1 = 1;
	reg start_i2c_transfer = 0;
	reg startup_sequence_3 = 0;
	reg startup_sequence_2 = 0;
	reg startup_sequence_1 = 0;
	reg i2c_transfer_has_occurred = 0;
	reg startup_sequence_3_has_occurred = 0;
	reg startup_sequence_2_has_occurred = 0;
	reg startup_sequence_1_has_occurred = 0;
	// ----------------------------------------------------------------------
	wire something_happened = startup_sequence_3 || startup_sequence_2 || startup_sequence_1 || start_i2c_transfer;
	wire anything_that_is_going_on = tok_a_out || pclk || sclk || sin || dreset || auxtrig || trigin || something_happened;
	wire data_a;
	IBUFDS data_in (.I(data_a_out_p), .IB(data_a_out_n), .O(data_a));
	wire [3:0] nybble;
//	wire [1:0] nybble_counter;
//	wire [15:0] data_word;
	wire header, meat, footer, fifo_write_strobe, msn; // msn = most significant nybble
	alpha_readout alpha_readout (.clock(sysclk), .reset(reset), .data_a(data_a), .header(header), .meat(meat), .footer(footer), .strobe(fifo_write_strobe), .msn(msn), .nybble(nybble), .nybble_counter(), .data_word());
	localparam LOG2_OF_DEPTH = 13 + 2; // $clog2(4200) + 2;
	wire [3:0] fifo_out_word;
	wire fifo_read_strobe;
	wire pmod_strobe;
	wire fifo_empty;
	fifo_single_clock #(.DATA_WIDTH(4), .LOG2_OF_DEPTH(LOG2_OF_DEPTH)) fsc (.clock(sysclk), .reset(reset), .error_count(),
		.data_in(nybble), .write_enable(fifo_write_strobe), .full(), .almost_full(), .full_or_almost_full(),
		.data_out(fifo_out_word), .read_enable(fifo_read_strobe), .empty(fifo_empty), .almost_empty(), .empty_or_almost_empty());
	handshake_fifo pmod_fifo (.clock(sysclk), .reset(reset), .fifo_read_strobe(fifo_read_strobe), .fifo_empty(fifo_empty), .acknowledge(acknowledge), .output_strobe(pmod_strobe));
	assign pmod[4] = pmod_strobe;
	assign pmod[3:0] = fifo_out_word;
	// tok_a_in tok_a_out anything_that_is_going_on msn header footer meat
	assign coax[0] = data_a;
	assign coax[1] = header;
	assign coax[2] = footer;
	assign coax[3] = meat;
	assign coax[4] = msn;
	assign coax[5] = tok_a_out;
	reg [3:0] rot_buffered_a = 0;
	reg [3:0] rot_buffered_b = 0;
	always @(posedge sysclk) begin
		if (reset) begin
			rot_buffered_a <= 0;
			rot_buffered_b <= 0;
		end else begin
			rot_buffered_b <= rot_buffered_a;
			rot_buffered_a <= ~rot;
		end
	end
	assign coax_led[3] = rot_buffered_b[3];
	assign coax_led[2] = rot_buffered_b[2];
	assign coax_led[1] = rot_buffered_b[1];
	assign coax_led[0] = rot_buffered_b[0];
	wire [3:0] ISEL_setting = 4'hb; // 79 us ramp
	wire [3:0] CMPbias_MSN = 4'h8;
	wire [3:0] ISEL_MSN    = ISEL_setting;
	wire [3:0] SBbias_MSN  = 4'h8;
	wire [3:0] DBbias_MSN  = 4'h8;
	wire [11:0] CMPbias = {CMPbias_MSN, 8'h44};
	wire [11:0] ISEL    = {ISEL_MSN,    8'h44};
	wire [11:0] SBbias  = {SBbias_MSN,  8'h44};
	wire [11:0] DBbias  = {DBbias_MSN,  8'h44};
	// ----------------------------------------------------------------------
	localparam STARTUP_SEQUENCE_3_COUNTER_PICKOFF = 26;
	reg [STARTUP_SEQUENCE_3_COUNTER_PICKOFF:0] startup_sequence_3_counter = 0;
	always @(posedge sysclk) begin
		startup_sequence_3 <= 0;
		if (reset) begin
			startup_sequence_3_has_occurred <= 0;
		end else if (~startup_sequence_3_has_occurred) begin
			if (startup_sequence_3_counter[STARTUP_SEQUENCE_3_COUNTER_PICKOFF]) begin
				if (should_do_startup_sequence_3) begin
					startup_sequence_3 <= 1'b1;
					startup_sequence_3_has_occurred <= 1'b1;
				end
			end else begin
				startup_sequence_3_counter <= startup_sequence_3_counter + 1'b1;
			end
		end
	end
	// ----------------------------------------------------------------------
	localparam STARTUP_SEQUENCE_2_COUNTER_PICKOFF = 26;
	reg [STARTUP_SEQUENCE_2_COUNTER_PICKOFF:0] startup_sequence_2_counter = 0;
	always @(posedge sysclk) begin
		startup_sequence_2 <= 0;
		if (reset) begin
			startup_sequence_2_has_occurred <= 0;
		end else if ((startup_sequence_3_has_occurred||~should_do_startup_sequence_3) && ~startup_sequence_2_has_occurred) begin
			if (startup_sequence_2_counter[STARTUP_SEQUENCE_2_COUNTER_PICKOFF]) begin
				if (should_do_startup_sequence_2) begin
					startup_sequence_2 <= 1'b1;
					startup_sequence_2_has_occurred <= 1'b1;
				end
			end else begin
				startup_sequence_2_counter <= startup_sequence_2_counter + 1'b1;
			end
		end
	end
	// ----------------------------------------------------------------------
	localparam START_I2C_TRANSFER_COUNTER_PICKOFF = 26;
	reg [START_I2C_TRANSFER_COUNTER_PICKOFF:0] start_i2c_transfer_counter = 0;
	always @(posedge sysclk) begin
		start_i2c_transfer <= 0;
		if (reset) begin
			i2c_transfer_has_occurred <= 0;
		//end else if (startup_sequence_3_has_occurred && startup_sequence_2_has_occurred && ~i2c_transfer_has_occurred) begin
		end else if ((startup_sequence_3_has_occurred||~should_do_startup_sequence_3) && (startup_sequence_2_has_occurred||~should_do_startup_sequence_2) && ~i2c_transfer_has_occurred) begin
			if (start_i2c_transfer_counter[START_I2C_TRANSFER_COUNTER_PICKOFF]) begin
				if (should_do_i2c_transfer) begin
					start_i2c_transfer <= 1'b1;
					i2c_transfer_has_occurred <= 1'b1;
				end
			end else begin
				start_i2c_transfer_counter <= start_i2c_transfer_counter + 1'b1;
			end
		end
	end
	// ----------------------------------------------------------------------
	wire debounced_button;
	debounce #(.CLOCK_FREQUENCY(100000000), .TIMEOUT_IN_MILLISECONDS(50)) button_debounce (.clock(sysclk), .raw_button_input(button), .polarity(1'b0), .button_activated_pulse(debounced_button), .button_deactivated_pulse(), .button_active());
	always @(posedge sysclk) begin
		startup_sequence_1 <= 0;
		if (reset) begin
			startup_sequence_1_has_occurred <= 0;
		end else if ((startup_sequence_3_has_occurred||~should_do_startup_sequence_3) && (startup_sequence_2_has_occurred||~should_do_startup_sequence_2) && (i2c_transfer_has_occurred||~should_do_i2c_transfer)) begin
			if (debounced_button) begin
				startup_sequence_1 <= 1;
				startup_sequence_1_has_occurred <= 1;
			end
		end
	end
	// ----------------------------------------------------------------------
	wire sda_in, sda_out, sda_dir;
	assign sda = sda_dir ? sda_out : 1'bz;
	assign sda_in = sda;
	alpha_control alpha_control (.clock(sysclk), .reset(reset), .startup_sequence_1(startup_sequence_1), .startup_sequence_2(startup_sequence_2), .startup_sequence_3(startup_sequence_3), .start_i2c_transfer(start_i2c_transfer), .sync(sync), .dreset(dreset), .tok_a_in(tok_a_in), .scl(scl), .sda_in(sda_in), .sda_out(sda_out), .sda_dir(sda_dir), .sin(sin), .pclk(pclk), .sclk(sclk), .trig_top(trigin), .CMPbias(CMPbias), .ISEL(ISEL), .SBbias(SBbias), .DBbias(DBbias));
endmodule

