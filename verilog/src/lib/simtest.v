// written 2025-02-27 by mza
// last updated 2025-03-05 by mza

// synthesis of this as top module (WIDTH=8) results in 8 slice LUTs and 1 DSP48A1
// synthesis of this as top module (WIDTH=18) results in 74 slice LUTs and 4 DSP48A1s
module quickmath #(
	parameter DATA_WIDTH = 18
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

// synthesis of this as top module (WIDTH=8) results in 8 slice registers, 9 slice LUTs and 1 DSP48A1
// note that this module does not produce the correct result
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

// synthesis of this as top module (WIDTH=8) results in 16 slice registers, 9 slice LUTs and 1 DSP48A1
// synthesis of this as top module (WIDTH=18) results in 126 slice registers, 124 slice LUTs and 1 DSP48A1
module pipelinemath_try2 #(
	parameter DATA_WIDTH = 18
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
	quickmath          qm (.clock(clock), .reset(reset), .input1(input1), .input2(input2), .input3(input3), .input4(input4), .result(result_qm));
	pipelinemath_try1 pm1 (.clock(clock), .reset(reset), .input1(input1), .input2(input2), .input3(input3), .input4(input4), .result(result_pm1));
	pipelinemath_try2 pm2 (.clock(clock), .reset(reset), .input1(input1), .input2(input2), .input3(input3), .input4(input4), .result_delayed_by_3(result_pm2));
	always @(posedge clock) begin
		result_qm_delayed_by_2 <= result_qm_delayed_by_1;
		result_qm_delayed_by_1 <= result_qm;
	end
	assign error_pm2 = result_pm2 - result_qm_delayed_by_2;
	assign error_pm1 = result_pm1 - result_qm;
endmodule

// HDL ADVISOR - You can improve the performance of the multiplier Mmult_i0[7]_i1[7]_MuLt_1_OUT by adding 1 register level(s)
module a_bunch_of_multipliers #(
	parameter WIDTH = 18
) (
	input clock,
	input [WIDTH-1:0] i0, i1, i2, i3,
	output reg [2*WIDTH-1:0] o0 = 0, o1 = 0, o2 = 0, o3 = 0
);
	always @(posedge clock) begin
		o0 <= i0 * i1;
		o1 <= i1 * i2;
		o2 <= i2 * i3;
		o3 <= i3 * i0;
	end
endmodule

// HDL_ADVISOR didn't mean to buffer the input...
module a_bunch_of_multipliers_with_an_extra_register_level_at_the_input_stage #(
	parameter WIDTH = 18
) (
	input clock,
	input [WIDTH-1:0] i0, i1, i2, i3,
	output reg [2*WIDTH-1:0] o0 = 0, o1 = 0, o2 = 0, o3 = 0
);
	reg [WIDTH-1:0] i0b = 0, i1b = 0, i2b = 0, i3b = 0;
	always @(posedge clock) begin
		o0 <= i0b * i1b;
		o1 <= i1b * i2b;
		o2 <= i2b * i3b;
		o3 <= i3b * i0b;
		i0b <= i0;
		i1b <= i1;
		i2b <= i2;
		i3b <= i3;
	end
endmodule

// HDL_ADVISOR wants you to buffer the output...
module a_bunch_of_multipliers_with_an_extra_register_level_at_the_output_stage #(
	parameter WIDTH = 99 // 8 up to 19 here => 4 DSP48A1s; 20 up to 37 => 16 DSP48A1s; above that, it uses lots of LUTs and 9 DSP48A1s
) (
	input clock,
	input [WIDTH-1:0] i0, i1, i2, i3,
	output reg [2*WIDTH-1:0] o0 = 0, o1 = 0, o2 = 0, o3 = 0
);
	reg [2*WIDTH-1:0] o0b = 0, o1b = 0, o2b = 0, o3b = 0;
	always @(posedge clock) begin
		o0 <= o0b;
		o1 <= o1b;
		o2 <= o2b;
		o3 <= o3b;
		o0b <= i0 * i1;
		o1b <= i1 * i2;
		o2b <= i2 * i3;
		o3b <= i3 * i0;
	end
endmodule

module a_bunch_of_multipliers_tb #(
	parameter WIDTH = 18,
	parameter CLOCK_PERIOD = 1.0,
	parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2.0
) ();
	reg clock = 0;
	always begin
		#HALF_CLOCK_PERIOD; clock <= ~clock;
	end
	reg [WIDTH-1:0] i0 = 0, i1 = 0, i2 = 0, i3 = 0;
	wire [2*WIDTH-1:0] o0_0, o1_0, o2_0, o3_0;
	wire [2*WIDTH-1:0] o0_1, o1_1, o2_1, o3_1;
	wire [2*WIDTH-1:0] o0_2, o1_2, o2_2, o3_2;
	a_bunch_of_multipliers                                                   #(.WIDTH(WIDTH)) abom_0 (.clock(clock), .i0(i0), .i1(i1), .i2(i2), .i3(i3), .o0(o0_0), .o1(o1_0), .o2(o2_0), .o3(o3_0));
	a_bunch_of_multipliers_with_an_extra_register_level_at_the_input_stage   #(.WIDTH(WIDTH)) abom_1 (.clock(clock), .i0(i0), .i1(i1), .i2(i2), .i3(i3), .o0(o0_1), .o1(o1_1), .o2(o2_1), .o3(o3_1));
	a_bunch_of_multipliers_with_an_extra_register_level_at_the_output_stage  #(.WIDTH(WIDTH)) abom_2 (.clock(clock), .i0(i0), .i1(i1), .i2(i2), .i3(i3), .o0(o0_2), .o1(o1_2), .o2(o2_2), .o3(o3_2));
	initial begin
		#(3*CLOCK_PERIOD);
		i0 <= 0; i1 <= 1; i2 <= 2; i3 <= 3; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= 5; i1 <= 5; i2 <= 5; i3 <= 5; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		i0 <= i0 + 1; i1 <= i1 + 1; i2 <= i2 + 1; i3 <= i3 + 1; #CLOCK_PERIOD;
		#(4*CLOCK_PERIOD); $finish;
	end
endmodule

