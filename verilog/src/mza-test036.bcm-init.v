// this file is automatically generated by xrm.py from the uh svn repo
// generated 2020-04-26

module bcm_init #(
	parameter DATA_BUS_WIDTH = 8,
	parameter ADDRESS_BUS_DEPTH = 14
) (
	input clock,
	input reset,
	output reg [ADDRESS_BUS_DEPTH-1:0] write_address = 0,
	output reg write_enable = 0,
	output reg [DATA_BUS_WIDTH-1:0] data_out = 0,
	output reg done = 0
);
	reg [7:0] values_array [4:0][48:0];
	reg [2:0] index_array [333:0];
	reg [2:0] values_array_counter_1 = 0;
	reg [5:0] values_array_counter_2 = 0;
	reg [8:0] index_array_counter = 0;
	reg [3:0] initializing_stage = 0;
	always @(posedge clock) begin
		if (reset) begin
			initializing_stage <= 0;
			values_array_counter_1 <= 0;
			values_array_counter_2 <= 0;
			index_array_counter <= 0;
		end else begin
			values_array_counter_2 <= values_array_counter_2 + 1'b1;
			if (initializing_stage==0) begin
				case (values_array_counter_2)
					49: begin values_array_counter_1 <= values_array_counter_1 + 1'b1; values_array_counter_2 <= 0; initializing_stage <= initializing_stage + 1'b1; end
					default: values_array[values_array_counter_1][values_array_counter_2] <= 8'h00;
				endcase
			end else if (initializing_stage==1) begin
				case (values_array_counter_2)
					0: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					1: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					3: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					4: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					6: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					7: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					9: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					10: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					12: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					13: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					15: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					16: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					18: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					49: begin values_array_counter_1 <= values_array_counter_1 + 1'b1; values_array_counter_2 <= 0; initializing_stage <= initializing_stage + 1'b1; end
					default: values_array[values_array_counter_1][values_array_counter_2] <= 8'h00;
				endcase
			end else if (initializing_stage==2) begin
				case (values_array_counter_2)
					3: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					4: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					6: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					7: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					9: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					10: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					12: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					13: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					15: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					16: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					18: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					19: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					21: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					22: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					24: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					26: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					27: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					29: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					30: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					32: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					33: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					35: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					36: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					38: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					39: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					41: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					42: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					44: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					45: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					47: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					49: begin values_array_counter_1 <= values_array_counter_1 + 1'b1; values_array_counter_2 <= 0; initializing_stage <= initializing_stage + 1'b1; end
					default: values_array[values_array_counter_1][values_array_counter_2] <= 8'h00;
				endcase
			end else if (initializing_stage==3) begin
				case (values_array_counter_2)
					0: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					1: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					3: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					4: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					6: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					7: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					9: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					10: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					12: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					13: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					15: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					16: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					18: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					19: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					21: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					23: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					49: begin values_array_counter_1 <= values_array_counter_1 + 1'b1; values_array_counter_2 <= 0; initializing_stage <= initializing_stage + 1'b1; end
					default: values_array[values_array_counter_1][values_array_counter_2] <= 8'h00;
				endcase
			end else if (initializing_stage==4) begin
				case (values_array_counter_2)
					0: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					1: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					3: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					4: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					6: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					7: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					9: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					10: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					12: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					13: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					15: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					16: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					18: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					19: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					21: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					22: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					24: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					26: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					27: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					29: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					30: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					32: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					33: values_array[values_array_counter_1][values_array_counter_2] <= 8'h04;
					35: values_array[values_array_counter_1][values_array_counter_2] <= 8'h40;
					36: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					38: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					39: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					41: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					42: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					44: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					45: values_array[values_array_counter_1][values_array_counter_2] <= 8'h01;
					47: values_array[values_array_counter_1][values_array_counter_2] <= 8'h10;
					49: begin values_array_counter_1 <= values_array_counter_1 + 1'b1; values_array_counter_2 <= 0; initializing_stage <= initializing_stage + 1'b1; end
					default: values_array[values_array_counter_1][values_array_counter_2] <= 8'h00;
				endcase
			end else if (initializing_stage==5) begin
				index_array_counter <= index_array_counter + 1'b1;
				case (index_array_counter)
					0: index_array[index_array_counter] <= 3'h4;
					1: index_array[index_array_counter] <= 3'h4;
					2: index_array[index_array_counter] <= 3'h4;
					3: index_array[index_array_counter] <= 3'h4;
					4: index_array[index_array_counter] <= 3'h4;
					5: index_array[index_array_counter] <= 3'h4;
					6: index_array[index_array_counter] <= 3'h4;
					7: index_array[index_array_counter] <= 3'h4;
					8: index_array[index_array_counter] <= 3'h4;
					9: index_array[index_array_counter] <= 3'h4;
					10: index_array[index_array_counter] <= 3'h4;
					11: index_array[index_array_counter] <= 3'h4;
					12: index_array[index_array_counter] <= 3'h1;
					13: index_array[index_array_counter] <= 3'h2;
					14: index_array[index_array_counter] <= 3'h4;
					15: index_array[index_array_counter] <= 3'h4;
					16: index_array[index_array_counter] <= 3'h4;
					17: index_array[index_array_counter] <= 3'h4;
					18: index_array[index_array_counter] <= 3'h4;
					19: index_array[index_array_counter] <= 3'h4;
					20: index_array[index_array_counter] <= 3'h4;
					21: index_array[index_array_counter] <= 3'h4;
					22: index_array[index_array_counter] <= 3'h4;
					23: index_array[index_array_counter] <= 3'h4;
					24: index_array[index_array_counter] <= 3'h4;
					25: index_array[index_array_counter] <= 3'h3;
					334: begin index_array_counter <= 0; values_array_counter_2 <= 0; initializing_stage <= initializing_stage + 1'b1; end
					default: index_array[index_array_counter] <= 3'h0;
				endcase
			end else if (initializing_stage==6) begin
				if (initialized) begin
					initializing_stage <= initializing_stage + 1'b1;
				end
			end
		end
	end
	reg [ADDRESS_BUS_DEPTH-1:0] counter = 0;
	reg initialized = 0;
	reg [5:0] values_array_counter_1_prime = 0;
	reg [5:0] values_array_counter_2_prime = 0;
	reg [8:0] index_array_counter_prime = 0;
	always @(posedge clock) begin
		if (reset) begin
			counter <= 0;
			write_enable <= 0;
			write_address <= 0;
			data_out <= 0;
			initialized <= 0;
			values_array_counter_1_prime <= 0;
			values_array_counter_2_prime <= 0;
			index_array_counter_prime <= 0;
			done <= 0;
		end else begin
			if (!initialized) begin
				if (initializing_stage==6) begin
					values_array_counter_2_prime <= values_array_counter_2_prime + 1'b1;
					write_enable <= 1;
					write_address <= counter;
					if (values_array_counter_2_prime==47) begin
						if (index_array_counter_prime==333) begin
							index_array_counter_prime <= 0;
							initialized <= 1;
						end else begin
							index_array_counter_prime <= index_array_counter_prime + 1'b1;
						end
					end else if (values_array_counter_2_prime==48) begin
						values_array_counter_1_prime <= index_array[index_array_counter_prime];
						values_array_counter_2_prime <= 0;
					end else begin
						data_out <= values_array[values_array_counter_1_prime][values_array_counter_2_prime];
					end
					counter <= counter + 1'b1;
				end
			end else begin
				write_enable <= 0;
				write_address <= 0;
				data_out <= 0;
				done <= 1;
			end
		end
	end
endmodule


