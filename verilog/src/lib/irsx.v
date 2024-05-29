// written 2023-10-09 by mza
// last updated 2024-05-29 by mza

`ifndef IRSX_LIB
`define IRSX_LIB

//`include "lib/RAM8.v"
`include "RAM8.v"

module irsx_register_interface #(
	parameter TESTBENCH = 0,
	parameter NUMBER_OF_ASIC_ADDRESS_BITS = 8,
	parameter MAX_REGISTER_ADDRESS = 2**NUMBER_OF_ASIC_ADDRESS_BITS - 1, // 255
	parameter NUMBER_OF_ASIC_DATA_BITS = 12,
	parameter NUMBER_OF_SIN_WORD_BITS = NUMBER_OF_ASIC_ADDRESS_BITS + NUMBER_OF_ASIC_DATA_BITS, // 20
	parameter EXTRA_STATE_COUNTER_INITIAL_VALUE = 4,
	parameter EXTRA_STATE_COUNTER_PICKOFF = $clog2(EXTRA_STATE_COUNTER_INITIAL_VALUE) + 1, // 6
	parameter CLOCK_DIVISOR_COUNTER_PICKOFF = 7
) (
	input clock, reset,
	input [NUMBER_OF_ASIC_ADDRESS_BITS-1:0] address,
	input [NUMBER_OF_ASIC_DATA_BITS-1:0] intended_data_in,
	output [NUMBER_OF_ASIC_DATA_BITS-1:0] intended_data_out,
	output [NUMBER_OF_ASIC_DATA_BITS-1:0] readback_data_out,
	output reg [NUMBER_OF_SIN_WORD_BITS-1:0] last_erroneous_readback,
	output reg [31:0] number_of_transactions = 0,
	input [CLOCK_DIVISOR_COUNTER_PICKOFF:0] clock_divider_initial_value_for_register_transactions,
	input [7:0] max_retries,
	input verify_with_shout,
	input write_enable,
	output reg sin = 0,
	output reg pclk = 0,
	output reg regclr = 1,
	output sclk,
	output reg [31:0] number_of_readback_errors = 0,
	input shout
);
	reg [CLOCK_DIVISOR_COUNTER_PICKOFF:0] clock_divisor_counter = 0;
	// both following addresses are 10 bits to easily address a whole single block ram
	wire [9:0] upstream_address_10 = { 2'b00, address }; // the address from the hdrb interface that reads from and writes to the "intended_values" bram
	reg [9:0] address_10 = 0; // the address that our state machine uses to look through the two brams to check for differences
	wire [11:0] data_intended; // from "intended_values" block ram at address address_10
	wire [11:0] data_readback; // from "actual_readback" block ram at address address_10
	reg [11:0] data_intended_copy = 0;
	reg [11:0] data_readback_copy = 0;
	RAM_s6_1k_12bit_12bit intended_values (.reset(reset),
		.clock_a(clock), .address_a(upstream_address_10), .data_in_a(intended_data_in), .write_enable_a(write_enable), .data_out_a(intended_data_out),
		.clock_b(clock), .address_b(address_10), .data_out_b(data_intended));
	wire [0:NUMBER_OF_SIN_WORD_BITS-1] sin_word = { address_10[NUMBER_OF_ASIC_ADDRESS_BITS-1:0], data_intended_copy };
	reg [5:0] sin_counter = 0;
	reg [3:0] pclk_counter = 0;
	reg [0:NUMBER_OF_SIN_WORD_BITS-1] shout_word = 0;
	localparam SHOUT_PIPELINE1_PICKOFF = 1;
	localparam SHOUT_PIPELINE2_PICKOFF = NUMBER_OF_SIN_WORD_BITS;
	reg [SHOUT_PIPELINE1_PICKOFF:0] shout_pipeline1 = 0; // runs at clock frequency; just to reduce metastability
	reg [SHOUT_PIPELINE2_PICKOFF:0] shout_pipeline2 = 0; // runs at SCLK
	wire [11:0] data_from_shout;
	assign data_from_shout = shout_word[8:NUMBER_OF_SIN_WORD_BITS-1]; // OSH and SSHSH in misc_reg168 default to 0 on powerup and that's the right thing to get shout
	reg shout_write = 0;
	RAM_s6_1k_12bit_12bit actual_readback (.reset(reset),
		.clock_a(clock), .address_a(address_10), .data_in_a(data_from_shout), .write_enable_a(shout_write), .data_out_a(data_readback), // for comparisons
		.clock_b(clock), .address_b(upstream_address_10), .data_out_b(readback_data_out)); // to readout to hdrb
	reg [1:0] mode = 0;
	assign sclk = sin_counter[0];
	reg [1:0] bram_wait_state = 2;
	reg [7:0] retries_remaining = 1;
	always @(posedge clock) begin
		regclr <= 0;
		shout_write <= 0;
		if (reset) begin
			mode <= 2'b00; // scan for differences
			regclr <= 1;
			sin <= 0;
			pclk <= 0;
			address_10 <= 0;
			bram_wait_state <= 2;
			sin_counter <= 0;
			pclk_counter <= 0;
			clock_divisor_counter <= 0;
			number_of_transactions <= 0;
			number_of_readback_errors <= 0;
			data_intended_copy <= 0;
			data_readback_copy <= 0;
			retries_remaining <= 1;
			last_erroneous_readback <= 0;
			shout_word <= 0;
			shout_pipeline1 <= 0;
			shout_pipeline2 <= 0;
		end else begin
			shout_pipeline1 <= { shout_pipeline1[SHOUT_PIPELINE1_PICKOFF-1:0], shout };
			if (mode==2'b00) begin // scan for differences
				if (bram_wait_state==0) begin
					if (data_intended_copy!=data_readback_copy) begin // checking two block rams against each other at address address_10
						if (0<retries_remaining) begin
							mode <= 2'b01; // difference found, so write updated value to asic
							sin <= 0;
							pclk <= 0;
							sin_counter <= 2;
							pclk_counter <= 0;
							sin <= sin_word[0]; // must get this ready before the first sclk
							clock_divisor_counter <= clock_divider_initial_value_for_register_transactions;
							bram_wait_state <= 2; // just to force it to copy from the block ram again
							retries_remaining <= retries_remaining - 1'b1;
						end else begin
							last_erroneous_readback <= shout_word;
							shout_word <= data_intended_copy; // give up on this one
							shout_write <= 1; // write it into the "actual_readback" block ram
							bram_wait_state <= 2; // just to force it to copy from the block ram again
							retries_remaining <= 1;
						end
					end else begin
						if (address_10<=MAX_REGISTER_ADDRESS) begin
							address_10 <= address_10 + 1'b1;
						end else begin
							address_10 <= 0;
						end
						bram_wait_state <= 2; // after every address_10 change
						retries_remaining <= max_retries + 1'b1;
					end
				end else if (bram_wait_state==1) begin
					data_intended_copy <= data_intended;
					data_readback_copy <= data_readback;
					bram_wait_state <= bram_wait_state - 1'b1;
				end else begin
					bram_wait_state <= bram_wait_state - 1'b1;
				end
			end else begin
				if (mode==2'b01) begin // difference found, so write updated value to asic
					if (clock_divisor_counter==0) begin
						clock_divisor_counter <= clock_divider_initial_value_for_register_transactions;
						if (sin_counter<2*NUMBER_OF_SIN_WORD_BITS) begin
							if (sclk) begin
								sin <= sin_word[sin_counter[5:1]];
							end
							sin_counter <= sin_counter + 1'b1;
						end else if (sin_counter<2*NUMBER_OF_SIN_WORD_BITS+2) begin
							pclk_counter <= 0;
							sin_counter <= sin_counter + 1'b1; // the last sclk
						end else begin
							if (pclk_counter==0) begin
								sin <= 0;
							end else if (pclk_counter==1) begin
								pclk <= 1; // "latch" a.k.a. "load bus register"
							end else if (pclk_counter==2) begin
								pclk <= 0;
							end else if (pclk_counter==3) begin
								sin <= 1;
							end else if (pclk_counter==4) begin
								pclk <= 1; // "load" a.k.a. "load destination/address node"
							end else if (pclk_counter==5) begin
								pclk <= 0;
							end else if (pclk_counter==6) begin
								sin <= 0;
							end else if (pclk_counter==7) begin
								if (verify_with_shout) begin
									mode <= 2'b10; // readback shout
								end else begin
									shout_word <= data_intended_copy;
									shout_write <= 1; // write it into the "actual_readback" block ram
									bram_wait_state <= 2;
									mode <= 2'b00; // scan for differences
								end
								number_of_transactions <= number_of_transactions + 1'b1;
								sin_counter <= 0;
							end
							pclk_counter <= pclk_counter + 1'b1;
						end
					end else begin
						clock_divisor_counter <= clock_divisor_counter - 1'b1;
					end
				end else if (mode==2'b10) begin // readback shout
					if (clock_divisor_counter==0) begin
						clock_divisor_counter <= clock_divider_initial_value_for_register_transactions + 2'd2;
						if (sin_counter<2*NUMBER_OF_SIN_WORD_BITS) begin
							if (sclk==0) begin
								shout_pipeline2 <= { shout_pipeline2[SHOUT_PIPELINE2_PICKOFF-1:0], shout_pipeline1[SHOUT_PIPELINE1_PICKOFF] };
							end
							sin_counter <= sin_counter + 1'b1;
							pclk_counter <= 0;
						end else if (pclk_counter==0) begin
							shout_pipeline2 <= { shout_pipeline2[SHOUT_PIPELINE2_PICKOFF-1:0], shout_pipeline1[SHOUT_PIPELINE1_PICKOFF] };
							pclk_counter <= pclk_counter + 1'b1;
						end else if (pclk_counter==1) begin
							shout_word <= shout_pipeline2[SHOUT_PIPELINE2_PICKOFF-:NUMBER_OF_SIN_WORD_BITS];
							shout_write <= 1; // write it into the "actual_readback" block ram
							pclk_counter <= pclk_counter + 1'b1;
						end else begin
							if (sin_word!=shout_word) begin
								number_of_readback_errors <= number_of_readback_errors + 1'b1;
							end
							mode <= 2'b00; // scan for differences
							bram_wait_state <= 2;
						end
					end else begin
						clock_divisor_counter <= clock_divisor_counter - 1'b1;
					end
				end else begin // extra state
					mode <= 2'b00; // scan for differences
				end
			end
		end
	end
endmodule

module irsx_register_interface_tb ();
	localparam HALF_CLOCK_PERIOD = 7.861/2;
	localparam WHOLE_CLOCK_PERIOD = 2*HALF_CLOCK_PERIOD;
	localparam SEVERAL_CLOCK_PERIODS = 2*WHOLE_CLOCK_PERIOD;
	localparam MANY_CLOCK_PERIODS = 100*WHOLE_CLOCK_PERIOD;
	localparam REALLY_A_LOT_OF_CLOCK_PERIODS = 1400*WHOLE_CLOCK_PERIOD;
	localparam DELAY_BETWEEN_SCLK_IN_AND_SHOUT_OUT = 16; // 10 ns, measured (scope_45.png)
	reg clock = 0;
	reg raw_reset = 1;
	reg reset = 1;
	reg shout = 0;
	wire sin, sclk, pclk, regclr;
	reg [11:0] raw_write_data_word = 0;
	reg [11:0] write_data_word = 0;
	wire [11:0] read_data_word;
	reg [7:0] raw_address_word = 0;
	reg [7:0] address_word = 0;
	reg raw_write_strobe = 0;
	reg write_strobe = 0;
	reg [19:0] shift_register = 0;
	wire [11:0] readback_data_word;
	wire [31:0] number_of_register_transactions;
	reg [7:0] clock_divider_initial_value_for_register_transactions = 0;
	wire [31:0] number_of_readback_errors;
	reg [7:0] max_retries = 5;
	reg verify_with_shout = 0;
	irsx_register_interface #(.TESTBENCH(1)) irsx_reg (.clock(clock), .reset(reset),
		.intended_data_in(write_data_word), .intended_data_out(read_data_word), .readback_data_out(readback_data_word),
		.number_of_transactions(number_of_register_transactions),
		.number_of_readback_errors(number_of_readback_errors), .last_erroneous_readback(last_erroneous_readback),
		.clock_divider_initial_value_for_register_transactions(clock_divider_initial_value_for_register_transactions),
		.max_retries(max_retries), .verify_with_shout(verify_with_shout),
		.address(address_word), .write_enable(write_strobe),
		.sin(sin), .sclk(sclk), .pclk(pclk), .regclr(regclr), .shout(shout));
	wire pre_shout = shift_register[18];
	always @(posedge clock) begin
		reset <= raw_reset;
		address_word <= raw_address_word;
		write_data_word <= raw_write_data_word;
		write_strobe <= raw_write_strobe;
	end
	always @(posedge sclk) begin
		shift_register <= { shift_register[18:0], sin };
	end
	always @(posedge sclk) begin
		shout <= #DELAY_BETWEEN_SCLK_IN_AND_SHOUT_OUT pre_shout;
	end
	always begin
		clock <= 1;
		#HALF_CLOCK_PERIOD;
		clock <= 0;
		#HALF_CLOCK_PERIOD;
	end
	initial begin
		repeat (50) begin // block ram needs a certain minimum clock cycles in reset?!?
			#WHOLE_CLOCK_PERIOD;
		end
		raw_reset <= 0;
		#500; //  wait until after the internal comparison of address_10 with 0x43
		// -----------------------
		#MANY_CLOCK_PERIODS;
		clock_divider_initial_value_for_register_transactions <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h765;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h98;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h210;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h43;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#5000; // gotta wait until the previous transactions with the asic have actually finished before changing clock_divider_initial_value_for_register_transactions
		clock_divider_initial_value_for_register_transactions <= 1;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h345;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h0a;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h567;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h13;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 0;
		raw_write_data_word <= 0;
		#6000; // gotta wait until the previous transactions with the asic have actually finished before changing clock_divider_initial_value_for_register_transactions
		clock_divider_initial_value_for_register_transactions <= 3;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h444;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h33;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h777;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h66;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 0;
		raw_write_data_word <= 0;
		#SEVERAL_CLOCK_PERIODS;
		if (0) begin
			repeat (255) begin
				raw_address_word <= raw_address_word + 1'b1;
				raw_write_data_word <= raw_write_data_word + 1'b1;
				#WHOLE_CLOCK_PERIOD;
				raw_write_strobe <= 1'b1;
				#WHOLE_CLOCK_PERIOD;
				raw_write_strobe <= 0;
				#WHOLE_CLOCK_PERIOD;
			end
		end
		// -----------------------
		#REALLY_A_LOT_OF_CLOCK_PERIODS;
		raw_address_word <= 8'h98;
		#MANY_CLOCK_PERIODS;
		raw_address_word <= 8'h43;
		#MANY_CLOCK_PERIODS;
		raw_address_word <= 8'h0a;
		#MANY_CLOCK_PERIODS;
		raw_address_word <= 8'h13;
		#MANY_CLOCK_PERIODS;
		raw_address_word <= 8'h66;
		#MANY_CLOCK_PERIODS;
		raw_address_word <= 8'h33;
		#MANY_CLOCK_PERIODS;
		$finish;
	end
endmodule

`endif

