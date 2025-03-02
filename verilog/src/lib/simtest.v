// written 2025-02-27 by mza
// last updated 2025-03-02 by mza

module quickmath #(
	parameter DATA_WIDTH = 8
) (
	input clock, reset,
	input [DATA_WIDTH-1:0] input1, input2, input3, input4,
	output reg [2*DATA_WIDTH-1:0] result = 0
);
	always @(posedge clock) begin
		if (reset) begin
			result <= 0;
		end else begin
			result <= input1 + input2 * (input4 - input3);
		end
	end
endmodule

module pipelinemath_try1 #(
	parameter DATA_WIDTH = 8
) (
	input clock, reset,
	input [DATA_WIDTH-1:0] input1, input2, input3, input4,
	output reg [2*DATA_WIDTH-1:0] result = 0
);
	reg [DATA_WIDTH-1:0] intermediate43 = 0;
	reg [2*DATA_WIDTH-1:0] intermediate243 = 0;
	always @(posedge clock) begin
		if (reset) begin
			result<= 0;
		end else begin
			result <= input1 + intermediate243;
			intermediate243 <= input2 * intermediate43;
			intermediate43 <= input4 - input3;
		end
	end
endmodule

module pipelinemath_try2 #(
	parameter DATA_WIDTH = 8
) (
	input clock, reset,
	input [DATA_WIDTH-1:0] input1, input2, input3, input4,
	output reg [2*DATA_WIDTH-1:0] result_delayed_by_3 = 0
);
	reg [DATA_WIDTH-1:0] intermediate43_delayed_by_1 = 0, intermediate43_delayed_by_2 = 0;
	reg [2*DATA_WIDTH-1:0] intermediate243_delayed_by_2 = 0;
	reg [DATA_WIDTH-1:0] input2_delayed_by_1 = 0, input1_delayed_by_1 = 0, input1_delayed_by_2 = 0;
	always @(posedge clock) begin
		if (reset) begin
			result_delayed_by_3 <= 0;
		end else begin
			result_delayed_by_3 <= input1_delayed_by_2 + intermediate243_delayed_by_2;
			intermediate243_delayed_by_2 <= input2_delayed_by_1 * intermediate43_delayed_by_1;
			intermediate43_delayed_by_2 <= intermediate43_delayed_by_1;
			intermediate43_delayed_by_1 <= input4 - input3;
			input1_delayed_by_2 <= input1_delayed_by_1;
			input1_delayed_by_1 <= input1;
			input2_delayed_by_1 <= input2;
		end
	end
endmodule

module math_tb #(
	parameter DATA_WIDTH = 8,
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2.0
) ();
	reg clock = 1, reset = 1;
	reg [DATA_WIDTH-1:0] input1 = 8'd0, input2 = 8'd1, input3 = 8'd2, input4 = 8'd3;
	wire [2*DATA_WIDTH-1:0] result_qm, result_pm1, result_pm2, error_pm1, error_pm2;
	reg [2*DATA_WIDTH-1:0] result_qm_delayed_by_1 = 0, result_qm_delayed_by_2 = 0;
	always begin
		#HALF_CLOCK_PERIOD; clock <= ~clock;
	end
	initial begin
		#(3*CLOCK_PERIOD+HALF_CLOCK_PERIOD); reset <= 0; #(4*CLOCK_PERIOD);
		#CLOCK_PERIOD; input1 <= input1 + 8'd1; input2 <= input2 + 8'd2; input3 <= input3 + 8'd1; input4 <= input4 + 8'd2;
		#CLOCK_PERIOD; input1 <= input1 + 8'd1; input2 <= input2 + 8'd2; input3 <= input3 + 8'd1; input4 <= input4 + 8'd2;
		#CLOCK_PERIOD; input1 <= input1 + 8'd1; input2 <= input2 + 8'd2; input3 <= input3 + 8'd1; input4 <= input4 + 8'd2;
		#CLOCK_PERIOD; input1 <= input1 + 8'd1; input2 <= input2 + 8'd2; input3 <= input3 + 8'd1; input4 <= input4 + 8'd2;
		#CLOCK_PERIOD; input1 <= input1 + 8'd1; input2 <= input2 + 8'd2; input3 <= input3 + 8'd1; input4 <= input4 + 8'd2;
		#CLOCK_PERIOD; input1 <= input1 + 8'd1; input2 <= input2 + 8'd2; input3 <= input3 + 8'd1; input4 <= input4 + 8'd2;
		#CLOCK_PERIOD; input1 <= input1 + 8'd1; input2 <= input2 + 8'd2; input3 <= input3 + 8'd1; input4 <= input4 + 8'd2;
		#(4*CLOCK_PERIOD); $finish;
	end
	quickmath qm (.clock(clock), .reset(reset), .input1(input1), .input2(input2), .input3(input3), .input4(input4), .result(result_qm));
	pipelinemath_try1 pm1 (.clock(clock), .reset(reset), .input1(input1), .input2(input2), .input3(input3), .input4(input4), .result(result_pm1));
	pipelinemath_try2 pm2 (.clock(clock), .reset(reset), .input1(input1), .input2(input2), .input3(input3), .input4(input4), .result_delayed_by_3(result_pm2));
	always @(posedge clock) begin
		result_qm_delayed_by_2 <= result_qm_delayed_by_1;
		result_qm_delayed_by_1 <= result_qm;
	end
	assign error_pm2 = result_pm2 - result_qm_delayed_by_2;
	assign error_pm1 = result_pm1 - result_qm;
endmodule

