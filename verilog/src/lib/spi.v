// written 2020-05-06 by mza
// last updated 2026-02-27 by mza

`ifndef SPI_LIB
`define SPI_LIB

// from https://en.wikipedia.org/wiki/Serial_Peripheral_Interface#/media/File:SPI_timing_diagram2.svg
//module spi_peripheral #(
//	parameter cpol = 0,
//	parameter cpha = 0
//) (
//	input sclock,
//	input reset,
//	input mosi,
//	output miso,
//	input cs_active_low
//);
//	reg [2:0] bit_counter = 0;
//	always @(posedge sclock) begin
//		if (reset) begin
//			bit_counter <= 0;
//		end else begin
//			if (cs_active_low==0) begin
//				bit_counter <= bit_counter + 1'b1;
//			end
//		end
//	end
//endmodule

// modified from https://www.fpga4fun.com/SPI2.html
module SPI_peripheral_simple8 (
	input clock,
	input SCK, SSEL, MOSI,
	output MISO,
	input [7:0] data_to_controller,
	output reg [7:0] data_from_controller = 0,
	output reg data_valid = 0
);
	// sync SCK, SSEL, MOSI to the FPGA clock using a 3-bits shift register
	reg [2:0] SCKr = 0;
	reg [2:0] SSELr = 0;
	reg [1:0] MOSIr = 0;
	always @(posedge clock) begin
		SCKr <= {SCKr[1:0], SCK};
		SSELr <= {SSELr[1:0], SSEL};
		MOSIr <= {MOSIr[0], MOSI};
	end
	wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
	wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges
	wire SSEL_active = ~SSELr[1];  // SSEL is active low
	wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
	wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge
	wire MOSI_data = MOSIr[1];
	// we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
	reg [2:0] bitcnt = 0;
	reg byte_received = 0;  // high when a byte has been received
	reg [7:0] byte_data_received = 0;
	always @(posedge clock) begin
		if (~SSEL_active) begin
			bitcnt <= 0;
		end else if (SCK_risingedge) begin
			bitcnt <= bitcnt + 1'b1;
			// implement a shift-left register (since we receive the data MSB first)
			byte_data_received <= {byte_data_received[6:0], MOSI_data};
		end
	end
	always @(posedge clock) begin
		data_valid <= 0;
		if (byte_received) begin
			data_from_controller <= byte_data_received;
			data_valid <= 1;
		end
		byte_received <= SSEL_active && SCK_risingedge && (bitcnt==7);
	end
	reg [7:0] byte_data_sent = 0;
//	reg [7:0] cnt = 0;
//	always @(posedge clock) begin
//		if (SSEL_startmessage) begin
//			cnt <= cnt + 8'h1;  // count the messages
//		end
//	end
	always @(posedge clock) begin
		if(SSEL_active) begin
			if (SSEL_startmessage) begin
				//byte_data_sent <= cnt;  // first byte sent in a message is the message count
				byte_data_sent <= data_to_controller;
			end else if (SCK_fallingedge) begin
				if (bitcnt==0) begin
					byte_data_sent <= 8'h00;  // after that, we send 0s
				end else begin
					byte_data_sent <= {byte_data_sent[6:0], 1'b0};
				end
			end
		end
	end
	assign MISO = byte_data_sent[7];	// send MSB first
	// we assume that there is only one peripheral on the SPI bus
	// so we don't bother with a tri-state buffer for MISO
	// otherwise we would need to tri-state MISO when SSEL is inactive
endmodule

module SPI_peripheral_simple8_tb;
	reg clock = 0;
	reg SCK = 0;
	reg MOSI = 0;
	reg SSEL = 1;
	wire MISO;
	reg [7:0] data_to_controller = 8'h89;
	wire [7:0] data_from_controller;
	wire data_valid;
	SPI_peripheral_simple8 spi_s8 (.clock(clock), .SCK(SCK), .MOSI(MOSI), .MISO(MISO), .SSEL(SSEL), .data_to_controller(data_to_controller), .data_from_controller(data_from_controller), .data_valid(data_valid));
	reg [7:0] data = 8'ha5;
	reg [7:0] i = 0;
	initial begin
		SCK <= 0;
		MOSI <= 0;
		SSEL <= 1;
		#200;
		SSEL <= 0;
		for (i=8; i>0; i=i-1) begin : command
			MOSI <= data[i-1];
			#100;
			SCK <= 1;
			#100;
			SCK <= 0;
		end
		MOSI <= 0;
		#100;
		SSEL <= 1;
	end
	always begin
		#10;
		clock <= ~clock;
	end
endmodule

// originally from https://www.fpga4fun.com/SPI2.html
// notes:
// raw pipelines should be 1 deeper (also the pickoffs)
// address16 and data32 and transaction_valid should probably have an extra level of buffering
// command8 should be interpreted and allow an addressless (autoincrement) mode
module SPI_peripheral_command8_address16_data32 (
	input clock,
	input SCK, SSEL, MOSI,
	output MISO,
	output reg [7:0] command8 = 0,
	output reg [15:0] address16 = 0,
	output reg [31:0] data32 = 0,
	input [31:0] data32_to_controller,
	output reg transaction_valid = 0
);
//	reg [8+16+32-1:0] word = 0;
	// sync SCK, SSEL, MOSI to the FPGA clock using a 3-bits shift register
	reg [2:0] SCKr = 0;
	reg [2:0] SSELr = 0;
	reg [1:0] MOSIr = 0;
	always @(posedge clock) begin
		SCKr <= {SCKr[1:0], SCK};
		SSELr <= {SSELr[1:0], SSEL};
		MOSIr <= {MOSIr[0], MOSI};
	end
	wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
	wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges
	wire SSEL_active = ~SSELr[1];  // SSEL is active low
	wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
	wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge
	wire MOSI_data = MOSIr[1];
	reg [3:0] bitcnt = 0;
	reg [3:0] bytecnt = 0;
	reg [7:0] byte_data_received = 0;
//	reg [7:0] error_count = 0;
	always @(posedge clock) begin
		transaction_valid <= 0;
		if (~SSEL_active) begin
			bitcnt <= 0;
			bytecnt <= 0;
		end else if (SCK_risingedge) begin
			bitcnt <= bitcnt + 1'b1;
			byte_data_received <= {byte_data_received[6:0], MOSI_data};
		end else begin
			if (bitcnt==8) begin
				if (bytecnt==0) begin
					command8 <= byte_data_received;
				// if (command8[3] and bytecnt==1)
				end else if (bytecnt==1) begin
					address16[15:8] <= byte_data_received;
				end else if (bytecnt==2) begin
					address16[7:0] <= byte_data_received;
					// address_valid <= 1;
				end else if (bytecnt==3) begin
					data32[31:24] <= byte_data_received;
				end else if (bytecnt==4) begin
					data32[23:16] <= byte_data_received;
				end else if (bytecnt==5) begin
					data32[15:8] <= byte_data_received;
				end else if (bytecnt==6) begin
					data32[7:0] <= byte_data_received;
					transaction_valid <= 1;
//				end else begin
//					error_count <= error_count + 1'b1;
				end
				bitcnt <= 0;
				bytecnt <= bytecnt + 1'b1;
			end
		end
	end
	reg [7:0] byte_data_sent = 0;
//	reg [7:0] cnt = 0;
//	always @(posedge clock) begin
//		if (SSEL_startmessage) begin
//			cnt <= cnt + 8'h1;  // count the messages
//		end
//	end
	reg [31:0] copy_of_data32_to_controller = 0;
	always @(posedge clock) begin
		if (SSEL_active) begin
//			if (SSEL_startmessage) begin
				//byte_data_sent <= cnt;  // first byte sent in a message is the message count
//				byte_data_sent <= data_to_controller;
//				byte_data_sent <= 8'h88;
			if (bytecnt==3 && bitcnt==0) begin
				copy_of_data32_to_controller <= data32_to_controller;
			end else if (SCK_fallingedge) begin
				copy_of_data32_to_controller <= { copy_of_data32_to_controller[30:0], 1'b0 };
//				byte_data_sent <= {byte_data_sent[6:0], 1'b0};
			end
		end
	end
	assign MISO = copy_of_data32_to_controller[31];	// send MSB first
	// we assume that there is only one peripheral on the SPI bus
	// so we don't bother with a tri-state buffer for MISO
	// otherwise we would need to tri-state MISO when SSEL is inactive
endmodule

module SPI_peripheral_command8_address16_data32_tb;
	reg clock = 0;
	reg SCK = 0;
	reg MOSI = 0;
	reg SSEL = 1;
	wire MISO;
//	reg [7:0] data_to_controller = 8'h89;
	wire transaction_valid;
	SPI_peripheral_command8_address16_data32 spi_c8_a16_d32 (.clock(clock), .SCK(SCK), .MOSI(MOSI), .MISO(MISO), .SSEL(SSEL), .transaction_valid(transaction_valid));
	reg [7:0] command8 = 8'h01;
	reg [15:0] address16 = 16'h2345;
	reg [31:0] data32 = 32'h6789abcd;
	reg [7:0] i = 0;
	initial begin
		SCK <= 0;
		MOSI <= 0;
		SSEL <= 1;
		#300;
		SSEL <= 0;
		for (i=8; i>0; i=i-1) begin : command
			MOSI <= command8[i-1];
			#100;
			SCK <= 1;
			#100;
			SCK <= 0;
		end
		for (i=16; i>0; i=i-1) begin : address
			MOSI <= address16[i-1];
			#100;
			SCK <= 1;
			#100;
			SCK <= 0;
		end
		for (i=32; i>0; i=i-1) begin : data
			MOSI <= data32[i-1];
			#100;
			SCK <= 1;
			#100;
			SCK <= 0;
		end
		MOSI <= 0;
		#100;
		SSEL <= 1;
	end
	always begin
		#10;
		clock <= ~clock;
	end
endmodule

// following issi datasheet for is66wvs4m8bll-104nli
module qspi_psram_controller_try1 #(
	parameter ADDRESS_DEPTH_MEBIWORDS = 4, // 4 Mi addresses
	parameter ADDRESS_DEPTH = ADDRESS_DEPTH_MEBIWORDS*1024*1024, // 4 Mi addresses
	parameter LOG2_OF_ADDRESS_DEPTH = $clog2(ADDRESS_DEPTH), // 22 address bits
	parameter INTERNAL_DATA_WIDTH = 8, // "4M8" memory internally
	parameter QSPI_ENTER_QPI_MODE_COMMAND = 8'h35, // 8 clocks for this command on mosi only; then device in quad command mode
	parameter QSPI_WRITE_COMMAND = 8'h38, // 8 clocks for this command on mosi only (or 2 clocks for this command in qpi mode); 6 clocks for the 24 bit address; no wait; then quad data in on every cycle
	parameter QSPI_READ_COMMAND = 8'heb // 8 clocks for this command on mosi only (or 2 clocks for this command in qpi mode); 6 clocks for the 24 bit address; 6 clocks wait; then quad data out on every cycle
) (
	input clock,
	input reset,
	input [LOG2_OF_ADDRESS_DEPTH-1:0] address,
	input [3:0] data_in,
	input write,
	output reg ready = 0,
	output reg [3:0] data_out = 0,
	output reg valid = 0,
	output reg qspi_cs = 1'b1,
	output reg qspi_sclk = 0,
	inout qspi_mosi, qspi_miso, qspi_sio2, qspi_sio3
);
	reg previous_write = 0;
//	reg should_switch_to_read_mode = 0;
	reg [3:0] qspi_output_enable = 4'b0001, qspi_potential_data_out = 0;
	wire [3:0] qspi_data_in;
	assign qspi_mosi = qspi_output_enable[0] ? qspi_potential_data_out[0] : 1'bz;
	assign qspi_miso = qspi_output_enable[1] ? qspi_potential_data_out[1] : 1'bz;
	assign qspi_sio2 = qspi_output_enable[2] ? qspi_potential_data_out[2] : 1'bz;
	assign qspi_sio3 = qspi_output_enable[3] ? qspi_potential_data_out[3] : 1'bz;
	assign qspi_data_in = { qspi_sio3, qspi_sio2, qspi_miso, qspi_mosi };
	reg [7:0] counter = 0;
	reg [7:0] command = QSPI_ENTER_QPI_MODE_COMMAND;
	always @(posedge clock) begin
		previous_write <= write;
		if (reset) begin
			data_out <= 0;
			valid <= 0;
			ready <= 0;
			qspi_cs <= 1'b1;
			qspi_sclk <= 0;
			qspi_output_enable <= 4'b0001;
			qspi_potential_data_out <= 0;
			counter <= 0;
			command <= QSPI_ENTER_QPI_MODE_COMMAND;
//			should_switch_to_read_mode <= 0;
		end else begin
			if (counter<=64) begin
				counter <= counter + 1'b1;
			end
			if (counter<=3) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=4) begin
				qspi_sclk <= 0;
				counter <= 9;
			// after this clock, the device will be properly out of reset
			end else if (counter<=9) begin
				qspi_potential_data_out <= { {4{command[7]}} };
				qspi_cs <= 0;
			end else if (counter<=10) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=11) begin
				qspi_potential_data_out <= { {4{command[6]}} };
				qspi_sclk <= 0;
			end else if (counter<=12) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=13) begin
				qspi_potential_data_out <= { {4{command[5]}} };
				qspi_sclk <= 0;
			end else if (counter<=14) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=15) begin
				qspi_potential_data_out <= { {4{command[4]}} };
				qspi_sclk <= 0;
			end else if (counter<=16) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=17) begin
				qspi_potential_data_out <= { {4{command[3]}} };
				qspi_sclk <= 0;
			end else if (counter<=18) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=19) begin
				qspi_potential_data_out <= { {4{command[2]}} };
				qspi_sclk <= 0;
			end else if (counter<=20) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=21) begin
				qspi_potential_data_out <= { {4{command[1]}} };
				qspi_sclk <= 0;
			end else if (counter<=22) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=23) begin
				qspi_potential_data_out <= { {4{command[0]}} };
				qspi_sclk <= 0;
			end else if (counter<=24) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=25) begin
				qspi_sclk <= 0;
				qspi_cs <= 1'b1;
			// after this clock, it should be in QPI mode
				counter <= 64;
			end else if (counter<=30) begin
				qspi_output_enable <= 4'b1111;
				if (write) begin
					command <= QSPI_WRITE_COMMAND;
				end else begin
					command <= QSPI_READ_COMMAND;
				end
			end else if (counter<=31) begin
				qspi_potential_data_out <= { command[7:4] };
				qspi_cs <= 0;
			end else if (counter<=32) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=33) begin
				qspi_potential_data_out <= { command[3:0] };
				qspi_sclk <= 0;
			end else if (counter<=34) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=35) begin
				qspi_sclk <= 0;
				counter <= 40;
			end else if (counter<=40) begin
				qspi_potential_data_out <= { {2{1'b0}}, address[21:20] };
			end else if (counter<=41) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=42) begin
				qspi_potential_data_out <= { address[19:16] };
				qspi_sclk <= 0;
			end else if (counter<=43) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=44) begin
				qspi_potential_data_out <= { address[15:12] };
				qspi_sclk <= 0;
			end else if (counter<=45) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=46) begin
				qspi_potential_data_out <= { address[11:8] };
				qspi_sclk <= 0;
			end else if (counter<=47) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=48) begin
				qspi_potential_data_out <= { address[7:4] };
				qspi_sclk <= 0;
			end else if (counter<=49) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=50) begin
				qspi_potential_data_out <= { address[3:0] };
				qspi_sclk <= 0;
			end else if (counter<=51) begin
				qspi_sclk <= 1'b1;
			end else if (counter<=52) begin
				qspi_sclk <= 0;
			// after this clock, it should be in streaming read/write mode
				if (~write) begin
					qspi_output_enable <= 0;
				end
				counter <= 64;
			end else begin
				qspi_sclk <= ~qspi_sclk;
				if (previous_write!=write) begin
					counter <= 30;
				end
				if (write) begin
					qspi_potential_data_out <= { data_in };
				end else begin
					data_out <= qspi_data_in;
				end
			end
		end
	end
endmodule

module qspi_psram_controller_tb;
	localparam CLOCK_PERIOD = 4;
	localparam HALF_CLOCK_PERIOD = CLOCK_PERIOD/2;
	reg clock = 0, reset = 1, write = 0;
	reg [21:0] address = 22'h123456;
	reg [3:0] data_in = 4'hc;
	wire [3:0] data_out;
	wire ready, valid;
	initial begin
		#(4*CLOCK_PERIOD);
		reset <= 0;
		#(2*CLOCK_PERIOD);
		data_in <= 4'h6;
		#(50*CLOCK_PERIOD);
		write <= 1'b1;
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		write <= 0;
		#(50*CLOCK_PERIOD);
		write <= 1'b1;
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD); data_in <= data_in + 1'b1; #(2*CLOCK_PERIOD);
		write <= 0;
		#(50*CLOCK_PERIOD);
		$finish;
	end
	always begin
		#HALF_CLOCK_PERIOD;
		clock <= ~clock;
	end
	qspi_psram_controller_try1 t1 (.clock(clock), .reset(reset), .address(address), .data_in(data_in), .data_out(data_out), .write(write), .ready(ready), .valid(valid));
endmodule

`endif

