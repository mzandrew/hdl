`timescale 1ns / 1ps
// written 2019-09-09 by mza
// based partly off mza-test029

module ssynchronizer_pnp #(
	parameter WIDTH=1
) (
	input clock1, clock2,
	input reset,
	input [WIDTH-1:0] in1,
	output [WIDTH-1:0] out2
);
	reg [WIDTH-1:0] intermediate_f1;
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
//	assign cdc = intermediate_f3;
	always @(negedge clock2) begin
		if (reset) begin
			intermediate_s1 <= 0;
		end else begin
			intermediate_s1 <= intermediate_f1;
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
	reg clock = 0;
	reg [WIDTH-1:0] in = 0;
	reg reset = 1;
	wire [WIDTH-1:0] out;
	parameter DEPTH = 4'd8;
	parameter WIDTH = 4'd4;
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

module asynchronizer (
	input clock,
	input reset,
	input async_in,
	output sync_out,
	output intermediate_s1, intermediate_s2, intermediate_s3
);
// https://daffy1108.wordpress.com/2014/06/08/synchronizers-for-asynchronous-signals/
	reg reg_intermediate_s1 = 0;
	reg reg_intermediate_s2 = 0;
	reg reg_intermediate_s3 = 0;
	reg reg_sync_out = 0;
//	(* KEEP = "TRUE" *) wire cdc;
	wire randy;
	assign randy = reset | ((~async_in) & reg_intermediate_s3);
	always @(posedge async_in or posedge randy) begin
		if (randy) begin
			reg_intermediate_s1 <= 0;
		end else begin
			reg_intermediate_s1 <= 1;
		end
	end
//	assign cdc = intermediate_s1;
	always @(posedge clock) begin
		if (randy) begin
			reg_intermediate_s2 <= 0;
		end else begin
			reg_intermediate_s2 <= reg_intermediate_s1; // cdc;
		end
	end
	always @(posedge clock) begin
		if (reset) begin
			reg_intermediate_s3 <= 0;
			reg_sync_out <= 0;
		end else begin
			reg_sync_out <= reg_intermediate_s3;
			reg_intermediate_s3 <= reg_intermediate_s2;
		end
	end
	assign intermediate_s1 = reg_intermediate_s1;
	assign intermediate_s2 = reg_intermediate_s2;
	assign intermediate_s3 = reg_intermediate_s3;
	assign sync_out = reg_sync_out;
endmodule

module asynchronizer_nonworking (
	input clock,
	input reset,
	input async_in,
	output sync_out,
	output intermediate_s1, intermediate_s2, intermediate_s3
);
// https://daffy1108.wordpress.com/2014/06/08/synchronizers-for-asynchronous-signals/
	reg reg_intermediate_s1 = 0;
	reg reg_intermediate_s2 = 0;
	reg reg_intermediate_s3 = 0;
	reg reg_sync_out;
//	(* KEEP = "TRUE" *) wire cdc;
	wire randy;
	assign randy = reset | ((~async_in) & intermediate_s3);
//	assign randy = reset | intermediate_s2;
	always @(posedge async_in) begin
		reg_intermediate_s1 <= 0;
		if (~reset) begin
//			reg_intermediate_s1 <= 0;
//		end else begin
			if (async_in) begin
				reg_intermediate_s1 <= 1;
			end
		end
	end
//	assign cdc = intermediate_s1;
	always @(posedge clock) begin
		reg_intermediate_s2 <= 0;
		if (~reset) begin
			reg_intermediate_s2 <= reg_intermediate_s1; // cdc;
		end
	end
	always @(posedge clock) begin
		reg_intermediate_s3 <= 0;
		reg_sync_out <= 0;
		if (~reset) begin
			reg_sync_out <= reg_intermediate_s3;
			reg_intermediate_s3 <= reg_intermediate_s2;
		end
	end
	assign intermediate_s1 = reg_intermediate_s1;
	assign intermediate_s2 = reg_intermediate_s2;
	assign intermediate_s3 = reg_intermediate_s3;
	assign sync_out = reg_sync_out;
endmodule

module asynchronizer_tb;
	reg clock = 0;
	reg reset = 0;
	reg async_in = 0;
	wire sync_out;
	wire intermediate_s1, intermediate_s2, intermediate_s3;
	initial begin
		clock <= 0;
		reset <= 1;
		async_in <= 0;
		#20
		reset <= 0;
		#20.25
		async_in <= 1;
		#6.5
		async_in <= 0;
		#20.75
		async_in <= 1;
		#0.75
		async_in <= 0;
	end
	always begin
		#1
		clock <= 1;
		#1
		clock <= 0;
	end
	asynchronizer blah (.clock(clock), .reset(reset), .async_in(async_in), .sync_out(sync_out), .intermediate_s1(intermediate_s1), .intermediate_s2(intermediate_s2), .intermediate_s3(intermediate_s3));
endmodule

