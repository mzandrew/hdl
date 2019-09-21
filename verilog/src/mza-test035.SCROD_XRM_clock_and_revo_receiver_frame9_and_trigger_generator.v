`timescale 1ns / 1ps
// written 2019-09-20 by mza
// based on vhdl version I wrote in late 2018 / early 2019 (from ScrodRevB_b2tt.vhd in UH svn repo)
// last updated 2019-09-21 by mza

module XRM_clock_and_revo_receiver_frame9_and_trigger_generator (
	input remote_clock127_p, remote_clock127_n,
	input remote_revo_p, remote_revo_n,
	input reset,
	input xrm_trigger_enabled, // from config.xrm_trigger_enabled
	input [4:0] trig_prescale_N_log2, // from config.trig_prescale_N_log2
	input [24:0] bunch_marker_a_position, // from config.bunch_marker_a
	input [24:0] bunch_marker_b_position, // from config.bunch_marker_b
	input [24:0] bunch_marker_c_position, // from config.bunch_marker_c
	input [24:0] bunch_marker_d_position, // from config.bunch_marker_d
	output xrm_trigger,
	output reg frame = 0,
	output reg frame9 = 0
);
	parameter FTSW_CLOCKS_IN_ONE_BEAM_ORBIT_MINUS_ONE = 1280 - 1;
	wire clock127;
	IBUFGDS clock127_instance (.I(remote_clock127_p), .IB(remote_clock127_n), .O(clock127));
	wire remote_revo_encoded;
	IBUFGDS revo_instance (.I(remote_revo_p), .IB(remote_revo_n), .O(remote_revo_encoded));
	wire remote_revo_raw;
	assign remote_revo_raw = clock127 ^ remote_revo_encoded;
	reg remote_revo = 0;
	reg local_revo = 0;
	reg xrm_trigger_active = 0;
	reg [8:0] frame9_token = 9'b100000000;
	reg bunch_marker_a = 0;
	reg bunch_marker_b = 0;
	reg bunch_marker_c = 0;
	reg bunch_marker_d = 0;
	reg [10:0] clock127_counter = 0; // 0 to 1279
	reg [31:0] frame9_counter = 1;
	reg [31:0] frame9_prescale = 0;
	reg [24:0] copy_of_bunch_marker_a_position = 0;
	reg [24:0] copy_of_bunch_marker_b_position = 0;
	reg [24:0] copy_of_bunch_marker_c_position = 0;
	reg [24:0] copy_of_bunch_marker_d_position = 0;
	assign xrm_trigger = bunch_marker_a | bunch_marker_b | bunch_marker_c | bunch_marker_d;
	always @(posedge clock127) begin
		if (reset) begin
			frame <= 0;
			frame9 <= 0;
			frame9_token <= 9'b100000000;
			clock127_counter <= 0;
			frame9_counter <= 1;
			xrm_trigger_active <= 0;
			local_revo <= 0;
			bunch_marker_a <= 0;
			bunch_marker_b <= 0;
			bunch_marker_c <= 0;
			bunch_marker_d <= 0;
		end else begin
			frame <= local_revo;
			frame9 <= frame9_token[8];
			bunch_marker_a <= 0;
			bunch_marker_b <= 0;
			bunch_marker_c <= 0;
			bunch_marker_d <= 0;
			if (xrm_trigger_active) begin
				         if (clock127_counter == copy_of_bunch_marker_a_position[12:2]) begin
					if (copy_of_bunch_marker_a_position[24:16] & frame9_token) begin
						bunch_marker_a <= 1;
					end
				end else if (clock127_counter == copy_of_bunch_marker_b_position[12:2]) begin
					if (copy_of_bunch_marker_b_position[24:16] & frame9_token) begin
						bunch_marker_b <= 1;
					end
				end else if (clock127_counter == copy_of_bunch_marker_c_position[12:2]) begin
					if (copy_of_bunch_marker_c_position[24:16] & frame9_token) begin
						bunch_marker_c <= 1;
					end
				end else if (clock127_counter == copy_of_bunch_marker_d_position[12:2]) begin
					if (copy_of_bunch_marker_d_position[24:16] & frame9_token) begin
						bunch_marker_d <= 1;
					end
				end
			end
			local_revo <= 0;
			if (remote_revo | (FTSW_CLOCKS_IN_ONE_BEAM_ORBIT_MINUS_ONE<=clock127_counter)) begin
				clock127_counter <= 0;
				local_revo <= 1;
				if (frame9_token == 9'b000000001) begin
					xrm_trigger_active <= 0;
					if (xrm_trigger_enabled) begin
						if (frame9_counter < frame9_prescale) begin
							frame9_counter <= frame9_counter + 1;
						end else begin
							xrm_trigger_active <= 1;
							frame9_counter <= 1;
						end
					end
					frame9_prescale <= 0;
					frame9_prescale[trig_prescale_N_log2] <= 1;
					copy_of_bunch_marker_a_position <= bunch_marker_a_position;
					copy_of_bunch_marker_b_position <= bunch_marker_b_position;
					copy_of_bunch_marker_c_position <= bunch_marker_c_position;
					copy_of_bunch_marker_d_position <= bunch_marker_d_position;
				end
				frame9_token <= { frame9_token[0], frame9_token[8:1] };
			end else begin
				clock127_counter = clock127_counter + 1;
			end
		end
	end
	always @(negedge clock127) begin
		if (reset) begin
			remote_revo <= 0;
		end else begin
			remote_revo <= remote_revo_raw;
		end
	end
endmodule

module XRM_clock_and_revo_receiver_frame9_and_trigger_generator_tb;
	reg scrod_remote_clock127_p = 0, scrod_remote_clock127_n = 1;
	reg scrod_remote_revo_p = 0, scrod_remote_revo_n = 1;
	reg scrod_reset = 1;
	reg scrod_xrm_trigger_enabled = 0;
	reg [4:0] scrod_trig_prescale_N_log2 = 12;
	reg [24:0] scrod_bunch_marker_a_position = 0;
	reg [24:0] scrod_bunch_marker_b_position = 1;
	reg [24:0] scrod_bunch_marker_c_position = 2;
	reg [24:0] scrod_bunch_marker_d_position = 3;
	wire scrod_xrm_trigger;
	wire scrod_frame;
	wire scrod_frame9;
	XRM_clock_and_revo_receiver_frame9_and_trigger_generator scrod (
		.remote_clock127_p(scrod_remote_clock127_p), .remote_clock127_n(scrod_remote_clock127_n),
		.remote_revo_p(scrod_remote_revo_p), .remote_revo_n(scrod_remote_revo_n),
		.reset(scrod_reset),
		.xrm_trigger_enabled(scrod_xrm_trigger_enabled), // from config.xrm_trigger_enabled
		.trig_prescale_N_log2(scrod_trig_prescale_N_log2), // from config.trig_prescale_N_log2
		.bunch_marker_a_position(scrod_bunch_marker_a_position), // from config.bunch_marker_a
		.bunch_marker_b_position(scrod_bunch_marker_b_position), // from config.bunch_marker_b
		.bunch_marker_c_position(scrod_bunch_marker_c_position), // from config.bunch_marker_c
		.bunch_marker_d_position(scrod_bunch_marker_d_position), // from config.bunch_marker_d
		.xrm_trigger(scrod_xrm_trigger),
		.frame(scrod_frame),
		.frame9(scrod_frame9)
	);
	initial begin
		scrod_remote_clock127_p <= 0; scrod_remote_clock127_n <= 1;
		scrod_remote_revo_p <= 0; scrod_remote_revo_n <= 1;
		scrod_reset <= 1;
		#100;
		scrod_reset <= 0;
		#500;
		scrod_xrm_trigger_enabled <= 1;
		scrod_bunch_marker_a_position[12:2] <= 0; scrod_bunch_marker_a_position[24:16] <= 9'b111111111;
		scrod_bunch_marker_b_position[12:2] <= 2; scrod_bunch_marker_b_position[24:16] <= 9'b000000001;
		scrod_bunch_marker_c_position[12:2] <= 3; scrod_bunch_marker_c_position[24:16] <= 9'b100000000;
		scrod_bunch_marker_d_position[12:2] <= 4; scrod_bunch_marker_d_position[24:16] <= 9'b000111000;
		scrod_trig_prescale_N_log2 <= 2;
		#400;
		scrod_remote_revo_p <= 1; scrod_remote_revo_n <= 0;
		#8;
		scrod_remote_revo_p <= 0; scrod_remote_revo_n <= 1;
		#10232;
		scrod_remote_revo_p <= 1; scrod_remote_revo_n <= 0;
		#8;
		scrod_remote_revo_p <= 0; scrod_remote_revo_n <= 1;
		#10232;
		scrod_remote_revo_p <= 1; scrod_remote_revo_n <= 0;
		#8;
		scrod_remote_revo_p <= 0; scrod_remote_revo_n <= 1;
		#10232;
		scrod_remote_revo_p <= 1; scrod_remote_revo_n <= 0;
		#8;
		scrod_remote_revo_p <= 0; scrod_remote_revo_n <= 1;
		#10232;
		scrod_remote_revo_p <= 1; scrod_remote_revo_n <= 0;
		#8;
		scrod_remote_revo_p <= 0; scrod_remote_revo_n <= 1;
	end
	always begin
		#4;
		scrod_remote_clock127_p <= ~scrod_remote_clock127_p; scrod_remote_clock127_n <= ~scrod_remote_clock127_n;
	end
endmodule

