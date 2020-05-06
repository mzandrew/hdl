// written 2020-05-06 by mza
// last updated 2020-05-06 by mza
// from https://en.wikipedia.org/wiki/Serial_Peripheral_Interface#/media/File:SPI_timing_diagram2.svg
//module spi_slave #(
//	parameter cpol = 0,
//	parameter cpha = 0
//) (
//	input sclk,
//	input reset,
//	input mosi,
//	output miso,
//	input cs_active_low
//);
//	reg [2:0] bit_counter = 0;
//	always @(posedge sclk) begin
//		if (reset) begin
//			bit_counter <= 0;
//		end else begin
//			if (cs_active_low==0) begin
//				bit_counter <= bit_counter + 1'b1;
//			end
//		end
//	end
//endmodule

// from https://www.fpga4fun.com/SPI2.html
module SPI_slave #(
) (
	input clk,
	input SCK, SSEL, MOSI,
	output MISO,
	output reg LED = 0,
	input [7:0] data_to_master,
	output reg [7:0] data_from_master = 0,
	output reg data_valid = 0
);
	// sync SCK to the FPGA clock using a 3-bits shift register
	reg [2:0] SCKr = 0;
	always @(posedge clk) begin
		SCKr <= {SCKr[1:0], SCK};
	end
	wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
	wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges
	// same thing for SSEL
	reg [2:0] SSELr = 0;
	always @(posedge clk) begin
		SSELr <= {SSELr[1:0], SSEL};
	end
	wire SSEL_active = ~SSELr[1];  // SSEL is active low
	wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
	wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge
	// and for MOSI
	reg [1:0] MOSIr = 0;
	always @(posedge clk) begin
		MOSIr <= {MOSIr[0], MOSI};
	end
	wire MOSI_data = MOSIr[1];
	// we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
	reg [2:0] bitcnt = 0;
	reg byte_received = 0;  // high when a byte has been received
	reg [7:0] byte_data_received = 0;
	always @(posedge clk) begin
		if (~SSEL_active) begin
			bitcnt <= 3'b000;
		end else if (SCK_risingedge) begin
			bitcnt <= bitcnt + 3'b001;
			// implement a shift-left register (since we receive the data MSB first)
			byte_data_received <= {byte_data_received[6:0], MOSI_data};
		end
	end
	always @(posedge clk) begin
		data_valid <= 0;
		if (byte_received) begin
			data_from_master <= byte_data_received;
			data_valid <= 1;
		end
		byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'b111);
	end
	// we use the LSB of the data received to control an LED
	always @(posedge clk) begin
		if (byte_received) begin
			LED <= byte_data_received[0];
		end
	end
	reg [7:0] byte_data_sent = 0;
	reg [7:0] cnt = 0;
	always @(posedge clk) begin
		if (SSEL_startmessage) begin
			cnt <= cnt + 8'h1;  // count the messages
		end
	end
	always @(posedge clk) begin
		if(SSEL_active) begin
			if (SSEL_startmessage) begin
				//byte_data_sent <= cnt;  // first byte sent in a message is the message count
				byte_data_sent <= data_to_master;  // first byte sent in a message is the message count
			end else if (SCK_fallingedge) begin
				if (bitcnt==3'b000) begin
					byte_data_sent <= 8'h00;  // after that, we send 0s
				end else begin
					byte_data_sent <= {byte_data_sent[6:0], 1'b0};
				end
			end
		end
	end
	assign MISO = byte_data_sent[7];	// send MSB first
	// we assume that there is only one slave on the SPI bus
	// so we don't bother with a tri-state buffer for MISO
	// otherwise we would need to tri-state MISO when SSEL is inactive
endmodule

module SPI_slave_tb;
	reg clock = 0;
	reg SCK = 0;
	reg MOSI = 0;
	reg SSEL = 1;
	wire MISO;
	wire LED;
	reg [7:0] data_to_master = 8'h89;
	wire [7:0] data_from_master;
	wire data_valid;
	SPI_slave spis (.clk(clock), .SCK(SCK), .MOSI(MOSI), .MISO(MISO), .SSEL(SSEL), .LED(LED), .data_to_master(data_to_master), .data_from_master(data_from_master), .data_valid(data_valid));
	reg [7:0] data = 8'ha5;
	initial begin
		SCK <= 0;
		MOSI <= 0;
		SSEL <= 1;
		#200;
		SSEL <= 0;
		MOSI <= data[7];
		#100;
		SCK <= 1;
		#100;
		SCK <= 0;
		MOSI <= data[6];
		#100;
		SCK <= 1;
		#100;
		SCK <= 0;
		MOSI <= data[5];
		#100;
		SCK <= 1;
		#100;
		SCK <= 0;
		MOSI <= data[4];
		#100;
		SCK <= 1;
		#100;
		SCK <= 0;
		MOSI <= data[3];
		#100;
		SCK <= 1;
		#100;
		SCK <= 0;
		MOSI <= data[2];
		#100;
		SCK <= 1;
		#100;
		SCK <= 0;
		MOSI <= data[1];
		#100;
		SCK <= 1;
		#100;
		SCK <= 0;
		MOSI <= data[0];
		#100;
		SCK <= 1;
		#100;
		SCK <= 0;
		#100;
		SSEL <= 1;
	end
	always begin
		#10;
		clock <= ~clock;
	end
endmodule

