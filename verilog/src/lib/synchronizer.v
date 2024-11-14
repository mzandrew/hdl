`timescale 1ns / 1ps
// written 2019-09-22 by mza
// based partly off mza-test029
// last updated 2024-11-13 by mza

`ifndef SYNCHRONIZER_LIB
`define SYNCHRONIZER_LIB

//	pipeline_synchronizer #(.WIDTH(2), .DEPTH(3)) mysin (.clock1(), .clock2(), .reset1(), .reset2(), .in1(), .out2());
module pipeline_synchronizer #(
	parameter DEPTH=2,
	parameter WIDTH=1
) (
	input clock1, clock2,
	input reset1, reset2,
	input [WIDTH-1:0] in1,
	output [WIDTH-1:0] out2
);
	reg [WIDTH-1:0] intermediate1 [DEPTH-1:0];
	reg [WIDTH-1:0] intermediate2 [DEPTH-1:0];
	(* KEEP = "TRUE" *) wire [WIDTH-1:0] cdc; // sometimes we get "WARNING:Xst:638 - in unit BLAH Conflict on KEEP property on signal BLAH/cdc and BLAH/cdc BLAH/cdc signal will be lost."
	integer i;
	always @(posedge clock1) begin
		for (i=1; i<DEPTH; i=i+1) begin : pipeline1
			if (reset1) begin
				intermediate1[i] <= 0;
			end else begin
				intermediate1[i] <= intermediate1[i-1];
			end
		end
		if (reset1) begin
			intermediate1[0] <= 0;
		end else begin
			intermediate1[0] <= in1;
		end
	end
	assign cdc = intermediate1[DEPTH-1];
	always @(posedge clock2) begin
		for (i=1; i<DEPTH; i=i+1) begin : pipeline2
			if (reset2) begin
				intermediate2[i] <= 0;
			end else begin
				intermediate2[i] <= intermediate2[i-1];
			end
		end
		if (reset2) begin
			intermediate2[0] <= 0;
		end else begin
			intermediate2[0] <= cdc;
		end
	end
	assign out2 = intermediate2[DEPTH-1];
endmodule

// the following probably shouldn't be used...
module ssynchronizer_pnp #(
	parameter WIDTH=1
) (
	input clock1, clock2,
	input reset1, reset2,
	input [WIDTH-1:0] in1,
	output [WIDTH-1:0] out2
);
	reg [WIDTH-1:0] intermediate_f1;
	reg [WIDTH-1:0] intermediate_s1;
	reg [WIDTH-1:0] intermediate_s2;
//	(* KEEP = "TRUE" *) wire [WIDTH-1:0] cdc;
	always @(posedge clock1 or posedge reset1) begin
		if (reset1) begin
			intermediate_f1 <= 0;
		end else begin
			intermediate_f1 <= in1;
		end
	end
//	assign cdc = intermediate_f3;
	always @(negedge clock2 or posedge reset2) begin
		if (reset2) begin
			intermediate_s1 <= 0;
		end else begin
			intermediate_s1 <= intermediate_f1;
		end
	end
	always @(posedge clock2 or posedge reset2) begin
		if (reset2) begin
			intermediate_s2 <= 0;
		end else begin
			intermediate_s2 <= intermediate_s1;
		end
	end
	assign out2 = intermediate_s2;
endmodule

// the following probably shouldn't be used...
module ssynchronizer_90_270 #(
	parameter WIDTH=1
) (
	input clock1,
	input clock2, clock1_90, clock1_270,
	input reset,
	input [WIDTH-1:0] in1,
	output [WIDTH-1:0] out2
);
	reg [WIDTH-1:0] intermediate_f1;
	reg [WIDTH-1:0] intermediate_f2;
	reg [WIDTH-1:0] intermediate_f3;
	reg [WIDTH-1:0] intermediate_f4;
	reg [WIDTH-1:0] intermediate_s1;
	reg [WIDTH-1:0] intermediate_s2;
//	(* KEEP = "TRUE" *) wire [WIDTH-1:0] cdc;
	always @(posedge clock1) begin
		if (reset) begin
			intermediate_f1 <= 0;
		end else begin
			intermediate_f1 <= in1;
		end
	end
	always @(posedge clock1_270) begin
		if (reset) begin
			intermediate_f2 <= 0;
		end else begin
			intermediate_f2 <= intermediate_f1;
		end
	end
	always @(negedge clock1) begin
		if (reset) begin
			intermediate_f3 <= 0;
		end else begin
			intermediate_f3 <= intermediate_f2;
		end
	end
	always @(posedge clock1_90) begin
		if (reset) begin
			intermediate_f4 <= 0;
		end else begin
			intermediate_f4 <= intermediate_f3;
		end
	end
//	assign cdc = intermediate_f4;
	always @(negedge clock2) begin
		if (reset) begin
			intermediate_s1 <= 0;
		end else begin
			//intermediate_s1 <= cdc;
			intermediate_s1 <= intermediate_f4;
		end
	end
	always @(posedge clock2) begin
		if (reset) begin
			intermediate_s2 <= 0;
		end else begin
			intermediate_s2 <= intermediate_s1;
		end
	end
	assign out2 = intermediate_s2;
endmodule

// the following probably shouldn't be used...
module ssynchronizer_pnppp #(
	parameter WIDTH=1
) (
	input clock1, clock2,
	input reset,
	input [WIDTH-1:0] in1,
	output [WIDTH-1:0] out2
);
	reg [WIDTH-1:0] intermediate_f1;
	reg [WIDTH-1:0] intermediate_f2;
	reg [WIDTH-1:0] intermediate_f3;
	reg [WIDTH-1:0] intermediate_s1;
	reg [WIDTH-1:0] intermediate_s2;
	(* KEEP = "TRUE" *) wire [WIDTH-1:0] cdc;
//  242 pos neg neg pos pos
//  332 pos neg neg neg pos
// 1030 pos pos neg neg pos
// 1759 pos neg neg pos neg
	always @(posedge clock1) begin
		if (reset) begin
			intermediate_f1 <= 0;
		end else begin
			intermediate_f1 <= in1;
		end
	end
	always @(negedge clock1) begin
		if (reset) begin
			intermediate_f2 <= 0;
		end else begin
			intermediate_f2 <= intermediate_f1;
		end
	end
	always @(negedge clock1) begin
		if (reset) begin
			intermediate_f3 <= 0;
		end else begin
			intermediate_f3 <= intermediate_f2;
		end
	end
	assign cdc = intermediate_f3;
	always @(posedge clock2) begin
		if (reset) begin
			intermediate_s1 <= 0;
		end else begin
			intermediate_s1 <= cdc;
		end
	end
	always @(posedge clock2) begin
		if (reset) begin
			intermediate_s2 <= 0;
		end else begin
			intermediate_s2 <= intermediate_s1;
		end
	end
	assign out2 = intermediate_s2;
endmodule

//	parameter POLARITY = "HIGH"
module edge_to_pulse #(
	parameter DEPTH = 3,
	parameter WIDTH = 1
) (
	input clock,
	input [WIDTH-1:0] in,
	input reset,
	output [WIDTH-1:0] out
);
	reg [DEPTH-1:0] reg_stream [WIDTH-1:0];
	reg [WIDTH-1:0] reg_out = 0;
	genvar i; // generate
	for (i=0; i<WIDTH; i=i+1) begin : general
		always @(posedge clock) begin
			if (reset) begin
				reg_stream[i] <= 0;
			end else begin
				reg_stream[i] <= { reg_stream[i][DEPTH-2:0], in[i] };
			end
		end
		always @(posedge clock) begin
			if (reset) begin
				reg_out[i] <= 0;
			end else begin
				if (reg_stream[i][2:1] == 2'b01) begin
					reg_out[i] <= 1;
				end else begin
					reg_out[i] <= 0;
				end
			end
		end
	end // endgenerate
	assign out = reg_out;
endmodule

module edge_to_pulse_tb;
	parameter WIDTH = 4'd4;
	parameter DEPTH = 4'd8;
	reg clock = 0;
	reg [WIDTH-1:0] in = 0;
	reg reset = 1;
	wire [WIDTH-1:0] out;
	edge_to_pulse #(.DEPTH(DEPTH), .WIDTH(WIDTH)) e2p (.clock(clock), .in(in), .reset(reset), .out(out));
	initial begin
		clock <= 0;
		reset <= 1;
		in <= 0;
		#10
		reset <= 0;
		#10
		in <= 4'b0001;
		#8;
		in <= 0;
		#10
		in <= 4'b0101;
		#2;
		in <= 4'b0100;
		#2;
		in <= 0;
		#10
		in <= 4'b0001;
		#4;
		in <= 0;
	end
	always begin
		#1
		clock <= 1;
		#1
		clock <= 0;
	end
endmodule

//	slow_asynchronizer #(.WIDTH(2), .DEPTH(3)) mysin (.clock(), .reset(), .async_in(), .sync_out());
// this is based on pipeline_synchronizer
module slow_asynchronizer #(
	parameter DEPTH=2,
	parameter WIDTH=1
) (
	input clock,
	input reset,
	input [WIDTH-1:0] async_in,
	output [WIDTH-1:0] sync_out
);
	reg [WIDTH-1:0] intermediate1 [DEPTH-1:0];
	reg [WIDTH-1:0] intermediate2 [DEPTH-1:0];
	(* KEEP = "TRUE" *) wire [WIDTH-1:0] async_cdc;
	genvar i;
	always @(posedge clock) begin
		if (reset) begin
			intermediate1[0] <= 0;
		end else begin
			intermediate1[0] <= async_in;
		end
	end
	for (i=1; i<DEPTH; i=i+1) begin : pipeline1
		always @(posedge clock) begin
			if (reset) begin
				intermediate1[i] <= 0;
			end else begin
				intermediate1[i] <= intermediate1[i-1];
			end
		end
	end
	assign async_cdc = intermediate1[DEPTH-1];
	always @(posedge clock) begin
		if (reset) begin
			intermediate2[0] <= 0;
		end else begin
			intermediate2[0] <= async_cdc;
		end
	end
	for (i=1; i<DEPTH; i=i+1) begin : pipeline2
		always @(posedge clock) begin
			if (reset) begin
				intermediate2[i] <= 0;
			end else begin
				intermediate2[i] <= intermediate2[i-1];
			end
		end
	end
	assign sync_out = intermediate2[DEPTH-1];
endmodule

// for when the asynchronous pulse is shorter than the synchronous clock period
module fast_asynchronizer #(
	parameter WIDTH = 1
) (
	input clock,
	input reset,
	input [WIDTH-1:0] async_in,
	output [WIDTH-1:0] sync_out
);
// https://daffy1108.wordpress.com/2014/06/08/synchronizers-for-asynchronous-signals/
	reg [WIDTH-1:0] reg_intermediate_s1;
	reg [WIDTH-1:0] reg_intermediate_s2;
	reg [WIDTH-1:0] reg_intermediate_s3;
	reg [WIDTH-1:0] reg_sync_out = 0;
//	(* KEEP = "TRUE" *) wire [WIDTH-1:0] cdc;
	wire [WIDTH-1:0] randy;
	genvar i;
	for (i=0; i<WIDTH; i=i+1) begin : randy_mapping
		assign randy[i] = reset || ((~async_in[i]) && reg_intermediate_s3[i]);
		always @(posedge async_in[i] or posedge randy[i]) begin
			if (randy[i]) begin
				reg_intermediate_s1[i] <= 0;
			end else begin
				reg_intermediate_s1[i] <= 1;
			end
		end
		//assign cdc = intermediate_s1;
		always @(posedge clock) begin
			if (randy[i]) begin
				reg_intermediate_s2[i] <= 0;
			end else begin
				reg_intermediate_s2[i] <= reg_intermediate_s1[i]; // cdc;
			end
		end
		always @(posedge clock) begin
			if (reset) begin
				reg_intermediate_s3[i] <= 0;
				reg_sync_out[i] <= 0;
			end else begin
				reg_sync_out[i] <= reg_intermediate_s3[i];
				reg_intermediate_s3[i] <= reg_intermediate_s2[i];
			end
		end
	end
	assign sync_out = reg_sync_out;
endmodule

module asynchronizers_tb;
	reg clock = 0;
	reg reset = 0;
	reg async_in = 0;
	wire sync_out1, sync_out2;
	initial begin
		clock <= 0;
		reset <= 1;
		async_in <= 0;
		#20
		reset <= 0;
		#20.25
		// medium pulse:
		async_in <= 1; #6.5 async_in <= 0;
		#20.75
		// short pulse:
		async_in <= 1; #0.75 async_in <= 0;
		#20.75
		// long pulse:
		async_in <= 1; #18 async_in <= 0;
	end
	always begin
		#1 clock <= 1;
		#1 clock <= 0;
	end
	fast_asynchronizer fast (.clock(clock), .reset(reset), .async_in(async_in), .sync_out(sync_out1));
	slow_asynchronizer #(.WIDTH(1), .DEPTH(2)) slow (.clock(clock), .reset(reset), .async_in(async_in), .sync_out(sync_out2));
endmodule

// cross-clock handshake
// following https://zipcpu.com/blog/2017/10/20/cdc.html
module handshake #(
	parameter DEPTH = 2
) (
	input clock_a,
	input input_trigger_a,
	input clock_b,
	output reg output_trigger_b = 0,
	output busy
);
	reg request_a = 0;
	reg ack_a = 0;
	reg [DEPTH-1:0] ack_pipe_a = 0;
	reg [DEPTH-1:0] request_pipe_b = 0;
	reg last_request_b = 0;
	reg request_b = 0;
	always @(posedge clock_a)
		if ((!busy)&&(input_trigger_a))
			request_a <= 1;
		else if (ack_a)
			request_a <= 0;
	always @(posedge clock_a)
		{ ack_a, ack_pipe_a } <= { ack_pipe_a, request_b };
	assign busy = (request_a) || (ack_a);
	always @(posedge clock_b)
		{ last_request_b, request_b, request_pipe_b } <= { request_b, request_pipe_b, request_a };
	always @(posedge clock_b)
		output_trigger_b <= (!last_request_b) && (request_b);
endmodule

module handshake_tb;
	wire busy;
	reg clock_a = 0;
	reg clock_b = 0;
	reg t_a = 0;
	wire t_b;
	handshake #(.DEPTH(6)) hs (.clock_a(clock_a), .input_trigger_a(t_a), .clock_b(clock_b), .output_trigger_b(t_b), .busy(busy));
	initial begin
		#32;
		t_a <= 1;
		#8
		t_a <= 0;
	end
	always begin
		#4;
		clock_a <= ~clock_a;
	end
	always begin
		#9;
		clock_b <= ~clock_b;
	end
endmodule

//	parameter BUTTON_POLARITY = 1 // not used yet
module button_debounce #(
	parameter DEBOUNCE_CLOCK_PERIODS = 20, // typically 10-50 ms worth of clock periods
	parameter METASTABLE_CLOCK_PERIODS = 3 // typically 2 or 3 clock periods
) (
	input clock,
	input button_raw,
	output reg button_just_went_active = 0,
	output reg button_just_went_inactive = 0,
	output reg button_state = 0,
	output reg button_just_changed = 0
);
	reg [METASTABLE_CLOCK_PERIODS-1:0] button_pipeline_short = 0;
	reg button_raw_previous = 0;
	reg button_state_is_stable = 0;
	reg [31:0] sequential_1_counter = 0;
	reg [31:0] sequential_0_counter = 0;
	always @(posedge clock) begin
		button_just_went_active <= 0;
		button_just_went_inactive <= 0;
		button_just_changed <= 0;
		if (button_state_is_stable) begin
			if (button_state) begin
				if (button_raw_previous==0) begin
					button_state <= 0;
					button_just_went_inactive <= 1;
					button_just_changed <= 1;
					button_state_is_stable <= 0;
					sequential_0_counter <= 1;
					sequential_1_counter <= 0;
				end
			end else begin
				if (button_raw_previous==1) begin
					button_state <= 1;
					button_just_went_active <= 1;
					button_just_changed <= 1;
					button_state_is_stable <= 0;
					sequential_0_counter <= 0;
					sequential_1_counter <= 1;
				end
			end
		end else begin
			if (DEBOUNCE_CLOCK_PERIODS<sequential_0_counter) begin
				button_state_is_stable <= 1;
			end else if (DEBOUNCE_CLOCK_PERIODS<sequential_1_counter) begin
				button_state_is_stable <= 1;
			end else begin
				button_state_is_stable <= 0;
			end
			if (button_raw_previous==0) begin
				sequential_0_counter <= sequential_0_counter + 1'b1;
				sequential_1_counter <= 0;
			end else begin
				sequential_1_counter <= sequential_1_counter + 1'b1;
				sequential_0_counter <= 0;
			end
		end
		{ button_raw_previous, button_pipeline_short } <= { button_pipeline_short, button_raw };
	end
endmodule

module button_debounce_tb;
	reg button_raw = 0;
	reg clock = 0;
	wire button_just_went_inactive;
	wire button_just_went_active;
	wire button_state;
	wire button_just_changed;
	button_debounce #(.DEBOUNCE_CLOCK_PERIODS(10)) bd (.button_raw(button_raw), .clock(clock), .button_just_went_inactive(button_just_went_inactive), .button_just_went_active(button_just_went_active), .button_state(button_state), .button_just_changed(button_just_changed));
	initial begin
		#400
		// normal transition on
		button_raw <= 1;
		#100
		button_raw <= 0;
		#100
		button_raw <= 1;
		#100
		button_raw <= 0;
		#100
		button_raw <= 1;
		#2000
		// normal transition off
		button_raw <= 0;
		#100
		button_raw <= 1;
		#100
		button_raw <= 0;
		#100
		button_raw <= 1;
		#100
		button_raw <= 0;
		#2000
		// quick transition on, then off
		button_raw <= 1;
		#100
		button_raw <= 0;
		#2000
		// steady on, then quick transition off, then back on
		button_raw <= 1;
		#1000
		button_raw <= 0;
		#20
		button_raw <= 1;
		#1000
		// quick transition off
		button_raw <= 0;
		#1000
		// steady off, then quick transition on, then back off
		button_raw <= 1;
		#20
		button_raw <= 0;
	end
	always begin
		#10
		clock <= ~clock;
	end
endmodule

`endif

