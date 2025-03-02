// written 2019-09-22 by mza
// last updated 2025-02-27 by mza

`ifndef GENERIC_LIB
`define GENERIC_LIB

`timescale 1ns / 1ps

module histogram8 #(
	parameter LOG2_OF_MAX_VALUE = 4,
	parameter NUMBER_OF_BINS = 8
) (
	input clock, clear,
	input [NUMBER_OF_BINS-1:0] increment_bin,
	output [LOG2_OF_MAX_VALUE-1:0] bin_count0, bin_count1, bin_count2, bin_count3, bin_count4, bin_count5, bin_count6, bin_count7
);
	reg [LOG2_OF_MAX_VALUE-1:0] bin_count [NUMBER_OF_BINS-1:0];
	integer i;
	always @(posedge clock) begin
		for (i=0; i<NUMBER_OF_BINS; i=i+1) begin
			if (clear) begin
				bin_count[i] <= 0;
			end else begin
				if (increment_bin[i]) begin
					bin_count[i] <= bin_count[i] + 1'b1;
				end
			end
		end
	end
	assign bin_count0 = bin_count[0];
	assign bin_count1 = bin_count[1];
	assign bin_count2 = bin_count[2];
	assign bin_count3 = bin_count[3];
	assign bin_count4 = bin_count[4];
	assign bin_count5 = bin_count[5];
	assign bin_count6 = bin_count[6];
	assign bin_count7 = bin_count[7];
endmodule

module histogram8_tb #(
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2,
	parameter LOG2_OF_MAX_VALUE = 7,
	parameter NUMBER_OF_BINS = 8
) ();
	reg clock = 0;
	always begin
		clock <= ~clock; #HALF_CLOCK_PERIOD;
	end
	reg [NUMBER_OF_BINS-1:0] pre_pulse = 0, pulse = 0;
	always @(posedge clock) begin
		pulse <= pre_pulse; clear <= pre_clear;
	end
	reg pre_clear = 0, clear = 0;
	initial begin
		#(4*CLOCK_PERIOD);
		pre_clear <= 1'b1; #CLOCK_PERIOD; pre_clear <= 1'b0; #CLOCK_PERIOD;
		#(4*CLOCK_PERIOD);
		pre_pulse <= 8'b00000000; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b10101010; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b01010101; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b10101010; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b01010101; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b00000000; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b11111111; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b11111111; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b11111111; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b00000000; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_clear <= 1'b1; #CLOCK_PERIOD; pre_clear <= 1'b0; #CLOCK_PERIOD;
		pre_pulse <= 8'b00000000; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b11001100; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b00110011; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b11111111; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_pulse <= 8'b00000000; #CLOCK_PERIOD; pre_pulse <= 0; #CLOCK_PERIOD;
		pre_clear <= 1'b1; #CLOCK_PERIOD; pre_clear <= 1'b0; #CLOCK_PERIOD;
		pre_pulse <= 8'b10101010; #(117*CLOCK_PERIOD);
		pre_pulse <= 8'b01010101; #(117*CLOCK_PERIOD);
		pre_pulse <= 8'b00000000;
		#(4*CLOCK_PERIOD);
		$finish;
	end
	wire [LOG2_OF_MAX_VALUE-1:0] bin_count [NUMBER_OF_BINS-1:0];
	histogram8 #(.NUMBER_OF_BINS(NUMBER_OF_BINS), .LOG2_OF_MAX_VALUE(LOG2_OF_MAX_VALUE)) h (.clock(clock), .clear(clear),
		.increment_bin(pulse),
		.bin_count0(bin_count[0]), .bin_count1(bin_count[1]), .bin_count2(bin_count[2]), .bin_count3(bin_count[3]),
		.bin_count4(bin_count[4]), .bin_count5(bin_count[5]), .bin_count6(bin_count[6]), .bin_count7(bin_count[7]));
endmodule

// specified for LOG2_OF_DEPTH in range [1,4]
module boxcar #(
	parameter WIDTH = 8,
	parameter LOG2_OF_DEPTH = 2,
	parameter DEPTH = 2**LOG2_OF_DEPTH,
	parameter ACCUMULATOR_PICKOFF = WIDTH + LOG2_OF_DEPTH - 1
) (
	input clock,
	input [WIDTH-1:0] in,
	input write_strobe,
	output [WIDTH-1:0] out
);
	reg [WIDTH-1:0] mem [DEPTH-1:0];
	reg [LOG2_OF_DEPTH-1:0] counter = 0;
	reg [ACCUMULATOR_PICKOFF:0] accumulator = 0;
	always @(posedge clock) begin
		if (write_strobe) begin
			mem[counter] <= in;
			counter <= counter + 1'b1;
		end
		if (DEPTH==16) begin
			accumulator <= mem[0] + mem[1] + mem[2] + mem[3] + mem[4] + mem[5] + mem[6] + mem[7] + mem[8] + mem[9] + mem[10] + mem[11] + mem[12] + mem[13] + mem[14] + mem[15];
		end else if (DEPTH==8) begin
			accumulator <= mem[0] + mem[1] + mem[2] + mem[3] + mem[4] + mem[5] + mem[6] + mem[7];
		end else if (DEPTH==4) begin
			accumulator <= mem[0] + mem[1] + mem[2] + mem[3];
		end else if (DEPTH==2) begin
			accumulator <= mem[0] + mem[1];
		end else begin
			accumulator <= mem[0];
		end
	end
	assign out = accumulator[ACCUMULATOR_PICKOFF-:WIDTH];
endmodule

module boxcar_tb #(
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2,
	parameter WIDTH = 8,
	parameter LOG2_OF_DEPTH = 2
) ();
	reg clock = 0;
	always begin
		clock <= ~clock; #HALF_CLOCK_PERIOD;
	end
	reg [WIDTH-1:0] pre_in = 0, in = 0;
	reg pre_write_strobe = 0, write_strobe = 0;
	always @(posedge clock) begin
		in <= pre_in; write_strobe <= pre_write_strobe;
	end
	initial begin
		#(4*CLOCK_PERIOD);
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h40; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h80; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'hc0; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		pre_in <= 8'h00; #CLOCK_PERIOD; pre_write_strobe <= 1; #CLOCK_PERIOD; pre_write_strobe <= 0; #CLOCK_PERIOD;
		#(4*CLOCK_PERIOD);
		$finish;
	end
	wire [WIDTH-1:0] out;
	boxcar #(.WIDTH(WIDTH), .LOG2_OF_DEPTH(LOG2_OF_DEPTH)) bc (.clock(clock), .write_strobe(write_strobe), .in(in), .out(out));
endmodule

// picks every RATIOth bit from in
module decimator #(
	parameter WIDTH = 8,
	parameter RATIO = 3
) (
	input clock,
	input [WIDTH*RATIO-1:0] in,
	output reg [WIDTH-1:0] out = 0
);
	integer i;
	always @(posedge clock) begin
		for (i=0; i<WIDTH; i=i+1) begin
			out[i] <= in[RATIO*i];
		end
	end
endmodule

module decimator_tb #(
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2
) ();
	reg clock = 0;
	always begin
		clock <= ~clock; #HALF_CLOCK_PERIOD;
	end
	reg [31:0] in = 0;
	initial begin
		#(4*CLOCK_PERIOD);
		in <= 32'hf0f0f0f0; #CLOCK_PERIOD; in <= 0; #CLOCK_PERIOD;
		in <= 32'h0f0f0f0f; #CLOCK_PERIOD; in <= 0; #CLOCK_PERIOD;
		in <= 32'h00ff00ff; #CLOCK_PERIOD; in <= 0; #CLOCK_PERIOD;
		in <= 32'h0bdb0a5a; #CLOCK_PERIOD; in <= 0; #CLOCK_PERIOD;
		#(4*CLOCK_PERIOD);
		$finish;
	end
	wire [7:0] out_8_3;
	wire [7:0] out_8_4;
	decimator #(.WIDTH(8), .RATIO(3)) d_8_3 (.clock(clock), .in(in[23:0]), .out(out_8_3));
	decimator #(.WIDTH(8), .RATIO(4)) d_8_4 (.clock(clock), .in(in), .out(out_8_4));
endmodule

// gearbox_pipeline #(.WIDTH(WIDTH), .RATIO(RATIO), .EXTRA_DELAY(2)) gp (.clock(clock), .valid(valid), .in(in), .out(out));
// this module will gladly overwrite data if the valid signal is not active every RATIO clock cycles
module gearbox_pipeline #(
	parameter WIDTH = 8,
	parameter LOG2_OF_WIDTH = $clog2(WIDTH),
	parameter RATIO = 3,
	parameter LOG2_OF_RATIO = $clog2(RATIO),
	parameter RATIO_TIMES_WIDTH = RATIO * WIDTH,
	parameter LOG2_OF_RATIO_TIMES_WIDTH = $clog2(RATIO_TIMES_WIDTH),
	parameter RATIO_MINUS_ONE_TIMES_WIDTH = (RATIO-1)*WIDTH,
	parameter EXTRA_DELAY = 4,
	parameter AMOUNT = RATIO + EXTRA_DELAY + 1,
	parameter PIPELINE_PICKOFF = WIDTH * AMOUNT - 1,
	parameter LOG2_OF_PIPELINE_PICKOFF = $clog2(PIPELINE_PICKOFF)
) (
	input clock,
	input valid,
	input [WIDTH*RATIO-1:0] in,
	output reg [WIDTH-1:0] out = 0
);
	reg [LOG2_OF_PIPELINE_PICKOFF:0] counter = 0;
	reg [PIPELINE_PICKOFF:0] pipeline = 0;
	wire [LOG2_OF_RATIO_TIMES_WIDTH-1:0] amount = RATIO_TIMES_WIDTH;
	wire [LOG2_OF_WIDTH:0] width = WIDTH;
	wire [LOG2_OF_PIPELINE_PICKOFF:0] pipeline_pickoff = PIPELINE_PICKOFF;
	always @(posedge clock) begin
		out <= pipeline[PIPELINE_PICKOFF-:WIDTH];
		if (counter==amount) begin
			counter <= 0;
		end else begin
			counter <= counter + width;
		end
		if (valid) begin
			pipeline <= { pipeline[PIPELINE_PICKOFF-WIDTH:RATIO_MINUS_ONE_TIMES_WIDTH], in };
		end else begin
			pipeline <= { pipeline[PIPELINE_PICKOFF-WIDTH:0], {WIDTH{1'b0}} };
		end
	end
endmodule

module gearbox_pipeline_tb #(
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2,
	parameter WIDTH = 4,
	parameter RATIO = 2,
	parameter EXTRA_DELAY = 0
) ();
	reg clock = 0;
	always begin
		clock <= ~clock; #HALF_CLOCK_PERIOD;
	end
	reg [WIDTH*RATIO-1:0] in = 0;
	wire [WIDTH-1:0] out;
	reg valid = 0;
	initial begin
		#(4*CLOCK_PERIOD);
		in <= 8'h00; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h01; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h02; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h04; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h08; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h10; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h20; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h40; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h80; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h00; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h00; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h0f; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'hf0; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h00; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'ha5; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h5a; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		in <= 8'h00; valid <= 1'b1; #CLOCK_PERIOD; valid <= 1'b0; #((RATIO-1)*CLOCK_PERIOD);
		#(3*EXTRA_DELAY*CLOCK_PERIOD);
		#(4*CLOCK_PERIOD);
		$finish;
	end
	gearbox_pipeline #(.WIDTH(WIDTH), .RATIO(RATIO), .EXTRA_DELAY(EXTRA_DELAY)) gp (.clock(clock), .valid(valid), .in(in), .out(out));
endmodule

// pipeline_gearbox #(.WIDTH(WIDTH), .RATIO(RATIO), .EXTRA_DELAY(3)) pg (.clock(clock), .in(in), .out(out), .valid(valid));
module pipeline_gearbox #(
	parameter WIDTH = 8,
	parameter RATIO = 3,
	parameter LOG2_OF_RATIO = $clog2(RATIO),
	parameter EXTRA_DELAY = 4,
	parameter AMOUNT = RATIO + EXTRA_DELAY,
	parameter LOG2_OF_AMOUNT = $clog2(AMOUNT),
	parameter PIPELINE_PICKOFF = WIDTH * AMOUNT - 1,
	parameter LOG2_OF_PIPELINE_PICKOFF = $clog2(PIPELINE_PICKOFF)
) (
	input clock,
	input [WIDTH-1:0] in,
	output reg [WIDTH*RATIO-1:0] out = 0,
	output reg valid = 0
);
	reg [LOG2_OF_PIPELINE_PICKOFF:0] counter = 0;
	wire [LOG2_OF_RATIO-1:0] ratio_minus_one = RATIO - 1'b1;
	wire [LOG2_OF_AMOUNT-1:0] amount = AMOUNT;
	reg [PIPELINE_PICKOFF:0] pipeline = 0;
	always @(posedge clock) begin
		valid <= 1'b0;
		if (counter==amount) begin
			counter <= counter - ratio_minus_one;
			out <= pipeline[PIPELINE_PICKOFF-:WIDTH*RATIO];
			valid <= 1'b1;
		end else begin
			counter <= counter + 1'b1;
		end
		pipeline <= { pipeline[PIPELINE_PICKOFF-WIDTH:0], in };
	end
endmodule

module pipeline_gearbox_tb #(
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2,
	parameter WIDTH = 8,
	parameter RATIO = 3,
	parameter EXTRA_DELAY = 0
) ();
	reg clock = 0;
	always begin
		clock <= ~clock; #HALF_CLOCK_PERIOD;
	end
	reg [WIDTH-1:0] in = 0;
	wire [WIDTH*RATIO-1:0] out;
	wire valid;
	initial begin
		#(4*CLOCK_PERIOD);
		in <= 8'h00; #CLOCK_PERIOD;
		in <= 8'h01; #CLOCK_PERIOD;
		in <= 8'h02; #CLOCK_PERIOD;
		in <= 8'h04; #CLOCK_PERIOD;
		in <= 8'h08; #CLOCK_PERIOD;
		in <= 8'h10; #CLOCK_PERIOD;
		in <= 8'h20; #CLOCK_PERIOD;
		in <= 8'h40; #CLOCK_PERIOD;
		in <= 8'h80; #CLOCK_PERIOD;
		in <= 8'h00; #CLOCK_PERIOD;
		in <= 8'h00; #CLOCK_PERIOD;
		in <= 8'h0f; #CLOCK_PERIOD;
		in <= 8'hf0; #CLOCK_PERIOD;
		in <= 8'h00; #CLOCK_PERIOD;
		in <= 8'ha5; #CLOCK_PERIOD;
		in <= 8'h5a; #CLOCK_PERIOD;
		in <= 8'h00; #CLOCK_PERIOD;
		#(3*EXTRA_DELAY*CLOCK_PERIOD);
		#(4*CLOCK_PERIOD);
		$finish;
	end
	pipeline_gearbox #(.WIDTH(WIDTH), .RATIO(RATIO), .EXTRA_DELAY(EXTRA_DELAY)) bob (.clock(clock), .in(in), .out(out), .valid(valid));
endmodule

// outputs n ~16th or ~256ths (per-HEX-age) instead of n ~100ths (per-CENT-age)
module duty_cycle_nw #(
	parameter ISERDES_WIDTH = 1,
	parameter LOG2_OF_ISERDES_WIDTH = $clog2(ISERDES_WIDTH),
	parameter RATIO_OF_EXAMINATION_WIDTH_TO_ISERDES_WIDTH = 4,
	parameter EXAMINATION_WIDTH = RATIO_OF_EXAMINATION_WIDTH_TO_ISERDES_WIDTH * ISERDES_WIDTH,
	parameter LOG2_OF_EXAMINATION_WIDTH = $clog2(EXAMINATION_WIDTH),
	parameter BIGGER_OF_ISERDES_WIDTH_OR_EXAMINATION_WIDTH = ISERDES_WIDTH<EXAMINATION_WIDTH ? EXAMINATION_WIDTH : ISERDES_WIDTH,
	parameter BIGGER_OF_LOG2_OF_ISERDES_WIDTH_OR_LOG2_OF_EXAMINATION_WIDTH = LOG2_OF_ISERDES_WIDTH<LOG2_OF_EXAMINATION_WIDTH ? LOG2_OF_EXAMINATION_WIDTH : LOG2_OF_ISERDES_WIDTH,
	parameter POLARITY = 1'b1,
	parameter N = 256,
	parameter LOG2_OF_N = $clog2(N),
	parameter MAX_COUNTER = {LOG2_OF_N{1'b1}},
	parameter LOG2_OF_PRIME_VALUE = 0,
	parameter METASTABILITY_DELAY = 3,
	parameter PIPELINE_PICKOFF = EXAMINATION_WIDTH * ISERDES_WIDTH + METASTABILITY_DELAY,
	parameter LOG2_OF_PIPELINE_PICKOFF = $clog2(PIPELINE_PICKOFF)
) (
	input clock,
	input [ISERDES_WIDTH-1:0] signal_in,
	output reg valid = 0,
	output [LOG2_OF_N-1:0] duty_cycle_perHEXage
);
	reg [LOG2_OF_N-1-LOG2_OF_PRIME_VALUE:0] duty_cycle_perHEXage_internal = 0;
	assign duty_cycle_perHEXage = { duty_cycle_perHEXage_internal, {LOG2_OF_PRIME_VALUE{1'b0}} };
	reg [PIPELINE_PICKOFF:0] signal_pipeline;
	wire [EXAMINATION_WIDTH-1:0] signal_word = signal_pipeline[PIPELINE_PICKOFF-:EXAMINATION_WIDTH];
	wire [LOG2_OF_ISERDES_WIDTH:0] iserdes_amount = ISERDES_WIDTH;
	wire [LOG2_OF_EXAMINATION_WIDTH:0] examination_amount = EXAMINATION_WIDTH;
	wire [LOG2_OF_ISERDES_WIDTH+LOG2_OF_EXAMINATION_WIDTH:0] amount = ISERDES_WIDTH * EXAMINATION_WIDTH;
	reg [LOG2_OF_PIPELINE_PICKOFF:0] new_bits_counter = 0;
	wire [LOG2_OF_EXAMINATION_WIDTH:0] count_word;
	count_ones #(.WIDTH(EXAMINATION_WIDTH)) myco (.clock(clock), .data_in(signal_word), .count_out(count_word));
	reg [LOG2_OF_N-1:0] accumulator = 0;
	reg [LOG2_OF_N-1+LOG2_OF_EXAMINATION_WIDTH:0] always_counter = 0;
	reg [LOG2_OF_N-1+LOG2_OF_EXAMINATION_WIDTH:0] active_counter = 0;
	reg [LOG2_OF_N-1+LOG2_OF_EXAMINATION_WIDTH:0] denominator = 0;
	reg [LOG2_OF_N-1+LOG2_OF_EXAMINATION_WIDTH-LOG2_OF_PRIME_VALUE+LOG2_OF_N:0] numerator = 0;
	always @(posedge clock) begin
		valid <= 1'b0;
		if (new_bits_counter==amount) begin
			always_counter <= always_counter + examination_amount;
			if (count_word) begin
				active_counter <= active_counter + count_word;
			end else begin
				numerator <= { active_counter, {LOG2_OF_N-LOG2_OF_PRIME_VALUE{1'b0}} };
				denominator <= always_counter;
				accumulator <= 0;
				active_counter <= 0;
				always_counter <= 0;
			end
			new_bits_counter <= new_bits_counter + iserdes_amount - examination_amount;
		end else begin
			new_bits_counter <= new_bits_counter + iserdes_amount;
		end
		if (0<denominator) begin
			if (denominator<numerator) begin
				numerator <= numerator - denominator;
				accumulator <= accumulator + 1'b1;
			end else begin
				denominator <= 0;
				duty_cycle_perHEXage_internal <= accumulator;
				valid <= 1'b1;
			end
		end
		signal_pipeline <= { signal_pipeline[PIPELINE_PICKOFF-ISERDES_WIDTH:0], signal_in };
	end
	initial begin
		$display("ISERDES_WIDTH=%d", ISERDES_WIDTH);
		$display("LOG2_OF_ISERDES_WIDTH=%d", LOG2_OF_ISERDES_WIDTH);
		$display("N=%d", N);
		$display("LOG2_OF_N=%d", LOG2_OF_N);
		$display("EXAMINATION_WIDTH=%d", EXAMINATION_WIDTH);
		$display("LOG2_OF_EXAMINATION_WIDTH=%d", LOG2_OF_EXAMINATION_WIDTH);
		$display("BIGGER_OF_ISERDES_WIDTH_OR_EXAMINATION_WIDTH=%d", BIGGER_OF_ISERDES_WIDTH_OR_EXAMINATION_WIDTH);
		$display("BIGGER_OF_LOG2_OF_ISERDES_WIDTH_OR_LOG2_OF_EXAMINATION_WIDTH=%d", BIGGER_OF_LOG2_OF_ISERDES_WIDTH_OR_LOG2_OF_EXAMINATION_WIDTH);
	end
endmodule

module duty_cycle_nw_tb #(
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2,
	parameter N = 16,
	parameter LOG2_OF_N = $clog2(N),
	parameter STEP = 1,
	parameter WAVEFORM_LENGTH = N + 7,
	parameter W = WAVEFORM_LENGTH,
	parameter WAIT_PERIOD = 7.1 * WAVEFORM_LENGTH * CLOCK_PERIOD
);
	reg clock = 0, clock_word4 = 0, clock_word3 = 0;
	always begin
		clock <= ~clock; #HALF_CLOCK_PERIOD;
	end
	always begin
		clock_word4 <= ~clock_word4; #(HALF_CLOCK_PERIOD*4);
	end
	always begin
		clock_word3 <= ~clock_word3; #(HALF_CLOCK_PERIOD*3);
	end
	reg [0:WAVEFORM_LENGTH-1] waveform = 0;
	reg [LOG2_OF_N-1:0] counter = 0;
	reg [LOG2_OF_N-1:0] counter4 = 0;
	reg [LOG2_OF_N-1:0] counter3 = 0;
	reg signal = 0;
	reg [4-1:0] signal_word4 = 0;
	reg [3-1:0] signal_word3 = 0;
	always @(posedge clock) begin
		signal <= waveform[counter];
		counter <= counter + 1'b1;
	end
	always @(posedge clock_word4) begin
		signal_word4 <= waveform[counter4+:4];
		if (counter4<N-4) begin
			counter4 <= counter4 + 3'd4;
		end else begin
			counter4 <= 0;
		end
	end
	always @(posedge clock_word3) begin
		signal_word3 <= waveform[counter3+:3];
		if (counter3<N-3) begin
			counter3 <= counter3 + 2'd3;
		end else begin
			counter3 <= 0;
		end
	end
	wire [LOG2_OF_N-1:0] duty_cycle_perHEXage_iserdes_1_2, duty_cycle_perHEXage_single_4_8, duty_cycle_perHEXage_single_3_5;
	wire valid_single_1_2, valid_iserdes_4_8, valid_iserdes_3_5;
	integer j, truth = 0;
	initial begin
		#WAIT_PERIOD;
		for (truth=0; truth<=W; truth=truth+STEP) begin
			for (j=0; j<truth; j=j+1) begin waveform[j] <= 1'b1; end;
			for (j=truth; j<W; j=j+1) begin waveform[j] <= 1'b0; end;
			#WAIT_PERIOD;
		end;
		#WAIT_PERIOD;
		truth = 13;
		for (j=0; j<truth; j=j+1) begin waveform[j] <= 1'b1; end;
		for (j=truth; j<W; j=j+1) begin waveform[j] <= 1'b0; end;
		#WAIT_PERIOD;
		truth = 0;
		for (j=0; j<truth; j=j+1) begin waveform[j] <= 1'b1; end;
		for (j=truth; j<W; j=j+1) begin waveform[j] <= 1'b0; end;
		#WAIT_PERIOD; $finish;
	end
	duty_cycle_nw #(.N(N), .ISERDES_WIDTH(1), .RATIO_OF_EXAMINATION_WIDTH_TO_ISERDES_WIDTH(2)) mdc_single_1_2 (.clock(clock), .signal_in(signal), .duty_cycle_perHEXage(duty_cycle_perHEXage_single_1_2), .valid(valid_single_1_2));
	duty_cycle_nw #(.N(N), .ISERDES_WIDTH(4), .RATIO_OF_EXAMINATION_WIDTH_TO_ISERDES_WIDTH(2)) mdc_iserdes4_8 (.clock(clock_word4), .signal_in(signal_word4), .duty_cycle_perHEXage(duty_cycle_perHEXage_iserdes_4_8), .valid(valid_iserdes_4_8));
	duty_cycle_nw #(.N(N), .ISERDES_WIDTH(3), .RATIO_OF_EXAMINATION_WIDTH_TO_ISERDES_WIDTH(2)) mdc_iserdes3_5 (.clock(clock_word3), .signal_in(signal_word3), .duty_cycle_perHEXage(duty_cycle_perHEXage_iserdes_3_5), .valid(valid_iserdes_3_5));
endmodule

// outputs n ~16th or ~256ths (per-HEX-age) instead of n ~100ths (per-CENT-age)
module duty_cycle #(
	parameter POLARITY = 1'b1,
	parameter N = 256,
	parameter LOG_BASE_2_OF_N = $clog2(N),
	parameter MAX_COUNTER = {LOG_BASE_2_OF_N{1'b1}},
	parameter LOG2_OF_PRIME_VALUE = 0,
	parameter PATTERN_LENGTH = 4,
	parameter PATTERN_GOING_ACTIVE = { ~POLARITY, ~POLARITY, POLARITY, POLARITY },
	parameter PATTERN_GOING_INACTIVE = { POLARITY, POLARITY, ~POLARITY, ~POLARITY },
	parameter METASTABILITY_DELAY = 3,
	parameter PIPELINE_PICKOFF = PATTERN_LENGTH + METASTABILITY_DELAY
) (
	input clock, signal_in,
	output reg valid = 0,
	output [LOG_BASE_2_OF_N-1:0] duty_cycle_perHEXage
);
	reg [LOG_BASE_2_OF_N-1-LOG2_OF_PRIME_VALUE:0] duty_cycle_perHEXage_internal = 0;
	assign duty_cycle_perHEXage = { duty_cycle_perHEXage_internal, {LOG2_OF_PRIME_VALUE{1'b0}} };
	reg [PIPELINE_PICKOFF:0] signal_pipeline;
	reg mode = 0;
	reg [LOG_BASE_2_OF_N-1:0] active_counter = 0;
	reg [LOG_BASE_2_OF_N-1:0] always_counter = 1'b1;
	reg [LOG_BASE_2_OF_N-1:0] denominator = 0;
	reg [LOG_BASE_2_OF_N-1-LOG2_OF_PRIME_VALUE+LOG_BASE_2_OF_N:0] numerator = 0;
	reg [LOG_BASE_2_OF_N-1-LOG2_OF_PRIME_VALUE:0] accumulator = 0;
	always @(posedge clock) begin
		valid <= 0;
		if (signal_pipeline[PIPELINE_PICKOFF-:PATTERN_LENGTH]==PATTERN_GOING_ACTIVE) begin
			mode <= 1'b1;
		end else if (signal_pipeline[PIPELINE_PICKOFF-:PATTERN_LENGTH]==PATTERN_GOING_INACTIVE) begin
			mode <= 1'b0;
			numerator <= { active_counter, {LOG_BASE_2_OF_N-LOG2_OF_PRIME_VALUE{1'b0}} };
			denominator <= always_counter;
			accumulator <= 0;
			active_counter <= 1'b1;
			always_counter <= 1'b1;
		end else begin
			if (0<denominator) begin
				if (denominator<numerator) begin
					numerator <= numerator - denominator;
					accumulator <= accumulator + 1'b1;
				end else begin
					denominator <= 0;
					duty_cycle_perHEXage_internal <= accumulator;
					valid <= 1'b1;
				end
			end
			if (always_counter<MAX_COUNTER) begin
				always_counter <= always_counter + 1'b1;
			end
			if (mode) begin // signal active
				if (active_counter<MAX_COUNTER) begin
					active_counter <= active_counter + 1'b1;
				end else begin // active_counter==MAX_COUNTER
					denominator <= 0;
					duty_cycle_perHEXage_internal <= MAX_COUNTER;
					valid <= 1'b1;
					active_counter <= 1'b1;
					always_counter <= 1'b1;
				end
			end else begin // signal inactive
				if (always_counter==MAX_COUNTER) begin
					denominator <= 0;
					duty_cycle_perHEXage_internal <= 0;
					valid <= 1'b1;
					active_counter <= 1'b1;
					always_counter <= 1'b1;
				end
			end
		end
		signal_pipeline <= { signal_pipeline[PIPELINE_PICKOFF-1:0], signal_in };
	end
endmodule

module duty_cycle_tb #(
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2,
	parameter N = 16,
	parameter LOG_BASE_2_OF_N = $clog2(N),
	parameter STEP = 4,
	parameter WAVEFORM_LENGTH = N,
	parameter LOG2_OF_WAVEFORM_LENGTH = $clog2(WAVEFORM_LENGTH),
	parameter WAIT_PERIOD = 7.1 * WAVEFORM_LENGTH * CLOCK_PERIOD
);
	reg clock = 0;
	always begin
		clock <= ~clock; #HALF_CLOCK_PERIOD;
	end
	reg signal = 0;
	reg [WAVEFORM_LENGTH-1:0] waveform = 0;
	reg [LOG2_OF_WAVEFORM_LENGTH-1:0] counter = 0;
	always @(posedge clock) begin
		signal <= waveform[counter];
		counter <= counter + 1'b1;
	end
	wire [LOG_BASE_2_OF_N-1:0] duty_cycle_perHEXage;
	wire valid;
	integer j, truth = 0;
	initial begin
		#WAIT_PERIOD;
		for (truth=0; truth<=N; truth=truth+STEP) begin
			for (j=0; j<truth; j=j+1) begin waveform[j] <= 1'b1; end;
			for (j=truth; j<N; j=j+1) begin waveform[j] <= 1'b0; end;
			#WAIT_PERIOD;
		end;
		#WAIT_PERIOD;
		truth = 13;
		for (j=0; j<truth; j=j+1) begin waveform[j] <= 1'b1; end;
		for (j=truth; j<N; j=j+1) begin waveform[j] <= 1'b0; end;
		#WAIT_PERIOD;
		truth = 0;
		for (j=0; j<truth; j=j+1) begin waveform[j] <= 1'b1; end;
		for (j=truth; j<N; j=j+1) begin waveform[j] <= 1'b0; end;
		#WAIT_PERIOD; $finish;
	end
	duty_cycle #(.N(N)) mdc (.clock(clock), .signal_in(signal), .duty_cycle_perHEXage(duty_cycle_perHEXage), .valid(valid));
endmodule

module counter_level #(
	parameter POLARITY = 1,
	parameter WIDTH = 32
) (
	input clock, reset, in,
	output reg [WIDTH-1:0] counter = 0
);
	always @(posedge clock) begin
		if (reset) begin
			counter <= 0;
		end else begin
			if (in==POLARITY) begin
				counter <= counter + 1'b1;
			end
		end
	end
endmodule

module counter_edge #(
	parameter POLARITY = 1, // 1 means 0-to-1 transition
	parameter PIPELINE_PICKOFF = 4,
	parameter WIDTH = 32
) (
	input clock, reset, in,
	output reg [WIDTH-1:0] counter = 0
);
	reg [PIPELINE_PICKOFF:0] pipeline = 0;
	always @(posedge clock) begin
		if (reset) begin
			counter <= 0;
			pipeline <= 0;
		end else begin
			pipeline <= { pipeline[PIPELINE_PICKOFF-1:0], in };
			if (pipeline[PIPELINE_PICKOFF:PIPELINE_PICKOFF-1]=={~POLARITY,POLARITY}) begin
				counter <= counter + 1'b1;
			end
		end
	end
endmodule

//	mux #(.WIDTH(8)) mymux (.I0(), .I1(), .S(), .O());
module mux #(
	parameter WIDTH = 1
) (
	input S,
	input [WIDTH-1:0] I0, I1,
	output [WIDTH-1:0] O
);
	assign O = S ? I1 : I0;
endmodule

//	mux_2to1 #(.WIDTH(8)) mymux (.in0(), .in1(), .sel(), .out());
module mux_2to1 #(
	parameter WIDTH = 1
) (
	input sel,
	input [WIDTH-1:0] in0, in1,
	output [WIDTH-1:0] out
);
	assign out = sel ? in1 : in0;
endmodule

module mux_4to1 #(
	parameter WIDTH = 1
) (
	input [WIDTH-1:0] in0, in1, in2, in3,
	input [1:0] sel,
	output [WIDTH-1:0] out
);
	assign out =
		(sel==2'd0) ? in0 :
		(sel==2'd1) ? in1 :
		(sel==2'd2) ? in2 :
		              in3 ;
endmodule

module mux_8to1 #(
	parameter WIDTH = 1
) (
	input [WIDTH-1:0] in0, in1, in2, in3, in4, in5, in6, in7,
	input [2:0] sel,
	output [WIDTH-1:0] out
);
	assign out =
		(sel==3'd0) ? in0 :
		(sel==3'd1) ? in1 :
		(sel==3'd2) ? in2 :
		(sel==3'd3) ? in3 :
		(sel==3'd4) ? in4 :
		(sel==3'd5) ? in5 :
		(sel==3'd6) ? in6 :
		              in7;
endmodule

module mux_16to1 #(
	parameter WIDTH = 1
) (
	input [WIDTH-1:0]
		in00, in01, in02, in03, in04, in05, in06, in07,
		in08, in09, in10, in11, in12, in13, in14, in15,
	input [3:0] sel,
	output [WIDTH-1:0] out
);
	assign out =
		(sel==4'd00) ? in00 :
		(sel==4'd01) ? in01 :
		(sel==4'd02) ? in02 :
		(sel==4'd03) ? in03 :
		(sel==4'd04) ? in04 :
		(sel==4'd05) ? in05 :
		(sel==4'd06) ? in06 :
		(sel==4'd07) ? in07 :
		(sel==4'd08) ? in08 :
		(sel==4'd09) ? in09 :
		(sel==4'd10) ? in10 :
		(sel==4'd11) ? in11 :
		(sel==4'd12) ? in12 :
		(sel==4'd13) ? in13 :
		(sel==4'd14) ? in14 :
		               in15;
endmodule

module mux_32to1 #(
	parameter WIDTH = 1
) (
	input [WIDTH-1:0]
		in00, in01, in02, in03, in04, in05, in06, in07,
		in08, in09, in10, in11, in12, in13, in14, in15,
		in16, in17, in18, in19, in20, in21, in22, in23,
		in24, in25, in26, in27, in28, in29, in30, in31,
	input [4:0] sel,
	output [WIDTH-1:0] out
);
	assign out =
		(sel==5'd00) ? in00 :
		(sel==5'd01) ? in01 :
		(sel==5'd02) ? in02 :
		(sel==5'd03) ? in03 :
		(sel==5'd04) ? in04 :
		(sel==5'd05) ? in05 :
		(sel==5'd06) ? in06 :
		(sel==5'd07) ? in07 :
		(sel==5'd08) ? in08 :
		(sel==5'd09) ? in09 :
		(sel==5'd10) ? in10 :
		(sel==5'd11) ? in11 :
		(sel==5'd12) ? in12 :
		(sel==5'd13) ? in13 :
		(sel==5'd14) ? in14 :
		(sel==5'd15) ? in15 :
		(sel==5'd16) ? in16 :
		(sel==5'd17) ? in17 :
		(sel==5'd18) ? in18 :
		(sel==5'd19) ? in19 :
		(sel==5'd20) ? in20 :
		(sel==5'd21) ? in21 :
		(sel==5'd22) ? in22 :
		(sel==5'd23) ? in23 :
		(sel==5'd24) ? in24 :
		(sel==5'd25) ? in25 :
		(sel==5'd26) ? in26 :
		(sel==5'd27) ? in27 :
		(sel==5'd28) ? in28 :
		(sel==5'd29) ? in29 :
		(sel==5'd30) ? in30 :
		               in31;
endmodule

module mux_8to1_tb;
	wire out;
	reg a, b, c, d, e, f, g, h;
	reg [2:0] sel = 3'd0;
	initial begin
		#1; sel <= 3'd0; a <= 0; b <= 0; c <= 0; d <= 0; e <= 0; f <= 0; g <= 0; h <= 0;
		// individual ones:
		#1; sel <= 3'd0; a <= 1; b <= 0; c <= 0; d <= 0; e <= 0; f <= 0; g <= 0; h <= 0;
		#1; sel <= 3'd1; a <= 0; b <= 1; c <= 0; d <= 0; e <= 0; f <= 0; g <= 0; h <= 0;
		#1; sel <= 3'd2; a <= 0; b <= 0; c <= 1; d <= 0; e <= 0; f <= 0; g <= 0; h <= 0;
		#1; sel <= 3'd3; a <= 0; b <= 0; c <= 0; d <= 1; e <= 0; f <= 0; g <= 0; h <= 0;
		#1; sel <= 3'd4; a <= 0; b <= 0; c <= 0; d <= 0; e <= 1; f <= 0; g <= 0; h <= 0;
		#1; sel <= 3'd5; a <= 0; b <= 0; c <= 0; d <= 0; e <= 0; f <= 1; g <= 0; h <= 0;
		#1; sel <= 3'd6; a <= 0; b <= 0; c <= 0; d <= 0; e <= 0; f <= 0; g <= 1; h <= 0;
		#1; sel <= 3'd7; a <= 0; b <= 0; c <= 0; d <= 0; e <= 0; f <= 0; g <= 0; h <= 1;
		// individual zeroes:
		#1; sel <= 3'd0; a <= 0; b <= 1; c <= 1; d <= 1; e <= 1; f <= 1; g <= 1; h <= 1;
		#1; sel <= 3'd1; a <= 1; b <= 0; c <= 1; d <= 1; e <= 1; f <= 1; g <= 1; h <= 1;
		#1; sel <= 3'd2; a <= 1; b <= 1; c <= 0; d <= 1; e <= 1; f <= 1; g <= 1; h <= 1;
		#1; sel <= 3'd3; a <= 1; b <= 1; c <= 1; d <= 0; e <= 1; f <= 1; g <= 1; h <= 1;
		#1; sel <= 3'd4; a <= 1; b <= 1; c <= 1; d <= 1; e <= 0; f <= 1; g <= 1; h <= 1;
		#1; sel <= 3'd5; a <= 1; b <= 1; c <= 1; d <= 1; e <= 1; f <= 0; g <= 1; h <= 1;
		#1; sel <= 3'd6; a <= 1; b <= 1; c <= 1; d <= 1; e <= 1; f <= 1; g <= 0; h <= 1;
		#1; sel <= 3'd7; a <= 1; b <= 1; c <= 1; d <= 1; e <= 1; f <= 1; g <= 1; h <= 0;
	end
	mux_8to1 tst (.in0(a), .in1(b), .in2(c), .in3(d), .in4(e), .in5(f), .in6(g), .in7(h), .sel(sel), .out(out));
endmodule

module demux_1to2 #(
	parameter WIDTH = 1,
	parameter [WIDTH-1:0] default_value = 0
) (
	input [WIDTH-1:0] in,
	input [0:0] sel,
	output [WIDTH-1:0] out0, out1
);
	assign out0 = (sel==3'd0) ? in : default_value;
	assign out1 = (sel==3'd1) ? in : default_value;
endmodule

module demux_1to4 #(
	parameter WIDTH = 1,
	parameter [WIDTH-1:0] default_value = 0
) (
	input [WIDTH-1:0] in,
	input [1:0] sel,
	output [WIDTH-1:0] out0, out1, out2, out3
);
	assign out0 = (sel==3'd0) ? in : default_value;
	assign out1 = (sel==3'd1) ? in : default_value;
	assign out2 = (sel==3'd2) ? in : default_value;
	assign out3 = (sel==3'd3) ? in : default_value;
endmodule

module demux_1to8 #(
	parameter WIDTH = 1,
	parameter [WIDTH-1:0] default_value = 0
) (
	input [WIDTH-1:0] in,
	input [2:0] sel,
	output [WIDTH-1:0] out0, out1, out2, out3, out4, out5, out6, out7
);
	assign out0 = (sel==3'd0) ? in : default_value;
	assign out1 = (sel==3'd1) ? in : default_value;
	assign out2 = (sel==3'd2) ? in : default_value;
	assign out3 = (sel==3'd3) ? in : default_value;
	assign out4 = (sel==3'd4) ? in : default_value;
	assign out5 = (sel==3'd5) ? in : default_value;
	assign out6 = (sel==3'd6) ? in : default_value;
	assign out7 = (sel==3'd7) ? in : default_value;
endmodule

module demux_1to16 #(
	parameter WIDTH = 1,
	parameter [WIDTH-1:0] default_value = 0
) (
	input [WIDTH-1:0] in,
	input [3:0] sel,
	output [WIDTH-1:0]
		out00, out01, out02, out03, out04, out05, out06, out07,
		out08, out09, out10, out11, out12, out13, out14, out15
);
	assign out00 = (sel==4'd00) ? in : default_value;
	assign out01 = (sel==4'd01) ? in : default_value;
	assign out02 = (sel==4'd02) ? in : default_value;
	assign out03 = (sel==4'd03) ? in : default_value;
	assign out04 = (sel==4'd04) ? in : default_value;
	assign out05 = (sel==4'd05) ? in : default_value;
	assign out06 = (sel==4'd06) ? in : default_value;
	assign out07 = (sel==4'd07) ? in : default_value;
	assign out08 = (sel==4'd08) ? in : default_value;
	assign out09 = (sel==4'd09) ? in : default_value;
	assign out10 = (sel==4'd10) ? in : default_value;
	assign out11 = (sel==4'd11) ? in : default_value;
	assign out12 = (sel==4'd12) ? in : default_value;
	assign out13 = (sel==4'd13) ? in : default_value;
	assign out14 = (sel==4'd14) ? in : default_value;
	assign out15 = (sel==4'd15) ? in : default_value;
endmodule

module demux_1to32 #(
	parameter WIDTH = 1,
	parameter [WIDTH-1:0] default_value = 0
) (
	input [WIDTH-1:0] in,
	input [4:0] sel,
	output [WIDTH-1:0]
		out00, out01, out02, out03, out04, out05, out06, out07,
		out08, out09, out10, out11, out12, out13, out14, out15,
		out16, out17, out18, out19, out20, out21, out22, out23,
		out24, out25, out26, out27, out28, out29, out30, out31
);
	assign out00 = (sel==5'd00) ? in : default_value;
	assign out01 = (sel==5'd01) ? in : default_value;
	assign out02 = (sel==5'd02) ? in : default_value;
	assign out03 = (sel==5'd03) ? in : default_value;
	assign out04 = (sel==5'd04) ? in : default_value;
	assign out05 = (sel==5'd05) ? in : default_value;
	assign out06 = (sel==5'd06) ? in : default_value;
	assign out07 = (sel==5'd07) ? in : default_value;
	assign out08 = (sel==5'd08) ? in : default_value;
	assign out09 = (sel==5'd09) ? in : default_value;
	assign out10 = (sel==5'd10) ? in : default_value;
	assign out11 = (sel==5'd11) ? in : default_value;
	assign out12 = (sel==5'd12) ? in : default_value;
	assign out13 = (sel==5'd13) ? in : default_value;
	assign out14 = (sel==5'd14) ? in : default_value;
	assign out15 = (sel==5'd15) ? in : default_value;
	assign out16 = (sel==5'd16) ? in : default_value;
	assign out17 = (sel==5'd17) ? in : default_value;
	assign out18 = (sel==5'd18) ? in : default_value;
	assign out19 = (sel==5'd19) ? in : default_value;
	assign out20 = (sel==5'd20) ? in : default_value;
	assign out21 = (sel==5'd21) ? in : default_value;
	assign out22 = (sel==5'd22) ? in : default_value;
	assign out23 = (sel==5'd23) ? in : default_value;
	assign out24 = (sel==5'd24) ? in : default_value;
	assign out25 = (sel==5'd25) ? in : default_value;
	assign out26 = (sel==5'd26) ? in : default_value;
	assign out27 = (sel==5'd27) ? in : default_value;
	assign out28 = (sel==5'd28) ? in : default_value;
	assign out29 = (sel==5'd29) ? in : default_value;
	assign out30 = (sel==5'd30) ? in : default_value;
	assign out31 = (sel==5'd31) ? in : default_value;
endmodule

module demux_1to8_tb;
	reg [2:0] in;
	wire [2:0] a, b, c, d, e, f, g, h;
	reg [2:0] sel = 3'd0;
	initial begin
		in <= 0;
		#1; sel <= 3'd0;
		#1; sel <= 3'd1;
		#1; sel <= 3'd2;
		#1; sel <= 3'd3;
		#1; sel <= 3'd4;
		#1; sel <= 3'd5;
		#1; sel <= 3'd6;
		#1; sel <= 3'd7;
		//
		#1; sel <= 3'd7;
		#1; sel <= 3'd6;
		#1; sel <= 3'd5;
		#1; sel <= 3'd4;
		#1; sel <= 3'd3;
		#1; sel <= 3'd2;
		#1; sel <= 3'd1;
		#1; sel <= 3'd0;
	end
	always begin
		#1;
		in <= in + 1;
	end
	demux_1to8 #(.WIDTH(3)) tst (
		.in(in), .sel(sel),
		.out0(a), .out1(b), .out2(c), .out3(d),
		.out4(e), .out5(f), .out6(g), .out7(h));
endmodule

module and_gate #(
	parameter DELAY_RISE = 0.5,
	parameter DELAY_FALL = 0.5,
	parameter TESTBENCH = 0
) (
	input I0,
	input I1,
	output O
);
	wire O0;
	if (TESTBENCH) begin
		reg O0_prev = 0;
		reg O1 = 0;
		always begin
			case ({ O0_prev, O0 })
				2'b00:   begin #DELAY_RISE; O0_prev <= O0; end
				2'b01:   begin #DELAY_RISE; O1 <= O0; O0_prev <= O0; end
				2'b10:   begin #DELAY_FALL; O1 <= O0; O0_prev <= O0; end
				default: begin #DELAY_RISE; O0_prev <= O0; end
			endcase
		end
		assign O = O1;
	end else begin
		assign O = O0;
	end
`ifdef XILINX
	// from Xilinx HDL Libraries Guide, version 14.5 
	LUT5 #(
		//.INIT(32'h00000008) // Specify LUT Contents
		.INIT(32'b00000000000000000000000000001000) // Specify LUT Contents
	) LUT5_inst (
		.O(O0), // LUT general output
		.I0(I0), // LUT input
		.I1(I1), // LUT input
		.I2(1'b0), // LUT input
		.I3(1'b0), // LUT input
		.I4(1'b0)  // LUT input
	);
`endif
endmodule

// idea from Ken Chapman's solution here: https://forums.xilinx.com/t5/Other-FPGA-Architecture/How-to-implement-a-ring-oscillator-with-routings-of-FPGA-Where/m-p/768895/highlight/true#M21839
module ring_oscillator #(
	parameter number_of_bits_for_coarse_stages = 3,
	parameter number_of_bits_for_medium_stages = 3,
	parameter number_of_bits_for_fine_stages = 3,
	parameter number_of_bits = number_of_bits_for_coarse_stages + number_of_bits_for_medium_stages + number_of_bits_for_fine_stages,
//	parameter number_of_coarse_stages = 8,
//	parameter number_of_medium_stages = 8,
//	parameter number_of_fine_stages = 8,
//	parameter number_of_stages = number_of_coarse_stages + number_of_medium_stages + number_of_fine_stages,
	parameter TESTBENCH = 0
) (
	input enable,
//	input [$clog2(number_of_stages)-1:0] select,
	input [number_of_bits-1:0] select,
	output clock_out
);
	localparam number_of_coarse_stages = 2**number_of_bits_for_coarse_stages;
	localparam number_of_medium_stages = 2**number_of_bits_for_medium_stages;
	localparam number_of_fine_stages = 2**number_of_bits_for_fine_stages;
	localparam number_of_stages = number_of_coarse_stages + number_of_medium_stages + number_of_fine_stages;
	wire [number_of_stages-1:0] stage;
	genvar i;
	localparam COARSE_DELAY = 10.0;
	localparam MEDIUM_DELAY = 2.0;
	localparam FINE_DELAY = 0.5;
	wire [number_of_bits_for_coarse_stages-1:0] select_coarse = select[number_of_bits-1:number_of_bits_for_medium_stages+number_of_bits_for_fine_stages];
	wire [number_of_bits_for_medium_stages-1:0] select_medium = select[number_of_bits-number_of_bits_for_coarse_stages-1:number_of_bits_for_fine_stages];
	wire [number_of_bits_for_fine_stages-1:0] select_fine = select[number_of_bits_for_fine_stages-1:0];
	for (i=0; i<number_of_coarse_stages-1; i=i+2) begin : coarse_feedback_even
		and_gate #(.DELAY_RISE(COARSE_DELAY), .DELAY_FALL(COARSE_DELAY), .TESTBENCH(TESTBENCH)) coarse (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	for (i=1; i<number_of_coarse_stages-1; i=i+2) begin : coarse_feedback_odd
		and_gate #(.DELAY_RISE(COARSE_DELAY), .DELAY_FALL(COARSE_DELAY), .TESTBENCH(TESTBENCH)) coarse (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	and_gate #(.DELAY_RISE(COARSE_DELAY), .DELAY_FALL(COARSE_DELAY), .TESTBENCH(TESTBENCH)) coarse_bride (.I0(stage[select_coarse]), .I1(enable), .O(stage[number_of_coarse_stages]));
	wire aftercoarse = stage[number_of_coarse_stages];
	for (i=number_of_coarse_stages; i<number_of_coarse_stages+number_of_medium_stages-1; i=i+2) begin : medium_feedback_even
		and_gate #(.DELAY_RISE(MEDIUM_DELAY), .DELAY_FALL(MEDIUM_DELAY), .TESTBENCH(TESTBENCH)) mediumm (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	for (i=number_of_coarse_stages+1; i<number_of_coarse_stages+number_of_medium_stages-1; i=i+2) begin : medium_feedback_odd
		and_gate #(.DELAY_RISE(MEDIUM_DELAY), .DELAY_FALL(MEDIUM_DELAY), .TESTBENCH(TESTBENCH)) mediumm (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	and_gate #(.DELAY_RISE(MEDIUM_DELAY), .DELAY_FALL(MEDIUM_DELAY), .TESTBENCH(TESTBENCH)) mediumm_bride (.I0(stage[number_of_coarse_stages+select_medium]), .I1(enable), .O(stage[number_of_coarse_stages+number_of_medium_stages]));
	wire aftermedium = stage[number_of_coarse_stages+number_of_medium_stages];
	for (i=number_of_coarse_stages+number_of_medium_stages; i<number_of_stages-1; i=i+2) begin : fine_feedback_even
		and_gate #(.DELAY_RISE(FINE_DELAY), .DELAY_FALL(FINE_DELAY), .TESTBENCH(TESTBENCH)) fine (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	for (i=number_of_coarse_stages+number_of_medium_stages+1; i<number_of_stages-1; i=i+2) begin : fine_feedback_odd
		and_gate #(.DELAY_RISE(FINE_DELAY), .DELAY_FALL(FINE_DELAY), .TESTBENCH(TESTBENCH)) fine (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	and_gate #(.DELAY_RISE(FINE_DELAY), .DELAY_FALL(FINE_DELAY), .TESTBENCH(TESTBENCH)) fine_bride (.I0(~stage[number_of_coarse_stages+number_of_medium_stages+select_fine]), .I1(enable), .O(stage[0]));
	wire afterfine = stage[0];
	assign clock_out = stage[0];
endmodule

module ring_oscillator_tb;
	wire clock;
	reg enable = 0;
	reg [3:0] select_coarse = 4'd0;
	reg [1:0] select_medium = 2'd0;
	reg [1:0] select_fine = 2'd0;
	wire [7:0] select = { select_coarse, select_medium, select_fine };
	ring_oscillator #(.number_of_bits_for_coarse_stages(4), .number_of_bits_for_medium_stages(2), .number_of_bits_for_fine_stages(2), .TESTBENCH(1)) ro (.enable(enable), .select(select), .clock_out(clock));
	initial begin
		#20;
		enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd00; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd01; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd02; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd03; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd04; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd05; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd06; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd07; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd08; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd09; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd10; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd11; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd12; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd13; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd14; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd15; #100; enable <= 1;
		#4000;
		#2000; enable <= 0; select_medium <= 2'd0; #100; enable <= 1;
		#2000; enable <= 0; select_medium <= 2'd1; #100; enable <= 1;
		#2000; enable <= 0; select_medium <= 2'd2; #100; enable <= 1;
		#2000; enable <= 0; select_medium <= 2'd3; #100; enable <= 1;
		#4000;
		#2000; enable <= 0; select_fine <= 2'd0; #100; enable <= 1;
		#2000; enable <= 0; select_fine <= 2'd1; #100; enable <= 1;
		#2000; enable <= 0; select_fine <= 2'd2; #100; enable <= 1;
		#2000; enable <= 0; select_fine <= 2'd3; #100; enable <= 1;
		#4000;
		enable <= 0;
		#20;
		$finish;
	end
endmodule

//	bus_entry_3state #(.WIDTH(7)) my3sbe (.I(pre_bus), .O(bus), .T(write));
module bus_entry_3state #(
	parameter WIDTH = 8
) (
	input [WIDTH-1:0] I,
	input T,
	inout [WIDTH-1:0] O
);
	assign O = T ? I : {WIDTH{1'bz}};
endmodule

//module bidirectional_bus #(
//	parameter WIDTH = 8
//) (
//	inout [WIDTH-1:0] A,
//	inout [WIDTH-1:0] B,
//	input direction
//);
//	assign A =  direction ? B : {WIDTH{1'bz}};
//	assign B = ~direction ? A : {WIDTH{1'bz}};
////	always @(direction) begin
////	if (direction) begin
////		assign A = B;
////	end else begin
////		assign B = A;
////	end
//endmodule

//module bidirectional_bus_tb;
//	localparam WIDTH = 8;
//	reg [WIDTH-1:0] pre_A = 0;
//	reg [WIDTH-1:0] pre_B = 0;
//	wire [WIDTH-1:0] A;
//	wire [WIDTH-1:0] B;
//	reg direction = 0;
//	bidirectional_bus #(.WIDTH(8)) bdb (.A(A), .B(B), .direction(direction));
//	initial begin
//		#100;
//		pre_A <= 8'h45;
//		#100;
//		pre_B <= 8'h78;
//		#100;
//		direction <= 1;
//		assign B = pre_B;
//		#100;
//		direction <= 0;
//		assign A = pre_A;
//		assign B = {WIDTH{1'bz}};
//	end
//endmodule

module clock #(
	parameter FREQUENCY_OF_CLOCK_HZ = 10000000.0,
	parameter PERIOD_OF_CLOCK_NS = 1000000000.0/FREQUENCY_OF_CLOCK_HZ, // WHOLE_PERIOD
	parameter HALF_PERIOD_OF_CLOCK_NS = PERIOD_OF_CLOCK_NS / 2.0
) (
	output reg clock = 0
);
	initial begin
		$display("creating clock with half period of %f ns", HALF_PERIOD_OF_CLOCK_NS);
	end
	always begin
		#HALF_PERIOD_OF_CLOCK_NS;
		clock = ~clock;
	end
endmodule

//	clock_ODDR_out_diff sstclk_ODDR  (.clock_in_p(sstclk), .clock_in_n(sstclk180), .clock_enable(regen_copy_on_sstclk), .clock_out_p(sstclk_p), .clock_out_n(sstclk_n));
module clock_ODDR_out_diff #(
	parameter SERIES = "spartan6"
) (
	input clock_in_n, clock_in_p,
	input clock_enable,
	output clock_out_p, clock_out_n
);
	wire clock_out;
	if (SERIES=="spartan6") begin
		ODDR2 #(.DDR_ALIGNMENT("NONE")) oddr2_clock (.C0(clock_in_p), .C1(clock_in_n), .CE(clock_enable), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0), .Q(clock_out));
//	end else begin
//		ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_clock (.C(clock), .CE(clock_enable), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(clock_out));
	end
	OBUFDS obuf_clock (.I(clock_out), .O(clock_out_p), .OB(clock_out_n));
endmodule

//	clock_ODDR_out sstclk_ODDR_second_copy  (.clock_in_p(sstclk),  .clock_in_n(sstclk180), .clock_enable(regen_copy_on_sstclk), .clock_out(coax[0]));
module clock_ODDR_out #(
	parameter SERIES = "spartan6"
) (
	input clock_in_n, clock_in_p,
	input clock_enable,
	output clock_out
);
	if (SERIES=="spartan6") begin
		ODDR2 #(.DDR_ALIGNMENT("NONE")) oddr2_clock (.C0(clock_in_p), .C1(clock_in_n), .CE(clock_enable), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0), .Q(clock_out));
//	end else begin
//		ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_clock (.C(clock), .CE(1'b1), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(clock_out));
	end
endmodule

//	myoddr oddr1 (.clock(clock127), .out(asic1_clock));
// for 7-series:
module myoddr #(
	POLARITY = 1'b1
) (
	input clock,
	output out
);
//	ODDR myodor (.D1(1'b1), .D2(1'b0), .C(clock), .CE(1'b1), .Q(out), .R(1'b0), .S(1'b0));
//	ODDR myodor (.D1(POLARITY), .D2(~POLARITY), .C(clock), .CE(1'b1), .Q(out), .R(1'b0), .S(1'b0));
	ODDR #(.INIT(~POLARITY)) myodor (.D1(POLARITY), .D2(~POLARITY), .C(clock), .CE(1'b1), .Q(out), .R(1'b0), .S(1'b0));
endmodule

module myoddr_tb;
	localparam CLOCK_PERIOD = 1.0;
	localparam HALF_CLOCK_PERIOD = CLOCK_PERIOD/2.0;
	reg clock127 = 0;
	wire asic1_clock, asic2_clock, asic3_clock, asic4_clock;
	always begin
		#HALF_CLOCK_PERIOD; clock127 <= ~clock127;
	end
	myoddr #(.POLARITY(1'b1)) oddr1 (.clock(clock127), .out(asic1_clock));
	myoddr #(.POLARITY(1'b1)) oddr2 (.clock(clock127), .out(asic2_clock));
	myoddr #(.POLARITY(1'b1)) oddr3 (.clock(clock127), .out(asic3_clock));
	myoddr #(.POLARITY(1'b0)) oddr4 (.clock(clock127), .out(asic4_clock));
endmodule

//	ddr mario (.clock(clock), .data0_in(), .data1_in(), .data_out());
module ddr (
	input clock,
	input data0_in, data1_in,
	output data_out
);
	wire clock0, clock180;
	//BUFIO2 #(.DIVIDE(2), .USE_DOUBLER("TRUE"), .I_INVERT("FALSE")) b0 (.I(clock), .IOCLK(clock0),   .DIVCLK(), .SERDESSTROBE());
	//BUFIO2 #(.DIVIDE(2), .USE_DOUBLER("FALSE"), .I_INVERT("TRUE")) b1 (.I(clock), .IOCLK(clock180), .DIVCLK(), .SERDESSTROBE());
	assign clock0 = clock;
	assign clock180 = ~clock;
	ODDR2 #(.DDR_ALIGNMENT("NONE")) ddr (.C0(clock0), .C1(clock180), .CE(1'b1), .D0(data0_in), .D1(data1_in), .R(1'b0), .S(1'b0), .Q(data_out));
endmodule

//	pipeline #(.WIDTH(8), .DEPTH(DELAY)) kewalos (.clock(word_clock1), .in(oserdes_word1_buffer), .out(oserdes_word1_buffer_delayed));
module pipeline #(
	parameter WIDTH = 8,
	parameter DEPTH = 4
) (
	input clock,
	input [WIDTH-1:0] in,
	output [WIDTH-1:0] out
);
	reg [WIDTH-1:0] middle [DEPTH-1:0];
	integer i;
	always @(posedge clock) begin
		for (i=1; i<DEPTH; i=i+1) begin
			middle[i] <= middle[i-1];
		end
		middle[0] <= in;
	end
	assign out = middle[DEPTH-1];
endmodule

//	arithmetic_pipeline #(.WIDTH(8), .DEPTH(DELAY)) kewalos (.clock(word_clock1), .minuend(8'hff), .subtrahend(oserdes_word1_buffer), .difference(oserdes_word1_buffer_delayed));
module arithmetic_pipeline #(
	parameter WIDTH = 8,
	parameter DEPTH = 4
//	parameter OPERATION = "SUBTRACT"
) (
	input clock,
	input [WIDTH-1:0] minuend, subtrahend,
	output [WIDTH-1:0] difference
);
	reg [WIDTH-1:0] middle [DEPTH-1:0];
	reg [WIDTH-1:0] previous_subtrahend;
	integer i;
	always @(posedge clock) begin
		for (i=2; i<DEPTH; i=i+1) begin
			middle[i] <= middle[i-1];
		end
		middle[1] <= middle[0] - previous_subtrahend;
		middle[0] <= minuend;
		previous_subtrahend <= subtrahend;
	end
	assign difference = middle[DEPTH-1];
endmodule

module arithmetic_pipeline_tb();
	localparam WIDTH = 8;
	localparam DEPTH = 3;
	localparam FREQUENCY_OF_CLOCK_HZ = 1000000000;
	localparam STEP_DURATION = 4;
	wire clock;
	clock #(.FREQUENCY_OF_CLOCK_HZ(FREQUENCY_OF_CLOCK_HZ)) c (.clock(clock));
	reg [WIDTH-1:0] minuend = 0;
	reg [WIDTH-1:0] subtrahend = 0;
	wire [WIDTH-1:0] difference;
	initial begin
		#100; minuend <= 47;
		#STEP_DURATION; subtrahend <= 11;
		#STEP_DURATION; subtrahend <= 17;
		#STEP_DURATION; subtrahend <= 27;
		#STEP_DURATION; subtrahend <= 37;
		#STEP_DURATION; subtrahend <= 47;
		#STEP_DURATION; subtrahend <= 48;
		#STEP_DURATION; subtrahend <= 49;
		#100;
		#STEP_DURATION; minuend <= 53;
		#100;
	end
	arithmetic_pipeline #(.WIDTH(WIDTH), .DEPTH(DEPTH)) ap (.clock(clock), .minuend(minuend), .subtrahend(subtrahend), .difference(difference));
endmodule

module cdc_pipeline #(
	parameter WIDTH = 8,
	parameter DEPTH = 4
) (
	input clock,
	input [WIDTH-1:0] in,
	output [WIDTH-1:0] out
);
	(* KEEP = "TRUE" *) wire [WIDTH-1:0] pipeline_cdc;
	assign pipeline_cdc = in;
	reg [WIDTH-1:0] middle [DEPTH-1:0];
	integer i;
	always @(posedge clock) begin
		for (i=1; i<DEPTH; i=i+1) begin
			middle[i] <= middle[i-1];
		end
		middle[0] <= pipeline_cdc;
	end
	assign out = middle[DEPTH-1];
endmodule

module resync #(
	parameter WIDTH = 1
) (
	input clock,
	input [WIDTH-1:0] in,
	output reg [WIDTH-1:0] out = 0
);
	always @(posedge clock) begin
		out <= in;
	end
endmodule

module fixed_bitslip #(
	parameter WIDTH = 8,
	parameter LOG2_WIDTH = $clog2(WIDTH),
	parameter BITSLIP = 0,
	parameter PIPELINE_PICKOFF = WIDTH + BITSLIP - 1
) (
	input clock,
	input [WIDTH-1:0] data_in,
	output [WIDTH-1:0] data_out
);
	reg [PIPELINE_PICKOFF:0] pipeline = 0;
	always @(posedge clock) begin
		pipeline <= { pipeline[PIPELINE_PICKOFF-WIDTH:0], data_in };
	end
	assign data_out = pipeline[BITSLIP+:WIDTH];
endmodule

module bitslip #(
	parameter WIDTH = 8,
	parameter LOG2_WIDTH = $clog2(WIDTH),
	parameter MAX_BITSLIP = WIDTH,
	parameter LOG2_OF_MAX_BITSLIP = $clog2(MAX_BITSLIP),
	parameter PIPELINE_PICKOFF = WIDTH + MAX_BITSLIP - 1
) (
	input clock,
	input [WIDTH-1:0] data_in,
	input [LOG2_OF_MAX_BITSLIP-1:0] bitslip,
	output [WIDTH-1:0] data_out
);
	reg [PIPELINE_PICKOFF:0] pipeline = 0;
	always @(posedge clock) begin
		pipeline <= { pipeline[PIPELINE_PICKOFF-WIDTH:0], data_in };
	end
	assign data_out = pipeline[bitslip+:WIDTH];
endmodule

module bitslip_tb #(
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2
) ();
	reg clock = 0;
	always begin
		clock <= ~clock; #HALF_CLOCK_PERIOD;
	end
	reg [31:0] pre_in = 0, in = 0;
	reg [7:0] pre_bitslip = 0, bitslip = 0;
	always @(posedge clock) begin
		in <= pre_in;
		bitslip <= pre_bitslip;
	end
	initial begin
		#(2*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'h0;  #(4*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'h1;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'h2;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'h3;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'h4;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'h5;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'h6;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'h7;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'h8;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'h9;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'ha;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'hb;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'hc;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'hd;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'he;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'hf;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h76543210; pre_bitslip <= 8'h10; #(1*CLOCK_PERIOD); // this output should be different for bs16/out16 below
		#(2*CLOCK_PERIOD);
		pre_in <= 32'h0f0f0f0f; pre_bitslip <= 8'd0;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h0f0f0f0f; pre_bitslip <= 8'd4;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h0f0f0f0f; pre_bitslip <= 8'd8;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h0f0f0f0f; pre_bitslip <= 8'd12; #(1*CLOCK_PERIOD);
		pre_in <= 32'h00ff00ff; pre_bitslip <= 8'd8;  #(1*CLOCK_PERIOD);
		pre_in <= 32'h0bdb0a5a; pre_bitslip <= 8'd16; #(1*CLOCK_PERIOD); // this output should be different for bs16/out16 below
		#(2*CLOCK_PERIOD);
		$finish;
	end
	wire [31:0] out16, out32, out64, out;
	bitslip #(.WIDTH(32), .MAX_BITSLIP(16)) bs16 (.clock(clock), .data_in(in), .bitslip(bitslip[3:0]), .data_out(out16));
	bitslip #(.WIDTH(32)                  ) bs32 (.clock(clock), .data_in(in), .bitslip(bitslip[4:0]), .data_out(out32));
	bitslip #(.WIDTH(32), .MAX_BITSLIP(64)) bs64 (.clock(clock), .data_in(in), .bitslip(bitslip[5:0]), .data_out(out64));
	fixed_bitslip #(.WIDTH(32), .BITSLIP(12)) fbs (.clock(clock), .data_in(in), .data_out(out));
endmodule

//	count_ones #(.WIDTH(8)) myco (.clock(), .data_in(), .count_out());
module count_ones #(
	parameter WIDTH = 8,
	parameter LOG2_WIDTH = $clog2(WIDTH)
) (
	input clock,
	input [WIDTH-1:0] data_in,
	output reg [LOG2_WIDTH:0] count_out = 0
);
	always @(posedge clock) begin
		if (8==WIDTH) begin
			count_out <= data_in[7] + data_in[6] + data_in[5] + data_in[4] + data_in[3] + data_in[2] + data_in[1] + data_in[0];
		end else if (7==WIDTH) begin
			count_out <= data_in[6] + data_in[5] + data_in[4] + data_in[3] + data_in[2] + data_in[1] + data_in[0];
		end else if (6==WIDTH) begin
			count_out <= data_in[5] + data_in[4] + data_in[3] + data_in[2] + data_in[1] + data_in[0];
		end else if (5==WIDTH) begin
			count_out <= data_in[4] + data_in[3] + data_in[2] + data_in[1] + data_in[0];
		end else if (4==WIDTH) begin
			count_out <= data_in[3] + data_in[2] + data_in[1] + data_in[0];
		end else if (3==WIDTH) begin
			count_out <= data_in[2] + data_in[1] + data_in[0];
		end else if (2==WIDTH) begin
			count_out <= data_in[1] + data_in[0];
		end else if (1==WIDTH) begin
			count_out <= data_in[0];
		end
	end
endmodule

`endif

