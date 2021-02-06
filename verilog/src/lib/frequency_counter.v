// written 2020-05-29 by mza
// based on mza-test014.duration-timer.uart.v
// and mza-test022.frequency-counter.uart.v
// updated 2020-05-30 by mza
// last updated 2021-02-06 by mza

module frequency_counter #(
	parameter FREQUENCY_OF_REFERENCE_CLOCK = 10000000,
	parameter LOG2_OF_DIVIDE_RATIO = 24, // 27 is good
	parameter MAXIMUM_EXPECTED_FREQUENCY = 250000000,
	parameter LOG2_OF_MAXIMUM_EXPECTED_FREQUENCY = $clog2(MAXIMUM_EXPECTED_FREQUENCY), // ~28
	parameter N = 100, // N for N_Hz calculations
	parameter FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ = FREQUENCY_OF_REFERENCE_CLOCK / N,
	parameter LOG2_OF_FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ = $clog2(FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ) // ~27
) (
	input reference_clock,
	input unknown_clock,
	output [31:0] frequency_of_unknown_clock,
	output reg valid = 0
);
	localparam MSB_OF_COUNTERS = LOG2_OF_DIVIDE_RATIO + 8; // 35
	localparam MSB_OF_ACCUMULATOR = LOG2_OF_MAXIMUM_EXPECTED_FREQUENCY + LOG2_OF_FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ + 3; // ~63
	localparam MSB_OF_RESULT = MSB_OF_ACCUMULATOR - LOG2_OF_DIVIDE_RATIO; // ~35
	reg [MSB_OF_ACCUMULATOR:0] accumulator = 0;
	reg [MSB_OF_ACCUMULATOR:0] previous_accumulator = 0;
	reg [LOG2_OF_DIVIDE_RATIO:0] reference_clock_counter = 0;
	wire trigger_active = reference_clock_counter[LOG2_OF_DIVIDE_RATIO];
	reg valid__unknown = 0;
	reg [4:0] valid__pipeline_reference = 0;
	always @(posedge reference_clock) begin
		reference_clock_counter <= reference_clock_counter + 1'b1;
		valid <= 0;
		if (valid__pipeline_reference[3:2]==2'b01) begin
			valid <= 1;
		end
		valid__pipeline_reference <= { valid__pipeline_reference[2:0], valid__unknown };
	end
	reg [3:0] trigger_stream = 0;
	always @(posedge unknown_clock) begin
		trigger_stream <= { trigger_stream[2:0], trigger_active };
	end
	always @(posedge unknown_clock) begin
		if (trigger_stream[2]) begin
			valid__unknown <= 0;
			accumulator <= accumulator + FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ;
		end else if (trigger_stream[3:2]==2'b10) begin
			previous_accumulator <= accumulator;
			accumulator <= 0;
			valid__unknown <= 1;
		end
	end
	assign frequency_of_unknown_clock = previous_accumulator[MSB_OF_ACCUMULATOR:LOG2_OF_DIVIDE_RATIO];
endmodule

`ifndef SYNTHESIS
module frequency_counter_tb ();
	reg reference_clock = 0;
	reg unknown_clock = 0;
	wire [31:0] frequency_of_unknown_clock;
	wire frequency_counter_sync;
	frequency_counter #(.FREQUENCY_OF_REFERENCE_CLOCK(10000000), .LOG2_OF_DIVIDE_RATIO(5)) fc (.reference_clock(reference_clock), .unknown_clock(unknown_clock), .frequency_of_unknown_clock(frequency_of_unknown_clock), .valid(frequency_counter_sync));
	task automatic wait_for_sync;
		begin
			@(posedge frequency_counter_sync);
		end
	endtask
	initial begin
		#100;
		wait_for_sync;
		$display("%t %9d", $time, frequency_of_unknown_clock);
		wait_for_sync;
		$display("%t %9d", $time, frequency_of_unknown_clock);
		wait_for_sync;
		$display("%t %9d", $time, frequency_of_unknown_clock);
		#100;
		$finish;
	end
	always begin
		#50;
		reference_clock = ~reference_clock;
	end
	always begin
		#14.135;
		unknown_clock = ~unknown_clock;
	end
endmodule
`endif

