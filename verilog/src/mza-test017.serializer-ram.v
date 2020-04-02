// written 2018-09-07 by mza
// to drive a SN65LV1023 serializer IC
// based on mza-test016.serializer.v 
// last updated 2020-04-02 by mza

`include "lib/easypll.v"
`include "lib/prbs.v"

module mytop (input clock, output [5:1] LED, 
output [7:0] J1,
inout [7:0] J2,
output [7:0] J3
);
	reg reset = 1;
	wire fast_clock;
	wire pll_is_locked;
	easypll #(.DIVR(0), .DIVF(56), .DIVQ(4), .FILTER_RANGE(1)) my_42MHz_pll_instance (.clock_input(clock), .reset_active_low(~reset), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 42.750 MHz
	reg [31:0] fast_clock_counter;
	localparam pickoff = 3;
	reg sync;
	always @(posedge fast_clock) begin
		sync <= 0;
		if (reset) begin
			fast_clock_counter <= 0;
		end else if (pll_is_locked) begin
			fast_clock_counter++;
			data_bus <= read_data[9:0];
			read_address <= fast_clock_counter[10:0];
			if (fast_clock_counter[pickoff:0]==0) begin
				sync <= 1;
			end
		end
	end
	reg [31:0] counter = 0;
	reg [10:0] read_address;
	reg [15:0] read_data;
	reg [10:0] write_address;
	reg [15:0] write_data;
	reg write_enable;
	reg initialized = 0;
	SB_RAM40_4K #(.WRITE_MODE(1), .READ_MODE(1)) ram40_4k_inst (
		.WADDR(write_address),
		.WDATA(write_data),
		.WE(write_enable),
		.WCLKE(1),
		.WCLK(clock),
		.RADDR(read_address),
		.RDATA(read_data),
		.RE(1),
		.RCLKE(1),
		.RCLK(fast_clock)
	);
	always @(posedge clock) begin
		counter++;
		if (reset) begin
			if (counter[log2_PRBSWIDTH-2]==1) begin
				reset <= 0;
			end
		end else begin
			write_enable <= 0;
			if (!initialized) begin
				if (counter[log2_PRBSWIDTH-1:0]==0) begin
					write_address <= counter[log2_PRBSWIDTH+10:log2_PRBSWIDTH];
					write_data <= buffered_rand[15:0];
					buffered_rand <= rand;
					write_enable <= 1;
					if (write_address==11'b11111111111) begin
						initialized <= 1;
					end
				end
			end
		end
	end
	assign J1[7] = 1; // vcc
	assign J1[3] = 1; // vcc
	assign J2[6] = 1; // powerdown_active_low
	assign J1[1] = 1; // data_enable
	assign J1[5] = 0; // gnd
	assign J1[4] = 0; // gnd
	assign J1[2] = 0; // gnd
	assign J1[0] = 0; // gnd
	assign J2[2] = 0; // gnd
	assign J1[6] = 0; // gnd
	assign J3[4] = 0; // use_tclk_rising_edge
	assign J2[3] = serial_stream_p; // 
	assign J2[7] = serial_stream_n; // 
	assign J3[5] = fast_clock; // tclk
	wire serial_stream_p;
	wire serial_stream_n;
	wire [9:0] data_bus;
	assign data_bus = { J3[3], J3[2],
	                    J3[1], J3[0], J2[0], J2[4],
	                    J2[1], J2[5], J3[6], J3[7] };
	assign LED[5] = sync;
	assign LED[4] = 0;
	assign LED[3] = 0;
	assign LED[2] = 0;
	assign LED[1] = 0;
	localparam PRBSWIDTH = 128;
	localparam log2_PRBSWIDTH = $clog2(PRBSWIDTH);
	wire [PRBSWIDTH-1:0] rand;
	reg [PRBSWIDTH-1:0] buffered_rand;
	prbs #(.WIDTH(PRBSWIDTH)) myprbs (.clock(clock), .reset(reset), .word(rand));
endmodule // mytop

module icestick (
input CLK,
output LED1, LED2, LED3, LED4, LED5,
output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
//output J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
output J2_1, J2_2, J2_3, J2_7, J2_8, J2_9,
input J2_4, J2_10,
output J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10,
output DCDn, DSRn, CTSn, TX, IR_TX, IR_SD,
input DTRn, RTSn, RX, IR_RX
);
	wire [7:0] J1 = { J1_10, J1_9, J1_8, J1_7, J1_6, J1_5, J1_4, J1_3 };
	wire [7:0] J2 = { J2_10, J2_9, J2_8, J2_7, J2_4, J2_3, J2_2, J2_1 };
	wire [7:0] J3 = { J3_10, J3_9, J3_8, J3_7, J3_6, J3_5, J3_4, J3_3 };
	wire [5:1] LED = { LED5, LED4, LED3, LED2, LED1 };
	assign { DCDn, DSRn, CTSn } = 1;
	assign { IR_TX, IR_SD } = 0;
	assign TX = 0;
	mytop mytop_instance (.clock(CLK), .LED(LED), .J1(J1), .J2(J2), .J3(J3));
endmodule // icestick

